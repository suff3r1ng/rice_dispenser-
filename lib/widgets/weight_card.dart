// lib/widgets/weight_card.dart
import 'package:flutter/material.dart';

class WeightCard extends StatelessWidget {
  final int weightGrams;
  const WeightCard({Key? key, required this.weightGrams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final kilos = (weightGrams / 1000).toStringAsFixed(2);
    final percentage = (weightGrams / 5000 * 100)
        .clamp(0, 100)
        .toInt(); // Assuming max capacity of 5kg

    Color getStatusColor() {
      if (percentage >= 70) return Colors.green;
      if (percentage >= 30) return Colors.orange;
      return Colors.red;
    }

    String getStatusText() {
      if (percentage >= 70) return 'Good Level';
      if (percentage >= 30) return 'Moderate Level';
      return 'Low Level';
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              getStatusColor().withOpacity(0.1),
              getStatusColor().withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.scale,
                        color: getStatusColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Weight',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getStatusText(),
                      style: TextStyle(
                        color: getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Weight Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$weightGrams',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: getStatusColor(),
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'g',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                '($kilos kg)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),

              const SizedBox(height: 16),

              // Progress Bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capacity',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(getStatusColor()),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
