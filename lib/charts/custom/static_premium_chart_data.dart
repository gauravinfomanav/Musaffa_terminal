import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';

/// Curated static finance datasets for the premium Custom Charts showcase.
class StaticPremiumChartData {
  StaticPremiumChartData._();

  static const String symbol = 'AAPL';
  static const String company = 'Apple Inc.';
  static const double currentPrice = 213.45;
  static const double changeAbs = 5.89;
  static const double changePct = 2.84;

  /// ~90 trading days — realistic uptrend with pullbacks.
  static List<OhlcCandlePoint> get priceHistory {
    final DateTime start = DateTime.now().subtract(const Duration(days: 120));
    final List<OhlcCandlePoint> points = <OhlcCandlePoint>[];
    double close = 178.40;
    for (int i = 0; i < 90; i++) {
      final DateTime date = start.add(Duration(days: i));
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }
      final double drift = 0.004 + (i % 17 == 0 ? -0.025 : 0);
      final double open = close;
      close = (close * (1 + drift + (i % 7 - 3) * 0.0015)).clamp(165.0, 225.0);
      final double high = [open, close].reduce((a, b) => a > b ? a : b) * 1.008;
      final double low = [open, close].reduce((a, b) => a < b ? a : b) * 0.992;
      final double volume = 42000000 + (i % 11) * 2800000.0;
      points.add(
        OhlcCandlePoint(
          date: date,
          open: double.parse(open.toStringAsFixed(2)),
          high: double.parse(high.toStringAsFixed(2)),
          low: double.parse(low.toStringAsFixed(2)),
          close: double.parse(close.toStringAsFixed(2)),
          volume: volume,
        ),
      );
    }
    return points;
  }

  static List<OhlcCandlePoint> get last30Days =>
      priceHistory.length > 30 ? priceHistory.sublist(priceHistory.length - 30) : priceHistory;

  static const Map<String, double> performanceReturns = <String, double>{
    '1D': 2.84,
    '1W': 4.12,
    '1M': 8.65,
    '3M': 14.20,
    '6M': 22.45,
    'YTD': 18.90,
    '1Y': 31.50,
    '3Y': 68.20,
    '5Y': 142.80,
  };

  static const List<StaticBarItem> sectorRanking = <StaticBarItem>[
    StaticBarItem('Technology', 42.8),
    StaticBarItem('Healthcare', 18.4),
    StaticBarItem('Financials', 12.6),
    StaticBarItem('Consumer', 9.2),
    StaticBarItem('Energy', 6.1),
    StaticBarItem('Industrials', 5.4),
    StaticBarItem('Other', 5.5),
  ];

  static const List<StaticAllocationSlice> portfolioAllocation = <StaticAllocationSlice>[
    StaticAllocationSlice('Equities', 58.2),
    StaticAllocationSlice('Fixed Income', 22.4),
    StaticAllocationSlice('Cash', 8.6),
    StaticAllocationSlice('Alternatives', 6.8),
    StaticAllocationSlice('Commodities', 4.0),
  ];

  static List<StaticLinePoint> get benchmarkComparison {
    final List<OhlcCandlePoint> hist = last30Days;
    if (hist.isEmpty) return <StaticLinePoint>[];
    final double baseStock = hist.first.close;
    final double baseBench = 100;
    return hist.asMap().entries.map((entry) {
      final int i = entry.key;
      final OhlcCandlePoint c = entry.value;
      final double stockNorm = (c.close / baseStock) * 100;
      final double benchNorm = baseBench + i * 0.18 + (i % 5) * 0.12;
      return StaticLinePoint(
        date: c.date,
        stock: double.parse(stockNorm.toStringAsFixed(2)),
        benchmark: double.parse(benchNorm.toStringAsFixed(2)),
      );
    }).toList();
  }

  static const List<StaticQuarterRevenue> quarterlyRevenue = <StaticQuarterRevenue>[
    StaticQuarterRevenue('Q1 \'24', 90.8, 72.4),
    StaticQuarterRevenue('Q2 \'24', 94.2, 76.1),
    StaticQuarterRevenue('Q3 \'24', 97.5, 78.9),
    StaticQuarterRevenue('Q4 \'24', 102.1, 82.3),
  ];

  static const List<StaticRiskPoint> riskReturnPeers = <StaticRiskPoint>[
    StaticRiskPoint('AAPL', 1.12, 28.4, true),
    StaticRiskPoint('MSFT', 0.98, 32.1, false),
    StaticRiskPoint('GOOGL', 1.05, 24.8, false),
    StaticRiskPoint('AMZN', 1.28, 35.6, false),
    StaticRiskPoint('NVDA', 1.65, 48.2, false),
    StaticRiskPoint('META', 1.22, 31.0, false),
  ];

  static const List<StaticEarningsSurprisePoint> earningsSurpriseTrend =
      <StaticEarningsSurprisePoint>[
    StaticEarningsSurprisePoint(
      label: 'Q2 FY26',
      dateLabel: '',
      estimate: 1.48,
      actual: 1.46,
      beat: false,
      deltaLabel: '-\$0.02',
    ),
    StaticEarningsSurprisePoint(
      label: 'Q3 FY26',
      dateLabel: '',
      estimate: 1.52,
      actual: 1.58,
      beat: true,
      deltaLabel: '+\$0.06',
    ),
    StaticEarningsSurprisePoint(
      label: 'Q4 FY26',
      dateLabel: '',
      estimate: 1.55,
      actual: 1.68,
      beat: true,
      deltaLabel: '+\$0.13',
    ),
    StaticEarningsSurprisePoint(
      label: 'Q1 FY27',
      dateLabel: '',
      estimate: 1.60,
      actual: 1.56,
      beat: false,
      deltaLabel: '-\$0.04',
    ),
    StaticEarningsSurprisePoint(
      label: 'Q2 FY27',
      dateLabel: 'Oct 23',
      estimate: 1.64,
      actual: null,
      beat: null,
      deltaLabel: 'Est. \$1.64',
    ),
  ];

  static const StaticPriceTargetRange analystPriceTarget = StaticPriceTargetRange(
    low: 9.00,
    average: 12.50,
    current: 10.80,
    high: 14.10,
  );

  static const List<StaticRecommendationBar> analystRecommendationBars =
      <StaticRecommendationBar>[
    StaticRecommendationBar(
      month: 'May',
      strongBuy: 3,
      buy: 0,
      hold: 8,
      underperform: 1,
      sell: 2,
    ),
    StaticRecommendationBar(
      month: 'Jun',
      strongBuy: 3,
      buy: 0,
      hold: 9,
      underperform: 1,
      sell: 1,
    ),
    StaticRecommendationBar(
      month: 'Jul',
      strongBuy: 2,
      buy: 1,
      hold: 11,
      underperform: 0,
      sell: 0,
    ),
    StaticRecommendationBar(
      month: 'Aug',
      strongBuy: 2,
      buy: 1,
      hold: 11,
      underperform: 0,
      sell: 0,
    ),
  ];

  static final List<StaticDividendPoint> dividendHistory = <StaticDividendPoint>[
    StaticDividendPoint(DateTime(2023, 2, 10), 0.23),
    StaticDividendPoint(DateTime(2023, 5, 12), 0.24),
    StaticDividendPoint(DateTime(2023, 8, 11), 0.24),
    StaticDividendPoint(DateTime(2023, 11, 10), 0.24),
    StaticDividendPoint(DateTime(2024, 2, 9), 0.24),
    StaticDividendPoint(DateTime(2024, 5, 10), 0.25),
    StaticDividendPoint(DateTime(2024, 8, 12), 0.25),
    StaticDividendPoint(DateTime(2024, 11, 8), 0.25),
  ];

  static const List<StaticAnalystMonth> analystTrend = <StaticAnalystMonth>[
    StaticAnalystMonth('Jan', 18, 22, 8, 2, 0),
    StaticAnalystMonth('Feb', 19, 21, 9, 2, 0),
    StaticAnalystMonth('Mar', 20, 20, 10, 2, 0),
    StaticAnalystMonth('Apr', 21, 19, 10, 2, 0),
    StaticAnalystMonth('May', 22, 18, 10, 1, 0),
    StaticAnalystMonth('Jun', 23, 17, 10, 1, 0),
    StaticAnalystMonth('Jul', 24, 16, 9, 1, 0),
    StaticAnalystMonth('Aug', 25, 15, 9, 1, 0),
  ];

  static const List<StaticMarginPoint> marginTrend = <StaticMarginPoint>[
    StaticMarginPoint('Q1 \'23', 43.8, 29.2, 25.3),
    StaticMarginPoint('Q2 \'23', 44.5, 29.8, 25.8),
    StaticMarginPoint('Q3 \'23', 45.0, 30.1, 26.0),
    StaticMarginPoint('Q4 \'23', 45.6, 30.5, 26.4),
    StaticMarginPoint('Q1 \'24', 46.1, 31.0, 26.8),
    StaticMarginPoint('Q2 \'24', 46.5, 31.4, 27.1),
  ];

  static const List<StaticCashFlowYear> cashFlowTrend = <StaticCashFlowYear>[
    StaticCashFlowYear('2020', 80.2, -12.4, -72.8),
    StaticCashFlowYear('2021', 92.0, -14.5, -86.2),
    StaticCashFlowYear('2022', 104.0, -22.1, -89.4),
    StaticCashFlowYear('2023', 110.5, -18.6, -84.2),
    StaticCashFlowYear('2024', 118.2, -20.3, -91.0),
  ];

  static const List<StaticValuationPoint> valuationMultiples = <StaticValuationPoint>[
    StaticValuationPoint('2020', 32.4, 7.8),
    StaticValuationPoint('2021', 28.6, 7.2),
    StaticValuationPoint('2022', 24.2, 6.5),
    StaticValuationPoint('2023', 27.8, 6.9),
    StaticValuationPoint('2024', 29.5, 7.4),
  ];

  static const List<StaticEpsSurprise> epsSurprises = <StaticEpsSurprise>[
    StaticEpsSurprise('Q1 \'24', 1.48, 1.52),
    StaticEpsSurprise('Q2 \'24', 1.42, 1.46),
    StaticEpsSurprise('Q3 \'24', 1.38, 1.44),
    StaticEpsSurprise('Q4 \'24', 1.55, 1.62),
  ];

  static const StaticRange52Week range52Week = StaticRange52Week(
    low: 164.08,
    high: 220.42,
    current: 213.45,
  );

  static const List<StaticBarItem> geographicRevenue = <StaticBarItem>[
    StaticBarItem('Americas', 42.5),
    StaticBarItem('Europe', 24.8),
    StaticBarItem('Greater China', 18.6),
    StaticBarItem('Japan', 7.4),
    StaticBarItem('Rest of Asia', 6.7),
  ];

  static const List<StaticCorrelationCell> correlationMatrix = <StaticCorrelationCell>[
    StaticCorrelationCell('AAPL', 'SPY', 0.82),
    StaticCorrelationCell('AAPL', 'QQQ', 0.91),
    StaticCorrelationCell('AAPL', 'XLK', 0.88),
    StaticCorrelationCell('AAPL', 'GLD', -0.12),
    StaticCorrelationCell('AAPL', 'TLT', -0.28),
    StaticCorrelationCell('SPY', 'QQQ', 0.96),
    StaticCorrelationCell('SPY', 'XLK', 0.94),
    StaticCorrelationCell('SPY', 'GLD', -0.08),
    StaticCorrelationCell('QQQ', 'XLK', 0.97),
  ];

  /// Monthly close + volume sampled from [priceHistory] — real OHLC values.
  static List<StaticVolumePricePoint> get volumePriceTrend {
    final List<OhlcCandlePoint> history = priceHistory;
    if (history.isEmpty) return <StaticVolumePricePoint>[];

    final Map<String, OhlcCandlePoint> lastByMonth = <String, OhlcCandlePoint>{};
    for (final OhlcCandlePoint point in history) {
      final String key = '${point.date.year}-${point.date.month.toString().padLeft(2, '0')}';
      lastByMonth[key] = point;
    }

    final List<OhlcCandlePoint> monthly = lastByMonth.values.toList()
      ..sort((OhlcCandlePoint a, OhlcCandlePoint b) => a.date.compareTo(b.date));

    return monthly.map((OhlcCandlePoint point) {
      return StaticVolumePricePoint(
        date: point.date,
        volumeK: point.volume / 1000,
        price: point.close,
      );
    }).toList();
  }

  static const List<StaticButterflyItem> butterflySales = <StaticButterflyItem>[
    StaticButterflyItem('SSD Drive', 140, 125),
    StaticButterflyItem('Docking Hub', 82, 91),
    StaticButterflyItem('Web Camera', 95, 78),
    StaticButterflyItem('Laptop Stand', 72, 88),
    StaticButterflyItem('Desk Lamp', 60, 67),
    StaticButterflyItem('Earbuds', 56, 63),
    StaticButterflyItem('Bluetooth Pen', 48, 54),
    StaticButterflyItem('Power Cable', 38, 44),
    StaticButterflyItem('Stylus', 22, 28),
    StaticButterflyItem('Screen Guard', 18, 21),
  ];

  static const List<StaticSunburstNode> sunburstNodes = <StaticSunburstNode>[
    StaticSunburstNode(id: 'equities', label: 'Equities', value: 180, colorGroup: 0),
    StaticSunburstNode(id: 'derivatives', label: 'Derivatives', value: 145, colorGroup: 1),
    StaticSunburstNode(id: 'fixed_income', label: 'Fixed Income', value: 160, colorGroup: 2),
    StaticSunburstNode(id: 'commodities', label: 'Commodities', value: 115, colorGroup: 3),
    StaticSunburstNode(id: 'eq_large', parentId: 'equities', label: 'Large Cap', value: 82, colorGroup: 0),
    StaticSunburstNode(id: 'eq_mid', parentId: 'equities', label: 'Mid Cap', value: 58, colorGroup: 0),
    StaticSunburstNode(id: 'eq_small', parentId: 'equities', label: 'Small Cap', value: 40, colorGroup: 0),
    StaticSunburstNode(id: 'der_options', parentId: 'derivatives', label: 'Options', value: 68, colorGroup: 1),
    StaticSunburstNode(id: 'der_futures', parentId: 'derivatives', label: 'Futures', value: 45, colorGroup: 1),
    StaticSunburstNode(id: 'der_swaps', parentId: 'derivatives', label: 'Swaps', value: 32, colorGroup: 1),
    StaticSunburstNode(id: 'fi_govt', parentId: 'fixed_income', label: 'Government', value: 75, colorGroup: 2),
    StaticSunburstNode(id: 'fi_corp', parentId: 'fixed_income', label: 'Corporate', value: 52, colorGroup: 2),
    StaticSunburstNode(id: 'fi_muni', parentId: 'fixed_income', label: 'Municipal', value: 33, colorGroup: 2),
    StaticSunburstNode(id: 'cm_gold', parentId: 'commodities', label: 'Gold', value: 48, colorGroup: 3),
    StaticSunburstNode(id: 'cm_oil', parentId: 'commodities', label: 'Crude Oil', value: 38, colorGroup: 3),
    StaticSunburstNode(id: 'cm_agri', parentId: 'commodities', label: 'Agriculture', value: 29, colorGroup: 3),
    StaticSunburstNode(id: 'eq_tech', parentId: 'eq_large', label: 'Technology', value: 82, colorGroup: 0),
    StaticSunburstNode(id: 'der_idx', parentId: 'der_options', label: 'Index Options', value: 68, colorGroup: 1),
    StaticSunburstNode(id: 'fi_tbill', parentId: 'fi_govt', label: 'T-Bills', value: 75, colorGroup: 2),
    StaticSunburstNode(id: 'cm_spot', parentId: 'cm_gold', label: 'Spot Gold', value: 48, colorGroup: 3),
  ];

  static double get sunburstTotal =>
      sunburstNodes.where((StaticSunburstNode n) => n.parentId == null).fold(0.0, (double s, StaticSunburstNode n) => s + n.value);
}

class StaticBarItem {
  const StaticBarItem(this.label, this.value);
  final String label;
  final double value;
}

class StaticAllocationSlice {
  const StaticAllocationSlice(this.label, this.percent);
  final String label;
  final double percent;
}

class StaticLinePoint {
  const StaticLinePoint({
    required this.date,
    required this.stock,
    required this.benchmark,
  });
  final DateTime date;
  final double stock;
  final double benchmark;
}

class StaticQuarterRevenue {
  const StaticQuarterRevenue(this.quarter, this.revenue, this.profit);
  final String quarter;
  final double revenue;
  final double profit;
}

class StaticRiskPoint {
  const StaticRiskPoint(this.ticker, this.beta, this.returnPct, this.isCurrent);
  final String ticker;
  final double beta;
  final double returnPct;
  final bool isCurrent;
}

class StaticEarningsSurprisePoint {
  const StaticEarningsSurprisePoint({
    required this.label,
    required this.dateLabel,
    required this.estimate,
    required this.actual,
    required this.beat,
    required this.deltaLabel,
  });

  final String label;
  final String dateLabel;
  final double estimate;
  final double? actual;
  final bool? beat;
  final String deltaLabel;
}

class StaticPriceTargetRange {
  const StaticPriceTargetRange({
    required this.low,
    required this.average,
    required this.current,
    required this.high,
  });

  final double low;
  final double average;
  final double current;
  final double high;

  double get averagePosition => ((average - low) / (high - low)).clamp(0.0, 1.0);
  double get currentPosition => ((current - low) / (high - low)).clamp(0.0, 1.0);
}

class StaticRecommendationBar {
  const StaticRecommendationBar({
    required this.month,
    required this.strongBuy,
    required this.buy,
    required this.hold,
    required this.underperform,
    required this.sell,
  });

  final String month;
  final int strongBuy;
  final int buy;
  final int hold;
  final int underperform;
  final int sell;

  int get total => strongBuy + buy + hold + underperform + sell;
}

class StaticDividendPoint {
  const StaticDividendPoint(this.date, this.amount);
  final DateTime date;
  final double amount;
}

class StaticAnalystMonth {
  const StaticAnalystMonth(
    this.month,
    this.strongBuy,
    this.buy,
    this.hold,
    this.sell,
    this.strongSell,
  );
  final String month;
  final int strongBuy;
  final int buy;
  final int hold;
  final int sell;
  final int strongSell;
}

class StaticMarginPoint {
  const StaticMarginPoint(this.period, this.gross, this.operating, this.net);
  final String period;
  final double gross;
  final double operating;
  final double net;
}

class StaticCashFlowYear {
  const StaticCashFlowYear(this.year, this.operating, this.investing, this.financing);
  final String year;
  final double operating;
  final double investing;
  final double financing;
}

class StaticValuationPoint {
  const StaticValuationPoint(this.year, this.pe, this.evRevenue);
  final String year;
  final double pe;
  final double evRevenue;
}

class StaticEpsSurprise {
  const StaticEpsSurprise(this.quarter, this.estimate, this.actual);
  final String quarter;
  final double estimate;
  final double actual;
}

class StaticRange52Week {
  const StaticRange52Week({
    required this.low,
    required this.high,
    required this.current,
  });
  final double low;
  final double high;
  final double current;

  double get position => ((current - low) / (high - low)).clamp(0.0, 1.0);
}

class StaticCorrelationCell {
  const StaticCorrelationCell(this.assetA, this.assetB, this.value);
  final String assetA;
  final String assetB;
  final double value;
}

class StaticVolumePricePoint {
  const StaticVolumePricePoint({
    required this.date,
    required this.volumeK,
    required this.price,
  });

  final DateTime date;
  final double volumeK;
  final double price;
}

class StaticButterflyItem {
  const StaticButterflyItem(this.category, this.online, this.inStore);

  final String category;
  final double online;
  final double inStore;
}

class StaticSunburstNode {
  const StaticSunburstNode({
    required this.id,
    required this.label,
    required this.value,
    this.parentId,
    this.colorGroup = 0,
  });

  final String id;
  final String? parentId;
  final String label;
  final double value;
  final int colorGroup;
}
