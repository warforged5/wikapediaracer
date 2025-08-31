import 'package:json_annotation/json_annotation.dart';

part 'sync_player.g.dart';

@JsonSerializable()
class SyncPlayer {
  final String id;
  @JsonKey(name: 'group_id')
  final String groupId;
  final String name;
  @JsonKey(name: 'device_id')
  final String? deviceId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'total_wins')
  final int totalWins;
  @JsonKey(name: 'total_losses')
  final int totalLosses;
  @JsonKey(name: 'total_races')
  final int totalRaces;
  @JsonKey(name: 'average_time_seconds')
  final double averageTimeSeconds;

  const SyncPlayer({
    required this.id,
    required this.groupId,
    required this.name,
    this.deviceId,
    required this.createdAt,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalRaces = 0,
    this.averageTimeSeconds = 0.0,
  });

  SyncPlayer copyWith({
    String? id,
    String? groupId,
    String? name,
    String? deviceId,
    DateTime? createdAt,
    int? totalWins,
    int? totalLosses,
    int? totalRaces,
    double? averageTimeSeconds,
  }) {
    return SyncPlayer(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      totalRaces: totalRaces ?? this.totalRaces,
      averageTimeSeconds: averageTimeSeconds ?? this.averageTimeSeconds,
    );
  }

  double get winRate => totalRaces > 0 ? totalWins / totalRaces : 0.0;
  
  Duration get averageTime => Duration(seconds: averageTimeSeconds.round());

  factory SyncPlayer.fromJson(Map<String, dynamic> json) => _$SyncPlayerFromJson(json);
  Map<String, dynamic> toJson() => _$SyncPlayerToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncPlayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}