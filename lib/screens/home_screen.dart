import 'package:flutter/material.dart';
import 'groups_screen.dart';
import 'quick_race_setup_screen.dart';
import 'history_screen.dart';
import 'achievements_screen.dart';
import 'theme_selector_screen.dart';
import 'tournament_screen.dart';
import '../themes/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Function(AppThemeData) onThemeChanged;
  
  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.speed,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Wikipedia Racer'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.palette_rounded,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              tooltip: 'Change Theme',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThemeSelectorScreen(
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: isWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            // Left side - Hero section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.speed,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Wikipedia Racer',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Challenge your friends to race through Wikipedia pages. Start from one article and navigate to another as fast as you can!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create groups to track wins and losses',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Race through multiple rounds',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.share,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export and share your race data',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Right side - Action cards
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.flash_on,
                      title: 'Quick Race',
                      subtitle: 'Start racing immediately',
                      color: Theme.of(context).colorScheme.primary,
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuickRaceSetupScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.group,
                            title: 'Groups',
                            subtitle: 'Manage groups',
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GroupsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildPillActionButton(
                            context,
                            icon: Icons.history,
                            title: 'History',
                            color: Theme.of(context).colorScheme.tertiary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildActionCard(
                      context,
                      icon: Icons.emoji_events,
                      title: 'Tournaments',
                      subtitle: 'Compete in structured competitions',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TournamentScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPillActionButton(
                            context,
                            icon: Icons.military_tech,
                            title: 'Profile',
                            color: Theme.of(context).colorScheme.tertiary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AchievementsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.palette,
                            title: 'Themes',
                            subtitle: '',
                            color: Theme.of(context).colorScheme.tertiary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ThemeSelectorScreen(
                                    onThemeChanged: widget.onThemeChanged,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              Icon(
                Icons.speed,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Wikipedia Racer',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Race through Wikipedia pages with friends',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Action buttons
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                _buildActionCard(
                  context,
                  icon: Icons.flash_on,
                  title: 'Quick Race',
                  subtitle: 'Start racing immediately',
                  color: Theme.of(context).colorScheme.primary,
                  isPrimary: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuickRaceSetupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildActionCard(
                  context,
                  icon: Icons.group,
                  title: 'Groups',
                  subtitle: 'Manage your racing groups',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GroupsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildPillActionButton(
                  context,
                  icon: Icons.history,
                  title: 'History',
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildActionCard(
                  context,
                  icon: Icons.emoji_events,
                  title: 'Tournaments',
                  subtitle: 'Compete in structured competitions',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TournamentScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildPillActionButton(
                  context,
                  icon: Icons.military_tech,
                  title: 'Achievements',
                  color: Theme.of(context).colorScheme.error,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AchievementsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildActionCard(
                  context,
                  icon: Icons.palette,
                  title: 'Themes',
                  
                  subtitle: 'Customize your experience',
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThemeSelectorScreen(
                          onThemeChanged: widget.onThemeChanged,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom info
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Create groups to track wins and losses, or jump into a quick race!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40), // Pill shape
        gradient: LinearGradient(
          colors: isSecondary 
            ? [
                Theme.of(context).colorScheme.secondaryContainer,
                Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.8),
              ]
            : [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSecondary 
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isSecondary 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onPrimary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    color: isSecondary 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSecondary 
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: (isSecondary 
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Theme.of(context).colorScheme.onPrimary).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isSecondary 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onPrimary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: isSecondary 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 110,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(55), // Pill shape
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(55),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(55), // Pill shape
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30), // Circular icon container
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isPrimary ? 120 : 110,
      child: Card(
        elevation: 2,
        shadowColor: color.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

