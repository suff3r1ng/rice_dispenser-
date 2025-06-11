# Database SQL Generation System

I've successfully implemented a comprehensive SQL generation and database management system for your Smart Rice Dispenser project. Here's what has been added:

## 🎯 What's Been Created

### 1. **SQL Generation Tools**
- **`lib/database/sql_generator.dart`** - Core SQL generation utilities
- **`lib/database/database_utility.dart`** - Database operations and statistics
- **`scripts/database_setup.dart`** - Command-line script for generating SQL files
- **`tools/generate_sql.dart`** - Standalone SQL generator tool
- **`generate_sql.bat`** - Windows batch script for easy execution

### 2. **Database Management Screen**
- **`lib/screens/database_management_screen.dart`** - GUI interface for database operations
- Added route `/database-management` to main app

### 3. **Generated SQL Files** (in `sql/` directory)
- **`01_create_schema.sql`** - Complete database schema with tables, indexes, triggers
- **`02_sample_data.sql`** - Sample data for testing
- **`03_statistics.sql`** - Database analysis and monitoring queries  
- **`99_cleanup.sql`** - Database cleanup script (use with caution!)
- **`README.md`** - Comprehensive documentation

## 🚀 How to Use

### Method 1: Command Line (Recommended)
```bash
# Generate all SQL files
dart tools/generate_sql.dart --all --verbose

# Or use the Windows batch script
generate_sql.bat

# Generate specific files only
dart tools/generate_sql.dart --schema
dart tools/generate_sql.dart --sample --output custom_directory/
```

### Method 2: From Flutter App
1. Add Database Management Screen to your navigation
2. Use the GUI to generate SQL and view database statistics
3. Copy generated SQL to clipboard for use in Supabase

### Method 3: Programmatically
```dart
import 'lib/database/sql_generator.dart';

// Generate schema SQL
final schema = SqlGenerator.generateAllTables();

// Generate sample data
final sampleData = SqlGenerator.generateSampleData();

// Generate statistics queries
final stats = SqlGenerator.generateStatsQuery();
```

## 📋 Database Schema

The generated schema includes:

### Tables
- **`settings`** - Application configuration (thresholds, etc.)
- **`rice_weight`** - Sensor weight measurements over time
- **`dispense_request`** - Rice dispensing requests and status
- **`migrations`** - Schema version tracking

### Features
- **UUID primary keys** for distributed compatibility
- **Automatic timestamps** on all tables
- **Database triggers** for auto-updating fields
- **Performance indexes** on frequently queried columns
- **Data validation** via CHECK constraints
- **Comprehensive comments** for self-documentation

## 🛠 Setup Instructions

### For Supabase (Recommended)
1. Generate SQL files: `dart tools/generate_sql.dart --all`
2. Open your Supabase project dashboard
3. Go to **SQL Editor**
4. Copy and paste the contents of `sql/01_create_schema.sql`
5. Click **Run** to create all tables
6. Optionally run `sql/02_sample_data.sql` for test data

### For Local Development
The Flutter app will automatically attempt to create tables on startup, but manual SQL execution is more reliable for complex schemas.

## 📊 Database Analysis

Use the generated statistics queries in `sql/03_statistics.sql` to analyze:
- Table sizes and record counts
- Recent activity patterns (24h)
- Rice level distribution
- Dispense request accuracy
- System efficiency metrics
- Hourly usage patterns

## 🔧 Key Features

### Automatic SQL Generation
- **Model-based**: SQL generated directly from your Dart model classes
- **Cross-platform**: Works on Windows, macOS, Linux
- **Flexible output**: Generate specific files or everything at once
- **Documentation**: Auto-generated README with setup instructions

### Database Management
- **Real-time statistics** display in Flutter app
- **SQL generation** directly from the app
- **Copy to clipboard** functionality
- **Database status monitoring**

### Migration System
- **Version tracking** with migrations table
- **Safe execution** with rollback capabilities  
- **Automatic application** on app startup
- **Error handling** for failed migrations

## 🎨 GUI Database Management

Access the database management screen in your app at `/database-management` route. Features include:

- **Live Statistics**: View table record counts and recent activity
- **SQL Generation**: Generate schema, sample data, cleanup, and analysis scripts
- **Copy to Clipboard**: Easy copying of generated SQL
- **Visual Interface**: User-friendly buttons and organized sections

## 📁 File Structure

```
smart_dispenser/
├── lib/
│   ├── database/
│   │   ├── database_migration.dart     # Migration framework
│   │   ├── sql_generator.dart          # Core SQL generation
│   │   └── database_utility.dart       # Database operations
│   └── screens/
│       └── database_management_screen.dart  # GUI interface
├── scripts/
│   └── database_setup.dart            # Command-line script
├── tools/
│   └── generate_sql.dart              # Standalone generator
├── sql/                               # Generated SQL files
│   ├── 01_create_schema.sql
│   ├── 02_sample_data.sql
│   ├── 03_statistics.sql
│   ├── 99_cleanup.sql
│   └── README.md
└── generate_sql.bat                   # Windows batch script
```

## 🔒 Safety Features

- **Backup recommendations** in documentation
- **Warning labels** on destructive operations
- **Validation checks** before schema changes
- **Error handling** for failed operations
- **Dry-run capabilities** for testing

## 🚀 Next Steps

1. **Generate your SQL files**: Run `dart tools/generate_sql.dart --all`
2. **Set up your database**: Use the generated `01_create_schema.sql` in Supabase
3. **Test with sample data**: Optionally run `02_sample_data.sql`
4. **Monitor your system**: Use `03_statistics.sql` for analysis
5. **Access via app**: Navigate to `/database-management` in your Flutter app

The system is now ready for production use and provides a solid foundation for database management in your Smart Rice Dispenser project!
