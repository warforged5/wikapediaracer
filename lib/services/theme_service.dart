import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';
  static const String _defaultTheme = 'Classic Blue';
  
  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();
  ThemeService._();

  /// Get the currently saved theme
  Future<AppThemeData> getSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey) ?? _defaultTheme;
      return AppThemes.getThemeByName(themeName);
    } catch (e) {
      // Return default theme if there's an error
      return AppThemes.getThemeByName(_defaultTheme);
    }
  }

  /// Save the selected theme
  Future<bool> saveTheme(String themeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_themeKey, themeName);
    } catch (e) {
      return false;
    }
  }

  /// Get the saved theme name
  Future<String> getSavedThemeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey) ?? _defaultTheme;
    } catch (e) {
      return _defaultTheme;
    }
  }

  /// Check if a theme is currently selected
  Future<bool> isThemeSelected(String themeName) async {
    final currentTheme = await getSavedThemeName();
    return currentTheme == themeName;
  }
}