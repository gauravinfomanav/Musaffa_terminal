import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Stock chart with range navigator, candles, volume pane, and RSI(14).
class PremiumStockRsiChart extends StatefulWidget {
  const PremiumStockRsiChart({super.key, required this.dark});

  final bool dark;

  @override
  State<PremiumStockRsiChart> createState() => _PremiumStockRsiChartState();
}

class _PremiumStockRsiChartState extends State<PremiumStockRsiChart> {
  late final List<OhlcCandlePoint> _data;
  late final List<_RsiPoint> _rsi;
  late final DateTime _minDate;
  late final DateTime _maxDate;
  late final ValueNotifier<_ViewRange> _range;

  DateTimeAxisController? _priceX;
  DateTimeAxisController? _volX;
  DateTimeAxisController? _rsiX;

  static const Color _bull = Color(0xFF26A069);
  static const Color _bear = Color(0xFFD64545);
  static const Color _rsiMain = Color(0xFF6B5B95);
  static const Color _rsiSignal = Color(0xFFE09B4E);
  static const Color _band80 = Color(0xFF7EB6D9);
  static const Color _band20 = Color(0xFFE08A8A);

  @override
  void initState() {
    super.initState();
    _data = StaticPremiumChartData.stockRsiHistory;
    _rsi = _computeRsi(_data, period: 14, signalPeriod: 3);
    _minDate = _data.first.date;
    _maxDate = _data.last.date;
    final DateTime start = DateTime(2021, 7, 1);
    final DateTime end = DateTime(2022, 3, 18);
    _range = ValueNotifier<_ViewRange>(
      _ViewRange(
        start.isBefore(_minDate) ? _minDate : start,
        end.isAfter(_maxDate) ? _maxDate : end,
      ),
    );
  }

  @override
  void dispose() {
    _range.dispose();
    super.dispose();
  }

  void _applyRange(DateTime start, DateTime end) {
    const Duration minSpan = Duration(days: 45);
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
    _range.value = _ViewRange(start, end);
    _priceX?.visibleMinimum = start;
    _priceX?.visibleMaximum = end;
    _volX?.visibleMinimum = start;
    _volX?.visibleMaximum = end;
    _rsiX?.visibleMinimum = start;
    _rsiX?.visibleMaximum = end;
  }

  TextStyle _axis([double size = 10]) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: UsPremiumPalette.muted(widget.dark),
      );

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final Color grid = UsPremiumPalette.grid(dark);

    return Container(
      height: 620,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UsPremiumPalette.border(dark)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'STOCK CHART · RELATIVE STRENGTH INDEX',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: UsPremiumPalette.muted(dark),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: _RangeNavigator(
              dark: dark,
              data: _data,
              minDate: _minDate,
              maxDate: _maxDate,
              range: _range,
              onChanged: _applyRange,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _LegendChip(dark: dark, color: _bull, label: 'MSFT'),
              const SizedBox(width: 8),
              _LegendChip(
                dark: dark,
                color: _bull.withValues(alpha: 0.5),
                label: 'Volume',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 52,
            child: ValueListenableBuilder<_ViewRange>(
              valueListenable: _range,
              builder: (_, _ViewRange r, __) {
                return SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  margin: EdgeInsets.zero,
                  primaryXAxis: DateTimeAxis(
                    minimum: _minDate,
                    maximum: _maxDate,
                    initialVisibleMinimum: r.start,
                    initialVisibleMaximum: r.end,
                    edgeLabelPlacement: EdgeLabelPlacement.shift,
                    majorGridLines: MajorGridLines(width: 0.7, color: grid),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    labelStyle: _axis(),
                    dateFormat: DateFormat('MMM yyyy'),
                    intervalType: DateTimeIntervalType.months,
                    interval: 2,
                    onRendererCreated: (DateTimeAxisController c) =>
                        _priceX = c,
                  ),
                  primaryYAxis: NumericAxis(
                    opposedPosition: true,
                    rangePadding: ChartRangePadding.round,
                    majorGridLines: MajorGridLines(width: 0.7, color: grid),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    labelStyle: _axis(),
                    numberFormat: NumberFormat('#0.00'),
                  ),
                  trackballBehavior: TrackballBehavior(
                    enable: true,
                    activationMode: ActivationMode.singleTap,
                    tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
                    lineType: TrackballLineType.vertical,
                    lineColor:
                        UsPremiumPalette.slateMid.withValues(alpha: 0.5),
                    lineWidth: 1,
                  ),
                  series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                    CandleSeries<OhlcCandlePoint, DateTime>(
                      name: 'MSFT',
                      dataSource: _data,
                      xValueMapper: (OhlcCandlePoint p, _) => p.date,
                      openValueMapper: (OhlcCandlePoint p, _) => p.open,
                      highValueMapper: (OhlcCandlePoint p, _) => p.high,
                      lowValueMapper: (OhlcCandlePoint p, _) => p.low,
                      closeValueMapper: (OhlcCandlePoint p, _) => p.close,
                      bullColor: _bull,
                      bearColor: _bear,
                      enableSolidCandles: true,
                      borderWidth: 1,
                      animationDuration: 500,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 14,
            child: ValueListenableBuilder<_ViewRange>(
              valueListenable: _range,
              builder: (_, _ViewRange r, __) {
                return SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  margin: EdgeInsets.zero,
                  primaryXAxis: DateTimeAxis(
                    minimum: _minDate,
                    maximum: _maxDate,
                    initialVisibleMinimum: r.start,
                    initialVisibleMaximum: r.end,
                    isVisible: false,
                    majorGridLines: const MajorGridLines(width: 0),
                    onRendererCreated: (DateTimeAxisController c) =>
                        _volX = c,
                  ),
                  primaryYAxis: NumericAxis(
                    opposedPosition: true,
                    majorGridLines: MajorGridLines(
                      width: 0.5,
                      color: grid.withValues(alpha: 0.7),
                    ),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    labelStyle: _axis(9),
                    numberFormat: NumberFormat.compact(),
                  ),
                  series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                    ColumnSeries<OhlcCandlePoint, DateTime>(
                      dataSource: _data,
                      xValueMapper: (OhlcCandlePoint p, _) => p.date,
                      yValueMapper: (OhlcCandlePoint p, _) => p.volume,
                      pointColorMapper: (OhlcCandlePoint p, _) => p.isUp
                          ? _bull.withValues(alpha: dark ? 0.55 : 0.48)
                          : _bear.withValues(alpha: dark ? 0.55 : 0.48),
                      width: 0.7,
                      spacing: 0.15,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(1),
                      ),
                      animationDuration: 500,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'RSI (14, 3, close)',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: UsPremiumPalette.text(dark),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 26,
            child: ValueListenableBuilder<_ViewRange>(
              valueListenable: _range,
              builder: (_, _ViewRange r, __) {
                return SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  margin: EdgeInsets.zero,
                  primaryXAxis: DateTimeAxis(
                    minimum: _minDate,
                    maximum: _maxDate,
                    initialVisibleMinimum: r.start,
                    initialVisibleMaximum: r.end,
                    isVisible: false,
                    majorGridLines: const MajorGridLines(width: 0),
                    onRendererCreated: (DateTimeAxisController c) =>
                        _rsiX = c,
                  ),
                  primaryYAxis: NumericAxis(
                    opposedPosition: true,
                    minimum: 0,
                    maximum: 100,
                    interval: 20,
                    majorGridLines: MajorGridLines(width: 0.6, color: grid),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    labelStyle: _axis(),
                    numberFormat: NumberFormat('0.00'),
                    plotBands: <PlotBand>[
                      PlotBand(
                        start: 0,
                        end: 20,
                        color: _band20.withValues(alpha: dark ? 0.18 : 0.12),
                        borderWidth: 0,
                      ),
                      PlotBand(
                        start: 20,
                        end: 20,
                        borderColor: _band20,
                        borderWidth: 1,
                        dashArray: const <double>[4, 3],
                      ),
                      PlotBand(
                        start: 50,
                        end: 50,
                        borderColor: UsPremiumPalette.muted(dark)
                            .withValues(alpha: 0.5),
                        borderWidth: 1,
                        dashArray: const <double>[4, 3],
                      ),
                      PlotBand(
                        start: 80,
                        end: 80,
                        borderColor: _band80,
                        borderWidth: 1,
                        dashArray: const <double>[4, 3],
                      ),
                    ],
                  ),
                  series: <CartesianSeries<_RsiPoint, DateTime>>[
                    SplineSeries<_RsiPoint, DateTime>(
                      name: 'RSI',
                      dataSource: _rsi,
                      xValueMapper: (_RsiPoint p, _) => p.date,
                      yValueMapper: (_RsiPoint p, _) => p.rsi,
                      color: _rsiMain,
                      width: 1.7,
                      animationDuration: 500,
                    ),
                    SplineSeries<_RsiPoint, DateTime>(
                      name: 'Signal',
                      dataSource: _rsi,
                      xValueMapper: (_RsiPoint p, _) => p.date,
                      yValueMapper: (_RsiPoint p, _) => p.signal,
                      color: _rsiSignal,
                      width: 1.5,
                      animationDuration: 500,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<_RsiPoint> _computeRsi(
    List<OhlcCandlePoint> candles, {
    required int period,
    required int signalPeriod,
  }) {
    if (candles.length < period + 2) return const <_RsiPoint>[];

    final List<double> gains = <double>[];
    final List<double> losses = <double>[];
    for (int i = 1; i < candles.length; i++) {
      final double d = candles[i].close - candles[i - 1].close;
      gains.add(d > 0 ? d : 0);
      losses.add(d < 0 ? -d : 0);
    }

    double avgGain =
        gains.take(period).fold(0.0, (double a, double b) => a + b) / period;
    double avgLoss =
        losses.take(period).fold(0.0, (double a, double b) => a + b) / period;

    double rsiAt(double g, double l) {
      if (l <= 1e-9) return 100;
      if (g <= 1e-9) return 0;
      return 100 - (100 / (1 + g / l));
    }

    final List<_RsiPoint> out = <_RsiPoint>[
      _RsiPoint(
        date: candles[period].date,
        rsi: rsiAt(avgGain, avgLoss),
        signal: 0,
      ),
    ];

    for (int i = period; i < gains.length; i++) {
      avgGain = ((avgGain * (period - 1)) + gains[i]) / period;
      avgLoss = ((avgLoss * (period - 1)) + losses[i]) / period;
      out.add(
        _RsiPoint(
          date: candles[i + 1].date,
          rsi: rsiAt(avgGain, avgLoss),
          signal: 0,
        ),
      );
    }

    for (int i = 0; i < out.length; i++) {
      if (i + 1 < signalPeriod) {
        out[i] = _RsiPoint(
          date: out[i].date,
          rsi: out[i].rsi,
          signal: out[i].rsi,
        );
        continue;
      }
      double sum = 0;
      for (int j = i - signalPeriod + 1; j <= i; j++) {
        sum += out[j].rsi;
      }
      out[i] = _RsiPoint(
        date: out[i].date,
        rsi: out[i].rsi,
        signal: sum / signalPeriod,
      );
    }
    return out;
  }
}

class _ViewRange {
  const _ViewRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

class _RsiPoint {
  const _RsiPoint({
    required this.date,
    required this.rsi,
    required this.signal,
  });

  final DateTime date;
  final double rsi;
  final double signal;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.dark,
    required this.color,
    required this.label,
  });

  final bool dark;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: UsPremiumPalette.border(dark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
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

class _RangeNavigator extends StatelessWidget {
  const _RangeNavigator({
    required this.dark,
    required this.data,
    required this.minDate,
    required this.maxDate,
    required this.range,
    required this.onChanged,
  });

  final bool dark;
  final List<OhlcCandlePoint> data;
  final DateTime minDate;
  final DateTime maxDate;
  final ValueNotifier<_ViewRange> range;
  final void Function(DateTime start, DateTime end) onChanged;

  @override
  Widget build(BuildContext context) {
    final int totalMs = math.max(1, maxDate.difference(minDate).inMilliseconds);
    final Color accent = UsPremiumPalette.electricBlueSoft;
    final Color border = UsPremiumPalette.border(dark);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        double xOf(DateTime d) =>
            (d.difference(minDate).inMilliseconds / totalMs) * w;

        DateTime dateOf(double x) {
          final double t = (x / w).clamp(0.0, 1.0);
          return minDate.add(Duration(milliseconds: (totalMs * t).round()));
        }

        return ValueListenableBuilder<_ViewRange>(
          valueListenable: range,
          builder: (_, _ViewRange r, __) {
            final double left = xOf(r.start).clamp(0.0, w);
            final double right = xOf(r.end).clamp(0.0, w);
            final double selW = math.max(28.0, right - left);

            return DecoratedBox(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1A2332) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        margin: EdgeInsets.zero,
                        primaryXAxis: DateTimeAxis(
                          minimum: minDate,
                          maximum: maxDate,
                          isVisible: false,
                          majorGridLines: const MajorGridLines(width: 0),
                        ),
                        primaryYAxis: const NumericAxis(isVisible: false),
                        series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                          SplineAreaSeries<OhlcCandlePoint, DateTime>(
                            dataSource: data,
                            xValueMapper: (OhlcCandlePoint p, _) => p.date,
                            yValueMapper: (OhlcCandlePoint p, _) => p.close,
                            borderColor: accent,
                            borderWidth: 1.4,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                accent.withValues(alpha: dark ? 0.35 : 0.28),
                                accent.withValues(alpha: 0.02),
                              ],
                            ),
                            animationDuration: 0,
                          ),
                        ],
                      ),
                    ),
                    // Dim outside selection
                    Positioned(
                      left: 0,
                      width: left,
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: UsPremiumPalette.surface(dark)
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    Positioned(
                      left: right,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: UsPremiumPalette.surface(dark)
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    // Active window
                    Positioned(
                      left: left,
                      width: selW,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (DragUpdateDetails d) {
                          final int dxMs =
                              ((d.delta.dx / w) * totalMs).round();
                          final Duration span = r.end.difference(r.start);
                          DateTime ns =
                              r.start.add(Duration(milliseconds: dxMs));
                          DateTime ne = ns.add(span);
                          if (ns.isBefore(minDate)) {
                            ns = minDate;
                            ne = ns.add(span);
                          }
                          if (ne.isAfter(maxDate)) {
                            ne = maxDate;
                            ns = ne.subtract(span);
                          }
                          onChanged(ns, ne);
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: accent.withValues(alpha: 0.85),
                                width: 1.5,
                              ),
                              right: BorderSide(
                                color: accent.withValues(alpha: 0.85),
                                width: 1.5,
                              ),
                            ),
                            color: accent.withValues(alpha: dark ? 0.14 : 0.10),
                          ),
                        ),
                      ),
                    ),
                    _NavHandle(
                      left: (left - 7).clamp(0.0, w - 14),
                      height: h,
                      dark: dark,
                      onDrag: (double dx) {
                        DateTime next = dateOf(left + dx);
                        if (next.isAfter(
                          r.end.subtract(const Duration(days: 30)),
                        )) {
                          next = r.end.subtract(const Duration(days: 30));
                        }
                        if (next.isBefore(minDate)) next = minDate;
                        onChanged(next, r.end);
                      },
                    ),
                    _NavHandle(
                      left: (right - 7).clamp(0.0, w - 14),
                      height: h,
                      dark: dark,
                      onDrag: (double dx) {
                        DateTime next = dateOf(right + dx);
                        if (next.isBefore(
                          r.start.add(const Duration(days: 30)),
                        )) {
                          next = r.start.add(const Duration(days: 30));
                        }
                        if (next.isAfter(maxDate)) next = maxDate;
                        onChanged(r.start, next);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NavHandle extends StatelessWidget {
  const _NavHandle({
    required this.left,
    required this.height,
    required this.dark,
    required this.onDrag,
  });

  final double left;
  final double height;
  final bool dark;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: (height - 28) / 2,
      width: 14,
      height: 28,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (DragUpdateDetails d) => onDrag(d.delta.dx),
        child: Container(
          decoration: BoxDecoration(
            color: UsPremiumPalette.surface(dark),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: UsPremiumPalette.border(dark)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 14,
              decoration: BoxDecoration(
                color: UsPremiumPalette.muted(dark),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
