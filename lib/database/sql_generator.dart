// lib/database/sql_generator.dart
/// Utility class to generate SQL DDL statements from Dart models
class SqlGenerator {
  /// Generate CREATE TABLE statement for Settings model
  static String generateSettingsTable() {
    return '''
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
''';
  }

  /// Generate CREATE TABLE statement for RiceWeight model
  static String generateRiceWeightTable() {
    return '''
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
''';
  }

  /// Generate CREATE TABLE statement for DispenseRequest model
  static String generateDispenseRequestTable() {
    return '''
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
''';
  }

  /// Generate all table creation statements
  static String generateAllTables() {
    return '''
-- ================================================
-- Smart Rice Dispenser Database Schema
-- Generated automatically from Dart models
-- ================================================

${generateSettingsTable()}

${generateRiceWeightTable()}

${generateDispenseRequestTable()}

-- ================================================
-- Create migrations tracking table
-- ================================================
CREATE TABLE IF NOT EXISTS migrations (
  version VARCHAR(50) PRIMARY KEY,
  description TEXT NOT NULL,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE migrations IS 'Tracks database schema migrations';
''';
  }

  /// Generate sample data insertion statements
  static String generateSampleData() {
    return '''
-- ================================================
-- Sample Data for Testing
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
  }

  /// Generate database cleanup statements
  static String generateCleanupScript() {
    return '''
-- ================================================
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
''';
  }

  /// Generate database statistics query
  static String generateStatsQuery() {
    return '''
-- ================================================
-- Database Statistics Query
-- ================================================

-- Table sizes and record counts
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

-- Record counts
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

-- Recent activity summary
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
''';
  }
}
