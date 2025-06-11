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

-- Note: Run this only if you want to completely reset the database
-- After running this, you'll need to run the schema creation script again
