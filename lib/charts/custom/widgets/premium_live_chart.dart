import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/controllers/ticker_custom_charts_controller.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Smooth, clean, modern premium live price chart for Custom Charts.
class PremiumLiveChart extends StatefulWidget {
  const PremiumLiveChart({
    super.key,
    required this.symbol,
    required this.companyName,
    required this.controller,
    this.fallbackPrice,
    this.dayChangePercent,
    this.isLiveConnected = false,
  });

  final String symbol;
  final String companyName;
  final TickerCustomChartsController controller;
  final double? fallbackPrice;
  final double? dayChangePercent;
  final bool isLiveConnected;

  @override
  State<PremiumLiveChart> createState() => _PremiumLiveChartState();
}

class _PremiumLiveChartState extends State<PremiumLiveChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  double? _prevPrice;
  Color? _flashColor;
  Timer? _flashTimer;

  Worker? _priceWorker;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _priceWorker = ever<double?>(widget.controller.livePrice, _onPriceTick);
  }

  @override
  void dispose() {
    _priceWorker?.dispose();
    _flashTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onPriceTick(double? price) {
    if (price == null || !mounted) return;
    if (_prevPrice != null && price != _prevPrice) {
      final Color flash = price > _prevPrice!
          ? UsPremiumPalette.gain
          : UsPremiumPalette.loss;
      setState(() => _flashColor = flash);
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 520), () {
        if (mounted) setState(() => _flashColor = null);
      });
    }
    _prevPrice = price;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final UsPremiumChartColors c = chartColors(dark);

    return Obx(() {
      final List<OhlcCandlePoint> data = widget.controller.visibleCandles;
      final bool loading = widget.controller.isLoadingPrice.value;
      final double? price = widget.controller.displayPrice ?? widget.fallbackPrice;
      final double? changePct =
          widget.controller.rangeChangePercent ?? widget.dayChangePercent;
      final bool up = (changePct ?? 0) >= 0;

      return Container(
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
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(dark, c, price, changePct, up),
            const SizedBox(height: 14),
            _buildToolbar(dark, c),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: loading
                    ? _buildLoader(dark, key: const ValueKey('loading'))
                    : data.isEmpty
                        ? _buildEmpty(
                            dark,
                            'No chart data available',
                            key: const ValueKey('empty'),
                          )
                        : KeyedSubtree(
                            key: ValueKey<String>(
                              '${widget.controller.selectedRange.value.label}-${data.length}',
                            ),
                            child: _buildAreaChart(dark, c, data, up),
                          ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(
    bool dark,
    UsPremiumChartColors c,
    double? price,
    double? changePct,
    bool up,
  ) {
    final Color priceColor =
        _flashColor ?? UsPremiumPalette.text(dark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    widget.symbol.toUpperCase(),
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: UsPremiumPalette.muted(dark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _LiveBadge(
                    connected: widget.isLiveConnected,
                    pulse: _pulse,
                    dark: dark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.6,
                      color: priceColor,
                    ),
                    child: Text(
                      price == null ? '--' : '\$${NumberFormat('#,##0.00').format(price)}',
                    ),
                  ),
                  if (changePct != null) ...<Widget>[
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (up ? UsPremiumPalette.gain : UsPremiumPalette.loss)
                              .withValues(alpha: dark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${up ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: up
                                ? UsPremiumPalette.gain
                                : UsPremiumPalette.loss,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (widget.companyName.isNotEmpty)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Text(
                widget.companyName,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 12,
                  height: 1.25,
                  color: UsPremiumPalette.muted(dark),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar(bool dark, UsPremiumChartColors c) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List<Widget>.generate(
        PremiumPriceRange.valuesOrdered.length,
        (int i) {
          final PremiumPriceRange range = PremiumPriceRange.valuesOrdered[i];
          final bool sel = widget.controller.selectedRange.value == range;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.controller.selectRange(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sel ? c.pillSelected : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: sel ? c.pillBorder : UsPremiumPalette.border(dark),
                  ),
                ),
                child: Text(
                  range.label,
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
        },
      ),
    );
  }

  Widget _buildAreaChart(
    bool dark,
    UsPremiumChartColors c,
    List<OhlcCandlePoint> data,
    bool up,
  ) {
    final bool intraday = widget.controller.isShowingIntradayData;
    final Color line = up ? c.priceLine : UsPremiumPalette.lossSoft;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      enableAxisAnimation: true,
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
            DateFormat(intraday ? 'MMM d · h:mm a' : 'MMM d, yyyy').format(x),
            '\$${y.toStringAsFixed(2)}',
          );
        },
      ),
      primaryXAxis: DateTimeAxis(
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: UsPremiumPalette.grid(dark),
        ),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: _axisStyle(dark),
        dateFormat: DateFormat(intraday ? 'h:mm a' : 'MMM d'),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: UsPremiumPalette.grid(dark),
        ),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: _axisStyle(dark),
        numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
      ),
      series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
        SplineAreaSeries<OhlcCandlePoint, DateTime>(
          dataSource: data,
          xValueMapper: (OhlcCandlePoint p, _) => p.date,
          yValueMapper: (OhlcCandlePoint p, _) => p.close,
          borderWidth: 1.8,
          borderColor: line,
          splineType: SplineType.cardinal,
          cardinalSplineTension: 0.18,
          animationDuration: 650,
          markerSettings: const MarkerSettings(isVisible: false),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              line.withValues(alpha: dark ? 0.34 : 0.20),
              line.withValues(alpha: 0.02),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoader(bool dark, {Key? key}) {
    return Center(
      key: key,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            UsPremiumPalette.electricBlueSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool dark, String message, {Key? key}) {
    return Center(
      key: key,
      child: Text(
        message,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 13,
          color: UsPremiumPalette.muted(dark),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({
    required this.connected,
    required this.pulse,
    required this.dark,
  });

  final bool connected;
  final AnimationController pulse;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        connected ? UsPremiumPalette.gain : UsPremiumPalette.muted(dark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) {
              final double t = connected ? pulse.value : 0.35;
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.45 + (t * 0.55)),
                  boxShadow: connected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35 * t),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'LIVE' : 'DELAYED',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: accent,
            ),
          ),
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
          Text(
            title,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 10,
              color: UsPremiumPalette.muted(dark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: UsPremiumPalette.text(dark),
            ),
          ),
        ],
      ),
    );
