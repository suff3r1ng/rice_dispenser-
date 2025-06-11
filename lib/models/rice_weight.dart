// lib/models/rice_weight.dart
class RiceWeight {
  final String id;
  final DateTime timestamp;
  final int weightGrams;
  final String levelState; // "full", "partial", or "empty"

  RiceWeight({
    required this.id,
    required this.timestamp,
    required this.weightGrams,
    required this.levelState,
  });

  factory RiceWeight.fromMap(Map<String, dynamic> map) {
    return RiceWeight(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      weightGrams: map['weight_grams'] as int,
      levelState: map['level_state'] as String,
    );
  }
}
