import 'package:json_annotation/json_annotation.dart';

part 'sync_group.g.dart';

@JsonSerializable()
class SyncGroup {
  final String id;
  final String name;
  @JsonKey(name: 'group_code')
  final String groupCode;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_played_at')
  final DateTime lastPlayedAt;
  @JsonKey(name: 'total_races')
  final int totalRaces;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by_device_id')
  final String? createdByDeviceId;

  const SyncGroup({
    required this.id,
    required this.name,
    required this.groupCode,
    required this.createdAt,
    required this.lastPlayedAt,
    this.totalRaces = 0,
    this.isActive = true,
    this.createdByDeviceId,
  });

  SyncGroup copyWith({
    String? id,
    String? name,
    String? groupCode,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int? totalRaces,
    bool? isActive,
    String? createdByDeviceId,
  }) {
    return SyncGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      groupCode: groupCode ?? this.groupCode,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalRaces: totalRaces ?? this.totalRaces,
      isActive: isActive ?? this.isActive,
      createdByDeviceId: createdByDeviceId ?? this.createdByDeviceId,
    );
  }

  factory SyncGroup.fromJson(Map<String, dynamic> json) => _$SyncGroupFromJson(json);
  Map<String, dynamic> toJson() => _$SyncGroupToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}