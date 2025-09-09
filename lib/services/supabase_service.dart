import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_group.dart';
import '../models/sync_player.dart';
import '../models/sync_active_race.dart';
import '../models/race_result.dart';
import '../models/player.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;
  
  // Device ID for tracking local players
  late String _deviceId;
  String get deviceId => _deviceId;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize Supabase service
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required String deviceId,
  }) async {
    if (_initialized) return;
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    _deviceId = deviceId;
    _initialized = true;
  }

  /// Generate a unique 6-character group code
  String _generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new synchronized group
  Future<SyncGroup> createGroup({
    required String name,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    String groupCode;
    int attempts = 0;
    const maxAttempts = 10;
    
    // Generate unique group code
    do {
      groupCode = _generateGroupCode();
      attempts++;
      
      if (attempts > maxAttempts) {
        throw Exception('Failed to generate unique group code after $maxAttempts attempts');
      }
      
      // Check if code already exists
      final existing = await _client
          .from('sync_groups')
          .select('id')
          .eq('group_code', groupCode)
          .maybeSingle();
          
      if (existing == null) break;
    } while (true);

    final response = await _client
        .from('sync_groups')
        .insert({
          'name': name,
          'group_code': groupCode,
          'created_by_device_id': _deviceId,
        })
        .select()
        .single();

    return SyncGroup.fromJson(response);
  }

  /// Join a group using group code
  Future<SyncGroup?> joinGroup({
    required String groupCode,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    final response = await _client
        .from('sync_groups')
        .select()
        .eq('group_code', groupCode.toUpperCase())
        .eq('is_active', true)
        .maybeSingle();

    return response != null ? SyncGroup.fromJson(response) : null;
  }

  /// Add player to a synchronized group
  Future<SyncPlayer> addPlayerToGroup({
    required String groupId,
    required String playerName,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    // Check if player already exists in group
    final existing = await _client
        .from('sync_players')
        .select()
        .eq('group_id', groupId)
        .eq('name', playerName)
        .maybeSingle();
        
    if (existing != null) {
      // Update device_id for existing player if different
      if (existing['device_id'] != _deviceId) {
        final updated = await _client
            .from('sync_players')
            .update({'device_id': _deviceId})
            .eq('id', existing['id'])
            .select()
            .single();
        return SyncPlayer.fromJson(updated);
      }
      return SyncPlayer.fromJson(existing);
    }

    final response = await _client
        .from('sync_players')
        .insert({
          'group_id': groupId,
          'name': playerName,
          'device_id': _deviceId,
        })
        .select()
        .single();

    return SyncPlayer.fromJson(response);
  }

  /// Manually add a player to a synchronized group (without device association)
  Future<SyncPlayer> addPlayerToGroupManually({
    required String groupId,
    required String playerName,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    // Check if player already exists in group
    final existing = await _client
        .from('sync_players')
        .select()
        .eq('group_id', groupId)
        .eq('name', playerName)
        .maybeSingle();
        
    if (existing != null) {
      throw Exception('Player "$playerName" already exists in this group');
    }

    final response = await _client
        .from('sync_players')
        .insert({
          'group_id': groupId,
          'name': playerName,
          'device_id': null, // No device association for manually added players
        })
        .select()
        .single();

    return SyncPlayer.fromJson(response);
  }

  /// Get all players in a group
  Future<List<SyncPlayer>> getGroupPlayers(String groupId) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    final response = await _client
        .from('sync_players')
        .select()
        .eq('group_id', groupId)
        .order('created_at');

    return response.map<SyncPlayer>((json) => SyncPlayer.fromJson(json)).toList();
  }

  /// Get group by ID
  Future<SyncGroup?> getGroup(String groupId) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    final response = await _client
        .from('sync_groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    return response != null ? SyncGroup.fromJson(response) : null;
  }

  /// Update group stats
  Future<void> updateGroupStats({
    required String groupId,
    required int totalRaces,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    await _client
        .from('sync_groups')
        .update({
          'total_races': totalRaces,
          'last_played_at': DateTime.now().toIso8601String(),
        })
        .eq('id', groupId);
  }

  /// Update player stats
  Future<void> updatePlayerStats({
    required String playerId,
    required int totalWins,
    required int totalLosses,
    required int totalRaces,
    required double averageTimeSeconds,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    await _client
        .from('sync_players')
        .update({
          'total_wins': totalWins,
          'total_losses': totalLosses,
          'total_races': totalRaces,
          'average_time_seconds': averageTimeSeconds,
        })
        .eq('id', playerId);
  }

  /// Start a new active race
  Future<SyncActiveRace> startActiveRace({
    required String groupId,
    required String startedByPlayerId,
    required Map<String, dynamic> raceConfig,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    // Remove any existing active race for this group
    await _client
        .from('sync_active_races')
        .delete()
        .eq('group_id', groupId);

    final response = await _client
        .from('sync_active_races')
        .insert({
          'group_id': groupId,
          'started_by_player_id': startedByPlayerId,
          'race_config': raceConfig,
          'expires_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        })
        .select()
        .single();

    return SyncActiveRace.fromJson(response);
  }

  /// Get active race for group
  Future<SyncActiveRace?> getActiveRace(String groupId) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    final response = await _client
        .from('sync_active_races')
        .select()
        .eq('group_id', groupId)
        .maybeSingle();

    return response != null ? SyncActiveRace.fromJson(response) : null;
  }

  /// Update active race status
  Future<void> updateActiveRace({
    required String raceId,
    ActiveRaceStatus? status,
    int? currentRound,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    final updateData = <String, dynamic>{};
    if (status != null) updateData['status'] = status.name;
    if (currentRound != null) updateData['current_round'] = currentRound;
    
    if (updateData.isEmpty) return;

    await _client
        .from('sync_active_races')
        .update(updateData)
        .eq('id', raceId);
  }

  /// Convert a local group to an online synchronized group
  Future<SyncGroup> convertLocalGroupToOnline({
    required String localGroupName,
    required List<Player> localPlayers,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    // Create the synchronized group
    final syncGroup = await createGroup(name: localGroupName);
    
    // Add all local players to the synchronized group
    for (final player in localPlayers) {
      await addPlayerToGroup(
        groupId: syncGroup.id,
        playerName: player.name,
      );
    }
    
    return syncGroup;
  }

  /// Complete active race and save results
  Future<void> completeRace({
    required String raceId,
    required RaceResult raceResult,
    required List<SyncPlayer> groupPlayers,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    // Find winner in sync players
    final winner = groupPlayers.firstWhere(
      (p) => p.name == raceResult.winner.name,
    );

    // Save race result
    final raceResultResponse = await _client
        .from('sync_race_results')
        .insert({
          'group_id': winner.groupId,
          'winner_id': winner.id,
          'total_duration_seconds': raceResult.totalDuration.inSeconds,
          'total_rounds': raceResult.rounds.length,
          'race_data': raceResult.toJson(),
          'completed_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    // Save individual rounds
    for (final round in raceResult.rounds) {
      final roundWinner = groupPlayers.firstWhere(
        (p) => p.id == round.winnerId,
      );
      
      await _client
          .from('sync_race_rounds')
          .insert({
            'race_result_id': raceResultResponse['id'],
            'round_number': round.roundNumber,
            'winner_id': roundWinner.id,
            'start_page_title': round.startPage.title,
            'end_page_title': round.endPage.title,
            'duration_seconds': round.duration.inSeconds,
          });
    }

    // Remove active race
    await _client
        .from('sync_active_races')
        .delete()
        .eq('id', raceId);
  }

  /// Get race history for group
  Future<List<Map<String, dynamic>>> getGroupRaceHistory(String groupId) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    final response = await _client
        .from('sync_race_results')
        .select('''
          *,
          winner:sync_players!winner_id(name),
          rounds:sync_race_rounds(*)
        ''')
        .eq('group_id', groupId)
        .order('completed_at', ascending: false);

    return response;
  }

  /// Subscribe to group changes
  RealtimeChannel subscribeToGroup({
    required String groupId,
    required Function(List<SyncPlayer>) onPlayersChanged,
    required Function(SyncActiveRace?) onActiveRaceChanged,
  }) {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    final channel = _client.channel('group_$groupId');

    // Subscribe to player changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sync_players',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: groupId,
      ),
      callback: (_) async {
        final players = await getGroupPlayers(groupId);
        onPlayersChanged(players);
      },
    );

    // Subscribe to active race changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sync_active_races',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: groupId,
      ),
      callback: (_) async {
        final activeRace = await getActiveRace(groupId);
        onActiveRaceChanged(activeRace);
      },
    );

    channel.subscribe();
    return channel;
  }

  /// Leave group (remove player)
  Future<void> leaveGroup({
    required String groupId,
    required String playerName,
  }) async {
    if (!_initialized) throw Exception('Supabase service not initialized');
    
    await _client
        .from('sync_players')
        .delete()
        .eq('group_id', groupId)
        .eq('name', playerName)
        .eq('device_id', _deviceId);
  }

  /// Check if service is available
  Future<bool> checkConnection() async {
    if (!_initialized) return false;
    
    try {
      await _client
          .from('sync_groups')
          .select('count')
          .limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}