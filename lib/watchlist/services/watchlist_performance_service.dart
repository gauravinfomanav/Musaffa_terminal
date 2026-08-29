import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';

/// Equal-weighted watchlist returns + sparkline series from Finnhub daily candles.
class WatchlistPeriodPerformance {
  const WatchlistPeriodPerformance({
    this.todayPercent,
    this.weekPercent,
    this.monthPercent,
    this.yearPercent,
    this.sparkline = const <double>[],
    this.sparklineDates = const <DateTime>[],
  });

  final double? todayPercent;
  final double? weekPercent;
  final double? monthPercent;
  final double? yearPercent;

  /// Normalized equal-weight index values (≈1 year), for sparkline painting.
  final List<double> sparkline;

  /// Calendar dates aligned with [sparkline] (same length when both non-empty).
  final List<DateTime> sparklineDates;

  bool get hasAnyMetric =>
      todayPercent != null ||
      weekPercent != null ||
      monthPercent != null ||
      yearPercent != null;

  bool get isPositiveYear => (yearPercent ?? todayPercent ?? 0) >= 0;
}

class WatchlistPerformanceService {
  WatchlistPerformanceService({StockCandleService? candleService})
      : _candles = candleService ?? StockCandleService();

  final StockCandleService _candles;

  static const int _maxSymbols = 40;
  static const int _batchSize = 5;
  static const int _sparklinePoints = 72;

  /// [fallbackTodayPercents] keyed by uppercased symbol — used for Today when
  /// live table % change is already available.
  Future<WatchlistPeriodPerformance> compute({
    required List<String> symbols,
    Map<String, double>? fallbackTodayPercents,
  }) async {
    final List<String> unique = <String>[];
    final Set<String> seen = <String>{};
    for (final String raw in symbols) {
      final String s = raw.trim().toUpperCase();
      if (s.isEmpty || !seen.add(s)) continue;
      unique.add(s);
      if (unique.length >= _maxSymbols) break;
    }

    if (unique.isEmpty) {
      return const WatchlistPeriodPerformance();
    }

    final List<List<PriceDataPoint>> series =
        await _fetchAllDailyCloses(unique);

    final List<double> todayVals = <double>[];
    final List<double> weekVals = <double>[];
    final List<double> monthVals = <double>[];
    final List<double> yearVals = <double>[];

    for (int i = 0; i < unique.length; i++) {
      final String symbol = unique[i];
      final List<PriceDataPoint> closes = series[i];
      final double? fromTable = fallbackTodayPercents?[symbol];
      if (fromTable != null) {
        todayVals.add(fromTable);
      } else {
        final double? day = _returnOverTradingDays(closes, 1);
        if (day != null) todayVals.add(day);
      }

      final double? week = _returnOverCalendar(closes, const Duration(days: 7));
      if (week != null) weekVals.add(week);

      final double? month =
          _returnOverCalendar(closes, const Duration(days: 30));
      if (month != null) monthVals.add(month);

      final double? year =
          _returnOverCalendar(closes, const Duration(days: 365));
      if (year != null) yearVals.add(year);
    }

    final SparklineSeries spark = _buildEqualWeightSparkline(series);

    return WatchlistPeriodPerformance(
      todayPercent: _avg(todayVals),
      weekPercent: _avg(weekVals),
      monthPercent: _avg(monthVals),
      yearPercent: _avg(yearVals),
      sparkline: spark.values,
      sparklineDates: spark.dates,
    );
  }

  Future<List<List<PriceDataPoint>>> _fetchAllDailyCloses(
    List<String> symbols,
  ) async {
    final List<List<PriceDataPoint>> out =
        List<List<PriceDataPoint>>.filled(symbols.length, const <PriceDataPoint>[]);

    for (int start = 0; start < symbols.length; start += _batchSize) {
      final int end = (start + _batchSize).clamp(0, symbols.length);
      final List<Future<List<PriceDataPoint>>> batch = <Future<List<PriceDataPoint>>>[];
      for (int i = start; i < end; i++) {
        batch.add(
          _candles.fetchLastTwelveMonths(symbols[i]).catchError(
            (_) => <PriceDataPoint>[],
          ),
        );
      }
      final List<List<PriceDataPoint>> results = await Future.wait(batch);
      for (int j = 0; j < results.length; j++) {
        out[start + j] = results[j];
      }
    }
    return out;
  }

  /// Percent return from ~[tradingDays] bars ago to latest close.
  double? _returnOverTradingDays(List<PriceDataPoint> closes, int tradingDays) {
    if (closes.length < tradingDays + 1) return null;
    final PriceDataPoint last = closes.last;
    final PriceDataPoint base = closes[closes.length - 1 - tradingDays];
    if (base.value <= 0) return null;
    return (last.value - base.value) / base.value * 100.0;
  }

  /// Percent return from the close on/before [now - lookback] to latest.
  double? _returnOverCalendar(
    List<PriceDataPoint> closes,
    Duration lookback,
  ) {
    if (closes.length < 2) return null;
    final PriceDataPoint last = closes.last;
    final DateTime target = last.date.subtract(lookback);

    PriceDataPoint? base;
    for (final PriceDataPoint p in closes) {
      if (!p.date.isAfter(target)) {
        base = p;
      } else {
        break;
      }
    }
    base ??= closes.first;
    if (identical(base, last) || base.value <= 0) return null;
    return (last.value - base.value) / base.value * 100.0;
  }

  /// Equal-weight index: each series normalized to 100 at its first close,
  /// then averaged per calendar day and downsampled.
  SparklineSeries _buildEqualWeightSparkline(
    List<List<PriceDataPoint>> series,
  ) {
    final List<List<PriceDataPoint>> usable = series
        .where((List<PriceDataPoint> s) => s.length >= 2)
        .toList();
    if (usable.isEmpty) return const SparklineSeries();

    final Map<String, List<double>> dayBuckets = <String, List<double>>{};

    for (final List<PriceDataPoint> closes in usable) {
      final double start = closes.first.value;
      if (start <= 0) continue;
      for (final PriceDataPoint p in closes) {
        final String key =
            '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
        (dayBuckets[key] ??= <double>[]).add((p.value / start) * 100.0);
      }
    }

    if (dayBuckets.isEmpty) return const SparklineSeries();

    final List<String> keys = dayBuckets.keys.toList()..sort();
    final List<double> index = <double>[];
    final List<DateTime> dates = <DateTime>[];
    for (final String key in keys) {
      final List<double> vals = dayBuckets[key]!;
      if (vals.isEmpty) continue;
      index.add(vals.reduce((double a, double b) => a + b) / vals.length);
      final List<String> parts = key.split('-');
      if (parts.length == 3) {
        dates.add(
          DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ),
        );
      }
    }

    return _downsampleSeries(index, dates, _sparklinePoints);
  }

  SparklineSeries _downsampleSeries(
    List<double> values,
    List<DateTime> dates,
    int target,
  ) {
    if (values.isEmpty || dates.isEmpty) {
      return const SparklineSeries();
    }
    if (values.length != dates.length) {
      return SparklineSeries(
        values: _downsample(values, target),
        dates: const <DateTime>[],
      );
    }
    if (values.length <= target) {
      return SparklineSeries(
        values: List<double>.from(values),
        dates: List<DateTime>.from(dates),
      );
    }
    if (target < 2) {
      return SparklineSeries(
        values: <double>[values.last],
        dates: <DateTime>[dates.last],
      );
    }

    final List<double> outV = <double>[];
    final List<DateTime> outD = <DateTime>[];
    final int last = values.length - 1;
    for (int i = 0; i < target; i++) {
      final double t = i / (target - 1);
      final int idx = (t * last).round().clamp(0, last);
      outV.add(values[idx]);
      outD.add(dates[idx]);
    }
    return SparklineSeries(values: outV, dates: outD);
  }

  List<double> _downsample(List<double> values, int target) {
    if (values.length <= target) return List<double>.from(values);
    if (target < 2) return <double>[values.last];

    final List<double> out = <double>[];
    final int last = values.length - 1;
    for (int i = 0; i < target; i++) {
      final double t = i / (target - 1);
      final int idx = (t * last).round().clamp(0, last);
      out.add(values[idx]);
    }
    return out;
  }

  double? _avg(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((double a, double b) => a + b) / values.length;
  }
}

/// Sparkline points for the equal-weight watchlist index chart.
class SparklineSeries {
  const SparklineSeries({
    this.values = const <double>[],
    this.dates = const <DateTime>[],
  });

  final List<double> values;
  final List<DateTime> dates;
}
