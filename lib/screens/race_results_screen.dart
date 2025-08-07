import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/race_result.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Results'),
        backgroundColor: const Color(0xFFFFD700),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Stack(
        children: [
          // Confetti animation
          Positioned.fill(child: _buildConfetti()),
          
          // Main content
          SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Winner announcement
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: ScaleTransition(
                    scale: _celebrationAnimation,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: const Color(0xFFFFD700),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '🎉 ${winner.name} Wins! 🎉',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Time: ${_formatDuration(widget.result.totalDuration)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.result.rounds.length} rounds completed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Results details
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Player standings
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Final Standings',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Sort players by wins
                              ...() {
                                final sortedPlayers = widget.result.participants
                                    .map((player) => MapEntry(player, playerWins[player.id] ?? 0))
                                    .toList()..sort((a, b) => b.value.compareTo(a.value));
                                
                                return sortedPlayers.asMap().entries.map<Widget>((entry) {
                                  final position = entry.key + 1;
                                  final player = entry.value.key;
                                  final wins = entry.value.value;
                                  final isWinner = player.id == winner.id;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isWinner 
                                          ? const Color(0xFFFFD700).withOpacity(0.1)
                                          : position == 2
                                              ? Colors.grey.withOpacity(0.1)
                                              : position == 3
                                                  ? Colors.brown.withOpacity(0.1)
                                                  : null,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isWinner
                                          ? Border.all(color: const Color(0xFFFFD700), width: 2)
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        // Position
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: position == 1
                                                ? const Color(0xFFFFD700)
                                                : position == 2
                                                    ? Colors.grey
                                                    : position == 3
                                                        ? Colors.brown
                                                        : Theme.of(context).colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$position',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
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
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: isWinner ? const Color(0xFFB8860B) : null,
                                                ),
                                              ),
                                              Text(
                                                '$wins ${wins == 1 ? 'round' : 'rounds'} won',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Medal/Trophy
                                        if (position <= 3)
                                          Icon(
                                            position == 1 ? Icons.emoji_events : Icons.military_tech,
                                            color: position == 1
                                                ? const Color(0xFFFFD700)
                                                : position == 2
                                                    ? Colors.grey
                                                    : Colors.brown,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              }(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Round by round breakdown
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Round Breakdown',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              ...widget.result.rounds.map((round) {
                                final roundWinner = widget.result.participants
                                    .firstWhere((p) => p.id == round.winnerId);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Round ${round.roundNumber}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              _formatDuration(round.duration),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Winner: ${roundWinner.name}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${round.startPage.title} → ${round.endPage.title}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
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

                // Bottom actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            // TODO: Implement rematch functionality
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Race Again'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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