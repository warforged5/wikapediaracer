import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/storage_service.dart';

class PlayerSelectorDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const PlayerSelectorDialog({
    super.key,
    this.title = 'Select Player',
    this.subtitle = 'Choose an existing player or create a new one',
  });

  @override
  State<PlayerSelectorDialog> createState() => _PlayerSelectorDialogState();
}

class _PlayerSelectorDialogState extends State<PlayerSelectorDialog> {
  List<Player> _allPlayers = [];
  bool _isLoading = true;
  bool _showNewPlayerField = false;
  final TextEditingController _newPlayerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _newPlayerController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);

    try {
      final results = await StorageService.instance.getRaceResults();
      final Set<Player> uniquePlayers = {};

      for (final result in results) {
        uniquePlayers.addAll(result.participants);
      }

      setState(() {
        _allPlayers = uniquePlayers.toList()..sort((a, b) => a.name.compareTo(b.name));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectPlayer(Player player) {
    Navigator.of(context).pop(player);
  }

  void _createNewPlayer() {
    final name = _newPlayerController.text.trim();
    if (name.isNotEmpty) {
      final newPlayer = Player(name: name);
      Navigator.of(context).pop(newPlayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // New player input
                        if (_showNewPlayerField) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _newPlayerController,
                                  decoration: const InputDecoration(
                                    labelText: 'Player Name',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_add),
                                  ),
                                  autofocus: true,
                                  onSubmitted: (_) => _createNewPlayer(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _showNewPlayerField = false;
                                            _newPlayerController.clear();
                                          });
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: _createNewPlayer,
                                        child: const Text('Create'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Existing players list
                          if (_allPlayers.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Existing Players',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _allPlayers.length,
                                itemBuilder: (context, index) {
                                  final player = _allPlayers[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        player.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(player.name),
                                    onTap: () => _selectPlayer(player),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(),
                          ],

                          // Create new player button
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showNewPlayerField = true;
                                  });
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text('Create New Player'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            // Cancel button
            if (!_showNewPlayerField)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}