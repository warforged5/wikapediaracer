// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
  id: json['id'] as String?,
  name: json['name'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
  totalLosses: (json['totalLosses'] as num?)?.toInt() ?? 0,
  totalRaces: (json['totalRaces'] as num?)?.toInt() ?? 0,
  averageTime: (json['averageTime'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'createdAt': instance.createdAt.toIso8601String(),
  'totalWins': instance.totalWins,
  'totalLosses': instance.totalLosses,
  'totalRaces': instance.totalRaces,
  'averageTime': instance.averageTime,
};
