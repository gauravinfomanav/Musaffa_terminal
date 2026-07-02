import 'package:flutter/material.dart';

/// A single quarterly data point for [QuarterlyBarChart].
class QuarterDataPoint {
  const QuarterDataPoint({
    required this.label,
    required this.value,
  });

  /// X-axis label, e.g. `"Jun '24"`.
  final String label;

  /// Metric value for the quarter, e.g. `368.4` or `-128.4`.
  final double value;
}

/// Visual + layout configuration for [QuarterlyBarChart].
///
/// All typography, axis, grid, and bar geometry are overridable so the same
/// widget can be reused across metrics with dynamic data later.
class QuarterlyBarChartTheme {
  const QuarterlyBarChartTheme({
    this.titleStyle,
    this.valueStyle,
    this.unitStyle,
    this.axisLabelStyle,
    this.dataLabelStyle,
    this.gridLineColor = const Color(0xFFE5E7EB),
    this.axisLineColor = const Color(0xFFD1D5DB),
    this.cardBackgroundColor = Colors.white,
    this.cardBorderColor = const Color(0xFFE5E7EB),
    this.barWidth = 0.55,
    this.barSpacing = 0.08,
    this.barCornerRadius = 4,
    this.chartHeight = 220,
    this.cardPadding = const EdgeInsets.fromLTRB(16, 14, 12, 12),
    this.yAxisInterval,
    this.yAxisMinimum,
    this.yAxisMaximum,
    this.yAxisPaddingRatio = 0.18,
    this.dataLabelHeadroomRatio = 0.18,
    this.plotAreaLeftPadding = 20,
    this.plotAreaRightPadding = 8,
    this.plotAreaTopPadding = 24,
    this.plotAreaBottomPadding = 8,
    this.firstBarGap = 10,
  });

  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final TextStyle? unitStyle;
  final TextStyle? axisLabelStyle;
  final TextStyle? dataLabelStyle;
  final Color gridLineColor;
  final Color axisLineColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final double barWidth;
  final double barSpacing;
  final double barCornerRadius;
  final double chartHeight;
  final EdgeInsets cardPadding;
  final double? yAxisInterval;
  final double? yAxisMinimum;
  final double? yAxisMaximum;
  final double yAxisPaddingRatio;
  final double dataLabelHeadroomRatio;
  final double plotAreaLeftPadding;
  final double plotAreaRightPadding;
  final double plotAreaTopPadding;
  final double plotAreaBottomPadding;
  final double firstBarGap;
}

/// Resolved Y-axis bounds for a dataset.
class QuarterlyBarChartYAxisRange {
  const QuarterlyBarChartYAxisRange({
    required this.minimum,
    required this.maximum,
    required this.interval,
  });

  final double minimum;
  final double maximum;
  final double interval;
}
