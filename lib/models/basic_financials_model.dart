/// Finnhub basic financials (`/stock/metric`).
///
/// Keeps the raw `metric` map so only present keys are displayed.
class BasicFinancialsModel {
  const BasicFinancialsModel({
    required this.metric,
    this.series,
    this.symbol,
  });

  final Map<String, dynamic> metric;
  final Map<String, dynamic>? series;
  final String? symbol;

  bool get hasContent => metric.isNotEmpty;

  num? metricNum(String key) {
    final dynamic value = metric[key];
    if (value is num) return value;
    if (value == null) return null;
    return num.tryParse(value.toString());
  }

  factory BasicFinancialsModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawMetric = json['metric'];
    final Map<String, dynamic> metric = rawMetric is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMetric)
        : <String, dynamic>{};

    final dynamic rawSeries = json['series'];
    final Map<String, dynamic>? series = rawSeries is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawSeries)
        : null;

    return BasicFinancialsModel(
      metric: metric,
      series: series,
      symbol: json['symbol']?.toString(),
    );
  }
}
