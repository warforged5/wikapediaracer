import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/race_result.dart';
import '../services/sharing_service.dart';

class RaceResultsScreen extends StatefulWidget {
  final RaceResult result;

  const RaceResultsScreen({super.key, required this.result});

  @override
  State<RaceResultsScreen> createState() => _RaceResultsScreenState();
}

class _RaceResultsScreenState extends State<RaceResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _slideController;
  late Animation<double> _celebrationAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    // Start animations
    _celebrationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _shareResults() async {
    try {
      await SharingService.instance.shareRaceResult(widget.result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share results: $e')),
        );
      }
    }
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_celebrationAnimation.value),
          child: Container(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.result.winner;
    final playerWins = widget.result.playerWins;
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti animation
            Positioned.fill(child: _buildConfetti()),
            
            // Main content
            SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Winner announcement header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isWeb ? 32 : 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Race Complete',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // Balance the close button
                          ],
                        ),
                        const SizedBox(height: 24),
                        ScaleTransition(
                          scale: _celebrationAnimation,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${winner.name} Wins!',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total Time: ${_formatDuration(widget.result.totalDuration)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.result.rounds.length} rounds completed',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content area
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isWeb ? 24 : 16),
                      child: isWeb ? _buildWebResultsLayout() : _buildMobileResultsLayout(),
                    ),
                  ),

                  // Bottom actions
                  Padding(
                    padding: EdgeInsets.all(isWeb ? 24 : 16),
                    child: Column(
                      children: [
                        // Share button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _shareResults(),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share Results'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Navigation buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                                icon: const Icon(Icons.home_rounded),
                                label: const Text('Home'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Race Again'),
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebResultsLayout() {
    final playerWins = widget.result.playerWins;
    
    return Row(
      children: [
        // Left Column - Final Standings
        Expanded(
          flex: 2,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final Standings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: _buildPlayerStandings(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Right Column - Round Breakdown
        Expanded(
          flex: 3,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Round Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: _buildRoundBreakdown(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileResultsLayout() {
    return Column(
      children: [
        // Final Standings Card
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final Standings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: _buildPlayerStandings(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Round Breakdown Card
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Round Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: _buildRoundBreakdown(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPlayerStandings() {
    final winner = widget.result.winner;
    final playerWins = widget.result.playerWins;
    final sortedPlayers = widget.result.participants
        .map((player) => MapEntry(player, playerWins[player.id] ?? 0))
        .toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedPlayers.asMap().entries.map<Widget>((entry) {
      final position = entry.key + 1;
      final player = entry.value.key;
      final wins = entry.value.value;
      final isWinner = player.id == winner.id;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: isWinner ? 4 : 1,
          color: isWinner 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Position badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: position == 1
                        ? Theme.of(context).colorScheme.primary
                        : position == 2
                            ? Theme.of(context).colorScheme.secondary
                            : position == 3
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Player info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isWinner 
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$wins ${wins == 1 ? 'round' : 'rounds'} won',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isWinner
                              ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Trophy/Medal
                if (position <= 3)
                  Icon(
                    position == 1 ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
                    color: position == 1
                        ? Theme.of(context).colorScheme.primary
                        : position == 2
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.tertiary,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildRoundBreakdown() {
    return widget.result.rounds.map((round) {
      final roundWinner = widget.result.participants
          .firstWhere((p) => p.id == round.winnerId);
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Round ${round.roundNumber}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(round.duration),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Winner: ${roundWinner.name}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${round.startPage.title} → ${round.endPage.title}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final List<ConfettiParticle> particles = [];

  ConfettiPainter(this.animationValue) {
    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      particles.add(ConfettiParticle());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = (particle.y + animationValue * 2) * size.height;
      
      // Only draw particles that are on screen
      if (y > 0 && y < size.height) {
        paint.color = particle.color;
        canvas.drawCircle(Offset(x, y), particle.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;

  ConfettiParticle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble() - 1, // Start above screen
        size = math.Random().nextDouble() * 4 + 2,
        color = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ][math.Random().nextInt(6)];
}