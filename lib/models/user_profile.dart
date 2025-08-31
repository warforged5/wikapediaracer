import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String? email;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'device_id')
  final String? deviceId;
  @JsonKey(name: 'local_data_migrated')
  final bool localDataMigrated;
  final Map<String, dynamic> preferences;
  @JsonKey(name: 'total_wins')
  final int totalWins;
  @JsonKey(name: 'total_losses')
  final int totalLosses;
  @JsonKey(name: 'total_races')
  final int totalRaces;

  const UserProfile({
    required this.id,
    this.email,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.deviceId,
    this.localDataMigrated = false,
    this.preferences = const {},
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalRaces = 0,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    bool? localDataMigrated,
    Map<String, dynamic>? preferences,
    int? totalWins,
    int? totalLosses,
    int? totalRaces,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      localDataMigrated: localDataMigrated ?? this.localDataMigrated,
      preferences: preferences ?? this.preferences,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      totalRaces: totalRaces ?? this.totalRaces,
    );
  }

  double get winRate => totalRaces > 0 ? totalWins / totalRaces : 0.0;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}