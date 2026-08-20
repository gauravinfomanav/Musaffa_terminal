/// Finnhub financial statements (`/stock/financials`).
class FinancialStatementModel {
  const FinancialStatementModel({
    required this.symbol,
    required this.statement,
    required this.frequency,
    required this.periods,
  });

  final String symbol;
  final String statement;
  final String frequency;

  /// Each map is one reporting period with dynamic Finnhub field keys.
  final List<Map<String, dynamic>> periods;

  bool get hasContent => periods.isNotEmpty;

  factory FinancialStatementModel.fromJson(
    Map<String, dynamic> json, {
    required String statement,
    required String frequency,
  }) {
    final List<dynamic> raw =
        json['financials'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> periods = raw
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList();

    return FinancialStatementModel(
      symbol: (json['symbol'] ?? '').toString(),
      statement: statement,
      frequency: frequency,
      periods: periods,
    );
  }
}
