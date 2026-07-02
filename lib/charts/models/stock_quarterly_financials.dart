/// One quarterly financial period from the Infomanav Finnhub proxy.
class QuarterlyFinancialPeriod {
  const QuarterlyFinancialPeriod({
    required this.period,
    required this.values,
  });

  factory QuarterlyFinancialPeriod.fromJson(Map<String, dynamic> json) {
    final Map<String, double> values = <String, double>{};
    for (final MapEntry<String, dynamic> entry in json.entries) {
      if (entry.key == 'period') {
        continue;
      }
      final double? parsed = _toDouble(entry.value);
      if (parsed != null) {
        values[entry.key] = parsed;
      }
    }

    return QuarterlyFinancialPeriod(
      period: json['period'] as String? ?? '',
      values: values,
    );
  }

  final String period;
  final Map<String, double> values;

  DateTime get periodDate =>
      DateTime.tryParse(period) ?? DateTime.fromMillisecondsSinceEpoch(0);

  double? valueFor(String key) => values[key];

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

/// Response from `api=stock/financials&statement={ic|bs|cf}&freq=quarterly`.
class StockQuarterlyFinancialsResponse {
  const StockQuarterlyFinancialsResponse({
    required this.symbol,
    required this.financials,
  });

  factory StockQuarterlyFinancialsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw =
        json['financials'] as List<dynamic>? ?? <dynamic>[];
    return StockQuarterlyFinancialsResponse(
      symbol: json['symbol'] as String? ?? '',
      financials: raw
          .whereType<Map<String, dynamic>>()
          .map(QuarterlyFinancialPeriod.fromJson)
          .where((QuarterlyFinancialPeriod item) => item.period.isNotEmpty)
          .toList(),
    );
  }

  final String symbol;
  final List<QuarterlyFinancialPeriod> financials;
}
