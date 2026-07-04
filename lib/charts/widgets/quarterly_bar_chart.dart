import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/engine/quarterly_bar_chart_engine.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Reusable quarterly column chart matching Infomanav Terminal financial cards.
///
/// Handles positive-only revenue charts and negative operating-profit charts
/// in one component. Data labels auto-position above positive bars and below
/// negative bars via Syncfusion's `ChartDataLabelAlignment.auto`.
///
/// Desktop hover highlights the bar under the cursor and shows a tooltip card.
/// When not hovering, the latest bar stays highlighted.
class QuarterlyBarChart extends StatefulWidget {
  const QuarterlyBarChart({
    super.key,
    required this.title,
    required this.displayValue,
    required this.unit,
    required this.data,
    this.priceData = const <PriceDataPoint>[],
    this.theme = const QuarterlyBarChartTheme(),
  });

  final String title;
  final String displayValue;
  final String unit;
  final List<QuarterDataPoint> data;
  final List<PriceDataPoint> priceData;
  final QuarterlyBarChartTheme theme;

  @override
  State<QuarterlyBarChart> createState() => _QuarterlyBarChartState();
}


class _QuarterlyBarChartState extends State<QuarterlyBarChart> {
  int? _hoveredIndex;
  bool _chartHovered = false;
  bool _isDark = false;
  Offset _pointerPosition = Offset.zero;
  final GlobalKey _chartStackKey = GlobalKey();
  TooltipBehavior? _tooltipBehavior;
  bool? _tooltipThemeIsDark;
  final GlobalKey<_HoverTooltipLayerState> _tooltipLayerKey =
      GlobalKey<_HoverTooltipLayerState>();
  bool _priceTooltipRenderThisFrame = false;
  bool _priceOverlayVisible = false;

  /// Syncfusion delays desktop tooltip show by 50ms; hide again after that window.
  static const Duration _tooltipHideGrace = Duration(milliseconds: 80);

  void _onChartEnter(PointerEvent _) {
    _chartHovered = true;
  }

  void _clearHover() {
    _chartHovered = false;
    _priceTooltipRenderThisFrame = false;
    _priceOverlayVisible = false;
    _tooltipBehavior?.hide();
    _tooltipLayerKey.currentState?.hide();

    // Beat Syncfusion's delayed desktop show timer if the pointer left quickly.
    Future<void>.delayed(_tooltipHideGrace, () {
      if (!mounted || _chartHovered) {
        return;
      }
      _tooltipBehavior?.hide();
      _tooltipLayerKey.currentState?.hide();
    });

    if (_hoveredIndex != null) {
      setState(() => _hoveredIndex = null);
    }
  }

  void _hidePriceOverlay() {
    _priceOverlayVisible = false;
    _tooltipLayerKey.currentState?.hide();
  }

  void _hideTooltip() {
    _tooltipBehavior?.hide();
    _hidePriceOverlay();
    _setHoveredIndex(null);
  }

  Offset _tooltipOffset() {
    return Offset(
      _pointerPosition.dx + 12,
      math.max(0, _pointerPosition.dy - 48),
    );
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (widget.priceData.isEmpty) {
      return;
    }
    final RenderBox? box =
        _chartStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    _pointerPosition = box.globalToLocal(event.position);

    // Run after Syncfusion finishes handling this hover event.
    Future<void>.microtask(() {
      if (!mounted || !_chartHovered) {
        return;
      }
      if (!_priceTooltipRenderThisFrame &&
          (!_priceOverlayVisible || !_isPointerOnPriceLine())) {
        _hidePriceOverlay();
        _tooltipBehavior?.hide();
      }
      _priceTooltipRenderThisFrame = false;
    });
  }

  bool _isPointerOnPriceLine() {
    final RenderBox? box =
        _chartStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || widget.priceData.isEmpty) {
      return false;
    }

    final QuarterlyBarChartTheme theme = widget.theme;
    final double plotLeft = theme.plotAreaLeftPadding;
    final double plotRight = box.size.width - theme.plotAreaRightPadding;
    final double plotTop = theme.plotAreaTopPadding;
    final double plotBottom = box.size.height - theme.plotAreaBottomPadding - 20;
    final double plotWidth = plotRight - plotLeft;
    final double plotHeight = plotBottom - plotTop;
    if (plotWidth <= 0 || plotHeight <= 0) {
      return false;
    }

    final Offset pointer = _pointerPosition;
    if (pointer.dx < plotLeft - 24 ||
        pointer.dx > plotRight + 24 ||
        pointer.dy < plotTop - 24 ||
        pointer.dy > plotBottom + 24) {
      return false;
    }

    final DateTime? axisMin = QuarterlyBarChartEngine.resolveXAxisMinimum(
      widget.data,
      widget.priceData,
    );
    final DateTime? axisMax = QuarterlyBarChartEngine.resolveXAxisMaximum(
      widget.data,
      widget.priceData,
    );
    if (axisMin == null || axisMax == null) {
      return false;
    }

    final int axisMs = axisMax.difference(axisMin).inMilliseconds;
    if (axisMs <= 0) {
      return false;
    }

    final double xRatio = ((pointer.dx - plotLeft) / plotWidth).clamp(0.0, 1.0);
    final DateTime hoverDate = axisMin.add(
      Duration(milliseconds: (axisMs * xRatio).round()),
    );

    int nearestIndex = 0;
    int nearestDays = widget.priceData[0].date.difference(hoverDate).inDays.abs();
    for (int i = 1; i < widget.priceData.length; i++) {
      final int days = widget.priceData[i].date.difference(hoverDate).inDays.abs();
      if (days < nearestDays) {
        nearestDays = days;
        nearestIndex = i;
      }
    }

    final PriceYAxisRange priceRange =
        QuarterlyBarChartEngine.resolvePriceYAxisRange(
      data: widget.priceData,
    );
    final double priceSpan = priceRange.maximum - priceRange.minimum;
    if (priceSpan <= 0) {
      return false;
    }

    double minDistance = double.infinity;
    for (final int index in <int>{
      nearestIndex,
      nearestIndex - 1,
      nearestIndex + 1,
    }) {
      if (index < 0 || index >= widget.priceData.length) {
        continue;
      }
      final PriceDataPoint point = widget.priceData[index];
      final int pointMs = point.date.difference(axisMin).inMilliseconds;
      final double x = plotLeft + (pointMs / axisMs) * plotWidth;
      final double y = plotTop +
          (1 - (point.value - priceRange.minimum) / priceSpan) * plotHeight;
      final double distance = (pointer - Offset(x, y)).distance;
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance <= 22;
  }

  Offset _priceTooltipOffsetFromArgs(TooltipArgs args) {
    final RenderBox? box =
        _chartStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || args.locationX == null || args.locationY == null) {
      return _tooltipOffset();
    }

    final Offset local = box.globalToLocal(
      Offset(args.locationX!, args.locationY!),
    );
    return Offset(
      local.dx + 12,
      math.max(0, local.dy - 48),
    );
  }

  void _onTooltipRender(TooltipArgs args) {
    if (!_chartHovered) {
      _hideTooltip();
      return;
    }

    final int? index = args.pointIndex is int
        ? args.pointIndex as int
        : args.pointIndex?.toInt();
    if (index == null) {
      _hideTooltip();
      return;
    }

    final bool isPriceSeries =
        widget.priceData.isNotEmpty && args.seriesIndex == 1;

    if (isPriceSeries) {
      if (index < 0 || index >= widget.priceData.length) {
        _hideTooltip();
        return;
      }

      final PriceDataPoint point = widget.priceData[index];

      final _HoverTooltipLayerState? layer = _tooltipLayerKey.currentState;
      if (layer == null) {
        return;
      }

      _priceTooltipRenderThisFrame = true;
      _priceOverlayVisible = true;
      _tooltipBehavior?.hide();
      layer.showPrice(
        offset: _priceTooltipOffsetFromArgs(args),
        dateLabel: QuarterlyBarChartEngine.formatPriceDateLabel(point.date),
        priceText: '\$${point.value.toStringAsFixed(2)}',
      );
      _setHoveredIndex(null);
      return;
    }

    if (widget.priceData.isNotEmpty) {
      _tooltipBehavior?.hide();
      return;
    }

    if (index < 0 || index >= widget.data.length) {
      _hideTooltip();
      return;
    }

    _hidePriceOverlay();
    _setHoveredIndex(index);
  }

  void _setHoveredIndex(int? index) {
    if (_hoveredIndex == index) {
      return;
    }
    setState(() => _hoveredIndex = index);
  }

  TooltipBehavior _createTooltipBehavior(bool isDark) {
    return TooltipBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      canShowMarker: false,
      color: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      elevation: 0,
      shadowColor: Colors.transparent,
      builder: (
        dynamic data,
        dynamic point,
        dynamic series,
        int pointIndex,
        int seriesIndex,
      ) {
        if (!_chartHovered) {
          return const SizedBox.shrink();
        }

        if (widget.priceData.isNotEmpty) {
          return const SizedBox.shrink();
        }

        if (data is PriceDataPoint) {
          return const SizedBox.shrink();
        }

        if (data is! QuarterDataPoint) {
          return const SizedBox.shrink();
        }

        return _BarTooltipCard(
          quarterLabel: data.label,
          metricTitle: widget.title,
          valueText: QuarterlyBarChartEngine.formatValue(data.value),
          isDark: _isDark,
        );
      },
    );
  }

  void _ensureTooltipBehavior(bool isDark) {
    if (_tooltipBehavior == null || _tooltipThemeIsDark != isDark) {
      _tooltipThemeIsDark = isDark;
      _tooltipBehavior = _createTooltipBehavior(isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    _isDark = isDark;
    _ensureTooltipBehavior(isDark);
    final TextStyle titleStyle = widget.theme.titleStyle ??
        QuarterlyBarChartEngine.defaultTitleStyle(context, isDark);
    final TextStyle valueStyle = widget.theme.valueStyle ??
        QuarterlyBarChartEngine.defaultValueStyle(context, isDark);
    final TextStyle unitStyle = widget.theme.unitStyle ??
        QuarterlyBarChartEngine.defaultUnitStyle(context, isDark);
    final TextStyle axisLabelStyle = widget.theme.axisLabelStyle ??
        QuarterlyBarChartEngine.defaultAxisLabelStyle(context, isDark);
    final TextStyle dataLabelStyle = widget.theme.dataLabelStyle ??
        QuarterlyBarChartEngine.defaultDataLabelStyle(context, isDark);

    final QuarterlyBarChartYAxisRange yRange =
        QuarterlyBarChartEngine.resolveYAxisRange(
      data: widget.data,
      theme: widget.theme,
    );

    final bool hasPriceOverlay = widget.priceData.isNotEmpty;

    final CartesianSeries<QuarterDataPoint, dynamic> series =
        QuarterlyBarChartEngine.buildColumnSeries(
      data: widget.data,
      latestIndex: widget.data.isEmpty ? -1 : widget.data.length - 1,
      hoveredIndex: _hoveredIndex,
      theme: widget.theme,
      dataLabelStyle: dataLabelStyle,
      enableTooltip: !hasPriceOverlay,
      categoryXAxis: !hasPriceOverlay,
    );
    final LineSeries<PriceDataPoint, DateTime>? priceSeries =
        widget.priceData.isEmpty
            ? null
            : QuarterlyBarChartEngine.buildPriceSeries(
                data: widget.priceData,
                theme: widget.theme,
              );
    final PriceYAxisRange? priceRange = widget.priceData.isEmpty
        ? null
        : QuarterlyBarChartEngine.resolvePriceYAxisRange(
            data: widget.priceData,
          );

    return Container(
      padding: widget.theme.cardPadding,
      decoration: BoxDecoration(
        color: widget.theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.theme.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ChartHeader(
            title: widget.title,
            displayValue: widget.displayValue,
            unit: widget.unit,
            titleStyle: titleStyle,
            valueStyle: valueStyle,
            unitStyle: unitStyle,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: widget.theme.chartHeight,
            child: MouseRegion(
              onEnter: _onChartEnter,
              onExit: (_) => _clearHover(),
              child: Listener(
                onPointerHover: _onPointerHover,
                child: Stack(
                  key: _chartStackKey,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    _QuarterlyBarChartCanvas(
                    key: ValueKey<bool>(hasPriceOverlay),
                    data: widget.data,
                    series: series,
                    tooltipBehavior: _tooltipBehavior!,
                    onTooltipRender: _onTooltipRender,
                    yAxis: QuarterlyBarChartEngine.buildYAxis(
                      range: yRange,
                      theme: widget.theme,
                      axisLabelStyle: axisLabelStyle,
                      data: widget.data,
                    ),
                    xAxis: QuarterlyBarChartEngine.buildXAxis(
                      theme: widget.theme,
                      axisLabelStyle: axisLabelStyle,
                      data: widget.data,
                      priceData: widget.priceData,
                    ),
                    priceAxis: priceRange == null
                        ? null
                        : QuarterlyBarChartEngine.buildPriceYAxis(
                            range: priceRange,
                            theme: widget.theme,
                            axisLabelStyle: axisLabelStyle,
                          ),
                    priceSeries: priceSeries,
                    plotAreaLeftPadding: widget.theme.plotAreaLeftPadding,
                    plotAreaRightPadding: widget.theme.plotAreaRightPadding,
                    plotAreaTopPadding: widget.theme.plotAreaTopPadding,
                  ),
                  if (widget.priceData.isNotEmpty)
                    _HoverTooltipLayer(
                      key: _tooltipLayerKey,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _HoverTooltipLayer extends StatefulWidget {
  const _HoverTooltipLayer({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  State<_HoverTooltipLayer> createState() => _HoverTooltipLayerState();
}

class _HoverTooltipLayerState extends State<_HoverTooltipLayer> {
  bool _visible = false;
  Offset _offset = Offset.zero;
  String _dateLabel = '';
  String _priceText = '';

  void hide() {
    if (!_visible) {
      return;
    }
    setState(() => _visible = false);
  }

  void showPrice({
    required Offset offset,
    required String dateLabel,
    required String priceText,
  }) {
    final bool contentChanged = !_visible ||
        _offset != offset ||
        _dateLabel != dateLabel ||
        _priceText != priceText;

    if (!contentChanged) {
      return;
    }

    setState(() {
      _visible = true;
      _offset = offset;
      _dateLabel = dateLabel;
      _priceText = priceText;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final Color secondary =
        widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: IgnorePointer(
        child: Material(
          elevation: 8,
          shadowColor:
              Colors.black.withValues(alpha: widget.isDark ? 0.4 : 0.14),
          color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: widget.isDark
                  ? const Color(0xFF404040)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _dateLabel,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _priceText,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarTooltipCard extends StatelessWidget {
  const _BarTooltipCard({
    required this.quarterLabel,
    required this.metricTitle,
    required this.valueText,
    required this.isDark,
  });

  final String quarterLabel;
  final String metricTitle;
  final String valueText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color primary =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A);
    final Color secondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  quarterLabel,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        metricTitle,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      valueText,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.title,
    required this.displayValue,
    required this.unit,
    required this.titleStyle,
    required this.valueStyle,
    required this.unitStyle,
  });

  final String title;
  final String displayValue;
  final String unit;
  final TextStyle titleStyle;
  final TextStyle valueStyle;
  final TextStyle unitStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: titleStyle),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(displayValue, style: valueStyle),
            const SizedBox(width: 6),
            Text(unit, style: unitStyle),
          ],
        ),
      ],
    );
  }
}

/// Thin owned wrapper around [SfCartesianChart] — axis + series assembly lives
/// in [QuarterlyBarChartEngine], not inline in the widget tree.
class _QuarterlyBarChartCanvas extends StatelessWidget {
  const _QuarterlyBarChartCanvas({
    super.key,
    required this.data,
    required this.series,
    required this.priceSeries,
    required this.tooltipBehavior,
    required this.onTooltipRender,
    required this.yAxis,
    required this.xAxis,
    required this.priceAxis,
    required this.plotAreaLeftPadding,
    required this.plotAreaRightPadding,
    required this.plotAreaTopPadding,
  });

  final List<QuarterDataPoint> data;
  final CartesianSeries<QuarterDataPoint, dynamic> series;
  final LineSeries<PriceDataPoint, DateTime>? priceSeries;
  final TooltipBehavior tooltipBehavior;
  final void Function(TooltipArgs args) onTooltipRender;
  final NumericAxis yAxis;
  final ChartAxis xAxis;
  final NumericAxis? priceAxis;
  final double plotAreaLeftPadding;
  final double plotAreaRightPadding;
  final double plotAreaTopPadding;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return SfCartesianChart(
      margin: EdgeInsets.only(
        left: plotAreaLeftPadding,
        right: plotAreaRightPadding,
        top: plotAreaTopPadding,
      ),
      plotAreaBorderWidth: 0,
      borderWidth: 0,
      tooltipBehavior: tooltipBehavior,
      onTooltipRender: onTooltipRender,
      primaryXAxis: xAxis,
      primaryYAxis: yAxis,
      axes: priceAxis == null ? const <ChartAxis>[] : <ChartAxis>[priceAxis!],
      series: <CartesianSeries<dynamic, dynamic>>[
        series,
        if (priceSeries != null) priceSeries!,
      ],
    );
  }
}
