import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/group.dart';
import '../models/player.dart';
import '../models/race_result.dart';
import '../models/sync_group.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import 'group_race_setup_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Group _group = Group(name: '');
  List<RaceResult> _raceHistory = [];
  bool _isLoading = true;
  SyncGroup? _convertedSyncGroup;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final groups = await StorageService.instance.getGroups();
      final updatedGroup = groups.firstWhere((g) => g.id == _group.id, orElse: () => _group);
      final history = await StorageService.instance.getGroupRaceResults(_group.id);
      
      setState(() {
        _group = updatedGroup;
        _raceHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _addPlayer() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Player name',
            hintText: 'Enter player name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Check for duplicates
      if (_group.players.any((p) => p.name.toLowerCase() == result.toLowerCase())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Player with this name already exists')),
          );
        }
        return;
      }

      try {
        final newPlayer = Player(name: result);
        final updatedGroup = _group.addPlayer(newPlayer);
        await StorageService.instance.saveGroup(updatedGroup);
        _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added player "$result"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding player: $e')),
          );
        }
      }
    }
  }

  Future<void> _removePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Are you sure you want to remove "${player.name}" from this group?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updatedGroup = _group.removePlayer(player.id);
        await StorageService.instance.saveGroup(updatedGroup);
        if (mounted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed player "${player.name}"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing player: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportGroupData() async {
    try {
      await StorageService.instance.shareGroupData(_group.id, _group.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  Future<void> _convertToOnlineGroup() async {
    if (!SupabaseService.instance.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Online groups are not available. Check Supabase configuration.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Online Group'),
        content: const Text(
          'This will create an online version of your group with a shareable code. '
          'Your local group will remain unchanged. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating online group...'),
            ],
          ),
        ),
      );
    }

    try {
      // Convert the group
      final syncGroup = await SupabaseService.instance.convertLocalGroupToOnline(
        localGroupName: _group.name,
        localPlayers: _group.players,
      );

      if (mounted) {
        setState(() {
          _convertedSyncGroup = syncGroup;
        });

        // Close loading dialog
        Navigator.pop(context);

        // Show success dialog with group code
        _showGroupCodeDialog(syncGroup.groupCode);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error converting group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGroupCodeDialog(String groupCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('Group Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your online group has been created successfully!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Group Code',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    groupCode,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: groupCode));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Group code copied to clipboard!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Code'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this code with friends so they can join your group!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(_group.name)),
            if (_convertedSyncGroup != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              if (_convertedSyncGroup == null && SupabaseService.instance.isInitialized)
                const PopupMenuItem(
                  value: 'convert',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Convert to Online'),
                    ],
                  ),
                ),
              if (_convertedSyncGroup != null)
                PopupMenuItem(
                  value: 'show_code',
                  child: Row(
                    children: [
                      Icon(Icons.code, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Show Group Code'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'convert':
                  _convertToOnlineGroup();
                  break;
                case 'show_code':
                  if (_convertedSyncGroup != null) {
                    _showGroupCodeDialog(_convertedSyncGroup!.groupCode);
                  }
                  break;
                case 'export':
                  _exportGroupData();
                  break;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => GroupRaceSetupScreen(group: _group),
            ),
          );
          if (result == true) {
            _loadData();
            if (mounted) {
              navigator.pop(true);
            }
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Race'),
      ),
    );
  }

  Widget _buildPlayersTab() {
    if (_group.players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text('No players in this group'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _addPlayer,
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_group.players.length} Players',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              OutlinedButton.icon(
                onPressed: _addPlayer,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _group.players.length,
            itemBuilder: (context, index) {
              final player = _group.players[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      player.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(player.name),
                  subtitle: Text('${player.totalWins} wins • ${player.totalRaces} races'),
                  trailing: _group.players.length > 2
                      ? IconButton(
                          onPressed: () => _removePlayer(player),
                          icon: Icon(
                            Icons.remove_circle,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    if (_raceHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64),
            SizedBox(height: 16),
            Text('No race data yet'),
            SizedBox(height: 8),
            Text('Start a race to see statistics'),
          ],
        ),
      );
    }

    // Calculate player stats
    final playerStats = <String, Map<String, int>>{};
    for (final player in _group.players) {
      playerStats[player.id] = {'wins': 0, 'total': 0};
    }

    for (final result in _raceHistory) {
      for (final participant in result.participants) {
        if (playerStats.containsKey(participant.id)) {
          playerStats[participant.id]!['total'] = 
              (playerStats[participant.id]!['total'] ?? 0) + 1;
          if (result.winnerId == participant.id) {
            playerStats[participant.id]!['wins'] = 
                (playerStats[participant.id]!['wins'] ?? 0) + 1;
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Races', _raceHistory.length.toString()),
                    _buildStatItem('Players', _group.players.length.toString()),
                    _buildStatItem('Last Played', 
                      _raceHistory.isNotEmpty
                          ? '${DateTime.now().difference(_raceHistory.last.completedAt).inDays} days ago'
                          : 'Never'),
                  ],
                ),
                if (_convertedSyncGroup != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Online Group Code',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _convertedSyncGroup!.groupCode));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Group code copied!')),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _convertedSyncGroup!.groupCode,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to copy • Share with friends to join!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ..._group.players.map((player) {
                  final stats = playerStats[player.id] ?? {'wins': 0, 'total': 0};
                  final wins = stats['wins'] ?? 0;
                  final total = stats['total'] ?? 0;
                  final winRate = total > 0 ? wins / total : 0.0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            player.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
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
                              Text(
                                player.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '$wins wins • ${total - wins} losses • ${(winRate * 100).toStringAsFixed(1)}% win rate',
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
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_raceHistory.isEmpty) {
      return const Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _raceHistory.length,
      itemBuilder: (context, index) {
        final result = _raceHistory[_raceHistory.length - 1 - index]; // Reverse order
        final winner = result.participants.firstWhere((p) => p.id == result.winnerId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.2),
              child: const Icon(Icons.emoji_events, color: Colors.orange),
            ),
            title: Text('${winner.name} won'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${result.rounds.length} rounds • ${result.participants.length} players'),
                Text(
                  '${result.completedAt.day}/${result.completedAt.month}/${result.completedAt.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Text(
              '${result.totalDuration.inMinutes}:${(result.totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      },
    );
  }
}