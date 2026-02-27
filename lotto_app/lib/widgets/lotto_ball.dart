import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LottoBall extends StatelessWidget {
  final int number;
  final double size;
  final bool isBonus;

  const LottoBall({
    super.key,
    required this.number,
    this.size = 40,
    this.isBonus = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.getBallColor(number);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: isBonus
            ? Border.all(color: Colors.orange, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
