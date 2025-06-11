// lib/models/dispense_request.dart
class DispenseRequest {
  final String id;
  final int requestedGrams;
  final double requestedCups;
  final int dispensedGrams; // Actual weight dispensed
  final String status; // "pending" or "completed"
  final DateTime requestedAt;

  DispenseRequest({
    required this.id,
    required this.requestedGrams,
    required this.requestedCups,
    required this.dispensedGrams,
    required this.status,
    required this.requestedAt,
  });

  factory DispenseRequest.fromMap(Map<String, dynamic> map) {
    return DispenseRequest(
      id: map['id'] as String,
      requestedGrams: map['requested_grams'] as int,
      requestedCups: (map['requested_cups'] as num).toDouble(),
      dispensedGrams: (map['dispensed_grams'] as int? ?? 0),
      status: map['status'] as String,
      requestedAt: DateTime.parse(map['requested_at'] as String),
    );
  }
}
