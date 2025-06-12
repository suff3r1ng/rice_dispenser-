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

## 3. Update Environment Variables

The app now uses environment variables for Supabase credentials. 

1. Edit the `.env` file in the project root (create it if it doesn't exist):
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   USE_DEMO_MODE=false
   ```

2. Replace with your actual Supabase credentials:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anon/public key
   - `USE_DEMO_MODE`: Set to `false` to use real database, `true` for demo mode

## 4. Finding Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Click on "Settings" (gear icon) in the sidebar
3. Select "API" from the submenu
4. Copy your project URL and anon/public key

## 5. Restart the App

After updating the environment variables, restart the app. It will now connect to your real Supabase database instead of using demo mode.

## Troubleshooting

### Connection Issues

If you see the error "Failed to initialize app" with a SocketException or ClientException:

1. **Check your internet connection** - Make sure you have internet access
2. **Verify credentials** - Double-check that your Supabase URL and anon key are correct
3. **Temporarily use demo mode** - If you're still having issues, set `USE_DEMO_MODE=true` in the `.env` file until you can resolve the connection issues
4. **Check Supabase status** - Make sure your Supabase project is active and not paused
5. **Network restrictions** - Some networks might block certain connections; try on a different network

### Database Tables Not Found

If tables are missing:

1. Use the Database Management screen to generate the SQL schema
2. Copy the generated SQL and run it in the Supabase SQL Editor
3. Check the Supabase dashboard to verify tables were created

### General Issues

- Check the app logs for error messages
- Verify your Supabase credentials are correct
- Make sure your database tables are properly created
- Check if Supabase is accessible from your network
