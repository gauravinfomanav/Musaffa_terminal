/// Daily or intraday OHLCV point from Finnhub `stock/candle` proxy.
class OhlcCandlePoint {
  const OhlcCandlePoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  bool get isUp => close >= open;
}
