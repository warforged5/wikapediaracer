import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/player.dart';
import '../services/tournament_service.dart';
import '../widgets/player_selector_dialog.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TournamentFormat _selectedFormat = TournamentFormat.singleElimination;
  int _maxParticipants = 8;
  DateTime? _startTime;
  bool _isLoading = false;
  Player? _selectedOrganizer;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tournament Name',
                      hintText: 'Enter a name for your tournament',
                      prefixIcon: Icon(Icons.emoji_events_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a tournament name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tournament Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Describe your tournament...',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tournament Organizer
                  Text(
                    'Tournament Organizer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectOrganizer,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedOrganizer?.name ?? 'Select organizer...',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _selectedOrganizer == null
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tournament Format
                  Text(
                    'Tournament Format',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...TournamentFormat.values.map((format) => RadioListTile<TournamentFormat>(
                    title: Text(_formatTournamentFormat(format)),
                    subtitle: Text(_getFormatDescription(format)),
                    value: format,
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                        // Adjust max participants based on format
                        if (format == TournamentFormat.singleElimination || 
                            format == TournamentFormat.doubleElimination) {
                          _maxParticipants = _getNearestPowerOfTwo(_maxParticipants);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 24),

                  // Max Participants
                  Text(
                    'Maximum Participants',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxParticipants.toDouble(),
                          min: 4,
                          max: 32,
                          divisions: _selectedFormat == TournamentFormat.singleElimination
                              ? 4 // Powers of 2: 4, 8, 16, 32
                              : 28, // All values 4-32
                          label: '$_maxParticipants players',
                          onChanged: (value) {
                            setState(() {
                              if (_selectedFormat == TournamentFormat.singleElimination ||
                                  _selectedFormat == TournamentFormat.doubleElimination) {
                                _maxParticipants = _getNearestPowerOfTwo(value.round());
                              } else {
                                _maxParticipants = value.round();
                              }
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_maxParticipants',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Start Time
                  Text(
                    'Start Time (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectStartTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _startTime == null
                                ? 'Tap to set start time'
                                : _formatDateTime(_startTime!),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _startTime == null
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (_startTime != null)
                            IconButton(
                              onPressed: () => setState(() => _startTime = null),
                              icon: const Icon(Icons.clear_rounded),
                              iconSize: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _createTournament,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_rounded),
                      label: Text(_isLoading ? 'Creating...' : 'Create Tournament'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTournamentFormat(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.singleElimination:
        return 'Single Elimination';
      case TournamentFormat.doubleElimination:
        return 'Double Elimination';
      case TournamentFormat.roundRobin:
        return 'Round Robin';
      case TournamentFormat.swiss:
        return 'Swiss System';
    }
  }

  String _getFormatDescription(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.singleElimination:
        return 'Players are eliminated after one loss. Fast-paced bracket format.';
      case TournamentFormat.doubleElimination:
        return 'Players have two chances. Losers bracket for second chances.';
      case TournamentFormat.roundRobin:
        return 'Everyone plays everyone else once. Most wins determines winner.';
      case TournamentFormat.swiss:
        return 'Players with similar records are paired. Balanced competition.';
    }
  }

  int _getNearestPowerOfTwo(int value) {
    final powers = [4, 8, 16, 32];
    int closest = powers[0];
    int minDiff = (powers[0] - value).abs();

    for (final power in powers) {
      final diff = (power - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = power;
      }
    }

    return closest;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (dateOnly == today) {
      dateStr = 'Today';
    } else if (dateOnly == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  Future<void> _selectOrganizer() async {
    final player = await showDialog<Player>(
      context: context,
      builder: (context) => const PlayerSelectorDialog(
        title: 'Select Tournament Organizer',
        subtitle: 'Choose who will organize this tournament',
      ),
    );

    if (player != null) {
      setState(() {
        _selectedOrganizer = player;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now().add(const Duration(hours: 1))),
      );

      if (time != null && mounted) {
        setState(() {
          _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOrganizer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tournament organizer')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await TournamentService.instance.createTournament(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        format: _selectedFormat,
        maxParticipants: _maxParticipants,
        initialParticipants: [_selectedOrganizer!],
        startTime: _startTime,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament created successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create tournament: $e')),
        );
      }
    }
  }
}