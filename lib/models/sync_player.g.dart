// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncPlayer _$SyncPlayerFromJson(Map<String, dynamic> json) => SyncPlayer(
  id: json['id'] as String,
  groupId: json['group_id'] as String,
  name: json['name'] as String,
  deviceId: json['device_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  totalWins: (json['total_wins'] as num?)?.toInt() ?? 0,
  totalLosses: (json['total_losses'] as num?)?.toInt() ?? 0,
  totalRaces: (json['total_races'] as num?)?.toInt() ?? 0,
  averageTimeSeconds: (json['average_time_seconds'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$SyncPlayerToJson(SyncPlayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'name': instance.name,
      'device_id': instance.deviceId,
      'created_at': instance.createdAt.toIso8601String(),
      'total_wins': instance.totalWins,
      'total_losses': instance.totalLosses,
      'total_races': instance.totalRaces,
      'average_time_seconds': instance.averageTimeSeconds,
    };
