// lib/config/supabase_config.dart
import '../env.dart';

class SupabaseConfig {
  // Using environment variables for Supabase credentials
  // Go to https://supabase.com/dashboard to create a new project
  // Then set these values in your .env file

  // These fallback values are used if environment variables are not set
  static const String fallbackUrl = 'https://your-project-id.supabase.co';
  static const String fallbackAnonKey = 'your-supabase-anon-key';

  // For development/testing, you can use these demo values (they won't work for real connections):
  static const String demoUrl = 'https://demo.supabase.co';
  static const String demoKey = 'demo_key_for_testing';

  // Default to demo mode if not explicitly set to false in .env
  static bool get useDemoMode {
    // If USE_DEMO_MODE is not found in .env or couldn't be parsed, default to true for safety
    return Env.useDemoMode ?? true;
  }

  // Get URL and key from environment variables with fallbacks
  static String get url => useDemoMode ? demoUrl : Env.supabaseUrl;
  static String get anonKey => useDemoMode ? demoKey : Env.supabaseAnonKey;
}
