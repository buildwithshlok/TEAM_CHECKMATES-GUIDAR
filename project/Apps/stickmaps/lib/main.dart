import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stickmaps/services/multilingual_service.dart';
import 'package:stickmaps/services/speech_service.dart';
import 'controllers/navigation_controller.dart';
import 'screens/home_screen.dart';
import 'screens/language_selection_screen.dart';

import 'utils/permissions_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize multilingual service
  await MultilingualService.initialize();

  // Request all necessary permissions
  await PermissionsHelper.requestAllPermissions();

  runApp(const SmartBlindStickApp());
}

class SmartBlindStickApp extends StatelessWidget {
  const SmartBlindStickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationController()),
        Provider(create: (_) => EnhancedSpeechService()),
      ],
      child: MaterialApp(
        title: 'Smart Blind Stick',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          // High contrast theme for accessibility
          brightness: Brightness.light,
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final controller = Provider.of<NavigationController>(
      context,
      listen: false,
    );
    final speechService = Provider.of<EnhancedSpeechService>(
      context,
      listen: false,
    );

    // Initialize speech service
    await speechService.initialize();

    // Check if language is selected
    final hasLanguage = MultilingualService.currentLanguage != null;

    // Check if Bluetooth device is already paired
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Navigate to appropriate screen
    if (!hasLanguage) {
      // Show language selection first
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LanguageSelectionScreen(isFirstTime: true),
        ),
      );
    } else {
      // Go directly to home
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.accessibility_new,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart Blind Stick',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Initializing...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
