import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lotto_result.dart';
import '../utils/constants.dart';
import '../utils/lotto_utils.dart';
import 'cache_service.dart';

class LottoApiService {
  /// 여러 회차를 배치로 API 조회 (최대 50개씩)
  static Future<List<LottoResult>> fetchBatch(List<int> roundList) async {
    final chasuParam = roundList.join('|');
    final url = Uri.parse('${AppConstants.apiBaseUrl}?chasu=$chasuParam');

    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0',
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) return [];

    final List<dynamic> dataList = json.decode(response.body);
    return dataList
        .map((d) => LottoResult.fromApiJson(d as Map<String, dynamic>))
        .toList();
  }

  /// 전체 데이터 로드 (캐시 → 부족분만 API 호출)
  static Future<List<LottoResult>> fetchAllResults({
    int startYear = 2020,
    int endYear = 2026,
  }) async {
    final (startRound, endRound) = LottoUtils.getRoundRange(startYear, endYear);

    // 캐시 로드
    final cachedResults = await CacheService.loadCache();
    final cachedRounds = cachedResults.map((r) => r.round).toSet();

    // 캐시에 없는 회차
    final missingRounds = <int>[];
    for (int r = startRound; r <= endRound; r++) {
      if (!cachedRounds.contains(r)) {
        missingRounds.add(r);
      }
    }

    if (missingRounds.isEmpty) {
      // 캐시만으로 충분
      return cachedResults
          .where((r) => r.round >= startRound && r.round <= endRound)
          .toList()
        ..sort((a, b) => a.round.compareTo(b.round));
    }

    // API 배치 호출
    final allResults = List<LottoResult>.from(cachedResults);
    for (int i = 0; i < missingRounds.length; i += AppConstants.batchSize) {
      final batch = missingRounds.sublist(
        i,
        (i + AppConstants.batchSize).clamp(0, missingRounds.length),
      );
      final fetched = await fetchBatch(batch);
      // 연도 필터
      for (final result in fetched) {
        final year = int.parse(result.date.split('-')[0]);
        if (year >= startYear && year <= endYear) {
          allResults.add(result);
        }
      }
    }

    allResults.sort((a, b) => a.round.compareTo(b.round));

    // 캐시 저장
    await CacheService.saveCache(allResults);

    return allResults
        .where((r) => r.round >= startRound && r.round <= endRound)
        .toList();
  }
}
