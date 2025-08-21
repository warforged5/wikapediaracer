import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/achievement.dart';
import '../models/player.dart';
import '../services/achievement_service.dart';
import '../services/storage_service.dart';
import 'user_selector_screen.dart';

class AchievementsScreen extends StatefulWidget {
  final String? playerId;

  const AchievementsScreen({super.key, this.playerId});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with TickerProviderStateMixin {
  List<Achievement> _achievements = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  Player? _selectedPlayer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.playerId != null) {
      // If a playerId is provided, use it directly
      _loadData();
    } else {
      // Otherwise, show user selector
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUserSelector();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showUserSelector() async {
    final result = await Navigator.push<Player>(
      context,
      MaterialPageRoute(builder: (context) => const UserSelectorScreen()),
    );
    
    if (result != null && mounted) {
      setState(() {
        _selectedPlayer = result;
        _isLoading = true;
      });
      AchievementService.instance.setCurrentPlayer(result.id);
      await _loadData();
    } else if (mounted) {
      // User cancelled, go back
      Navigator.pop(context);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.playerId != null) {
        AchievementService.instance.setCurrentPlayer(widget.playerId!);
      } else if (_selectedPlayer != null) {
        AchievementService.instance.setCurrentPlayer(_selectedPlayer!.id);
      }
      
      final achievements = await AchievementService.instance.getUserAchievements();
      final stats = await AchievementService.instance.getAchievementStats();
      
      setState(() {
        _achievements = achievements;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading achievements: $e')),
        );
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      await StorageService.instance.shareAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data exported successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Show confirmation dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will replace all current data with the imported data.'),
              const SizedBox(height: 16),
              if (data['exported_at'] != null)
                Text(
                  'Export date: ${DateTime.parse(data['exported_at']).toLocal()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (data['app_version'] != null)
                Text(
                  'App version: ${data['app_version']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to continue?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
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
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await StorageService.instance.importAllData(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Data imported successfully! Please restart the app.'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 5),
            ),
          );
          
          // Reload data
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedPlayer != null 
            ? Text('${_selectedPlayer!.name}\'s Achievements')
            : const Text('Achievements'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportAllData();
                  break;
                case 'import':
                  _importData();
                  break;
                case 'switch_user':
                  _showUserSelector();
                  break;
                case 'refresh':
                  _loadData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Export All Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Import Data'),
                  ],
                ),
              ),
              if (_selectedPlayer != null)
                const PopupMenuItem(
                  value: 'switch_user',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Switch User'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Unlocked', icon: Icon(Icons.check_circle)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsOverview(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAchievementsList(_achievements),
                      _buildAchievementsList(_achievements.where((a) => a.isUnlocked).toList()),
                      _buildAchievementsList(_achievements.where((a) => !a.isUnlocked && a.currentProgress > 0).toList()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Achievement Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatCard('Unlocked', _stats['unlocked'] ?? 0, Icons.check_circle, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('In Progress', _stats['inProgress'] ?? 0, Icons.trending_up, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Locked', _stats['locked'] ?? 0, Icons.lock, Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_stats['total'] ?? 0) > 0 ? (_stats['unlocked'] ?? 0) / (_stats['total'] ?? 1) : 0,
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '${_stats['unlocked'] ?? 0} of ${_stats['total'] ?? 0} achievements unlocked',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements) {
    if (achievements.isEmpty) {
      String message;
      IconData iconData;
      switch (_tabController.index) {
        case 1:
          message = 'No achievements unlocked yet';
          iconData = Icons.lock_outline;
          break;
        case 2:
          message = 'No achievements in progress';
          iconData = Icons.trending_flat;
          break;
        default:
          message = 'No achievements available';
          iconData = Icons.emoji_events_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                iconData,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Group achievements by type
    final achievementsByType = <AchievementType, List<Achievement>>{};
    for (final achievement in achievements) {
      achievementsByType.putIfAbsent(achievement.type, () => []).add(achievement);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: achievementsByType.entries.map((entry) {
        return _buildAchievementSection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildAchievementSection(AchievementType type, List<Achievement> achievements) {
    String sectionTitle;
    IconData sectionIcon;
    Color sectionColor;

    switch (type) {
      case AchievementType.wins:
        sectionTitle = 'Victory Achievements';
        sectionIcon = Icons.emoji_events;
        sectionColor = const Color(0xFFFFD700);
        break;
      case AchievementType.races:
        sectionTitle = 'Participation Achievements';
        sectionIcon = Icons.directions_run;
        sectionColor = Colors.blue;
        break;
      case AchievementType.speed:
        sectionTitle = 'Speed Achievements';
        sectionIcon = Icons.flash_on;
        sectionColor = Colors.orange;
        break;
      case AchievementType.streak:
        sectionTitle = 'Streak Achievements';
        sectionIcon = Icons.local_fire_department;
        sectionColor = Colors.red;
        break;
      case AchievementType.special:
        sectionTitle = 'Special Achievements';
        sectionIcon = Icons.star;
        sectionColor = Colors.purple;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(sectionIcon, color: sectionColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                sectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: sectionColor,
                ),
              ),
            ],
          ),
        ),
        ...achievements.map((achievement) => _buildAchievementCard(achievement)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final tierColor = _getTierColor(achievement.tier);
    final isUnlocked = achievement.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isUnlocked ? 3 : 1,
        child: InkWell(
          onTap: () => _showAchievementDetail(achievement),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isUnlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tierColor.withValues(alpha: 0.1),
                        tierColor.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              border: isUnlocked
                  ? Border.all(color: tierColor.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isUnlocked 
                            ? tierColor.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnlocked 
                              ? tierColor.withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getIconData(achievement.iconName),
                        size: 28,
                        color: isUnlocked 
                            ? tierColor 
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (isUnlocked)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: tierColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isUnlocked 
                                    ? null 
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          _buildTierBadge(achievement.tier),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUnlocked 
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (!isUnlocked && achievement.currentProgress > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: achievement.progressPercentage,
                                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${achievement.currentProgress}/${achievement.targetValue}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierBadge(AchievementTier tier) {
    Color color;
    String label;
    
    switch (tier) {
      case AchievementTier.bronze:
        color = const Color(0xFFCD7F32);
        label = 'Bronze';
        break;
      case AchievementTier.silver:
        color = const Color(0xFFC0C0C0);
        label = 'Silver';
        break;
      case AchievementTier.gold:
        color = const Color(0xFFFFD700);
        label = 'Gold';
        break;
      case AchievementTier.platinum:
        color = const Color(0xFFE5E4E2);
        label = 'Platinum';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'military_tech':
        return Icons.military_tech;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'directions_run':
        return Icons.directions_run;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'diamond':
        return Icons.diamond;
      case 'flash_on':
        return Icons.flash_on;
      case 'whatshot':
        return Icons.whatshot;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'bolt':
        return Icons.bolt;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'fireplace':
        return Icons.fireplace;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'star_rate':
        return Icons.star_rate;
      case 'trending_up':
        return Icons.trending_up;
      case 'speed':
        return Icons.speed;
      default:
        return Icons.emoji_events;
    }
  }

  void _showAchievementDetail(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTierColor(achievement.tier).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(achievement.iconName),
                color: _getTierColor(achievement.tier),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildTierBadge(achievement.tier),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (achievement.isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text('Unlocked', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    if (achievement.unlockedAt != null) ...[
                      const Spacer(),
                      Text(
                        '${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Progress: ${achievement.currentProgress}/${achievement.targetValue}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: achievement.progressPercentage,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_getTierColor(achievement.tier)),
              ),
              const SizedBox(height: 8),
              Text(
                '${(achievement.progressPercentage * 100).toStringAsFixed(1)}% complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}