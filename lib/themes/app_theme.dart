import 'package:flutter/material.dart';

class AppThemeData {
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Brightness brightness;

  const AppThemeData({
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.brightness,
  });

  ThemeData get themeData {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: surfaceColor,
      secondary: secondaryColor,
    );

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      
      // Typography improvements for Material 3 expressive
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w400, letterSpacing: -0.25),
        displayMedium: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
        displaySmall: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
        headlineLarge: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
        headlineMedium: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
        headlineSmall: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
        titleLarge: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0),
        titleMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.15),
        titleSmall: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodyLarge: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.5),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.25),
        bodySmall: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.1),
        labelMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
        labelSmall: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
      
      // AppBar with Material 3 expressive design
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      
      // Enhanced card design with Material 3 elevations
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.transparent,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(0),
      ),
      
      // Modern button designs
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
      
      // Enhanced chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
          color: colorScheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Tab bar improvements
      tabBarTheme: TabBarThemeData(
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
      ),
      
      // Enhanced dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 6,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      
      // Modern snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
      ),
      
      // List tile improvements
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}

class AppThemes {
  static const List<AppThemeData> themes = [
    // 1. Classic Blue (Default)
    AppThemeData(
      name: 'Classic Blue',
      description: 'Clean and professional',
      icon: Icons.business,
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF03DAC6),
      backgroundColor: Color(0xFFF5F5F5),
      surfaceColor: Colors.white,
      brightness: Brightness.light,
    ),

    // 2. Ocean Breeze
    AppThemeData(
      name: 'Ocean Breeze',
      description: 'Calm ocean vibes',
      icon: Icons.waves,
      primaryColor: Color(0xFF006064),
      secondaryColor: Color(0xFF4DD0E1),
      backgroundColor: Color(0xFFE0F7FA),
      surfaceColor: Color(0xFFF1F8FF),
      brightness: Brightness.light,
    ),

    // 3. Forest Green
    AppThemeData(
      name: 'Forest Green',
      description: 'Natural and refreshing',
      icon: Icons.forest,
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF81C784),
      backgroundColor: Color(0xFFE8F5E8),
      surfaceColor: Color(0xFFF1F8E9),
      brightness: Brightness.light,
    ),

    // 4. Sunset Orange
    AppThemeData(
      name: 'Sunset Orange',
      description: 'Warm and energetic',
      icon: Icons.wb_sunny,
      primaryColor: Color(0xFFE65100),
      secondaryColor: Color(0xFFFFCC02),
      backgroundColor: Color(0xFFFFF3E0),
      surfaceColor: Color(0xFFFFF8E1),
      brightness: Brightness.light,
    ),

    // 5. Royal Purple
    AppThemeData(
      name: 'Royal Purple',
      description: 'Elegant and luxurious',
      icon: Icons.diamond,
      primaryColor: Color(0xFF6A1B9A),
      secondaryColor: Color(0xFFBA68C8),
      backgroundColor: Color(0xFFF3E5F5),
      surfaceColor: Color(0xFFFCE4EC),
      brightness: Brightness.light,
    ),

    // 6. Cherry Red
    AppThemeData(
      name: 'Cherry Red',
      description: 'Bold and passionate',
      icon: Icons.favorite,
      primaryColor: Color(0xFFC62828),
      secondaryColor: Color(0xFFE57373),
      backgroundColor: Color(0xFFFFEBEE),
      surfaceColor: Color(0xFFFFF5F5),
      brightness: Brightness.light,
    ),

    // 7. Midnight Dark
    AppThemeData(
      name: 'Midnight Dark',
      description: 'Sleek dark mode',
      icon: Icons.nightlight,
      primaryColor: Color(0xFF1976D2),
      secondaryColor: Color(0xFF64B5F6),
      backgroundColor: Color(0xFF121212),
      surfaceColor: Color(0xFF1E1E1E),
      brightness: Brightness.dark,
    ),

    // 8. Cyber Neon
    AppThemeData(
      name: 'Cyber Neon',
      description: 'Futuristic and electric',
      icon: Icons.computer,
      primaryColor: Color(0xFF00E676),
      secondaryColor: Color(0xFF1DE9B6),
      backgroundColor: Color(0xFF0D1117),
      surfaceColor: Color(0xFF161B22),
      brightness: Brightness.dark,
    ),

    // 9. Coffee Brown
    AppThemeData(
      name: 'Coffee Brown',
      description: 'Warm and cozy',
      icon: Icons.local_cafe,
      primaryColor: Color(0xFF5D4037),
      secondaryColor: Color(0xFFA1887F),
      backgroundColor: Color(0xFFFFF8E1),
      surfaceColor: Color(0xFFFFF9C4),
      brightness: Brightness.light,
    ),

    // 10. Arctic Blue
    AppThemeData(
      name: 'Arctic Blue',
      description: 'Cool and minimal',
      icon: Icons.ac_unit,
      primaryColor: Color(0xFF0277BD),
      secondaryColor: Color(0xFF4FC3F7),
      backgroundColor: Color(0xFFE1F5FE),
      surfaceColor: Color(0xFFF0F8FF),
      brightness: Brightness.light,
    ),

    // 11. Cotton Candy
    AppThemeData(
      name: 'Cotton Candy',
      description: 'Sweet and playful',
      icon: Icons.cake,
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFF9C27B0),
      backgroundColor: Color(0xFFFCE4EC),
      surfaceColor: Color(0xFFF8BBD9),
      brightness: Brightness.light,
    ),

    // 13. Lavender Dreams
    AppThemeData(
      name: 'Lavender Dreams',
      description: 'Soft and serene',
      icon: Icons.local_florist,
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFFAB47BC),
      backgroundColor: Color(0xFFF3E5F5),
      surfaceColor: Color.fromARGB(255, 231, 217, 234),
      brightness: Brightness.light,
    ),

    // 14. Electric Lime
    AppThemeData(
      name: 'Electric Lime',
      description: 'Bright and energizing',
      icon: Icons.flash_on,
      primaryColor: Color(0xFF8BC34A),
      secondaryColor: Color(0xFFCDDC39),
      backgroundColor: Color(0xFFF1F8E9),
      surfaceColor: Color(0xFFDCEDC8),
      brightness: Brightness.light,
    ),

    // 15. Cosmic Purple
    AppThemeData(
      name: 'Cosmic Purple',
      description: 'Deep space vibes',
      icon: Icons.stars,
      primaryColor: Color(0xFF512DA8),
      secondaryColor: Color(0xFF7C4DFF),
      backgroundColor: Color(0xFF0A0A0A),
      surfaceColor: Color(0xFF1A1A2E),
      brightness: Brightness.dark,
    ),

    // 16. Autumn Leaves
    AppThemeData(
      name: 'Autumn Leaves',
      description: 'Cozy fall colors',
      icon: Icons.park,
      primaryColor: Color(0xFFBF360C),
      secondaryColor: Color(0xFFFF8A65),
      backgroundColor: Color(0xFFFBE9E7),
      surfaceColor: Color(0xFFFFE0B2),
      brightness: Brightness.light,
    ),

    // 17. Mint Fresh
    AppThemeData(
      name: 'Mint Fresh',
      description: 'Clean and refreshing',
      icon: Icons.eco,
      primaryColor: Color(0xFF00796B),
      secondaryColor: Color(0xFF4DB6AC),
      backgroundColor: Color(0xFFE0F2F1),
      surfaceColor: Color(0xFFB2DFDB),
      brightness: Brightness.light,
    ),

    // 18. Rose Gold
    AppThemeData(
      name: 'Rose Gold',
      description: 'Elegant and trendy',
      icon: Icons.star,
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFFFF9800),
      backgroundColor: Color(0xFFFCE4EC),
      surfaceColor: Color(0xFFF8BBD9),
      brightness: Brightness.light,
    ),

    // 19. Deep Ocean
    AppThemeData(
      name: 'Deep Ocean',
      description: 'Mysterious depths',
      icon: Icons.water,
      primaryColor: Color(0xFF1A237E),
      secondaryColor: Color(0xFF3F51B5),
      backgroundColor: Color(0xFF0A1628),
      surfaceColor: Color(0xFF1E2A3A),
      brightness: Brightness.dark,
    ),

    // 20. Peachy Keen
    AppThemeData(
      name: 'Peachy Keen',
      description: 'Soft and cheerful',
      icon: Icons.sentiment_satisfied,
      primaryColor: Color(0xFFFF7043),
      secondaryColor: Color(0xFFFFAB91),
      backgroundColor: Color(0xFFFFF3E0),
      surfaceColor: Color(0xFFFFE0B2),
      brightness: Brightness.light,
    ),

    // 21. Steel Gray
    AppThemeData(
      name: 'Steel Gray',
      description: 'Modern industrial',
      icon: Icons.build,
      primaryColor: Color(0xFF455A64),
      secondaryColor: Color(0xFF78909C),
      backgroundColor: Color(0xFFECEFF1),
      surfaceColor: Color(0xFFCFD8DC),
      brightness: Brightness.light,
    ),

    // 22. Neon Pink
    AppThemeData(
      name: 'Neon Pink',
      description: 'Bold and electric',
      icon: Icons.whatshot,
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFFFF4081),
      backgroundColor: Color(0xFF121212),
      surfaceColor: Color(0xFF1E1E2E),
      brightness: Brightness.dark,
    ),

    // 23. Sky Blue
    AppThemeData(
      name: 'Sky Blue',
      description: 'Open and airy',
      icon: Icons.cloud,
      primaryColor: Color(0xFF03A9F4),
      secondaryColor: Color(0xFF00BCD4),
      backgroundColor: Color(0xFFE1F5FE),
      surfaceColor: Color(0xFFB3E5FC),
      brightness: Brightness.light,
    ),

    // 24. Midnight Purple
    AppThemeData(
      name: 'Midnight Purple',
      description: 'Rich and mysterious',
      icon: Icons.nights_stay,
      primaryColor: Color(0xFF4A148C),
      secondaryColor: Color(0xFF7B1FA2),
      backgroundColor: Color(0xFF0F0F0F),
      surfaceColor: Color(0xFF1A0E27),
      brightness: Brightness.dark,
    ),
  ];

  static AppThemeData getThemeByName(String name) {
    return themes.firstWhere(
      (theme) => theme.name == name,
      orElse: () => themes.first, // Default to Classic Blue
    );
  }

  static int getThemeIndex(String name) {
    return themes.indexWhere((theme) => theme.name == name);
  }
}