import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/models/quarterly_chart_colors.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Builds Syncfusion cartesian chart primitives for [QuarterlyBarChart].
///
/// ## Syncfusion source references (v29.1.38, pub-cache)
///
/// This engine does **not** call `SfCartesianChart` directly from the widget.
/// Instead it centralises the series/axis construction that mirrors Syncfusion's
/// public API surface, which is implemented in:
///
/// | Concern | Syncfusion file | What we reuse |
/// |---------|-----------------|---------------|
/// | Chart shell | `lib/src/charts/cartesian_chart.dart` | `SfCartesianChart` plot area, margins, border |
/// | Column geometry | `lib/src/charts/series/column_series.dart` | `ColumnSeries`, `width`, `spacing`, `borderRadius`, `ColumnSegment.toRRect` rounding |
/// | Per-bar colour | `lib/src/charts/series/chart_series.dart` | `pointColorMapper` callback contract |
/// | Data labels | `lib/src/charts/common/data_label.dart` | `DataLabelSettings`, `ChartDataLabelPosition.outside`, `ChartDataLabelAlignment.auto` |
/// | Y axis | `lib/src/charts/axis/numeric_axis.dart` | `NumericAxis`, `majorGridLines`, hidden axis line |
/// | X axis | `lib/src/charts/axis/category_axis.dart` | `CategoryAxis`, category labels from `xValueMapper` |
///
/// ## Written fresh in this repo
///
/// - Y-axis nice-number interval calculation ([resolveYAxisRange])
/// - Per-chart border radius direction (top for positive bars, bottom for negative)
/// - Last-bar highlight via `pointColorMapper`
/// - Value formatting helpers
/// - Header is outside Syncfusion (built in the widget layer)
class QuarterlyBarChartEngine {
  const QuarterlyBarChartEngine._();

  static final NumberFormat _valueFormat = NumberFormat('#,##0.0');
  static final NumberFormat _axisNumberFormat = NumberFormat('#,##0.#');
  static final NumberFormat _priceAxisFormat = NumberFormat('#,##0.##');

  static String formatValue(double value) => _valueFormat.format(value);

  static String formatPriceDateLabel(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String year = (date.year % 100).toString().padLeft(2, '0');
    return "${months[date.month - 1]} ${date.day}, '$year";
  }

  static QuarterlyBarChartYAxisRange resolveYAxisRange({
    required List<QuarterDataPoint> data,
    required QuarterlyBarChartTheme theme,
  }) {
    if (theme.yAxisMinimum != null &&
        theme.yAxisMaximum != null &&
        theme.yAxisInterval != null) {
      return QuarterlyBarChartYAxisRange(
        minimum: theme.yAxisMinimum!,
        maximum: theme.yAxisMaximum!,
        interval: theme.yAxisInterval!,
      );
    }

    if (data.isEmpty) {
      return const QuarterlyBarChartYAxisRange(
        minimum: 0,
        maximum: 100,
        interval: 50,
      );
    }

    double minValue = data.first.value;
    double maxValue = data.first.value;
    for (final QuarterDataPoint point in data) {
      minValue = math.min(minValue, point.value);
      maxValue = math.max(maxValue, point.value);
    }

    final bool allPositive = minValue >= 0;
    final bool allNegative = maxValue <= 0;
    final bool mixedSigns = hasMixedSigns(data);

    if (mixedSigns &&
        theme.yAxisMinimum == null &&
        theme.yAxisMaximum == null) {
      final double padding = theme.mixedSignYAxisPadding;
      final double rawMin = minValue - padding;
      final double rawMax = maxValue + padding;
      final double interval = theme.yAxisInterval ??
          _mixedSignAxisInterval(rawMax - rawMin);

      return QuarterlyBarChartYAxisRange(
        minimum: (rawMin / interval).floorToDouble() * interval,
        maximum: (rawMax / interval).ceilToDouble() * interval,
        interval: interval,
      );
    }

    final double span = (maxValue - minValue).abs();
    final double axisPadding = span == 0
        ? math.max(1, maxValue.abs() * theme.yAxisPaddingRatio)
        : span * theme.yAxisPaddingRatio;
    final double labelHeadroom = maxValue > 0
        ? maxValue * theme.dataLabelHeadroomRatio
        : 0;
    final double negativeLabelHeadroom = minValue < 0
        ? minValue.abs() * theme.dataLabelHeadroomRatio
        : 0;

    double minimum = theme.yAxisMinimum ?? minValue;
    double maximum = theme.yAxisMaximum ?? maxValue;

    if (theme.yAxisMinimum == null || theme.yAxisMaximum == null) {
      if (theme.yAxisMinimum == null) {
        if (allPositive) {
          minimum = 0;
        } else if (allNegative) {
          maximum = 0;
          minimum = minValue - axisPadding - negativeLabelHeadroom;
        } else {
          minimum = minValue - axisPadding - negativeLabelHeadroom;
        }
      }

      if (theme.yAxisMaximum == null) {
        if (allPositive) {
          minimum = theme.yAxisMinimum ?? 0;
          maximum = maxValue + axisPadding + labelHeadroom;
        } else if (allNegative) {
          maximum = theme.yAxisMaximum ?? 0;
        } else {
          maximum = maxValue + axisPadding + labelHeadroom;
          minimum = theme.yAxisMinimum ??
              (minValue - axisPadding - negativeLabelHeadroom);
        }
      }
    }

    final double interval = theme.yAxisInterval ??
        _niceInterval((maximum - minimum).abs().clamp(1, double.infinity));

    if (theme.yAxisMinimum == null) {
      minimum = (minimum / interval).floorToDouble() * interval;
    }
    if (theme.yAxisMaximum == null) {
      maximum = (maximum / interval).ceilToDouble() * interval;
    }

    return QuarterlyBarChartYAxisRange(
      minimum: minimum,
      maximum: maximum,
      interval: interval,
    );
  }

  static PriceYAxisRange resolvePriceYAxisRange({
    required List<PriceDataPoint> data,
  }) {
    if (data.isEmpty) {
      return const PriceYAxisRange(
        minimum: 0,
        maximum: 100,
        interval: 50,
      );
    }

    double minValue = data.first.value;
    double maxValue = data.first.value;
    for (final PriceDataPoint point in data) {
      minValue = math.min(minValue, point.value);
      maxValue = math.max(maxValue, point.value);
    }

    final double span = (maxValue - minValue).abs();
    final double padding = span == 0 ? math.max(1, maxValue.abs() * 0.1) : span * 0.12;
    final double rawMin = math.max(0, minValue - padding);
    final double rawMax = maxValue + 200;
    final double interval =
        _niceInterval((rawMax - rawMin).abs().clamp(1, double.infinity));

    return PriceYAxisRange(
      minimum: (rawMin / interval).floorToDouble() * interval,
      maximum: (rawMax / interval).ceilToDouble() * interval,
      interval: interval,
    );
  }

  static bool isNegativeDominant(List<QuarterDataPoint> data) {
    if (data.isEmpty) {
      return false;
    }
    return data.every((QuarterDataPoint point) => point.value <= 0);
  }

  static bool hasMixedSigns(List<QuarterDataPoint> data) {
    if (data.isEmpty) {
      return false;
    }
    bool hasPositive = false;
    bool hasNegative = false;
    for (final QuarterDataPoint point in data) {
      if (point.value > 0) {
        hasPositive = true;
      } else if (point.value < 0) {
        hasNegative = true;
      }
    }
    return hasPositive && hasNegative;
  }

  static BorderRadius barBorderRadius({
    required QuarterlyBarChartTheme theme,
    required List<QuarterDataPoint> data,
  }) {
    final double radius = theme.barCornerRadius;
    if (hasMixedSigns(data)) {
      return BorderRadius.zero;
    }
    if (isNegativeDominant(data)) {
      return BorderRadius.only(
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  static NumericAxis buildYAxis({
    required QuarterlyBarChartYAxisRange range,
    required QuarterlyBarChartTheme theme,
    required TextStyle axisLabelStyle,
    required List<QuarterDataPoint> data,
  }) {
    return NumericAxis(
      minimum: range.minimum,
      maximum: range.maximum,
      interval: range.interval,
      numberFormat: _axisNumberFormat,
      axisLine: AxisLine(
        width: 1,
        color: theme.axisLineColor,
      ),
      majorTickLines: MajorTickLines(
        size: 4,
        color: theme.axisLineColor,
      ),
      minorTickLines: const MinorTickLines(size: 0),
      majorGridLines: MajorGridLines(
        width: 1,
        color: theme.gridLineColor,
      ),
      minorGridLines: const MinorGridLines(width: 0),
      labelStyle: axisLabelStyle,
      plotBands: const <PlotBand>[],
    );
  }

  static NumericAxis buildPriceYAxis({
    required PriceYAxisRange range,
    required QuarterlyBarChartTheme theme,
    required TextStyle axisLabelStyle,
  }) {
    return NumericAxis(
      name: 'priceAxis',
      opposedPosition: true,
      minimum: range.minimum,
      maximum: range.maximum,
      interval: range.interval,
      numberFormat: _priceAxisFormat,
      axisLine: AxisLine(
        width: 1,
        color: theme.axisLineColor,
      ),
      majorTickLines: MajorTickLines(
        size: 4,
        color: theme.axisLineColor,
      ),
      minorTickLines: const MinorTickLines(size: 0),
      majorGridLines: const MajorGridLines(width: 0),
      minorGridLines: const MinorGridLines(width: 0),
      labelStyle: axisLabelStyle.copyWith(
        color: theme.priceAxisLabelColor,
      ),
    );
  }

  static DateTime? resolveXAxisMinimum(
    List<QuarterDataPoint> data,
    List<PriceDataPoint> priceData,
  ) {
    final DateTime? minDate = _minimumDate(data, priceData);
    if (minDate == null) {
      return null;
    }
    return minDate.subtract(_resolveDateAxisEdgePadding(data, priceData));
  }

  static DateTime? resolveXAxisMaximum(
    List<QuarterDataPoint> data,
    List<PriceDataPoint> priceData,
  ) {
    final DateTime? maxDate = _maximumDate(data, priceData);
    if (maxDate == null) {
      return null;
    }
    return maxDate.add(_resolveDateAxisEdgePadding(data, priceData));
  }

  static ChartAxis buildXAxis({
    required QuarterlyBarChartTheme theme,
    required TextStyle axisLabelStyle,
    required List<QuarterDataPoint> data,
    required List<PriceDataPoint> priceData,
  }) {
    if (priceData.isEmpty) {
      return _buildCategoryXAxis(
        theme: theme,
        axisLabelStyle: axisLabelStyle,
        data: data,
      );
    }

    return _buildDateTimeXAxis(
      theme: theme,
      axisLabelStyle: axisLabelStyle,
      data: data,
      priceData: priceData,
    );
  }

  static CategoryAxis _buildCategoryXAxis({
    required QuarterlyBarChartTheme theme,
    required TextStyle axisLabelStyle,
    required List<QuarterDataPoint> data,
  }) {
    return CategoryAxis(
      arrangeByIndex: true,
      labelPlacement: LabelPlacement.onTicks,
      minimum: -0.5,
      maximum: data.length - 0.5,
      maximumLabels: data.length,
      labelIntersectAction: AxisLabelIntersectAction.multipleRows,
      axisLine: AxisLine(
        width: 1,
        color: theme.axisLineColor,
      ),
      majorTickLines: MajorTickLines(
        size: 4,
        color: theme.axisLineColor,
      ),
      majorGridLines: const MajorGridLines(width: 0),
      labelStyle: axisLabelStyle,
      plotOffset: theme.plotAreaBottomPadding,
    );
  }

  static DateTimeAxis _buildDateTimeXAxis({
    required QuarterlyBarChartTheme theme,
    required TextStyle axisLabelStyle,
    required List<QuarterDataPoint> data,
    required List<PriceDataPoint> priceData,
  }) {
    final bool crossesZero = hasMixedSigns(data) || isNegativeDominant(data);
    final DateTime? minDate = _minimumDate(data, priceData);
    final DateTime? maxDate = _maximumDate(data, priceData);
    final Duration edgePadding = _resolveDateAxisEdgePadding(data, priceData);

    final int quarterMonths = data.length >= 2
        ? ((data.last.date.difference(data.first.date).inDays) /
                (30.44 * (data.length - 1)))
            .round()
            .clamp(2, 4)
        : 3;

    return DateTimeAxis(
      minimum: minDate?.subtract(edgePadding),
      maximum: maxDate?.add(edgePadding),
      crossesAt: crossesZero ? 0 : null,
      axisLine: AxisLine(
        width: 1,
        color: theme.axisLineColor,
      ),
      majorTickLines: MajorTickLines(
        size: 4,
        color: theme.axisLineColor,
      ),
      majorGridLines: const MajorGridLines(width: 0),
      labelStyle: axisLabelStyle,
      interval: quarterMonths.toDouble(),
      intervalType: DateTimeIntervalType.months,
      desiredIntervals: data.length,
      edgeLabelPlacement: EdgeLabelPlacement.none,
      plotOffset: theme.plotAreaBottomPadding,
      plotOffsetStart: theme.firstBarGap,
      axisLabelFormatter: (AxisLabelRenderDetails details) {
        final num rawValue = details.value;
        final DateTime tickDate =
            DateTime.fromMillisecondsSinceEpoch(rawValue.toInt());

        QuarterDataPoint? nearest;
        int? nearestDays;
        for (final QuarterDataPoint point in data) {
          final int days =
              point.date.difference(tickDate).inDays.abs();
          if (nearestDays == null || days < nearestDays) {
            nearestDays = days;
            nearest = point;
          }
        }

        if (nearest != null && nearestDays != null && nearestDays <= 45) {
          return ChartAxisLabel(nearest.label, details.textStyle);
        }

        return ChartAxisLabel('', details.textStyle);
      },
    );
  }

  static CartesianSeries<QuarterDataPoint, dynamic> buildColumnSeries({
    required List<QuarterDataPoint> data,
    required int latestIndex,
    int? hoveredIndex,
    required QuarterlyBarChartTheme theme,
    required TextStyle dataLabelStyle,
    bool enableTooltip = true,
    bool categoryXAxis = false,
  }) {
    if (categoryXAxis) {
      return ColumnSeries<QuarterDataPoint, String>(
        dataSource: data,
        xValueMapper: (QuarterDataPoint point, _) => point.label,
        yValueMapper: (QuarterDataPoint point, _) => point.value,
        pointColorMapper: (QuarterDataPoint point, int index) {
          final bool isHighlighted =
              index == latestIndex || index == hoveredIndex;
          return QuarterlyChartColors.barColor(
            point.value,
            highlighted: isHighlighted,
          );
        },
        dataLabelMapper: (QuarterDataPoint point, _) => formatValue(point.value),
        width: theme.barWidth,
        spacing: theme.barSpacing,
        borderRadius: barBorderRadius(theme: theme, data: data),
        animationDuration: 0,
        enableTooltip: enableTooltip,
        dataLabelSettings: DataLabelSettings(
          isVisible: true,
          labelPosition: ChartDataLabelPosition.outside,
          labelAlignment: ChartDataLabelAlignment.auto,
          overflowMode: OverflowMode.shift,
          textStyle: dataLabelStyle,
          margin: const EdgeInsets.only(top: 6, bottom: 6),
        ),
      );
    }

    return ColumnSeries<QuarterDataPoint, DateTime>(
      dataSource: data,
      xValueMapper: (QuarterDataPoint point, _) => point.date,
      yValueMapper: (QuarterDataPoint point, _) => point.value,
      pointColorMapper: (QuarterDataPoint point, int index) {
        final bool isHighlighted =
            index == latestIndex || index == hoveredIndex;
        return QuarterlyChartColors.barColor(
          point.value,
          highlighted: isHighlighted,
        );
      },
      dataLabelMapper: (QuarterDataPoint point, _) => formatValue(point.value),
      width: theme.barWidth,
      spacing: theme.barSpacing,
      borderRadius: barBorderRadius(theme: theme, data: data),
      animationDuration: 0,
      enableTooltip: enableTooltip,
      dataLabelSettings: DataLabelSettings(
        isVisible: true,
        labelPosition: ChartDataLabelPosition.outside,
        labelAlignment: ChartDataLabelAlignment.auto,
        overflowMode: OverflowMode.shift,
        textStyle: dataLabelStyle,
        margin: const EdgeInsets.only(top: 6, bottom: 6),
      ),
    );
  }

  static LineSeries<PriceDataPoint, DateTime> buildPriceSeries({
    required List<PriceDataPoint> data,
    required QuarterlyBarChartTheme theme,
  }) {
    return LineSeries<PriceDataPoint, DateTime>(
      dataSource: data,
      xValueMapper: (PriceDataPoint point, _) => point.date,
      yValueMapper: (PriceDataPoint point, _) => point.value,
      yAxisName: 'priceAxis',
      color: theme.priceLineColor,
      width: 2,
      animationDuration: theme.priceLineAnimationDuration,
      enableTooltip: true,
      markerSettings: const MarkerSettings(isVisible: false),
    );
  }

  static TextStyle defaultTitleStyle(BuildContext context, bool isDark) {
    return TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
    );
  }

  static TextStyle defaultValueStyle(BuildContext context, bool isDark) {
    return TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A),
      height: 1.1,
    );
  }

  static TextStyle defaultUnitStyle(BuildContext context, bool isDark) {
    return TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
    );
  }

  static TextStyle defaultAxisLabelStyle(BuildContext context, bool isDark) {
    return TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
    );
  }

  static TextStyle defaultDataLabelStyle(BuildContext context, bool isDark) {
    return TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A),
    );
  }

  static double _niceInterval(double raw) {
    final double exponent = (math.log(raw) / math.ln10).floorToDouble();
    final double fraction = raw / math.pow(10, exponent);
    double niceFraction;
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
    return niceFraction * math.pow(10, exponent).toDouble();
  }

  /// Picks a readable tick step for mixed-sign charts without overshooting
  /// (e.g. range ~1000 should use 200, not jump to 2000).
  static double _mixedSignAxisInterval(double range) {
    if (range <= 0) {
      return 50;
    }

    const List<double> steps = <double>[
      25,
      50,
      100,
      200,
      250,
      500,
      1000,
      2000,
    ];

    for (final double step in steps) {
      final int tickCount = (range / step).ceil();
      if (tickCount >= 4 && tickCount <= 8) {
        return step;
      }
    }

    return _niceInterval(range);
  }

  static DateTime? _minimumDate(
    List<QuarterDataPoint> data,
    List<PriceDataPoint> priceData,
  ) {
    final Iterable<DateTime> dates = <DateTime>[
      ...data.map((QuarterDataPoint point) => point.date),
      ...priceData.map((PriceDataPoint point) => point.date),
    ];
    if (dates.isEmpty) {
      return null;
    }
    return dates.reduce(
      (DateTime current, DateTime next) => current.isBefore(next) ? current : next,
    );
  }

  static DateTime? _maximumDate(
    List<QuarterDataPoint> data,
    List<PriceDataPoint> priceData,
  ) {
    final Iterable<DateTime> dates = <DateTime>[
      ...data.map((QuarterDataPoint point) => point.date),
      ...priceData.map((PriceDataPoint point) => point.date),
    ];
    if (dates.isEmpty) {
      return null;
    }
    return dates.reduce(
      (DateTime current, DateTime next) => current.isAfter(next) ? current : next,
    );
  }

  static Duration _resolveDateAxisEdgePadding(
    List<QuarterDataPoint> data,
    List<PriceDataPoint> priceData,
  ) {
    if (priceData.length >= 2) {
      final List<DateTime> sorted = priceData
          .map((PriceDataPoint point) => point.date)
          .toList()
        ..sort();
      final int days = sorted[1].difference(sorted[0]).inDays.abs();
      return Duration(days: math.max(14, days * 8));
    }

    if (data.length >= 2) {
      final List<DateTime> sorted = data
          .map((QuarterDataPoint point) => point.date)
          .toList()
        ..sort();
      final int days = sorted[1].difference(sorted[0]).inDays.abs();
      return Duration(days: math.max(18, (days * 0.28).round()));
    }

    return const Duration(days: 21);
  }
}
