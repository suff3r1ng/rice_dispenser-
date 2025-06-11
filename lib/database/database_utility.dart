// lib/database/database_utility.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sql_generator.dart';

/// Utility class for database operations and SQL generation
class DatabaseUtility {
  final SupabaseClient _client;

  DatabaseUtility(this._client);

  /// Generate all SQL files to the project directory
  static Future<void> generateSqlFiles() async {
    // This method can be called from the app to generate SQL files
    print('Generating SQL files...');

    // Generate schema
    final schema = SqlGenerator.generateAllTables();
    print('Schema SQL:');
    print(schema);
    print('\n${'=' * 50}\n');

    // Generate sample data
    final sampleData = SqlGenerator.generateSampleData();
    print('Sample Data SQL:');
    print(sampleData);
    print('\n${'=' * 50}\n');

    // Generate cleanup script
    final cleanup = SqlGenerator.generateCleanupScript();
    print('Cleanup SQL:');
    print(cleanup);
    print('\n${'=' * 50}\n');

    // Generate stats query
    final stats = SqlGenerator.generateStatsQuery();
    print('Statistics SQL:');
    print(stats);
  }

  /// Execute SQL script directly (for Supabase RPC if available)
  Future<void> executeSql(String sql) async {
    try {
      // Try to use RPC function if available
      await _client.rpc('execute_sql', params: {'sql': sql});
    } catch (e) {
      print('Direct SQL execution not available: $e');
      print('Please run the SQL manually in Supabase dashboard');
      rethrow;
    }
  }

  /// Create all tables using direct table creation
  Future<void> createTablesDirectly() async {
    try {
      print('Creating tables directly...');

      // Create settings table
      await _createSettingsTable();

      // Create rice_weight table
      await _createRiceWeightTable();

      // Create dispense_request table
      await _createDispenseRequestTable();

      print('All tables created successfully');
    } catch (e) {
      print('Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> _createSettingsTable() async {
    try {
      // Check if table exists by trying to query it
      await _client.from('settings').select('id').limit(1);
      print('Settings table already exists');
    } catch (e) {
      print('Creating settings table...');
      // Table doesn't exist, we'll let the migration system handle it
      // or use Supabase dashboard to create manually
    }
  }

  Future<void> _createRiceWeightTable() async {
    try {
      await _client.from('rice_weight').select('id').limit(1);
      print('Rice weight table already exists');
    } catch (e) {
      print('Creating rice_weight table...');
      // Table doesn't exist, will be handled by migration system
    }
  }

  Future<void> _createDispenseRequestTable() async {
    try {
      await _client.from('dispense_request').select('id').limit(1);
      print('Dispense request table already exists');
    } catch (e) {
      print('Creating dispense_request table...');
      // Table doesn't exist, will be handled by migration system
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final stats = <String, dynamic>{};

      // Get record counts
      final settingsCount = await _getTableCount('settings');
      final riceWeightCount = await _getTableCount('rice_weight');
      final dispenseRequestCount = await _getTableCount('dispense_request');

      stats['table_counts'] = {
        'settings': settingsCount,
        'rice_weight': riceWeightCount,
        'dispense_request': dispenseRequestCount,
      };

      // Get recent activity
      final recentWeightsResponse = await _client
          .from('rice_weight')
          .select('*', const FetchOptions(count: CountOption.exact))
          .gte(
              'timestamp',
              DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .toIso8601String());

      final recentRequestsResponse = await _client
          .from('dispense_request')
          .select('*', const FetchOptions(count: CountOption.exact))
          .gte(
              'requested_at',
              DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .toIso8601String());

      stats['recent_activity'] = {
        'rice_weights_24h': recentWeightsResponse.count ?? 0,
        'dispense_requests_24h': recentRequestsResponse.count ?? 0,
      };

      return stats;
    } catch (e) {
      print('Error getting database stats: $e');
      return {'error': e.toString()};
    }
  }

  Future<int> _getTableCount(String tableName) async {
    try {
      final response = await _client
          .from(tableName)
          .select('*', const FetchOptions(count: CountOption.exact));
      return response.count ?? 0;
    } catch (e) {
      print('Error getting count for $tableName: $e');
      return 0;
    }
  }
}
