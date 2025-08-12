// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentMatch _$TournamentMatchFromJson(Map<String, dynamic> json) =>
    TournamentMatch(
      id: json['id'] as String?,
      tournamentId: json['tournamentId'] as String,
      round: (json['round'] as num).toInt(),
      matchNumber: (json['matchNumber'] as num).toInt(),
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      winnerId: json['winnerId'] as String?,
      raceResult: json['raceResult'] == null
          ? null
          : RaceResult.fromJson(json['raceResult'] as Map<String, dynamic>),
      scheduledTime: json['scheduledTime'] == null
          ? null
          : DateTime.parse(json['scheduledTime'] as String),
      completedTime: json['completedTime'] == null
          ? null
          : DateTime.parse(json['completedTime'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TournamentMatchToJson(TournamentMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'round': instance.round,
      'matchNumber': instance.matchNumber,
      'participantIds': instance.participantIds,
      'winnerId': instance.winnerId,
      'raceResult': instance.raceResult,
      'scheduledTime': instance.scheduledTime?.toIso8601String(),
      'completedTime': instance.completedTime?.toIso8601String(),
      'metadata': instance.metadata,
    };

TournamentBracket _$TournamentBracketFromJson(Map<String, dynamic> json) =>
    TournamentBracket(
      tournamentId: json['tournamentId'] as String,
      format: $enumDecode(_$TournamentFormatEnumMap, json['format']),
      matches: (json['matches'] as List<dynamic>)
          .map((e) => TournamentMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      roundParticipants: (json['roundParticipants'] as Map<String, dynamic>)
          .map(
            (k, e) => MapEntry(
              int.parse(k),
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ),
      participantSeeds: Map<String, int>.from(json['participantSeeds'] as Map),
    );

Map<String, dynamic> _$TournamentBracketToJson(TournamentBracket instance) =>
    <String, dynamic>{
      'tournamentId': instance.tournamentId,
      'format': _$TournamentFormatEnumMap[instance.format]!,
      'matches': instance.matches,
      'roundParticipants': instance.roundParticipants.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'participantSeeds': instance.participantSeeds,
    };

const _$TournamentFormatEnumMap = {
  TournamentFormat.singleElimination: 'single_elimination',
  TournamentFormat.doubleElimination: 'double_elimination',
  TournamentFormat.roundRobin: 'round_robin',
  TournamentFormat.swiss: 'swiss',
};

Tournament _$TournamentFromJson(Map<String, dynamic> json) => Tournament(
  id: json['id'] as String?,
  name: json['name'] as String,
  description: json['description'] as String,
  organizerId: json['organizerId'] as String,
  format: $enumDecode(_$TournamentFormatEnumMap, json['format']),
  status:
      $enumDecodeNullable(_$TournamentStatusEnumMap, json['status']) ??
      TournamentStatus.pending,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => Player.fromJson(e as Map<String, dynamic>))
      .toList(),
  maxParticipants: (json['maxParticipants'] as num).toInt(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  startTime: json['startTime'] == null
      ? null
      : DateTime.parse(json['startTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  raceChallenges:
      (json['raceChallenges'] as List<dynamic>?)
          ?.map((e) => WikipediaPage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  bracket: json['bracket'] == null
      ? null
      : TournamentBracket.fromJson(json['bracket'] as Map<String, dynamic>),
  winnerId: json['winnerId'] as String?,
  settings: json['settings'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$TournamentToJson(Tournament instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'organizerId': instance.organizerId,
      'format': _$TournamentFormatEnumMap[instance.format]!,
      'status': _$TournamentStatusEnumMap[instance.status]!,
      'participants': instance.participants,
      'maxParticipants': instance.maxParticipants,
      'createdAt': instance.createdAt.toIso8601String(),
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'raceChallenges': instance.raceChallenges,
      'bracket': instance.bracket,
      'winnerId': instance.winnerId,
      'settings': instance.settings,
    };

const _$TournamentStatusEnumMap = {
  TournamentStatus.pending: 'pending',
  TournamentStatus.active: 'active',
  TournamentStatus.completed: 'completed',
  TournamentStatus.cancelled: 'cancelled',
};

TournamentInvitation _$TournamentInvitationFromJson(
  Map<String, dynamic> json,
) => TournamentInvitation(
  id: json['id'] as String?,
  tournamentId: json['tournamentId'] as String,
  inviteeId: json['inviteeId'] as String,
  inviterId: json['inviterId'] as String,
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  respondedAt: json['respondedAt'] == null
      ? null
      : DateTime.parse(json['respondedAt'] as String),
  accepted: json['accepted'] as bool?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$TournamentInvitationToJson(
  TournamentInvitation instance,
) => <String, dynamic>{
  'id': instance.id,
  'tournamentId': instance.tournamentId,
  'inviteeId': instance.inviteeId,
  'inviterId': instance.inviterId,
  'sentAt': instance.sentAt.toIso8601String(),
  'respondedAt': instance.respondedAt?.toIso8601String(),
  'accepted': instance.accepted,
  'message': instance.message,
};
