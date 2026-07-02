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
    this.theme = const QuarterlyBarChartTheme(),
  });

  final String title;
  final String displayValue;
  final String unit;
  final List<QuarterDataPoint> data;
  final QuarterlyBarChartTheme theme;

  @override
  State<QuarterlyBarChart> createState() => _QuarterlyBarChartState();
}

class _QuarterlyBarChartState extends State<QuarterlyBarChart> {
  int? _hoveredIndex;
  bool _chartHovered = false;
  bool _isDark = false;
  TooltipBehavior? _tooltipBehavior;
  bool? _tooltipThemeIsDark;

  /// Syncfusion delays desktop tooltip show by 50ms; hide again after that window.
  static const Duration _tooltipHideGrace = Duration(milliseconds: 80);

  void _onChartEnter(PointerEvent _) {
    _chartHovered = true;
  }

  void _clearHover() {
    _chartHovered = false;
    _tooltipBehavior?.hide();

    // Beat Syncfusion's delayed desktop show timer if the pointer left quickly.
    Future<void>.delayed(_tooltipHideGrace, () {
      if (!mounted || _chartHovered) {
        return;
      }
      _tooltipBehavior?.hide();
    });

    if (_hoveredIndex != null) {
      setState(() => _hoveredIndex = null);
    }
  }

  void _onTooltipRender(TooltipArgs args) {
    if (!_chartHovered) {
      _tooltipBehavior?.hide();
      return;
    }

    final int? index = args.pointIndex is int
        ? args.pointIndex as int
        : args.pointIndex?.toInt();
    if (index == null || index == _hoveredIndex) {
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

        final QuarterDataPoint item = data as QuarterDataPoint;
        return _BarTooltipCard(
          quarterLabel: item.label,
          metricTitle: widget.title,
          valueText: QuarterlyBarChartEngine.formatValue(item.value),
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

    final ColumnSeries<QuarterDataPoint, String> series =
        QuarterlyBarChartEngine.buildColumnSeries(
      data: widget.data,
      latestIndex: widget.data.isEmpty ? -1 : widget.data.length - 1,
      hoveredIndex: _hoveredIndex,
      theme: widget.theme,
      dataLabelStyle: dataLabelStyle,
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
              child: _QuarterlyBarChartCanvas(
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
                ),
                plotAreaLeftPadding: widget.theme.plotAreaLeftPadding,
                plotAreaRightPadding: widget.theme.plotAreaRightPadding,
                plotAreaTopPadding: widget.theme.plotAreaTopPadding,
              ),
            ),
          ),
        ],
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
    required this.data,
    required this.series,
    required this.tooltipBehavior,
    required this.onTooltipRender,
    required this.yAxis,
    required this.xAxis,
    required this.plotAreaLeftPadding,
    required this.plotAreaRightPadding,
    required this.plotAreaTopPadding,
  });

  final List<QuarterDataPoint> data;
  final ColumnSeries<QuarterDataPoint, String> series;
  final TooltipBehavior tooltipBehavior;
  final void Function(TooltipArgs args) onTooltipRender;
  final NumericAxis yAxis;
  final CategoryAxis xAxis;
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
      series: <CartesianSeries<QuarterDataPoint, String>>[series],
    );
  }
}
