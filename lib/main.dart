import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve splash screen until app is ready
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  
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
    
    // Remove splash screen once theme is loaded and app is ready
    FlutterNativeSplash.remove();
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
