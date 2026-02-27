import 'package:flutter/material.dart';
import '../services/lotto_service.dart';
import '../widgets/frequency_bar.dart';

class AnalysisScreen extends StatelessWidget {
  final Map<int, int> frequency;
  final int totalRounds;

  const AnalysisScreen({
    super.key,
    required this.frequency,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    final topFrequent = LottoService.getTopFrequent(frequency, totalRounds);
    final leastFrequent = LottoService.getLeastFrequent(frequency, totalRounds);
    final rangeStats = LottoService.getRangeStats(frequency);

    final topMaxCount =
        topFrequent.isNotEmpty ? topFrequent.first.count.toDouble() : 1.0;
    final leastMaxCount =
        leastFrequent.isNotEmpty ? leastFrequent.last.count.toDouble() : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Card(
            color: Colors.deepPurple[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    '총 $totalRounds회차 당첨번호 통계',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 최다 출현 TOP 10
          const Text(
            '가장 많이 나온 번호 TOP 10',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...topFrequent.map(
            (d) => FrequencyBar(
              number: d.number,
              count: d.count,
              percentage: d.percentage,
              maxCount: topMaxCount,
            ),
          ),
          const SizedBox(height: 24),

          // 최소 출현 TOP 10
          const Text(
            '가장 적게 나온 번호 TOP 10',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...leastFrequent.map(
            (d) => FrequencyBar(
              number: d.number,
              count: d.count,
              percentage: d.percentage,
              maxCount: leastMaxCount,
            ),
          ),
          const SizedBox(height: 24),

          // 구간별 비율
          const Text(
            '구간별 출현 비율',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: rangeStats.map((r) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            r.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor:
                                    (r.percentage / 100 * 4).clamp(0.0, 1.0),
                                child: Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${r.percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 55,
                          child: Text(
                            '${r.count}회',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
