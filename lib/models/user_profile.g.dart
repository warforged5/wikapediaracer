// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  email: json['email'] as String?,
  displayName: json['display_name'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deviceId: json['device_id'] as String?,
  localDataMigrated: json['local_data_migrated'] as bool? ?? false,
  preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
  totalWins: (json['total_wins'] as num?)?.toInt() ?? 0,
  totalLosses: (json['total_losses'] as num?)?.toInt() ?? 0,
  totalRaces: (json['total_races'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'device_id': instance.deviceId,
      'local_data_migrated': instance.localDataMigrated,
      'preferences': instance.preferences,
      'total_wins': instance.totalWins,
      'total_losses': instance.totalLosses,
      'total_races': instance.totalRaces,
    };
