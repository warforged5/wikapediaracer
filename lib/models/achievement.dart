import 'package:json_annotation/json_annotation.dart';

part 'achievement.g.dart';

enum AchievementType {
  wins,
  races,
  speed,
  streak,
  special,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
}

@JsonSerializable()
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final AchievementType type;
  final AchievementTier tier;
  final int targetValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.type,
    required this.tier,
    required this.targetValue,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    AchievementType? type,
    AchievementTier? tier,
    int? targetValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      targetValue: targetValue ?? this.targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AchievementDefinitions {
  static const List<Achievement> allAchievements = [
    // Win achievements
    Achievement(
      id: 'first_win',
      name: 'First Victory',
      description: 'Win your first race',
      iconName: 'emoji_events',
      type: AchievementType.wins,
      tier: AchievementTier.bronze,
      targetValue: 1,
    ),
    Achievement(
      id: 'win_5',
      name: 'Rising Star',
      description: 'Win 5 races',
      iconName: 'star',
      type: AchievementType.wins,
      tier: AchievementTier.silver,
      targetValue: 5,
    ),
    Achievement(
      id: 'win_10',
      name: 'Champion',
      description: 'Win 10 races',
      iconName: 'military_tech',
      type: AchievementType.wins,
      tier: AchievementTier.gold,
      targetValue: 10,
    ),
    Achievement(
      id: 'win_25',
      name: 'Wikipedia Master',
      description: 'Win 25 races',
      iconName: 'workspace_premium',
      type: AchievementType.wins,
      tier: AchievementTier.platinum,
      targetValue: 25,
    ),

    // Race participation achievements
    Achievement(
      id: 'race_5',
      name: 'Getting Started',
      description: 'Complete 5 races',
      iconName: 'directions_run',
      type: AchievementType.races,
      tier: AchievementTier.bronze,
      targetValue: 5,
    ),
    Achievement(
      id: 'race_15',
      name: 'Dedicated Racer',
      description: 'Complete 15 races',
      iconName: 'fitness_center',
      type: AchievementType.races,
      tier: AchievementTier.silver,
      targetValue: 15,
    ),
    Achievement(
      id: 'race_30',
      name: 'Marathon Runner',
      description: 'Complete 30 races',
      iconName: 'emoji_events',
      type: AchievementType.races,
      tier: AchievementTier.gold,
      targetValue: 30,
    ),
    Achievement(
      id: 'race_50',
      name: 'Race Veteran',
      description: 'Complete 50 races',
      iconName: 'diamond',
      type: AchievementType.races,
      tier: AchievementTier.platinum,
      targetValue: 50,
    ),

    // Speed achievements (seconds)
    Achievement(
      id: 'speed_300',
      name: 'Lightning Fast',
      description: 'Complete a race in under 5 minutes',
      iconName: 'flash_on',
      type: AchievementType.speed,
      tier: AchievementTier.bronze,
      targetValue: 300,
    ),
    Achievement(
      id: 'speed_180',
      name: 'Speed Demon',
      description: 'Complete a race in under 3 minutes',
      iconName: 'whatshot',
      type: AchievementType.speed,
      tier: AchievementTier.silver,
      targetValue: 180,
    ),
    Achievement(
      id: 'speed_120',
      name: 'Supersonic',
      description: 'Complete a race in under 2 minutes',
      iconName: 'rocket_launch',
      type: AchievementType.speed,
      tier: AchievementTier.gold,
      targetValue: 120,
    ),
    Achievement(
      id: 'speed_60',
      name: 'Light Speed',
      description: 'Complete a race in under 1 minute',
      iconName: 'bolt',
      type: AchievementType.speed,
      tier: AchievementTier.platinum,
      targetValue: 60,
    ),

    // Win streak achievements
    Achievement(
      id: 'streak_3',
      name: 'Hot Streak',
      description: 'Win 3 races in a row',
      iconName: 'local_fire_department',
      type: AchievementType.streak,
      tier: AchievementTier.bronze,
      targetValue: 3,
    ),
    Achievement(
      id: 'streak_5',
      name: 'On Fire',
      description: 'Win 5 races in a row',
      iconName: 'fireplace',
      type: AchievementType.streak,
      tier: AchievementTier.silver,
      targetValue: 5,
    ),
    Achievement(
      id: 'streak_10',
      name: 'Unstoppable',
      description: 'Win 10 races in a row',
      iconName: 'auto_awesome',
      type: AchievementType.streak,
      tier: AchievementTier.gold,
      targetValue: 10,
    ),

    // Special achievements
    Achievement(
      id: 'perfect_round',
      name: 'Perfect Round',
      description: 'Win all rounds in a multi-round race',
      iconName: 'star_rate',
      type: AchievementType.special,
      tier: AchievementTier.gold,
      targetValue: 1,
    ),
    Achievement(
      id: 'comeback_king',
      name: 'Comeback King',
      description: 'Win a race after losing the first round',
      iconName: 'trending_up',
      type: AchievementType.special,
      tier: AchievementTier.silver,
      targetValue: 1,
    ),
    Achievement(
      id: 'quick_race_master',
      name: 'Quick Draw',
      description: 'Win 10 quick races',
      iconName: 'speed',
      type: AchievementType.special,
      tier: AchievementTier.silver,
      targetValue: 10,
    ),
  ];

  static Achievement? getAchievementById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}