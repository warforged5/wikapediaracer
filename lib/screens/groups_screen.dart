import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:morphable_shape/morphable_shape.dart';
import '../models/group.dart';
import '../models/sync_group.dart';
import '../models/sync_player.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> _groups = [];
  bool _isLoading = true;
  bool _isSupabaseAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkSupabase();
    _loadGroups();
  }

  Future<void> _checkSupabase() async {
    setState(() {
      _isSupabaseAvailable = SupabaseService.instance.isInitialized;
    });
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await StorageService.instance.getGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This will also delete all race history for this group.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageService.instance.deleteGroup(group.id);
        _loadGroups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${group.name}"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting group: $e')),
          );
        }
      }
    }
  }

  Future<void> _joinGroup() async {
    if (!_isSupabaseAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Online groups not available - check Supabase configuration')),
      );
      return;
    }

    final groupCodeController = TextEditingController();
    final playerNameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Online Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: groupCodeController,
              decoration: const InputDecoration(
                labelText: 'Group Code',
                hintText: 'Enter 6-character code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (value) {
                groupCodeController.text = value.toUpperCase();
                groupCodeController.selection = TextSelection.fromPosition(
                  TextPosition(offset: groupCodeController.text.length),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: playerNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your player name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Join Group'),
          ),
        ],
      ),
    );

    if (result == true && groupCodeController.text.length == 6 && playerNameController.text.isNotEmpty) {
      try {
        // Join the group
        final syncGroup = await SupabaseService.instance.joinGroup(
          groupCode: groupCodeController.text,
        );

        if (syncGroup == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group not found - check the code and try again')),
            );
          }
          return;
        }

        // Add player to the group
        await SupabaseService.instance.addPlayerToGroup(
          groupId: syncGroup.id,
          playerName: playerNameController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully joined "${syncGroup.name}"!')),
          );
          
          // Navigate to group detail (you'll need to create a sync group detail screen)
          _showSyncGroupInfo(syncGroup);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to join group: $e')),
          );
        }
      }
    }
  }

  void _showSyncGroupInfo(SyncGroup syncGroup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Joined ${syncGroup.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve successfully joined the online group!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Code: ${syncGroup.groupCode}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share this code with friends to invite them!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Features available:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...[ 
              'Real-time synchronized races',
              'Shared group statistics',
              'Live race history',
              'Group leaderboards',
            ].map((feature) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature, style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy group code to clipboard
              Clipboard.setData(ClipboardData(text: syncGroup.groupCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group code copied to clipboard!')),
              );
            },
            child: const Text('Copy Code'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          if (_isSupabaseAvailable)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Join Online Group',
              onPressed: _joinGroup,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyState()
              : _buildGroupsList(),
      floatingActionButton: animatedAddButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateGroupScreen(),
            ),
          );
          if (result == true) {
            _loadGroups();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.group_add,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Groups Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSupabaseAvailable 
                ? 'Create your first local group or join an online group with friends!'
                : 'Create your first group to start tracking races and compete with friends!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateGroupScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadGroups();
                      }
                    },
                    icon: const Icon(Icons.add, size: 24),
                    label: const Text(
                      'Create Local Group',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (_isSupabaseAvailable) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _joinGroup,
                      icon: const Icon(Icons.login, size: 24),
                      label: const Text(
                        'Join Online Group',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(group: group),
                    ),
                  );
                  if (result == true) {
                    _loadGroups();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${group.players.length} players',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                    const SizedBox(width: 8),
                                    const Text('Delete Group'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteGroup(group);
                              }
                            },
                          ),
                        ],
                      ),
                      
                      if (group.totalRaces > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 20,
                                color: const Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${group.totalRaces} races completed',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Player avatars
                      if (group.players.isNotEmpty) ...[
                        Row(
                          children: [
                            ...group.players.take(5).map((player) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  player.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            )),
                            if (group.players.length > 5)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    '+${group.players.length - 5}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class animatedAddButton extends StatefulWidget {
  final VoidCallback onPressed;

  const animatedAddButton({
    required this.onPressed,
  });

  @override
  State<animatedAddButton> createState() => animatedAddButtonState();
}

class animatedAddButtonState extends State<animatedAddButton>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _spinController;
  late Animation<double> _morphAnimation;
  late Animation<double> _spinAnimation;
  late MorphableShapeBorderTween _shapeTween;
  
  @override
  void initState() {
    super.initState();
    
    // Create shapes for morphing - circle to rounded octagon
    final circle = CircleShapeBorder();
    
    final roundedOctagon = PolygonShapeBorder(
      sides: 8,
      cornerRadius: 25.toPercentLength,
      cornerStyle: CornerStyle.rounded,
    );
    
    _shapeTween = MorphableShapeBorderTween(
      begin: circle,
      end: roundedOctagon,
      method: MorphMethod.auto,
    );
    
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    );
    
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0, // 2 full rotations (720 degrees)
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _morphController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _handlePress() async {
    // Start spinning and morphing simultaneously
    final animationFutures = [
      _spinController.forward(),
      _morphController.forward(),
    ];
    
    // Call the onPressed immediately as animations start
    widget.onPressed();
    
    // Wait for animations to complete
    await Future.wait(animationFutures);
    
    // Keep the shape changed for a moment before reverting
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Reverse both animations simultaneously
    await Future.wait([
      _morphController.reverse(),
      _spinController.reverse(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_morphAnimation, _spinAnimation]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _spinAnimation.value * math.pi,
          child: FloatingActionButton(
            onPressed: _handlePress,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: _shapeTween.lerp(_morphAnimation.value),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }
}