// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../supabase_service.dart';
import '../models/rice_weight.dart';
import '../main.dart';
import '../widgets/weight_card.dart';
import '../widgets/level_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  RiceWeight? _currentWeight;
  late SettingsNotifier _settingsNotifier;
  late SupabaseService _supabaseService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();

    // Setup pulse animation for status indicators
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
      _loadInitialWeight();
      _subscribeToWeightChanges();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialWeight() async {
    setState(() => _isLoading = true);
    final latest = await _supabaseService.fetchLatestRiceWeight();
    if (latest != null) {
      setState(() {
        _currentWeight = latest;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToWeightChanges() {
    _supabaseService.onRiceWeightChange((newRw) {
      final lowThreshold = _settingsNotifier.settings.lowThresholdGrams;
      setState(() => _currentWeight = newRw);

      if (newRw.weightGrams <= lowThreshold) {
        _supabaseService.showLowRiceNotification(newRw.weightGrams);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final weight = _currentWeight?.weightGrams ?? 0;
    final levelState = _currentWeight?.levelState ?? 'empty';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Smart Rice Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Rice Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => Navigator.pushNamed(context, '/database-status'),
            tooltip: 'Database Status',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ScaleTransition(
              scale: levelState == 'empty'
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: WeightCard(weightGrams: weight),
            ),
            const SizedBox(height: 16),
            ScaleTransition(
              scale: levelState == 'empty'
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: LevelIndicator(levelState: levelState),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.rice_bowl),
              label: const Text('Dispense Rice'),
              onPressed: () => Navigator.pushNamed(context, '/dispense'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
