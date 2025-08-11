import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/race_result.dart';
import 'storage_service.dart';

class AchievementService {
  static const String _achievementsKey = 'user_achievements';
  static const String _winStreakKey = 'current_win_streak';
  
  static AchievementService? _instance;
  static AchievementService get instance => _instance ??= AchievementService._();
  AchievementService._();

  SharedPreferences? _prefs;
  String? _currentPlayerId;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  void setCurrentPlayer(String playerId) {
    _currentPlayerId = playerId;
  }

  Future<List<Achievement>> getUserAchievements() async {
    await init();
    if (_currentPlayerId == null) return [];
    
    final achievementsJson = _prefs?.getString('${_achievementsKey}_$_currentPlayerId');
    if (achievementsJson == null) {
      // Initialize with default achievements for this user
      return await _initializeAchievements();
    }
    
    final List<dynamic> achievementsList = jsonDecode(achievementsJson);
    return achievementsList.map((json) => Achievement.fromJson(json)).toList();
  }

  Future<List<Achievement>> _initializeAchievements() async {
    if (_currentPlayerId == null) return [];
    
    // Create user's personal copy of achievements with current progress
    final userStats = await _calculateCurrentStats();
    final achievements = AchievementDefinitions.allAchievements.map((achievement) {
      return _updateAchievementProgress(achievement, userStats);
    }).toList();
    
    await _saveUserAchievements(achievements);
    return achievements;
  }

  Future<void> _saveUserAchievements(List<Achievement> achievements) async {
    await init();
    if (_currentPlayerId == null) return;
    
    final achievementsJson = jsonEncode(achievements.map((a) => a.toJson()).toList());
    await _prefs?.setString('${_achievementsKey}_$_currentPlayerId', achievementsJson);
  }

  Future<Map<String, dynamic>> _calculateCurrentStats() async {
    if (_currentPlayerId == null) return {};
    
    final allResults = await StorageService.instance.getRaceResults();
    final playerResults = allResults.where((r) => r.participants.any((p) => p.id == _currentPlayerId)).toList();
    
    int totalRaces = playerResults.length;
    int totalWins = playerResults.where((r) => r.winnerId == _currentPlayerId).length;
    int quickRaceWins = playerResults
        .where((r) => r.groupId == null && r.winnerId == _currentPlayerId)
        .length;
    
    // Calculate fastest race time
    int fastestRaceSeconds = playerResults
        .where((r) => r.winnerId == _currentPlayerId)
        .map((r) => r.totalDuration.inSeconds)
        .fold<int?>(null, (min, duration) => min == null || duration < min ? duration : min) ?? 0;
    
    // Calculate current win streak
    int currentWinStreak = await _getCurrentWinStreak();
    
    // Check for perfect rounds and comebacks
    int perfectRounds = 0;
    int comebacks = 0;
    
    for (final result in playerResults.where((r) => r.winnerId == _currentPlayerId)) {
      if (result.rounds.length > 1) {
        bool isPerfect = result.rounds.every((round) => round.winnerId == _currentPlayerId);
        if (isPerfect) perfectRounds++;
        
        // Check for comeback (lost first round but won race)
        if (result.rounds.first.winnerId != _currentPlayerId) {
          comebacks++;
        }
      }
    }
    
    return {
      'totalRaces': totalRaces,
      'totalWins': totalWins,
      'quickRaceWins': quickRaceWins,
      'fastestRaceSeconds': fastestRaceSeconds,
      'currentWinStreak': currentWinStreak,
      'perfectRounds': perfectRounds,
      'comebacks': comebacks,
    };
  }

  Achievement _updateAchievementProgress(Achievement achievement, Map<String, dynamic> stats) {
    int progress = 0;
    bool isUnlocked = false;
    
    switch (achievement.type) {
      case AchievementType.wins:
        progress = stats['totalWins'] ?? 0;
        break;
      case AchievementType.races:
        progress = stats['totalRaces'] ?? 0;
        break;
      case AchievementType.speed:
        int fastestTime = stats['fastestRaceSeconds'] ?? 0;
        progress = fastestTime > 0 && fastestTime <= achievement.targetValue ? 1 : 0;
        break;
      case AchievementType.streak:
        progress = stats['currentWinStreak'] ?? 0;
        break;
      case AchievementType.special:
        switch (achievement.id) {
          case 'perfect_round':
            progress = stats['perfectRounds'] ?? 0;
            break;
          case 'comeback_king':
            progress = stats['comebacks'] ?? 0;
            break;
          case 'quick_race_master':
            progress = stats['quickRaceWins'] ?? 0;
            break;
        }
        break;
    }
    
    isUnlocked = progress >= achievement.targetValue;
    
    return achievement.copyWith(
      currentProgress: progress,
      isUnlocked: isUnlocked,
      unlockedAt: isUnlocked && !achievement.isUnlocked ? DateTime.now() : achievement.unlockedAt,
    );
  }

  Future<List<Achievement>> checkAndUpdateAchievements(RaceResult raceResult) async {
    if (_currentPlayerId == null) return [];
    
    final currentAchievements = await getUserAchievements();
    final newlyUnlocked = <Achievement>[];
    
    // Update win streak
    bool playerWon = raceResult.winnerId == _currentPlayerId;
    await _updateWinStreak(playerWon);
    
    // Recalculate stats and update achievements
    final stats = await _calculateCurrentStats();
    final updatedAchievements = currentAchievements.map((achievement) {
      final updated = _updateAchievementProgress(achievement, stats);
      
      // Check if this achievement was just unlocked
      if (updated.isUnlocked && !achievement.isUnlocked) {
        newlyUnlocked.add(updated);
      }
      
      return updated;
    }).toList();
    
    await _saveUserAchievements(updatedAchievements);
    return newlyUnlocked;
  }

  Future<int> _getCurrentWinStreak() async {
    await init();
    if (_currentPlayerId == null) return 0;
    
    return _prefs?.getInt('${_winStreakKey}_$_currentPlayerId') ?? 0;
  }

  Future<void> _updateWinStreak(bool playerWon) async {
    await init();
    if (_currentPlayerId == null) return;
    
    int currentStreak = await _getCurrentWinStreak();
    
    if (playerWon) {
      currentStreak++;
    } else {
      currentStreak = 0;
    }
    
    await _prefs?.setInt('${_winStreakKey}_$_currentPlayerId', currentStreak);
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final achievements = await getUserAchievements();
    return achievements.where((a) => a.isUnlocked).toList();
  }

  Future<List<Achievement>> getInProgressAchievements() async {
    final achievements = await getUserAchievements();
    return achievements.where((a) => !a.isUnlocked && a.currentProgress > 0).toList();
  }

  Future<Map<String, int>> getAchievementStats() async {
    final achievements = await getUserAchievements();
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final total = achievements.length;
    final inProgress = achievements.where((a) => !a.isUnlocked && a.currentProgress > 0).length;
    
    return {
      'unlocked': unlocked,
      'total': total,
      'inProgress': inProgress,
      'locked': total - unlocked - inProgress,
    };
  }

  Future<void> resetPlayerAchievements(String playerId) async {
    await init();
    await _prefs?.remove('${_achievementsKey}_$playerId');
    await _prefs?.remove('${_winStreakKey}_$playerId');
  }
}