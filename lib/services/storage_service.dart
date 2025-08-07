import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/group.dart';
import '../models/race_result.dart';

class StorageService {
  static const String _groupsKey = 'groups';
  static const String _raceResultsKey = 'race_results';

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
}