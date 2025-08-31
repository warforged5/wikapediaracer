import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_group.dart';
import '../models/sync_player.dart';
import '../services/supabase_service.dart';
import 'package:share_plus/share_plus.dart';

class SyncGroupDetailScreen extends StatefulWidget {
  final SyncGroup group;

  const SyncGroupDetailScreen({super.key, required this.group});

  @override
  State<SyncGroupDetailScreen> createState() => _SyncGroupDetailScreenState();
}

class _SyncGroupDetailScreenState extends State<SyncGroupDetailScreen> {
  List<SyncPlayer> _players = [];
  bool _isLoading = true;
  late RealtimeChannel _subscription;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _subscription.unsubscribe();
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPlayers,
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
                                  widget.group.totalRaces.toString(),
                                  Icons.emoji_events,
                                ),
                              ],
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
                                            Text(
                                              player.name,
                                              style: TextStyle(
                                                fontWeight: isCurrentDevice ? FontWeight.bold : null,
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
            ),
    );
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