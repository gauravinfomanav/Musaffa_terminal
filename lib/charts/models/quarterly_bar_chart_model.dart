import 'package:flutter/material.dart';

/// A single quarterly data point for [QuarterlyBarChart].
class QuarterDataPoint {
  const QuarterDataPoint({
    required this.date,
    required this.label,
    required this.value,
  });

  /// Quarter-end date used on the time axis.
  final DateTime date;

  /// X-axis label, e.g. `"Jun '24"`.
  final String label;

  /// Metric value for the quarter, e.g. `368.4` or `-128.4`.
  final double value;
}

/// A daily or sampled stock price point for the overlay line.
class PriceDataPoint {
  const PriceDataPoint({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;
}


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
    this.priceLineColor = const Color.fromARGB(255, 213, 244, 187),
    this.priceAxisLabelColor = const Color(0xFF6B7280),
    this.priceLineAnimationDuration = 1000.0,
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
    this.mixedSignYAxisPadding = 200,
    this.plotAreaLeftPadding = 20,
    this.plotAreaRightPadding = 8,
    this.plotAreaTopPadding = 24,
    this.plotAreaBottomPadding = 8,
    this.firstBarGap = 10,
    this.inlineHeader = false,
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
  final Color priceLineColor;
  final Color priceAxisLabelColor;
  final double priceLineAnimationDuration;
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
  final double mixedSignYAxisPadding;
  final double plotAreaLeftPadding;
  final double plotAreaRightPadding;
  final double plotAreaTopPadding;
  final double plotAreaBottomPadding;
  final double firstBarGap;
  final bool inlineHeader;
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

/// Resolved Y-axis bounds for an overlaid price series.
class PriceYAxisRange {
  const PriceYAxisRange({
    required this.minimum,
    required this.maximum,
    required this.interval,
  });

  final double minimum;
  final double maximum;
  final double interval;
}
