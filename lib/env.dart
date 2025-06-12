import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment variables manager
class Env {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project-id.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-supabase-anon-key';

  static bool get useDemoMode =>
      dotenv.env['USE_DEMO_MODE']?.toLowerCase() == 'true';

  /// Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      print('Environment variables loaded successfully.');
    } catch (e) {
      // If .env file doesn't exist, we'll use the fallback values
      print(
          'Warning: .env file not found or could not be loaded. Using default values.');
    }
  }
}
