class LottoResult {
  final int round;
  final String date;
  final List<int> numbers;
  final int bonus;

  LottoResult({
    required this.round,
    required this.date,
    required this.numbers,
    required this.bonus,
  });

  factory LottoResult.fromJson(Map<String, dynamic> json) {
    return LottoResult(
      round: json['round'] as int,
      date: json['date'] as String,
      numbers: List<int>.from(json['numbers']),
      bonus: json['bonus'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'date': date,
      'numbers': numbers,
      'bonus': bonus,
    };
  }

  /// API 응답(lotto-haru)에서 변환
  factory LottoResult.fromApiJson(Map<String, dynamic> json) {
    return LottoResult(
      round: json['chasu'] as int,
      date: json['date'] as String,
      numbers: List<int>.from(json['ball'])..sort(),
      bonus: json['bonusBall'] as int,
    );
  }
}
