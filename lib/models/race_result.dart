import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'player.dart';
import 'wikipedia_page.dart';

part 'race_result.g.dart';

@JsonSerializable()
class RaceRound {
  final WikipediaPage startPage;
  final WikipediaPage endPage;
  final Duration duration;
  final String winnerId;
  final int roundNumber;

  const RaceRound({
    required this.startPage,
    required this.endPage,
    required this.duration,
    required this.winnerId,
    required this.roundNumber,
  });

  factory RaceRound.fromJson(Map<String, dynamic> json) => _$RaceRoundFromJson(json);
  Map<String, dynamic> toJson() => _$RaceRoundToJson(this);
}

@JsonSerializable()
class RaceResult {
  final String id;
  final String? groupId;
  final List<Player> participants;
  final List<RaceRound> rounds;
  final String winnerId;
  final DateTime completedAt;
  final Duration totalDuration;
  final int totalRounds;

  RaceResult({
    String? id,
    this.groupId,
    required this.participants,
    required this.rounds,
    required this.winnerId,
    DateTime? completedAt,
    required this.totalDuration,
    required this.totalRounds,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now();

  Player get winner => participants.firstWhere((p) => p.id == winnerId);

  Map<String, int> get playerWins {
    final wins = <String, int>{};
    for (final player in participants) {
      wins[player.id] = 0;
    }
    for (final round in rounds) {
      wins[round.winnerId] = (wins[round.winnerId] ?? 0) + 1;
    }
    return wins;
  }

  factory RaceResult.fromJson(Map<String, dynamic> json) => _$RaceResultFromJson(json);
  Map<String, dynamic> toJson() => _$RaceResultToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RaceResult && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}