class PortfolioHoldingMarketData {
  const PortfolioHoldingMarketData({
    required this.ticker,
    this.marketCapMillions,
    this.avgDailyVolume,
    this.industry,
    this.peTTM,
    this.dividendYield,
    this.country,
  });

  final String ticker;
  /// Finnhub profile market cap — millions USD.
  final double? marketCapMillions;
  final double? avgDailyVolume;
  final String? industry;
  final double? peTTM;
  final double? dividendYield;
  final String? country;
}

class PortfolioAllocationInsights {
  const PortfolioAllocationInsights({
    required this.holdingData,
    this.weightedAvgMarketCapMillions,
    this.weightedAvgDailyVolume,
    this.weightedAvgPe,
    this.weightedAvgDividendYield,
    this.finnhubLoadedCount = 0,
    this.finnhubEligibleCount = 0,
  });

  final List<PortfolioHoldingMarketData> holdingData;
  final double? weightedAvgMarketCapMillions;
  final double? weightedAvgDailyVolume;
  final double? weightedAvgPe;
  final double? weightedAvgDividendYield;
  final int finnhubLoadedCount;
  final int finnhubEligibleCount;

  static const empty = PortfolioAllocationInsights(holdingData: []);
}
