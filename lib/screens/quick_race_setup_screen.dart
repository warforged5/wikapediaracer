import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import 'race_screen.dart';
import 'custom_list_screen.dart';

class QuickRaceSetupScreen extends StatefulWidget {
  const QuickRaceSetupScreen({super.key});

  @override
  State<QuickRaceSetupScreen> createState() => _QuickRaceSetupScreenState();
}

class _QuickRaceSetupScreenState extends State<QuickRaceSetupScreen> {
  final List<TextEditingController> _playerControllers = [];
  final List<Player> _selectedProfilePlayers = [];
  int _rounds = 3;
  bool _isLoading = false;
  List<Player> _savedPlayers = [];

  @override
  void initState() {
    super.initState();
    // Start with 2 default players
    _playerControllers.add(TextEditingController(text: 'Player 1'));
    _playerControllers.add(TextEditingController(text: 'Player 2'));
    _loadSavedPlayers();
  }

  Future<void> _loadSavedPlayers() async {
    try {
      // Get all saved players and players from race results
      final savedPlayers = await StorageService.instance.getPlayers();
      final results = await StorageService.instance.getRaceResults();
      final Set<Player> uniquePlayers = {};
      
      for (final result in results) {
        uniquePlayers.addAll(result.participants);
      }
      
      final allPlayers = Set<Player>.from(savedPlayers);
      allPlayers.addAll(uniquePlayers);
      
      setState(() {
        _savedPlayers = allPlayers.toList()..sort((a, b) => a.name.compareTo(b.name));
      });
    } catch (e) {
      // Handle error silently or show a message if needed
    }
  }

  @override
  void dispose() {
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_playerControllers.length + _selectedProfilePlayers.length < 8) {
      setState(() {
        _playerControllers.add(
          TextEditingController(text: 'Player ${_playerControllers.length + _selectedProfilePlayers.length + 1}'),
        );
      });
    }
  }

  void _removePlayer(int index) {
    if (_playerControllers.length + _selectedProfilePlayers.length > 2) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
      });
    }
  }

  void _removeProfilePlayer(int index) {
    if (_playerControllers.length + _selectedProfilePlayers.length > 2) {
      setState(() {
        _selectedProfilePlayers.removeAt(index);
      });
    }
  }

  Future<void> _startRace() async {
    // Combine text field players and selected profile players
    final textPlayers = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => Player(name: name))
        .toList();
    
    final allPlayers = <Player>[...textPlayers, ..._selectedProfilePlayers]
        .toSet() // Remove duplicates by ID
        .toList();

    if (allPlayers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 unique players are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => RaceScreen(
              players: allPlayers,
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

  void _navigateToCustomList() {
    // Combine text field players and selected profile players
    final textPlayers = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => Player(name: name))
        .toList();
    
    final allPlayers = <Player>[...textPlayers, ..._selectedProfilePlayers]
        .toSet() // Remove duplicates by ID
        .toList();

    if (allPlayers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 unique players are required')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomListScreen(
          players: allPlayers,
          rounds: _rounds,
          groupId: null,
        ),
      ),
    );
  }

  Future<void> _showProfileSelector() async {
    if (_savedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved profiles found')),
      );
      return;
    }

    final selectedProfiles = await showDialog<List<Player>>(
      context: context,
      builder: (context) => _ProfileSelectorDialog(
        availableProfiles: _savedPlayers,
        alreadySelected: _selectedProfilePlayers,
      ),
    );

    if (selectedProfiles != null) {
      setState(() {
        _selectedProfilePlayers.clear();
        _selectedProfilePlayers.addAll(selectedProfiles);
      });
    }
  }

  Widget _buildPlayerTextField(int index) {
    return TextField(
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
    );
  }

  Widget _buildProfilePlayerCard(int index) {
    final player = _selectedProfilePlayers[index];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            player.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(player.name),
        subtitle: const Text('Saved Profile'),
        trailing: (_playerControllers.length + _selectedProfilePlayers.length > 2)
            ? IconButton(
                onPressed: () => _removeProfilePlayer(index),
                icon: Icon(
                  Icons.remove_circle,
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Race Setup'),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLargeScreen ? _buildLargeScreenLayout(context) : _buildMobileLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Players Section
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
                        'Players',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          if (_savedPlayers.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: (_playerControllers.length + _selectedProfilePlayers.length < 8) 
                                  ? _showProfileSelector 
                                  : null,
                              icon: const Icon(Icons.people, size: 18),
                              label: const Text('Add Profile'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if (_savedPlayers.isNotEmpty) const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: (_playerControllers.length + _selectedProfilePlayers.length < 8) 
                                ? _addPlayer 
                                : null,
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter custom names or select from saved profiles',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text input fields
                  ...List.generate(_playerControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: _buildPlayerTextField(index)),
                          if (_playerControllers.length + _selectedProfilePlayers.length > 2)
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
                  
                  // Profile player cards
                  ...List.generate(_selectedProfilePlayers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildProfilePlayerCard(index),
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
      );
  }

  Widget _buildLargeScreenLayout(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Players and Rounds
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Players Section
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Players',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  if (_savedPlayers.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: (_playerControllers.length + _selectedProfilePlayers.length < 8) 
                                          ? _showProfileSelector 
                                          : null,
                                      icon: const Icon(Icons.people, size: 18),
                                      label: const Text('Add Profile'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  if (_savedPlayers.isNotEmpty) const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: (_playerControllers.length + _selectedProfilePlayers.length < 8) 
                                        ? _addPlayer 
                                        : null,
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter custom names or select from saved profiles',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Player fields in a more compact layout for large screens
                          ...List.generate(_playerControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(child: _buildPlayerTextField(index)),
                                  if (_playerControllers.length + _selectedProfilePlayers.length > 2)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: IconButton(
                                        onPressed: () => _removePlayer(index),
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          
                          // Profile player cards
                          ...List.generate(_selectedProfilePlayers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildProfilePlayerCard(index),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of Rounds',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Each round requires reaching a different Wikipedia page',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 24),

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
                          
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              '$_rounds ${_rounds == 1 ? 'round' : 'rounds'} selected',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 32),
            
            // Right column - Actions
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Custom List Button
                  Container(
                    height: 72,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
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
                        borderRadius: BorderRadius.circular(36),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list_alt,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Use Custom List',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

                  const SizedBox(height: 24),

                  // Start Race Button
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
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
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _startRace,
                        borderRadius: BorderRadius.circular(40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.play_arrow,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 32,
                                ),
                              const SizedBox(width: 16),
                              Text(
                                _isLoading ? 'Starting Race...' : 'Start Race',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Quick races are saved to your history and count toward achievements. Race fast and climb the leaderboard!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
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

class _ProfileSelectorDialog extends StatefulWidget {
  final List<Player> availableProfiles;
  final List<Player> alreadySelected;

  const _ProfileSelectorDialog({
    required this.availableProfiles,
    required this.alreadySelected,
  });

  @override
  State<_ProfileSelectorDialog> createState() => _ProfileSelectorDialogState();
}

class _ProfileSelectorDialogState extends State<_ProfileSelectorDialog> {
  final Set<Player> _selectedPlayers = {};

  @override
  void initState() {
    super.initState();
    _selectedPlayers.addAll(widget.alreadySelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.people),
          SizedBox(width: 8),
          Text('Select Profiles'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              'Choose one or more profiles to add to the race',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.availableProfiles.length,
                itemBuilder: (context, index) {
                  final player = widget.availableProfiles[index];
                  final isSelected = _selectedPlayers.contains(player);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedPlayers.add(player);
                          } else {
                            _selectedPlayers.remove(player);
                          }
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          player.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        player.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: FutureBuilder<Map<String, int>>(
                        future: StorageService.instance.getPlayerStats(player.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final stats = snapshot.data!;
                            return Text(
                              '${stats['wins']} wins • ${stats['totalRaces']} races',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const Text('Loading stats...');
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedPlayers.toList()),
          child: Text('Add ${_selectedPlayers.length} Profile${_selectedPlayers.length == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}