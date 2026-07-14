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
}
