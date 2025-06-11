// tools/generate_sql.dart

/// Standalone tool to generate SQL files for the Smart Rice Dispenser database
///
/// Usage:
///   dart tools/generate_sql.dart [options]
///
/// Options:
///   --help, -h        Show this help message
///   --output, -o      Output directory (default: sql/)
///   --schema          Generate schema file only
///   --sample          Generate sample data file only
///   --cleanup         Generate cleanup file only
///   --stats           Generate statistics file only
///   --all             Generate all files (default)
///   --verbose, -v     Verbose output

import 'dart:io';

void main(List<String> args) async {
  final options = parseArgs(args);

  if (options['help'] == true) {
    printUsage();
    return;
  }

  final outputDir = options['output'] ?? 'sql';
  final verbose = options['verbose'] == true;

  if (verbose) {
    print('Smart Rice Dispenser SQL Generator');
    print('Output directory: $outputDir');
    print('');
  }

  try {
    await ensureOutputDirectory(outputDir);

    if (options['schema'] == true || options['all'] == true) {
      await generateSchemaFile(outputDir, verbose);
    }

    if (options['sample'] == true || options['all'] == true) {
      await generateSampleDataFile(outputDir, verbose);
    }

    if (options['cleanup'] == true || options['all'] == true) {
      await generateCleanupFile(outputDir, verbose);
    }

    if (options['stats'] == true || options['all'] == true) {
      await generateStatsFile(outputDir, verbose);
    }

    if (options['all'] == true ||
        (!options.containsKey('schema') &&
            !options.containsKey('sample') &&
            !options.containsKey('cleanup') &&
            !options.containsKey('stats'))) {
      await generateReadmeFile(outputDir, verbose);
    }

    print('✅ SQL generation completed successfully!');
    if (!verbose) {
      print('Files generated in: $outputDir/');
    }
  } catch (e) {
    print('❌ Error generating SQL files: $e');
    exit(1);
  }
}

Map<String, dynamic> parseArgs(List<String> args) {
  final options = <String, dynamic>{};

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];

    switch (arg) {
      case '--help':
      case '-h':
        options['help'] = true;
        break;
      case '--output':
      case '-o':
        if (i + 1 < args.length) {
          options['output'] = args[i + 1];
          i++;
        }
        break;
      case '--schema':
        options['schema'] = true;
        break;
      case '--sample':
        options['sample'] = true;
        break;
      case '--cleanup':
        options['cleanup'] = true;
        break;
      case '--stats':
        options['stats'] = true;
        break;
      case '--all':
        options['all'] = true;
        break;
      case '--verbose':
      case '-v':
        options['verbose'] = true;
        break;
    }
  }

  return options;
}

void printUsage() {
  print('''
Smart Rice Dispenser SQL Generator

Generates SQL DDL scripts from Dart models for database setup.

Usage:
  dart tools/generate_sql.dart [options]

Options:
  --help, -h        Show this help message
  --output, -o DIR  Output directory (default: sql/)
  --schema          Generate schema file only
  --sample          Generate sample data file only  
  --cleanup         Generate cleanup file only
  --stats           Generate statistics file only
  --all             Generate all files (default)
  --verbose, -v     Verbose output

Examples:
  dart tools/generate_sql.dart
  dart tools/generate_sql.dart --schema --output database/
  dart tools/generate_sql.dart --all --verbose

Generated files:
  01_create_schema.sql    - Database schema with tables, indexes, triggers
  02_sample_data.sql      - Sample data for testing
  03_statistics.sql       - Database analysis queries
  99_cleanup.sql          - Drop all tables (dangerous!)
  README.md               - Documentation and setup instructions
''');
}

Future<void> ensureOutputDirectory(String dir) async {
  final directory = Directory(dir);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

Future<void> generateSchemaFile(String outputDir, bool verbose) async {
  if (verbose) print('Generating schema file...');

  const schema = '''-- ================================================
-- Smart Rice Dispenser Database Schema
-- Generated automatically from Dart models
-- ================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- Success message
DO \$\$
BEGIN
  RAISE NOTICE 'Smart Rice Dispenser database schema created successfully!';
END
\$\$;
''';

  await writeFile('$outputDir/01_create_schema.sql', schema);
  if (verbose) print('✅ Schema file: $outputDir/01_create_schema.sql');
}

Future<void> generateSampleDataFile(String outputDir, bool verbose) async {
  if (verbose) print('Generating sample data file...');

  const sampleData = '''-- ================================================
-- Sample Data for Smart Rice Dispenser
-- For testing and development purposes
-- ================================================

-- Sample settings (if none exist)
INSERT INTO settings (low_threshold_grams) 
SELECT 150 
WHERE NOT EXISTS (SELECT 1 FROM settings);

-- Sample rice weight data (simulating sensor readings over time)
INSERT INTO rice_weight (weight_grams, level_state, timestamp) VALUES
(1500, 'full', NOW() - INTERVAL '4 hours'),
(1450, 'full', NOW() - INTERVAL '3 hours 30 minutes'),
(1200, 'partial', NOW() - INTERVAL '2 hours'),
(1100, 'partial', NOW() - INTERVAL '1 hour 30 minutes'),
(800, 'partial', NOW() - INTERVAL '1 hour'),
(500, 'partial', NOW() - INTERVAL '30 minutes'),
(200, 'empty', NOW() - INTERVAL '15 minutes'),
(1600, 'full', NOW() - INTERVAL '10 minutes'),
(1580, 'full', NOW());

-- Sample dispense requests (simulating user interactions)
INSERT INTO dispense_request (requested_grams, requested_cups, dispensed_grams, status, requested_at, completed_at) VALUES
(200, 1.0, 195, 'completed', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours' + INTERVAL '30 seconds'),
(400, 2.0, 405, 'completed', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours' + INTERVAL '45 seconds'),
(300, 1.5, 295, 'completed', NOW() - INTERVAL '1 hour 30 minutes', NOW() - INTERVAL '1 hour 30 minutes' + INTERVAL '35 seconds'),
(150, 0.75, 148, 'completed', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour' + INTERVAL '25 seconds'),
(250, 1.25, 0, 'pending', NOW() - INTERVAL '5 minutes', NULL),
(100, 0.5, 102, 'completed', NOW() - INTERVAL '2 minutes', NOW() - INTERVAL '2 minutes' + INTERVAL '20 seconds');

-- Success message
DO \$\$
BEGIN
  RAISE NOTICE 'Sample data inserted successfully!';
  RAISE NOTICE 'Rice weight records: %', (SELECT COUNT(*) FROM rice_weight);
  RAISE NOTICE 'Dispense request records: %', (SELECT COUNT(*) FROM dispense_request);
END
\$\$;
''';

  await writeFile('$outputDir/02_sample_data.sql', sampleData);
  if (verbose) print('✅ Sample data file: $outputDir/02_sample_data.sql');
}

Future<void> generateCleanupFile(String outputDir, bool verbose) async {
  if (verbose) print('Generating cleanup file...');

  const cleanup = '''-- ================================================
-- Database Cleanup Script
-- WARNING: This will delete ALL data and tables!
-- ================================================

-- CAUTION: This script will permanently delete all data
-- Only run this if you want to completely reset the database
-- After running this, you'll need to run the schema creation script again

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS migrations CASCADE;
DROP TABLE IF EXISTS dispense_request CASCADE;
DROP TABLE IF EXISTS rice_weight CASCADE;
DROP TABLE IF EXISTS settings CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS set_completed_at() CASCADE;

-- Drop the UUID extension if it was created by this schema
-- (Uncomment the line below if you want to remove the extension)
-- DROP EXTENSION IF EXISTS "uuid-ossp";

-- Success message
DO \$\$
BEGIN
  RAISE NOTICE 'Database cleanup completed.';
  RAISE NOTICE 'All Smart Rice Dispenser tables and functions have been removed.';
  RAISE NOTICE 'Run 01_create_schema.sql to recreate the database structure.';
END
\$\$;
''';

  await writeFile('$outputDir/99_cleanup.sql', cleanup);
  if (verbose) print('✅ Cleanup file: $outputDir/99_cleanup.sql');
}

Future<void> generateStatsFile(String outputDir, bool verbose) async {
  if (verbose) print('Generating statistics file...');

  const stats = '''-- ================================================
-- Database Statistics and Analysis Queries
-- Run these queries to analyze your rice dispenser data
-- ================================================

-- Basic table information and sizes
SELECT 
  schemaname,
  tablename,
  attname as column_name,
  n_distinct,
  most_common_vals,
  most_common_freqs
FROM pg_stats 
WHERE schemaname = 'public' 
  AND tablename IN ('settings', 'rice_weight', 'dispense_request')
ORDER BY tablename, attname;

-- Record counts and table sizes
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

-- Rice level distribution analysis
SELECT 
  level_state,
  COUNT(*) as measurement_count,
  ROUND(AVG(weight_grams), 2) as avg_weight_grams,
  MIN(weight_grams) as min_weight_grams,
  MAX(weight_grams) as max_weight_grams,
  ROUND(STDDEV(weight_grams), 2) as weight_stddev
FROM rice_weight 
GROUP BY level_state
ORDER BY 
  CASE level_state 
    WHEN 'full' THEN 1 
    WHEN 'partial' THEN 2 
    WHEN 'empty' THEN 3 
  END;

-- Dispense request status and accuracy analysis
SELECT 
  status,
  COUNT(*) as request_count,
  ROUND(AVG(requested_grams), 2) as avg_requested_grams,
  ROUND(AVG(dispensed_grams), 2) as avg_dispensed_grams,
  ROUND(AVG(CASE 
    WHEN dispensed_grams > 0 THEN ABS(requested_grams - dispensed_grams) 
    ELSE NULL 
  END), 2) as avg_accuracy_diff_grams,
  ROUND(AVG(CASE 
    WHEN dispensed_grams > 0 THEN (ABS(requested_grams - dispensed_grams) * 100.0 / requested_grams)
    ELSE NULL 
  END), 2) as avg_accuracy_diff_percent
FROM dispense_request 
GROUP BY status
ORDER BY status;

-- Recent weight trends (last 20 measurements)
SELECT 
  timestamp,
  weight_grams,
  level_state,
  LAG(weight_grams) OVER (ORDER BY timestamp) as previous_weight,
  weight_grams - LAG(weight_grams) OVER (ORDER BY timestamp) as weight_change,
  CASE 
    WHEN LAG(weight_grams) OVER (ORDER BY timestamp) IS NULL THEN 'First measurement'
    WHEN weight_grams > LAG(weight_grams) OVER (ORDER BY timestamp) THEN 'Rice added'
    WHEN weight_grams < LAG(weight_grams) OVER (ORDER BY timestamp) THEN 'Rice dispensed'
    ELSE 'No change'
  END as change_type
FROM rice_weight 
ORDER BY timestamp DESC 
LIMIT 20;

-- Hourly dispense activity pattern
SELECT 
  EXTRACT(HOUR FROM requested_at) as hour_of_day,
  COUNT(*) as dispense_count,
  ROUND(AVG(requested_grams), 2) as avg_grams_requested,
  ROUND(SUM(requested_grams), 2) as total_grams_requested
FROM dispense_request 
WHERE requested_at >= NOW() - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM requested_at)
ORDER BY hour_of_day;

-- System efficiency metrics
WITH efficiency_stats AS (
  SELECT 
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_requests,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
    AVG(CASE 
      WHEN status = 'completed' AND dispensed_grams > 0 
      THEN ABS(requested_grams - dispensed_grams) 
    END) as avg_dispense_error
  FROM dispense_request
)
SELECT 
  total_requests,
  completed_requests,
  failed_requests,
  pending_requests,
  ROUND((completed_requests * 100.0 / NULLIF(total_requests, 0)), 2) as success_rate_percent,
  ROUND(avg_dispense_error, 2) as avg_dispense_error_grams
FROM efficiency_stats;
''';

  await writeFile('$outputDir/03_statistics.sql', stats);
  if (verbose) print('✅ Statistics file: $outputDir/03_statistics.sql');
}

Future<void> generateReadmeFile(String outputDir, bool verbose) async {
  if (verbose) print('Generating documentation...');

  const readme = '''# Smart Rice Dispenser Database

This directory contains SQL scripts and documentation for setting up and managing the Smart Rice Dispenser database.

## Quick Start

1. **Create the database schema:**
   ```sql
   \\i 01_create_schema.sql
   ```

2. **Add sample data (optional):**
   ```sql
   \\i 02_sample_data.sql
   ```

3. **Analyze your data:**
   ```sql
   \\i 03_statistics.sql
   ```

## Files Overview

| File | Purpose | Safe to Run |
|------|---------|-------------|
| `01_create_schema.sql` | Creates all tables, indexes, triggers | ✅ Yes |
| `02_sample_data.sql` | Inserts test data | ✅ Yes |
| `03_statistics.sql` | Analysis queries | ✅ Yes |
| `99_cleanup.sql` | **DROPS ALL TABLES** | ⚠️ **DANGEROUS** |

## Database Schema

### Core Tables

#### `settings`
Application configuration settings.
- `id` (SERIAL PRIMARY KEY)
- `low_threshold_grams` (INTEGER) - Rice low level alert threshold
- `created_at`, `updated_at` (TIMESTAMP WITH TIME ZONE)

#### `rice_weight`
Weight sensor measurements over time.
- `id` (UUID PRIMARY KEY)
- `timestamp` (TIMESTAMP WITH TIME ZONE) - When measured
- `weight_grams` (INTEGER) - Weight in grams
- `level_state` (VARCHAR) - 'full', 'partial', or 'empty'
- `created_at` (TIMESTAMP WITH TIME ZONE)

#### `dispense_request`
Rice dispensing requests and their outcomes.
- `id` (UUID PRIMARY KEY)
- `requested_grams` (INTEGER) - Amount requested
- `requested_cups` (DECIMAL) - Cups equivalent
- `dispensed_grams` (INTEGER) - Actual amount dispensed
- `status` (VARCHAR) - 'pending', 'completed', or 'failed'
- `requested_at`, `completed_at` (TIMESTAMP WITH TIME ZONE)
- `created_at` (TIMESTAMP WITH TIME ZONE)

#### `migrations`
Tracks applied database schema changes.
- `version` (VARCHAR PRIMARY KEY)
- `description` (TEXT)
- `executed_at` (TIMESTAMP WITH TIME ZONE)

### Features

- **Automatic Timestamps**: All tables track creation time
- **Data Validation**: CHECK constraints ensure data integrity
- **Performance Optimized**: Indexes on frequently queried columns
- **Audit Trail**: Track when dispense requests complete
- **UUID Support**: Uses UUID for distributed system compatibility

## Setup Methods

### Method 1: Supabase Dashboard (Recommended)
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Copy and paste `01_create_schema.sql`
4. Click **Run**
5. Optionally run `02_sample_data.sql` for test data

### Method 2: Flutter App Auto-Migration
The app automatically creates tables on first run using the built-in migration system.

### Method 3: Command Line (Advanced)
```bash
# If you have direct PostgreSQL access
psql -h your-host -U your-user -d your-database -f 01_create_schema.sql
psql -h your-host -U your-user -d your-database -f 02_sample_data.sql
```

## Maintenance Tasks

### View Database Statistics
Run queries from `03_statistics.sql` to analyze:
- Table sizes and record counts
- Recent activity patterns
- Rice level distributions
- Dispense accuracy metrics
- System efficiency

### Monitor Performance
```sql
-- Check table sizes
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size(tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(tablename) DESC;

-- Monitor recent activity
SELECT COUNT(*) FROM rice_weight WHERE timestamp >= NOW() - INTERVAL '1 hour';
SELECT COUNT(*) FROM dispense_request WHERE requested_at >= NOW() - INTERVAL '1 hour';
```

### Backup Important Data
```sql
-- Export recent data
COPY (
  SELECT * FROM rice_weight 
  WHERE timestamp >= NOW() - INTERVAL '30 days'
) TO '/path/to/rice_weight_backup.csv' CSV HEADER;

COPY (
  SELECT * FROM dispense_request 
  WHERE requested_at >= NOW() - INTERVAL '30 days'
) TO '/path/to/dispense_requests_backup.csv' CSV HEADER;
```

## Troubleshooting

### Common Issues

**Tables don't exist:**
- Run `01_create_schema.sql` in Supabase dashboard
- Check that your database user has CREATE permissions

**Migration errors:**
- Restart the Flutter app to trigger auto-migration
- Manually run schema creation in Supabase dashboard

**Performance issues:**
- Check if indexes exist: `\\d+ table_name`
- Analyze query performance: `EXPLAIN ANALYZE your_query;`
- Consider partitioning for large datasets

### Database Reset (⚠️ Dangerous)
Only if you need to completely start over:

```sql
-- This will DELETE ALL DATA!
\\i 99_cleanup.sql
\\i 01_create_schema.sql
```

## Integration

### Flutter App Integration
The app automatically:
- Creates tables on startup via migration system
- Validates schema compatibility
- Provides real-time database status monitoring

### Monitoring Dashboard
Access the database management screen in the app:
- View table statistics
- Generate SQL scripts
- Monitor connection status

## Support

- Check the Flutter app logs for database errors
- Use the built-in database status screen for diagnostics
- Monitor Supabase dashboard for connection issues

---
*Generated by Smart Rice Dispenser SQL Generator*
''';

  await writeFile('$outputDir/README.md', readme);
  if (verbose) print('✅ Documentation: $outputDir/README.md');
}

Future<void> writeFile(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
