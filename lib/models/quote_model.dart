/// Finnhub quote (`/quote`).
class QuoteModel {
  const QuoteModel({
    this.currentPrice,
    this.change,
    this.percentChange,
    this.high,
    this.low,
    this.open,
    this.previousClose,
    this.timestamp,
  });

  final double? currentPrice;
  final double? change;
  final double? percentChange;
  final double? high;
  final double? low;
  final double? open;
  final double? previousClose;
  final int? timestamp;

  bool get hasContent =>
      currentPrice != null || previousClose != null || open != null;

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      currentPrice: _toDouble(json['c']),
      change: _toDouble(json['d']),
      percentChange: _toDouble(json['dp']),
      high: _toDouble(json['h']),
      low: _toDouble(json['l']),
      open: _toDouble(json['o']),
      previousClose: _toDouble(json['pc']),
      timestamp: _toInt(json['t']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
