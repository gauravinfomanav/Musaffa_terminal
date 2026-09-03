class PortfolioAnalyticsSnapshot {
  const PortfolioAnalyticsSnapshot({
    this.performance = const PortfolioPerformanceMetrics(),
    this.countries = const [],
    this.sectors = const [],
    this.topHoldings = const [],
    this.contributions = const [],
    this.concentration = const ConcentrationMetrics(),
    this.valuation = const ValuationMetrics(),
    this.marketCapMix = const [],
    this.assetClasses = const [],
    this.correlation,
    this.benchmark,
    this.liquidity = const LiquidityMetrics(),
    this.usesEqualWeightPreview = false,
  });

  final PortfolioPerformanceMetrics performance;
  final List<CountryAllocation> countries;
  final List<SectorAllocation> sectors;
  final List<HoldingAnalytics> topHoldings;
  final List<ContributionRow> contributions;
  final ConcentrationMetrics concentration;
  final ValuationMetrics valuation;
  final List<MarketCapBucket> marketCapMix;
  final List<AssetClassSlice> assetClasses;
  final CorrelationMatrix? correlation;
  final BenchmarkComparison? benchmark;
  final LiquidityMetrics liquidity;
  /// True when target % are unset — exposure uses equal-weight preview.
  final bool usesEqualWeightPreview;

  static const empty = PortfolioAnalyticsSnapshot();
}

class PortfolioPerformanceMetrics {
  const PortfolioPerformanceMetrics({
    this.day1,
    this.week1,
    this.month1,
    this.month3,
    this.month6,
    this.year1,
    this.sparkline = const [],
    this.sparklineDates = const [],
    this.bestHolding,
    this.worstHolding,
  });

  final double? day1;
  final double? week1;
  final double? month1;
  final double? month3;
  final double? month6;
  final double? year1;
  final List<double> sparkline;
  final List<DateTime> sparklineDates;
  final HoldingAnalytics? bestHolding;
  final HoldingAnalytics? worstHolding;

  bool get isPositive => (month1 ?? week1 ?? day1 ?? 0) >= 0;
}

class CountryAllocation {
  const CountryAllocation({
    required this.code,
    required this.name,
    required this.percent,
    this.mapId,
    this.holdingsCount = 0,
  });

  final String code;
  final String name;
  final double percent;
  final String? mapId;
  final int holdingsCount;
}

class SectorAllocation {
  const SectorAllocation({
    required this.name,
    required this.percent,
    this.dayChange,
  });

  final String name;
  final double percent;
  final double? dayChange;
}

class HoldingAnalytics {
  const HoldingAnalytics({
    required this.ticker,
    required this.name,
    required this.weight,
    this.dayChange,
    this.contribution,
    this.logo,
    this.marketCapMillions,
    this.pe,
    this.volume,
  });

  final String ticker;
  final String name;
  final double weight;
  final double? dayChange;
  final double? contribution;
  final String? logo;
  final double? marketCapMillions;
  final double? pe;
  final double? volume;
}

class ContributionRow {
  const ContributionRow({
    required this.ticker,
    required this.name,
    required this.contribution,
    required this.weight,
  });

  final String ticker;
  final String name;
  final double contribution;
  final double weight;
}

class ConcentrationMetrics {
  const ConcentrationMetrics({
    this.top1 = 0,
    this.top3 = 0,
    this.top5 = 0,
    this.hhi = 0,
    this.holdingsCount = 0,
    this.label = '—',
  });

  final double top1;
  final double top3;
  final double top5;
  final double hhi;
  final int holdingsCount;
  final String label;
}

class ValuationMetrics {
  const ValuationMetrics({
    this.pe,
    this.pb,
    this.dividendYield,
    this.avgMarketCapMillions,
    this.avgVolume,
  });

  final double? pe;
  final double? pb;
  final double? dividendYield;
  final double? avgMarketCapMillions;
  final double? avgVolume;
}

class MarketCapBucket {
  const MarketCapBucket({required this.label, required this.percent});

  final String label;
  final double percent;
}

class AssetClassSlice {
  const AssetClassSlice({required this.label, required this.percent});

  final String label;
  final double percent;
}

class CorrelationMatrix {
  const CorrelationMatrix({
    required this.tickers,
    required this.values,
  });

  final List<String> tickers;
  final List<List<double>> values;
}

class BenchmarkComparison {
  const BenchmarkComparison({
    required this.benchmarkLabel,
    required this.benchmarkSymbol,
    this.portfolioMonth,
    this.benchmarkMonth,
  });

  final String benchmarkLabel;
  final String benchmarkSymbol;
  final double? portfolioMonth;
  final double? benchmarkMonth;
}

class LiquidityMetrics {
  const LiquidityMetrics({
    this.avgVolume,
    this.highLiquidityCount = 0,
    this.lowLiquidityCount = 0,
  });

  final double? avgVolume;
  final int highLiquidityCount;
  final int lowLiquidityCount;
}
