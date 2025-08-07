// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
  id: json['id'] as String?,
  name: json['name'] as String,
  players: (json['players'] as List<dynamic>?)
      ?.map((e) => Player.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  lastPlayedAt: json['lastPlayedAt'] == null
      ? null
      : DateTime.parse(json['lastPlayedAt'] as String),
  totalRaces: (json['totalRaces'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'players': instance.players,
  'createdAt': instance.createdAt.toIso8601String(),
  'lastPlayedAt': instance.lastPlayedAt.toIso8601String(),
  'totalRaces': instance.totalRaces,
};
