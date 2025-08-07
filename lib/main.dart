import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  runApp(const WikipediaRacerApp());
}

class WikipediaRacerApp extends StatefulWidget {
  const WikipediaRacerApp({super.key});

  @override
  State<WikipediaRacerApp> createState() => _WikipediaRacerAppState();
}

class _WikipediaRacerAppState extends State<WikipediaRacerApp> {
  AppThemeData? _currentTheme;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.instance.getSavedTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  void _onThemeChanged(AppThemeData newTheme) {
    setState(() {
      _currentTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTheme == null) {
      return MaterialApp(
        title: 'Wikipedia Racer',
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Wikipedia Racer',
      debugShowCheckedModeBanner: false,
      theme: _currentTheme!.themeData,
      home: HomeScreen(onThemeChanged: _onThemeChanged),
    );
  }
}
