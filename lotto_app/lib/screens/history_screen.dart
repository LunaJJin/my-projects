import 'package:flutter/material.dart';
import '../models/lotto_result.dart';
import '../widgets/lotto_ball.dart';

class HistoryScreen extends StatelessWidget {
  final List<LottoResult> results;

  const HistoryScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    // 최신순 정렬
    final sorted = List<LottoResult>.from(results)
      ..sort((a, b) => b.round.compareTo(a.round));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final r = sorted[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${r.round}회',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      r.date,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...r.numbers.map(
                      (n) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: LottoBall(number: n, size: 36),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    LottoBall(number: r.bonus, size: 36, isBonus: true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
