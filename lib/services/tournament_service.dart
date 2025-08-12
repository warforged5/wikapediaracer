import 'package:flutter/foundation.dart';
import '../models/tournament.dart';
import '../models/player.dart';
import '../models/race_result.dart';
import '../models/wikipedia_page.dart';
import 'storage_service.dart';

class TournamentService {
  static const TournamentService _instance = TournamentService._internal();
  static const TournamentService instance = _instance;
  const TournamentService._internal();

  static const String _tournamentsKey = 'tournaments';
  static const String _tournamentInvitationsKey = 'tournament_invitations';

  Future<List<Tournament>> getAllTournaments() async {
    try {
      final data = await StorageService.instance.getData(_tournamentsKey);
      if (data == null) return [];
      
      final List<dynamic> tournamentsList = data;
      return tournamentsList.map((json) => Tournament.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tournaments: $e');
      }
      return [];
    }
  }

  Future<Tournament?> getTournamentById(String id) async {
    final tournaments = await getAllTournaments();
    try {
      return tournaments.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Tournament>> getTournamentsByPlayer(String playerId) async {
    final tournaments = await getAllTournaments();
    return tournaments.where((t) => t.participants.any((p) => p.id == playerId)).toList();
  }

  Future<List<Tournament>> getActiveTournaments() async {
    final tournaments = await getAllTournaments();
    return tournaments.where((t) => t.status == TournamentStatus.active).toList();
  }

  Future<List<Tournament>> getPendingTournaments() async {
    final tournaments = await getAllTournaments();
    return tournaments.where((t) => t.status == TournamentStatus.pending).toList();
  }

  Future<Tournament> createTournament({
    required String name,
    required String description,
    required TournamentFormat format,
    required int maxParticipants,
    List<Player> initialParticipants = const [],
    List<WikipediaPage> raceChallenges = const [],
    DateTime? startTime,
    Map<String, dynamic> settings = const {},
  }) async {
    // Use the first participant as organizer if provided, otherwise create a default organizer
    String organizerId;
    List<Player> participants = [...initialParticipants];
    
    if (participants.isNotEmpty) {
      organizerId = participants.first.id;
    } else {
      // Create a default organizer player
      final organizer = Player(name: 'Tournament Organizer');
      participants.add(organizer);
      organizerId = organizer.id;
    }

    final tournament = Tournament(
      name: name,
      description: description,
      organizerId: organizerId,
      format: format,
      participants: participants,
      maxParticipants: maxParticipants,
      raceChallenges: raceChallenges,
      startTime: startTime,
      settings: settings,
    );

    await _saveTournament(tournament);
    return tournament;
  }

  Future<Tournament> joinTournament(String tournamentId, Player player) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) {
      throw Exception('Tournament not found');
    }

    if (tournament.isFull) {
      throw Exception('Tournament is full');
    }

    if (tournament.status != TournamentStatus.pending) {
      throw Exception('Tournament has already started');
    }

    if (tournament.participants.any((p) => p.id == player.id)) {
      throw Exception('Player is already in the tournament');
    }

    final updatedTournament = tournament.copyWith(
      participants: [...tournament.participants, player],
    );

    await _saveTournament(updatedTournament);
    return updatedTournament;
  }

  Future<Tournament> leaveTournament(String tournamentId, String playerId) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) {
      throw Exception('Tournament not found');
    }

    if (tournament.status != TournamentStatus.pending) {
      throw Exception('Cannot leave tournament after it has started');
    }

    final updatedParticipants = tournament.participants.where((p) => p.id != playerId).toList();
    
    final updatedTournament = tournament.copyWith(
      participants: updatedParticipants,
    );

    await _saveTournament(updatedTournament);
    return updatedTournament;
  }

  Future<Tournament> startTournament(String tournamentId) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) {
      throw Exception('Tournament not found');
    }

    if (!tournament.canStart) {
      throw Exception('Tournament cannot be started (needs at least 2 participants)');
    }

    final bracket = _generateBracket(tournament);
    
    final updatedTournament = tournament.copyWith(
      status: TournamentStatus.active,
      startTime: DateTime.now(),
      bracket: bracket,
    );

    await _saveTournament(updatedTournament);
    return updatedTournament;
  }

  Future<Tournament> submitMatchResult(String tournamentId, String matchId, RaceResult result) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) {
      throw Exception('Tournament not found');
    }

    if (tournament.bracket == null) {
      throw Exception('Tournament bracket not found');
    }

    final bracket = tournament.bracket!;
    final matchIndex = bracket.matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) {
      throw Exception('Match not found');
    }

    final match = bracket.matches[matchIndex];
    if (match.isCompleted) {
      throw Exception('Match is already completed');
    }

    final updatedMatch = match.copyWith(
      winnerId: result.winnerId,
      raceResult: result,
      completedTime: DateTime.now(),
    );

    final updatedMatches = [...bracket.matches];
    updatedMatches[matchIndex] = updatedMatch;

    final updatedBracket = TournamentBracket(
      tournamentId: bracket.tournamentId,
      format: bracket.format,
      matches: updatedMatches,
      roundParticipants: bracket.roundParticipants,
      participantSeeds: bracket.participantSeeds,
    );

    // Check if tournament is complete and advance bracket if needed
    final (finalBracket, status, winnerId) = _advanceBracket(updatedBracket, tournament.participants);

    final updatedTournament = tournament.copyWith(
      bracket: finalBracket,
      status: status,
      winnerId: winnerId,
      endTime: status == TournamentStatus.completed ? DateTime.now() : null,
    );

    await _saveTournament(updatedTournament);
    return updatedTournament;
  }

  TournamentBracket _generateBracket(Tournament tournament) {
    switch (tournament.format) {
      case TournamentFormat.singleElimination:
        return _generateSingleEliminationBracket(tournament);
      case TournamentFormat.roundRobin:
        return _generateRoundRobinBracket(tournament);
      case TournamentFormat.doubleElimination:
      case TournamentFormat.swiss:
        // For now, fall back to single elimination
        return _generateSingleEliminationBracket(tournament);
    }
  }

  TournamentBracket _generateSingleEliminationBracket(Tournament tournament) {
    final participants = [...tournament.participants];
    participants.shuffle(); // Randomize seeding for now

    // Create seeds map
    final participantSeeds = <String, int>{};
    for (int i = 0; i < participants.length; i++) {
      participantSeeds[participants[i].id] = i + 1;
    }

    final matches = <TournamentMatch>[];
    final roundParticipants = <int, List<String>>{};

    // Calculate number of rounds needed
    final totalRounds = _calculateRoundsNeeded(participants.length);
    
    // First round
    final firstRoundParticipants = <String>[];
    for (int i = 0; i < participants.length; i += 2) {
      if (i + 1 < participants.length) {
        // Create match between participants i and i+1
        final match = TournamentMatch(
          tournamentId: tournament.id,
          round: 1,
          matchNumber: matches.length + 1,
          participantIds: [participants[i].id, participants[i + 1].id],
        );
        matches.add(match);
      } else {
        // Odd number of participants, this one gets a bye
        firstRoundParticipants.add(participants[i].id);
      }
    }

    roundParticipants[1] = participants.map((p) => p.id).toList();

    // Generate placeholder matches for subsequent rounds
    for (int round = 2; round <= totalRounds; round++) {
      final previousRoundMatches = matches.where((m) => m.round == round - 1).length;
      final thisRoundMatches = (previousRoundMatches / 2).ceil();
      
      for (int i = 0; i < thisRoundMatches; i++) {
        final match = TournamentMatch(
          tournamentId: tournament.id,
          round: round,
          matchNumber: matches.length + 1,
          participantIds: [], // Will be filled when previous round completes
        );
        matches.add(match);
      }
    }

    return TournamentBracket(
      tournamentId: tournament.id,
      format: tournament.format,
      matches: matches,
      roundParticipants: roundParticipants,
      participantSeeds: participantSeeds,
    );
  }

  TournamentBracket _generateRoundRobinBracket(Tournament tournament) {
    final participants = [...tournament.participants];
    final matches = <TournamentMatch>[];
    final roundParticipants = <int, List<String>>{};

    int matchNumber = 1;
    int round = 1;

    // Create a match between every pair of participants
    for (int i = 0; i < participants.length; i++) {
      for (int j = i + 1; j < participants.length; j++) {
        final match = TournamentMatch(
          tournamentId: tournament.id,
          round: round,
          matchNumber: matchNumber,
          participantIds: [participants[i].id, participants[j].id],
        );
        matches.add(match);
        matchNumber++;
      }
    }

    roundParticipants[1] = participants.map((p) => p.id).toList();

    final participantSeeds = <String, int>{};
    for (int i = 0; i < participants.length; i++) {
      participantSeeds[participants[i].id] = i + 1;
    }

    return TournamentBracket(
      tournamentId: tournament.id,
      format: tournament.format,
      matches: matches,
      roundParticipants: roundParticipants,
      participantSeeds: participantSeeds,
    );
  }

  (TournamentBracket, TournamentStatus, String?) _advanceBracket(
    TournamentBracket bracket, 
    List<Player> participants
  ) {
    if (bracket.format == TournamentFormat.roundRobin) {
      return _advanceRoundRobin(bracket, participants);
    } else {
      return _advanceSingleElimination(bracket, participants);
    }
  }

  (TournamentBracket, TournamentStatus, String?) _advanceRoundRobin(
    TournamentBracket bracket,
    List<Player> participants
  ) {
    final allMatches = bracket.matches;
    final completedMatches = allMatches.where((m) => m.isCompleted).toList();

    // Check if all matches are completed
    if (completedMatches.length == allMatches.length) {
      // Calculate final standings
      final wins = <String, int>{};
      for (final participant in participants) {
        wins[participant.id] = 0;
      }

      for (final match in completedMatches) {
        if (match.winnerId != null) {
          wins[match.winnerId!] = (wins[match.winnerId!] ?? 0) + 1;
        }
      }

      // Find winner (most wins)
      final sortedParticipants = participants
          .where((p) => wins.containsKey(p.id))
          .toList()
        ..sort((a, b) => (wins[b.id] ?? 0).compareTo(wins[a.id] ?? 0));

      final winnerId = sortedParticipants.isNotEmpty ? sortedParticipants.first.id : null;
      
      return (bracket, TournamentStatus.completed, winnerId);
    }

    return (bracket, TournamentStatus.active, null);
  }

  (TournamentBracket, TournamentStatus, String?) _advanceSingleElimination(
    TournamentBracket bracket,
    List<Player> participants
  ) {
    final allMatches = bracket.matches;
    final currentRoundMatches = allMatches.where((m) => m.round == bracket.totalRounds).toList();

    // Check if final round is complete
    if (currentRoundMatches.length == 1 && currentRoundMatches.first.isCompleted) {
      return (bracket, TournamentStatus.completed, currentRoundMatches.first.winnerId);
    }

    // Advance completed matches to next round
    final updatedMatches = <TournamentMatch>[];
    bool hasAdvanced = false;

    for (final match in allMatches) {
      if (match.participantIds.isEmpty && !match.isCompleted) {
        // This is a placeholder match - try to fill it
        final previousRoundMatches = allMatches.where((m) => m.round == match.round - 1).toList();
        final requiredMatches = previousRoundMatches
            .where((m) => m.isCompleted && m.winnerId != null)
            .toList();

        if (requiredMatches.length >= 2) {
          // Fill this match with winners from previous round
          final updatedMatch = TournamentMatch(
            id: match.id,
            tournamentId: match.tournamentId,
            round: match.round,
            matchNumber: match.matchNumber,
            participantIds: requiredMatches.take(2).map((m) => m.winnerId!).toList(),
          );
          updatedMatches.add(updatedMatch);
          hasAdvanced = true;
        } else {
          updatedMatches.add(match);
        }
      } else {
        updatedMatches.add(match);
      }
    }

    final updatedBracket = TournamentBracket(
      tournamentId: bracket.tournamentId,
      format: bracket.format,
      matches: updatedMatches,
      roundParticipants: bracket.roundParticipants,
      participantSeeds: bracket.participantSeeds,
    );

    return (updatedBracket, TournamentStatus.active, null);
  }

  int _calculateRoundsNeeded(int participantCount) {
    if (participantCount <= 1) return 1;
    int rounds = 0;
    int remaining = participantCount;
    
    while (remaining > 1) {
      remaining = (remaining / 2).ceil();
      rounds++;
    }
    
    return rounds;
  }

  Future<void> _saveTournament(Tournament tournament) async {
    final tournaments = await getAllTournaments();
    final index = tournaments.indexWhere((t) => t.id == tournament.id);
    
    if (index >= 0) {
      tournaments[index] = tournament;
    } else {
      tournaments.add(tournament);
    }

    final jsonList = tournaments.map((t) => t.toJson()).toList();
    await StorageService.instance.saveData(_tournamentsKey, jsonList);
  }

  Future<void> deleteTournament(String tournamentId) async {
    final tournaments = await getAllTournaments();
    tournaments.removeWhere((t) => t.id == tournamentId);
    
    final jsonList = tournaments.map((t) => t.toJson()).toList();
    await StorageService.instance.saveData(_tournamentsKey, jsonList);
  }

  // Tournament Invitations
  Future<List<TournamentInvitation>> getInvitationsForPlayer(String playerId) async {
    try {
      final data = await StorageService.instance.getData(_tournamentInvitationsKey);
      if (data == null) return [];
      
      final List<dynamic> invitationsList = data;
      final invitations = invitationsList.map((json) => TournamentInvitation.fromJson(json)).toList();
      
      return invitations.where((inv) => inv.inviteeId == playerId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tournament invitations: $e');
      }
      return [];
    }
  }

  Future<TournamentInvitation> sendInvitation({
    required String tournamentId,
    required String inviteeId,
    required String inviterId,
    String? message,
  }) async {
    final invitation = TournamentInvitation(
      tournamentId: tournamentId,
      inviteeId: inviteeId,
      inviterId: inviterId,
      message: message,
    );

    await _saveInvitation(invitation);
    return invitation;
  }

  Future<TournamentInvitation> respondToInvitation(String invitationId, bool accept) async {
    final invitations = await _getAllInvitations();
    final index = invitations.indexWhere((inv) => inv.id == invitationId);
    
    if (index == -1) {
      throw Exception('Invitation not found');
    }

    final updatedInvitation = invitations[index].copyWith(
      accepted: accept,
      respondedAt: DateTime.now(),
    );

    await _saveInvitation(updatedInvitation);
    return updatedInvitation;
  }

  Future<List<TournamentInvitation>> _getAllInvitations() async {
    try {
      final data = await StorageService.instance.getData(_tournamentInvitationsKey);
      if (data == null) return [];
      
      final List<dynamic> invitationsList = data;
      return invitationsList.map((json) => TournamentInvitation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveInvitation(TournamentInvitation invitation) async {
    final invitations = await _getAllInvitations();
    final index = invitations.indexWhere((inv) => inv.id == invitation.id);
    
    if (index >= 0) {
      invitations[index] = invitation;
    } else {
      invitations.add(invitation);
    }

    final jsonList = invitations.map((inv) => inv.toJson()).toList();
    await StorageService.instance.saveData(_tournamentInvitationsKey, jsonList);
  }
}