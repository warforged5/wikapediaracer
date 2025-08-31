import 'package:json_annotation/json_annotation.dart';

part 'sync_active_race.g.dart';

enum ActiveRaceStatus {
  waiting,
  countdown,
  active,
  completed,
  cancelled,
}

@JsonSerializable()
class SyncActiveRace {
  final String id;
  @JsonKey(name: 'group_id')
  final String groupId;
  @JsonKey(name: 'started_by_player_id')
  final String startedByPlayerId;
  @JsonKey(name: 'race_config')
  final Map<String, dynamic> raceConfig;
  final ActiveRaceStatus status;
  @JsonKey(name: 'current_round')
  final int currentRound;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  const SyncActiveRace({
    required this.id,
    required this.groupId,
    required this.startedByPlayerId,
    required this.raceConfig,
    this.status = ActiveRaceStatus.waiting,
    this.currentRound = 1,
    required this.startedAt,
    required this.expiresAt,
  });

  SyncActiveRace copyWith({
    String? id,
    String? groupId,
    String? startedByPlayerId,
    Map<String, dynamic>? raceConfig,
    ActiveRaceStatus? status,
    int? currentRound,
    DateTime? startedAt,
    DateTime? expiresAt,
  }) {
    return SyncActiveRace(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      startedByPlayerId: startedByPlayerId ?? this.startedByPlayerId,
      raceConfig: raceConfig ?? this.raceConfig,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == ActiveRaceStatus.active && !isExpired;

  factory SyncActiveRace.fromJson(Map<String, dynamic> json) => _$SyncActiveRaceFromJson(json);
  Map<String, dynamic> toJson() => _$SyncActiveRaceToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncActiveRace && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}