import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('No .env file found, using environment variables');
  }
  
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
    
    // Get Supabase credentials from .env file or environment variables
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 
                       const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
                           const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: _getTextScaler(context),
          ),
          child: child!,
        );
      },
    );
  }

  TextScaler _getTextScaler(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    
    // Base scale factor on the shortest side of the screen
    // This ensures consistent scaling across different orientations
    double scaleFactor;
    
    if (shortestSide < 320) {
      // Very small phones (iPhone SE 1st gen, etc.)
      scaleFactor = 0.8;
    } else if (shortestSide < 375) {
      // Small phones (iPhone SE 2nd/3rd gen, etc.)
      scaleFactor = 0.9;
    } else if (shortestSide < 414) {
      // Standard phones (iPhone 12/13/14, etc.)
      scaleFactor = 1.0;
    } else if (shortestSide < 500) {
      // Large phones (iPhone Pro Max, etc.)
      scaleFactor = 1.05;
    } else if (shortestSide < 768) {
      // Small tablets
      scaleFactor = 1.1;
    } else if (shortestSide < 1024) {
      // Large tablets
      scaleFactor = 1.15;
    } else {
      // Desktop screens
      scaleFactor = 1.2;
    }
    
    // Additional adjustment for very tall/short screens
    final aspectRatio = screenWidth / screenHeight;
    if (aspectRatio > 2.0) {
      // Very wide screens (landscape tablets, etc.)
      scaleFactor *= 0.95;
    } else if (aspectRatio < 0.5) {
      // Very tall screens
      scaleFactor *= 0.95;
    }
    
    // Clamp the scale factor to reasonable bounds
    scaleFactor = scaleFactor.clamp(0.75, 1.3);
    
    return TextScaler.linear(scaleFactor);
  }
}