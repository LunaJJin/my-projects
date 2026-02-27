import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FrequencyBar extends StatelessWidget {
  final int number;
  final int count;
  final double percentage;
  final double maxCount;

  const FrequencyBar({
    super.key,
    required this.number,
    required this.count,
    required this.percentage,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.getBallColor(number);
    final ratio = maxCount > 0 ? count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: Text(
              '${count}회 (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
