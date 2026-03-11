import 'package:flutter/material.dart';

class WeeklySummaryItem extends StatelessWidget {
  final String label;
  final double value;

  const WeeklySummaryItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text(value.toStringAsFixed(2)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (value / 7.0).clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
