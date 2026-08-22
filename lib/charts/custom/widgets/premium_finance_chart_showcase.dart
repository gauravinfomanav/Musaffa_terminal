import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_finance_extra_charts.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_allocation_donut.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_timeline_process_charts.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_stock_gui_chart.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Pure chart showcase — US institutional fintech visual language, static data.
class PremiumFinanceChartShowcase extends StatefulWidget {
  const PremiumFinanceChartShowcase({
    super.key,
    this.includeHero = true,
  });

  /// When false, the static hero price chart is omitted (e.g. live chart above).
  final bool includeHero;

  @override
  State<PremiumFinanceChartShowcase> createState() =>
      _PremiumFinanceChartShowcaseState();
}

class _PremiumFinanceChartShowcaseState extends State<PremiumFinanceChartShowcase> {
  int _priceRangeIndex = 5; // 1Y default
  static const List<String> _ranges = <String>[
    '1D', '1W', '1M', '3M', '6M', 'YTD', '1Y', '5Y', 'All',
  ];

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final bool wide = w >= 1100;
        final bool medium = w >= 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.includeHero) ...<Widget>[
              _HeroPriceChart(
                dark: dark,
                rangeIndex: _priceRangeIndex,
                ranges: _ranges,
                onRangeChanged: (int i) => setState(() => _priceRangeIndex = i),
              ),
              const SizedBox(height: 14),
            ],
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: _CandleVolumeChart(dark: dark)),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: _PerformanceHeatmapChart(dark: dark)),
                ],
              )
            else ...<Widget>[
              _CandleVolumeChart(dark: dark),
              const SizedBox(height: 14),
              _PerformanceHeatmapChart(dark: dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _AllocationDonutChart(dark: dark)),
                  const SizedBox(width: 14),
                  Expanded(child: _SectorRankingChart(dark: dark)),
                ],
              )
            else ...<Widget>[
              _AllocationDonutChart(dark: dark),
              const SizedBox(height: 14),
              _SectorRankingChart(dark: dark),
            ],
            const SizedBox(height: 14),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _BenchmarkComparisonChart(dark: dark)),
                  const SizedBox(width: 14),
                  Expanded(child: _EarningsSurprisePulseChart(dark: dark)),
                ],
              )
            else ...<Widget>[
              _BenchmarkComparisonChart(dark: dark),
              const SizedBox(height: 14),
              _EarningsSurprisePulseChart(dark: dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _RevenueProfitStackedChart(dark: dark)),
                  const SizedBox(width: 14),
                  Expanded(child: _DividendAreaChart(dark: dark)),
                ],
              )
            else ...<Widget>[
              _RevenueProfitStackedChart(dark: dark),
              const SizedBox(height: 14),
              _DividendAreaChart(dark: dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: PremiumFinanceExtraCharts.range52Week(dark)),
                  const SizedBox(width: 14),
                  Expanded(child: PremiumFinanceExtraCharts.sunburstChart(dark)),
                ],
              )
            else ...<Widget>[
              PremiumFinanceExtraCharts.range52Week(dark),
              const SizedBox(height: 14),
              PremiumFinanceExtraCharts.sunburstChart(dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: PremiumFinanceExtraCharts.marginTrend(dark)),
                  const SizedBox(width: 14),
                  Expanded(child: PremiumFinanceExtraCharts.valuationMultiples(dark)),
                ],
              )
            else ...<Widget>[
              PremiumFinanceExtraCharts.marginTrend(dark),
              const SizedBox(height: 14),
              PremiumFinanceExtraCharts.valuationMultiples(dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: PremiumFinanceExtraCharts.cashFlowStack(dark)),
                  const SizedBox(width: 14),
                  Expanded(child: PremiumFinanceExtraCharts.epsSurprise(dark)),
                ],
              )
            else ...<Widget>[
              PremiumFinanceExtraCharts.cashFlowStack(dark),
              const SizedBox(height: 14),
              PremiumFinanceExtraCharts.epsSurprise(dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: PremiumFinanceExtraCharts.geographicRevenue(dark)),
                  const SizedBox(width: 14),
                  Expanded(child: PremiumFinanceExtraCharts.correlationMatrix(dark)),
                ],
              )
            else ...<Widget>[
              PremiumFinanceExtraCharts.geographicRevenue(dark),
              const SizedBox(height: 14),
              PremiumFinanceExtraCharts.correlationMatrix(dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: PremiumFinanceExtraCharts.volumePriceCombo(dark)),
                  const SizedBox(width: 14),
                  Expanded(child: PremiumFinanceExtraCharts.tornadoChart(dark)),
                ],
              )
            else ...<Widget>[
              PremiumFinanceExtraCharts.volumePriceCombo(dark),
              const SizedBox(height: 14),
              PremiumFinanceExtraCharts.tornadoChart(dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _AnalystPriceTargetsChart(dark: dark)),
                  const SizedBox(width: 14),
                  Expanded(child: _AnalystRecommendationsChart(dark: dark)),
                ],
              )
            else ...<Widget>[
              _AnalystPriceTargetsChart(dark: dark),
              const SizedBox(height: 14),
              _AnalystRecommendationsChart(dark: dark),
            ],
            const SizedBox(height: 14),
            if (medium)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: PremiumTimelineProcessCharts.scrollableChart(dark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PremiumTimelineProcessCharts.realTimeChart(dark),
                  ),
                ],
              )
            else ...<Widget>[
              PremiumTimelineProcessCharts.scrollableChart(dark),
              const SizedBox(height: 14),
              PremiumTimelineProcessCharts.realTimeChart(dark),
            ],
            const SizedBox(height: 14),
            PremiumStockGuiChart(dark: dark),
          ],
        );
      },
    );
  }
}

// ─── Shared shell ───────────────────────────────────────────────────────────

class _ChartShell extends StatelessWidget {
  const _ChartShell({
    required this.dark,
    required this.caption,
    required this.height,
    required this.child,
  });

  final bool dark;
  final String caption;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UsPremiumPalette.border(dark)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            caption,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: UsPremiumPalette.muted(dark),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

TextStyle _axisStyle(bool dark, {double size = 10}) => TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: UsPremiumPalette.muted(dark),
    );

Widget _tooltip(bool dark, String title, String body) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UsPremiumPalette.border(dark)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 10,
                color: UsPremiumPalette.muted(dark),
              )),
          const SizedBox(height: 4),
          Text(body,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: UsPremiumPalette.text(dark),
              )),
        ],
      ),
    );

TooltipBehavior _sfTooltip(bool dark, Widget Function(dynamic data) builder) =>
    TooltipBehavior(
      enable: true,
      color: Colors.transparent,
      borderColor: Colors.transparent,
      elevation: 0,
      builder: (dynamic data, _, __, ___, ____) => builder(data),
    );

TrackballBehavior _trackball(
  bool dark,
  Widget Function(TrackballDetails details) builder,
) {
  final UsPremiumChartColors c = chartColors(dark);
  return TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
    lineType: TrackballLineType.vertical,
    tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
    lineColor: c.crosshair,
    markerSettings: TrackballMarkerSettings(
      color: c.trackballMarker,
      borderColor: UsPremiumPalette.surface(dark),
      borderWidth: 2,
      height: 7,
      width: 7,
    ),
    builder: (_, TrackballDetails details) => builder(details),
  );
}

List<OhlcCandlePoint> _sliceHistory(int rangeIndex) {
  final List<OhlcCandlePoint> all = StaticPremiumChartData.priceHistory;
  if (all.isEmpty) return all;
  final int days = switch (rangeIndex) {
    0 => 1,
    1 => 7,
    2 => 22,
    3 => 66,
    4 => 132,
    5 => DateTime.now().difference(DateTime(DateTime.now().year)).inDays,
    6 => 252,
    7 => 252 * 5,
    _ => all.length,
  };
  return all.length <= days ? all : all.sublist(all.length - days);
}

// ─── 1. Hero area price chart ───────────────────────────────────────────────

class _HeroPriceChart extends StatelessWidget {
  const _HeroPriceChart({
    required this.dark,
    required this.rangeIndex,
    required this.ranges,
    required this.onRangeChanged,
  });

  final bool dark;
  final int rangeIndex;
  final List<String> ranges;
  final ValueChanged<int> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final List<OhlcCandlePoint> data = _sliceHistory(rangeIndex);
    final double price = StaticPremiumChartData.currentPrice;
    final double chg = StaticPremiumChartData.changePct;
    final bool up = chg >= 0;
    final UsPremiumChartColors c = chartColors(dark);

    return Container(
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UsPremiumPalette.border(dark)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                StaticPremiumChartData.symbol,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: UsPremiumPalette.muted(dark),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.5,
                  color: UsPremiumPalette.text(dark),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${up ? '+' : ''}${chg.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: up ? UsPremiumPalette.gain : UsPremiumPalette.loss,
                ),
              ),
              const Spacer(),
              Text(
                StaticPremiumChartData.company,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 12,
                  color: UsPremiumPalette.muted(dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List<Widget>.generate(ranges.length, (int i) {
              final bool sel = i == rangeIndex;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onRangeChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? c.pillSelected : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: sel ? c.pillBorder : UsPremiumPalette.border(dark),
                      ),
                    ),
                    child: Text(
                      ranges[i],
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                        color: sel
                            ? UsPremiumPalette.electricBlueSoft
                            : UsPremiumPalette.muted(dark),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: EdgeInsets.zero,
              crosshairBehavior: CrosshairBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                lineType: CrosshairLineType.both,
                lineColor: c.crosshair,
                lineWidth: 1,
              ),
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                lineType: TrackballLineType.vertical,
                lineColor: c.crosshair,
                markerSettings: TrackballMarkerSettings(
                  color: c.trackballMarker,
                  borderColor: UsPremiumPalette.surface(dark),
                  borderWidth: 2,
                  height: 7,
                  width: 7,
                ),
                builder: (_, TrackballDetails d) {
                  final dynamic x = d.point?.x;
                  final dynamic y = d.point?.y;
                  if (x is! DateTime || y is! num) return const SizedBox.shrink();
                  return _tooltip(
                    dark,
                    DateFormat('MMM d, yyyy').format(x),
                    '\$${y.toStringAsFixed(2)}',
                  );
                },
              ),
              primaryXAxis: DateTimeAxis(
                majorGridLines: MajorGridLines(
                  width: 0.5,
                  color: UsPremiumPalette.grid(dark),
                ),
                axisLine: AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: _axisStyle(dark),
                dateFormat: DateFormat('MMM d'),
              ),
              primaryYAxis: NumericAxis(
                opposedPosition: true,
                majorGridLines: MajorGridLines(
                  width: 0.5,
                  color: UsPremiumPalette.grid(dark),
                ),
                axisLine: AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: _axisStyle(dark),
                numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
              ),
              series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                SplineAreaSeries<OhlcCandlePoint, DateTime>(
                  dataSource: data,
                  xValueMapper: (OhlcCandlePoint p, _) => p.date,
                  yValueMapper: (OhlcCandlePoint p, _) => p.close,
                  borderWidth: 1.5,
                  borderColor: c.priceLine,
                  splineType: SplineType.cardinal,
                  cardinalSplineTension: 0.18,
                  markerSettings: const MarkerSettings(isVisible: false),
                  gradient: c.priceAreaFill,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Candlestick + volume ────────────────────────────────────────────────

class _CandleVolumeChart extends StatelessWidget {
  const _CandleVolumeChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final List<OhlcCandlePoint> data =
        StaticPremiumChartData.last30Days;
    final UsPremiumChartColors c = chartColors(dark);

    return _ChartShell(
      dark: dark,
      caption: 'CANDLESTICK · 30D',
      height: 340,
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: EdgeInsets.zero,
              trackballBehavior: _trackball(dark, (TrackballDetails d) {
                final dynamic x = d.point?.x;
                final dynamic y = d.point?.y;
                if (x is! DateTime || y is! num) return const SizedBox.shrink();
                OhlcCandlePoint? candle;
                for (final OhlcCandlePoint p in data) {
                  if (p.date == x) {
                    candle = p;
                    break;
                  }
                }
                if (candle == null) return const SizedBox.shrink();
                return _tooltip(
                  dark,
                  DateFormat('MMM d, yyyy').format(candle.date),
                  'O \$${candle.open.toStringAsFixed(2)}  H \$${candle.high.toStringAsFixed(2)}\n'
                  'L \$${candle.low.toStringAsFixed(2)}  C \$${candle.close.toStringAsFixed(2)}',
                );
              }),
              primaryXAxis: DateTimeAxis(isVisible: false),
              primaryYAxis: NumericAxis(
                opposedPosition: true,
                majorGridLines: MajorGridLines(
                  width: 0.5,
                  color: UsPremiumPalette.grid(dark),
                ),
                axisLine: AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: _axisStyle(dark),
                numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
              ),
              series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                CandleSeries<OhlcCandlePoint, DateTime>(
                  dataSource: data,
                  xValueMapper: (OhlcCandlePoint p, _) => p.date,
                  lowValueMapper: (OhlcCandlePoint p, _) => p.low,
                  highValueMapper: (OhlcCandlePoint p, _) => p.high,
                  openValueMapper: (OhlcCandlePoint p, _) => p.open,
                  closeValueMapper: (OhlcCandlePoint p, _) => p.close,
                  bullColor: c.candleBull,
                  bearColor: c.candleBear,
                  spacing: 0.3,
                  width: 0.65,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: EdgeInsets.zero,
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: _axisStyle(dark, size: 9),
                dateFormat: DateFormat('MMM d'),
              ),
              primaryYAxis: NumericAxis(
                isVisible: false,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                ColumnSeries<OhlcCandlePoint, DateTime>(
                  dataSource: data,
                  xValueMapper: (OhlcCandlePoint p, _) => p.date,
                  yValueMapper: (OhlcCandlePoint p, _) => p.volume,
                  pointColorMapper: (OhlcCandlePoint p, _) =>
                      c.volumeBar(p.isUp),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(1)),
                  spacing: 0.3,
                  width: 0.65,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3. Performance heatmap ───────────────────────────────────────────────────

class _PerformanceHeatmapChart extends StatefulWidget {
  const _PerformanceHeatmapChart({required this.dark});
  final bool dark;

  @override
  State<_PerformanceHeatmapChart> createState() =>
      _PerformanceHeatmapChartState();
}

class _PerformanceHeatmapChartState extends State<_PerformanceHeatmapChart> {
  int? _hoveredIndex;
  Offset? _hoveredOffset;

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final UsPremiumChartColors c = chartColors(dark);
    final entries = StaticPremiumChartData.performanceReturns.entries.toList();

    return _ChartShell(
      dark: dark,
      caption: 'PERFORMANCE HEATMAP',
      height: 340,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const int columns = 3;
          const double gap = 6;
          final int rows = (entries.length / columns).ceil();
          final double tileWidth = (constraints.maxWidth - ((columns - 1) * gap)) / columns;
          final double tileHeight = (constraints.maxHeight - ((rows - 1) * gap)) / rows;
          final double ratio = tileWidth / tileHeight;

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  childAspectRatio: ratio,
                ),
                itemCount: entries.length,
                itemBuilder: (_, int i) {
                  final String period = entries[i].key;
                  final double v = entries[i].value;
                  final bool pos = v >= 0;
                  final Color tone = pos ? UsPremiumPalette.gain : UsPremiumPalette.loss;
                  final double intensity = (v.abs() / 25).clamp(0.12, 1.0);
                  final bool hovered = _hoveredIndex == i;
                  final Color fill =
                      pos ? c.heatmapPositive(intensity) : c.heatmapNegative(intensity);
                  return MouseRegion(
                    onEnter: (PointerEnterEvent event) => setState(() {
                      _hoveredIndex = i;
                      _hoveredOffset = event.localPosition;
                    }),
                    onHover: (PointerHoverEvent event) => setState(() {
                      _hoveredIndex = i;
                      _hoveredOffset = event.localPosition;
                    }),
                    onExit: (_) => setState(() {
                      _hoveredIndex = null;
                      _hoveredOffset = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hovered
                              ? tone.withValues(alpha: 0.55)
                              : tone.withValues(alpha: 0.18),
                          width: hovered ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(period,
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: tone,
                              )),
                          const SizedBox(height: 3),
                          Text(
                            '${pos ? '+' : ''}${v.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: UsPremiumPalette.text(dark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_hoveredIndex != null)
                Positioned(
                  left: ((_hoveredOffset?.dx ?? 0) + 12).clamp(0.0, 180.0),
                  top: ((_hoveredOffset?.dy ?? 0) - 42).clamp(0.0, 220.0),
                  child: _tooltip(
                    dark,
                    entries[_hoveredIndex!].key,
                    '${entries[_hoveredIndex!].value >= 0 ? '+' : ''}'
                    '${entries[_hoveredIndex!].value.toStringAsFixed(2)}% return',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── 4. Donut allocation ──────────────────────────────────────────────────────

class _AllocationDonutChart extends StatelessWidget {
  const _AllocationDonutChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return _ChartShell(
      dark: dark,
      caption: 'PORTFOLIO ALLOCATION',
      height: 300,
      child: PremiumAllocationDonut(
        dark: dark,
        slices: StaticPremiumChartData.portfolioAllocation,
        centerValue: '\$4.82B',
        centerLabel: 'Total AUM',
      ),
    );
  }
}

// ─── 5. Horizontal sector ranking ───────────────────────────────────────────

class _SectorRankingChart extends StatelessWidget {
  const _SectorRankingChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final items = StaticPremiumChartData.sectorRanking;
    final UsPremiumChartColors c = chartColors(dark);

    return _ChartShell(
      dark: dark,
      caption: 'SECTOR ALLOCATION · RANKED',
      height: 300,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        isTransposed: true,
        tooltipBehavior: _sfTooltip(dark, (dynamic data) {
          if (data is! StaticBarItem) return const SizedBox.shrink();
          return _tooltip(
            dark,
            data.label,
            '${data.value.toStringAsFixed(1)}% of portfolio',
          );
        }),
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: _axisStyle(dark),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: UsPremiumPalette.grid(dark),
          ),
          axisLine: AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: _axisStyle(dark),
          axisLabelFormatter: (AxisLabelRenderDetails details) {
            return ChartAxisLabel(
              '${details.value.toStringAsFixed(0)}%',
              details.textStyle,
            );
          },
        ),
        series: <CartesianSeries<StaticBarItem, String>>[
          BarSeries<StaticBarItem, String>(
            dataSource: items,
            xValueMapper: (StaticBarItem i, _) => i.label,
            yValueMapper: (StaticBarItem i, _) => i.value,
            borderRadius: BorderRadius.circular(3),
            pointColorMapper: (StaticBarItem i, int idx) => c.seriesAt(idx),
            width: 0.55,
          ),
        ],
      ),
    );
  }
}

// ─── 6. Benchmark comparison ────────────────────────────────────────────────

class _BenchmarkComparisonChart extends StatelessWidget {
  const _BenchmarkComparisonChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final data = StaticPremiumChartData.benchmarkComparison;
    final UsPremiumChartColors c = chartColors(dark);

    return _ChartShell(
      dark: dark,
      caption: 'STOCK VS S&P 500 · NORMALIZED',
      height: 300,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        tooltipBehavior: TooltipBehavior(
          enable: true,
          shared: true,
          color: UsPremiumPalette.surface(dark),
          borderColor: UsPremiumPalette.border(dark),
          borderWidth: 1,
          elevation: 10,
          header: '',
          textStyle: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: UsPremiumPalette.text(dark),
          ),
        ),
        primaryXAxis: DateTimeAxis(
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: UsPremiumPalette.grid(dark),
          ),
          axisLine: AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: _axisStyle(dark),
          dateFormat: DateFormat('MMM d'),
        ),
        primaryYAxis: NumericAxis(
          opposedPosition: true,
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: UsPremiumPalette.grid(dark),
          ),
          axisLine: AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: _axisStyle(dark),
        ),
        series: <CartesianSeries<StaticLinePoint, DateTime>>[
          SplineSeries<StaticLinePoint, DateTime>(
            name: StaticPremiumChartData.symbol,
            dataSource: data,
            xValueMapper: (StaticLinePoint p, _) => p.date,
            yValueMapper: (StaticLinePoint p, _) => p.stock,
            color: c.benchmarkPrimary,
            width: 1.8,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
          SplineSeries<StaticLinePoint, DateTime>(
            name: 'S&P 500',
            dataSource: data,
            xValueMapper: (StaticLinePoint p, _) => p.date,
            yValueMapper: (StaticLinePoint p, _) => p.benchmark,
            color: c.benchmarkSecondary,
            width: 1.5,
            dashArray: const <double>[5, 4],
            markerSettings: const MarkerSettings(isVisible: false),
          ),
        ],
      ),
    );
  }
}

// ─── 7. Risk / return scatter ───────────────────────────────────────────────

class _EarningsSurprisePulseChart extends StatefulWidget {
  const _EarningsSurprisePulseChart({required this.dark});
  final bool dark;

  @override
  State<_EarningsSurprisePulseChart> createState() =>
      _EarningsSurprisePulseChartState();
}

class _EarningsSurprisePulseChartState extends State<_EarningsSurprisePulseChart> {
  int _hoveredIndex = 2;

  @override
  Widget build(BuildContext context) {
    final List<StaticEarningsSurprisePoint> points =
        StaticPremiumChartData.earningsSurpriseTrend;
    final bool dark = widget.dark;
    final UsPremiumChartColors c = chartColors(dark);
    final StaticEarningsSurprisePoint active = points[_hoveredIndex];

    return _ChartShell(
      dark: dark,
      caption: 'EARNINGS ESTIMATE · SURPRISE',
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.priceLine.withValues(alpha: dark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.priceLine.withValues(alpha: 0.22)),
                ),
                child: Text(
                  active.label,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: UsPremiumPalette.text(dark),
                  ),
                ),
              ),
              _metricBadge(
                dark,
                label: 'Estimate',
                value: '\$${active.estimate.toStringAsFixed(2)}',
                color: UsPremiumPalette.cyanAccent,
                outlined: true,
              ),
              if (active.actual != null)
                _metricBadge(
                  dark,
                  label: active.beat == true ? 'Beat' : 'Missed',
                  value: '\$${active.actual!.toStringAsFixed(2)}',
                  color: active.beat == true
                      ? const Color(0xFF0D9373)
                      : const Color(0xFFC45B5B),
                ),
              if (active.actual != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: (active.beat == true
                            ? const Color(0xFF0D9373)
                            : const Color(0xFFC45B5B))
                        .withValues(alpha: dark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    active.deltaLabel,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active.beat == true
                          ? const Color(0xFF0D9373)
                          : const Color(0xFFC45B5B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Stack(
                  children: <Widget>[
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _EarningsSurprisePainter(
                        dark: dark,
                        colors: c,
                        points: points,
                        hoveredIndex: _hoveredIndex,
                      ),
                    ),
                    Row(
                      children: List<Widget>.generate(points.length, (int index) {
                        return Expanded(
                          child: MouseRegion(
                            opaque: false,
                            onEnter: (_) => setState(() => _hoveredIndex = index),
                            onHover: (_) => setState(() => _hoveredIndex = index),
                            child: const SizedBox.expand(),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double leftPad = 38;
                final double chartWidth = constraints.maxWidth - leftPad;
                final double stepX = chartWidth / (points.length + 0.15);

                return Stack(
                  clipBehavior: Clip.none,
                  children: List<Widget>.generate(points.length, (int index) {
                    final StaticEarningsSurprisePoint point = points[index];
                    final bool future = point.actual == null;
                    final Color valueColor = future
                        ? UsPremiumPalette.text(dark).withValues(alpha: 0.6)
                        : point.beat == true
                            ? const Color(0xFF0D9373)
                            : const Color(0xFFC45B5B);
                    final double centerX = leftPad + stepX * (index + 0.5);

                    return Positioned(
                      left: centerX - 38,
                      width: 76,
                      child: Column(
                        children: <Widget>[
                          Text(
                            point.label,
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 10,
                              fontWeight: _hoveredIndex == index ? FontWeight.w700 : FontWeight.w500,
                              color: _hoveredIndex == index
                                  ? UsPremiumPalette.text(dark)
                                  : UsPremiumPalette.text(dark).withValues(alpha: 0.55),
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            future ? point.dateLabel : (point.beat! ? '▲ Beat' : '▼ Miss'),
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: valueColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!future)
                            Text(
                              point.deltaLabel,
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: valueColor.withValues(alpha: 0.75),
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsSurprisePainter extends CustomPainter {
  _EarningsSurprisePainter({
    required this.dark,
    required this.colors,
    required this.points,
    required this.hoveredIndex,
  });

  final bool dark;
  final UsPremiumChartColors colors;
  final List<StaticEarningsSurprisePoint> points;
  final int hoveredIndex;

  static const List<double> _ticks = <double>[1.45, 1.50, 1.55, 1.60, 1.65, 1.70];
  static const double _minY = 1.42;
  static const double _maxY = 1.72;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 38;
    const double topPad = 12;
    const double bottomPad = 8;
    final double chartWidth = size.width - leftPad;
    final double chartHeight = size.height - topPad - bottomPad;
    final double stepX = chartWidth / (points.length + 0.15);

    for (final double tick in _ticks) {
      final double y = _mapY(tick, chartHeight, topPad);
      _drawDashedLine(
        canvas,
        from: Offset(leftPad, y),
        to: Offset(size.width, y),
        color: UsPremiumPalette.grid(dark).withValues(alpha: dark ? 0.65 : 0.80),
      );
      _paintText(
        canvas,
        tick.toStringAsFixed(2),
        Offset(0, y - 8),
        TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: UsPremiumPalette.text(dark).withValues(alpha: 0.50),
        ),
      );
    }

    final StaticEarningsSurprisePoint active = points[hoveredIndex];
    final double activeX = leftPad + stepX * (hoveredIndex + 0.5);
    final double activeY = _mapY(
      active.beat == false ? active.estimate : (active.actual ?? active.estimate),
      chartHeight,
      topPad,
    );
    _drawDashedLine(
      canvas,
      from: Offset(activeX, topPad),
      to: Offset(activeX, topPad + chartHeight),
      color: UsPremiumPalette.cyanAccent.withValues(alpha: 0.40),
    );
    _drawDashedLine(
      canvas,
      from: Offset(leftPad, activeY),
      to: Offset(size.width, activeY),
      color: UsPremiumPalette.cyanAccent.withValues(alpha: 0.40),
    );

    for (int i = 0; i < points.length; i++) {
      final StaticEarningsSurprisePoint point = points[i];
      final double x = leftPad + stepX * (i + 0.5);
      final double estimateY = _mapY(point.estimate, chartHeight, topPad);
      _drawEstimateDot(canvas, Offset(x, estimateY));
      if (point.actual != null) {
        final double actualY = point.beat == false
            ? _mapY(1.45, chartHeight, topPad)
            : _mapY(point.actual!, chartHeight, topPad);
        _drawActualDot(
          canvas,
          Offset(x, actualY),
          point.beat == true ? colors.gainColor : colors.lossColor,
        );
      }
    }
  }

  double _mapY(double value, double chartHeight, double topPad) {
    final double t = ((value - _minY) / (_maxY - _minY)).clamp(0.0, 1.0);
    return topPad + chartHeight - (t * chartHeight);
  }

  void _drawEstimateDot(Canvas canvas, Offset center) {
    final Color ringColor = dark
        ? const Color(0xFF9AA4AF)
        : const Color(0xFFB6BEC7);
    canvas.drawCircle(
      center,
      11,
      Paint()..color = ringColor.withValues(alpha: dark ? 0.14 : 0.10),
    );
    canvas.drawCircle(center, 8.5, Paint()..color = UsPremiumPalette.surface(dark));
    canvas.drawCircle(
      center,
      8.5,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _drawActualDot(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(
      center,
      13,
      Paint()..color = color.withValues(alpha: dark ? 0.16 : 0.10),
    );
    canvas.drawCircle(center, 9, Paint()..color = color);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawDashedLine(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required Color color,
  }) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final bool horizontal = from.dy == to.dy;
    double cursor = horizontal ? from.dx : from.dy;
    final double end = horizontal ? to.dx : to.dy;
    while (cursor < end) {
      if (horizontal) {
        canvas.drawLine(
          Offset(cursor, from.dy),
          Offset((cursor + 4).clamp(from.dx, to.dx), from.dy),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(from.dx, cursor),
          Offset(from.dx, (cursor + 4).clamp(from.dy, to.dy)),
          paint,
        );
      }
      cursor += 7;
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _EarningsSurprisePainter oldDelegate) =>
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.dark != dark ||
      oldDelegate.points != points;
}

// ─── 8. Stacked revenue / profit ──────────────────────────────────────────────

class _RevenueProfitStackedChart extends StatelessWidget {
  const _RevenueProfitStackedChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final q = StaticPremiumChartData.quarterlyRevenue;
    final UsPremiumChartColors c = chartColors(dark);

    return _ChartShell(
      dark: dark,
      caption: 'REVENUE VS PROFIT · QUARTERLY',
      height: 280,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          labelStyle: _axisStyle(dark),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: UsPremiumPalette.grid(dark),
          ),
          axisLine: AxisLine(width: 0),
          labelStyle: _axisStyle(dark),
          numberFormat: NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 1),
        ),
        series: <CartesianSeries<StaticQuarterRevenue, String>>[
          ColumnSeries<StaticQuarterRevenue, String>(
            name: 'Revenue',
            dataSource: q,
            xValueMapper: (StaticQuarterRevenue r, _) => r.quarter,
            yValueMapper: (StaticQuarterRevenue r, _) => r.revenue,
            color: c.revenueBar,
            borderRadius: BorderRadius.circular(4),
            width: 0.42,
            spacing: 0.12,
          ),
          ColumnSeries<StaticQuarterRevenue, String>(
            name: 'Net Profit',
            dataSource: q,
            xValueMapper: (StaticQuarterRevenue r, _) => r.quarter,
            yValueMapper: (StaticQuarterRevenue r, _) => r.profit,
            color: c.profitBar,
            borderRadius: BorderRadius.circular(4),
            width: 0.42,
            spacing: 0.12,
          ),
        ],
      ),
    );
  }
}

// ─── 9. Dividend area ─────────────────────────────────────────────────────────

class _DividendAreaChart extends StatelessWidget {
  const _DividendAreaChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final divs = StaticPremiumChartData.dividendHistory;
    final UsPremiumChartColors c = chartColors(dark);

    return _ChartShell(
      dark: dark,
      caption: 'DIVIDEND GROWTH',
      height: 280,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        trackballBehavior: _trackball(dark, (TrackballDetails d) {
          final dynamic x = d.point?.x;
          final dynamic y = d.point?.y;
          if (x is! DateTime || y is! num) return const SizedBox.shrink();
          return _tooltip(
            dark,
            DateFormat('MMM yyyy').format(x),
            'Dividend  \$${y.toStringAsFixed(4)}',
          );
        }),
        primaryXAxis: DateTimeAxis(
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: UsPremiumPalette.grid(dark),
          ),
          axisLine: AxisLine(width: 0),
          labelStyle: _axisStyle(dark),
          dateFormat: DateFormat('MMM yy'),
        ),
        primaryYAxis: NumericAxis(
          opposedPosition: true,
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: UsPremiumPalette.grid(dark),
          ),
          axisLine: AxisLine(width: 0),
          labelStyle: _axisStyle(dark),
          numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 3),
        ),
        series: <CartesianSeries<StaticDividendPoint, DateTime>>[
          SplineAreaSeries<StaticDividendPoint, DateTime>(
            dataSource: divs,
            xValueMapper: (StaticDividendPoint p, _) => p.date,
            yValueMapper: (StaticDividendPoint p, _) => p.amount,
            borderWidth: 1.5,
            borderColor: c.dividendLine,
            color: c.dividendFill.colors.first,
            gradient: c.dividendFill,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
        ],
      ),
    );
  }
}

// ─── 10. Analyst stacked area ─────────────────────────────────────────────────

class _AnalystPriceTargetsChart extends StatelessWidget {
  const _AnalystPriceTargetsChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final StaticPriceTargetRange data = StaticPremiumChartData.analystPriceTarget;
    final UsPremiumChartColors c = chartColors(dark);

    const Color avgColor = Color(0xFF0D9373);
    const Color curColor = Color(0xFF4A6CF7);
    const double dotR = 11;
    const double calloutW = 82;
    const double calloutH = 44;
    const double lineH = 16;

    // Layout: avgCallout(44) + line(16) + barCenter + line(16) + curCallout(44) = ~140
    // Bar at vertical center ~100, Low/High at bar level
    const double barY = 68; // Y of bar center

    return _ChartShell(
      dark: dark,
      caption: 'ANALYST PRICE TARGETS',
      height: 260,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double avgCx = w * data.averagePosition;
          final double curCx = w * data.currentPosition;
          final double avgCalloutL =
              (avgCx - calloutW / 2).clamp(0.0, w - calloutW);
          final double curCalloutL =
              (curCx - calloutW / 2).clamp(0.0, w - calloutW);
          final Color barColor =
              dark ? const Color(0xFF3A3F47) : const Color(0xFFD8DCE2);

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // ── Bar line ──
              Positioned(
                left: 0,
                right: 0,
                top: barY - 2.5,
                height: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // ── Average dot ──
              Positioned(
                left: avgCx - dotR,
                top: barY - dotR,
                child: Container(
                  width: dotR * 2,
                  height: dotR * 2,
                  decoration: BoxDecoration(
                    color: avgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: UsPremiumPalette.surface(dark), width: 3),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: avgColor.withValues(alpha: 0.35), blurRadius: 8),
                    ],
                  ),
                ),
              ),
              // ── Current dot ──
              Positioned(
                left: curCx - dotR,
                top: barY - dotR,
                child: Container(
                  width: dotR * 2,
                  height: dotR * 2,
                  decoration: BoxDecoration(
                    color: curColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: UsPremiumPalette.surface(dark), width: 3),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: curColor.withValues(alpha: 0.35), blurRadius: 8),
                    ],
                  ),
                ),
              ),
              // ── Average connector (dot → up to callout) ──
              Positioned(
                left: avgCx - 0.5,
                top: barY - dotR - lineH,
                child: Container(width: 1, height: lineH, color: avgColor.withValues(alpha: 0.55)),
              ),
              // ── Average callout ──
              Positioned(
                left: avgCalloutL,
                top: barY - dotR - lineH - calloutH,
                child: _valueCallout(dark,
                    value: data.average.toStringAsFixed(2),
                    label: 'Average',
                    accent: avgColor),
              ),
              // ── Current connector (dot → down to callout) ──
              Positioned(
                left: curCx - 0.5,
                top: barY + dotR,
                child: Container(width: 1, height: lineH, color: curColor.withValues(alpha: 0.55)),
              ),
              // ── Current callout ──
              Positioned(
                left: curCalloutL,
                top: barY + dotR + lineH,
                child: _valueCallout(dark,
                    value: data.current.toStringAsFixed(2),
                    label: 'Current',
                    accent: curColor),
              ),
              // ── Low label ──
              Positioned(
                left: 0,
                top: barY + dotR + 4,
                child: _edgeValue(dark, data.low.toStringAsFixed(2), 'Low'),
              ),
              // ── High label ──
              Positioned(
                right: 0,
                top: barY + dotR + 4,
                child: _edgeValue(dark, data.high.toStringAsFixed(2), 'High', alignEnd: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalystRecommendationsChart extends StatelessWidget {
  const _AnalystRecommendationsChart({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final List<StaticRecommendationBar> data =
        StaticPremiumChartData.analystRecommendationBars;
    final UsPremiumChartColors c = chartColors(dark);

    return _ChartShell(
      dark: dark,
      caption: 'ANALYST RECOMMENDATIONS',
      height: 260,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: _axisStyle(dark),
        ),
        primaryYAxis: NumericAxis(
          maximum: 16,
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: UsPremiumPalette.grid(dark),
          ),
          axisLine: AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: _axisStyle(dark),
        ),
        tooltipBehavior: _sfTooltip(dark, (dynamic data) {
          if (data is! StaticRecommendationBar) return const SizedBox.shrink();
          return _tooltip(dark, data.month, '${data.total} analyst ratings');
        }),
        series: <CartesianSeries<StaticRecommendationBar, String>>[
          StackedColumnSeries<StaticRecommendationBar, String>(
            name: 'Strong Buy',
            dataSource: data,
            xValueMapper: (StaticRecommendationBar m, _) => m.month,
            yValueMapper: (StaticRecommendationBar m, _) => m.strongBuy,
            color: c.analystStrongBuy,
            width: 0.48,
          ),
          StackedColumnSeries<StaticRecommendationBar, String>(
            name: 'Buy',
            dataSource: data,
            xValueMapper: (StaticRecommendationBar m, _) => m.month,
            yValueMapper: (StaticRecommendationBar m, _) => m.buy,
            color: c.analystBuy,
            width: 0.48,
          ),
          StackedColumnSeries<StaticRecommendationBar, String>(
            name: 'Hold',
            dataSource: data,
            xValueMapper: (StaticRecommendationBar m, _) => m.month,
            yValueMapper: (StaticRecommendationBar m, _) => m.hold,
            color: c.analystHold,
            width: 0.48,
          ),
          StackedColumnSeries<StaticRecommendationBar, String>(
            name: 'Underperform',
            dataSource: data,
            xValueMapper: (StaticRecommendationBar m, _) => m.month,
            yValueMapper: (StaticRecommendationBar m, _) => m.underperform,
            color: const Color(0xFFE57B39),
            width: 0.48,
          ),
          StackedColumnSeries<StaticRecommendationBar, String>(
            name: 'Sell',
            dataSource: data,
            xValueMapper: (StaticRecommendationBar m, _) => m.month,
            yValueMapper: (StaticRecommendationBar m, _) => m.sell,
            color: c.analystStrongSell,
            width: 0.48,
          ),
          ScatterSeries<StaticRecommendationBar, String>(
            dataSource: data,
            xValueMapper: (StaticRecommendationBar m, _) => m.month,
            yValueMapper: (StaticRecommendationBar m, _) => m.total.toDouble(),
            color: Colors.transparent,
            markerSettings: const MarkerSettings(isVisible: false),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.outer,
              textStyle: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: UsPremiumPalette.text(dark),
              ),
            ),
            dataLabelMapper: (StaticRecommendationBar m, _) => '${m.total}',
          ),
        ],
      ),
    );
  }
}

Widget _valueCallout(
  bool dark, {
  required String value,
  required String label,
  required Color accent,
}) =>
    Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: UsPremiumPalette.text(dark),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: UsPremiumPalette.muted(dark),
            ),
          ),
        ],
      ),
    );

Widget _edgeValue(
  bool dark,
  String value,
  String label, {
  bool alignEnd = false,
}) =>
    Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: UsPremiumPalette.text(dark),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 10,
            color: UsPremiumPalette.muted(dark),
          ),
        ),
      ],
    );

Widget _metricBadge(
  bool dark, {
  required String label,
  required String value,
  required Color color,
  bool outlined = false,
}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: outlined
            ? UsPremiumPalette.surface(dark)
            : color.withValues(alpha: dark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: outlined ? UsPremiumPalette.surface(dark) : color,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.6),
            ),
          ),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: UsPremiumPalette.muted(dark),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
