import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lotto_result.dart';
import '../models/purchased_number.dart';
import '../utils/constants.dart';

class CacheService {
  /// 캐시에서 저장된 결과 로드
  static Future<List<LottoResult>> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.cacheKey);
    if (jsonString == null) return [];

    final data = json.decode(jsonString) as Map<String, dynamic>;
    final results = (data['results'] as List)
        .map((e) => LottoResult.fromJson(e as Map<String, dynamic>))
        .toList();
    return results;
  }

  /// 결과를 캐시에 저장
  static Future<void> saveCache(List<LottoResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'updated': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    };
    await prefs.setString(AppConstants.cacheKey, json.encode(data));
  }

  /// 캐시된 회차 번호 Set 반환
  static Future<Set<int>> getCachedRounds() async {
    final results = await loadCache();
    return results.map((r) => r.round).toSet();
  }

  /// 구매 번호 로드
  static Future<List<PurchasedNumber>> loadPurchasedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.purchasedKey);
    if (jsonString == null) return [];

    final list = json.decode(jsonString) as List;
    return list
        .map((e) => PurchasedNumber.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 구매 번호 저장 (기존 리스트에 추가)
  static Future<void> savePurchasedNumber(PurchasedNumber number) async {
    final prefs = await SharedPreferences.getInstance();
    final numbers = await loadPurchasedNumbers();
    numbers.add(number);
    final jsonString = json.encode(numbers.map((n) => n.toJson()).toList());
    await prefs.setString(AppConstants.purchasedKey, jsonString);
  }

  /// 구매 번호 삭제
  static Future<void> deletePurchasedNumber(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final numbers = await loadPurchasedNumbers();
    numbers.removeWhere((n) => n.id == id);
    final jsonString = json.encode(numbers.map((n) => n.toJson()).toList());
    await prefs.setString(AppConstants.purchasedKey, jsonString);
  }

  /// 생성된 번호 세트 저장
  static Future<void> saveGeneratedSets(List<List<int>> sets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(sets);
    await prefs.setString(AppConstants.generatedSetsKey, jsonString);
  }

  /// 생성된 번호 세트 로드
  static Future<List<List<int>>?> loadGeneratedSets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.generatedSetsKey);
    if (jsonString == null) return null;
    final list = json.decode(jsonString) as List;
    return list.map((e) => List<int>.from(e)).toList();
  }
}
