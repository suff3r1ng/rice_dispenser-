@echo off
REM Generate SQL files for Smart Rice Dispenser database
REM This script runs the Dart SQL generator tool

echo Smart Rice Dispenser - SQL Generator
echo ====================================
echo.

REM Check if Dart is installed
dart --version >nul 2>&1
if errorlevel 1 (
    echo Error: Dart is not installed or not in PATH
    echo Please install Dart SDK and try again
    pause
    exit /b 1
)

REM Run the SQL generator
echo Generating SQL files...
dart tools/generate_sql.dart --all --verbose

if errorlevel 1 (
    echo.
    echo Error occurred during generation
    pause
    exit /b 1
)

echo.
echo ====================================
echo SQL files generated successfully!
echo Check the 'sql' directory for output files
echo.
echo Files created:
echo   sql/01_create_schema.sql    - Database schema
echo   sql/02_sample_data.sql      - Test data
echo   sql/03_statistics.sql       - Analysis queries
echo   sql/99_cleanup.sql          - Drop tables (DANGEROUS!)
echo   sql/README.md               - Documentation
echo.
echo To create your database:
echo 1. Open Supabase dashboard
echo 2. Go to SQL Editor
echo 3. Copy and paste sql/01_create_schema.sql
echo 4. Click Run
echo.
pause
