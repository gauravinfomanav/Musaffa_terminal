import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Highcharts-like stock chart: candles + volume + smooth range GUI.
class PremiumStockGuiChart extends StatefulWidget {
  const PremiumStockGuiChart({super.key, required this.dark});

  final bool dark;

  @override
  State<PremiumStockGuiChart> createState() => _PremiumStockGuiChartState();
}

class _PremiumStockGuiChartState extends State<PremiumStockGuiChart> {
  late final List<OhlcCandlePoint> _data;
  late final DateTime _minDate;
  late final DateTime _maxDate;
  late final ValueNotifier<_StockRange> _range;
  late final ValueNotifier<OhlcCandlePoint?> _hover;

  final GlobalKey<_StockPanesState> _panesKey = GlobalKey<_StockPanesState>();

  @override
  void initState() {
    super.initState();
    _data = StaticPremiumChartData.stockGuiHistory;
    _minDate = _data.first.date;
    _maxDate = _data.last.date;
    final int spanDays = _maxDate.difference(_minDate).inDays;
    final DateTime start = _maxDate.subtract(Duration(days: (spanDays * 0.42).round()));
    _range = ValueNotifier<_StockRange>(
      _StockRange(
        start.isBefore(_minDate) ? _minDate : start,
        _maxDate,
      ),
    );
    _hover = ValueNotifier<OhlcCandlePoint?>(_data.isEmpty ? null : _data.last);
  }

  @override
  void dispose() {
    _range.dispose();
    _hover.dispose();
    super.dispose();
  }

  void _applyRange(DateTime start, DateTime end) {
    final Duration minSpan = const Duration(days: 90);
    if (end.difference(start) < minSpan) {
      end = start.add(minSpan);
      if (end.isAfter(_maxDate)) {
        end = _maxDate;
        start = end.subtract(minSpan);
        if (start.isBefore(_minDate)) start = _minDate;
      }
    }
    if (start.isBefore(_minDate)) start = _minDate;
    if (end.isAfter(_maxDate)) end = _maxDate;

    _range.value = _StockRange(start, end);
    _panesKey.currentState?.setVisibleRange(start, end);

    // Keep hover candle inside the new window.
    final OhlcCandlePoint? h = _hover.value;
    if (h == null || h.date.isBefore(start) || h.date.isAfter(end)) {
      OhlcCandlePoint? lastIn;
      for (final OhlcCandlePoint p in _data) {
        if (!p.date.isBefore(start) && !p.date.isAfter(end)) lastIn = p;
      }
      _hover.value = lastIn;
    }
  }

  void _applyPreset(Duration lookback) {
    final DateTime end = _maxDate;
    DateTime start = end.subtract(lookback);
    if (start.isBefore(_minDate)) start = _minDate;
    _applyRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final UsPremiumChartColors c = chartColors(dark);

    return Container(
      height: 560,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UsPremiumPalette.border(dark)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _HeaderBar(
            dark: dark,
            colors: c,
            hover: _hover,
            onPreset: _applyPreset,
            onAll: () => _applyRange(_minDate, _maxDate),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _StockPanes(
              key: _panesKey,
              dark: dark,
              colors: c,
              data: _data,
              minDate: _minDate,
              maxDate: _maxDate,
              initialRange: _range.value,
              rangeListenable: _range,
              onHover: (OhlcCandlePoint? p) {
                if (p != null) _hover.value = p;
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: _SmoothRangeNavigator(
              dark: dark,
              colors: c,
              data: _data,
              minDate: _minDate,
              maxDate: _maxDate,
              range: _range,
              onChanged: _applyRange,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRange {
  const _StockRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

// ─── Header / legend / presets ──────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.dark,
    required this.colors,
    required this.hover,
    required this.onPreset,
    required this.onAll,
  });

  final bool dark;
  final UsPremiumChartColors colors;
  final ValueNotifier<OhlcCandlePoint?> hover;
  final void Function(Duration lookback) onPreset;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'STOCK CHART · WITH GUI',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: UsPremiumPalette.muted(dark),
              ),
            ),
            const Spacer(),
            _PresetChip(dark: dark, colors: colors, label: '1Y', onTap: () => onPreset(const Duration(days: 365))),
            const SizedBox(width: 6),
            _PresetChip(dark: dark, colors: colors, label: '2Y', onTap: () => onPreset(const Duration(days: 730))),
            const SizedBox(width: 6),
            _PresetChip(dark: dark, colors: colors, label: '5Y', onTap: () => onPreset(const Duration(days: 1825))),
            const SizedBox(width: 6),
            _PresetChip(dark: dark, colors: colors, label: 'All', onTap: onAll),
          ],
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<OhlcCandlePoint?>(
          valueListenable: hover,
          builder: (_, OhlcCandlePoint? tip, __) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _OhlcLegend(
                key: ValueKey<String>(
                  tip == null
                      ? 'empty'
                      : '${tip.date.millisecondsSinceEpoch}-${tip.close}',
                ),
                dark: dark,
                tip: tip,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.dark,
    required this.colors,
    required this.label,
    required this.onTap,
  });

  final bool dark;
  final UsPremiumChartColors colors;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.pillSelected.withValues(alpha: dark ? 0.35 : 0.55),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: colors.pillBorder.withValues(alpha: 0.55)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: UsPremiumPalette.electricBlueSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _OhlcLegend extends StatelessWidget {
  const _OhlcLegend({super.key, required this.dark, required this.tip});

  final bool dark;
  final OhlcCandlePoint? tip;

  @override
  Widget build(BuildContext context) {
    final TextStyle muted = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 11,
      color: UsPremiumPalette.muted(dark),
    );
    final TextStyle value = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: UsPremiumPalette.text(dark),
    );

    return Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    UsPremiumPalette.electricBlueSoft,
                    UsPremiumPalette.tealAccent,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: UsPremiumPalette.electricBlueSoft.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${StaticPremiumChartData.company} Stock Price',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: UsPremiumPalette.text(dark),
              ),
            ),
            if (tip != null) ...<Widget>[
              const SizedBox(width: 10),
              Text(
                DateFormat('MMM d, yyyy').format(tip!.date),
                style: muted,
              ),
            ],
          ],
        ),
        if (tip != null) ...<Widget>[
          _kv('Open', tip!.open.toStringAsFixed(3), muted, value),
          _kv('High', tip!.high.toStringAsFixed(3), muted, value),
          _kv('Low', tip!.low.toStringAsFixed(3), muted, value),
          _kv(
            'Close',
            tip!.close.toStringAsFixed(3),
            muted,
            value.copyWith(
              color: tip!.isUp ? UsPremiumPalette.gain : UsPremiumPalette.loss,
            ),
          ),
        ],
      ],
    );
  }

  Widget _kv(String k, String v, TextStyle muted, TextStyle value) {
    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(text: '$k ', style: muted),
          TextSpan(text: v, style: value),
        ],
      ),
    );
  }
}

// ─── Price + volume panes (stable — range via axis controllers) ─────────────

class _StockPanes extends StatefulWidget {
  const _StockPanes({
    super.key,
    required this.dark,
    required this.colors,
    required this.data,
    required this.minDate,
    required this.maxDate,
    required this.initialRange,
    required this.rangeListenable,
    required this.onHover,
  });

  final bool dark;
  final UsPremiumChartColors colors;
  final List<OhlcCandlePoint> data;
  final DateTime minDate;
  final DateTime maxDate;
  final _StockRange initialRange;
  final ValueNotifier<_StockRange> rangeListenable;
  final ValueChanged<OhlcCandlePoint?> onHover;

  @override
  State<_StockPanes> createState() => _StockPanesState();
}

class _StockPanesState extends State<_StockPanes> {
  DateTimeAxisController? _priceX;
  DateTimeAxisController? _volX;
  late DateTime _viewStart;
  late DateTime _viewEnd;

  @override
  void initState() {
    super.initState();
    _viewStart = widget.initialRange.start;
    _viewEnd = widget.initialRange.end;
  }

  void setVisibleRange(DateTime start, DateTime end) {
    _viewStart = start;
    _viewEnd = end;
    _priceX?.visibleMinimum = start;
    _priceX?.visibleMaximum = end;
    _volX?.visibleMinimum = start;
    _volX?.visibleMaximum = end;
  }

  OhlcCandlePoint? _find(DateTime x) {
    OhlcCandlePoint? best;
    int bestDiff = 1 << 30;
    for (final OhlcCandlePoint p in widget.data) {
      final int d = (p.date.difference(x).inMilliseconds).abs();
      if (d < bestDiff) {
        bestDiff = d;
        best = p;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final UsPremiumChartColors c = widget.colors;
    final Color bull = dark ? const Color(0xFFE8EEF4) : Colors.white;
    final Color bear = UsPremiumPalette.electricBlueSoft.withValues(alpha: 0.88);
    final Color vol = UsPremiumPalette.violetAccent.withValues(alpha: dark ? 0.72 : 0.62);

    return Column(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.zero,
            enableAxisAnimation: true,
            zoomPanBehavior: ZoomPanBehavior(
              enablePanning: true,
              enablePinching: true,
              zoomMode: ZoomMode.x,
              enableMouseWheelZooming: true,
            ),
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
              lineType: TrackballLineType.vertical,
              lineColor: UsPremiumPalette.slateMid.withValues(alpha: 0.45),
              lineWidth: 1,
              shouldAlwaysShow: false,
              builder: (_, TrackballDetails details) {
                final dynamic x = details.groupingModeInfo?.points.isNotEmpty == true
                    ? details.groupingModeInfo!.points.first.x
                    : details.point?.x;
                if (x is DateTime) {
                  final OhlcCandlePoint? found = _find(x);
                  if (found != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onHover(found);
                    });
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            primaryXAxis: DateTimeAxis(
              name: 'primaryXAxis',
              minimum: widget.minDate,
              maximum: widget.maxDate,
              initialVisibleMinimum: _viewStart,
              initialVisibleMaximum: _viewEnd,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              majorGridLines: MajorGridLines(
                width: 0.6,
                color: c.grid.withValues(alpha: dark ? 0.9 : 1),
                dashArray: const <double>[4, 4],
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelStyle: _axis(dark),
              dateFormat: DateFormat('MMM yyyy'),
              intervalType: DateTimeIntervalType.months,
              interval: 6,
              onRendererCreated: (DateTimeAxisController ctrl) => _priceX = ctrl,
            ),
            primaryYAxis: NumericAxis(
              opposedPosition: true,
              majorGridLines: MajorGridLines(
                width: 0.6,
                color: c.grid,
                dashArray: const <double>[4, 4],
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelStyle: _axis(dark),
              numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
            ),
            series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
              CandleSeries<OhlcCandlePoint, DateTime>(
                name: 'Price',
                dataSource: widget.data,
                xValueMapper: (OhlcCandlePoint p, _) => p.date,
                openValueMapper: (OhlcCandlePoint p, _) => p.open,
                highValueMapper: (OhlcCandlePoint p, _) => p.high,
                lowValueMapper: (OhlcCandlePoint p, _) => p.low,
                closeValueMapper: (OhlcCandlePoint p, _) => p.close,
                bullColor: bull,
                bearColor: bear,
                enableSolidCandles: true,
                borderWidth: 1.1,
                animationDuration: 700,
                animationDelay: 40,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<_StockRange>(
          valueListenable: widget.rangeListenable,
          builder: (_, _StockRange r, __) {
            return _VolumeLabel(
              dark: dark,
              start: r.start,
              end: r.end,
              data: widget.data,
            );
          },
        ),
        Expanded(
          flex: 2,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.zero,
            enableAxisAnimation: true,
            primaryXAxis: DateTimeAxis(
              minimum: widget.minDate,
              maximum: widget.maxDate,
              initialVisibleMinimum: _viewStart,
              initialVisibleMaximum: _viewEnd,
              isVisible: false,
              majorGridLines: const MajorGridLines(width: 0),
              onRendererCreated: (DateTimeAxisController ctrl) => _volX = ctrl,
            ),
            primaryYAxis: NumericAxis(
              opposedPosition: true,
              majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelStyle: _axis(dark, size: 9),
              numberFormat: NumberFormat.compact(),
            ),
            series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
              ColumnSeries<OhlcCandlePoint, DateTime>(
                dataSource: widget.data,
                xValueMapper: (OhlcCandlePoint p, _) => p.date,
                yValueMapper: (OhlcCandlePoint p, _) => p.volume,
                pointColorMapper: (OhlcCandlePoint p, _) =>
                    p.isUp ? vol : vol.withValues(alpha: dark ? 0.45 : 0.38),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(1.5)),
                width: 0.82,
                animationDuration: 650,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VolumeLabel extends StatelessWidget {
  const _VolumeLabel({
    required this.dark,
    required this.start,
    required this.end,
    required this.data,
  });

  final bool dark;
  final DateTime start;
  final DateTime end;
  final List<OhlcCandlePoint> data;

  @override
  Widget build(BuildContext context) {
    double sum = 0;
    for (final OhlcCandlePoint p in data) {
      if (!p.date.isBefore(start) && !p.date.isAfter(end)) sum += p.volume;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: UsPremiumPalette.violetAccent,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: UsPremiumPalette.violetAccent.withValues(alpha: 0.35),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Volume  ${NumberFormat.compact().format(sum)}',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: UsPremiumPalette.text(dark),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Smooth range navigator ─────────────────────────────────────────────────

class _SmoothRangeNavigator extends StatefulWidget {
  const _SmoothRangeNavigator({
    required this.dark,
    required this.colors,
    required this.data,
    required this.minDate,
    required this.maxDate,
    required this.range,
    required this.onChanged,
  });

  final bool dark;
  final UsPremiumChartColors colors;
  final List<OhlcCandlePoint> data;
  final DateTime minDate;
  final DateTime maxDate;
  final ValueNotifier<_StockRange> range;
  final void Function(DateTime start, DateTime end) onChanged;

  @override
  State<_SmoothRangeNavigator> createState() => _SmoothRangeNavigatorState();
}

class _SmoothRangeNavigatorState extends State<_SmoothRangeNavigator> {
  static const double _handleW = 12;

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final UsPremiumChartColors c = widget.colors;
    final int totalMs = widget.maxDate.difference(widget.minDate).inMilliseconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double w = constraints.maxWidth;

              double xOf(DateTime d) {
                if (totalMs <= 0) return 0;
                return (d.difference(widget.minDate).inMilliseconds / totalMs) * w;
              }

              DateTime dateOf(double x) {
                final double t = (x / w).clamp(0.0, 1.0);
                return widget.minDate.add(
                  Duration(milliseconds: (totalMs * t).round()),
                );
              }

              return ValueListenableBuilder<_StockRange>(
                valueListenable: widget.range,
                builder: (_, _StockRange r, __) {
                  final double left = xOf(r.start);
                  final double right = xOf(r.end);
                  final double selW = (right - left).clamp(28.0, w);

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        // Overview spark
                        SfCartesianChart(
                          plotAreaBorderWidth: 0,
                          margin: EdgeInsets.zero,
                          primaryXAxis: DateTimeAxis(
                            minimum: widget.minDate,
                            maximum: widget.maxDate,
                            isVisible: false,
                            majorGridLines: const MajorGridLines(width: 0),
                          ),
                          primaryYAxis: const NumericAxis(isVisible: false),
                          series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                            SplineAreaSeries<OhlcCandlePoint, DateTime>(
                              dataSource: widget.data,
                              xValueMapper: (OhlcCandlePoint p, _) => p.date,
                              yValueMapper: (OhlcCandlePoint p, _) => p.close,
                              borderColor: c.priceLine,
                              borderWidth: 1.4,
                              color: c.priceLine.withValues(alpha: 0.45),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  c.priceLine.withValues(alpha: dark ? 0.32 : 0.22),
                                  c.priceLine.withValues(alpha: 0.02),
                                ],
                              ),
                              animationDuration: 0,
                            ),
                          ],
                        ),
                        // Soft mask outside selection
                        Positioned(
                          left: 0,
                          width: left.clamp(0, w),
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: UsPremiumPalette.surface(dark).withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                        Positioned(
                          left: right.clamp(0, w),
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: UsPremiumPalette.surface(dark).withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                        // Selection glass
                        Positioned(
                          left: left,
                          width: selW,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (DragUpdateDetails d) {
                              final int dxMs = ((d.delta.dx / w) * totalMs).round();
                              final Duration span = r.end.difference(r.start);
                              DateTime nextStart =
                                  r.start.add(Duration(milliseconds: dxMs));
                              DateTime nextEnd = nextStart.add(span);
                              if (nextStart.isBefore(widget.minDate)) {
                                nextStart = widget.minDate;
                                nextEnd = nextStart.add(span);
                              }
                              if (nextEnd.isAfter(widget.maxDate)) {
                                nextEnd = widget.maxDate;
                                nextStart = nextEnd.subtract(span);
                                if (nextStart.isBefore(widget.minDate)) {
                                  nextStart = widget.minDate;
                                }
                              }
                              widget.onChanged(nextStart, nextEnd);
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.priceLine.withValues(alpha: dark ? 0.14 : 0.10),
                                border: Border(
                                  left: BorderSide(
                                    color: c.priceLine.withValues(alpha: 0.85),
                                    width: 1.5,
                                  ),
                                  right: BorderSide(
                                    color: c.priceLine.withValues(alpha: 0.85),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Handles
                        Positioned(
                          left: (left - _handleW / 2).clamp(0, w - _handleW),
                          top: 6,
                          bottom: 6,
                          width: _handleW,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (DragUpdateDetails d) {
                              widget.onChanged(dateOf(left + d.delta.dx), r.end);
                            },
                            child: _NavHandle(dark: dark, colors: c),
                          ),
                        ),
                        Positioned(
                          left: (right - _handleW / 2).clamp(0, w - _handleW),
                          top: 6,
                          bottom: 6,
                          width: _handleW,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (DragUpdateDetails d) {
                              widget.onChanged(r.start, dateOf(right + d.delta.dx));
                            },
                            child: _NavHandle(dark: dark, colors: c),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (final int y in <int>[2020, 2021, 2022, 2023, 2024])
              Text(
                '$y',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: UsPremiumPalette.muted(dark),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NavHandle extends StatelessWidget {
  const _NavHandle({required this.dark, required this.colors});

  final bool dark;
  final UsPremiumChartColors colors;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: Container(
        decoration: BoxDecoration(
          color: UsPremiumPalette.surface(dark),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.priceLine.withValues(alpha: 0.9)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.priceLine.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 2,
            height: 14,
            decoration: BoxDecoration(
              color: colors.priceLine.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _axis(bool dark, {double size = 10}) => TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: UsPremiumPalette.muted(dark),
    );
