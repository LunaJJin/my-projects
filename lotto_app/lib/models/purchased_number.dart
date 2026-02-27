class PurchasedNumber {
  final String id;
  final List<int> numbers;
  final String purchasedDate;

  PurchasedNumber({
    required this.id,
    required this.numbers,
    required this.purchasedDate,
  });

  factory PurchasedNumber.fromJson(Map<String, dynamic> json) {
    return PurchasedNumber(
      id: json['id'] as String,
      numbers: List<int>.from(json['numbers']),
      purchasedDate: json['purchasedDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numbers': numbers,
      'purchasedDate': purchasedDate,
    };
  }
}
