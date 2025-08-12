import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'player.dart';
import 'race_result.dart';
import 'wikipedia_page.dart';

part 'tournament.g.dart';

enum TournamentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

enum TournamentFormat {
  @JsonValue('single_elimination')
  singleElimination,
  @JsonValue('double_elimination')
  doubleElimination,
  @JsonValue('round_robin')
  roundRobin,
  @JsonValue('swiss')
  swiss,
}

@JsonSerializable()
class TournamentMatch {
  final String id;
  final String tournamentId;
  final int round;
  final int matchNumber;
  final List<String> participantIds;
  final String? winnerId;
  final RaceResult? raceResult;
  final DateTime? scheduledTime;
  final DateTime? completedTime;
  final Map<String, dynamic> metadata;

  TournamentMatch({
    String? id,
    required this.tournamentId,
    required this.round,
    required this.matchNumber,
    required this.participantIds,
    this.winnerId,
    this.raceResult,
    this.scheduledTime,
    this.completedTime,
    this.metadata = const {},
  }) : id = id ?? const Uuid().v4();

  bool get isCompleted => winnerId != null && raceResult != null;
  bool get isInProgress => winnerId == null && raceResult != null;
  bool get isPending => winnerId == null && raceResult == null;

  TournamentMatch copyWith({
    String? winnerId,
    RaceResult? raceResult,
    DateTime? completedTime,
    Map<String, dynamic>? metadata,
  }) {
    return TournamentMatch(
      id: id,
      tournamentId: tournamentId,
      round: round,
      matchNumber: matchNumber,
      participantIds: participantIds,
      winnerId: winnerId ?? this.winnerId,
      raceResult: raceResult ?? this.raceResult,
      scheduledTime: scheduledTime,
      completedTime: completedTime ?? this.completedTime,
      metadata: metadata ?? this.metadata,
    );
  }

  factory TournamentMatch.fromJson(Map<String, dynamic> json) => _$TournamentMatchFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentMatchToJson(this);
}

@JsonSerializable()
class TournamentBracket {
  final String tournamentId;
  final TournamentFormat format;
  final List<TournamentMatch> matches;
  final Map<int, List<String>> roundParticipants;
  final Map<String, int> participantSeeds;

  const TournamentBracket({
    required this.tournamentId,
    required this.format,
    required this.matches,
    required this.roundParticipants,
    required this.participantSeeds,
  });

  List<TournamentMatch> getMatchesForRound(int round) {
    return matches.where((match) => match.round == round).toList()
      ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
  }

  int get totalRounds => matches.isEmpty ? 0 : matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
  
  List<TournamentMatch> get completedMatches => matches.where((match) => match.isCompleted).toList();
  List<TournamentMatch> get pendingMatches => matches.where((match) => match.isPending).toList();
  List<TournamentMatch> get inProgressMatches => matches.where((match) => match.isInProgress).toList();

  factory TournamentBracket.fromJson(Map<String, dynamic> json) => _$TournamentBracketFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentBracketToJson(this);
}

@JsonSerializable()
class Tournament {
  final String id;
  final String name;
  final String description;
  final String organizerId;
  final TournamentFormat format;
  final TournamentStatus status;
  final List<Player> participants;
  final int maxParticipants;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<WikipediaPage> raceChallenges;
  final TournamentBracket? bracket;
  final String? winnerId;
  final Map<String, dynamic> settings;

  Tournament({
    String? id,
    required this.name,
    required this.description,
    required this.organizerId,
    required this.format,
    this.status = TournamentStatus.pending,
    required this.participants,
    required this.maxParticipants,
    DateTime? createdAt,
    this.startTime,
    this.endTime,
    this.raceChallenges = const [],
    this.bracket,
    this.winnerId,
    this.settings = const {},
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Player? get winner => winnerId != null 
      ? participants.cast<Player?>().firstWhere((p) => p?.id == winnerId, orElse: () => null)
      : null;

  Player get organizer => participants.firstWhere((p) => p.id == organizerId);

  bool get canStart => participants.length >= 2 && status == TournamentStatus.pending;
  bool get isActive => status == TournamentStatus.active;
  bool get isCompleted => status == TournamentStatus.completed;
  bool get isFull => participants.length >= maxParticipants;
  
  int get currentRound {
    if (bracket == null) return 0;
    final inProgress = bracket!.inProgressMatches;
    final completed = bracket!.completedMatches;
    
    if (inProgress.isNotEmpty) {
      return inProgress.first.round;
    } else if (completed.isNotEmpty) {
      return completed.map((m) => m.round).reduce((a, b) => a > b ? a : b) + 1;
    } else {
      return 1;
    }
  }

  Duration? get totalDuration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  Tournament copyWith({
    String? name,
    String? description,
    TournamentStatus? status,
    List<Player>? participants,
    DateTime? startTime,
    DateTime? endTime,
    List<WikipediaPage>? raceChallenges,
    TournamentBracket? bracket,
    String? winnerId,
    Map<String, dynamic>? settings,
  }) {
    return Tournament(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      organizerId: organizerId,
      format: format,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants,
      createdAt: createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      raceChallenges: raceChallenges ?? this.raceChallenges,
      bracket: bracket ?? this.bracket,
      winnerId: winnerId ?? this.winnerId,
      settings: settings ?? this.settings,
    );
  }

  factory Tournament.fromJson(Map<String, dynamic> json) => _$TournamentFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tournament && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class TournamentInvitation {
  final String id;
  final String tournamentId;
  final String inviteeId;
  final String inviterId;
  final DateTime sentAt;
  final DateTime? respondedAt;
  final bool? accepted;
  final String? message;

  TournamentInvitation({
    String? id,
    required this.tournamentId,
    required this.inviteeId,
    required this.inviterId,
    DateTime? sentAt,
    this.respondedAt,
    this.accepted,
    this.message,
  })  : id = id ?? const Uuid().v4(),
        sentAt = sentAt ?? DateTime.now();

  bool get isPending => accepted == null;
  bool get isAccepted => accepted == true;
  bool get isDeclined => accepted == false;

  TournamentInvitation copyWith({
    DateTime? respondedAt,
    bool? accepted,
  }) {
    return TournamentInvitation(
      id: id,
      tournamentId: tournamentId,
      inviteeId: inviteeId,
      inviterId: inviterId,
      sentAt: sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
      accepted: accepted ?? this.accepted,
      message: message,
    );
  }

  factory TournamentInvitation.fromJson(Map<String, dynamic> json) => _$TournamentInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentInvitationToJson(this);
}