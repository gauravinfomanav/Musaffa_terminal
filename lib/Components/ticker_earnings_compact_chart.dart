import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/widgets/quarterly_bar_chart.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Compact [QuarterlyBarChart] styling shared across ticker earnings charts.
class TickerEarningsCompactChart {
  const TickerEarningsCompactChart._();

  static const double defaultHeight = 220;
  static const double chartChromeHeight = 58;

  static double resolveChartHeight({double? containerHeight}) {
    if (containerHeight == null) {
      return defaultHeight - chartChromeHeight;
    }
    return math.max(72, containerHeight - chartChromeHeight);
  }

  static QuarterlyBarChartTheme theme({
    required bool isDarkMode,
    double? containerHeight,
  }) {
    final Color titleColor =
        isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final Color valueColor =
        isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A);

    return QuarterlyBarChartTheme(
      cardBackgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      cardBorderColor:
          isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
      gridLineColor:
          isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
      axisLineColor:
          isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
      priceAxisLabelColor:
          isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
      chartHeight: resolveChartHeight(containerHeight: containerHeight),
      cardPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      titleStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: titleColor,
      ),
      valueStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: valueColor,
        height: 1.1,
      ),
      unitStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: titleColor,
      ),
      inlineHeader: true,
    );
  }

  static Widget build({
    required String title,
    required String displayValue,
    required String unit,
    required List<QuarterDataPoint> data,
    required bool isDarkMode,
    double? containerHeight,
  }) {
    final double resolvedHeight = containerHeight ?? defaultHeight;

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: resolvedHeight,
      child: QuarterlyBarChart(
        title: title,
        displayValue: displayValue,
        unit: unit,
        data: data,
        theme: theme(
          isDarkMode: isDarkMode,
          containerHeight: resolvedHeight,
        ),
      ),
    );
  }
}
