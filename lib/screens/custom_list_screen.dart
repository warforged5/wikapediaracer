import 'package:flutter/material.dart';
import '../models/custom_list.dart';
import '../services/storage_service.dart';
import 'race_screen.dart';
import '../models/player.dart';

class CustomListScreen extends StatefulWidget {
  final List<Player> players;
  final int rounds;
  final String? groupId;

  const CustomListScreen({
    super.key,
    required this.players,
    required this.rounds,
    this.groupId,
  });

  @override
  State<CustomListScreen> createState() => _CustomListScreenState();
}

class _CustomListScreenState extends State<CustomListScreen> {
  final _nameController = TextEditingController();
  final _pagesController = TextEditingController();
  final _scrollController = ScrollController();
  int _optionCount = 5;
  bool _isLoading = false;
  List<CustomList> _savedLists = [];
  CustomList? _selectedList;

  @override
  void initState() {
    super.initState();
    _loadSavedLists();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pagesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLists() async {
    final lists = await StorageService.instance.getCustomLists();
    setState(() {
      _savedLists = lists;
    });
  }

  List<String> _parsePages(String input) {
    if (input.trim().isEmpty) return [];
    
    // Split by both commas and newlines, trim whitespace, remove empty strings
    final pages = input
        .split(RegExp(r'[,\n]'))
        .map((page) => page.trim())
        .where((page) => page.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();
    
    return pages;
  }

  void _validateAndProceed() {
    if (_selectedList != null) {
      _startRaceWithList(_selectedList!);
      return;
    }

    final pages = _parsePages(_pagesController.text);
    
    if (pages.length < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least 30 Wikipedia pages. Currently: ${pages.length}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    if (_optionCount > pages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Option count cannot be more than total pages (${pages.length})'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    _startRaceWithPages(pages);
  }

  Future<void> _saveList() async {
    final pages = _parsePages(_pagesController.text);
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the list')),
      );
      return;
    }
    
    if (pages.length < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least 30 Wikipedia pages. Currently: ${pages.length}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final customList = CustomList.create(name: name, pages: pages);
      await StorageService.instance.saveCustomList(customList);
      await _loadSavedLists();
      
      _nameController.clear();
      _pagesController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('List "$name" saved with ${pages.length} pages'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving list: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteList(CustomList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.deleteCustomList(list.id);
      await _loadSavedLists();
      if (_selectedList?.id == list.id) {
        setState(() => _selectedList = null);
      }
    }
  }

  void _startRaceWithPages(List<String> pages) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaceScreen(
          players: widget.players,
          rounds: widget.rounds,
          groupId: widget.groupId,
          customPages: pages,
          optionCount: _optionCount,
        ),
      ),
    );
  }

  void _startRaceWithList(CustomList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaceScreen(
          players: widget.players,
          rounds: widget.rounds,
          groupId: widget.groupId,
          customPages: list.pages,
          optionCount: _optionCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _parsePages(_pagesController.text);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Lists'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Saved Lists Section
          if (_savedLists.isNotEmpty) ...[
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
                      'Saved Lists',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a saved list to use for racing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._savedLists.map((list) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedList?.id == list.id
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          width: _selectedList?.id == list.id ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedList?.id == list.id
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
                            : null,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(list.name),
                        subtitle: Text('${list.pages.length} pages'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _deleteList(list),
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        selected: _selectedList?.id == list.id,
                        onTap: () {
                          setState(() {
                            _selectedList = _selectedList?.id == list.id ? null : list;
                          });
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Create New List Section
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
                    'Create New List',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter at least 30 Wikipedia page titles separated by commas or newlines',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List Name Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'List Name (Optional)',
                      prefixIcon: const Icon(Icons.list_alt),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pages Input Field
                  TextField(
                    controller: _pagesController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Wikipedia Pages',
                      hintText: 'Albert Einstein, Marie Curie, Isaac Newton...\nor one page per line',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Page Count Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${pages.length} pages entered',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: pages.length >= 30
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_nameController.text.trim().isNotEmpty && pages.length >= 30)
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _saveList,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: const Text('Save List'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Options Section
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
                    'Race Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how many page options to show during the race',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      final count = index + 3; // 3-8 options
                      final isSelected = _optionCount == count;
                      
                      return _AnimatedOptionButton(
                        count: count,
                        isSelected: isSelected,
                        onTap: () => setState(() => _optionCount = count),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '$_optionCount page options during race',
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
              borderRadius: BorderRadius.circular(32),
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
                onTap: (_selectedList != null || pages.length >= 30) ? _validateAndProceed : null,
                borderRadius: BorderRadius.circular(32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Start Custom Race',
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
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom lists replace the random Wikipedia API. Make sure page titles are exact matches to Wikipedia articles.',
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

class _AnimatedOptionButton extends StatefulWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedOptionButton({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedOptionButton> createState() => _AnimatedOptionButtonState();
}

class _AnimatedOptionButtonState extends State<_AnimatedOptionButton>
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
  void didUpdateWidget(_AnimatedOptionButton oldWidget) {
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
          // Calculate border radius: squircle (12) to circle (24)
          final borderRadius = Tween<double>(
            begin: 12.0, // Squircle
            end: 24.0,   // Circle
          ).evaluate(_morphAnimation);
          
          final scale = widget.isSelected 
            ? (1.0 + (_scaleAnimation.value - 1.0)) 
            : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
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
                  child: Text('${widget.count}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}