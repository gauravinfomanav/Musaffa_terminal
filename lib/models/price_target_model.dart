class PriceTargetModel {
  const PriceTargetModel({
    required this.symbol,
    required this.targetHigh,
    required this.targetMean,
    required this.targetLow,
    required this.targetMedian,
    required this.numberAnalysts,
    required this.lastUpdated,
  });

  final String symbol;
  final double targetHigh;
  final double targetMean;
  final double targetLow;
  final double targetMedian;
  final int numberAnalysts;
  final DateTime? lastUpdated;

  bool get hasTargets =>
      targetHigh > 0 || targetMean > 0 || targetLow > 0;

  factory PriceTargetModel.fromJson(Map<String, dynamic> json) {
    return PriceTargetModel(
      symbol: (json['symbol'] ?? '').toString(),
      targetHigh: _double(json['targetHigh']),
      targetMean: _double(json['targetMean']),
      targetLow: _double(json['targetLow']),
      targetMedian: _double(json['targetMedian']),
      numberAnalysts: _int(json['numberAnalysts']),
      lastUpdated: _date(json['lastUpdated']),
    );
  }
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
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
