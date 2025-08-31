import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/group.dart';
import '../models/race_result.dart';
import '../models/player.dart';
import '../models/custom_list.dart';

class StorageService {
  static const String _groupsKey = 'groups';
  static const String _raceResultsKey = 'race_results';
  static const String _currentPlayerKey = 'current_player';
  static const String _customListsKey = 'custom_lists';
  static const String _playersKey = 'players';
  static const String _deviceIdKey = 'device_id';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Group>> getGroups() async {
    await init();
    final groupsJson = _prefs?.getString(_groupsKey);
    if (groupsJson == null) return [];
    
    final List<dynamic> groupsList = jsonDecode(groupsJson);
    return groupsList.map((json) => Group.fromJson(json)).toList();
  }

  Future<void> saveGroups(List<Group> groups) async {
    await init();
    final groupsJson = jsonEncode(groups.map((g) => g.toJson()).toList());
    await _prefs?.setString(_groupsKey, groupsJson);
  }

  Future<void> saveGroup(Group group) async {
    final groups = await getGroups();
    final index = groups.indexWhere((g) => g.id == group.id);
    
    if (index >= 0) {
      groups[index] = group;
    } else {
      groups.add(group);
    }
    
    await saveGroups(groups);
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = await getGroups();
    groups.removeWhere((g) => g.id == groupId);
    await saveGroups(groups);
    
    // Also delete race results for this group
    final results = await getRaceResults();
    results.removeWhere((r) => r.groupId == groupId);
    await saveRaceResults(results);
  }

  Future<List<RaceResult>> getRaceResults() async {
    await init();
    final resultsJson = _prefs?.getString(_raceResultsKey);
    if (resultsJson == null) return [];
    
    final List<dynamic> resultsList = jsonDecode(resultsJson);
    return resultsList.map((json) => RaceResult.fromJson(json)).toList();
  }

  Future<void> saveRaceResults(List<RaceResult> results) async {
    await init();
    final resultsJson = jsonEncode(results.map((r) => r.toJson()).toList());
    await _prefs?.setString(_raceResultsKey, resultsJson);
  }

  Future<void> saveRaceResult(RaceResult result) async {
    final results = await getRaceResults();
    results.add(result);
    await saveRaceResults(results);
  }

  Future<List<RaceResult>> getGroupRaceResults(String groupId) async {
    final results = await getRaceResults();
    return results.where((r) => r.groupId == groupId).toList();
  }

  Future<Map<String, dynamic>> exportGroupData(String groupId) async {
    final groups = await getGroups();
    final group = groups.firstWhere((g) => g.id == groupId);
    final raceResults = await getGroupRaceResults(groupId);
    
    return {
      'group': group.toJson(),
      'race_results': raceResults.map((r) => r.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
    };
  }

  Future<void> shareGroupData(String groupId, String groupName) async {
    try {
      final data = await exportGroupData(groupId);
      final jsonString = jsonEncode(data);
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/wikipedia_race_$groupName.json');
      await file.writeAsString(jsonString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Wikipedia Race group data for $groupName',
        subject: 'Wikipedia Race Export',
      );
    } catch (e) {
      throw Exception('Failed to export group data: $e');
    }
  }

  Future<void> clearAllData() async {
    await init();
    await _prefs?.clear();
  }

  Future<Map<String, int>> getPlayerStats(String playerId) async {
    final results = await getRaceResults();
    int wins = 0;
    int totalRaces = 0;
    
    for (final result in results) {
      if (result.participants.any((p) => p.id == playerId)) {
        totalRaces++;
        if (result.winnerId == playerId) {
          wins++;
        }
      }
    }
    
    return {
      'wins': wins,
      'totalRaces': totalRaces,
      'losses': totalRaces - wins,
    };
  }

  // Current Player Methods
  Future<Player?> getCurrentPlayer() async {
    await init();
    final playerJson = _prefs?.getString(_currentPlayerKey);
    if (playerJson == null) return null;
    
    try {
      final playerMap = jsonDecode(playerJson);
      return Player.fromJson(playerMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> setCurrentPlayer(Player player) async {
    await init();
    final playerJson = jsonEncode(player.toJson());
    await _prefs?.setString(_currentPlayerKey, playerJson);
  }

  Future<void> clearCurrentPlayer() async {
    await init();
    await _prefs?.remove(_currentPlayerKey);
  }

  // Player Storage Methods
  Future<List<Player>> getPlayers() async {
    await init();
    final playersJson = _prefs?.getString(_playersKey);
    if (playersJson == null) return [];
    
    final List<dynamic> playersList = jsonDecode(playersJson);
    return playersList.map((json) => Player.fromJson(json)).toList();
  }

  Future<void> savePlayers(List<Player> players) async {
    await init();
    final playersJson = jsonEncode(players.map((p) => p.toJson()).toList());
    await _prefs?.setString(_playersKey, playersJson);
  }

  Future<void> savePlayer(Player player) async {
    final players = await getPlayers();
    final index = players.indexWhere((p) => p.id == player.id);
    
    if (index >= 0) {
      players[index] = player;
    } else {
      players.add(player);
    }
    
    await savePlayers(players);
  }

  Future<Player?> getPlayer(String playerId) async {
    final players = await getPlayers();
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  Future<void> deletePlayer(String playerId) async {
    final players = await getPlayers();
    players.removeWhere((p) => p.id == playerId);
    await savePlayers(players);
  }

  // Generic Data Storage Methods
  Future<dynamic> getData(String key) async {
    await init();
    final jsonData = _prefs?.getString(key);
    if (jsonData == null) return null;
    
    try {
      return jsonDecode(jsonData);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveData(String key, dynamic data) async {
    await init();
    final jsonData = jsonEncode(data);
    await _prefs?.setString(key, jsonData);
  }

  Future<void> removeData(String key) async {
    await init();
    await _prefs?.remove(key);
  }

  // Device ID Methods
  Future<String?> getDeviceId() async {
    await init();
    return _prefs?.getString(_deviceIdKey);
  }

  Future<void> saveDeviceId(String deviceId) async {
    await init();
    await _prefs?.setString(_deviceIdKey, deviceId);
  }

  // Custom List Methods
  Future<List<CustomList>> getCustomLists() async {
    await init();
    final listsJson = _prefs?.getString(_customListsKey);
    if (listsJson == null) return [];
    
    final List<dynamic> listsList = jsonDecode(listsJson);
    return listsList.map((json) => CustomList.fromJson(json)).toList();
  }

  Future<void> saveCustomLists(List<CustomList> lists) async {
    await init();
    final listsJson = jsonEncode(lists.map((l) => l.toJson()).toList());
    await _prefs?.setString(_customListsKey, listsJson);
  }

  Future<void> saveCustomList(CustomList customList) async {
    final lists = await getCustomLists();
    final index = lists.indexWhere((l) => l.id == customList.id);
    
    if (index >= 0) {
      lists[index] = customList;
    } else {
      lists.add(customList);
    }
    
    await saveCustomLists(lists);
  }

  Future<void> deleteCustomList(String listId) async {
    final lists = await getCustomLists();
    lists.removeWhere((l) => l.id == listId);
    await saveCustomLists(lists);
  }

  Future<CustomList?> getCustomList(String listId) async {
    final lists = await getCustomLists();
    try {
      return lists.firstWhere((l) => l.id == listId);
    } catch (e) {
      return null;
    }
  }

  // Full Data Export/Import Methods
  Future<Map<String, dynamic>> exportAllData() async {
    await init();
    final allData = <String, dynamic>{};
    
    // Get all shared preferences keys
    final prefs = _prefs!;
    final keys = prefs.getKeys();
    
    // Export all data
    for (final key in keys) {
      final value = prefs.get(key);
      if (value is String) {
        try {
          // Try to parse as JSON, if it fails, keep as string
          allData[key] = jsonDecode(value);
        } catch (e) {
          allData[key] = value;
        }
      } else {
        allData[key] = value;
      }
    }
    
    return {
      'data': allData,
      'exported_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'export_type': 'full_backup',
    };
  }

  Future<void> importAllData(Map<String, dynamic> importData) async {
    await init();
    final prefs = _prefs!;
    
    if (!importData.containsKey('data')) {
      throw Exception('Invalid import data format');
    }
    
    final data = importData['data'] as Map<String, dynamic>;
    
    // Clear existing data first
    await prefs.clear();
    
    // Import all data
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else {
        // Convert complex objects back to JSON strings
        await prefs.setString(key, jsonEncode(value));
      }
    }
  }

  Future<void> shareAllData() async {
    try {
      final data = await exportAllData();
      final jsonString = jsonEncode(data);
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/wikipedia_racer_backup_$timestamp.json');
      await file.writeAsString(jsonString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Wikipedia Racer - Full Data Backup',
        subject: 'Wikipedia Racer Data Export',
      );
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }
}