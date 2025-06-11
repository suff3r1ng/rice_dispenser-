// lib/config/supabase_config.dart
class SupabaseConfig {
  // TODO: Replace these with your actual Supabase project credentials
  // Go to https://supabase.com/dashboard to create a new project

  static const String supabaseUrl = 'https://hdzuqgojojdtcemxxkbt.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhkenVxZ29qb2pkdGNlbXh4a2J0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY2MzIzOTEsImV4cCI6MjA2MjIwODM5MX0.l6idHd0WrNkIfZ5uRAiKRD-Ump7HOIxROy0DMSYq7q0';

  // For development/testing, you can use these demo values (they won't work for real connections):
  static const String demoUrl = 'https://demo.supabase.co';
  static const String demoKey = 'demo_key_for_testing';

  // Set this to true to use demo mode (no real database connection)
  static const bool useDemoMode = false;

  static String get url => useDemoMode ? demoUrl : supabaseUrl;
  static String get anonKey => useDemoMode ? demoKey : supabaseAnonKey;
}
