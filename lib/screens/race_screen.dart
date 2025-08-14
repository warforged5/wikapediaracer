import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wikapediaracer/screens/groups_screen.dart';
import 'dart:async';
import 'dart:math';
import '../models/player.dart';
import '../models/wikipedia_page.dart';
import '../models/race_result.dart';
import '../models/achievement.dart';
import '../services/wikipedia_service.dart';
import '../services/storage_service.dart';
import '../services/achievement_service.dart';
import 'race_results_screen.dart';

enum RacePhase {
  selectingStart,
  selectingEnd,
  countdown,
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
  Timer? _countdownTimer;
  DateTime? _raceStartTime;
  Duration _currentRoundDuration = Duration.zero;
  int _countdownSeconds = 0;
  int _countdownDuration = 5; // Default 5 seconds
  
  final List<RaceRound> _completedRounds = [];
  final Map<String, int> _playerScores = {};
  final TextEditingController _customPageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize player scores
    for (final player in widget.players) {
      _playerScores[player.id] = 0;
    }
    
    _loadCountdownDuration();
    _loadRandomPages();
  }

  @override
  void dispose() {
    _raceTimer?.cancel();
    _countdownTimer?.cancel();
    _customPageController.dispose();
    super.dispose();
  }

  Future<void> _loadCountdownDuration() async {
    final duration = await StorageService.instance.getData('countdown_duration');
    if (duration != null && duration is int) {
      setState(() {
        _countdownDuration = duration;
      });
    }
  }

  Future<void> _setCountdownDuration(int duration) async {
    await StorageService.instance.saveData('countdown_duration', duration);
    setState(() {
      _countdownDuration = duration;
    });
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
        _phase = RacePhase.countdown;
        _countdownSeconds = _countdownDuration;
      });
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });
      
      if (_countdownSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() {
          _phase = RacePhase.racing;
          _raceStartTime = DateTime.now();
        });
        _startRaceTimer();
      }
    });
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

  Future<void> _copyPageName(String pageName, String pageType) async {
    await Clipboard.setData(ClipboardData(text: pageName));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$pageType page name copied: $pageName'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCountdownSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.timer_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Countdown Duration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how many seconds to countdown before starting the race:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [3, 5, 8, 10, 15].map((duration) {
                final isSelected = _countdownDuration == duration;
                return FilterChip(
                  selected: isSelected,
                  label: Text('$duration seconds'),
                  onSelected: (selected) {
                    if (selected) {
                      _setCountdownDuration(duration);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _playerWins(Player player) async {
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
      await _completeRace();
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
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: isWeb ? 600 : double.maxFinite,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with winner announcement
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isWeb ? 32 : 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: isWeb ? 48 : 36,
                      ),
                    ),
                    SizedBox(height: isWeb ? 20 : 16),
                    Text(
                      'Round ${winner.roundNumber} Complete!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 28 : 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$winnerName is the winner!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                        fontSize: isWeb ? 20 : 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Time: ${_formatDuration(winner.duration)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content section with leaderboard
              Padding(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                child: Column(
                  children: [
                    Text(
                      'Current Standings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Leaderboard
                    Container(
                      constraints: BoxConstraints(maxHeight: isWeb ? 300 : 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.players.length,
                        itemBuilder: (context, index) {
                          final player = widget.players[index];
                          final score = _playerScores[player.id] ?? 0;
                          final isRoundWinner = player.id == winner.winnerId;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: isRoundWinner ? 4 : 1,
                              color: isRoundWinner 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surface,
                              child: Padding(
                                padding: EdgeInsets.all(isWeb ? 16 : 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: isWeb ? 40 : 32,
                                      height: isWeb ? 40 : 32,
                                      decoration: BoxDecoration(
                                        color: isRoundWinner
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.outline,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          player.name.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isWeb ? 16 : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isWeb ? 16 : 12),
                                    Expanded(
                                      child: Text(
                                        player.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: isRoundWinner ? FontWeight.bold : FontWeight.w500,
                                          color: isRoundWinner 
                                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isRoundWinner
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.surfaceContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$score ${score == 1 ? 'win' : 'wins'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isRoundWinner 
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isRoundWinner) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.emoji_events_outlined,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(height: isWeb ? 24 : 20),
                    
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 32 : 24,
                            vertical: isWeb ? 16 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _currentRound >= widget.rounds 
                                  ? 'View Results'
                                  : 'Continue to Round $_currentRound',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isWeb ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
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

  Future<void> _completeRace() async {
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
    
    // Always save race result (both quick races and group races)
    await StorageService.instance.saveRaceResult(raceResult);
    
    // Check achievements for all participants
    final newlyUnlockedAchievements = <String, List<Achievement>>{};
    for (final player in widget.players) {
      AchievementService.instance.setCurrentPlayer(player.id);
      final newAchievements = await AchievementService.instance.checkAndUpdateAchievements(raceResult);
      if (newAchievements.isNotEmpty) {
        newlyUnlockedAchievements[player.id] = newAchievements;
      }
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
            // Settings button for countdown duration
            if (_phase == RacePhase.selectingStart || _phase == RacePhase.selectingEnd)
              IconButton(
                onPressed: _showCountdownSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Countdown Settings',
              ),
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
                        _phase == RacePhase.selectingStart ? Icons.play_arrow : (_phase == RacePhase.selectingEnd ? Icons.flag : Icons.timer),
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _phase == RacePhase.selectingStart 
                          ? 'Choose Start' 
                          : (_phase == RacePhase.selectingEnd 
                            ? 'Choose Target'
                            : 'Get Ready'
                          ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimary,
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
        return Theme.of(context).colorScheme.primary;
      case RacePhase.selectingEnd:
        return Theme.of(context).colorScheme.secondary;
      case RacePhase.countdown:
        return Theme.of(context).colorScheme.tertiary;
      case RacePhase.racing:
        return Theme.of(context).colorScheme.primary;
      case RacePhase.roundComplete:
        return Theme.of(context).colorScheme.secondary;
      case RacePhase.raceComplete:
        return Theme.of(context).colorScheme.tertiary;
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
    if (_phase == RacePhase.racing) {
      return _buildRacingView();
    } else if (_phase == RacePhase.countdown) {
      return _buildCountdownView();
    } else {
      return _buildPageSelection();
    }
  }

  String _getPhaseTitle() {
    switch (_phase) {
      case RacePhase.selectingStart:
        return 'Round $_currentRound: Select Starting Page';
      case RacePhase.selectingEnd:
        return _currentRound == 1 
            ? 'Round $_currentRound: Select Target Page'
            : 'Round $_currentRound: Select Next Target';
      case RacePhase.countdown:
        return 'Round $_currentRound: Get Ready!';
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
      case RacePhase.countdown:
        return 'Race starting in $_countdownSeconds seconds...';
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
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section - Fixed height
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              decoration: BoxDecoration(
                color: _getPhaseColor(),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _phase == RacePhase.selectingStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: isWeb ? 32 : 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPhaseTitle(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: isWeb ? 24 : 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPhaseSubtitle(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                                fontSize: isWeb ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content Section - Takes remaining space
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 24 : 16),
                child: Column(
                  children: [
                    // Custom Input Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(isWeb ? 20 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter Custom Page',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customPageController,
                                    decoration: InputDecoration(
                                      hintText: 'Wikipedia page title...',
                                      prefixIcon: const Icon(Icons.article_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onSubmitted: _handleCustomPageInput,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                animatedAddButton(onPressed:  () => _handleCustomPageInput(_customPageController.text))
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Page Grid Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Choose from Suggestions',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _loadRandomPages,
                                  icon: const Icon(Icons.refresh_rounded),
                                  tooltip: 'Get new suggestions',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWeb ? 4 : (isTablet ? 3 : 2),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: isWeb ? 1.3 : 1.0,
                              ),
                              itemCount: _currentPageOptions.length,
                              itemBuilder: (context, index) {
                                final page = _currentPageOptions[index];
                                return _buildCleanPageCard(page, index);
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
          ],
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
    final color = isStart ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;
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
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Timer Header - Fixed height
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Round $_currentRound of ${widget.rounds}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontSize: isWeb ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(_currentRoundDuration),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: isWeb ? 36 : 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.timer_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: isWeb ? 32 : 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content Area - Takes remaining space
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 24 : 16),
                child: isWeb ? _buildWebTwoColumnLayout() : _buildMobileLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownView() {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with countdown info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.timer_rounded,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: isWeb ? 32 : 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPhaseTitle(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: isWeb ? 24 : 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPhaseSubtitle(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                fontSize: isWeb ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Countdown display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Large countdown number with floating animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, sin(value * 2 * pi) * 3),
                          child: AnimatedScale(
                            scale: _countdownSeconds <= 3 ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: isWeb ? 200 : 150,
                              height: isWeb ? 200 : 150,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(isWeb ? 100 : 75),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: _countdownSeconds <= 3 ? 0.5 : 0.3),
                                    blurRadius: _countdownSeconds <= 3 ? 30 : 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$_countdownSeconds',
                                  style: TextStyle(
                                    fontSize: isWeb ? 80 : 60,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: isWeb ? 40 : 30),
                    
                    // Race path display
                    if (isWeb) _buildWebRacePathPreview() else _buildMobileRacePathPreview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebRacePathPreview() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'START',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _startPage?.title ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _copyPageName(_startPage?.title ?? '', 'Start'),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          iconSize: 16,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          tooltip: 'Copy start page name',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.arrow_forward_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TARGET',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _endPage?.title ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _copyPageName(_endPage?.title ?? '', 'Target'),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          iconSize: 16,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          tooltip: 'Copy target page name',
                        ),
                      ],
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

  Widget _buildMobileRacePathPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Start page
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'START',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _startPage?.title ?? '',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _copyPageName(_startPage?.title ?? '', 'Start'),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        iconSize: 14,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        tooltip: 'Copy start page name',
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              
              const SizedBox(height: 16),
              
              // Target page
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TARGET',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _endPage?.title ?? '',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _copyPageName(_endPage?.title ?? '', 'Target'),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        iconSize: 14,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        tooltip: 'Copy target page name',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPathCard(WikipediaPage page, {required bool isStart}) {
    final color = isStart ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;
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
          child: _buildCleanRacePathCard(_startPage!, isStart: true),
        ),
        Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Navigate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildCleanRacePathCard(_endPage!, isStart: false),
        ),
      ],
    );
  }

  Widget _buildMobileRacePath() {
    return Column(
      children: [
        Expanded(
          child: _buildCleanRacePathCard(_startPage!, isStart: true),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 4),
              Text(
                'Navigate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildCleanRacePathCard(_endPage!, isStart: false),
        ),
      ],
    );
  }

  Widget _buildRacePathCard(WikipediaPage page, {required bool isStart}) {
    final color = isStart ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildWebBoldPath() {
    return Row(
      children: [
        Expanded(
          child: _buildBoldPathCard(_startPage!, isStart: true),
        ),
        Container(
          width: 120,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color(0xFF388E3C),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.double_arrow_rounded,
                  size: 40,
                  color: Color(0xFF388E3C),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'NAVIGATE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildBoldPathCard(_endPage!, isStart: false),
        ),
      ],
    );
  }

  Widget _buildMobileBoldPath() {
    return Column(
      children: [
        _buildBoldPathCard(_startPage!, isStart: true),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF388E3C),
              width: 3,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 32,
                color: const Color(0xFF388E3C),
              ),
              const SizedBox(height: 8),
              Text(
                'NAVIGATE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF388E3C),
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildBoldPathCard(_endPage!, isStart: false),
      ],
    );
  }

  Widget _buildBoldPathCard(WikipediaPage page, {required bool isStart}) {
    final color = isStart ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isWeb ? 100 : 80,
            height: isWeb ? 100 : 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(isWeb ? 50 : 40),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
              color: Colors.white,
              size: isWeb ? 50 : 40,
            ),
          ),
          SizedBox(height: isWeb ? 24 : 20),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? 24 : 16, 
              vertical: isWeb ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isStart ? 'START' : 'TARGET',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 2.0,
              ),
            ),
          ),
          SizedBox(height: isWeb ? 24 : 20),
          Text(
            page.title,
            style: TextStyle(
              fontSize: isWeb ? 28 : 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: isWeb ? 4 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (page.extract != null && page.extract!.isNotEmpty && isWeb) ...[
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: Text(
                page.extract!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFunPathCard(WikipediaPage page, {required bool isStart}) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final primaryColor = isStart ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary;
    final emoji = isStart ? '🚀' : '🎯';
    final label = isStart ? 'START' : 'FINISH';
    
    return Card(
      elevation: 6,
      shadowColor: primaryColor.withValues(alpha: 0.3),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fun emoji header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: isWeb ? 24 : 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Page title with fun styling
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    page.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: isWeb ? 16 : 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: isWeb ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (page.extract != null && page.extract!.isNotEmpty && isWeb) ...[
                    const SizedBox(height: 8),
                    Text(
                      page.extract!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCustomPageInput(String title) {
    if (title.trim().isEmpty) return;
    
    // Create a custom Wikipedia page from the input
    final customPage = WikipediaPage(
      pageId: -1, // Use -1 to indicate custom page
      title: title.trim(),
      extract: 'Custom page: ${title.trim()}',
    );
    
    // Clear the text field
    _customPageController.clear();
    
    // Select this custom page
    _selectPage(customPage);
  }

  Widget _buildFunPageSelectionCard(WikipediaPage page, int index, {bool isWeb = false}) {
    return Card(
      elevation: 4,
      shadowColor: _getPhaseColor().withValues(alpha: 0.3),
      child: InkWell(
        onTap: () => _selectPage(page),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getPhaseColor().withValues(alpha: 0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            border: Border.all(
              color: _getPhaseColor().withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getPhaseColor(),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getPhaseColor().withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getPhaseColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.article_rounded,
                        color: _getPhaseColor(),
                        size: 16,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Expanded(
                  child: Text(
                    page.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isWeb ? 14 : 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: isWeb ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Extract preview
                if (page.extract != null && page.extract!.isNotEmpty) ...[
                  Text(
                    page.extract!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: isWeb ? 12 : 11,
                      height: 1.3,
                    ),
                    maxLines: isWeb ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Select button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _getPhaseColor(),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getPhaseColor().withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SELECT',
                        style: TextStyle(
                          fontSize: isWeb ? 12 : 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanPageCard(WikipediaPage page, int index) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _selectPage(page),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPhaseColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 10 : 12,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.article_outlined,
                    color: _getPhaseColor(),
                    size: isWeb ? 16 : 20,
                  ),
                ],
              ),
              
              SizedBox(height: isWeb ? 8 : 12),
              
              // Title
              Text(
                page.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isWeb ? 13 : 13,
                  height: 1.2,
                ),
                maxLines: isWeb ? 2 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: isWeb ? 6 : 8),
              
              // Extract (only on web and only if space allows)
              if (page.extract != null && page.extract!.isNotEmpty && isWeb) ...[
                Expanded(
                  child: Text(
                    page.extract!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 8),
              ] else
                const Spacer(),
              
              // Select button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _selectPage(page),
                  style: FilledButton.styleFrom(
                    backgroundColor: _getPhaseColor(),
                    padding: EdgeInsets.symmetric(vertical: isWeb ? 6 : 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'SELECT',
                    style: TextStyle(
                      fontSize: isWeb ? 11 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player player, int index) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.primaryContainer,
      Theme.of(context).colorScheme.secondaryContainer,
    ];
    final color = colors[index % colors.length];
    
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () => _playerWins(player),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color,
          ),
          padding: EdgeInsets.all(isWeb ? 16 : 12),
          child: Row(
            children: [
              Container(
                width: isWeb ? 40 : 32,
                height: isWeb ? 40 : 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    player.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player.name,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanRacePathCard(WikipediaPage page, {required bool isStart}) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final primaryColor = isStart 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.tertiary;
    final containerColor = isStart 
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.tertiaryContainer;
    final onContainerColor = isStart 
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onTertiaryContainer;
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                color: onContainerColor,
                size: isWeb ? 32 : 24,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isStart ? 'START' : 'TARGET',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isWeb ? 12 : 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Page title with copy button
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        page.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 16 : 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: isWeb ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _copyPageName(page.title, isStart ? 'Start' : 'Target'),
                      icon: const Icon(Icons.copy_rounded),
                      iconSize: isWeb ? 18 : 16,
                      padding: const EdgeInsets.all(4),
                      constraints: BoxConstraints(
                        minWidth: isWeb ? 28 : 24,
                        minHeight: isWeb ? 28 : 24,
                      ),
                      tooltip: 'Copy ${isStart ? "start" : "target"} page name',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTwoColumnLayout() {
    return Row(
      children: [
        // Left Column - Race Path (takes 60% of width)
        Expanded(
          flex: 3,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Race Path',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildCleanRacePathCard(_startPage!, isStart: true),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Navigate',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildCleanRacePathCard(_endPage!, isStart: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Right Column - Player Selection (takes 40% of width)
        Expanded(
          flex: 2,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Who reached the target?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: widget.players.length,
                      itemBuilder: (context, index) {
                        final player = widget.players[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildWebPlayerCard(player, index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Race Path Section
        Expanded(
          flex: 2,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Race Path',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildMobileRacePath(),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Player Selection Section
        Expanded(
          flex: 1,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Who reached the target?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: widget.players.length,
                      itemBuilder: (context, index) {
                        final player = widget.players[index];
                        return _buildPlayerCard(player, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebPlayerCard(Player player, int index) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.primaryContainer,
      Theme.of(context).colorScheme.secondaryContainer,
    ];
    final color = colors[index % colors.length];
    
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () => _playerWins(player),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color,
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    player.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.touch_app_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}