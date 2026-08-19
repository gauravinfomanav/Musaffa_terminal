import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';

/// Curated static financial datasets for the premium Custom Charts showcase.
class PremiumStaticChartData {
  PremiumStaticChartData._();

  static const String symbol = 'AAPL';
  static const String company = 'Apple Inc.';
  static const double currentPrice = 213.45;
  static const double changeAbs = 5.89;
  static const double changePct = 2.84;

  static final DateTime _anchor = DateTime(2025, 8, 19);

  /// Smooth daily closes — 1 year synthetic but realistic shape.
  static List<OhlcCandlePoint> priceSeries({int days = 252}) {
    final List<OhlcCandlePoint> points = <OhlcCandlePoint>[];
    double price = 178.20;
    for (int i = days; i >= 0; i--) {
      final DateTime date = _anchor.subtract(Duration(days: i));
      final double drift = 0.0018 + (i % 17 - 8) * 0.0004;
      final double open = price;
      price = (price * (1 + drift)).clamp(165.0, 225.0);
      final double high = (price * 1.012).clamp(open, 230.0);
      final double low = (price * 0.988).clamp(160.0, open);
      final double close = price;
      final double volume = 42000000 + (i % 11) * 2800000.0;
      points.add(
        OhlcCandlePoint(
          date: date,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }
    points.last = OhlcCandlePoint(
      date: _anchor,
      open: 209.10,
      high: 214.80,
      low: 208.40,
      close: currentPrice,
      volume: 51200000,
    );
    return points;
  }

  static List<OhlcCandlePoint> intradaySeries() {
    final List<OhlcCandlePoint> points = <OhlcCandlePoint>[];
    double price = 208.72;
    final DateTime start = DateTime(_anchor.year, _anchor.month, _anchor.day, 9, 30);
    for (int i = 0; i < 26; i++) {
      final DateTime date = start.add(Duration(minutes: i * 15));
      final double open = price;
      price += (i % 5 - 2) * 0.42 + 0.18;
      price = price.clamp(207.5, 214.2);
      points.add(
        OhlcCandlePoint(
          date: date,
          open: open,
          high: price + 0.35,
          low: price - 0.28,
          close: price,
          volume: 1800000 + i * 120000.0,
        ),
      );
    }
    points.last = OhlcCandlePoint(
      date: start.add(const Duration(minutes: 25 * 15)),
      open: 211.80,
      high: 214.80,
      low: 211.20,
      close: currentPrice,
      volume: 3200000,
    );
    return points;
  }

  static List<_LinePoint> benchmarkComparison() {
    return <_LinePoint>[
      _LinePoint('Jan', 100, 100),
      _LinePoint('Feb', 102.4, 101.1),
      _LinePoint('Mar', 105.8, 103.6),
      _LinePoint('Apr', 103.2, 104.8),
      _LinePoint('May', 108.6, 106.2),
      _LinePoint('Jun', 112.4, 108.9),
      _LinePoint('Jul', 115.2, 111.4),
      _LinePoint('Aug', 118.8, 113.7),
      _LinePoint('Sep', 116.4, 115.1),
      _LinePoint('Oct', 121.6, 117.8),
      _LinePoint('Nov', 126.2, 120.4),
      _LinePoint('Dec', 132.8, 123.6),
    ];
  }

  static List<_RankPoint> sectorRanking() => <_RankPoint>[
        const _RankPoint('Technology', 18.4),
        const _RankPoint('Communication', 14.2),
        const _RankPoint('Consumer Disc.', 11.8),
        const _RankPoint('Financials', 9.6),
        const _RankPoint('Healthcare', 7.4),
        const _RankPoint('Industrials', 6.1),
        const _RankPoint('Energy', 4.8),
      ];

  static List<_StackPoint> revenueProfit() => <_StackPoint>[
        const _StackPoint('Q1 24', 94.8, 24.2),
        const _StackPoint('Q2 24', 85.8, 21.4),
        const _StackPoint('Q3 24', 89.5, 22.9),
        const _StackPoint('Q4 24', 96.2, 25.8),
        const _StackPoint('Q1 25', 98.4, 26.6),
      ];

  static List<_AllocSlice> portfolioAllocation() => <_AllocSlice>[
        const _AllocSlice('Equities', 58.4),
        const _AllocSlice('Fixed Income', 22.6),
        const _AllocSlice('Cash', 8.8),
        const _AllocSlice('Alternatives', 6.4),
        const _AllocSlice('Commodities', 3.8),
      ];

  static List<_ScatterPoint> riskReturn() => <_ScatterPoint>[
        const _ScatterPoint('AAPL', 1.18, 12.8, true),
        const _ScatterPoint('MSFT', 0.92, 14.6),
        const _ScatterPoint('GOOGL', 1.05, 11.2),
        const _ScatterPoint('AMZN', 1.24, 18.4),
        const _ScatterPoint('META', 1.31, 22.1),
        const _ScatterPoint('NVDA', 1.68, 38.6),
        const _ScatterPoint('JPM', 1.08, 8.4),
        const _ScatterPoint('V', 0.88, 10.2),
      ];

  static List<_HeatCell> performanceHeatmap() => <_HeatCell>[
        const _HeatCell('1D', 2.84),
        const _HeatCell('1W', 4.12),
        const _HeatCell('1M', 6.38),
        const _HeatCell('3M', 11.24),
        const _HeatCell('6M', 18.62),
        const _HeatCell('YTD', 22.48),
        const _HeatCell('1Y', 28.16),
        const _HeatCell('3Y', 64.82),
        const _HeatCell('5Y', 112.40),
      ];

  static List<_AnalystPoint> analystTrend() => <_AnalystPoint>[
        const _AnalystPoint('Jan', 12, 18, 8, 2, 0),
        const _AnalystPoint('Feb', 14, 19, 7, 2, 0),
        const _AnalystPoint('Mar', 15, 20, 6, 2, 1),
        const _AnalystPoint('Apr', 16, 21, 6, 1, 1),
        const _AnalystPoint('May', 17, 22, 5, 1, 0),
        const _AnalystPoint('Jun', 18, 23, 5, 1, 0),
        const _AnalystPoint('Jul', 19, 24, 4, 1, 0),
        const _AnalystPoint('Aug', 20, 25, 4, 0, 0),
      ];

  static List<_LinePoint> dividendGrowth() => <_LinePoint>[
        _LinePoint('2019', 0.76, 0),
        _LinePoint('2020', 0.82, 0),
        _LinePoint('2021', 0.88, 0),
        _LinePoint('2022', 0.92, 0),
        _LinePoint('2023', 0.96, 0),
        _LinePoint('2024', 1.02, 0),
      ];

  static List<_VolumeBar> volumeProfile() => <_VolumeBar>[
        const _VolumeBar('Mon', 48.2),
        const _VolumeBar('Tue', 52.6),
        const _VolumeBar('Wed', 44.8),
        const _VolumeBar('Thu', 58.4),
        const _VolumeBar('Fri', 61.2),
      ];

  static const double portfolioTotal = 2480000;
}

class _LinePoint {
  const _LinePoint(this.label, this.asset, this.benchmark);
  final String label;
  final double asset;
  final double benchmark;
}

class _RankPoint {
  const _RankPoint(this.label, this.value);
  final String label;
  final double value;
}

class _StackPoint {
  const _StackPoint(this.label, this.revenue, this.profit);
  final String label;
  final double revenue;
  final double profit;
}

class _AllocSlice {
  const _AllocSlice(this.label, this.percent);
  final String label;
  final double percent;
}

class _ScatterPoint {
  const _ScatterPoint(this.label, this.beta, this.returnPct, [this.highlight = false]);
  final String label;
  final double beta;
  final double returnPct;
  final bool highlight;
}

class _HeatCell {
  const _HeatCell(this.period, this.value);
  final String period;
  final double value;
}

class _AnalystPoint {
  const _AnalystPoint(this.period, this.strongBuy, this.buy, this.hold, this.sell, this.strongSell);
  final String period;
  final double strongBuy;
  final double buy;
  final double hold;
  final double sell;
  final double strongSell;
}

class _VolumeBar {
  const _VolumeBar(this.label, this.value);
  final String label;
  final double value;
}

/// Slice labels exposed for donut chart legends.
extension PremiumStaticAlloc on PremiumStaticChartData {
  static List<({String label, double percent})> allocationSlices() {
    return PremiumStaticChartData.portfolioAllocation()
        .map((s) => (label: s.label, percent: s.percent))
        .toList();
  }
}
