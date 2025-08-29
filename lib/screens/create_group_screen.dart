import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/player.dart';
import '../services/storage_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final List<TextEditingController> _playerControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 default players
    _addPlayerField();
    _addPlayerField();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayerField() {
    setState(() {
      _playerControllers.add(TextEditingController());
    });
  }

  void _removePlayerField(int index) {
    if (_playerControllers.length > 2) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupName = _groupNameController.text.trim();
      final playerNames = _playerControllers
          .map((c) => c.text.trim())
          .where((name) => name.isNotEmpty)
          .toSet() // Remove duplicates
          .toList();

      if (playerNames.length < 2) {
        throw Exception('At least 2 unique players are required');
      }

      final players = playerNames
          .map((name) => Player(name: name))
          .toList();

      final group = Group(name: groupName, players: players);
      await StorageService.instance.saveGroup(group);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created group "${group.name}"')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final maxContentWidth = isLargeScreen ? 800.0 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _createGroup,
              child: const Text('Create'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Form(
            key: _formKey,
            child: isLargeScreen ? _buildLargeScreenLayout() : _buildSmallScreenLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallScreenLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGroupNameCard(),
        const SizedBox(height: 16),
        _buildPlayersCard(),
        const SizedBox(height: 32),
        _buildCreateButton(),
        const SizedBox(height: 16),
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildLargeScreenLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Group',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up a racing group to compete with friends and track statistics over time',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Two-column layout
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Group Name and Info
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildGroupNameCard(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right Column - Players
                Expanded(
                  flex: 1,
                  child: _buildPlayersCard(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bottom Action
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 200,
                child: _buildCreateButton(),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupNameCard() {
    return Card(
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
              children: [
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Group Name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Enter group name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Group name is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersCard() {
    return Card(
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
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Players',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _playerControllers.length < 10 ? _addPlayerField : null,
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
              'Add at least 2 players to your group (${_playerControllers.where((c) => c.text.trim().isNotEmpty).length}/10)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            // Player Fields with improved layout for large screens
            ...List.generate(_playerControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _playerControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Player ${index + 1} name',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final playerName = value.trim();
                              final otherNames = _playerControllers
                                  .where((c) => c != _playerControllers[index])
                                  .map((c) => c.text.trim())
                                  .where((name) => name.isNotEmpty);
                              
                              if (otherNames.contains(playerName)) {
                                return 'Player names must be unique';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_playerControllers.length > 2)
                        Container(
                          width: 48,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _removePlayerField(index),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
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
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _isLoading ? null : _createGroup,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Create Group',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'About Groups',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Groups keep track of wins, losses, and race history for all members. You can add or remove players later and view detailed statistics for each group.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}