import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/race_result.dart';
import '../models/player.dart';

class SharingService {
  static const SharingService _instance = SharingService._internal();
  static const SharingService instance = _instance;
  const SharingService._internal();

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _generateRaceResultText(RaceResult result) {
    final winner = result.winner;
    final playerWins = result.playerWins;
    final totalTime = _formatDuration(result.totalDuration);
    
    final buffer = StringBuffer();
    buffer.writeln('🏆 Wikipedia Race Results! 🏆');
    buffer.writeln('');
    buffer.writeln('🥇 Winner: ${winner.name}');
    buffer.writeln('⏱️ Total Time: $totalTime');
    buffer.writeln('🏁 Rounds: ${result.rounds.length}');
    buffer.writeln('');
    
    if (result.participants.length > 1) {
      buffer.writeln('📊 Final Standings:');
      final sortedPlayers = result.participants
          .map((player) => MapEntry(player, playerWins[player.id] ?? 0))
          .toList()..sort((a, b) => b.value.compareTo(a.value));
      
      for (int i = 0; i < sortedPlayers.length; i++) {
        final player = sortedPlayers[i].key;
        final wins = sortedPlayers[i].value;
        final emoji = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}.';
        buffer.writeln('$emoji ${player.name} - $wins wins');
      }
      buffer.writeln('');
    }
    
    if (result.rounds.isNotEmpty) {
      buffer.writeln('🎯 Race Path:');
      for (final round in result.rounds.take(3)) { // Show first 3 rounds
        buffer.writeln('${round.startPage.title} → ${round.endPage.title}');
      }
      if (result.rounds.length > 3) {
        buffer.writeln('... and ${result.rounds.length - 3} more rounds!');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('Challenge me in Wikipedia Racer! 🚀');
    
    return buffer.toString();
  }

  String _generateTournamentResultText(String tournamentName, Player winner, List<Player> participants, Duration totalDuration) {
    final buffer = StringBuffer();
    buffer.writeln('🏆 TOURNAMENT CHAMPION! 🏆');
    buffer.writeln('');
    buffer.writeln('🎯 Tournament: $tournamentName');
    buffer.writeln('👑 Champion: ${winner.name}');
    buffer.writeln('⏱️ Tournament Duration: ${_formatDuration(totalDuration)}');
    buffer.writeln('👥 Participants: ${participants.length}');
    buffer.writeln('');
    buffer.writeln('Join the next Wikipedia Racer tournament! 🚀');
    
    return buffer.toString();
  }

  Future<void> shareRaceResult(RaceResult result, {String? customMessage}) async {
    try {
      final text = customMessage ?? _generateRaceResultText(result);
      
      if (kIsWeb) {
        // For web, we'll use the Share API if available, otherwise copy to clipboard
        await Share.share(text, subject: 'Wikipedia Race Results');
      } else {
        // For mobile platforms, use the native share dialog
        await Share.share(
          text,
          subject: 'Wikipedia Race Results - ${result.winner.name} wins!',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing race result: $e');
      }
      rethrow;
    }
  }

  Future<void> shareRaceChallenge(String challengerName, String? targetPage) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('🎯 Wikipedia Race Challenge! 🎯');
      buffer.writeln('');
      buffer.writeln('${challengerName} challenges you to a Wikipedia race!');
      if (targetPage != null) {
        buffer.writeln('🏁 Target: $targetPage');
      }
      buffer.writeln('');
      buffer.writeln('Think you can find the shortest path? Let\'s race! 🚀');
      buffer.writeln('Download Wikipedia Racer and accept the challenge!');
      
      await Share.share(
        buffer.toString(),
        subject: 'Wikipedia Race Challenge from $challengerName',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing race challenge: $e');
      }
      rethrow;
    }
  }

  Future<void> shareTournamentResult(
    String tournamentName,
    Player winner,
    List<Player> participants,
    Duration totalDuration, {
    String? customMessage,
  }) async {
    try {
      final text = customMessage ?? 
          _generateTournamentResultText(tournamentName, winner, participants, totalDuration);
      
      await Share.share(
        text,
        subject: 'Tournament Results - $tournamentName',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing tournament result: $e');
      }
      rethrow;
    }
  }

  Future<void> shareTournamentInvitation(String tournamentName, String organizerName, DateTime startTime) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('🏆 Tournament Invitation! 🏆');
      buffer.writeln('');
      buffer.writeln('🎯 Tournament: $tournamentName');
      buffer.writeln('👤 Organized by: $organizerName');
      buffer.writeln('⏰ Start Time: ${_formatDateTime(startTime)}');
      buffer.writeln('');
      buffer.writeln('Join the ultimate Wikipedia racing competition! 🚀');
      buffer.writeln('Download Wikipedia Racer and prove you\'re the fastest!');
      
      await Share.share(
        buffer.toString(),
        subject: 'Join the $tournamentName Tournament!',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing tournament invitation: $e');
      }
      rethrow;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else {
      return 'Starting soon!';
    }
  }

  Future<void> sharePersonalStats(Player player, List<RaceResult> recentRaces) async {
    try {
      final totalRaces = recentRaces.length;
      final wins = recentRaces.where((race) => race.winnerId == player.id).length;
      final winRate = totalRaces > 0 ? (wins / totalRaces * 100).toStringAsFixed(1) : '0';
      
      final buffer = StringBuffer();
      buffer.writeln('📊 My Wikipedia Racing Stats! 📊');
      buffer.writeln('');
      buffer.writeln('👤 Player: ${player.name}');
      buffer.writeln('🏁 Total Races: $totalRaces');
      buffer.writeln('🏆 Wins: $wins');
      buffer.writeln('📈 Win Rate: $winRate%');
      buffer.writeln('');
      buffer.writeln('Think you can beat my record? Challenge me! 🚀');
      buffer.writeln('Download Wikipedia Racer and let\'s race!');
      
      await Share.share(
        buffer.toString(),
        subject: '${player.name}\'s Wikipedia Racing Stats',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing personal stats: $e');
      }
      rethrow;
    }
  }
}