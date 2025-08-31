// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncGroup _$SyncGroupFromJson(Map<String, dynamic> json) => SyncGroup(
  id: json['id'] as String,
  name: json['name'] as String,
  groupCode: json['group_code'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  lastPlayedAt: DateTime.parse(json['last_played_at'] as String),
  totalRaces: (json['total_races'] as num?)?.toInt() ?? 0,
  isActive: json['is_active'] as bool? ?? true,
  createdByDeviceId: json['created_by_device_id'] as String?,
);

Map<String, dynamic> _$SyncGroupToJson(SyncGroup instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'group_code': instance.groupCode,
  'created_at': instance.createdAt.toIso8601String(),
  'last_played_at': instance.lastPlayedAt.toIso8601String(),
  'total_races': instance.totalRaces,
  'is_active': instance.isActive,
  'created_by_device_id': instance.createdByDeviceId,
};
