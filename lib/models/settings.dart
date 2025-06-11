// lib/models/settings.dart
class Settings {
  final int id;
  final int lowThresholdGrams;

  Settings({
    required this.id,
    required this.lowThresholdGrams,
  });

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'] as int,
      lowThresholdGrams: map['low_threshold_grams'] as int,
    );
  }
}
