import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/player.dart';
import '../services/tournament_service.dart';
import '../services/sharing_service.dart';
import 'tournament_bracket_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  late Tournament _tournament;
  bool _isLoading = false;
  String? _currentPlayerId;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
  }

  bool get _isParticipant => false; // Remove participant checking for now

  bool get _isOrganizer => false; // Remove organizer checking for now

  bool get _canJoin => !_tournament.isFull && _tournament.status == TournamentStatus.pending;

  bool get _canStart => _tournament.canStart && _tournament.status == TournamentStatus.pending;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament.name),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareTournament,
            icon: const Icon(Icons.share_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (_isOrganizer && _tournament.status == TournamentStatus.pending)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Tournament'),
                    ],
                  ),
                ),
              if (_isParticipant && !_isOrganizer && _tournament.status == TournamentStatus.pending)
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app_rounded),
                      SizedBox(width: 8),
                      Text('Leave Tournament'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _tournament.name,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusChip(_tournament.status),
                          ],
                        ),
                        if (_tournament.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _tournament.description,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              Icons.people_rounded,
                              '${_tournament.participants.length}/${_tournament.maxParticipants} players',
                            ),
                            _buildInfoChip(
                              Icons.category_rounded,
                              _formatTournamentFormat(_tournament.format),
                            ),
                            if (_tournament.startTime != null)
                              _buildInfoChip(
                                Icons.schedule_rounded,
                                _formatDateTime(_tournament.startTime!),
                              ),
                            _buildInfoChip(
                              Icons.person_rounded,
                              'Organized by ${_tournament.organizer.name}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Participants
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Participants (${_tournament.participants.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._tournament.participants.map((player) => _buildParticipantTile(player)),
                        if (_tournament.participants.length < _tournament.maxParticipants) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Text(
                              '${_tournament.maxParticipants - _tournament.participants.length} spots remaining',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Tournament Bracket (if active or completed)
                if (_tournament.status == TournamentStatus.active || _tournament.status == TournamentStatus.completed) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tournament Bracket',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _viewBracket(),
                                icon: const Icon(Icons.account_tree_rounded),
                                label: const Text('View Bracket'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_tournament.bracket != null) ...[
                            Text(
                              'Current Round: ${_tournament.currentRound}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _tournament.bracket!.completedMatches.length /
                                  _tournament.bracket!.matches.length,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_tournament.bracket!.completedMatches.length} / ${_tournament.bracket!.matches.length} matches completed',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                // Winner announcement (if completed)
                if (_tournament.status == TournamentStatus.completed && _tournament.winner != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tournament Champion!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tournament.winner!.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          if (_tournament.totalDuration != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tournament Duration: ${_formatDuration(_tournament.totalDuration!)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _shareResult,
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share Results'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget? _buildActionButtons(BuildContext context) {
    if (_isLoading) return null;

    final buttons = <Widget>[];

    if (_canJoin) {
      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: _joinTournament,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Join Tournament'),
          ),
        ),
      );
    }

    if (_canStart) {
      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: _startTournament,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Tournament'),
          ),
        ),
      );
    }

    if (_tournament.status == TournamentStatus.active && _isParticipant) {
      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: _viewBracket,
            icon: const Icon(Icons.account_tree_rounded),
            label: const Text('View Bracket'),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: buttons.length == 1
            ? buttons.first
            : Row(
                children: buttons
                    .expand((button) => [button, const SizedBox(width: 8)])
                    .take(buttons.length * 2 - 1)
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildStatusChip(TournamentStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case TournamentStatus.pending:
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        textColor = Theme.of(context).colorScheme.onSurface;
        text = 'Pending';
        icon = Icons.schedule_rounded;
        break;
      case TournamentStatus.active:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        textColor = Theme.of(context).colorScheme.onPrimaryContainer;
        text = 'Active';
        icon = Icons.play_arrow_rounded;
        break;
      case TournamentStatus.completed:
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        textColor = Theme.of(context).colorScheme.onTertiaryContainer;
        text = 'Completed';
        icon = Icons.emoji_events_rounded;
        break;
      case TournamentStatus.cancelled:
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        textColor = Theme.of(context).colorScheme.onErrorContainer;
        text = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(Player player) {
    final isOrganizer = player.id == _tournament.organizerId;
    final isCurrentUser = player.id == _currentPlayerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isOrganizer || isCurrentUser) ...[
                  const SizedBox(height: 2),
                  Text(
                    isOrganizer ? 'Organizer' : 'You',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTournamentFormat(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.singleElimination:
        return 'Single Elimination';
      case TournamentFormat.doubleElimination:
        return 'Double Elimination';
      case TournamentFormat.roundRobin:
        return 'Round Robin';
      case TournamentFormat.swiss:
        return 'Swiss System';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes}m';
    } else if (difference.inMinutes > -60) {
      return '${difference.inMinutes.abs()}m ago';
    } else {
      return '${difference.inHours.abs()}h ago';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Future<void> _joinTournament() async {
    if (!_canJoin) return;

    // Show a dialog to get player name
    final playerName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Join Tournament'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your name to join this tournament:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.of(context).pop(value.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (playerName == null || playerName.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final player = Player(name: playerName);
      final updatedTournament = await TournamentService.instance.joinTournament(
        _tournament.id,
        player,
      );

      setState(() {
        _tournament = updatedTournament;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined tournament!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join tournament: $e')),
        );
      }
    }
  }

  Future<void> _startTournament() async {
    if (!_canStart) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Tournament'),
        content: Text(
          'Are you sure you want to start "${_tournament.name}"?\n\n'
          'This will generate the tournament bracket and no more players can join.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final updatedTournament = await TournamentService.instance.startTournament(_tournament.id);

      setState(() {
        _tournament = updatedTournament;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament started successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start tournament: $e')),
        );
      }
    }
  }

  void _viewBracket() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentBracketScreen(tournament: _tournament),
      ),
    );
  }

  Future<void> _shareTournament() async {
    try {
      if (_tournament.status == TournamentStatus.pending) {
        await SharingService.instance.shareTournamentInvitation(
          _tournament.name,
          _tournament.organizer.name,
          _tournament.startTime ?? DateTime.now().add(const Duration(hours: 1)),
        );
      } else if (_tournament.status == TournamentStatus.completed && _tournament.winner != null) {
        await SharingService.instance.shareTournamentResult(
          _tournament.name,
          _tournament.winner!,
          _tournament.participants,
          _tournament.totalDuration ?? Duration.zero,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share tournament: $e')),
        );
      }
    }
  }

  Future<void> _shareResult() async {
    if (_tournament.winner == null) return;

    await SharingService.instance.shareTournamentResult(
      _tournament.name,
      _tournament.winner!,
      _tournament.participants,
      _tournament.totalDuration ?? Duration.zero,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'delete':
        _deleteTournament();
        break;
      case 'leave':
        _leaveTournament();
        break;
    }
  }

  Future<void> _deleteTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: Text('Are you sure you want to delete "${_tournament.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TournamentService.instance.deleteTournament(_tournament.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tournament deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete tournament: $e')),
          );
        }
      }
    }
  }

  Future<void> _leaveTournament() async {
    if (_currentPlayerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Tournament'),
        content: Text('Are you sure you want to leave "${_tournament.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TournamentService.instance.leaveTournament(_tournament.id, _currentPlayerId!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left tournament successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave tournament: $e')),
          );
        }
      }
    }
  }
}