import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/models/portfolio_analytics_snapshot.dart';
import 'package:musaffa_terminal/portfolio/services/portfolio_analytics_service.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
import 'package:musaffa_terminal/portfolio/utils/portfolio_allocation_palette.dart';
import 'package:musaffa_terminal/portfolio/widgets/model_allocation_ring.dart';
import 'package:musaffa_terminal/portfolio/widgets/portfolio_country_map.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';

enum _AnalyticsTab { overview, performance, exposure, risk, valuation }

enum _PerfPeriod { day1, week1, month1, month3, month6, year1 }

/// Tabbed institutional-style analytics for model portfolios.
class PortfolioAnalyticsDashboard extends StatefulWidget {
  const PortfolioAnalyticsDashboard({
    super.key,
    required this.isDark,
    required this.holdings,
    this.benchmarkLabel = 'S&P 500',
  });

  final bool isDark;
  final List<ModelPortfolioHolding> holdings;
  final String benchmarkLabel;

  @override
  State<PortfolioAnalyticsDashboard> createState() =>
      _PortfolioAnalyticsDashboardState();
}

class _PortfolioAnalyticsDashboardState extends State<PortfolioAnalyticsDashboard> {
  final _service = PortfolioAnalyticsService();

  PortfolioAnalyticsSnapshot _snapshot = PortfolioAnalyticsSnapshot.empty;
  bool _loading = true;
  Object? _token;
  int _selectedTabIndex = 0;
  _PerfPeriod _period = _PerfPeriod.month1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PortfolioAnalyticsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameHoldings(oldWidget.holdings, widget.holdings) ||
        oldWidget.benchmarkLabel != widget.benchmarkLabel) {
      _load();
    }
  }

  bool _sameHoldings(List<ModelPortfolioHolding> a, List<ModelPortfolioHolding> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].ticker.toUpperCase() != b[i].ticker.toUpperCase()) return false;
      if (a[i].targetPercent != b[i].targetPercent) return false;
    }
    return true;
  }

  Future<void> _load() async {
    if (widget.holdings.isEmpty) {
      setState(() {
        _snapshot = PortfolioAnalyticsSnapshot.empty;
        _loading = false;
      });
      return;
    }

    final token = Object();
    _token = token;
    setState(() => _loading = true);

    try {
      final snap = await _service.load(
        holdings: widget.holdings,
        benchmarkLabel: widget.benchmarkLabel,
      );
      if (!mounted || _token != token) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _token != token) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    if (widget.holdings.isEmpty) {
      return _emptyState(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabBar(isDark),
        if (_snapshot.usesEqualWeightPreview) ...[
          const SizedBox(height: 10),
          _previewBanner(isDark),
        ],
        const SizedBox(height: 16),
        if (_loading && _snapshot == PortfolioAnalyticsSnapshot.empty)
          _loadingPlaceholder(isDark)
        else
          _buildTabBody(isDark),
      ],
    );
  }

  Widget _previewBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUi.accent(isDark).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.accent(isDark).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: HomeUi.accent(isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Allocation % not set — showing equal-weight preview. Set target % for accurate weights.',
              style: HomeUi.control(isDark).copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    const labels = ['Overview', 'Performance', 'Exposure', 'Risk', 'Valuation'];
    return HomeUi.segmentedControl(
      dark: isDark,
      options: labels,
      selectedIndex: _selectedTabIndex,
      onChanged: (index) => setState(() => _selectedTabIndex = index),
    );
  }

  Widget _buildTabBody(bool isDark) {
    switch (_AnalyticsTab.values[_selectedTabIndex]) {
      case _AnalyticsTab.overview:
        return _OverviewTab(
          isDark: isDark,
          snapshot: _snapshot,
          loading: _loading,
          period: _period,
          onPeriodChanged: (p) => setState(() => _period = p),
        );
      case _AnalyticsTab.performance:
        return _PerformanceTab(
          isDark: isDark,
          snapshot: _snapshot,
          loading: _loading,
          period: _period,
          onPeriodChanged: (p) => setState(() => _period = p),
        );
      case _AnalyticsTab.exposure:
        return _ExposureTab(isDark: isDark, snapshot: _snapshot);
      case _AnalyticsTab.risk:
        return _RiskTab(isDark: isDark, snapshot: _snapshot);
      case _AnalyticsTab.valuation:
        return _ValuationTab(isDark: isDark, snapshot: _snapshot, loading: _loading);
    }
  }

  Widget _loadingPlaceholder(bool isDark) {
    return Column(
      children: [
        SizedBox(height: 220, child: WatchlistShimmer.performanceCard(isDarkMode: isDark)),
        const SizedBox(height: 12),
        SizedBox(height: 280, child: WatchlistShimmer.performanceCard(isDarkMode: isDark)),
      ],
    );
  }

  Widget _emptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 44, color: HomeUi.muted(isDark)),
          const SizedBox(height: 12),
          Text(
            'Add holdings with allocation to unlock analytics',
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.isDark,
    required this.snapshot,
    required this.loading,
    required this.period,
    required this.onPeriodChanged,
  });

  final bool isDark;
  final PortfolioAnalyticsSnapshot snapshot;
  final bool loading;
  final _PerfPeriod period;
  final ValueChanged<_PerfPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PerformanceCard(
              isDark: isDark,
              performance: snapshot.performance,
              benchmark: snapshot.benchmark,
              loading: loading,
              period: period,
              onPeriodChanged: onPeriodChanged,
              compact: false,
            ),
            const SizedBox(height: 12),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _CountryCard(isDark: isDark, countries: snapshot.countries)),
                    const SizedBox(width: 12),
                    Expanded(child: _SectorCard(isDark: isDark, sectors: snapshot.sectors)),
                  ],
                ),
              )
            else ...[
              _CountryCard(isDark: isDark, countries: snapshot.countries),
              const SizedBox(height: 12),
              _SectorCard(isDark: isDark, sectors: snapshot.sectors),
            ],
            const SizedBox(height: 12),
            _ContributionCard(isDark: isDark, rows: snapshot.contributions),
            const SizedBox(height: 12),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TopHoldingsCard(isDark: isDark, holdings: snapshot.topHoldings),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RiskSnapshotCard(
                        isDark: isDark,
                        concentration: snapshot.concentration,
                        valuation: snapshot.valuation,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _TopHoldingsCard(isDark: isDark, holdings: snapshot.topHoldings),
              const SizedBox(height: 12),
              _RiskSnapshotCard(
                isDark: isDark,
                concentration: snapshot.concentration,
                valuation: snapshot.valuation,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PerformanceTab extends StatelessWidget {
  const _PerformanceTab({
    required this.isDark,
    required this.snapshot,
    required this.loading,
    required this.period,
    required this.onPeriodChanged,
  });

  final bool isDark;
  final PortfolioAnalyticsSnapshot snapshot;
  final bool loading;
  final _PerfPeriod period;
  final ValueChanged<_PerfPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final perf = snapshot.performance;
    final bench = snapshot.benchmark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PerformanceCard(
          isDark: isDark,
          performance: perf,
          benchmark: bench,
          loading: loading,
          period: period,
          onPeriodChanged: onPeriodChanged,
          compact: false,
          tallChart: true,
        ),
        if (bench != null &&
            bench.portfolioMonth != null &&
            bench.benchmarkMonth != null) ...[
          const SizedBox(height: 12),
          _AnalyticsCard(
            isDark: isDark,
            title: 'Benchmark Comparison',
            subtitle: '1M return vs ${bench.benchmarkLabel}',
            child: _BenchmarkTable(isDark: isDark, benchmark: bench),
          ),
        ],
        if (perf.bestHolding != null || perf.worstHolding != null) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 640;
              final best = perf.bestHolding;
              final worst = perf.worstHolding;
              final cards = <Widget>[
                if (best != null)
                  Expanded(
                    child: _MoverCard(isDark: isDark, label: 'Best today', holding: best, positive: true),
                  ),
                if (best != null && worst != null) SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                if (worst != null)
                  Expanded(
                    child: _MoverCard(isDark: isDark, label: 'Worst today', holding: worst, positive: false),
                  ),
              ];
              if (wide) {
                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards),
                );
              }
              return Column(children: cards);
            },
          ),
        ],
        const SizedBox(height: 12),
        _ContributionCard(isDark: isDark, rows: snapshot.contributions),
      ],
    );
  }
}

class _ExposureTab extends StatelessWidget {
  const _ExposureTab({required this.isDark, required this.snapshot});

  final bool isDark;
  final PortfolioAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CountryCard(isDark: isDark, countries: snapshot.countries, tall: true),
            const SizedBox(height: 12),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _SectorCard(isDark: isDark, sectors: snapshot.sectors, showChange: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _AssetClassCard(isDark: isDark, slices: snapshot.assetClasses)),
                  ],
                ),
              )
            else ...[
              _SectorCard(isDark: isDark, sectors: snapshot.sectors, showChange: true),
              const SizedBox(height: 12),
              _AssetClassCard(isDark: isDark, slices: snapshot.assetClasses),
            ],
            const SizedBox(height: 12),
            _MarketCapCard(isDark: isDark, buckets: snapshot.marketCapMix),
          ],
        );
      },
    );
  }
}

class _RiskTab extends StatelessWidget {
  const _RiskTab({required this.isDark, required this.snapshot});

  final bool isDark;
  final PortfolioAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConcentrationCard(isDark: isDark, metrics: snapshot.concentration),
        if (snapshot.correlation != null) ...[
          const SizedBox(height: 12),
          _CorrelationCard(isDark: isDark, matrix: snapshot.correlation!),
        ],
      ],
    );
  }
}

class _ValuationTab extends StatelessWidget {
  const _ValuationTab({
    required this.isDark,
    required this.snapshot,
    required this.loading,
  });

  final bool isDark;
  final PortfolioAnalyticsSnapshot snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final v = snapshot.valuation;
    final liq = snapshot.liquidity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnalyticsCard(
          isDark: isDark,
          title: 'Portfolio Valuation',
          subtitle: 'Allocation-weighted fundamentals · Finnhub',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiTile(isDark: isDark, label: 'Portfolio P/E', value: v.pe?.toStringAsFixed(1)),
              _KpiTile(isDark: isDark, label: 'Portfolio P/B', value: v.pb?.toStringAsFixed(1)),
              _KpiTile(
                isDark: isDark,
                label: 'Dividend yield',
                value: v.dividendYield != null ? '${v.dividendYield!.toStringAsFixed(2)}%' : null,
              ),
              _KpiTile(
                isDark: isDark,
                label: 'Avg market cap',
                value: v.avgMarketCapMillions != null
                    ? Constants.formatMarketCapFromMillions(v.avgMarketCapMillions!)
                    : null,
              ),
              _KpiTile(
                isDark: isDark,
                label: 'Avg volume (10D)',
                value: v.avgVolume != null ? _formatVolume(v.avgVolume!) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AnalyticsCard(
          isDark: isDark,
          title: 'Liquidity',
          subtitle: 'Volume-based holding classification',
          child: Row(
            children: [
              Expanded(
                child: _KpiTile(
                  isDark: isDark,
                  label: 'High liquidity',
                  value: '${liq.highLiquidityCount} holdings',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  isDark: isDark,
                  label: 'Low liquidity',
                  value: '${liq.lowLiquidityCount} holdings',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _TopHoldingsCard(
          isDark: isDark,
          holdings: snapshot.topHoldings,
          showFundamentals: true,
        ),
      ],
    );
  }

  String _formatVolume(num value) {
    return FinnhubDisplayFormatters.formatCompactCurrency(value).replaceAll('\$', '');
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.isDark,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final bool isDark;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: HomeUi.sectionTitle(isDark)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: HomeUi.subtitle(isDark).copyWith(fontSize: 11)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.isDark,
    required this.performance,
    required this.benchmark,
    required this.loading,
    required this.period,
    required this.onPeriodChanged,
    this.compact = true,
    this.tallChart = false,
  });

  final bool isDark;
  final PortfolioPerformanceMetrics performance;
  final BenchmarkComparison? benchmark;
  final bool loading;
  final _PerfPeriod period;
  final ValueChanged<_PerfPeriod> onPeriodChanged;
  final bool compact;
  final bool tallChart;

  @override
  Widget build(BuildContext context) {
    final positive = performance.isPositive;
    final lineColor = positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark);
    final fillColor = lineColor.withValues(alpha: isDark ? 0.18 : 0.12);
    final chartHeight = tallChart ? 160.0 : 100.0;

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Portfolio Performance',
      subtitle: 'Allocation-weighted · Finnhub daily closes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSelector(
            isDark: isDark,
            period: period,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PeriodMetric(
                      isDark: isDark,
                      label: _periodLabel(period),
                      value: _periodValue(performance, period),
                      loading: loading && _periodValue(performance, period) == null,
                      large: true,
                    ),
                    if (benchmark?.portfolioMonth != null &&
                        benchmark?.benchmarkMonth != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'vs ${benchmark!.benchmarkLabel} '
                        '${_fmtPct(benchmark!.benchmarkMonth!)} (1M)',
                        style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: chartHeight,
                  child: performance.sparkline.length >= 2
                      ? CustomPaint(
                          painter: _SparklinePainter(
                            values: performance.sparkline,
                            lineColor: lineColor,
                            fillColor: fillColor,
                          ),
                          child: const SizedBox.expand(),
                        )
                      : WatchlistShimmer.sparkline(isDarkMode: isDark, width: 200, height: chartHeight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _periodLabel(_PerfPeriod p) {
    switch (p) {
      case _PerfPeriod.day1:
        return 'Today';
      case _PerfPeriod.week1:
        return '1 Week';
      case _PerfPeriod.month1:
        return '1 Month';
      case _PerfPeriod.month3:
        return '3 Months';
      case _PerfPeriod.month6:
        return '6 Months';
      case _PerfPeriod.year1:
        return '1 Year';
    }
  }

  double? _periodValue(PortfolioPerformanceMetrics p, _PerfPeriod period) {
    switch (period) {
      case _PerfPeriod.day1:
        return p.day1;
      case _PerfPeriod.week1:
        return p.week1;
      case _PerfPeriod.month1:
        return p.month1;
      case _PerfPeriod.month3:
        return p.month3;
      case _PerfPeriod.month6:
        return p.month6;
      case _PerfPeriod.year1:
        return p.year1;
    }
  }

  String _fmtPct(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(2)}%';
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.isDark,
    required this.period,
    required this.onChanged,
  });

  final bool isDark;
  final _PerfPeriod period;
  final ValueChanged<_PerfPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = <(_PerfPeriod, String)>[
      (_PerfPeriod.day1, '1D'),
      (_PerfPeriod.week1, '1W'),
      (_PerfPeriod.month1, '1M'),
      (_PerfPeriod.month3, '3M'),
      (_PerfPeriod.month6, '6M'),
      (_PerfPeriod.year1, '1Y'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        final selected = period == item.$1;
        return GestureDetector(
          onTap: () => onChanged(item.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? HomeUi.accent(isDark).withValues(alpha: 0.12) : HomeUi.elevatedBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusSm),
              border: Border.all(
                color: selected ? HomeUi.accent(isDark) : HomeUi.borderLight(isDark),
              ),
            ),
            child: Text(
              item.$2,
              style: HomeUi.control(isDark).copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? HomeUi.accent(isDark) : HomeUi.muted(isDark),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.isDark,
    required this.countries,
    this.tall = false,
  });

  final bool isDark;
  final List<CountryAllocation> countries;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final mapCountries = countries.where((c) => c.mapId != null).toList();

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Country Exposure',
      subtitle: 'Geographic allocation by holding weight',
      child: countries.isEmpty
          ? Text('No country data yet', style: HomeUi.subtitle(isDark))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mapCountries.isNotEmpty)
                  PortfolioCountryMap(
                    isDark: isDark,
                    countries: mapCountries,
                    height: tall ? 320 : 220,
                  ),
                if (mapCountries.isNotEmpty) const SizedBox(height: 12),
                ...countries.take(6).map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _HorizontalBarRow(
                      isDark: isDark,
                      label: c.name,
                      trailing: formatAllocationPercent(c.percent),
                      fraction: c.percent / (countries.first.percent > 0 ? countries.first.percent : 100),
                      color: HomeUi.accent(isDark),
                      subtitle: c.holdingsCount > 0 ? '${c.holdingsCount} holdings' : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.isDark,
    required this.sectors,
    this.showChange = false,
  });

  final bool isDark;
  final List<SectorAllocation> sectors;
  final bool showChange;

  @override
  Widget build(BuildContext context) {
    final slices = sectors
        .map((s) => (label: s.name, percent: s.percent))
        .toList();
    final total = sectors.fold<double>(0, (s, e) => s + e.percent);

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Sector Exposure',
      subtitle: showChange ? 'Allocation and today\'s sector move' : null,
      child: sectors.isEmpty
          ? Text('No sector data yet', style: HomeUi.subtitle(isDark))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModelBreakdownDonut(
                  isDark: isDark,
                  slices: slices.take(6).toList(),
                  centerValue: formatAllocationPercent(total),
                  centerLabel: 'Total',
                  size: 120,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: sectors.take(6).map((s) {
                      final change = s.dayChange;
                      final changeText = change == null
                          ? null
                          : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: PortfolioAllocationPalette.sectorColor(s.name, isDark),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.name,
                                style: HomeUi.control(isDark).copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatAllocationPercent(s.percent),
                              style: HomeUi.control(isDark).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            if (showChange && changeText != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                changeText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: (change ?? 0) >= 0
                                      ? HomeUi.positive(isDark)
                                      : HomeUi.negative(isDark),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.isDark, required this.rows});

  final bool isDark;
  final List<ContributionRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxAbs = rows.isEmpty
        ? 1.0
        : rows.map((r) => r.contribution.abs()).reduce(math.max).clamp(0.01, double.infinity);

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Contribution to Portfolio Return',
      subtitle: 'Today\'s weighted impact by holding',
      child: rows.isEmpty
          ? Text('No contribution data yet', style: HomeUi.subtitle(isDark))
          : Column(
              children: rows.take(6).map((r) {
                final positive = r.contribution >= 0;
                final color = positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          r.ticker,
                          style: HomeUi.control(isDark).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${positive ? '+' : ''}${r.contribution.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (r.contribution.abs() / maxAbs).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: HomeUi.elevatedBg(isDark),
                            valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.85)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _TopHoldingsCard extends StatelessWidget {
  const _TopHoldingsCard({
    required this.isDark,
    required this.holdings,
    this.showFundamentals = false,
  });

  final bool isDark;
  final List<HoldingAnalytics> holdings;
  final bool showFundamentals;

  @override
  Widget build(BuildContext context) {
    final maxWeight = holdings.isEmpty
        ? 100.0
        : holdings.map((h) => h.weight).reduce(math.max).clamp(1.0, 100.0);

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Top Holdings',
      subtitle: 'Weight · daily change · contribution',
      child: holdings.isEmpty
          ? Text('No holdings yet', style: HomeUi.subtitle(isDark))
          : Column(
              children: holdings.take(showFundamentals ? 8 : 5).map((h) {
                final change = h.dayChange;
                final positive = (change ?? 0) >= 0;
                final tone = change == null
                    ? HomeUi.muted(isDark)
                    : (positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          showLogo(
                            h.ticker,
                            h.logo ?? '',
                            sideWidth: 24,
                            name: h.name,
                            borderColor: HomeUi.borderLight(isDark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.ticker,
                              style: HomeUi.control(isDark).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            formatAllocationPercent(h.weight),
                            style: HomeUi.control(isDark).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 58,
                            child: Text(
                              change == null
                                  ? '—'
                                  : '${positive ? '+' : ''}${change.toStringAsFixed(2)}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tone,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (h.weight / maxWeight).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: HomeUi.elevatedBg(isDark),
                          valueColor: AlwaysStoppedAnimation(HomeUi.accent(isDark)),
                        ),
                      ),
                      if (showFundamentals &&
                          (h.pe != null || h.marketCapMillions != null)) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (h.pe != null) 'P/E ${h.pe!.toStringAsFixed(1)}',
                            if (h.marketCapMillions != null)
                              Constants.formatMarketCapFromMillions(h.marketCapMillions!),
                          ].join(' · '),
                          style: HomeUi.subtitle(isDark).copyWith(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _RiskSnapshotCard extends StatelessWidget {
  const _RiskSnapshotCard({
    required this.isDark,
    required this.concentration,
    required this.valuation,
  });

  final bool isDark;
  final ConcentrationMetrics concentration;
  final ValuationMetrics valuation;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      isDark: isDark,
      title: 'Risk & Market Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConcentrationBars(isDark: isDark, metrics: concentration),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipMetric(
                isDark: isDark,
                label: 'Holdings',
                value: '${concentration.holdingsCount}',
              ),
              if (valuation.pe != null)
                _ChipMetric(
                  isDark: isDark,
                  label: 'P/E',
                  value: valuation.pe!.toStringAsFixed(1),
                ),
              if (valuation.dividendYield != null)
                _ChipMetric(
                  isDark: isDark,
                  label: 'Div yield',
                  value: '${valuation.dividendYield!.toStringAsFixed(2)}%',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConcentrationCard extends StatelessWidget {
  const _ConcentrationCard({required this.isDark, required this.metrics});

  final bool isDark;
  final ConcentrationMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      isDark: isDark,
      title: 'Risk & Concentration',
      subtitle: 'Portfolio weight concentration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: HomeUi.accent(isDark).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HomeUi.radiusSm),
              border: Border.all(color: HomeUi.accent(isDark).withValues(alpha: 0.35)),
            ),
            child: Text(
              metrics.label,
              style: HomeUi.control(isDark).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: HomeUi.accent(isDark),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ConcentrationBars(isDark: isDark, metrics: metrics),
          const SizedBox(height: 12),
          Text(
            'HHI ${metrics.hhi.toStringAsFixed(0)} · ${metrics.holdingsCount} holdings',
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ConcentrationBars extends StatelessWidget {
  const _ConcentrationBars({required this.isDark, required this.metrics});

  final bool isDark;
  final ConcentrationMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HorizontalBarRow(
          isDark: isDark,
          label: 'Top 1',
          trailing: formatAllocationPercent(metrics.top1),
          fraction: metrics.top1 / 100,
          color: HomeUi.accent(isDark),
        ),
        const SizedBox(height: 8),
        _HorizontalBarRow(
          isDark: isDark,
          label: 'Top 3',
          trailing: formatAllocationPercent(metrics.top3),
          fraction: metrics.top3 / 100,
          color: HomeUi.accent(isDark).withValues(alpha: 0.75),
        ),
        const SizedBox(height: 8),
        _HorizontalBarRow(
          isDark: isDark,
          label: 'Top 5',
          trailing: formatAllocationPercent(metrics.top5),
          fraction: metrics.top5 / 100,
          color: HomeUi.accent(isDark).withValues(alpha: 0.55),
        ),
      ],
    );
  }
}

class _CorrelationCard extends StatelessWidget {
  const _CorrelationCard({required this.isDark, required this.matrix});

  final bool isDark;
  final CorrelationMatrix matrix;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      isDark: isDark,
      title: 'Correlation Matrix',
      subtitle: 'Daily return correlation · top ${matrix.tickers.length} holdings',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _CorrelationHeatmap(isDark: isDark, matrix: matrix),
      ),
    );
  }
}

class _CorrelationHeatmap extends StatelessWidget {
  const _CorrelationHeatmap({required this.isDark, required this.matrix});

  final bool isDark;
  final CorrelationMatrix matrix;

  @override
  Widget build(BuildContext context) {
    const cell = 44.0;
    final tickers = matrix.tickers;
    final n = tickers.length;

    Color cellColor(double v) {
      if (v >= 0.99) return HomeUi.accent(isDark);
      final t = v.abs().clamp(0.0, 1.0);
      if (v >= 0) {
        return HomeUi.positive(isDark).withValues(alpha: 0.15 + t * 0.65);
      }
      return HomeUi.negative(isDark).withValues(alpha: 0.15 + t * 0.65);
    }

    return Table(
      defaultColumnWidth: const FixedColumnWidth(cell),
      children: [
        TableRow(
          children: [
            const SizedBox(width: cell, height: cell),
            for (final t in tickers)
              Center(
                child: Text(
                  t,
                  style: HomeUi.control(isDark).copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        for (var i = 0; i < n; i++)
          TableRow(
            children: [
              Center(
                child: Text(
                  tickers[i],
                  style: HomeUi.control(isDark).copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (var j = 0; j < n; j++)
                Container(
                  width: cell,
                  height: cell,
                  margin: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cellColor(matrix.values[i][j]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: HomeUi.borderLight(isDark)),
                  ),
                  child: Text(
                    matrix.values[i][j].toStringAsFixed(2),
                    style: HomeUi.control(isDark).copyWith(fontSize: 9),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _AssetClassCard extends StatelessWidget {
  const _AssetClassCard({required this.isDark, required this.slices});

  final bool isDark;
  final List<AssetClassSlice> slices;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      isDark: isDark,
      title: 'Asset-Class Exposure',
      child: slices.isEmpty
          ? Text('No asset-class data', style: HomeUi.subtitle(isDark))
          : Column(
              children: slices.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HorizontalBarRow(
                    isDark: isDark,
                    label: s.label,
                    trailing: formatAllocationPercent(s.percent),
                    fraction: s.percent / 100,
                    color: PortfolioAllocationPalette.assetType(s.label, isDark),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _MarketCapCard extends StatelessWidget {
  const _MarketCapCard({required this.isDark, required this.buckets});

  final bool isDark;
  final List<MarketCapBucket> buckets;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      isDark: isDark,
      title: 'Market-Cap Mix',
      child: buckets.isEmpty
          ? Text('No market-cap data', style: HomeUi.subtitle(isDark))
          : Column(
              children: buckets.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HorizontalBarRow(
                    isDark: isDark,
                    label: b.label,
                    trailing: formatAllocationPercent(b.percent),
                    fraction: b.percent / 100,
                    color: HomeUi.accent(isDark),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _BenchmarkTable extends StatelessWidget {
  const _BenchmarkTable({required this.isDark, required this.benchmark});

  final bool isDark;
  final BenchmarkComparison benchmark;

  @override
  Widget build(BuildContext context) {
    String fmt(double? v) {
      if (v == null) return '—';
      return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            Text('Portfolio', style: HomeUi.subtitle(isDark).copyWith(fontWeight: FontWeight.w700)),
            Text(benchmark.benchmarkLabel, style: HomeUi.subtitle(isDark).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('1M Return', style: HomeUi.control(isDark).copyWith(fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(fmt(benchmark.portfolioMonth), style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(fmt(benchmark.benchmarkMonth), style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({
    required this.isDark,
    required this.label,
    required this.holding,
    required this.positive,
  });

  final bool isDark;
  final String label;
  final HoldingAnalytics holding;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark);
    final change = holding.dayChange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HomeUi.subtitle(isDark).copyWith(fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            holding.ticker,
            style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(holding.name, style: HomeUi.subtitle(isDark), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(
            change == null ? '—' : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _HorizontalBarRow extends StatelessWidget {
  const _HorizontalBarRow({
    required this.isDark,
    required this.label,
    required this.trailing,
    required this.fraction,
    required this.color,
    this.subtitle,
  });

  final bool isDark;
  final String label;
  final String trailing;
  final double fraction;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: HomeUi.control(isDark).copyWith(fontSize: 12)),
                  if (subtitle != null)
                    Text(subtitle!, style: HomeUi.subtitle(isDark).copyWith(fontSize: 10)),
                ],
              ),
            ),
            Text(
              trailing,
              style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: HomeUi.elevatedBg(isDark),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.isDark, required this.label, this.value});

  final bool isDark;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HomeUi.subtitle(isDark).copyWith(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value ?? '—',
            style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _ChipMetric extends StatelessWidget {
  const _ChipMetric({required this.isDark, required this.label, required this.value});

  final bool isDark;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusSm),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HomeUi.subtitle(isDark).copyWith(fontSize: 10)),
          Text(value, style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PeriodMetric extends StatelessWidget {
  const _PeriodMetric({
    required this.isDark,
    required this.label,
    this.value,
    this.loading = false,
    this.large = false,
  });

  final bool isDark;
  final String label;
  final double? value;
  final bool loading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final positive = (value ?? 0) >= 0;
    final color = !hasValue
        ? HomeUi.muted(isDark)
        : (positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: HomeUi.subtitle(isDark).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        if (loading)
          WatchlistShimmer.metricValue(isDarkMode: isDark)
        else
          Text(
            !hasValue
                ? '—'
                : '${positive ? '▲' : '▼'} ${value!.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: large ? 22 : 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    this.strokeWidth = 2,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    var minV = values.first;
    var maxV = values.first;
    for (final v in values) {
      minV = math.min(minV, v);
      maxV = math.max(maxV, v);
    }
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    const padY = 2.0;
    final usableH = size.height - padY * 2;
    final last = values.length - 1;

    Offset pointAt(int i) {
      final t = i / last;
      final norm = (values[i] - minV) / span;
      return Offset(size.width * t, padY + usableH * (1 - norm));
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i <= last; i++) {
      line.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final area = Path.from(line)
      ..lineTo(pointAt(last).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
