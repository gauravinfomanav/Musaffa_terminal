import 'dart:math' as math;

import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/basic_financials_model.dart';
import 'package:musaffa_terminal/models/quote_model.dart';
import 'package:musaffa_terminal/models/stock_profile_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/models/portfolio_analytics_snapshot.dart';
import 'package:musaffa_terminal/portfolio/services/model_portfolio_enrichment.dart';
import 'package:musaffa_terminal/services/company_enrichment_cache.dart';
import 'package:musaffa_terminal/services/finnhub/basic_financials_service.dart';
import 'package:musaffa_terminal/services/finnhub/quote_service.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';
import 'package:musaffa_terminal/services/finnhub/stock_profile_service.dart';

class PortfolioAnalyticsService {
  PortfolioAnalyticsService({
    StockCandleService? candleService,
    QuoteService? quoteService,
    StockProfileService? profileService,
    BasicFinancialsService? financialsService,
  })  : _candles = candleService ?? StockCandleService(),
        _quotes = quoteService ?? QuoteService(),
        _profiles = profileService ?? StockProfileService(),
        _financials = financialsService ?? BasicFinancialsService();

  final StockCandleService _candles;
  final QuoteService _quotes;
  final StockProfileService _profiles;
  final BasicFinancialsService _financials;

  static const _maxSymbols = 30;
  static const _correlationMax = 8;

  Future<PortfolioAnalyticsSnapshot> load({
    required List<ModelPortfolioHolding> holdings,
    String benchmarkLabel = 'S&P 500',
  }) async {
    if (holdings.isEmpty) return PortfolioAnalyticsSnapshot.empty;

    await enrichModelPortfolioHoldings(holdings);

    final eligible = _eligible(holdings);
    if (eligible.isEmpty) return PortfolioAnalyticsSnapshot.empty;

    final allocatedSum = eligible.fold<double>(0, (s, h) => s + h.targetPercent);
    final usesEqualWeightPreview = allocatedSum <= 0;
    final weights = _normalizedWeights(eligible);
    final benchmarkSymbol = _benchmarkSymbol(benchmarkLabel);

    final now = DateTime.now();
    final fromYear = now.subtract(const Duration(days: 365));

    final holdingData = await _loadHoldingData(eligible);
    final allCloses = await Future.wait(
      eligible.map((h) => _closes(h.ticker.trim().toUpperCase(), fromYear, now)),
    );

    final quotes = await Future.wait(
      eligible.map((h) => _fetchQuote(h.ticker.trim().toUpperCase())),
    );

    final portfolioReturns = _portfolioReturns(allCloses, weights);
    final recentCloses = allCloses
        .map((s) => s.length > 30 ? s.sublist(s.length - 30) : s)
        .toList();
    final spark = _buildWeightedSparkline(recentCloses, weights);

    double? benchMonth;
    if (benchmarkSymbol.isNotEmpty) {
      try {
        final benchCloses = await _closes(
          benchmarkSymbol,
          now.subtract(const Duration(days: 30)),
          now,
        );
        benchMonth = _returnOverCalendar(benchCloses, const Duration(days: 30));
      } catch (_) {}
    }

    final holdingAnalytics = <HoldingAnalytics>[];
    final contributions = <ContributionRow>[];
    for (var i = 0; i < eligible.length; i++) {
      final h = eligible[i];
      final w = weights[i];
      final dayChange =
          quotes[i]?.percentChange ?? _dayChangeFromCloses(allCloses[i]);
      final contribution = dayChange != null ? dayChange * w : null;
      final data = holdingData[i];
      final effectiveWeight = w * 100;

      final row = HoldingAnalytics(
        ticker: h.ticker.trim().toUpperCase(),
        name: h.company ?? h.ticker,
        weight: effectiveWeight,
        dayChange: dayChange,
        contribution: contribution,
        logo: h.tickerModel?.logo,
        marketCapMillions: data.marketCapMillions,
        pe: data.pe,
        volume: data.volume,
      );
      holdingAnalytics.add(row);
      if (contribution != null) {
        contributions.add(
          ContributionRow(
            ticker: row.ticker,
            name: row.name,
            contribution: contribution,
            weight: effectiveWeight,
          ),
        );
      }
    }

    contributions.sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));
    holdingAnalytics.sort((a, b) => b.weight.compareTo(a.weight));

    HoldingAnalytics? best;
    HoldingAnalytics? worst;
    for (final h in holdingAnalytics) {
      if (h.dayChange == null) continue;
      if (best == null || h.dayChange! > best.dayChange!) best = h;
      if (worst == null || h.dayChange! < worst.dayChange!) worst = h;
    }

    final todayFromQuotes = _weightedToday(quotes, weights, allCloses);

    return PortfolioAnalyticsSnapshot(
      performance: PortfolioPerformanceMetrics(
        day1: todayFromQuotes ?? portfolioReturns.week1,
        week1: portfolioReturns.week1,
        month1: portfolioReturns.month1,
        month3: portfolioReturns.month3,
        month6: portfolioReturns.month6,
        year1: portfolioReturns.year1,
        sparkline: spark.values,
        sparklineDates: spark.dates,
        bestHolding: best,
        worstHolding: worst,
      ),
      countries: _countryAllocations(eligible, holdingData, weights),
      sectors: _sectorAllocations(eligible, holdingData, holdingAnalytics, weights),
      topHoldings: holdingAnalytics.take(8).toList(),
      contributions: contributions.take(8).toList(),
      concentration: _concentration(eligible, weights),
      valuation: _valuation(holdingData, weights),
      marketCapMix: _marketCapMix(holdingData, eligible, weights),
      assetClasses: _assetClasses(holdings, usesEqualWeightPreview),
      correlation: _correlationMatrix(eligible, allCloses),
      benchmark: BenchmarkComparison(
        benchmarkLabel: benchmarkLabel,
        benchmarkSymbol: benchmarkSymbol,
        portfolioMonth: portfolioReturns.month1,
        benchmarkMonth: benchMonth,
      ),
      liquidity: _liquidity(holdingData),
      usesEqualWeightPreview: usesEqualWeightPreview,
    );
  }

  double? _dayChangeFromCloses(List<PriceDataPoint> closes) {
    if (closes.length < 2) return null;
    final prev = closes[closes.length - 2].value;
    final last = closes.last.value;
    if (prev <= 0) return null;
    return (last - prev) / prev * 100.0;
  }

  double? _weightedToday(
    List<QuoteModel?> quotes,
    List<double> weights,
    List<List<PriceDataPoint>> closes,
  ) {
    var sum = 0.0;
    var wSum = 0.0;
    for (var i = 0; i < weights.length; i++) {
      final ch = quotes[i]?.percentChange ?? _dayChangeFromCloses(closes[i]);
      if (ch == null) continue;
      sum += ch * weights[i];
      wSum += weights[i];
    }
    return wSum > 0 ? sum : null;
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
    if (holdings.isEmpty) return const [];
    final raw = holdings.map((h) => h.targetPercent.clamp(0, 100)).toList();
    final sum = raw.fold<double>(0, (s, w) => s + w);
    if (sum <= 0) {
      return List<double>.filled(holdings.length, 1 / holdings.length);
    }
    return raw.map((w) => w / sum).toList();
  }

  String _benchmarkSymbol(String label) {
    switch (label) {
      case 'NASDAQ 100':
        return 'QQQ';
      case 'NIFTY 50':
      case 'NIFTY 500':
        return 'INDA';
      case 'Custom':
        return '';
      default:
        return 'SPY';
    }
  }

  Future<List<_HoldingData>> _loadHoldingData(
    List<ModelPortfolioHolding> holdings,
  ) async {
    await CompanyEnrichmentCache.ensureForHoldings(holdings);

    return Future.wait(
      holdings.map((h) async {
        final ticker = h.ticker.trim().toUpperCase();
        StockProfileModel? profile;
        BasicFinancialsModel? fin;
        try {
          profile = await _profiles.fetchProfile2(ticker);
        } catch (_) {}
        try {
          fin = await _financials.fetchAll(ticker);
        } catch (_) {}

        final enrichment = CompanyEnrichmentCache.getCached(ticker);

        var marketCapMillions = profile?.marketCapitalization?.toDouble();
        if (marketCapMillions == null || marketCapMillions <= 0) {
          if (h.marketCap != null && h.marketCap! > 0) {
            marketCapMillions = h.assetType == ModelAssetType.etf
                ? h.marketCap! / 1e6
                : h.marketCap;
          } else if (enrichment?.marketCap != null) {
            marketCapMillions = enrichment!.marketCap!.toDouble();
          }
        }

        final country = _resolveCountry(h, profile?.country?.trim());
        final sector = _resolveSector(h, profile);

        return _HoldingData(
          ticker: ticker,
          marketCapMillions: marketCapMillions,
          country: country,
          sector: sector,
          pe: _metric(fin, const ['peTTM', 'peBasicExclExtraTTM']),
          pb: _metric(fin, const ['pbAnnual', 'pbQuarterly']),
          dividendYield: _metric(
            fin,
            const ['dividendYieldIndicatedAnnual', 'currentDividendYieldTTM'],
          ),
          volume: _metric(
            fin,
            const ['10DayAverageTradingVolume', '3MonthAverageTradingVolume'],
          ),
        );
      }),
    );
  }

  String? _resolveCountry(ModelPortfolioHolding h, String? profileCountry) {
    if (profileCountry != null && profileCountry.isNotEmpty) {
      return profileCountry.toUpperCase();
    }
    return _inferCountry(h);
  }

  String? _resolveSector(ModelPortfolioHolding h, StockProfileModel? profile) {
    if (h.sector != null && h.sector!.trim().isNotEmpty) {
      return h.sector!.trim();
    }
    final industry = profile?.finnhubIndustry?.trim();
    if (industry != null && industry.isNotEmpty) return industry;
    return null;
  }

  String? _inferCountry(ModelPortfolioHolding h) {
    final ex = (h.exchange ?? '').toUpperCase();
    if (ex.contains('NSE') || ex.contains('BSE') || ex.contains('NSI')) {
      return 'IN';
    }
    if (ex.contains('LSE') || ex.contains('LON')) return 'GB';
    if (ex.contains('TSE') || ex.contains('JPX') || ex.contains('TYO')) {
      return 'JP';
    }
    if (ModelPortfolioHolding.isSearchableAsset(h.assetType)) return 'US';
    return null;
  }

  double? _metric(BasicFinancialsModel? fin, List<String> keys) {
    if (fin == null) return null;
    for (final k in keys) {
      final v = fin.metricNum(k);
      if (v != null && v > 0) return v.toDouble();
    }
    return null;
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

  Future<QuoteModel?> _fetchQuote(String symbol) async {
    try {
      return await _quotes.fetchQuote(symbol);
    } catch (_) {
      return null;
    }
  }

  ({
    double? week1,
    double? month1,
    double? month3,
    double? month6,
    double? year1,
  }) _portfolioReturns(
    List<List<PriceDataPoint>> series,
    List<double> weights,
  ) {
    double? weighted(List<double?> vals) {
      var sum = 0.0;
      var wSum = 0.0;
      for (var i = 0; i < vals.length; i++) {
        final v = vals[i];
        if (v == null) continue;
        sum += v * weights[i];
        wSum += weights[i];
      }
      return wSum > 0 ? sum : null;
    }

    return (
      week1: weighted(
        series.map((s) => _returnOverCalendar(s, const Duration(days: 7))).toList(),
      ),
      month1: weighted(
        series.map((s) => _returnOverCalendar(s, const Duration(days: 30))).toList(),
      ),
      month3: weighted(
        series.map((s) => _returnOverCalendar(s, const Duration(days: 90))).toList(),
      ),
      month6: weighted(
        series.map((s) => _returnOverCalendar(s, const Duration(days: 180))).toList(),
      ),
      year1: weighted(
        series.map((s) => _returnOverCalendar(s, const Duration(days: 365))).toList(),
      ),
    );
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
    if (series.isEmpty) return (values: const [], dates: const []);

    final dayBuckets = <String, double>{};
    final dayWeight = <String, double>{};

    for (var i = 0; i < series.length; i++) {
      final closes = series[i];
      if (closes.length < 2) continue;
      final start = closes.first.value;
      if (start <= 0) continue;
      final w = i < weights.length ? weights[i] : 0;
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

    return _downsampleSeries(index, dates, 72);
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

  List<CountryAllocation> _countryAllocations(
    List<ModelPortfolioHolding> eligible,
    List<_HoldingData> data,
    List<double> weights,
  ) {
    final countryByTicker = {for (final d in data) d.ticker: d.country};
    final map = <String, ({double pct, int count})>{};

    for (var i = 0; i < eligible.length; i++) {
      final pct = weights[i] * 100;
      if (pct <= 0) continue;
      final h = eligible[i];
      String code = 'OTHER';
      if (ModelPortfolioHolding.isSearchableAsset(h.assetType)) {
        final c = countryByTicker[h.ticker.trim().toUpperCase()];
        if (c != null && c.isNotEmpty) code = c.toUpperCase();
      } else {
        code = _assetLabel(h.assetType).toUpperCase();
      }
      final prev = map[code];
      map[code] = (
        pct: (prev?.pct ?? 0) + pct,
        count: (prev?.count ?? 0) + 1,
      );
    }

    return map.entries
        .map(
          (e) => CountryAllocation(
            code: e.key,
            name: _countryName(e.key),
            percent: e.value.pct,
            mapId: _countryMapId(e.key),
            holdingsCount: e.value.count,
          ),
        )
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  List<SectorAllocation> _sectorAllocations(
    List<ModelPortfolioHolding> eligible,
    List<_HoldingData> data,
    List<HoldingAnalytics> analytics,
    List<double> weights,
  ) {
    final sectorByTicker = {for (final d in data) d.ticker: d.sector};
    final changeByTicker = {for (final a in analytics) a.ticker: a.dayChange};
    final map = <String, ({double pct, double changeSum, int changeN})>{};

    for (var i = 0; i < eligible.length; i++) {
      final pct = weights[i] * 100;
      if (pct <= 0) continue;
      final h = eligible[i];
      final ticker = h.ticker.trim().toUpperCase();
      final sector = (sectorByTicker[ticker]?.trim().isNotEmpty == true)
          ? sectorByTicker[ticker]!.trim()
          : (h.sector?.trim().isNotEmpty == true)
              ? h.sector!.trim()
              : _assetLabel(h.assetType);
      final ch = changeByTicker[ticker];
      final prev = map[sector];
      map[sector] = (
        pct: (prev?.pct ?? 0) + pct,
        changeSum: (prev?.changeSum ?? 0) + (ch ?? 0),
        changeN: (prev?.changeN ?? 0) + (ch != null ? 1 : 0),
      );
    }

    return map.entries
        .map(
          (e) => SectorAllocation(
            name: e.key,
            percent: e.value.pct,
            dayChange: e.value.changeN > 0
                ? e.value.changeSum / e.value.changeN
                : null,
          ),
        )
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  ConcentrationMetrics _concentration(
    List<ModelPortfolioHolding> eligible,
    List<double> weights,
  ) {
    if (eligible.isEmpty) {
      return const ConcentrationMetrics(holdingsCount: 0);
    }

    final indexed = List.generate(
      eligible.length,
      (i) => (weight: weights[i], index: i),
    )..sort((a, b) => b.weight.compareTo(a.weight));

    double sumTop(int n) => indexed
        .take(n)
        .fold<double>(0, (s, e) => s + e.weight * 100);

    final hhi = weights.fold<double>(0, (s, w) => s + w * w) * 10000;

    String label;
    if (hhi < 1500) {
      label = 'Low concentration';
    } else if (hhi < 2500) {
      label = 'Moderate concentration';
    } else {
      label = 'High concentration';
    }

    return ConcentrationMetrics(
      top1: sumTop(1),
      top3: sumTop(3),
      top5: sumTop(5),
      hhi: hhi,
      holdingsCount: eligible.length,
      label: label,
    );
  }

  ValuationMetrics _valuation(List<_HoldingData> data, List<double> weights) {
    double? wAvg(List<double?> vals) {
      var sum = 0.0;
      var wSum = 0.0;
      for (var i = 0; i < vals.length; i++) {
        final v = vals[i];
        if (v == null || v <= 0) continue;
        sum += v * weights[i];
        wSum += weights[i];
      }
      return wSum > 0 ? sum / wSum : null;
    }

    return ValuationMetrics(
      pe: wAvg(data.map((d) => d.pe).toList()),
      pb: wAvg(data.map((d) => d.pb).toList()),
      dividendYield: wAvg(data.map((d) => d.dividendYield).toList()),
      avgMarketCapMillions: wAvg(data.map((d) => d.marketCapMillions).toList()),
      avgVolume: wAvg(data.map((d) => d.volume).toList()),
    );
  }

  List<MarketCapBucket> _marketCapMix(
    List<_HoldingData> data,
    List<ModelPortfolioHolding> holdings,
    List<double> weights,
  ) {
    final buckets = <String, double>{
      'Mega Cap': 0,
      'Large Cap': 0,
      'Mid Cap': 0,
      'Small Cap': 0,
      'Other': 0,
    };

    for (var i = 0; i < holdings.length; i++) {
      final w = weights[i] * 100;
      if (w <= 0) continue;
      final bucket = _capBucket(data[i].marketCapMillions);
      buckets[bucket] = (buckets[bucket] ?? 0) + w;
    }

    return buckets.entries
        .where((e) => e.value > 0)
        .map((e) => MarketCapBucket(label: e.key, percent: e.value))
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  String _capBucket(double? capMillions) {
    if (capMillions == null || capMillions <= 0) return 'Other';
    final cap = capMillions * 1e6;
    if (cap >= 200e9) return 'Mega Cap';
    if (cap >= 10e9) return 'Large Cap';
    if (cap >= 2e9) return 'Mid Cap';
    return 'Small Cap';
  }

  List<AssetClassSlice> _assetClasses(
    List<ModelPortfolioHolding> holdings,
    bool equalWeightPreview,
  ) {
    if (holdings.isEmpty) return const [];

    final map = <String, double>{};
    if (equalWeightPreview) {
      final share = 100.0 / holdings.length;
      for (final h in holdings) {
        final label = _assetLabel(h.assetType);
        map[label] = (map[label] ?? 0) + share;
      }
    } else {
      for (final h in holdings) {
        if (h.targetPercent <= 0) continue;
        final label = _assetLabel(h.assetType);
        map[label] = (map[label] ?? 0) + h.targetPercent;
      }
    }

    return map.entries
        .map((e) => AssetClassSlice(label: e.key, percent: e.value))
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  CorrelationMatrix? _correlationMatrix(
    List<ModelPortfolioHolding> holdings,
    List<List<PriceDataPoint>> closes,
  ) {
    final n = math.min(_correlationMax, holdings.length);
    if (n < 2) return null;

    final tickers =
        holdings.take(n).map((h) => h.ticker.trim().toUpperCase()).toList();
    final returns = <List<double>>[];

    for (var i = 0; i < n; i++) {
      final series = closes[i];
      if (series.length < 5) return null;
      final rets = <double>[];
      for (var j = 1; j < series.length; j++) {
        final prev = series[j - 1].value;
        final cur = series[j].value;
        if (prev > 0) rets.add((cur - prev) / prev);
      }
      if (rets.length < 4) return null;
      returns.add(rets);
    }

    final minLen = returns.map((r) => r.length).reduce(math.min);
    final aligned = returns.map((r) => r.sublist(r.length - minLen)).toList();

    final matrix = List.generate(n, (_) => List.filled(n, 0.0));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        matrix[i][j] = i == j ? 1.0 : _pearson(aligned[i], aligned[j]);
      }
    }

    return CorrelationMatrix(tickers: tickers, values: matrix);
  }

  double _pearson(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    final n = a.length;
    final meanA = a.reduce((x, y) => x + y) / n;
    final meanB = b.reduce((x, y) => x + y) / n;
    var num = 0.0;
    var denA = 0.0;
    var denB = 0.0;
    for (var i = 0; i < n; i++) {
      final da = a[i] - meanA;
      final db = b[i] - meanB;
      num += da * db;
      denA += da * da;
      denB += db * db;
    }
    if (denA <= 0 || denB <= 0) return 0;
    return (num / math.sqrt(denA * denB)).clamp(-1.0, 1.0);
  }

  LiquidityMetrics _liquidity(List<_HoldingData> data) {
    var high = 0;
    var low = 0;
    double? volSum;
    var volN = 0;

    for (final d in data) {
      final v = d.volume;
      if (v == null) continue;
      volSum = (volSum ?? 0) + v;
      volN++;
      if (v >= 1e6) {
        high++;
      } else if (v < 1e5) {
        low++;
      }
    }

    return LiquidityMetrics(
      avgVolume: volN > 0 ? volSum! / volN : null,
      highLiquidityCount: high,
      lowLiquidityCount: low,
    );
  }

  String _assetLabel(ModelAssetType type) {
    switch (type) {
      case ModelAssetType.stock:
        return 'Equity';
      case ModelAssetType.etf:
        return 'ETF';
      case ModelAssetType.gold:
        return 'Gold';
      case ModelAssetType.bond:
        return 'Bonds';
      case ModelAssetType.reit:
        return 'Real Estate';
      case ModelAssetType.cash:
        return 'Cash';
      case ModelAssetType.commodity:
        return 'Commodity';
      case ModelAssetType.other:
        return 'Other';
    }
  }

  String _countryName(String code) {
    const names = {
      'US': 'United States',
      'IN': 'India',
      'GB': 'United Kingdom',
      'UK': 'United Kingdom',
      'JP': 'Japan',
      'CN': 'China',
      'DE': 'Germany',
      'FR': 'France',
      'CA': 'Canada',
      'AU': 'Australia',
      'KR': 'South Korea',
      'TW': 'Taiwan',
      'CH': 'Switzerland',
      'NL': 'Netherlands',
      'SE': 'Sweden',
      'BR': 'Brazil',
      'MX': 'Mexico',
      'IE': 'Ireland',
      'OTHER': 'Other',
    };
    return names[code.toUpperCase()] ?? code;
  }

  String? _countryMapId(String code) {
    const ids = {
      'US': '840',
      'IN': '356',
      'GB': '826',
      'UK': '826',
      'JP': '392',
      'CN': '156',
      'DE': '276',
      'FR': '250',
      'CA': '124',
      'AU': '036',
      'KR': '410',
      'TW': '158',
      'CH': '756',
      'NL': '528',
      'SE': '752',
      'BR': '076',
      'MX': '484',
      'IE': '372',
    };
    return ids[code.toUpperCase()];
  }
}

class _HoldingData {
  const _HoldingData({
    required this.ticker,
    this.marketCapMillions,
    this.country,
    this.sector,
    this.pe,
    this.pb,
    this.dividendYield,
    this.volume,
  });

  final String ticker;
  final double? marketCapMillions;
  final String? country;
  final String? sector;
  final double? pe;
  final double? pb;
  final double? dividendYield;
  final double? volume;
}
