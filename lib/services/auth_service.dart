import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/group.dart';
import '../models/custom_list.dart';
import '../models/achievement.dart';
import 'storage_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  SupabaseClient get _client => Supabase.instance.client;
  
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
  
  UserProfile? _currentProfile;
  UserProfile? get currentProfile => _currentProfile;

  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  StreamSubscription<AuthState>? _authSubscription;

  /// Initialize auth service and listen to auth changes
  Future<void> initialize() async {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      _authStateController.add(data);
      _handleAuthStateChange(data);
    });

    // Load current user profile if signed in
    if (isSignedIn) {
      await _loadUserProfile();
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _authStateController.close();
  }

  void _handleAuthStateChange(AuthState data) async {
    if (data.event == AuthChangeEvent.signedIn && data.session?.user != null) {
      await _loadUserProfile();
    } else if (data.event == AuthChangeEvent.signedOut) {
      _currentProfile = null;
    }
  }

  /// Create account with email and password
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
    bool migrateLocalData = true,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to create account');
    }

    // Create user profile
    final profile = await _createUserProfile(
      userId: response.user!.id,
      email: email,
      displayName: displayName,
      migrateLocalData: migrateLocalData,
    );

    return profile;
  }

  /// Sign in with email and password
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign in');
    }

    await _loadUserProfile();
    return _currentProfile!;
  }

  /// Create anonymous account (can be upgraded later)
  Future<UserProfile> signInAnonymously({
    required String displayName,
    bool migrateLocalData = true,
  }) async {
    final response = await _client.auth.signInAnonymously();

    if (response.user == null) {
      throw Exception('Failed to create anonymous account');
    }

    // Create user profile for anonymous user
    final profile = await _createUserProfile(
      userId: response.user!.id,
      displayName: displayName,
      migrateLocalData: migrateLocalData,
    );

    return profile;
  }

  /// Upgrade anonymous account to permanent account
  Future<UserProfile> upgradeAccount({
    required String email,
    required String password,
  }) async {
    if (!isAnonymous) {
      throw Exception('User is not anonymous');
    }

    // Update user with email and password
    final response = await _client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
      ),
    );

    if (response.user == null) {
      throw Exception('Failed to upgrade account');
    }

    // Update profile with email
    final updatedProfile = await _updateUserProfile(
      email: email,
    );

    return updatedProfile;
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentProfile = null;
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    if (!isSignedIn) return;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response != null) {
        _currentProfile = UserProfile.fromJson(response);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  /// Create user profile in database
  Future<UserProfile> _createUserProfile({
    required String userId,
    String? email,
    required String displayName,
    bool migrateLocalData = true,
  }) async {
    String? deviceId;
    if (migrateLocalData) {
      deviceId = await StorageService.instance.getDeviceId();
    }

    final profileData = {
      'id': userId,
      'email': email,
      'display_name': displayName,
      'device_id': deviceId,
      'local_data_migrated': false, // Will be set to true after migration
    };

    // Retry logic to handle RLS timing issues
    dynamic response;
    int retries = 0;
    const maxRetries = 3;
    
    while (retries < maxRetries) {
      try {
        response = await _client
            .from('user_profiles')
            .insert(profileData)
            .select()
            .single();
        break; // Success, exit retry loop
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          throw Exception('Failed to create user profile after $maxRetries attempts: $e');
        }
        
        // Wait a bit before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 500 * retries));
        print('Retrying user profile creation (attempt $retries): $e');
      }
    }

    final profile = UserProfile.fromJson(response);
    _currentProfile = profile;

    // Migrate local data if requested
    if (migrateLocalData && deviceId != null) {
      await _migrateLocalData();
    }

    return profile;
  }

  /// Update user profile
  Future<UserProfile> _updateUserProfile({
    String? email,
    String? displayName,
    Map<String, dynamic>? preferences,
    int? totalWins,
    int? totalLosses,
    int? totalRaces,
  }) async {
    if (!isSignedIn || _currentProfile == null) {
      throw Exception('User not signed in');
    }

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (email != null) updateData['email'] = email;
    if (displayName != null) updateData['display_name'] = displayName;
    if (preferences != null) updateData['preferences'] = preferences;
    if (totalWins != null) updateData['total_wins'] = totalWins;
    if (totalLosses != null) updateData['total_losses'] = totalLosses;
    if (totalRaces != null) updateData['total_races'] = totalRaces;

    final response = await _client
        .from('user_profiles')
        .update(updateData)
        .eq('id', _currentProfile!.id)
        .select()
        .single();

    final updatedProfile = UserProfile.fromJson(response);
    _currentProfile = updatedProfile;
    return updatedProfile;
  }

  /// Migrate local data to cloud
  Future<void> _migrateLocalData() async {
    if (!isSignedIn || _currentProfile == null) return;

    try {
      // Migrate local groups
      final localGroups = await StorageService.instance.getGroups();
      for (final group in localGroups) {
        await _client
            .from('user_local_groups')
            .insert({
              'user_id': _currentProfile!.id,
              'group_data': group.toJson(),
            });
      }

      // Migrate custom lists
      final customLists = await StorageService.instance.getCustomLists();
      for (final list in customLists) {
        await _client
            .from('user_custom_lists')
            .insert({
              'user_id': _currentProfile!.id,
              'list_data': list.toJson(),
            });
      }

      // Mark migration as complete
      await _client
          .from('user_profiles')
          .update({'local_data_migrated': true})
          .eq('id', _currentProfile!.id);

      _currentProfile = _currentProfile!.copyWith(localDataMigrated: true);
    } catch (e) {
      print('Error migrating local data: $e');
    }
  }

  /// Sync local groups to cloud
  Future<void> syncLocalGroups() async {
    if (!isSignedIn || _currentProfile == null) return;

    try {
      final localGroups = await StorageService.instance.getGroups();
      
      // Get existing cloud groups
      final existingResponse = await _client
          .from('user_local_groups')
          .select('group_data')
          .eq('user_id', _currentProfile!.id);

      final existingGroups = existingResponse
          .map<Group>((row) => Group.fromJson(row['group_data']))
          .toList();

      // Sync new/updated groups
      for (final group in localGroups) {
        final existingIndex = existingGroups.indexWhere((g) => g.id == group.id);
        
        if (existingIndex == -1) {
          // Insert new group
          await _client
              .from('user_local_groups')
              .insert({
                'user_id': _currentProfile!.id,
                'group_data': group.toJson(),
              });
        } else {
          // Update existing group
          await _client
              .from('user_local_groups')
              .update({
                'group_data': group.toJson(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', _currentProfile!.id)
              .eq('id', group.id);
        }
      }
    } catch (e) {
      print('Error syncing local groups: $e');
    }
  }

  /// Restore data from cloud
  Future<void> restoreFromCloud() async {
    if (!isSignedIn || _currentProfile == null) return;

    try {
      // Restore local groups
      final groupsResponse = await _client
          .from('user_local_groups')
          .select('group_data')
          .eq('user_id', _currentProfile!.id);

      final cloudGroups = groupsResponse
          .map<Group>((row) => Group.fromJson(row['group_data']))
          .toList();

      if (cloudGroups.isNotEmpty) {
        await StorageService.instance.saveGroups(cloudGroups);
      }

      // Restore custom lists
      final listsResponse = await _client
          .from('user_custom_lists')
          .select('list_data')
          .eq('user_id', _currentProfile!.id);

      final cloudLists = listsResponse
          .map<CustomList>((row) => CustomList.fromJson(row['list_data']))
          .toList();

      if (cloudLists.isNotEmpty) {
        await StorageService.instance.saveCustomLists(cloudLists);
      }
    } catch (e) {
      print('Error restoring from cloud: $e');
    }
  }

  /// Update user statistics
  Future<void> updateStats({
    required int totalWins,
    required int totalLosses,
    required int totalRaces,
  }) async {
    if (isSignedIn && _currentProfile != null) {
      await _updateUserProfile(
        totalWins: totalWins,
        totalLosses: totalLosses,
        totalRaces: totalRaces,
      );
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (isSignedIn && _currentProfile != null) {
      await _updateUserProfile(preferences: preferences);
    }
  }
}