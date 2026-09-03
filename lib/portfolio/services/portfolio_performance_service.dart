import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/services/finnhub/quote_service.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';

class PortfolioPeriodPerformance {
  const PortfolioPeriodPerformance({
    this.todayPercent,
    this.weekPercent,
    this.monthPercent,
    this.sparkline = const <double>[],
    this.sparklineDates = const <DateTime>[],
  });

  final double? todayPercent;
  final double? weekPercent;
  final double? monthPercent;
  final List<double> sparkline;
  final List<DateTime> sparklineDates;

  bool get isPositive => (monthPercent ?? weekPercent ?? todayPercent ?? 0) >= 0;
}

class PortfolioHoldingQuote {
  const PortfolioHoldingQuote({
    required this.ticker,
    required this.name,
    this.logo,
    this.changePercent,
    this.sparkline = const <double>[],
  });

  final String ticker;
  final String name;
  final String? logo;
  final double? changePercent;
  final List<double> sparkline;
}

class PortfolioPerformanceService {
  PortfolioPerformanceService({
    StockCandleService? candleService,
    QuoteService? quoteService,
  })  : _candles = candleService ?? StockCandleService(),
        _quotes = quoteService ?? QuoteService();

  final StockCandleService _candles;
  final QuoteService _quotes;

  static const _maxSymbols = 25;
  static const _historyDays = 30;

  Future<PortfolioPeriodPerformance> loadPortfolioPerformance(
    List<ModelPortfolioHolding> holdings,
  ) async {
    final eligible = _eligible(holdings);
    if (eligible.isEmpty) return const PortfolioPeriodPerformance();

    final weights = _normalizedWeights(eligible);
    final from = DateTime.now().subtract(const Duration(days: _historyDays));
    final to = DateTime.now();

    final series = await Future.wait(
      eligible.map((h) => _closes(h.ticker.trim().toUpperCase(), from, to)),
    );

    final weekVals = <double>[];
    final monthVals = <double>[];
    for (var i = 0; i < series.length; i++) {
      final w = weights[i];
      if (w <= 0) continue;
      final week = _returnOverCalendar(series[i], const Duration(days: 7));
      final month = _returnOverCalendar(series[i], const Duration(days: 30));
      if (week != null) weekVals.add(week * w);
      if (month != null) monthVals.add(month * w);
    }

    final spark = _buildWeightedSparkline(series, weights);
    final today = await _weightedTodayChange(eligible, weights);

    return PortfolioPeriodPerformance(
      todayPercent: today,
      weekPercent: weekVals.isEmpty ? null : weekVals.reduce((a, b) => a + b),
      monthPercent: monthVals.isEmpty ? null : monthVals.reduce((a, b) => a + b),
      sparkline: spark.values,
      sparklineDates: spark.dates,
    );
  }

  Future<List<PortfolioHoldingQuote>> loadTopHoldingsQuotes(
    List<ModelPortfolioHolding> holdings, {
    int limit = 5,
  }) async {
    final sorted = [...holdings]
      ..sort((a, b) => b.targetPercent.compareTo(a.targetPercent));
    final top = sorted
        .where((h) => ModelPortfolioHolding.isSearchableAsset(h.assetType))
        .take(limit)
        .toList();

    if (top.isEmpty) return const [];

    final from = DateTime.now().subtract(const Duration(days: _historyDays));
    final to = DateTime.now();

    return Future.wait(
      top.map((h) async {
        final ticker = h.ticker.trim().toUpperCase();
        double? change;
        List<double> spark = const [];

        try {
          final quote = await _quotes.fetchQuote(ticker);
          change = quote?.percentChange;
        } catch (_) {}

        try {
          final closes = await _candles.fetchDailyCloses(ticker, from: from, to: to);
          if (closes.length >= 2) {
            spark = _downsample(
              closes.map((p) => p.value).toList(),
              24,
            );
          }
        } catch (_) {}

        return PortfolioHoldingQuote(
          ticker: ticker,
          name: h.company ?? ticker,
          logo: h.tickerModel?.logo,
          changePercent: change,
          sparkline: spark,
        );
      }),
    );
  }

  List<ModelPortfolioHolding> _eligible(List<ModelPortfolioHolding> holdings) {
    final seen = <String>{};
    final out = <ModelPortfolioHolding>[];
    for (final h in holdings) {
      if (!ModelPortfolioHolding.isSearchableAsset(h.assetType)) continue;
      final t = h.ticker.trim().toUpperCase();
      if (t.isEmpty || !seen.add(t)) continue;
      out.add(h);
      if (out.length >= _maxSymbols) break;
    }
    return out;
  }

  List<double> _normalizedWeights(List<ModelPortfolioHolding> holdings) {
    final raw = holdings.map((h) => h.targetPercent.clamp(0, 100)).toList();
    final sum = raw.fold<double>(0, (s, w) => s + w);
    if (sum <= 0) {
      return List<double>.filled(holdings.length, 1 / holdings.length);
    }
    return raw.map((w) => w / sum).toList();
  }

  Future<double?> _weightedTodayChange(
    List<ModelPortfolioHolding> holdings,
    List<double> weights,
  ) async {
    final values = <double>[];
    final weightSum = <double>[];

    for (var i = 0; i < holdings.length; i++) {
      try {
        final quote = await _quotes.fetchQuote(holdings[i].ticker.trim().toUpperCase());
        final change = quote?.percentChange;
        if (change != null) {
          values.add(change * weights[i]);
          weightSum.add(weights[i]);
        }
      } catch (_) {}
    }

    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b);
  }

  Future<List<PriceDataPoint>> _closes(
    String symbol,
    DateTime from,
    DateTime to,
  ) async {
    try {
      return await _candles.fetchDailyCloses(symbol, from: from, to: to);
    } catch (_) {
      return <PriceDataPoint>[];
    }
  }

  double? _returnOverCalendar(List<PriceDataPoint> closes, Duration lookback) {
    if (closes.length < 2) return null;
    final last = closes.last;
    final target = last.date.subtract(lookback);

    PriceDataPoint? base;
    for (final p in closes) {
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

  ({List<double> values, List<DateTime> dates}) _buildWeightedSparkline(
    List<List<PriceDataPoint>> series,
    List<double> weights,
  ) {
    final usable = <int>[];
    for (var i = 0; i < series.length; i++) {
      if (series[i].length >= 2) usable.add(i);
    }
    if (usable.isEmpty) return (values: const [], dates: const []);

    final dayBuckets = <String, double>{};
    final dayWeight = <String, double>{};

    for (final i in usable) {
      final closes = series[i];
      final start = closes.first.value;
      if (start <= 0) continue;
      final w = weights[i];
      for (final p in closes) {
        final key =
            '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
        dayBuckets[key] = (dayBuckets[key] ?? 0) + (p.value / start) * 100.0 * w;
        dayWeight[key] = (dayWeight[key] ?? 0) + w;
      }
    }

    if (dayBuckets.isEmpty) return (values: const [], dates: const []);

    final keys = dayBuckets.keys.toList()..sort();
    final index = <double>[];
    final dates = <DateTime>[];
    for (final key in keys) {
      final w = dayWeight[key]!;
      if (w <= 0) continue;
      index.add(dayBuckets[key]! / w);
      final parts = key.split('-');
      if (parts.length == 3) {
        dates.add(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
      }
    }

    final downsampled = _downsampleSeries(index, dates, 72);
    return (values: downsampled.values, dates: downsampled.dates);
  }

  ({List<double> values, List<DateTime> dates}) _downsampleSeries(
    List<double> values,
    List<DateTime> dates,
    int target,
  ) {
    if (values.isEmpty) return (values: const [], dates: const []);
    if (values.length <= target) {
      return (values: List<double>.from(values), dates: List<DateTime>.from(dates));
    }
    final outV = <double>[];
    final outD = <DateTime>[];
    final last = values.length - 1;
    for (var i = 0; i < target; i++) {
      final idx = ((i / (target - 1)) * last).round().clamp(0, last);
      outV.add(values[idx]);
      if (dates.length == values.length) outD.add(dates[idx]);
    }
    return (values: outV, dates: outD);
  }

  List<double> _downsample(List<double> values, int target) {
    if (values.length <= target) return List<double>.from(values);
    if (target < 2) return [values.last];
    final out = <double>[];
    final last = values.length - 1;
    for (var i = 0; i < target; i++) {
      final idx = ((i / (target - 1)) * last).round().clamp(0, last);
      out.add(values[idx]);
    }
    return out;
  }
}
