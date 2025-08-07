import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'player.g.dart';

@JsonSerializable()
class Player {
  final String id;
  final String name;
  final DateTime createdAt;
  final int totalWins;
  final int totalLosses;
  final int totalRaces;
  final double averageTime;

  Player({
    String? id,
    required this.name,
    DateTime? createdAt,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalRaces = 0,
    this.averageTime = 0.0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Player copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? totalWins,
    int? totalLosses,
    int? totalRaces,
    double? averageTime,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      totalRaces: totalRaces ?? this.totalRaces,
      averageTime: averageTime ?? this.averageTime,
    );
  }

  double get winRate => totalRaces > 0 ? totalWins / totalRaces : 0.0;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}