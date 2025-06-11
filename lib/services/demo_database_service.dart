// lib/services/demo_database_service.dart
import 'dart:async';
import 'dart:math' as math;
import '../models/rice_weight.dart';
import '../models/dispense_request.dart';
import '../models/settings.dart';

/// Demo database service for testing without Supabase connection
class DemoDatabaseService {
  static final DemoDatabaseService _instance = DemoDatabaseService._internal();
  factory DemoDatabaseService() => _instance;
  DemoDatabaseService._internal();

  // In-memory storage for demo data
  final List<RiceWeight> _riceWeights = [];
  final List<DispenseRequest> _dispenseRequests = [];
  Settings _settings = Settings(id: 1, lowThresholdGrams: 500);

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔧 Initializing Demo Database Service...');

    // Generate demo data
    await _generateDemoRiceWeights();
    await _generateDemoDispenseRequests();

    _isInitialized = true;
    print('✅ Demo Database Service initialized successfully');
  }

  Future<void> _generateDemoRiceWeights() async {
    final now = DateTime.now();
    final random = math.Random();

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

      _riceWeights.add(RiceWeight(
        id: 'demo_${i}_${random.nextInt(1000)}',
        timestamp: timestamp,
        weightGrams: weight.toInt(),
        levelState: levelState,
      ));
    }
  }

  Future<void> _generateDemoDispenseRequests() async {
    final now = DateTime.now();
    final random = math.Random();
    final statuses = ['completed', 'pending', 'failed'];

    for (int i = 10; i >= 0; i--) {
      final requestTime = now.subtract(Duration(hours: i * 2));
      final requestedGrams = [100, 200, 300, 500][random.nextInt(4)];
      final status = statuses[random.nextInt(statuses.length)];

      _dispenseRequests.add(DispenseRequest(
        id: 'demo_req_${i}_${random.nextInt(1000)}',
        requestedGrams: requestedGrams,
        requestedCups: requestedGrams / 200.0,
        dispensedGrams: status == 'completed' ? requestedGrams : 0,
        status: status,
        requestedAt: requestTime,
      ));
    }
  }

  // Rice Weight methods
  Future<RiceWeight?> fetchLatestRiceWeight() async {
    await initialize();
    return _riceWeights.isNotEmpty ? _riceWeights.last : null;
  }

  Future<List<RiceWeight>> fetchRiceWeightHistory() async {
    await initialize();
    return List.from(_riceWeights);
  }

  Future<void> addRiceWeight(RiceWeight riceWeight) async {
    await initialize();
    _riceWeights.add(riceWeight);
  }

  // Dispense Request methods
  Future<void> createDispenseRequest(int grams) async {
    await initialize();
    final request = DispenseRequest(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      requestedGrams: grams,
      requestedCups: grams / 200.0,
      dispensedGrams: 0,
      status: 'pending',
      requestedAt: DateTime.now(),
    );
    _dispenseRequests.add(request);

    // Simulate processing after 3 seconds
    Timer(const Duration(seconds: 3), () {
      final index = _dispenseRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _dispenseRequests[index] = DispenseRequest(
          id: request.id,
          requestedGrams: request.requestedGrams,
          requestedCups: request.requestedCups,
          dispensedGrams: grams,
          status: 'completed',
          requestedAt: request.requestedAt,
        );
      }
    });
  }

  Future<List<DispenseRequest>> fetchDispenseHistory() async {
    await initialize();
    return List.from(_dispenseRequests.reversed);
  }

  // Settings methods
  Future<Settings> getSettings() async {
    await initialize();
    return _settings;
  }

  Future<void> updateLowThreshold(int newThreshold) async {
    await initialize();
    _settings = Settings(
      id: _settings.id,
      lowThresholdGrams: newThreshold,
    );
  }

  // Database stats for management screen
  Future<Map<String, dynamic>> getDatabaseStats() async {
    await initialize();

    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));

    final recentWeights =
        _riceWeights.where((w) => w.timestamp.isAfter(last24h)).length;
    final recentRequests =
        _dispenseRequests.where((r) => r.requestedAt.isAfter(last24h)).length;

    return {
      'table_counts': {
        'settings': 1,
        'rice_weight': _riceWeights.length,
        'dispense_request': _dispenseRequests.length,
      },
      'recent_activity': {
        'rice_weights_24h': recentWeights,
        'dispense_requests_24h': recentRequests,
      },
      'demo_mode': true,
    };
  }
}
