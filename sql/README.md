# Database Setup for Smart Rice Dispenser

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
\i 99_cleanup.sql

-- Then recreate the schema
\i 01_create_schema.sql
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
