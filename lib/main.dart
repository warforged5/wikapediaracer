import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:uuid/uuid.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/supabase_service.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve splash screen until app is ready
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  
  await StorageService.instance.init();
  
  // Initialize Supabase if credentials are available
  await _initializeSupabase();
  
  runApp(const WikipediaRacerApp());
}

Future<void> _initializeSupabase() async {
  try {
    // Get or generate device ID
    String? deviceId = await StorageService.instance.getDeviceId();
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await StorageService.instance.saveDeviceId(deviceId);
    }
    
    // TODO: Add your Supabase credentials here
    // These should be stored in environment variables or a config file in production
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await SupabaseService.instance.initialize(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
        deviceId: deviceId,
      );
      debugPrint('Supabase initialized successfully');
    } else {
      debugPrint('Supabase credentials not provided - running in offline mode');
    }
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }
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