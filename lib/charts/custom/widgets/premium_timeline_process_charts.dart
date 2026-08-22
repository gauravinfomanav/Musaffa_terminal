import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Scrollable and real-time chart demos for Custom Charts.
class PremiumTimelineProcessCharts {
  PremiumTimelineProcessCharts._();

  static Widget scrollableChart(bool dark) => _ChartShell(
        dark: dark,
        caption: 'SCROLLABLE · MONTHLY VOLUME · PAN',
        height: 300,
        child: const _ScrollableVolumeChart(),
      );

  static Widget realTimeChart(bool dark) => _ChartShell(
        dark: dark,
        caption: 'REAL TIME · LIVE TICK STREAM',
        height: 300,
        child: const _RealTimeLineChart(),
      );
}

// ─── Scrollable ─────────────────────────────────────────────────────────────

class _ScrollableVolumeChart extends StatelessWidget {
  const _ScrollableVolumeChart();

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticScrollPoint> data = StaticPremiumChartData.scrollableVolume;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        zoomMode: ZoomMode.x,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: UsPremiumPalette.surface(dark),
        borderColor: UsPremiumPalette.border(dark),
        borderWidth: 1,
        textStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      primaryXAxis: CategoryAxis(
        autoScrollingDelta: 12,
        autoScrollingMode: AutoScrollingMode.end,
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: _axis(dark),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
      ),
      series: <CartesianSeries<StaticScrollPoint, String>>[
        ColumnSeries<StaticScrollPoint, String>(
          dataSource: data,
          xValueMapper: (StaticScrollPoint p, _) => p.label,
          yValueMapper: (StaticScrollPoint p, _) => p.value,
          color: c.priceLine.withValues(alpha: dark ? 0.85 : 0.75),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          width: 0.72,
          animationDuration: 600,
        ),
      ],
    );
  }
}

// ─── Real time ──────────────────────────────────────────────────────────────

class _RealTimeLineChart extends StatefulWidget {
  const _RealTimeLineChart();

  @override
  State<_RealTimeLineChart> createState() => _RealTimeLineChartState();
}

class _RealTimeLineChartState extends State<_RealTimeLineChart> {
  late List<_TickPoint> _data;
  ChartSeriesController<_TickPoint, int>? _controller;
  Timer? _timer;
  int _count = 0;
  double _last = 100;

  @override
  void initState() {
    super.initState();
    _data = List<_TickPoint>.generate(18, (int i) {
      _last = 100 + math.sin(i / 2.4) * 8 + (i % 3) * 1.2;
      return _TickPoint(i, _last);
    });
    _count = _data.length;
    _timer = Timer.periodic(const Duration(milliseconds: 850), _onTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    final double next =
        (_last + (math.Random().nextDouble() - 0.48) * 4.2).clamp(78.0, 128.0);
    _last = next;
    _data.add(_TickPoint(_count, next));
    if (_data.length > 24) {
      _data.removeAt(0);
      _controller?.updateDataSource(
        addedDataIndexes: <int>[_data.length - 1],
        removedDataIndexes: <int>[0],
      );
    } else {
      _controller?.updateDataSource(
        addedDataIndexes: <int>[_data.length - 1],
      );
    }
    _count++;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final UsPremiumChartColors c = chartColors(dark);

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: UsPremiumPalette.surface(dark),
        borderColor: UsPremiumPalette.border(dark),
        borderWidth: 1,
        textStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      primaryXAxis: NumericAxis(
        isVisible: false,
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
      ),
      series: <CartesianSeries<_TickPoint, int>>[
        SplineAreaSeries<_TickPoint, int>(
          dataSource: _data,
          xValueMapper: (_TickPoint p, _) => p.x,
          yValueMapper: (_TickPoint p, _) => p.y,
          color: c.priceLine,
          borderColor: c.priceLine,
          borderWidth: 2,
          gradient: c.priceAreaFill,
          animationDuration: 0,
          onRendererCreated: (ChartSeriesController<_TickPoint, int> ctrl) {
            _controller = ctrl;
          },
        ),
      ],
    );
  }
}

class _TickPoint {
  const _TickPoint(this.x, this.y);
  final int x;
  final double y;
}

// ─── Shared ─────────────────────────────────────────────────────────────────

TextStyle _axis(bool dark, {double size = 10}) => TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: UsPremiumPalette.muted(dark),
    );

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
      clipBehavior: Clip.hardEdge,
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
