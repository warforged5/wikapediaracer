import 'package:flutter/material.dart';
import 'dart:async';
import '../models/player.dart';
import '../models/wikipedia_page.dart';
import '../models/race_result.dart';
import '../services/wikipedia_service.dart';
import '../services/storage_service.dart';
import 'race_results_screen.dart';

enum RacePhase {
  selectingStart,
  selectingEnd,
  racing,
  roundComplete,
  raceComplete,
}

class RaceScreen extends StatefulWidget {
  final List<Player> players;
  final int rounds;
  final String? groupId;

  const RaceScreen({
    super.key,
    required this.players,
    required this.rounds,
    this.groupId,
  });

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  RacePhase _phase = RacePhase.selectingStart;
  int _currentRound = 1;
  List<WikipediaPage> _currentPageOptions = [];
  WikipediaPage? _startPage;
  WikipediaPage? _endPage;
  bool _isLoading = false;
  String _loadingMessage = '';
  
  Timer? _raceTimer;
  DateTime? _raceStartTime;
  Duration _currentRoundDuration = Duration.zero;
  
  final List<RaceRound> _completedRounds = [];
  final Map<String, int> _playerScores = {};
  

  @override
  void initState() {
    super.initState();
    
    // Initialize player scores
    for (final player in widget.players) {
      _playerScores[player.id] = 0;
    }
    
    
    
    _loadRandomPages();
  }

  @override
  void dispose() {
    _raceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRandomPages() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = _phase == RacePhase.selectingStart 
          ? 'Loading starting pages...' 
          : 'Loading target pages...';
    });

    try {
      final pages = await WikipediaService.instance.getRandomPages(10);
      setState(() {
        _currentPageOptions = pages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pages: $e')),
        );
      }
    }
  }

  void _selectPage(WikipediaPage page) {
    
    if (_phase == RacePhase.selectingStart) {
      setState(() {
        _startPage = page;
        _phase = RacePhase.selectingEnd;
      });
      _loadRandomPages();
    } else if (_phase == RacePhase.selectingEnd) {
      setState(() {
        _endPage = page;
        _phase = RacePhase.racing;
        _raceStartTime = DateTime.now();
      });
      _startRaceTimer();
      _showRaceDialog();
    }
  }

  void _startRaceTimer() {
    _raceTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_raceStartTime != null) {
        setState(() {
          _currentRoundDuration = DateTime.now().difference(_raceStartTime!);
        });
      }
    });
  }

  void _showRaceDialog() {
    // No longer showing a dialog - racing is now full-screen
    // This method now just updates the phase to racing
  }

  void _playerWins(Player player) {
    _raceTimer?.cancel();
    _playerScores[player.id] = (_playerScores[player.id] ?? 0) + 1;
    
    final round = RaceRound(
      startPage: _startPage!,
      endPage: _endPage!,
      duration: _currentRoundDuration,
      winnerId: player.id,
      roundNumber: _currentRound,
    );
    
    _completedRounds.add(round);
    // No dialog to close in new full-screen design
    
    if (_currentRound >= widget.rounds) {
      _completeRace();
    } else {
      _nextRound();
    }
  }

  void _nextRound() {
    setState(() {
      _currentRound++;
      _phase = RacePhase.roundComplete;
      _currentRoundDuration = Duration.zero;
      // The previous end page becomes the new start page
      _startPage = _endPage;
      _endPage = null;
    });
    
    _showRoundCompleteDialog();
  }

  void _showRoundCompleteDialog() {
    final winner = _completedRounds.last;
    final winnerName = widget.players.firstWhere((p) => p.id == winner.winnerId).name;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Round Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Winner announcement
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$winnerName wins Round ${winner.roundNumber}!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB8860B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Time: ${_formatDuration(winner.duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Current scores
              Text(
                'Current Leaderboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Scores list
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.players.length,
                  itemBuilder: (context, index) {
                    final player = widget.players[index];
                    final score = _playerScores[player.id] ?? 0;
                    final isWinner = player.id == winner.winnerId;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isWinner 
                            ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: isWinner ? Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        ) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isWinner 
                                  ? const Color(0xFFFFD700)
                                  : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                player.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              player.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isWinner
                                  ? const Color(0xFFFFD700)
                                  : Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$score ${score == 1 ? 'win' : 'wins'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isWinner 
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // For subsequent rounds, we only need to select the end page
                // since start page is already set from previous round
                _phase = _currentRound == 1 ? RacePhase.selectingStart : RacePhase.selectingEnd;
                if (_currentRound == 1) {
                  _startPage = null;
                }
                _endPage = null;
              });
              _loadRandomPages();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 18),
                const SizedBox(width: 8),
                Text('Start Round $_currentRound'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeRace() {
    _raceTimer?.cancel();
    setState(() => _phase = RacePhase.raceComplete);
    
    // Determine overall winner (player with most round wins)
    String winnerId = _playerScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final totalDuration = _completedRounds
        .map((r) => r.duration)
        .reduce((a, b) => a + b);
    
    final raceResult = RaceResult(
      groupId: widget.groupId,
      participants: widget.players,
      rounds: _completedRounds,
      winnerId: winnerId,
      totalDuration: totalDuration,
      totalRounds: widget.rounds,
    );
    
    // Save result if it's a group race
    if (widget.groupId != null) {
      StorageService.instance.saveRaceResult(raceResult);
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RaceResultsScreen(result: raceResult),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${milliseconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Leave Race?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to leave the race? All progress will be lost and cannot be recovered.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.exit_to_app_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text('Leave'),
                  ],
                ),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _phase == RacePhase.racing 
              ? 'Racing - Round $_currentRound of ${widget.rounds}'
              : 'Round $_currentRound of ${widget.rounds}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: MediaQuery.of(context).size.width > 800 ? 22 : 18,
              letterSpacing: 0,
            ),
          ),
          centerTitle: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
          actions: [
            if (_phase != RacePhase.racing && MediaQuery.of(context).size.width > 800)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getPhaseColor(),
                        _getPhaseColor().withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getPhaseColor().withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _phase == RacePhase.selectingStart ? Icons.play_arrow : Icons.flag,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _phase == RacePhase.selectingStart ? 'Choose Start' : 'Choose Target',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Color _getPhaseColor() {
    switch (_phase) {
      case RacePhase.selectingStart:
        return const Color(0xFF1976D2); // Material Blue 700
      case RacePhase.selectingEnd:
        return const Color(0xFFFF6F00); // Material Orange 800
      case RacePhase.racing:
        return const Color(0xFF388E3C); // Material Green 700
      case RacePhase.roundComplete:
        return const Color(0xFF7B1FA2); // Material Purple 700
      case RacePhase.raceComplete:
        return const Color(0xFFFFD700); // Gold
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getPhaseColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_getPhaseColor()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _loadingMessage,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getPhaseColor(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fetching Wikipedia pages...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Full screen layouts - no phase indicator bar
    return _phase == RacePhase.racing 
        ? _buildRacingView() 
        : _buildPageSelection();
  }

  String _getPhaseTitle() {
    switch (_phase) {
      case RacePhase.selectingStart:
        return 'Round $_currentRound: Select Starting Page';
      case RacePhase.selectingEnd:
        return _currentRound == 1 
            ? 'Round $_currentRound: Select Target Page'
            : 'Round $_currentRound: Select Next Target';
      case RacePhase.racing:
        return 'Round $_currentRound: Racing in Progress!';
      case RacePhase.roundComplete:
        return 'Round $_currentRound Complete';
      case RacePhase.raceComplete:
        return 'Race Complete!';
    }
  }

  String _getPhaseSubtitle() {
    switch (_phase) {
      case RacePhase.selectingStart:
        return 'Choose which Wikipedia page to start from';
      case RacePhase.selectingEnd:
        return _currentRound == 1 
            ? 'Choose the target page to race to'
            : 'Starting from "${_startPage?.title}" - choose your next target';
      case RacePhase.racing:
        return 'First player to reach "${_endPage?.title}" wins!';
      case RacePhase.roundComplete:
        return 'Get ready for the next round';
      case RacePhase.raceComplete:
        return 'All rounds completed!';
    }
  }

  Widget _buildPageSelection() {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final isTablet = screenSize.width > 600;
    
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 1400 : double.infinity),
          child: Column(
            children: [
              // Clean header with instruction
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _getPhaseColor().withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getPhaseColor().withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: isWeb ? 64 : 56,
                      height: isWeb ? 64 : 56,
                      decoration: BoxDecoration(
                        color: _getPhaseColor(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _phase == RacePhase.selectingStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                        size: isWeb ? 32 : 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getPhaseTitle(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getPhaseColor(),
                        fontSize: isWeb ? 24 : 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPhaseSubtitle(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: isWeb ? 16 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Page grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWeb ? 5 : isTablet ? 3 : 2,
                    crossAxisSpacing: isWeb ? 24 : 12,
                    mainAxisSpacing: isWeb ? 24 : 12,
                    childAspectRatio: isWeb ? 0.85 : 0.75,
                  ),
                  itemCount: _currentPageOptions.length,
                  itemBuilder: (context, index) {
                    final page = _currentPageOptions[index];
                    return _buildModernPageCard(page, index, isWeb: isWeb);
                  },
                ),
              ),
              
              // Refresh button
              if (isWeb) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _loadRandomPages,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Get New Pages'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPageCard(WikipediaPage page, int index, {bool isWeb = false}) {
    return Card(
      elevation: 1,
      shadowColor: Colors.transparent,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _getPhaseColor().withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectPage(page),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Header with number and icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getPhaseColor().withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getPhaseColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getPhaseColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.article_rounded,
                        color: _getPhaseColor(),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        page.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 16 : 15,
                          letterSpacing: 0,
                        ),
                        maxLines: isWeb ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Extract/Description
                      if (page.extract != null && page.extract!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Expanded(
                          child: Text(
                            page.extract!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: isWeb ? 13 : 12,
                              height: 1.4,
                              letterSpacing: 0.4,
                            ),
                            maxLines: isWeb ? 4 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      // Select button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _selectPage(page),
                          style: FilledButton.styleFrom(
                            backgroundColor: _getPhaseColor(),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isWeb ? 14 : 12,
                            ),
                            elevation: 0,
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isWeb ? 14 : 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text('SELECT'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Modern, clean path card for racing
  Widget _buildSimplePathCard(WikipediaPage page, {required bool isStart}) {
    final color = isStart ? const Color(0xFF1976D2) : const Color(0xFF388E3C);
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isStart ? 'START' : 'TARGET',
                  style: TextStyle(
                    fontSize: isWeb ? 12 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isWeb ? 16 : 12),
          Text(
            page.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: isWeb ? 16 : 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
            maxLines: isWeb ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Keep original method for backward compatibility
  Widget _buildPageCard(WikipediaPage page, {bool isWeb = false}) {
    return _buildModernPageCard(page, 0, isWeb: isWeb);
  }

  Widget _buildRacingView() {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final isTablet = screenSize.width > 600;
    
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 16 : 12),
          child: Column(
            children: [
              // Compact timer header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 24 : 16,
                  vertical: isWeb ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF388E3C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      color: Colors.white,
                      size: isWeb ? 20 : 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatDuration(_currentRoundDuration),
                      style: TextStyle(
                        fontSize: isWeb ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isWeb ? 16 : 12),
              
              // Compact race info
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 16 : 12,
                  vertical: isWeb ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_score_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Round $_currentRound of ${widget.rounds}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isWeb ? 16 : 12),
              
              // Horizontal race path - more compact
              Container(
                padding: EdgeInsets.all(isWeb ? 16 : 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    
                    // Compact start -> target layout
                    Row(
                      children: [
                        Expanded(child: _buildCompactPathCard(_startPage!, isStart: true)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward_rounded, size: 24, color: Theme.of(context).colorScheme.primary),
                        ),
                        Expanded(child: _buildCompactPathCard(_endPage!, isStart: false)),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isWeb ? 16 : 12),
              
              // Compact player selection header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 16 : 12,
                  vertical: isWeb ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: isWeb ? 20 : 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Who won?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isWeb ? 16 : 12),
              
              // Player buttons - takes remaining space
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWeb ? 
                            (widget.players.length > 4 ? 3 : 2) : 
                            (isTablet ? 2 : 1),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isWeb ? 4.0 : 5.0,
                        ),
                        itemCount: widget.players.length,
                        itemBuilder: (context, index) {
                          final player = widget.players[index];
                          final colors = [
                            const Color(0xFF1976D2), const Color(0xFFD32F2F), const Color(0xFF388E3C), 
                            const Color(0xFFFF6F00), const Color(0xFF7B1FA2), const Color(0xFF00796B)
                          ];
                          final color = colors[index % colors.length];
                          
                          return Card(
                            elevation: 1,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _playerWins(player),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: color,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            player.name.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          player.name,
                                          style: TextStyle(
                                            fontSize: isWeb ? 16 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPathCard(WikipediaPage page, {required bool isStart}) {
    final color = isStart ? const Color(0xFF1976D2) : const Color(0xFF388E3C);
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Container(
      padding: EdgeInsets.all(isWeb ? 12 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  isStart ? 'START' : 'TARGET',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isWeb ? 12 : 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWebRacePath() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildRacePathCard(_startPage!, isStart: true),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'NAVIGATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: _buildRacePathCard(_endPage!, isStart: false),
        ),
      ],
    );
  }

  Widget _buildMobileRacePath() {
    return Column(
      children: [
        _buildRacePathCard(_startPage!, isStart: true),
        const SizedBox(height: 20),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NAVIGATE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildRacePathCard(_endPage!, isStart: false),
      ],
    );
  }

  Widget _buildRacePathCard(WikipediaPage page, {required bool isStart}) {
    final color = isStart ? Colors.blue : Colors.green;
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isWeb ? 64 : 48,
            height: isWeb ? 64 : 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isStart ? Icons.play_arrow : Icons.flag,
              color: Colors.white,
              size: isWeb ? 32 : 24,
            ),
          ),
          SizedBox(height: isWeb ? 16 : 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isStart ? 'START' : 'TARGET',
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: isWeb ? 16 : 12),
          Text(
            page.title,
            style: TextStyle(
              fontSize: isWeb ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: isWeb ? 4 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (page.extract != null && page.extract!.isNotEmpty && isWeb) ...[
            SizedBox(height: 12),
            Text(
              page.extract!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}