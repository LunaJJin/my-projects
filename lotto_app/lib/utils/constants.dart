import 'package:flutter/material.dart';

class AppConstants {
  static const String apiBaseUrl = 'https://api.lotto-haru.kr/win/analysis.json';
  static const String cacheKey = 'lotto_cache';
  static const String purchasedKey = 'purchased_numbers';
  static const String generatedSetsKey = 'generated_sets';
  static const int startYear = 2020;
  static const int endYear = 2026;
  static const int batchSize = 50;

  /// 로또 1회차 시작일 (2002-12-07)
  static final DateTime lottoStartDate = DateTime(2002, 12, 7);

  /// 번호 구간 (통계용)
  static const List<List<int>> numberRanges = [
    [1, 10],
    [11, 20],
    [21, 30],
    [31, 40],
    [41, 45],
  ];

  /// 로또 공 색상 (번호 구간별)
  static const Map<String, Color> ballColors = {
    '1-10': Color(0xFFFBC02D),   // 노랑
    '11-20': Color(0xFF42A5F5),  // 파랑
    '21-30': Color(0xFFEF5350),  // 빨강
    '31-40': Color(0xFF78909C),  // 회색
    '41-45': Color(0xFF66BB6A),  // 초록
  };

  static Color getBallColor(int number) {
    if (number <= 10) return ballColors['1-10']!;
    if (number <= 20) return ballColors['11-20']!;
    if (number <= 30) return ballColors['21-30']!;
    if (number <= 40) return ballColors['31-40']!;
    return ballColors['41-45']!;
  }
}
