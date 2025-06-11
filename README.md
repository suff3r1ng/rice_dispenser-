# Smart Rice Dispenser - Real Database Setup

To use real data from Supabase instead of the demo data, follow these steps:

## 1. Sign Up for Supabase

1. Go to [Supabase](https://supabase.com/) and create an account if you don't have one
2. Create a new project

## 2. Set Up the Database Schema

You have two options:

### Option A: Use the SQL Editor in Supabase
1. Navigate to the SQL Editor in your Supabase dashboard
2. Copy the contents of `sql/01_create_schema.sql` and execute it
3. Optionally, execute `sql/02_sample_data.sql` to add initial data

### Option B: Use the Flutter App's Database Management Screen
1. In the app, go to the Database Status screen (top-right icon in the app)
2. Navigate to the Database Management screen
3. Use the GUI to execute the schema creation

## 3. Update Credentials in the App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values with your actual Supabase credentials:
   ```dart
   static const String supabaseUrl = 'https://your-project-id.supabase.co';
   static const String supabaseAnonKey = 'your-supabase-anon-key';
   ```
3. Make sure `useDemoMode` is set to `false`

## 4. Finding Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Click on "Settings" (gear icon) in the sidebar
3. Select "API" from the submenu
4. Copy your project URL and anon/public key

## 5. Restart the App

After updating the credentials, restart the app. It will now connect to your real Supabase database instead of using demo data.

## Troubleshooting

If you encounter any issues:
- Check the app logs for error messages
- Verify your Supabase credentials are correct
- Make sure your database tables are properly created
- Check if Supabase is accessible from your network
