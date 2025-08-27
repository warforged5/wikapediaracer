import 'package:flutter/material.dart';
import '../models/group.dart';
import 'race_screen.dart';
import 'custom_list_screen.dart';

class GroupRaceSetupScreen extends StatefulWidget {
  final Group group;

  const GroupRaceSetupScreen({super.key, required this.group});

  @override
  State<GroupRaceSetupScreen> createState() => _GroupRaceSetupScreenState();
}

class _GroupRaceSetupScreenState extends State<GroupRaceSetupScreen> {
  final Set<String> _selectedPlayerIds = <String>{};
  int _rounds = 3;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Select all players by default
    _selectedPlayerIds.addAll(widget.group.players.map((p) => p.id));
  }

  Future<void> _startRace() async {
    if (_selectedPlayerIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 players must be selected')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedPlayers = widget.group.players
          .where((p) => _selectedPlayerIds.contains(p.id))
          .toList();
      
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => RaceScreen(
              players: selectedPlayers,
              rounds: _rounds,
              groupId: widget.group.id,
            ),
          ),
        );
        
        if (result == true && mounted) {
          Navigator.pop(context, true);
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

  void _togglePlayer(String playerId) {
    setState(() {
      if (_selectedPlayerIds.contains(playerId)) {
        _selectedPlayerIds.remove(playerId);
      } else {
        _selectedPlayerIds.add(playerId);
      }
    });
  }

  void _selectAllPlayers() {
    setState(() {
      _selectedPlayerIds.clear();
      _selectedPlayerIds.addAll(widget.group.players.map((p) => p.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPlayerIds.clear();
    });
  }

  void _navigateToCustomList() {
    if (_selectedPlayerIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 players must be selected')),
      );
      return;
    }

    final selectedPlayers = widget.group.players
        .where((p) => _selectedPlayerIds.contains(p.id))
        .toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomListScreen(
          players: selectedPlayers,
          rounds: _rounds,
          groupId: widget.group.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} Race'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Player Selection Section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
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
                        'Select Players',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _selectAllPlayers,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      height: 34,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(19),
                                          bottomLeft: Radius.circular(19),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'All',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 20,
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _clearSelection,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      height: 34,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(19),
                                          bottomRight: Radius.circular(19),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'None',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedPlayerIds.length} of ${widget.group.players.length} players selected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Player checkboxes
                  ...widget.group.players.map((player) {
                    final isSelected = _selectedPlayerIds.contains(player.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surface,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _togglePlayer(player.id),
                        title: Text(player.name),
                        subtitle: Text('${player.totalWins} wins • ${player.totalRaces} races'),
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            player.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

          const SizedBox(height: 16),

          // Custom List Button
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToCustomList(),
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Use Custom List',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Start Race Button
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: (_isLoading || _selectedPlayerIds.length < 2) ? null : _startRace,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, size: 24),
              label: Text(
                _isLoading 
                    ? 'Starting Race...' 
                    : _selectedPlayerIds.length < 2 
                        ? 'Select 2+ Players'
                        : 'Start Race',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This race will be saved to your group history and player statistics will be updated.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
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