// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'race_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaceRound _$RaceRoundFromJson(Map<String, dynamic> json) => RaceRound(
  startPage: WikipediaPage.fromJson(json['startPage'] as Map<String, dynamic>),
  endPage: WikipediaPage.fromJson(json['endPage'] as Map<String, dynamic>),
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  winnerId: json['winnerId'] as String,
  roundNumber: (json['roundNumber'] as num).toInt(),
);

Map<String, dynamic> _$RaceRoundToJson(RaceRound instance) => <String, dynamic>{
  'startPage': instance.startPage,
  'endPage': instance.endPage,
  'duration': instance.duration.inMicroseconds,
  'winnerId': instance.winnerId,
  'roundNumber': instance.roundNumber,
};

RaceResult _$RaceResultFromJson(Map<String, dynamic> json) => RaceResult(
  id: json['id'] as String?,
  groupId: json['groupId'] as String?,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => Player.fromJson(e as Map<String, dynamic>))
      .toList(),
  rounds: (json['rounds'] as List<dynamic>)
      .map((e) => RaceRound.fromJson(e as Map<String, dynamic>))
      .toList(),
  winnerId: json['winnerId'] as String,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  totalDuration: Duration(microseconds: (json['totalDuration'] as num).toInt()),
  totalRounds: (json['totalRounds'] as num).toInt(),
);

Map<String, dynamic> _$RaceResultToJson(RaceResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'participants': instance.participants,
      'rounds': instance.rounds,
      'winnerId': instance.winnerId,
      'completedAt': instance.completedAt.toIso8601String(),
      'totalDuration': instance.totalDuration.inMicroseconds,
      'totalRounds': instance.totalRounds,
    };
