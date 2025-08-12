import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/player.dart';

class TournamentBracketScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentBracketScreen({super.key, required this.tournament});

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  late Tournament _tournament;
  int _selectedRound = 1;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    if (_tournament.bracket != null && _tournament.bracket!.matches.isNotEmpty) {
      _selectedRound = _tournament.currentRound.clamp(1, _tournament.bracket!.totalRounds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bracket = _tournament.bracket;
    if (bracket == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${_tournament.name} - Bracket'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Tournament bracket not available'),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_tournament.name} - Bracket'),
        centerTitle: true,
        elevation: 0,
        bottom: bracket.totalRounds > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: bracket.totalRounds,
                    itemBuilder: (context, index) {
                      final round = index + 1;
                      final isSelected = round == _selectedRound;
                      final roundMatches = bracket.getMatchesForRound(round);
                      final completedCount = roundMatches.where((m) => m.isCompleted).length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            round == bracket.totalRounds
                                ? 'Final'
                                : round == bracket.totalRounds - 1 && bracket.totalRounds > 2
                                    ? 'Semi-Final'
                                    : 'Round $round',
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedRound = round),
                          avatar: completedCount == roundMatches.length
                              ? const Icon(Icons.check_circle, size: 18)
                              : completedCount > 0
                                  ? const Icon(Icons.schedule, size: 18)
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              )
            : null,
      ),
      body: _buildBracketView(bracket, isWeb),
    );
  }

  Widget _buildBracketView(TournamentBracket bracket, bool isWeb) {
    if (_tournament.format == TournamentFormat.roundRobin) {
      return _buildRoundRobinView(bracket);
    } else {
      return _buildEliminationView(bracket, isWeb);
    }
  }

  Widget _buildEliminationView(TournamentBracket bracket, bool isWeb) {
    final roundMatches = bracket.getMatchesForRound(_selectedRound);

    if (roundMatches.isEmpty) {
      return const Center(
        child: Text('No matches in this round'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round header
          Text(
            _selectedRound == bracket.totalRounds
                ? 'Final'
                : _selectedRound == bracket.totalRounds - 1 && bracket.totalRounds > 2
                    ? 'Semi-Final'
                    : 'Round $_selectedRound',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${roundMatches.where((m) => m.isCompleted).length} of ${roundMatches.length} matches completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Matches
          ...roundMatches.map((match) => _buildMatchCard(match)).toList(),
        ],
      ),
    );
  }

  Widget _buildRoundRobinView(TournamentBracket bracket) {
    final allMatches = bracket.matches;
    final completedMatches = allMatches.where((m) => m.isCompleted).toList();

    // Calculate standings
    final standings = <String, int>{};
    for (final participant in _tournament.participants) {
      standings[participant.id] = 0;
    }

    for (final match in completedMatches) {
      if (match.winnerId != null) {
        standings[match.winnerId!] = (standings[match.winnerId!] ?? 0) + 1;
      }
    }

    final sortedParticipants = _tournament.participants.toList()
      ..sort((a, b) => (standings[b.id] ?? 0).compareTo(standings[a.id] ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Standings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sortedParticipants.asMap().entries.map((entry) {
                    final position = entry.key + 1;
                    final participant = entry.value;
                    final wins = standings[participant.id] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: position == 1
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: position <= 3
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '$position',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              participant.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$wins wins',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // All matches
          Text(
            'All Matches',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...allMatches.map((match) => _buildMatchCard(match)).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    Player? player1;
    Player? player2;

    if (match.participantIds.isNotEmpty) {
      try {
        player1 = _tournament.participants.firstWhere((p) => p.id == match.participantIds[0]);
      } catch (e) {
        // Player not found
      }
    }

    if (match.participantIds.length > 1) {
      try {
        player2 = _tournament.participants.firstWhere((p) => p.id == match.participantIds[1]);
      } catch (e) {
        // Player not found
      }
    }

    final winner = match.winnerId != null
        ? _tournament.participants.cast<Player?>().firstWhere((p) => p?.id == match.winnerId, orElse: () => null)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match header
            Row(
              children: [
                Text(
                  'Match ${match.matchNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildMatchStatusChip(match),
              ],
            ),

            const SizedBox(height: 12),

            // Players
            Row(
              children: [
                Expanded(
                  child: _buildPlayerCard(
                    player1,
                    winner?.id == player1?.id,
                    match.isCompleted,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildPlayerCard(
                    player2,
                    winner?.id == player2?.id,
                    match.isCompleted,
                  ),
                ),
              ],
            ),

            // Race result details
            if (match.raceResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Duration: ${_formatDuration(match.raceResult!.totalDuration)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.route_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rounds: ${match.raceResult!.totalRounds}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player? player, bool isWinner, bool matchCompleted) {
    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          'TBD',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    Color? backgroundColor;
    Color? borderColor;
    Widget? trailing;

    if (matchCompleted) {
      if (isWinner) {
        backgroundColor = Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5);
        borderColor = Theme.of(context).colorScheme.primary;
        trailing = Icon(
          Icons.emoji_events_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        );
      } else {
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildMatchStatusChip(TournamentMatch match) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    if (match.isCompleted) {
      backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
      textColor = Theme.of(context).colorScheme.onTertiaryContainer;
      text = 'Completed';
      icon = Icons.check_circle_rounded;
    } else if (match.isInProgress) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
      text = 'In Progress';
      icon = Icons.play_circle_rounded;
    } else {
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      textColor = Theme.of(context).colorScheme.onSurface;
      text = 'Pending';
      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}