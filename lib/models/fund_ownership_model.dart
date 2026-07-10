class FundOwnershipModel {
  const FundOwnershipModel({
    required this.name,
    required this.share,
    required this.portfolioPercent,
    required this.change,
    required this.filingDate,
  });

  final String name;
  final num share;
  final double portfolioPercent;
  final num change;
  final DateTime? filingDate;

  factory FundOwnershipModel.fromJson(Map<String, dynamic> json) {
    return FundOwnershipModel(
      name: (json['name'] ?? '').toString(),
      share: _num(json['share']),
      portfolioPercent: _double(json['portfolioPercent']),
      change: _num(json['change']),
      filingDate: _date(json['filingDate']),
    );
  }
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  final String raw = value.toString().trim();
  if (raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}
