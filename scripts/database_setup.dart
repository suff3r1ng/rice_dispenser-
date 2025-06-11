// scripts/database_setup.dart
import 'dart:io';

/// Command-line tool for database schema generation and management
void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    return;
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'generate':
      await generateSqlFiles();
      break;
    case 'generate-schema':
      await generateSchemaFile();
      break;
    case 'generate-sample':
      await generateSampleDataFile();
      break;
    case 'generate-cleanup':
      await generateCleanupFile();
      break;
    case 'generate-stats':
      await generateStatsFile();
      break;
    case 'generate-all':
      await generateAllFiles();
      break;
    case 'help':
    case '--help':
    case '-h':
      printUsage();
      break;
    default:
      print('Unknown command: $command');
      printUsage();
  }
}

void printUsage() {
  print('''
Database Setup Tool for Smart Rice Dispenser

Usage: dart scripts/database_setup.dart <command>

Commands:
  generate          Generate all SQL files
  generate-schema   Generate only schema creation SQL
  generate-sample   Generate only sample data SQL
  generate-cleanup  Generate only cleanup SQL
  generate-stats    Generate only statistics query SQL
  generate-all      Generate all SQL files and documentation
  help              Show this help message

Examples:
  dart scripts/database_setup.dart generate
  dart scripts/database_setup.dart generate-schema
  dart scripts/database_setup.dart generate-all

Generated files will be saved to the 'sql/' directory.
''');
}

Future<void> generateSqlFiles() async {
  await generateSchemaFile();
  await generateSampleDataFile();
  print('✅ SQL files generated successfully!');
}

Future<void> generateAllFiles() async {
  await generateSchemaFile();
  await generateSampleDataFile();
  await generateCleanupFile();
  await generateStatsFile();
  await generateReadmeFile();
  print('✅ All SQL files and documentation generated successfully!');
}

Future<void> generateSchemaFile() async {
  const schema = '''-- ================================================
-- Smart Rice Dispenser Database Schema
-- Generated automatically from Dart models
-- ================================================

-- Settings table
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

-- Trigger to automatically update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
\$\$ language 'plpgsql';

CREATE TRIGGER update_settings_updated_at 
  BEFORE UPDATE ON settings 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Rice Weight table
CREATE TABLE IF NOT EXISTS rice_weight (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  weight_grams INTEGER NOT NULL,
  level_state VARCHAR(20) NOT NULL CHECK (level_state IN ('full', 'partial', 'empty')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_rice_weight_timestamp ON rice_weight(timestamp);
CREATE INDEX IF NOT EXISTS idx_rice_weight_level_state ON rice_weight(level_state);
CREATE INDEX IF NOT EXISTS idx_rice_weight_weight_grams ON rice_weight(weight_grams);

-- Comments for documentation
COMMENT ON TABLE rice_weight IS 'Stores rice weight measurements from sensors';
COMMENT ON COLUMN rice_weight.id IS 'Unique identifier for each weight measurement';
COMMENT ON COLUMN rice_weight.timestamp IS 'When the measurement was taken';
COMMENT ON COLUMN rice_weight.weight_grams IS 'Weight measurement in grams';
COMMENT ON COLUMN rice_weight.level_state IS 'Rice level state: full, partial, or empty';

-- Dispense Request table
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_dispense_request_status ON dispense_request(status);
CREATE INDEX IF NOT EXISTS idx_dispense_request_requested_at ON dispense_request(requested_at);
CREATE INDEX IF NOT EXISTS idx_dispense_request_completed_at ON dispense_request(completed_at);

-- Trigger to automatically set completed_at when status changes
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

-- Comments for documentation
COMMENT ON TABLE dispense_request IS 'Stores rice dispensing requests and their status';
COMMENT ON COLUMN dispense_request.id IS 'Unique identifier for each dispense request';
COMMENT ON COLUMN dispense_request.requested_grams IS 'Amount of rice requested in grams';
COMMENT ON COLUMN dispense_request.requested_cups IS 'Amount of rice requested in cups';
COMMENT ON COLUMN dispense_request.dispensed_grams IS 'Actual amount dispensed in grams';
COMMENT ON COLUMN dispense_request.status IS 'Request status: pending, completed, or failed';

-- Create migrations tracking table
CREATE TABLE IF NOT EXISTS migrations (
  version VARCHAR(50) PRIMARY KEY,
  description TEXT NOT NULL,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE migrations IS 'Tracks database schema migrations';
''';

  await _writeToFile('sql/01_create_schema.sql', schema);
  print('✅ Schema file generated: sql/01_create_schema.sql');
}

Future<void> generateSampleDataFile() async {
  const sampleData = '''-- ================================================
-- Sample Data for Smart Rice Dispenser
-- ================================================

-- Sample settings (if none exist)
INSERT INTO settings (low_threshold_grams) 
SELECT 150 
WHERE NOT EXISTS (SELECT 1 FROM settings);

-- Sample rice weight data
INSERT INTO rice_weight (weight_grams, level_state, timestamp) VALUES
(1500, 'full', NOW() - INTERVAL '1 hour'),
(1200, 'partial', NOW() - INTERVAL '30 minutes'),
(800, 'partial', NOW() - INTERVAL '15 minutes'),
(500, 'partial', NOW() - INTERVAL '5 minutes'),
(1600, 'full', NOW());

-- Sample dispense requests
INSERT INTO dispense_request (requested_grams, requested_cups, dispensed_grams, status, requested_at, completed_at) VALUES
(200, 1.0, 195, 'completed', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours' + INTERVAL '30 seconds'),
(400, 2.0, 405, 'completed', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour' + INTERVAL '45 seconds'),
(150, 0.75, 0, 'pending', NOW() - INTERVAL '5 minutes', NULL),
(300, 1.5, 295, 'completed', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes' + INTERVAL '1 minute');
''';

  await _writeToFile('sql/02_sample_data.sql', sampleData);
  print('✅ Sample data file generated: sql/02_sample_data.sql');
}

Future<void> generateCleanupFile() async {
  const cleanup = '''-- ================================================
-- Database Cleanup Script
-- WARNING: This will delete all data!
-- ================================================

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS migrations CASCADE;
DROP TABLE IF EXISTS dispense_request CASCADE;
DROP TABLE IF EXISTS rice_weight CASCADE;
DROP TABLE IF EXISTS settings CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS set_completed_at() CASCADE;

-- Note: Run this only if you want to completely reset the database
-- After running this, you'll need to run the schema creation script again
''';

  await _writeToFile('sql/99_cleanup.sql', cleanup);
  print('✅ Cleanup file generated: sql/99_cleanup.sql');
}

Future<void> generateStatsFile() async {
  const stats = '''-- ================================================
-- Database Statistics and Analysis Queries
-- ================================================

-- Table sizes and record counts
SELECT 
  'settings' as table_name, 
  COUNT(*) as record_count,
  pg_size_pretty(pg_total_relation_size('settings')) as table_size
FROM settings
UNION ALL
SELECT 
  'rice_weight' as table_name, 
  COUNT(*) as record_count,
  pg_size_pretty(pg_total_relation_size('rice_weight')) as table_size
FROM rice_weight
UNION ALL
SELECT 
  'dispense_request' as table_name, 
  COUNT(*) as record_count,
  pg_size_pretty(pg_total_relation_size('dispense_request')) as table_size
FROM dispense_request;

-- Recent activity summary (last 24 hours)
SELECT 
  'Recent rice weights' as activity,
  COUNT(*) as count,
  MIN(timestamp) as earliest,
  MAX(timestamp) as latest
FROM rice_weight 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
  'Recent dispense requests' as activity,
  COUNT(*) as count,
  MIN(requested_at) as earliest,
  MAX(requested_at) as latest
FROM dispense_request 
WHERE requested_at >= NOW() - INTERVAL '24 hours';

-- Rice level distribution
SELECT 
  level_state,
  COUNT(*) as count,
  ROUND(AVG(weight_grams), 2) as avg_weight_grams,
  MIN(weight_grams) as min_weight_grams,
  MAX(weight_grams) as max_weight_grams
FROM rice_weight 
GROUP BY level_state
ORDER BY level_state;

-- Dispense request status summary
SELECT 
  status,
  COUNT(*) as count,
  ROUND(AVG(requested_grams), 2) as avg_requested_grams,
  ROUND(AVG(dispensed_grams), 2) as avg_dispensed_grams,
  ROUND(AVG(CASE WHEN dispensed_grams > 0 THEN ABS(requested_grams - dispensed_grams) END), 2) as avg_accuracy_diff
FROM dispense_request 
GROUP BY status
ORDER BY status;

-- Recent weight trends (last 10 measurements)
SELECT 
  timestamp,
  weight_grams,
  level_state,
  LAG(weight_grams) OVER (ORDER BY timestamp) as previous_weight,
  weight_grams - LAG(weight_grams) OVER (ORDER BY timestamp) as weight_change
FROM rice_weight 
ORDER BY timestamp DESC 
LIMIT 10;
''';

  await _writeToFile('sql/03_statistics.sql', stats);
  print('✅ Statistics file generated: sql/03_statistics.sql');
}

Future<void> generateReadmeFile() async {
  const readme = '''# Database Setup for Smart Rice Dispenser

This directory contains SQL scripts to set up and manage the database for the Smart Rice Dispenser application.

## Files

- `01_create_schema.sql` - Creates all tables, indexes, triggers, and constraints
- `02_sample_data.sql` - Inserts sample data for testing
- `03_statistics.sql` - Queries for database statistics and analysis
- `99_cleanup.sql` - Drops all tables and functions (USE WITH CAUTION!)

## Setup Instructions

### Option 1: Using Supabase Dashboard

1. Open your Supabase project dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `01_create_schema.sql`
4. Click "Run" to execute the schema creation
5. Optionally, run `02_sample_data.sql` to add test data

### Option 2: Using the Flutter App

The app will automatically create tables when it starts up using the migration system.

### Option 3: Using Command Line (if you have psql access)

```bash
# Create schema
psql -h your-host -U your-user -d your-database -f 01_create_schema.sql

# Add sample data (optional)
psql -h your-host -U your-user -d your-database -f 02_sample_data.sql
```

## Database Schema

### Tables

#### settings
- Stores application configuration
- Fields: id, low_threshold_grams, created_at, updated_at

#### rice_weight
- Stores weight measurements from sensors
- Fields: id, timestamp, weight_grams, level_state, created_at

#### dispense_request
- Stores rice dispensing requests and status
- Fields: id, requested_grams, requested_cups, dispensed_grams, status, requested_at, completed_at, created_at

#### migrations
- Tracks applied database migrations
- Fields: version, description, executed_at

### Features

- **Automatic timestamps**: All tables have created_at fields
- **Triggers**: Auto-update updated_at for settings, auto-set completed_at for dispense requests
- **Indexes**: Optimized for common query patterns
- **Constraints**: Data validation at database level
- **Comments**: Self-documenting schema

## Maintenance

### View Statistics
Run the queries in `03_statistics.sql` to analyze:
- Table sizes and record counts
- Recent activity
- Rice level distribution
- Dispense accuracy

### Reset Database
⚠️ **Warning**: This will delete all data!

```sql
-- Run the cleanup script
\\i 99_cleanup.sql

-- Then recreate the schema
\\i 01_create_schema.sql
```

## Migration System

The app includes an automatic migration system that:
- Tracks applied migrations
- Runs new migrations on app startup
- Ensures database schema is always up to date

Migration files are embedded in the app code and don't require manual execution.

## Troubleshooting

### Permission Issues
Make sure your database user has CREATE, INSERT, UPDATE, DELETE permissions on the public schema.

### Connection Issues
Verify your Supabase connection URL and API key in the app configuration.

### Missing Tables
If tables are missing, run the schema creation script or restart the app to trigger migrations.
''';

  await _writeToFile('sql/README.md', readme);
  print('✅ Documentation generated: sql/README.md');
}

Future<void> _writeToFile(String filePath, String content) async {
  final file = File(filePath);

  // Create directory if it doesn't exist
  await file.parent.create(recursive: true);

  // Write the content
  await file.writeAsString(content);
}
