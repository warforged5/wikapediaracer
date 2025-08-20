import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wikapediaracer/screens/groups_screen.dart';
import 'package:morphable_shape/morphable_shape.dart';
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
  final List<String>? customPages;
  final int? optionCount;

  const RaceScreen({
    super.key,
    required this.players,
    required this.rounds,
    this.groupId,
    this.customPages,
    this.optionCount,
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
  int _refreshCount = 0;
  static const int _maxRefreshes = 3;
  
  // Custom list support
  List<String>? _customPageList;
  int _customPageOptionCount = 5;

  @override
  void initState() {
    super.initState();
    
    // Initialize player scores
    for (final player in widget.players) {
      _playerScores[player.id] = 0;
    }
    
    // Initialize custom list support
    _customPageList = widget.customPages;
    _customPageOptionCount = widget.optionCount ?? 5;
    
    _loadCountdownDuration();
    _loadPages();
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

  Future<void> _loadPages() async {
    if (_isLoading) return; // Prevent concurrent calls
    
    setState(() {
      _isLoading = true;
      _loadingMessage = _phase == RacePhase.selectingStart 
          ? 'Loading starting pages...' 
          : 'Loading target pages...';
    });

    try {
      List<WikipediaPage> pages;
      
      if (_customPageList != null && _customPageList!.isNotEmpty) {
        // Use custom list
        pages = _getRandomCustomPages(_customPageOptionCount);
      } else {
        // Use Wikipedia API
        pages = await WikipediaService.instance.getRandomPages(10)
            .timeout(const Duration(seconds: 10));
      }
      
      if (mounted) {
        setState(() {
          _currentPageOptions = pages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pages: $e')),
        );
      }
    }
  }

  List<WikipediaPage> _getRandomCustomPages(int count) {
    if (_customPageList == null || _customPageList!.isEmpty) {
      return [];
    }
    
    final shuffled = List<String>.from(_customPageList!)..shuffle();
    final selectedPages = shuffled.take(count).toList();
    
    return selectedPages.map((title) => WikipediaPage(
      pageId: title.hashCode,
      title: title,
    )).toList();
  }

  Future<void> _refreshPages() async {
    if (_customPageList != null) {
      // For custom lists, we can refresh without limits
      await _loadPages();
      return;
    }
    
    if (_refreshCount >= _maxRefreshes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum refresh limit reached (3/3). Use custom page option if needed.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    _refreshCount++;
    await _loadPages();
    
    if (mounted) {
      final remaining = _maxRefreshes - _refreshCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pages refreshed! ${remaining > 0 ? "$remaining refreshes remaining" : "No more refreshes available"}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectPage(WikipediaPage page) {
    
    if (_phase == RacePhase.selectingStart) {
      setState(() {
        _startPage = page;
        _phase = RacePhase.selectingEnd;
        _refreshCount = 0; // Reset refresh count for end page selection
      });
      // Only load pages if we're not already loading and it's not a custom page issue
      if (!_isLoading) {
        _loadPages();
      }
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
      builder: (context) => _CountdownSettingsDialog(
        currentDuration: _countdownDuration,
        onDurationChanged: _setCountdownDuration,
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
                            _refreshCount = 0; // Reset refresh count for new round
                          });
                          _loadPages();
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
                                  onPressed: _refreshCount >= _maxRefreshes ? null : _refreshPages,
                                  icon: const Icon(Icons.refresh_rounded),
                                  tooltip: _refreshCount >= _maxRefreshes 
                                      ? 'Maximum refreshes reached (3/3)'
                                      : 'Get new suggestions (${_maxRefreshes - _refreshCount} left)',
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
                                return _AnimatedPageCard(
                                  page: page, 
                                  index: index, 
                                  onTap: () => _selectPage(page),
                                  phaseColor: _getPhaseColor(),
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
          ],
        ),
      ),
    );
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

  Widget _buildSimpleCountdownPreview(bool isWeb) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    
    return Container(
      constraints: BoxConstraints(maxWidth: isWeb ? 500 : 400),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start page - simplified
              _buildSimplePagePreview(_startPage!, isStart: true, isWeb: isWeb, isCompact: isCompact),
              
              SizedBox(height: isWeb ? 16 : 12),
              
              // Arrow indicator
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 16 : 12, 
                  vertical: isWeb ? 8 : 6
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: isWeb ? 18 : 16,
                    ),
                    SizedBox(width: isWeb ? 6 : 4),
                    Text(
                      'RACE TO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: isWeb ? 12 : 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isWeb ? 16 : 12),
              
              // Target page - simplified
              _buildSimplePagePreview(_endPage!, isStart: false, isWeb: isWeb, isCompact: isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimplePagePreview(WikipediaPage page, {required bool isStart, required bool isWeb, required bool isCompact}) {
    final primaryColor = isStart 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.tertiary;
    final containerColor = isStart 
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.tertiaryContainer;
    final onContainerColor = isStart 
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onTertiaryContainer;
    
    return Row(
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(isWeb ? 10 : 8),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
            color: onContainerColor,
            size: isWeb ? 20 : 18,
          ),
        ),
        
        SizedBox(width: isWeb ? 12 : 10),
        
        // Label
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 8 : 6, 
            vertical: isWeb ? 4 : 3
          ),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isStart ? 'START' : 'TARGET',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isWeb ? 10 : 9,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        SizedBox(width: isWeb ? 12 : 10),
        
        // Page title
        Expanded(
          child: Text(
            page.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isWeb ? 14 : 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                    // Animated countdown timer with spinning and morphing
                    _AnimatedCountdownTimer(
                      countdownSeconds: _countdownSeconds,
                      isWeb: isWeb,
                    ),
                    
                    SizedBox(height: isWeb ? 40 : 30),
                    
                    // Race path display - simplified for countdown
                    _buildSimpleCountdownPreview(isWeb),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive breakpoints
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800 && screenWidth <= 1200;
    final isSmallScreen = screenWidth > 600 && screenWidth <= 800;
    final isMobile = screenWidth <= 600;
    final isCompact = screenHeight < 600;
    
    // Dynamic sizing based on screen size
    final cardPadding = isLargeScreen ? 20.0 : isMediumScreen ? 16.0 : isSmallScreen ? 14.0 : 12.0;
    final iconSize = isLargeScreen ? 32.0 : isMediumScreen ? 28.0 : isSmallScreen ? 24.0 : 20.0;
    final titleFontSize = isLargeScreen ? 16.0 : isMediumScreen ? 15.0 : isSmallScreen ? 14.0 : 13.0;
    final labelFontSize = isLargeScreen ? 11.0 : isMediumScreen ? 10.0 : 9.0;
    final descriptionFontSize = isLargeScreen ? 13.0 : isMediumScreen ? 12.0 : isSmallScreen ? 11.0 : 10.0;
    
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
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Icon and label
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                    color: onContainerColor,
                    size: iconSize,
                  ),
                ),
                
                SizedBox(height: isMobile ? 6 : 8),
                
                // Label
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10, 
                    vertical: isMobile ? 4 : 6
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isStart ? 'START' : 'TARGET',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: labelFontSize,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(width: isMobile ? 12 : 16),
            
            // Right side - Page content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page title with copy button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          page.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: titleFontSize,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.3,
                          ),
                          maxLines: isCompact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _copyPageName(page.title, isStart ? 'Start' : 'Target'),
                        icon: const Icon(Icons.copy_rounded),
                        iconSize: isMobile ? 16 : 18,
                        padding: const EdgeInsets.all(4),
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 24 : 28,
                          minHeight: isMobile ? 24 : 28,
                        ),
                        tooltip: 'Copy ${isStart ? "start" : "target"} page name',
                      ),
                    ],
                  ),
                  
                  // Page description (if available)
                  if (page.extract != null && page.extract!.isNotEmpty) ...[
                    SizedBox(height: isMobile ? 6 : 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        page.extract!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: descriptionFontSize,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: isCompact ? 2 : (isMobile ? 3 : 4),
                        overflow: TextOverflow.ellipsis,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedPageCard extends StatefulWidget {
  final WikipediaPage page;
  final int index;
  final VoidCallback onTap;
  final Color phaseColor;

  const _AnimatedPageCard({
    required this.page,
    required this.index,
    required this.onTap,
    required this.phaseColor,
  });

  @override
  State<_AnimatedPageCard> createState() => _AnimatedPageCardState();
}

class _AnimatedPageCardState extends State<_AnimatedPageCard>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _bounceController;
  late Animation<double> _morphAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Morph from squircle (0.0) to circle-like (1.0)
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
    );
    
    // Scale animation for the bounce
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    // Start entrance animation with delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _morphController.forward();
        _bounceController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.reset();
    _bounceController.forward().then((_) {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_morphAnimation, _scaleAnimation]),
      builder: (context, child) {
        // Calculate border radius: squircle (12) to more rounded (20)
        final borderRadius = Tween<double>(
          begin: 12.0, // Squircle
          end: 20.0,   // More rounded
        ).evaluate(_morphAnimation);
        
        final scale = 1.0 + (_scaleAnimation.value - 1.0);
        
        return Transform.scale(
          scale: scale,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: widget.phaseColor.withValues(alpha: _isHovered ? 0.3 : 0.1),
                    blurRadius: _isHovered ? 12 : 6,
                    offset: Offset(0, _isHovered ? 8 : 4),
                    spreadRadius: _isHovered ? 1 : 0,
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  side: BorderSide(
                    color: widget.phaseColor.withValues(alpha: _isHovered ? 0.4 : 0.2),
                    width: _isHovered ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: _handleTap,
                  borderRadius: BorderRadius.circular(borderRadius),
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
                                color: widget.phaseColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWeb ? 10 : 12,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.article_outlined,
                              color: widget.phaseColor,
                              size: isWeb ? 16 : 20,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: isWeb ? 8 : 12),
                        
                        // Title
                        Text(
                          widget.page.title,
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
                        if (widget.page.extract != null && widget.page.extract!.isNotEmpty && isWeb) ...[
                          Expanded(
                            child: Text(
                              widget.page.extract!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 11,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else
                          const Spacer(),
                        
                        // Select button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _handleTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: widget.phaseColor,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountdownSettingsDialog extends StatefulWidget {
  final int currentDuration;
  final Function(int) onDurationChanged;

  const _CountdownSettingsDialog({
    required this.currentDuration,
    required this.onDurationChanged,
  });

  @override
  State<_CountdownSettingsDialog> createState() => _CountdownSettingsDialogState();
}

class _CountdownSettingsDialogState extends State<_CountdownSettingsDialog> {
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.currentDuration;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          _buildSegmentedButtons(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSegmentedButtons() {
    const durations = [3, 5, 8, 10, 15];
    
    return Row(
      children: durations.asMap().entries.map((entry) {
        final index = entry.key;
        final duration = entry.value;
        final isFirst = index == 0;
        final isLast = index == durations.length - 1;
        final isSelected = _selectedDuration == duration;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isLast ? 0 : 2,
            ),
            child: _buildSegmentButton(
              duration: duration,
              isSelected: isSelected,
              isFirst: isFirst,
              isLast: isLast,
              onTap: () {
                setState(() {
                  _selectedDuration = duration;
                });
                widget.onDurationChanged(duration);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSegmentButton({
    required int duration,
    required bool isSelected,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    // When selected, use more rounded corners on both sides
    final leftRadius = isSelected 
        ? const Radius.circular(16) 
        : (isFirst ? const Radius.circular(12) : const Radius.circular(4));
    final rightRadius = isSelected 
        ? const Radius.circular(16) 
        : (isLast ? const Radius.circular(12) : const Radius.circular(4));
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: leftRadius,
          right: rightRadius,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.horizontal(
              left: leftRadius,
              right: rightRadius,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ) ?? const TextStyle(),
              child: Text('${duration}s'),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCountdownTimer extends StatefulWidget {
  final int countdownSeconds;
  final bool isWeb;

  const _AnimatedCountdownTimer({
    required this.countdownSeconds,
    required this.isWeb,
  });

  @override
  State<_AnimatedCountdownTimer> createState() => _AnimatedCountdownTimerState();
}

class _AnimatedCountdownTimerState extends State<_AnimatedCountdownTimer>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _morphController;
  late AnimationController _floatController;
  late Animation<double> _spinAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _floatAnimation;
  late MorphableShapeBorderTween _shapeTween;

  @override
  void initState() {
    super.initState();

    // Create shapes for morphing - cycle through different shapes
    final shapes = [
      CircleShapeBorder(),
      PolygonShapeBorder(sides: 6, cornerRadius: 15.toPercentLength, cornerStyle: CornerStyle.rounded),
      StarShapeBorder(
      corners: 5,
      inset: 50.toPercentLength,
      cornerRadius: 30.toPXLength,
      cornerStyle: CornerStyle.rounded,
      insetRadius: 0.toPXLength,
      insetStyle: CornerStyle.rounded
      ),
      PolygonShapeBorder(sides: 8, cornerRadius: 25.toPercentLength, cornerStyle: CornerStyle.rounded),
      
    ];

    _shapeTween = MorphableShapeBorderTween(
      begin: shapes[0],
      end: shapes[1],
      method: MorphMethod.auto,
    );

    // Continuous spinning animation
    _spinController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Shape morphing animation
    _morphController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Floating animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.linear,
    ));

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOut,
    );

    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // Start continuous animations
    _spinController.repeat();
    _floatController.repeat(reverse: true);
    
    // Start morphing cycle
    _startMorphCycle(shapes);
  }

  void _startMorphCycle(List<ShapeBorder> shapes) {
    int currentIndex = 0;
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final nextIndex = (currentIndex + 1) % shapes.length;
      setState(() {
        _shapeTween = MorphableShapeBorderTween(
          begin: shapes[currentIndex] as MorphableShapeBorder,
          end: shapes[nextIndex] as MorphableShapeBorder,
          method: MorphMethod.auto,
        );
      });
      
      _morphController.reset();
      _morphController.forward();
      currentIndex = nextIndex;
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _morphController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isWeb ? 200.0 : 150.0;
    final fontSize = widget.isWeb ? 80.0 : 60.0;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_spinAnimation, _morphAnimation, _floatAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, sin(_floatAnimation.value * 2 * pi) * 5),
          child: Transform.rotate(
            angle: _spinAnimation.value * 2 * pi,
            child: AnimatedScale(
              scale: widget.countdownSeconds <= 3 ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: size,
                height: size,
                decoration: ShapeDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: _shapeTween.lerp(_morphAnimation.value)!,
                  shadows: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: widget.countdownSeconds <= 3 ? 0.5 : 0.3
                      ),
                      blurRadius: widget.countdownSeconds <= 3 ? 30 : 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -_spinAnimation.value * 2 * pi, // Counter-rotate text
                    child: Text(
                      '${widget.countdownSeconds}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}