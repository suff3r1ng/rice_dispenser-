// lib/supabase_service.dart
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Temporarily disabled
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'models/rice_weight.dart';
import 'models/dispense_request.dart';
import 'models/settings.dart';
import 'database/database_migration.dart';
import 'config/supabase_config.dart';
import 'services/logger_service.dart';

enum DatabaseStatus { connected, disconnected, error, initializing }

enum TableStatus { exists, missing, creating, error }

class DatabaseInfo {
  final String tableName;
  final TableStatus status;
  final int recordCount;
  final DateTime? lastUpdated;
  final String? errorMessage;

  DatabaseInfo({
    required this.tableName,
    required this.status,
    this.recordCount = 0,
    this.lastUpdated,
    this.errorMessage,
  });
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  DatabaseStatus _connectionStatus = DatabaseStatus.initializing;
  List<DatabaseInfo> _tableStatuses = [];
  final ValueNotifier<DatabaseStatus> connectionStatusNotifier =
      ValueNotifier(DatabaseStatus.initializing);
  final ValueNotifier<List<DatabaseInfo>> tableStatusesNotifier =
      ValueNotifier([]);

  // Demo mode support
  bool get isDemoMode => SupabaseConfig.useDemoMode;

  // Demo data storage (only used in demo mode)
  final List<RiceWeight> _demoRiceWeights = [];
  final List<DispenseRequest> _demoDispenseRequests = [];
  Settings _demoSettings = Settings(id: 1, lowThresholdGrams: 500);
  bool _demoInitialized = false;

  // Getters for status
  DatabaseStatus get connectionStatus => _connectionStatus;
  List<DatabaseInfo> get tableStatuses => _tableStatuses;

  /// Initialize Supabase and setup database
  Future<void> initialize() async {
    try {
      _updateConnectionStatus(DatabaseStatus.initializing);

      if (SupabaseConfig.useDemoMode) {
        LoggerService.info(
            '🔧 Starting in DEMO MODE - no real database connection');
        await _initializeDemoData();
        _updateConnectionStatus(DatabaseStatus.connected);

        // Create fake table statuses for demo mode
        _tableStatuses = [
          DatabaseInfo(
              tableName: 'settings',
              status: TableStatus.exists,
              recordCount: 1),
          DatabaseInfo(
              tableName: 'rice_weight',
              status: TableStatus.exists,
              recordCount: 25),
          DatabaseInfo(
              tableName: 'dispense_request',
              status: TableStatus.exists,
              recordCount: 11),
        ];

        tableStatusesNotifier.value = _tableStatuses;
        LoggerService.info('✅ Demo mode initialization completed successfully');
        return;
      }

      // Initialize Supabase for real database connection
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      // Test connection and setup database
      await _testConnection();
      await _runMigrations();
      await _ensureTablesExist();
      _updateConnectionStatus(DatabaseStatus.connected);
      LoggerService.info('✅ Supabase initialization completed successfully');
    } catch (e) {
      LoggerService.error('Error initializing Supabase', e);
      _updateConnectionStatus(DatabaseStatus.error);
      rethrow;
    }
  }

  void _updateConnectionStatus(DatabaseStatus status) {
    _connectionStatus = status;
    connectionStatusNotifier.value = status;
  }

  void _updateTableStatuses(List<DatabaseInfo> statuses) {
    _tableStatuses = statuses;
    tableStatusesNotifier.value = statuses;
  }

  /// Test database connection
  Future<void> _testConnection() async {
    try {
      await supabase.from('rice_weight').select('id').limit(1);
    } catch (e) {
      throw Exception('Failed to connect to database: $e');
    }
  }

  /// Run database migrations
  Future<void> _runMigrations() async {
    try {
      LoggerService.database('MIGRATION', 'Running database migrations...');
      final migrationManager = DatabaseMigrationManager(supabase);
      await migrationManager.runMigrations();
      LoggerService.database(
          'MIGRATION', 'Database migrations completed successfully');
    } catch (e) {
      LoggerService.error('Error running migrations', e);
      // Don't rethrow - let the app continue with existing table structure
    }
  }

  /// Ensure all required tables exist
  Future<void> _ensureTablesExist() async {
    try {
      LoggerService.database('DB', 'Verifying database tables...');

      final tableStatuses = <DatabaseInfo>[];

      // Check settings table
      try {
        final settingsResponse = await supabase.from('settings').select('*');
        tableStatuses.add(DatabaseInfo(
          tableName: 'settings',
          status: TableStatus.exists,
          recordCount: settingsResponse.length,
          lastUpdated: DateTime.now(),
        ));
        LoggerService.database('DB',
            'Settings table exists with ${settingsResponse.length} records');
      } catch (e) {
        tableStatuses.add(DatabaseInfo(
          tableName: 'settings',
          status: TableStatus.missing,
          errorMessage: e.toString(),
        ));
        LoggerService.database('DB', 'Settings table missing: $e');
      }

      // Check rice_weight table
      try {
        final riceWeightResponse = await supabase.from('rice_weight').select('*');
        tableStatuses.add(DatabaseInfo(
          tableName: 'rice_weight',
          status: TableStatus.exists,
          recordCount: riceWeightResponse.length,
          lastUpdated: DateTime.now(),
        ));
        LoggerService.database('DB',
            'Rice_weight table exists with ${riceWeightResponse.length} records');
      } catch (e) {
        tableStatuses.add(DatabaseInfo(
          tableName: 'rice_weight',
          status: TableStatus.missing,
          errorMessage: e.toString(),
        ));
        LoggerService.database('DB', 'Rice_weight table missing: $e');
      }

      // Check dispense_request table
      try {
        final requestResponse = await supabase.from('dispense_request').select('*');
        tableStatuses.add(DatabaseInfo(
          tableName: 'dispense_request',
          status: TableStatus.exists,
          recordCount: requestResponse.length,
          lastUpdated: DateTime.now(),
        ));
        LoggerService.database('DB',
            'Dispense_request table exists with ${requestResponse.length} records');
      } catch (e) {
        tableStatuses.add(DatabaseInfo(
          tableName: 'dispense_request',
          status: TableStatus.missing,
          errorMessage: e.toString(),
        ));
        LoggerService.database('DB', 'Dispense_request table missing: $e');
      }

      _updateTableStatuses(tableStatuses);

      // If any tables are missing, try to create them via migrations
      if (tableStatuses.any((info) => info.status == TableStatus.missing)) {
        LoggerService.database('DB',
            'Some tables are missing, will attempt to create via migrations');
        await _runMigrations();
      }
    } catch (e) {
      LoggerService.error('Error verifying tables', e);
    }
  }

  /// Initialize demo data for demo mode
  Future<void> _initializeDemoData() async {
    if (_demoInitialized) return;

    LoggerService.info('🔧 Initializing Demo Data...');

    // Generate demo rice weights
    await _generateDemoRiceWeights();

    // Generate demo dispense requests
    await _generateDemoDispenseRequests();

    _demoInitialized = true;
    LoggerService.info('✅ Demo data initialized successfully');
  }

  Future<void> _generateDemoRiceWeights() async {
    final now = DateTime.now();
    // Use a fixed random seed for consistent demo data
    final random = math.Random(42);

    // Generate 24 hours of rice weight data
    for (int i = 24; i >= 0; i--) {
      final timestamp = now.subtract(Duration(hours: i));
      final baseWeight = 3000 - (i * 50) + random.nextInt(200) - 100;
      final weight = math.max(100, baseWeight);

      String levelState;
      if (weight > 4000) {
        levelState = 'full';
      } else if (weight > 1000) {
        levelState = 'partial';
      } else {
        levelState = 'empty';
      }

      _demoRiceWeights.add(RiceWeight(
        id: 'demo_${i}_${random.nextInt(1000)}',
        timestamp: timestamp,
        weightGrams: weight.toInt(),
        levelState: levelState,
      ));
    }
  }

  Future<void> _generateDemoDispenseRequests() async {
    final now = DateTime.now();
    // Use a fixed random seed for consistent demo data
    final random = math.Random(42);
    final statuses = ['completed', 'pending', 'failed'];

    for (int i = 10; i >= 0; i--) {
      final requestTime = now.subtract(Duration(hours: i * 2));
      final requestedGrams = [100, 200, 300, 500][random.nextInt(4)];
      final status = statuses[random.nextInt(statuses.length)];

      _demoDispenseRequests.add(DispenseRequest(
        id: 'demo_req_${i}_${random.nextInt(1000)}',
        requestedGrams: requestedGrams,
        requestedCups: requestedGrams / 200.0,
        dispensedGrams: status == 'completed' ? requestedGrams : 0,
        status: status,
        requestedAt: requestTime,
      ));
    }
  }

  /// Get Supabase client instance
  SupabaseClient get supabase => Supabase.instance.client;

  /// Fetch the latest rice weight entry
  Future<RiceWeight?> fetchLatestRiceWeight() async {
    if (isDemoMode) {
      await _initializeDemoData();
      return _demoRiceWeights.isNotEmpty ? _demoRiceWeights.last : null;
    }

    try {
      final response = await supabase
          .from('rice_weight')
          .select()
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return RiceWeight.fromMap(response.first);
    } catch (e) {
      LoggerService.error('Error fetching rice weight', e);
      return null;
    }
  }

  /// Subscribe to realtime rice_weight INSERTs/UPDATEs (simplified)
  void onRiceWeightChange(void Function(RiceWeight) callback) {
    // For now, use a simple polling approach
    // In production, you would set up proper realtime subscriptions
    LoggerService.info('Rice weight change subscription setup (polling mode)');
  }

  /// Fetch historical rice_weight records (for chart/history)
  Future<List<RiceWeight>> fetchRiceWeightHistory() async {
    if (isDemoMode) {
      await _initializeDemoData();
      return List.from(_demoRiceWeights);
    }

    try {
      final response = await supabase
          .from('rice_weight')
          .select()
          .order('timestamp', ascending: true);

      return response
          .map((row) => RiceWeight.fromMap(row))
          .toList();
    } catch (e) {
      LoggerService.error('Error fetching rice history', e);
      return [];
    }
  }

  /// Insert a new dispense request
  Future<void> createDispenseRequest(int grams) async {
    if (isDemoMode) {
      await _initializeDemoData();
      final request = DispenseRequest(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        requestedGrams: grams,
        requestedCups: grams / 200.0,
        dispensedGrams: 0,
        status: 'pending',
        requestedAt: DateTime.now(),
      );
      _demoDispenseRequests.add(request);

      // Simulate processing after 3 seconds (in real app)
      return;
    }

    try {
      final cups = grams / 200.0; // simple conversion
      await supabase.from('dispense_request').insert({
        'requested_grams': grams,
        'requested_cups': cups,
        'status': 'pending',
        'dispensed_grams': 0, // Add field for actual dispensed weight
      });
    } catch (e) {
      LoggerService.error('Error creating dispense request', e);
    }
  }

  /// Subscribe to realtime dispense_requests INSERTs/UPDATEs (simplified)
  void onDispenseRequestChange(void Function(DispenseRequest) callback) {
    // For now, use a simple polling approach
    // In production, you would set up proper realtime subscriptions
    LoggerService.info(
        'Dispense request change subscription setup (polling mode)');
  }

  /// Fetch historical dispense requests
  Future<List<DispenseRequest>> fetchDispenseHistory() async {
    if (isDemoMode) {
      await _initializeDemoData();
      return List.from(_demoDispenseRequests.reversed);
    }

    try {
      final response = await supabase
          .from('dispense_request')
          .select()
          .order('requested_at', ascending: false);

      return response
          .map((row) => DispenseRequest.fromMap(row))
          .toList();
    } catch (e) {
      LoggerService.error('Error fetching dispense history', e);
      return [];
    }
  }

  /// Fetch / create / update settings (low_threshold)
  Future<Settings> getSettings() async {
    if (isDemoMode) {
      await _initializeDemoData();
      return _demoSettings;
    }

    try {
      // We'll assume there's exactly one settings row; create a default if none exists.
      final response = await supabase.from('settings').select().limit(1);

      if (response.isEmpty) {
        // Insert default
        final insertResp = await supabase
            .from('settings')
            .insert({'low_threshold_grams': 500, 'id': 1})
            .select()
            .single();
        return Settings.fromMap(insertResp);
      } else {
        return Settings.fromMap(response.first);
      }
    } catch (e) {
      LoggerService.error('Error fetching settings', e);
      return Settings(id: 1, lowThresholdGrams: 500); // default 500g
    }
  }

  Future<void> updateLowThreshold(int newThreshold) async {
    if (isDemoMode) {
      await _initializeDemoData();
      _demoSettings = Settings(
        id: _demoSettings.id,
        lowThresholdGrams: newThreshold,
      );
      return;
    }

    try {
      final settings = await getSettings();
      await supabase
          .from('settings')
          .update({'low_threshold_grams': newThreshold}).eq('id', settings.id);
    } catch (e) {
      LoggerService.error('Error updating threshold', e);
    }
  }

  /// Trigger a local notification (temporarily disabled)
  Future<void> showLowRiceNotification(int currentWeight) async {
    // Temporarily disabled due to flutter_local_notifications dependency issues
    LoggerService.info(
        'Low Rice Alert: Rice level is down to $currentWeight g. Please refill soon.');
  }

  /// Get database statistics for management screen
  Future<Map<String, dynamic>> getDatabaseStats() async {
    if (isDemoMode) {
      await _initializeDemoData();

      final now = DateTime.now();
      final last24h = now.subtract(const Duration(hours: 24));

      final recentWeights =
          _demoRiceWeights.where((w) => w.timestamp.isAfter(last24h)).length;
      final recentRequests = _demoDispenseRequests
          .where((r) => r.requestedAt.isAfter(last24h))
          .length;

      return {
        'table_counts': {
          'settings': 1,
          'rice_weight': _demoRiceWeights.length,
          'dispense_request': _demoDispenseRequests.length,
        },
        'recent_activity': {
          'rice_weights_24h': recentWeights,
          'dispense_requests_24h': recentRequests,
        },
        'demo_mode': true,
      };
    }

    // For real database, use DatabaseUtility
    throw UnimplementedError(
        'getDatabaseStats should be called from DatabaseUtility for real database');
  }

  /// Refresh database connection status and table information
  Future<void> refreshDatabaseStatus() async {
    try {
      // Update connection status to initializing during refresh
      _updateConnectionStatus(DatabaseStatus.initializing);

      if (isDemoMode) {
        // In demo mode, simulate a delay and then show connected
        await Future.delayed(const Duration(milliseconds: 800));
        _updateConnectionStatus(DatabaseStatus.connected);

        // Refresh demo table statuses
        final demoStatuses = [
          DatabaseInfo(
            tableName: 'settings',
            status: TableStatus.exists,
            recordCount: 1,
            lastUpdated: DateTime.now(),
          ),
          DatabaseInfo(
            tableName: 'rice_weight',
            status: TableStatus.exists,
            recordCount: _demoRiceWeights.length,
            lastUpdated: DateTime.now(),
          ),
          DatabaseInfo(
            tableName: 'dispense_request',
            status: TableStatus.exists,
            recordCount: _demoDispenseRequests.length,
            lastUpdated: DateTime.now(),
          ),
        ];

        _updateTableStatuses(demoStatuses);
        return;
      }

      // For real database connection
      try {
        // Test connection
        await _testConnection();
        _updateConnectionStatus(DatabaseStatus.connected);

        // Update table statuses
        final tableStatuses = <DatabaseInfo>[];

        // Check settings table
        try {
          final settingsResponse = await supabase.from('settings').select('*');
          tableStatuses.add(DatabaseInfo(
            tableName: 'settings',
            status: TableStatus.exists,
            recordCount: settingsResponse.length,
            lastUpdated: DateTime.now(),
          ));
        } catch (e) {
          tableStatuses.add(DatabaseInfo(
            tableName: 'settings',
            status: TableStatus.missing,
            errorMessage: e.toString(),
          ));
        }

        // Check rice_weight table
        try {
          final riceWeightResponse = await supabase.from('rice_weight').select('*');
          tableStatuses.add(DatabaseInfo(
            tableName: 'rice_weight',
            status: TableStatus.exists,
            recordCount: riceWeightResponse.length,
            lastUpdated: DateTime.now(),
          ));
        } catch (e) {
          tableStatuses.add(DatabaseInfo(
            tableName: 'rice_weight',
            status: TableStatus.missing,
            errorMessage: e.toString(),
          ));
        }

        // Check dispense_request table
        try {
          final requestResponse = await supabase.from('dispense_request').select('*');
          tableStatuses.add(DatabaseInfo(
            tableName: 'dispense_request',
            status: TableStatus.exists,
            recordCount: requestResponse.length,
            lastUpdated: DateTime.now(),
          ));
        } catch (e) {
          tableStatuses.add(DatabaseInfo(
            tableName: 'dispense_request',
            status: TableStatus.missing,
            errorMessage: e.toString(),
          ));
        }

        _updateTableStatuses(tableStatuses);
      } catch (e) {
        _updateConnectionStatus(DatabaseStatus.error);
        _updateTableStatuses([]);
      }
    } catch (e) {
      _updateConnectionStatus(DatabaseStatus.error);
    }
  }
}
