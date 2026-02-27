import 'dart:math';
import '../models/lotto_result.dart';
import '../utils/constants.dart';

class FrequencyData {
  final int number;
  final int count;
  final double percentage;

  FrequencyData({
    required this.number,
    required this.count,
    required this.percentage,
  });
}

class RangeData {
  final String label;
  final int count;
  final double percentage;

  RangeData({
    required this.label,
    required this.count,
    required this.percentage,
  });
}

class LottoService {
  /// 전체 번호 빈도 계산
  static Map<int, int> calculateFrequency(List<LottoResult> results) {
    final freq = <int, int>{};
    for (final r in results) {
      for (final n in r.numbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  /// 최다 출현 TOP N
  static List<FrequencyData> getTopFrequent(
    Map<int, int> freq,
    int totalRounds, {
    int topN = 10,
  }) {
    final entries = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(topN).map((e) {
      return FrequencyData(
        number: e.key,
        count: e.value,
        percentage: e.value / totalRounds * 100,
      );
    }).toList();
  }

  /// 최소 출현 TOP N
  static List<FrequencyData> getLeastFrequent(
    Map<int, int> freq,
    int totalRounds, {
    int topN = 10,
  }) {
    final entries = freq.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(topN).map((e) {
      return FrequencyData(
        number: e.key,
        count: e.value,
        percentage: e.value / totalRounds * 100,
      );
    }).toList();
  }

  /// 구간별 출현 비율
  static List<RangeData> getRangeStats(Map<int, int> freq) {
    final totalCount = freq.values.fold<int>(0, (sum, v) => sum + v);
    return AppConstants.numberRanges.map((range) {
      final start = range[0];
      final end = range[1];
      int rangeCount = 0;
      for (int n = start; n <= end; n++) {
        rangeCount += freq[n] ?? 0;
      }
      return RangeData(
        label: '$start~$end',
        count: rangeCount,
        percentage: totalCount > 0 ? rangeCount / totalCount * 100 : 0,
      );
    }).toList();
  }

  /// 빈도 가중치 기반 번호 생성 (count 세트)
  static List<List<int>> generateNumbers(Map<int, int> freq, {int count = 5}) {
    final random = Random();
    final numbers = List.generate(45, (i) => i + 1);
    final weights = numbers.map((n) => (freq[n] ?? 0) + 1).toList();
    final totalWeight = weights.fold<int>(0, (sum, w) => sum + w);

    final generated = <List<int>>[];
    for (int i = 0; i < count; i++) {
      final picked = <int>{};
      while (picked.length < 6) {
        // 가중치 기반 랜덤 선택
        double r = random.nextDouble() * totalWeight;
        for (int j = 0; j < numbers.length; j++) {
          r -= weights[j];
          if (r <= 0) {
            picked.add(numbers[j]);
            break;
          }
        }
      }
      generated.add(picked.toList()..sort());
    }
    return generated;
  }
}
