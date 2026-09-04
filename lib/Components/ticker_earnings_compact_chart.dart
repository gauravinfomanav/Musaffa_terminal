import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/widgets/quarterly_bar_chart.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Compact [QuarterlyBarChart] styling shared across ticker earnings charts.
class TickerEarningsCompactChart {
  const TickerEarningsCompactChart._();

  static const double cardHeight = 280;

  static QuarterlyBarChartTheme theme({
    required bool isDarkMode,
  }) {
    return QuarterlyBarChartTheme(
      cardBackgroundColor: HomeUi.cardBg(isDarkMode),
      cardBorderColor: HomeUi.borderLight(isDarkMode),
      gridLineColor: HomeUi.borderLight(isDarkMode),
      axisLineColor: HomeUi.borderLight(isDarkMode),
      priceAxisLabelColor: HomeUi.accent(isDarkMode),
      cardPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      titleStyle: HomeUi.sectionTitle(isDarkMode).copyWith(fontSize: 15),
      valueStyle: HomeUi.tableCellEmphasis(isDarkMode).copyWith(
        fontSize: 18,
        letterSpacing: -0.4,
        height: 1.1,
      ),
      unitStyle: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
      inlineHeader: true,
      barWidth: 0.42,
      barSpacing: 0.14,
      barCornerRadius: 5,
      barColor: HomeUi.chartBarColor(isDarkMode),
      negativeBarColor: HomeUi.chartNegativeBarColor(isDarkMode),
      expandChart: true,
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
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: containerHeight ?? cardHeight,
      child: QuarterlyBarChart(
        title: title,
        displayValue: displayValue,
        unit: unit,
        data: data,
        theme: theme(isDarkMode: isDarkMode),
      ),
    );
  }
}
