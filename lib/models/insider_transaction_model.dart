class InsiderTransactionModel {
  const InsiderTransactionModel({
    required this.name,
    required this.change,
    required this.share,
    required this.transactionPrice,
    required this.transactionDate,
    required this.filingDate,
  });

  final String name;
  final num change;
  final num share;
  final num transactionPrice;
  final DateTime? transactionDate;
  final DateTime? filingDate;

  bool get isBuy => change > 0;
  bool get isSell => change < 0;

  factory InsiderTransactionModel.fromJson(Map<String, dynamic> json) {
    return InsiderTransactionModel(
      name: (json['name'] ?? json['insiderName'] ?? json['insider'] ?? '')
          .toString(),
      change: _num(json['change'] ?? json['shareChange']),
      share: _num(json['share'] ?? json['shareHeld']),
      transactionPrice:
          _num(json['transactionPrice'] ?? json['price'] ?? json['transactionPriceUSD']),
      transactionDate:
          _date(json['transactionDate'] ?? json['transactionDateTime']),
      filingDate: _date(json['filingDate']),
    );
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    final String raw = value.toString();
    if (raw.isEmpty) return null;
    try {
      if (raw.length == 10 && int.tryParse(raw) != null) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(raw) * 1000);
      }
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
