import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for database operations and statistics
class DatabaseUtility {
  final SupabaseClient _supabase;

  DatabaseUtility(this._supabase);

  /// Get statistics about the database
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      // Get table counts
      final settingsResponse = await _supabase.from('settings').select('*');
      final riceWeightResponse =
          await _supabase.from('rice_weight').select('*');
      final dispenseRequestResponse =
          await _supabase.from('dispense_request').select('*');

      // Calculate recent activity (last 24h)
      final now = DateTime.now().toUtc();
      final yesterday = now.subtract(const Duration(hours: 24));

      final recentWeights = riceWeightResponse.where((row) {
        final timestamp = DateTime.parse(row['timestamp'] as String);
        return timestamp.isAfter(yesterday);
      }).length;

      final recentRequests = dispenseRequestResponse.where((row) {
        final timestamp = DateTime.parse(row['requested_at'] as String);
        return timestamp.isAfter(yesterday);
      }).length;

      return {
        'table_counts': {
          'settings': settingsResponse.length,
          'rice_weight': riceWeightResponse.length,
          'dispense_request': dispenseRequestResponse.length,
        },
        'recent_activity': {
          'rice_weights_24h': recentWeights,
          'dispense_requests_24h': recentRequests,
        },
        'demo_mode': false,
      };
    } catch (e) {
      // Return a basic structure on error
      return {
        'table_counts': {
          'settings': 0,
          'rice_weight': 0,
          'dispense_request': 0,
        },
        'recent_activity': {
          'rice_weights_24h': 0,
          'dispense_requests_24h': 0,
        },
        'error': e.toString(),
        'demo_mode': false,
      };
    }
  }

  /// Execute a raw SQL query
  Future<void> executeRawSql(String sql) async {
    try {
      await _supabase.rpc('exec_sql', params: {'query': sql});
    } catch (e) {
      rethrow;
    }
  }
}
