// lib/database/database_migration.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for database migrations
abstract class Migration {
  final String version;
  final String description;

  Migration(this.version, this.description);

  /// Execute the migration
  Future<void> up(SupabaseClient client);

  /// Rollback the migration (optional)
  Future<void> down(SupabaseClient client) async {
    // Default implementation does nothing
  }
}

/// Migration manager to handle database schema updates
class DatabaseMigrationManager {
  final SupabaseClient _client;

  DatabaseMigrationManager(this._client);

  /// Get all available migrations
  List<Migration> get migrations => [
        CreateSettingsTableMigration(),
        CreateRiceWeightTableMigration(),
        CreateDispenseRequestTableMigration(),
        CreateMigrationsTableMigration(),
      ];

  /// Run all pending migrations
  Future<void> runMigrations() async {
    try {
      // Ensure migrations table exists
      await _ensureMigrationsTableExists();

      // Get executed migrations
      final executedMigrations = await _getExecutedMigrations();

      // Run pending migrations
      for (final migration in migrations) {
        if (!executedMigrations.contains(migration.version)) {
          print(
              'Running migration: ${migration.version} - ${migration.description}');
          await migration.up(_client);
          await _recordMigration(migration);
          print('Migration ${migration.version} completed successfully');
        }
      }
    } catch (e) {
      print('Error running migrations: $e');
      rethrow;
    }
  }

  /// Ensure migrations tracking table exists
  Future<void> _ensureMigrationsTableExists() async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS migrations (
        version VARCHAR(50) PRIMARY KEY,
        description TEXT NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    ''';
    await _client.rpc('execute_sql', params: {'sql': sql});
  }

  /// Get list of executed migrations
  Future<Set<String>> _getExecutedMigrations() async {
    try {
      final response = await _client.from('migrations').select('version');

      return (response as List).map((row) => row['version'] as String).toSet();
    } catch (e) {
      // If table doesn't exist, return empty set
      return <String>{};
    }
  }

  /// Record executed migration
  Future<void> _recordMigration(Migration migration) async {
    await _client.from('migrations').insert({
      'version': migration.version,
      'description': migration.description,
    });
  }
}

/// Migration to create settings table
class CreateSettingsTableMigration extends Migration {
  CreateSettingsTableMigration() : super('001', 'Create settings table');
  @override
  Future<void> up(SupabaseClient client) async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS settings (
        id SERIAL PRIMARY KEY,
        low_threshold_grams INTEGER NOT NULL DEFAULT 100,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      -- Insert default settings if none exist
      INSERT INTO settings (low_threshold_grams) 
      SELECT 100 
      WHERE NOT EXISTS (SELECT 1 FROM settings);
    ''';

    await client.rpc('execute_sql', params: {'sql': sql});
  }
}

/// Migration to create rice_weight table
class CreateRiceWeightTableMigration extends Migration {
  CreateRiceWeightTableMigration() : super('002', 'Create rice_weight table');

  @override
  Future<void> up(SupabaseClient client) async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS rice_weight (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        weight_grams INTEGER NOT NULL,
        level_state VARCHAR(20) NOT NULL CHECK (level_state IN ('full', 'partial', 'empty')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      -- Create index for timestamp queries
      CREATE INDEX IF NOT EXISTS idx_rice_weight_timestamp ON rice_weight(timestamp);
      CREATE INDEX IF NOT EXISTS idx_rice_weight_level_state ON rice_weight(level_state);
    ''';

    await client.rpc('execute_sql', params: {'sql': sql});
  }
}

/// Migration to create dispense_request table
class CreateDispenseRequestTableMigration extends Migration {
  CreateDispenseRequestTableMigration()
      : super('003', 'Create dispense_request table');

  @override
  Future<void> up(SupabaseClient client) async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS dispense_request (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        requested_grams INTEGER NOT NULL,
        requested_cups DECIMAL(5,2) NOT NULL,
        dispensed_grams INTEGER DEFAULT 0,
        status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
        requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        completed_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      -- Create indexes for common queries
      CREATE INDEX IF NOT EXISTS idx_dispense_request_status ON dispense_request(status);
      CREATE INDEX IF NOT EXISTS idx_dispense_request_requested_at ON dispense_request(requested_at);
      
      -- Create trigger to set completed_at when status changes to completed
      CREATE OR REPLACE FUNCTION set_completed_at()
      RETURNS TRIGGER AS \$\$
      BEGIN
        IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
          NEW.completed_at = NOW();
        END IF;
        RETURN NEW;
      END;
      \$\$ language 'plpgsql';
      
      CREATE TRIGGER update_dispense_request_completed_at 
        BEFORE UPDATE ON dispense_request 
        FOR EACH ROW 
        EXECUTE FUNCTION set_completed_at();
    ''';

    await client.rpc('execute_sql', params: {'sql': sql});
  }
}

/// Migration to create migrations table (for bootstrapping)
class CreateMigrationsTableMigration extends Migration {
  CreateMigrationsTableMigration()
      : super('000', 'Create migrations tracking table');

  @override
  Future<void> up(SupabaseClient client) async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS migrations (
        version VARCHAR(50) PRIMARY KEY,
        description TEXT NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    ''';

    await client.rpc('execute_sql', params: {'sql': sql});
  }
}
