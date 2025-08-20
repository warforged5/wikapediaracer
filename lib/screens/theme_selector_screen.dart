import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../services/theme_service.dart';

class ThemeSelectorScreen extends StatefulWidget {
  final Function(AppThemeData) onThemeChanged;

  const ThemeSelectorScreen({super.key, required this.onThemeChanged});

  @override
  State<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen> {
  String _selectedTheme = 'Classic Blue';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final currentTheme = await ThemeService.instance.getSavedThemeName();
    setState(() {
      _selectedTheme = currentTheme;
      _isLoading = false;
    });
  }

  Future<void> _selectTheme(AppThemeData theme) async {
    setState(() {
      _selectedTheme = theme.name;
    });

    // Save theme and notify parent
    await ThemeService.instance.saveTheme(theme.name);
    widget.onThemeChanged(theme);

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme changed to ${theme.name}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Theme',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isWeb ? 24 : 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.palette,
                              size: isWeb ? 48 : 36,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: isWeb ? 16 : 12),
                            Text(
                              'Personalize Your Experience',
                              style: TextStyle(
                                fontSize: isWeb ? 24 : 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isWeb ? 8 : 6),
                            Text(
                              'Choose from 10 beautiful themes to make Wikipedia Racer your own',
                              style: TextStyle(
                                fontSize: isWeb ? 16 : 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isWeb ? 32 : 24),

                      // Theme Grid
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWeb ? 5 : isTablet ? 3 : 2,
                            crossAxisSpacing: isWeb ? 20 : 12,
                            mainAxisSpacing: isWeb ? 20 : 12,
                            childAspectRatio: isWeb ? 0.9 : 0.85,
                          ),
                          itemCount: AppThemes.themes.length,
                          itemBuilder: (context, index) {
                            final theme = AppThemes.themes[index];
                            final isSelected = _selectedTheme == theme.name;

                            return _buildThemeCard(theme, isSelected, isWeb);
                          },
                        ),
                      ),

                      // Bottom info
                      if (isWeb) ...[
                        SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your theme preference is automatically saved and will be applied across all screens.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildThemeCard(AppThemeData theme, bool isSelected, bool isWeb) {
    return Card(
      elevation: isSelected ? 8 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected 
            ? theme.primaryColor.withValues(alpha: 0.6)
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 3 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectTheme(theme),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Theme preview header
              Container(
                width: double.infinity,
                height: isWeb ? 80 : 60,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: theme.secondaryColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -5,
                      bottom: -15,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Theme icon
                    Center(
                      child: Icon(
                        theme.icon,
                        color: theme.brightness == Brightness.light 
                          ? Colors.white 
                          : Colors.white,
                        size: isWeb ? 32 : 24,
                      ),
                    ),
                    // Selected indicator
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check,
                            color: theme.primaryColor,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Theme info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isWeb ? 16 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: TextStyle(
                          fontSize: isWeb ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                            ? theme.primaryColor 
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isWeb ? 8 : 6),
                      Expanded(
                        child: Text(
                          theme.description,
                          style: TextStyle(
                            fontSize: isWeb ? 13 : 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                          maxLines: isWeb ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: isWeb ? 12 : 8),
                      
                      // Color preview dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: isWeb ? 16 : 12,
                            height: isWeb ? 16 : 12,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: isWeb ? 16 : 12,
                            height: isWeb ? 16 : 12,
                            decoration: BoxDecoration(
                              color: theme.secondaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: isWeb ? 16 : 12,
                            height: isWeb ? 16 : 12,
                            decoration: BoxDecoration(
                              color: theme.backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}