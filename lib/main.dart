// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dispense_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/database_status_screen.dart';
import 'screens/database_management_screen.dart';
import 'models/settings.dart';
import 'services/logger_service.dart';
import 'env.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    LoggerService.info('🚀 Starting Smart Rice Dispenser App...');

    // Initialize environment variables first
    await Env.initialize();

    // Initialize Supabase directly when in demo mode
    if (SupabaseConfig.useDemoMode) {
      LoggerService.info('Using demo mode - skipping Supabase initialization');
    } else {
      // Initialize Supabase directly before creating SupabaseService
      LoggerService.info(
          'Initializing Supabase with URL: ${SupabaseConfig.url}');
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      LoggerService.info('Supabase initialized successfully');
    }

    // Now initialize our service
    await SupabaseService().initialize();

    // Preload settings
    LoggerService.debug('Loading app settings...');
    final settings = await SupabaseService().getSettings();
    LoggerService.info('✅ App initialization completed successfully');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsNotifier>(
              create: (_) => SettingsNotifier(settings)),
        ],
        child: const SmartRiceApp(),
      ),
    );
  } catch (e, stackTrace) {
    LoggerService.error('❌ Failed to initialize app', e, stackTrace);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SmartRiceApp extends StatelessWidget {
  const SmartRiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Rice Container',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/dispense': (context) => const DispenseScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/database-status': (context) => const DatabaseStatusScreen(),
        '/database-management': (context) => const DatabaseManagementScreen(),
      },
      // Add error handling for route errors
      onGenerateRoute: (settings) {
        LoggerService.warning('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('Page not found'),
            ),
          ),
        );
      },
    );
  }
}

/// A simple ChangeNotifier to hold settings
class SettingsNotifier extends ChangeNotifier {
  Settings _settings;
  SettingsNotifier(this._settings);

  Settings get settings => _settings;

  void update(Settings newSettings) {
    LoggerService.debug('Updating app settings: ${newSettings.toString()}');
    _settings = newSettings;
    notifyListeners();
  }
}
