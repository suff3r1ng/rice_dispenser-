# 🌾 Smart Rice Container App

A professional Flutter application for monitoring and dispensing rice from a smart container with real-time database monitoring, enhanced UI design, and comprehensive analytics.

## ✨ Features

### 🎨 Professional UI Design
- **Modern Material Design**: Enhanced visual design with gradients, shadows, and rounded corners
- **Responsive Layouts**: Professional card-based layouts with proper spacing
- **Color-coded Status**: Intuitive color coding for different states (green=good, orange=warning, red=critical)
- **Animated Elements**: Smooth animations for better user experience
- **Professional Icons**: Contextual icons throughout the app

### 📊 Database Management
- **Real-time Status Monitoring**: Live database connection status tracking
- **Table Management**: Automatic table creation and verification
- **Connection Testing**: Built-in database connectivity testing
- **Sample Data Generation**: Easy sample data insertion for testing
- **Error Handling**: Comprehensive error handling with user feedback

### ⚖️ Weight Monitoring
- **Real-time Weight Display**: Current rice weight with visual indicators
- **Capacity Tracking**: Progress bars showing container fill percentage
- **Level Indicators**: Smart level detection (Full/Partial/Empty)
- **Historical Data**: Weight tracking over time with charts

### 🍚 Rice Dispensing
- **Quick Selection**: Pre-defined amount buttons (100g, 200g, 300g, 500g, 1000g)
- **Custom Amounts**: Manual input with validation
- **Progress Tracking**: Visual feedback during dispensing
- **Request History**: Complete history of all dispense requests

### 📈 Analytics & History
- **Dispense Analytics**: Total dispenses and rice amounts
- **Weight Charts**: Beautiful line charts showing weight trends
- **Interactive Data**: Detailed view of historical data
- **Export Ready**: Data structured for future export features

### ⚙️ Settings Management
- **Threshold Configuration**: Customizable low rice alert thresholds
- **Cloud Sync**: Automatic settings synchronization
- **Quick Actions**: Easy navigation to key features
- **Professional Layout**: Clean, organized settings interface

## 🏗️ Architecture

### Backend Integration
- **Supabase Database**: Cloud-based PostgreSQL database
- **Real-time Subscriptions**: Live data updates
- **Automatic Schema**: Self-creating database tables
- **Connection Management**: Robust connection handling

### Database Schema
```sql
-- Rice weight tracking
rice_weight (
  id UUID PRIMARY KEY,
  timestamp TIMESTAMPTZ,
  weight_grams INTEGER,
  level_state TEXT
)

-- Dispense requests
dispense_requests (
  id UUID PRIMARY KEY,
  requested_grams INTEGER,
  requested_cups DECIMAL,
  dispensed_grams INTEGER,
  status TEXT,
  requested_at TIMESTAMPTZ
)

-- App settings
settings (
  id UUID PRIMARY KEY,
  low_threshold_grams INTEGER,
  updated_at TIMESTAMPTZ
)
```

### State Management
- **ValueNotifiers**: Reactive state management for database status
- **Provider Pattern**: Settings management across the app
- **Animation Controllers**: Smooth UI animations
- **Error States**: Comprehensive error handling

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android SDK (for Android builds)
- Supabase account and project

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Supabase:
   - Create a Supabase project
   - Update `supabase_service.dart` with your credentials
4. Run the app:
   ```bash
   flutter run
   ```

### Development Setup
Enable Developer Mode on Windows for symlink support:
```bash
start ms-settings:developers
```

## 📱 App Screens

### 🏠 Home Screen
- **Weight Display**: Current rice weight with status
- **Level Indicator**: Visual container status
- **Quick Actions**: Navigation to key features
- **Real-time Updates**: Live data refresh

### 📊 Database Status Screen
- **Connection Status**: Real-time database connection monitoring
- **Table Information**: Status of all database tables
- **Quick Actions**: Test connection, refresh status, add sample data
- **Error Reporting**: Detailed error information

### 🍚 Dispense Screen
- **Quick Selection**: Predefined amount buttons
- **Custom Input**: Manual amount entry with validation
- **Progress Indicator**: Visual feedback during dispensing
- **Professional Design**: Modern card-based layout

### 📈 History Screen
- **Dispense List**: Complete history with analytics
- **Weight Chart**: Interactive line charts
- **Data Summary**: Total statistics and trends
- **Professional Tables**: Clean data presentation

### ⚙️ Settings Screen
- **Threshold Management**: Customizable alert settings
- **Quick Navigation**: Links to other features
- **Cloud Sync**: Automatic synchronization
- **Professional Layout**: Organized settings interface

## 🔧 Technical Details

### Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  supabase_flutter: ^1.10.25
  provider: ^6.0.5
  fl_chart: ^0.68.0
  intl: ^0.18.1
```

### File Structure
```
lib/
├── main.dart                 # App entry point
├── supabase_service.dart     # Database service layer
├── models/                   # Data models
│   ├── rice_weight.dart
│   ├── dispense_request.dart
│   └── settings.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── database_status_screen.dart
│   ├── dispense_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
└── widgets/                  # Reusable components
    ├── weight_card.dart
    └── level_indicator.dart
```

## 🎯 Key Enhancements Made

### 1. Professional UI Redesign
- Modern Material Design implementation
- Gradient backgrounds and card layouts
- Improved typography and spacing
- Professional color schemes

### 2. Database Monitoring System
- Real-time connection status tracking
- Automatic table creation and verification
- Professional status dashboard
- Comprehensive error handling

### 3. Enhanced User Experience
- Smooth animations and transitions
- Intuitive navigation patterns
- Visual feedback for all actions
- Professional loading states

### 4. Robust Error Handling
- Comprehensive try-catch blocks
- User-friendly error messages
- Graceful degradation
- Connection recovery mechanisms

### 5. Advanced Analytics
- Beautiful chart visualizations
- Historical data tracking
- Statistical summaries
- Export-ready data structure

## 🔮 Future Enhancements
- Push notifications for low rice alerts
- Data export functionality
- Multi-language support
- IoT device integration
- Machine learning predictions

## 🐛 Troubleshooting

### Common Issues
1. **Build Errors**: Run `flutter clean && flutter pub get`
2. **Database Connection**: Check Supabase credentials
3. **Symlink Issues**: Enable Developer Mode on Windows
4. **Animation Performance**: Test on physical device

### Development Notes
- Use physical devices for best performance testing
- Database credentials should be in environment variables for production
- Test all features with various data states (empty, partial, full)

## 📄 License
This project is licensed under the MIT License.

## 🤝 Contributing
Contributions are welcome! Please read the contributing guidelines before submitting PRs.

---

**Smart Rice Container App** - Professional IoT rice management solution with beautiful UI and robust cloud integration.
