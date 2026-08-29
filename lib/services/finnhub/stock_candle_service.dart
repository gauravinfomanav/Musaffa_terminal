import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class StockCandleService {
  StockCandleService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  static const Duration _twelveMonths = Duration(days: 365);

  Future<List<PriceDataPoint>> fetchDailyCloses(
    String symbol, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <PriceDataPoint>[];
    }

    final int fromEpoch = from.toUtc().millisecondsSinceEpoch ~/ 1000;
    final int toEpoch = to.toUtc().millisecondsSinceEpoch ~/ 1000;
    final String cacheKey = 'stock/candle:$normalized:D:$fromEpoch:$toEpoch';

    final dynamic decoded = await _client.get(
      'stock/candle',
      queryParameters: <String, String>{
        'symbol': normalized,
        'resolution': 'D',
        'from': fromEpoch.toString(),
        'to': toEpoch.toString(),
      },
      cacheKey: cacheKey,
      forceRefresh: forceRefresh,
    );

    if (decoded is! Map<String, dynamic>) {
      return <PriceDataPoint>[];
    }
    if (decoded['s'] != 'ok') {
      return <PriceDataPoint>[];
    }

    final List<dynamic> closes =
        decoded['c'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> timestamps =
        decoded['t'] as List<dynamic>? ?? <dynamic>[];

    final int count =
        closes.length < timestamps.length ? closes.length : timestamps.length;

    final List<PriceDataPoint> points = <PriceDataPoint>[];
    for (int index = 0; index < count; index++) {
      final dynamic closeRaw = closes[index];
      final dynamic timestampRaw = timestamps[index];
      if (closeRaw is! num || timestampRaw is! num) {
        continue;
      }
      points.add(
        PriceDataPoint(
          date: DateTime.fromMillisecondsSinceEpoch(
            timestampRaw.toInt() * 1000,
            isUtc: true,
          ).toLocal(),
          value: closeRaw.toDouble(),
        ),
      );
    }

    points.sort(
      (PriceDataPoint a, PriceDataPoint b) => a.date.compareTo(b.date),
    );
    return points;
  }

  Future<List<PriceDataPoint>> fetchLastTwelveMonths(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final DateTime to = DateTime.now();
    final DateTime from = to.subtract(_twelveMonths);
    return fetchDailyCloses(
      symbol,
      from: from,
      to: to,
      forceRefresh: forceRefresh,
    );
  }

  /// Full OHLCV candles from Finnhub `stock/candle` proxy.
  Future<List<OhlcCandlePoint>> fetchOhlc(
    String symbol, {
    required DateTime from,
    required DateTime to,
    String resolution = 'D',
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <OhlcCandlePoint>[];
    }

    final int fromEpoch = from.toUtc().millisecondsSinceEpoch ~/ 1000;
    final int toEpoch = to.toUtc().millisecondsSinceEpoch ~/ 1000;
    final String cacheKey =
        'stock/candle:$normalized:$resolution:$fromEpoch:$toEpoch';

    final dynamic decoded = await _client.get(
      'stock/candle',
      queryParameters: <String, String>{
        'symbol': normalized,
        'resolution': resolution,
        'from': fromEpoch.toString(),
        'to': toEpoch.toString(),
      },
      cacheKey: cacheKey,
      forceRefresh: forceRefresh,
    );

    if (decoded is! Map<String, dynamic>) {
      return <OhlcCandlePoint>[];
    }
    if (decoded['s'] != 'ok') {
      return <OhlcCandlePoint>[];
    }

    final List<dynamic> opens =
        decoded['o'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> highs =
        decoded['h'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> lows = decoded['l'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> closes =
        decoded['c'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> volumes =
        decoded['v'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> timestamps =
        decoded['t'] as List<dynamic>? ?? <dynamic>[];

    final int count = <int>[
      opens.length,
      highs.length,
      lows.length,
      closes.length,
      volumes.length,
      timestamps.length,
    ].reduce((int a, int b) => a < b ? a : b);

    final List<OhlcCandlePoint> points = <OhlcCandlePoint>[];
    for (int index = 0; index < count; index++) {
      final dynamic openRaw = opens[index];
      final dynamic highRaw = highs[index];
      final dynamic lowRaw = lows[index];
      final dynamic closeRaw = closes[index];
      final dynamic volumeRaw = volumes[index];
      final dynamic timestampRaw = timestamps[index];
      if (openRaw is! num ||
          highRaw is! num ||
          lowRaw is! num ||
          closeRaw is! num ||
          volumeRaw is! num ||
          timestampRaw is! num) {
        continue;
      }
      final double open = openRaw.toDouble();
      final double high = highRaw.toDouble();
      final double low = lowRaw.toDouble();
      final double close = closeRaw.toDouble();
      if (!_isValidOhlc(open: open, high: high, low: low, close: close)) {
        continue;
      }
      points.add(
        OhlcCandlePoint(
          date: DateTime.fromMillisecondsSinceEpoch(
            timestampRaw.toInt() * 1000,
            isUtc: true,
          ).toLocal(),
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volumeRaw.toDouble(),
        ),
      );
    }

    points.sort(
      (OhlcCandlePoint a, OhlcCandlePoint b) => a.date.compareTo(b.date),
    );
    return points;
  }

  static bool _isValidOhlc({
    required double open,
    required double high,
    required double low,
    required double close,
  }) {
    if (open <= 0 || high <= 0 || low <= 0 || close <= 0) return false;
    if (high < low) return false;
    if (close > high * 1.05 || close < low * 0.95) return false;
    if (open > high * 1.05 || open < low * 0.95) return false;
    return true;
  }
}
