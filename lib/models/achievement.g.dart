// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  iconName: json['iconName'] as String,
  type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
  tier: $enumDecode(_$AchievementTierEnumMap, json['tier']),
  targetValue: (json['targetValue'] as num).toInt(),
  isUnlocked: json['isUnlocked'] as bool? ?? false,
  unlockedAt: json['unlockedAt'] == null
      ? null
      : DateTime.parse(json['unlockedAt'] as String),
  currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'iconName': instance.iconName,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'tier': _$AchievementTierEnumMap[instance.tier]!,
      'targetValue': instance.targetValue,
      'isUnlocked': instance.isUnlocked,
      'unlockedAt': instance.unlockedAt?.toIso8601String(),
      'currentProgress': instance.currentProgress,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.wins: 'wins',
  AchievementType.races: 'races',
  AchievementType.speed: 'speed',
  AchievementType.streak: 'streak',
  AchievementType.special: 'special',
};

const _$AchievementTierEnumMap = {
  AchievementTier.bronze: 'bronze',
  AchievementTier.silver: 'silver',
  AchievementTier.gold: 'gold',
  AchievementTier.platinum: 'platinum',
};
