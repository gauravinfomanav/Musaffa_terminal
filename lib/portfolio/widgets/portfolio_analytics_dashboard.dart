import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/sliding_pill_tabs.dart';
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
    final accent = HomeUi.accent(isDark);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: accent.withValues(alpha: isDark ? 0.28 : 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.14),
                    const Color(0xFF171A24),
                  ),
                  const Color(0xFF141720),
                ]
              : [
                  const Color(0xFFEFF6FF),
                  const Color(0xFFF8FAFC),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_rounded, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Allocation % not set — showing equal-weight preview. Set target % for accurate weights.',
              style: HomeUi.control(isDark).copyWith(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    const labels = ['Overview', 'Performance', 'Exposure', 'Risk', 'Valuation'];
    return Align(
      alignment: Alignment.centerLeft,
      child: SlidingPillTabs(
        itemCount: labels.length,
        selectedIndex: _selectedTabIndex,
        isDarkMode: isDark,
        height: HomeUi.controlHeight,
        onSelect: (index) {
          if (index == _selectedTabIndex) return;
          // Defer body swap so mouse tracker finishes the pointer update first.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || index == _selectedTabIndex) return;
            setState(() => _selectedTabIndex = index);
          });
        },
        itemBuilder: (context, index, isSelected) {
          return Text(
            labels[index],
            style: HomeUi.control(isDark, active: isSelected).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : HomeUi.muted(isDark),
            ),
          );
        },
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: HomeUi.softBrandWellGradient,
            ),
            child: HomeUi.brandIcon(
              icon: Icons.insights_rounded,
              size: 28,
              gradient: HomeUi.softBrandIconGradient,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analytics ready when you are',
            style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Add holdings with allocation to unlock performance, exposure, and risk.',
            textAlign: TextAlign.center,
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 13, height: 1.4),
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
            icon: Icons.compare_arrows_rounded,
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
    final concentration = _ConcentrationCard(
      isDark: isDark,
      metrics: snapshot.concentration,
    );
    final correlation = snapshot.correlation == null
        ? null
        : _CorrelationCard(isDark: isDark, matrix: snapshot.correlation!);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Avoid IntrinsicHeight here: correlation heatmap uses LayoutBuilder,
        // which cannot provide intrinsic dimensions and crashes on desktop.
        final wide = constraints.maxWidth >= 960 && correlation != null;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: concentration),
              const SizedBox(width: 12),
              Expanded(flex: 6, child: correlation),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            concentration,
            if (correlation != null) ...[
              const SizedBox(height: 12),
              correlation,
            ],
          ],
        );
      },
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
          icon: Icons.account_balance_rounded,
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
          icon: Icons.water_drop_rounded,
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
    this.icon,
    this.trailing,
  });

  final bool isDark;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        boxShadow: HomeUi.cardShadow(isDark),
      ),
      child: Material(
        color: HomeUi.cardBg(isDark),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          side: BorderSide(color: HomeUi.borderLight(isDark), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1A1D28),
                          HomeUi.cardBg(isDark),
                        ]
                      : [
                          const Color(0xFFFAFBFC),
                          Colors.white,
                        ],
                ),
                border: Border(
                  bottom: BorderSide(color: HomeUi.borderLight(isDark)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      title: title,
                      subtitleText: subtitle,
                      icon: icon,
                      titleFontSize: 15,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: trailing!,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: child,
            ),
          ],
        ),
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
    final selectedValue = _periodValue(performance, period);
    final positive = (selectedValue ?? 0) >= 0;
    final lineColor = selectedValue == null
        ? HomeUi.accent(isDark)
        : (positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark));
    final fillColor = lineColor.withValues(alpha: isDark ? 0.16 : 0.1);
    final chartHeight = tallChart ? 188.0 : 148.0;
    final hasBenchmark = benchmark?.portfolioMonth != null &&
        benchmark?.benchmarkMonth != null;
    final vsBench = hasBenchmark
        ? (benchmark!.portfolioMonth! - benchmark!.benchmarkMonth!)
        : null;

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Portfolio Performance',
      subtitle: 'Allocation-weighted · Finnhub daily closes',
      icon: Icons.show_chart_rounded,
      trailing: _PeriodSelector(
        isDark: isDark,
        period: period,
        onChanged: onPeriodChanged,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final metricPanel = _PerformanceMetricPanel(
            isDark: isDark,
            periodLabel: _periodLabel(period),
            value: selectedValue,
            loading: loading && selectedValue == null,
            lineColor: lineColor,
            positive: positive,
            benchmarkLabel: hasBenchmark ? benchmark!.benchmarkLabel : null,
            benchmarkValue: hasBenchmark ? benchmark!.benchmarkMonth : null,
            vsBenchmark: vsBench,
            performance: performance,
            activePeriod: period,
            fillHeight: wide,
          );
          final chartPanel = _PerformanceChartPanel(
            isDark: isDark,
            lineColor: lineColor,
            fillColor: fillColor,
            chartHeight: chartHeight,
            values: performance.sparkline,
            dates: performance.sparklineDates,
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                metricPanel,
                const SizedBox(height: 12),
                chartPanel,
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 292, child: metricPanel),
                const SizedBox(width: 12),
                Expanded(child: chartPanel),
              ],
            ),
          );
        },
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
}

class _PerformanceMetricPanel extends StatelessWidget {
  const _PerformanceMetricPanel({
    required this.isDark,
    required this.periodLabel,
    required this.value,
    required this.loading,
    required this.lineColor,
    required this.positive,
    required this.performance,
    required this.activePeriod,
    this.benchmarkLabel,
    this.benchmarkValue,
    this.vsBenchmark,
    this.fillHeight = false,
  });

  final bool isDark;
  final String periodLabel;
  final double? value;
  final bool loading;
  final Color lineColor;
  final bool positive;
  final PortfolioPerformanceMetrics performance;
  final _PerfPeriod activePeriod;
  final String? benchmarkLabel;
  final double? benchmarkValue;
  final double? vsBenchmark;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: fillHeight ? double.infinity : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(
          color: lineColor.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    lineColor.withValues(alpha: 0.14),
                    const Color(0xFF171A24),
                  ),
                  const Color(0xFF12151F),
                ]
              : [
                  Color.alphaBlend(
                    lineColor.withValues(alpha: 0.07),
                    const Color(0xFFFCFCFD),
                  ),
                  Colors.white,
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Text(
              periodLabel.toUpperCase(),
              style: HomeUi.subtitle(isDark).copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            WatchlistShimmer.metricValue(isDarkMode: isDark)
          else
            Text(
              value == null
                  ? '—'
                  : '${positive ? '▲' : '▼'} ${value!.abs().toStringAsFixed(2)}%',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontFamilyFallback: Constants.FONT_FALLBACK,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.05,
                color: value == null ? HomeUi.muted(isDark) : lineColor,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Selected period return',
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 11.5),
          ),
          if (benchmarkLabel != null && benchmarkValue != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                border: Border.all(color: HomeUi.borderLight(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VS ${benchmarkLabel!.toUpperCase()}',
                    style: HomeUi.subtitle(isDark).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _fmtPct(benchmarkValue!),
                    style: HomeUi.control(isDark).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (vsBenchmark != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${vsBenchmark! >= 0 ? '+' : ''}${vsBenchmark!.toStringAsFixed(2)}% vs bench',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: vsBenchmark! >= 0
                            ? HomeUi.positive(isDark)
                            : HomeUi.negative(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (fillHeight) const Spacer(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniPeriodChip(
                  isDark: isDark,
                  label: '1W',
                  value: performance.week1,
                  active: activePeriod == _PerfPeriod.week1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniPeriodChip(
                  isDark: isDark,
                  label: '1M',
                  value: performance.month1,
                  active: activePeriod == _PerfPeriod.month1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniPeriodChip(
                  isDark: isDark,
                  label: '1Y',
                  value: performance.year1,
                  active: activePeriod == _PerfPeriod.year1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtPct(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(2)}%';
  }
}

class _MiniPeriodChip extends StatelessWidget {
  const _MiniPeriodChip({
    required this.isDark,
    required this.label,
    required this.value,
    required this.active,
  });

  final bool isDark;
  final String label;
  final double? value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final positive = (value ?? 0) >= 0;
    final color = value == null
        ? HomeUi.muted(isDark)
        : (positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: isDark ? 0.16 : 0.1)
            : (isDark ? const Color(0xFF151822) : Colors.white),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.35)
              : HomeUi.borderLight(isDark),
        ),
        boxShadow: active
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: HomeUi.subtitle(isDark).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value == null
                  ? '—'
                  : '${positive ? '+' : ''}${value!.toStringAsFixed(1)}%',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceChartPanel extends StatelessWidget {
  const _PerformanceChartPanel({
    required this.isDark,
    required this.lineColor,
    required this.fillColor,
    required this.chartHeight,
    required this.values,
    required this.dates,
  });

  final bool isDark;
  final Color lineColor;
  final Color fillColor;
  final double chartHeight;
  final List<double> values;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final hasChart = values.length >= 2;
    final startLabel = dates.isNotEmpty
        ? DateFormat('dd MMM').format(dates.first)
        : null;
    final endLabel = dates.length > 1
        ? DateFormat('dd MMM').format(dates.last)
        : null;

    return Container(
      constraints: BoxConstraints(minHeight: chartHeight + 36),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    lineColor.withValues(alpha: 0.08),
                    const Color(0xFF151822),
                  ),
                  const Color(0xFF10131A),
                ]
              : [
                  Color.alphaBlend(
                    lineColor.withValues(alpha: 0.04),
                    const Color(0xFFFCFCFD),
                  ),
                  const Color(0xFFF5F7FA),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'TREND',
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: lineColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: lineColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Hover for details',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: chartHeight,
            child: hasChart
                ? _InteractiveSparkline(
                    isDark: isDark,
                    values: values,
                    dates: dates,
                    lineColor: lineColor,
                    fillColor: fillColor,
                  )
                : WatchlistShimmer.sparkline(
                    isDarkMode: isDark,
                    width: 200,
                    height: chartHeight,
                  ),
          ),
          if (startLabel != null && endLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  startLabel,
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 10.5),
                ),
                const Spacer(),
                Text(
                  endLabel,
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151822) : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final selected = period == item.$1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged(item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark ? const Color(0xFF1E2430) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                    border: Border.all(
                      color: selected
                          ? HomeUi.borderStrong(isDark)
                          : Colors.transparent,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.22 : 0.04,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    item.$2,
                    style: HomeUi.control(isDark).copyWith(
                      fontSize: 11.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                      color: selected
                          ? HomeUi.title(isDark)
                          : HomeUi.muted(isDark),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
      icon: Icons.public_rounded,
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
    final sliceColors = sectors
        .map((s) => PortfolioAllocationPalette.sectorColor(s.name, isDark))
        .toList();
    final total = sectors.fold<double>(0, (s, e) => s + e.percent);

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Sector Exposure',
      subtitle: showChange
          ? 'Allocation and today\'s sector move'
          : 'Weight by GICS sector',
      icon: Icons.donut_large_rounded,
      child: sectors.isEmpty
          ? Text('No sector data yet', style: HomeUi.subtitle(isDark))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ModelBreakdownDonut(
                  isDark: isDark,
                  slices: slices.take(6).toList(),
                  colors: sliceColors.take(6).toList(),
                  centerValue: formatAllocationPercent(total),
                  centerLabel: 'Total',
                  size: 168,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < sectors.take(6).length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _SectorLegendRow(
                          isDark: isDark,
                          sector: sectors[i],
                          color: sliceColors[i],
                          showChange: showChange,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectorLegendRow extends StatelessWidget {
  const _SectorLegendRow({
    required this.isDark,
    required this.sector,
    required this.color,
    required this.showChange,
  });

  final bool isDark;
  final SectorAllocation sector;
  final Color color;
  final bool showChange;

  @override
  Widget build(BuildContext context) {
    final change = sector.dayChange;
    final changeText = change == null
        ? null
        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151822) : Colors.white,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sector.name,
              style: HomeUi.control(isDark).copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatAllocationPercent(sector.percent),
            style: HomeUi.control(isDark).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          if (showChange && changeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: ((change ?? 0) >= 0
                        ? HomeUi.positive(isDark)
                        : HomeUi.negative(isDark))
                    .withValues(alpha: isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              ),
              child: Text(
                changeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: (change ?? 0) >= 0
                      ? HomeUi.positive(isDark)
                      : HomeUi.negative(isDark),
                ),
              ),
            ),
          ],
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
      icon: Icons.stacked_bar_chart_rounded,
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
                          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                          child: LinearProgressIndicator(
                            value: (r.contribution.abs() / maxAbs).clamp(0.0, 1.0),
                            minHeight: 9,
                            backgroundColor: HomeUi.elevatedBg(isDark),
                            valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.9)),
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
      icon: Icons.workspace_premium_rounded,
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
                        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                        child: LinearProgressIndicator(
                          value: (h.weight / maxWeight).clamp(0.0, 1.0),
                          minHeight: 7,
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
      subtitle: 'Concentration and valuation snapshot',
      icon: Icons.shield_rounded,
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

  Color get _badgeColor {
    final label = metrics.label.toLowerCase();
    if (label.contains('high')) return const Color(0xFFD97706);
    if (label.contains('low') || label.contains('divers')) {
      return HomeUi.positive(isDark);
    }
    return HomeUi.accent(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor;

    return _AnalyticsCard(
      isDark: isDark,
      title: 'Risk & Concentration',
      subtitle: 'Portfolio weight concentration',
      icon: Icons.security_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              metrics.label,
              style: HomeUi.control(isDark).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _RiskStatTile(
                  isDark: isDark,
                  label: 'HHI',
                  value: metrics.hhi.toStringAsFixed(0),
                  hint: 'Herfindahl index',
                  accent: badgeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RiskStatTile(
                  isDark: isDark,
                  label: 'Holdings',
                  value: '${metrics.holdingsCount}',
                  hint: 'Active positions',
                  accent: HomeUi.accent(isDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RiskStatTile(
                  isDark: isDark,
                  label: 'Top 1',
                  value: formatAllocationPercent(metrics.top1),
                  hint: 'Largest weight',
                  accent: HomeUi.accent(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: HomeUi.borderLight(isDark)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF171A24), const Color(0xFF12151F)]
                    : [const Color(0xFFFCFCFD), const Color(0xFFF5F7FA)],
              ),
            ),
            child: _ConcentrationBars(isDark: isDark, metrics: metrics),
          ),
        ],
      ),
    );
  }
}

class _RiskStatTile extends StatelessWidget {
  const _RiskStatTile({
    required this.isDark,
    required this.label,
    required this.value,
    required this.hint,
    required this.accent,
  });

  final bool isDark;
  final String label;
  final String value;
  final String hint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        color: isDark ? const Color(0xFF151822) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: HomeUi.subtitle(isDark).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: HomeUi.control(isDark).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final accent = HomeUi.accent(isDark);
    final rows = <({String label, double value, Color color})>[
      (label: 'Top 1 holding', value: metrics.top1, color: accent),
      (
        label: 'Top 3 holdings',
        value: metrics.top3,
        color: Color.lerp(accent, HomeUi.muted(isDark), 0.28)!,
      ),
      (
        label: 'Top 5 holdings',
        value: metrics.top5,
        color: Color.lerp(accent, HomeUi.muted(isDark), 0.48)!,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _HorizontalBarRow(
            isDark: isDark,
            label: rows[i].label,
            trailing: formatAllocationPercent(rows[i].value),
            fraction: rows[i].value / 100,
            color: rows[i].color,
            barHeight: 11,
          ),
        ],
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
      subtitle:
          'Daily return correlation · top ${matrix.tickers.length} holdings',
      icon: Icons.grid_on_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: HomeUi.borderLight(isDark)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF171A24), const Color(0xFF12151F)]
                    : [const Color(0xFFFCFCFD), const Color(0xFFF5F7FA)],
              ),
            ),
            child: _CorrelationHeatmap(isDark: isDark, matrix: matrix),
          ),
          const SizedBox(height: 12),
          _CorrelationLegend(isDark: isDark),
        ],
      ),
    );
  }
}

class _CorrelationLegend extends StatelessWidget {
  const _CorrelationLegend({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, Color color})>[
      (label: 'Self (1.0)', color: HomeUi.accent(isDark)),
      (
        label: 'Positive',
        color: HomeUi.positive(isDark).withValues(alpha: 0.72),
      ),
      (
        label: 'Negative',
        color: HomeUi.negative(isDark).withValues(alpha: 0.72),
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: HomeUi.subtitle(isDark).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _CorrelationHeatmap extends StatelessWidget {
  const _CorrelationHeatmap({required this.isDark, required this.matrix});

  final bool isDark;
  final CorrelationMatrix matrix;

  Color _cellColor(double v) {
    if (v.isNaN || v.isInfinite) {
      return isDark ? const Color(0xFF1A1D28) : const Color(0xFFF1F5F9);
    }
    if (v >= 0.99) return HomeUi.accent(isDark);
    final t = v.abs().clamp(0.0, 1.0);
    if (v >= 0) {
      return Color.lerp(
        isDark ? const Color(0xFF1A2E28) : const Color(0xFFE8F7F0),
        HomeUi.positive(isDark),
        0.35 + t * 0.65,
      )!;
    }
    return Color.lerp(
      isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFCECEC),
      HomeUi.negative(isDark),
      0.35 + t * 0.65,
    )!;
  }

  Color _textColor(double v) {
    if (v.isNaN || v.isInfinite) return HomeUi.muted(isDark);
    if (v >= 0.99) return Colors.white;
    if (v.abs() >= 0.55) return Colors.white;
    return HomeUi.title(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final tickers = matrix.tickers;
    final n = tickers.length;
    if (n == 0) {
      return Text('No correlation data', style: HomeUi.subtitle(isDark));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelCol = 64.0;
        final available = (constraints.maxWidth - labelCol).clamp(180.0, 900.0);
        final cell = (available / n).clamp(52.0, 88.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: labelCol),
                for (final t in tickers)
                  SizedBox(
                    width: cell,
                    child: Center(
                      child: Text(
                        t,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeUi.control(isDark).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: labelCol,
                    child: Text(
                      tickers[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeUi.control(isDark).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (var j = 0; j < n; j++)
                    SizedBox(
                      width: cell,
                      height: cell * 0.78,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _cellColor(matrix.values[i][j]),
                            borderRadius:
                                BorderRadius.circular(HomeUi.radiusSm),
                            border: Border.all(
                              color: HomeUi.borderLight(isDark)
                                  .withValues(alpha: 0.55),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _cellColor(matrix.values[i][j])
                                    .withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              matrix.values[i][j].toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontFamilyFallback: Constants.FONT_FALLBACK,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _textColor(matrix.values[i][j]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
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
      subtitle: 'Allocation across stocks, ETFs & more',
      icon: Icons.category_rounded,
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
      subtitle: 'Large · mid · small · micro weight',
      icon: Icons.pie_chart_outline_rounded,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    color.withValues(alpha: 0.14),
                    const Color(0xFF171A24),
                  ),
                  const Color(0xFF141720),
                ]
              : [
                  Color.alphaBlend(
                    color.withValues(alpha: 0.07),
                    const Color(0xFFFCFCFD),
                  ),
                  Colors.white,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            holding.ticker,
            style: HomeUi.control(isDark).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          Text(
            holding.name,
            style: HomeUi.subtitle(isDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            change == null
                ? '—'
                : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
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
    this.barHeight = 9,
  });

  final bool isDark;
  final String label;
  final String trailing;
  final double fraction;
  final Color color;
  final String? subtitle;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final track = isDark ? const Color(0xFF2A2F3A) : const Color(0xFFEEF1F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: HomeUi.control(isDark).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: HomeUi.subtitle(isDark).copyWith(fontSize: 10),
                    ),
                ],
              ),
            ),
            Text(
              trailing,
              style: HomeUi.control(isDark).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E6EC),
              width: 0.8,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    color,
                    Color.lerp(color, Colors.white, isDark ? 0.14 : 0.1)!,
                  ],
                ),
              ),
            ),
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
      width: 158,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1D28), const Color(0xFF141720)]
              : [const Color(0xFFFCFCFD), Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: HomeUi.subtitle(isDark).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value ?? '—',
            style: HomeUi.control(isDark).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151822) : Colors.white,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: HomeUi.subtitle(isDark).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: HomeUi.control(isDark).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveSparkline extends StatefulWidget {
  const _InteractiveSparkline({
    required this.isDark,
    required this.values,
    required this.dates,
    required this.lineColor,
    required this.fillColor,
  });

  final bool isDark;
  final List<double> values;
  final List<DateTime> dates;
  final Color lineColor;
  final Color fillColor;

  @override
  State<_InteractiveSparkline> createState() => _InteractiveSparklineState();
}

class _InteractiveSparklineState extends State<_InteractiveSparkline> {
  int? _hoverIndex;
  bool _hoverUpdateScheduled = false;
  int? _pendingHoverIndex;

  void _scheduleHoverIndex(int? next) {
    if (next == _hoverIndex && _pendingHoverIndex == null) return;
    if (next == _pendingHoverIndex) return;
    _pendingHoverIndex = next;
    if (_hoverUpdateScheduled) return;
    _hoverUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hoverUpdateScheduled = false;
      if (!mounted) return;
      final pending = _pendingHoverIndex;
      _pendingHoverIndex = null;
      if (pending == _hoverIndex) return;
      setState(() => _hoverIndex = pending);
    });
  }

  void _updateHover(Offset local, Size size) {
    final values = widget.values;
    if (values.length < 2 || size.width <= 0) return;
    final last = values.length - 1;
    final t = (local.dx / size.width).clamp(0.0, 1.0);
    final next = (t * last).round().clamp(0, last);
    _scheduleHoverIndex(next);
  }

  void _clearHover() => _scheduleHoverIndex(null);

  String _formatDate(int index) {
    if (index < 0 || index >= widget.dates.length) return 'Point ${index + 1}';
    return DateFormat('dd MMM yyyy').format(widget.dates[index]);
  }

  String _formatChange(int index) {
    final values = widget.values;
    if (values.isEmpty || index < 0 || index >= values.length) return '—';
    final base = values.first;
    if (base <= 0) return values[index].toStringAsFixed(2);
    final change = (values[index] / base - 1) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final hover = _hoverIndex;
    final tipChange = hover == null ? null : _formatChange(hover);
    final tipDate = hover == null ? null : _formatDate(hover);
    final tipPositive = hover != null &&
        values.isNotEmpty &&
        values.first > 0 &&
        values[hover] >= values.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          opaque: false,
          cursor: SystemMouseCursors.precise,
          onHover: (event) => _updateHover(event.localPosition, size),
          onExit: (_) => _clearHover(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SparklinePainter(
                    values: values,
                    lineColor: widget.lineColor,
                    fillColor: widget.fillColor,
                    strokeWidth: 2.4,
                    hoverIndex: hover,
                    isDark: widget.isDark,
                  ),
                ),
              ),
              if (hover != null && tipDate != null && tipChange != null)
                _SparklineTooltip(
                  isDark: widget.isDark,
                  dateLabel: tipDate,
                  changeLabel: tipChange,
                  positive: tipPositive,
                  chartSize: size,
                  hoverIndex: hover,
                  pointCount: values.length,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SparklineTooltip extends StatelessWidget {
  const _SparklineTooltip({
    required this.isDark,
    required this.dateLabel,
    required this.changeLabel,
    required this.positive,
    required this.chartSize,
    required this.hoverIndex,
    required this.pointCount,
  });

  final bool isDark;
  final String dateLabel;
  final String changeLabel;
  final bool positive;
  final Size chartSize;
  final int hoverIndex;
  final int pointCount;

  @override
  Widget build(BuildContext context) {
    final last = math.max(1, pointCount - 1);
    final x = chartSize.width * (hoverIndex / last);
    const tipWidth = 128.0;
    final left = (x - tipWidth / 2).clamp(0.0, chartSize.width - tipWidth);

    return Positioned(
      left: left,
      top: 0,
      child: IgnorePointer(
        child: Container(
          width: tipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D28) : Colors.white,
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(color: HomeUi.borderLight(isDark)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateLabel,
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                changeLabel,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontFamilyFallback: Constants.FONT_FALLBACK,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: positive
                      ? HomeUi.positive(isDark)
                      : HomeUi.negative(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    this.strokeWidth = 2,
    this.hoverIndex,
    this.isDark = false,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;
  final int? hoverIndex;
  final bool isDark;

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
    const padY = 4.0;
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
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );

    final end = pointAt(last);
    canvas.drawCircle(
      end,
      strokeWidth + 1.5,
      Paint()..color = lineColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      end,
      strokeWidth * 0.7,
      Paint()..color = lineColor,
    );

    final hover = hoverIndex;
    if (hover == null || hover < 0 || hover > last) return;

    final p = pointAt(hover);
    final guide = Paint()
      ..color = lineColor.withValues(alpha: isDark ? 0.35 : 0.28)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dash = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(p.dx, y), Offset(p.dx, math.min(y + dash, size.height)), guide);
      y += dash * 2;
    }

    canvas.drawCircle(
      p,
      strokeWidth + 3.5,
      Paint()..color = lineColor.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      p,
      strokeWidth + 1.2,
      Paint()
        ..color = isDark ? const Color(0xFF12151F) : Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      p,
      strokeWidth * 0.85,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.isDark != isDark;
  }
}
