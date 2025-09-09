import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_group.dart';
import '../models/sync_player.dart';
import '../models/player.dart';
import '../services/supabase_service.dart';
import 'race_screen.dart';
import 'package:share_plus/share_plus.dart';

class SyncGroupDetailScreen extends StatefulWidget {
  final SyncGroup group;

  const SyncGroupDetailScreen({super.key, required this.group});

  @override
  State<SyncGroupDetailScreen> createState() => _SyncGroupDetailScreenState();
}

class _SyncGroupDetailScreenState extends State<SyncGroupDetailScreen> with TickerProviderStateMixin {
  List<SyncPlayer> _players = [];
  List<Map<String, dynamic>> _raceHistory = [];
  bool _isLoading = true;
  late RealtimeChannel _subscription;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlayers();
    _loadRaceHistory();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _subscription.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _subscription = SupabaseService.instance.subscribeToGroup(
      groupId: widget.group.id,
      onPlayersChanged: (players) {
        if (mounted) {
          setState(() {
            _players = players;
          });
        }
      },
      onActiveRaceChanged: (activeRace) {
        // Handle active race changes if needed
      },
    );
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final players = await SupabaseService.instance.getGroupPlayers(widget.group.id);
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading players: $e')),
        );
      }
    }
  }

  Future<void> _loadRaceHistory() async {
    try {
      final history = await SupabaseService.instance.getGroupRaceHistory(widget.group.id);
      if (mounted) {
        setState(() {
          _raceHistory = history;
        });
      }
    } catch (e) {
      print('Error loading race history: $e');
    }
  }

  void _copyGroupCode() {
    Clipboard.setData(ClipboardData(text: widget.group.groupCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Group code ${widget.group.groupCode} copied to clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _shareGroupCode() async {
    final inviteText = '''🏁 Join my Wikipedia Racing group!

Group: ${widget.group.name}
Group Code: ${widget.group.groupCode}

Race through Wikipedia with us! Get the Wikipedia Racer app and join using this code.

Current players: ${_players.length}
Total races: ${widget.group.totalRaces}''';

    try {
      await Share.share(
        inviteText,
        subject: 'Join my Wikipedia Racing group - ${widget.group.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${widget.group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get current device player
        final devicePlayer = _players.firstWhere(
          (p) => p.deviceId == SupabaseService.instance.deviceId,
          orElse: () => throw Exception('Player not found'),
        );

        await SupabaseService.instance.leaveGroup(
          groupId: widget.group.id,
          playerName: devicePlayer.name,
        );

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Left "${widget.group.name}" successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave group: $e')),
          );
        }
      }
    }
  }

  Future<void> _startRace() async {
    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 players to start a race')),
      );
      return;
    }

    // Show race setup dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RaceSetupDialog(players: _players),
    );

    if (result != null && mounted) {
      final selectedPlayerIds = result['selectedPlayerIds'] as Set<String>;
      final rounds = result['rounds'] as int;
      
      // Convert SyncPlayers to regular Players for the race
      final selectedPlayers = _players
          .where((p) => selectedPlayerIds.contains(p.id))
          .map((syncPlayer) => Player(
                id: syncPlayer.id,
                name: syncPlayer.name,
                totalWins: syncPlayer.totalWins,
                totalLosses: syncPlayer.totalRaces - syncPlayer.totalWins,
                totalRaces: syncPlayer.totalRaces,
              ))
          .toList();
      
      final raceResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => RaceScreen(
            players: selectedPlayers,
            rounds: rounds,
            groupId: widget.group.id,
          ),
        ),
      );
      
      if (raceResult == true) {
        // Refresh data after race completion
        _loadPlayers();
        _loadRaceHistory();
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadPlayers(),
      _loadRaceHistory(),
    ]);
  }

  Future<void> _addPlayerManually() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _AddPlayerDialog(),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await SupabaseService.instance.addPlayerToGroupManually(
          groupId: widget.group.id,
          playerName: result.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Added "$result" to the group!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to add player: $e')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name),
            Text(
              'Online Group',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    const Text('Leave Group'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'leave') {
                _leaveGroup();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Players', icon: Icon(Icons.people)),
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlayersTab(),
                _buildStatsTab(),
                _buildHistoryTab(),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_player',
            onPressed: _addPlayerManually,
            child: const Icon(Icons.person_add),
            tooltip: 'Add Player',
          ),
          if (_players.length >= 2) ...[
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'start_race',
              onPressed: _startRace,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Race'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Code Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Group Code',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _copyGroupCode,
                          icon: Icon(
                            Icons.copy,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          tooltip: 'Copy Code',
                        ),
                        IconButton(
                          onPressed: _shareGroupCode,
                          icon: Icon(
                            Icons.share,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          tooltip: 'Share Invite',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.group.groupCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Share this code with friends to invite them!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Players List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Players (${_players.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.sync,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_players.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No players yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          final player = _players[index];
                          final isCurrentDevice = player.deviceId == SupabaseService.instance.deviceId;
                          final isManuallyAdded = player.deviceId == null;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: isCurrentDevice ? 2 : 0,
                              color: isCurrentDevice 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCurrentDevice
                                      ? Theme.of(context).colorScheme.primary
                                      : isManuallyAdded
                                          ? Theme.of(context).colorScheme.outline
                                          : Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                    player.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        player.name,
                                        style: TextStyle(
                                          fontWeight: isCurrentDevice ? FontWeight.bold : null,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentDevice) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'You',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ] else if (isManuallyAdded) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.person_add_alt_1,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Manual',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.outline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.devices,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Online',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  '${player.totalWins} wins • ${player.totalRaces} races',
                                ),
                                trailing: player.totalRaces > 0
                                    ? Text(
                                        '${(player.winRate * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Group Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          'Players',
                          _players.length.toString(),
                          Icons.people,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          context,
                          'Total Races',
                          _raceHistory.length.toString(),
                          Icons.emoji_events,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Player Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_players.isEmpty)
                      const Center(
                        child: Text('No players yet'),
                      )
                    else
                      ..._players.map((player) {
                        final isCurrentDevice = player.deviceId == SupabaseService.instance.deviceId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isCurrentDevice
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                                child: Text(
                                  player.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          player.name,
                                          style: TextStyle(
                                            fontWeight: isCurrentDevice ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                        if (isCurrentDevice) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'You',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${player.totalWins} wins • ${player.totalRaces - player.totalWins} losses • ${player.totalRaces > 0 ? (player.winRate * 100).toStringAsFixed(1) : '0.0'}% win rate',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_raceHistory.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64),
                  SizedBox(height: 16),
                  Text('No race history'),
                  SizedBox(height: 8),
                  Text('Complete races to see history here'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _raceHistory.length,
        itemBuilder: (context, index) {
          final result = _raceHistory[index];
          final winnerName = result['winner']?['name'] ?? 'Unknown';
          final completedAt = DateTime.tryParse(result['completed_at'] ?? '') ?? DateTime.now();
          final rounds = result['rounds'] as List<dynamic>? ?? [];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.2),
                child: const Icon(Icons.emoji_events, color: Colors.orange),
              ),
              title: Text('$winnerName won'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${rounds.length} rounds • ${result['participant_count'] ?? 0} players'),
                  Text(
                    '${completedAt.day}/${completedAt.month}/${completedAt.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: result['total_duration'] != null
                  ? Text(
                      _formatDuration(result['total_duration'] as int),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Race Setup Dialog
class _RaceSetupDialog extends StatefulWidget {
  final List<SyncPlayer> players;

  const _RaceSetupDialog({required this.players});

  @override
  State<_RaceSetupDialog> createState() => _RaceSetupDialogState();
}

class _RaceSetupDialogState extends State<_RaceSetupDialog> {
  final Set<String> _selectedPlayerIds = <String>{};
  int _rounds = 3;

  @override
  void initState() {
    super.initState();
    // Select all players by default
    _selectedPlayerIds.addAll(widget.players.map((p) => p.id));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Race Setup'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player selection
            Text(
              'Select Players (${_selectedPlayerIds.length}/${widget.players.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: widget.players.length,
                itemBuilder: (context, index) {
                  final player = widget.players[index];
                  final isSelected = _selectedPlayerIds.contains(player.id);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedPlayerIds.add(player.id);
                        } else {
                          _selectedPlayerIds.remove(player.id);
                        }
                      });
                    },
                    title: Text(player.name),
                    subtitle: Text('${player.totalWins} wins • ${player.totalRaces} races'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Rounds selection
            Text(
              'Rounds: $_rounds',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _rounds.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              label: _rounds.toString(),
              onChanged: (value) {
                setState(() {
                  _rounds = value.toInt();
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedPlayerIds.length >= 2
              ? () {
                  Navigator.pop(context, {
                    'selectedPlayerIds': _selectedPlayerIds,
                    'rounds': _rounds,
                  });
                }
              : null,
          child: const Text('Start Race'),
        ),
      ],
    );
  }
}

// Add Player Dialog
class _AddPlayerDialog extends StatefulWidget {
  const _AddPlayerDialog();
  
  @override
  State<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<_AddPlayerDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.person_add,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Add Player'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a new player to this group manually. They can join later with the group code to take control of their profile.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Player Name',
                hintText: 'Enter player name',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a player name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (value.trim().length > 30) {
                  return 'Name must be less than 30 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (_formKey.currentState?.validate() == true) {
                  Navigator.pop(context, _controller.text.trim());
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Add Player'),
        ),
      ],
    );
  }
}