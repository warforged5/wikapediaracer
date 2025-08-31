// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_active_race.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncActiveRace _$SyncActiveRaceFromJson(Map<String, dynamic> json) =>
    SyncActiveRace(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      startedByPlayerId: json['started_by_player_id'] as String,
      raceConfig: json['race_config'] as Map<String, dynamic>,
      status:
          $enumDecodeNullable(_$ActiveRaceStatusEnumMap, json['status']) ??
          ActiveRaceStatus.waiting,
      currentRound: (json['current_round'] as num?)?.toInt() ?? 1,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$SyncActiveRaceToJson(SyncActiveRace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'started_by_player_id': instance.startedByPlayerId,
      'race_config': instance.raceConfig,
      'status': _$ActiveRaceStatusEnumMap[instance.status]!,
      'current_round': instance.currentRound,
      'started_at': instance.startedAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
    };

const _$ActiveRaceStatusEnumMap = {
  ActiveRaceStatus.waiting: 'waiting',
  ActiveRaceStatus.countdown: 'countdown',
  ActiveRaceStatus.active: 'active',
  ActiveRaceStatus.completed: 'completed',
  ActiveRaceStatus.cancelled: 'cancelled',
};
