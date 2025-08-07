import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'player.dart';

part 'group.g.dart';

@JsonSerializable()
class Group {
  final String id;
  final String name;
  final List<Player> players;
  final DateTime createdAt;
  final DateTime lastPlayedAt;
  final int totalRaces;

  Group({
    String? id,
    required this.name,
    List<Player>? players,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    this.totalRaces = 0,
  })  : id = id ?? const Uuid().v4(),
        players = players ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastPlayedAt = lastPlayedAt ?? DateTime.now();

  Group copyWith({
    String? id,
    String? name,
    List<Player>? players,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int? totalRaces,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ?? List.from(this.players),
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalRaces: totalRaces ?? this.totalRaces,
    );
  }

  Group addPlayer(Player player) {
    if (players.any((p) => p.id == player.id)) {
      return this;
    }
    return copyWith(players: [...players, player]);
  }

  Group removePlayer(String playerId) {
    return copyWith(
      players: players.where((p) => p.id != playerId).toList(),
    );
  }

  Group updatePlayer(Player updatedPlayer) {
    final index = players.indexWhere((p) => p.id == updatedPlayer.id);
    if (index == -1) return this;
    
    final newPlayers = List<Player>.from(players);
    newPlayers[index] = updatedPlayer;
    return copyWith(players: newPlayers);
  }

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}