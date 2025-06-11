// scripts/setup_real_database.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/config/supabase_config.dart';
import '../lib/services/logger_service.dart';

/// This script helps set up the real Supabase database by executing the SQL scripts
void main() async {
  print('=== Smart Rice Dispenser - Real Database Setup ===');
  print('This script will help you set up your Supabase database tables.');

  // Initialize Supabase
  print('\nInitializing Supabase connection...');
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('✅ Supabase connection successful!');
  } catch (e) {
    print('❌ Error connecting to Supabase: $e');
    print('\nPlease check your credentials in lib/config/supabase_config.dart');
    return;
  }

  final supabase = Supabase.instance.client;

  // Function to execute SQL scripts
  Future<void> executeScript(String path, String description) async {
    try {
      print('\nExecuting $description...');
      final file = File(path);
      if (!file.existsSync()) {
        print('❌ Script file not found at $path');
        return;
      }

      final sql = file.readAsStringSync();
      await supabase.rpc('exec_sql', params: {'query': sql});
      print('✅ Successfully executed $description!');
    } catch (e) {
      print('❌ Error executing $description: $e');
    }
  }

  // Ask user if they want to proceed
  print('\nThis will set up the following tables in your Supabase project:');
  print('- settings');
  print('- rice_weight');
  print('- dispense_request');
  print('- migrations');

  print('\nWARNING: If these tables already exist, this might modify them.');
  print('Do you want to proceed? (y/n)');

  final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
  if (response != 'y') {
    print('Operation cancelled.');
    return;
  }

  // Execute schema creation script
  await executeScript('sql/01_create_schema.sql', 'schema creation script');

  // Ask about sample data
  print('\nDo you want to add sample data to your database? (y/n)');
  final sampleResponse = stdin.readLineSync()?.toLowerCase() ?? 'n';
  if (sampleResponse == 'y') {
    await executeScript('sql/02_sample_data.sql', 'sample data script');
  }

  print('\n=== Setup Complete ===');
  print('You can now run your app with real database data!');
  print(
      'Remember to keep useDemoMode = false in lib/config/supabase_config.dart');
}
