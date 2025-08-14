import 'package:flutter/material.dart';
import '../models/player.dart';
import 'race_screen.dart';

class QuickRaceSetupScreen extends StatefulWidget {
  const QuickRaceSetupScreen({super.key});

  @override
  State<QuickRaceSetupScreen> createState() => _QuickRaceSetupScreenState();
}

class _QuickRaceSetupScreenState extends State<QuickRaceSetupScreen> {
  final List<TextEditingController> _playerControllers = [];
  int _rounds = 3;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 default players
    _playerControllers.add(TextEditingController(text: 'Player 1'));
    _playerControllers.add(TextEditingController(text: 'Player 2'));
  }

  @override
  void dispose() {
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_playerControllers.length < 8) {
      setState(() {
        _playerControllers.add(
          TextEditingController(text: 'Player ${_playerControllers.length + 1}'),
        );
      });
    }
  }

  void _removePlayer(int index) {
    if (_playerControllers.length > 2) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
      });
    }
  }

  Future<void> _startRace() async {
    final playerNames = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();

    if (playerNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 unique players are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final players = playerNames.map((name) => Player(name: name)).toList();
      
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => RaceScreen(
              players: players,
              rounds: _rounds,
              groupId: null, // Quick race - no group
            ),
          ),
        );
        
        if (result == true && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting race: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Race Setup'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Players Section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Players',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _playerControllers.length < 8 ? _addPlayer : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Player'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize player names or keep the defaults',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Player name fields
                  ...List.generate(_playerControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _playerControllers[index],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person),
                                labelText: 'Player ${index + 1}',
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                          if (_playerControllers.length > 2)
                            IconButton(
                              onPressed: () => _removePlayer(index),
                              icon: Icon(
                                Icons.remove_circle,
                                color: Theme.of(context).colorScheme.error,
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

          const SizedBox(height: 16),

          // Rounds Section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Number of Rounds',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each round requires reaching a different Wikipedia page',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Round selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      final rounds = index + 1;
                      final isSelected = _rounds == rounds;
                      
                      return _RoundSelectorButton(
                        rounds: rounds,
                        isSelected: isSelected,
                        onTap: () => setState(() => _rounds = rounds),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '$_rounds ${_rounds == 1 ? 'round' : 'rounds'} selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Start Race Button
          Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32), // Pill shape
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _startRace,
                borderRadius: BorderRadius.circular(32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.play_arrow,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 28,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _isLoading ? 'Starting Race...' : 'Start Race',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quick races are saved to your history and count toward achievements. Race fast and climb the leaderboard!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
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

class _RoundSelectorButton extends StatefulWidget {
  final int rounds;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoundSelectorButton({
    required this.rounds,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoundSelectorButton> createState() => _RoundSelectorButtonState();
}

class _RoundSelectorButtonState extends State<_RoundSelectorButton>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _bounceController;
  late Animation<double> _morphAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Morph from squircle (0.0) to circle (1.0)
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
    );
    
    // Scale animation for the bounce
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    if (widget.isSelected) {
      _morphController.forward();
      _bounceController.forward();
    }
  }

  @override
  void didUpdateWidget(_RoundSelectorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _morphController.forward();
        _bounceController.reset();
        _bounceController.forward();
      } else {
        _morphController.reverse();
        _bounceController.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_morphAnimation, _scaleAnimation]),
        builder: (context, child) {
          // Calculate border radius: squircle (16) to circle (28)
          final borderRadius = Tween<double>(
            begin: 16.0, // Squircle
            end: 28.0,   // Circle
          ).evaluate(_morphAnimation);
          
          final scale = widget.isSelected 
            ? (1.0 + (_scaleAnimation.value - 1.0)) 
            : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  width: widget.isSelected ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: widget.isSelected ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ] : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isSelected ? 18 : 16,
                  ),
                  child: Text('${widget.rounds}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}