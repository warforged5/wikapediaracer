import 'package:flutter/material.dart';
import '../models/group.dart';
import 'race_screen.dart';

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
                        'Select Players',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _selectAllPlayers,
                            child: const Text('All'),
                          ),
                          TextButton(
                            onPressed: _clearSelection,
                            child: const Text('None'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedPlayerIds.length} of ${widget.group.players.length} players selected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                            : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surface,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _togglePlayer(player.id),
                        title: Text(player.name),
                        subtitle: Text('${player.totalWins} wins • ${player.totalRaces} races'),
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                      
                      return GestureDetector(
                        onTap: () => setState(() => _rounds = rounds),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Center(
                            child: Text(
                              '$rounds',
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
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
              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
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