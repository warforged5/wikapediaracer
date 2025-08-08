import 'package:flutter/material.dart';
import 'groups_screen.dart';
import 'quick_race_setup_screen.dart';
import 'history_screen.dart';
import 'theme_selector_screen.dart';
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
        title: const Text('Wikipedia Racer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.group,
                            title: 'Groups',
                            subtitle: 'Manage groups',
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.history,
                            title: 'History',
                            subtitle: 'View stats',
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.palette,
                            title: 'Themes',
                            subtitle: 'Customize appearance',
                            color: Colors.purple,
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
                        const Expanded(child: SizedBox()),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Action buttons
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'View past races and stats',
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
                  icon: Icons.palette,
                  title: 'Themes',
                  subtitle: 'Customize your experience',
                  color: Colors.purple,
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
              ],
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
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
      height: isPrimary ? 120 : 100,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isPrimary ? color : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isPrimary ? Colors.transparent : color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: isPrimary ? 72 : 64,
                  height: isPrimary ? 72 : 64,
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? Colors.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : color,
                    size: isPrimary ? 36 : 32,
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
                          color: isPrimary ? Colors.white : null,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isPrimary 
                              ? Colors.white.withValues(alpha: 0.9)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? Colors.white.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: isPrimary 
                        ? Colors.white.withValues(alpha: 0.9)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

