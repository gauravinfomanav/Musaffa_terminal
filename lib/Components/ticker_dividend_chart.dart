import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/models/dividend_entry.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DividendChartPoint {
  const DividendChartPoint({
    required this.date,
    required this.amount,
    required this.label,
  });

  final DateTime date;
  final double amount;
  final String label;
}

class TickerDividendChart extends StatelessWidget {
  const TickerDividendChart({
    super.key,
    required this.entries,
    required this.isDarkMode,
    this.isLoading = false,
  });

  final List<DividendEntry> entries;
  final bool isDarkMode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return TickerFinnhubSectionCard(
        isDarkMode: isDarkMode,
        child: TickerFinnhubLoadingState(isDarkMode: isDarkMode, height: 220),
      );
    }

    final List<DividendChartPoint> points = entries
        .where((DividendEntry entry) =>
            entry.amount != null && entry.amount! > 0)
        .map(
          (DividendEntry entry) => DividendChartPoint(
            date: entry.date,
            amount: entry.amount!,
            label: FinnhubDisplayFormatters.formatShortDate(entry.date),
          ),
        )
        .toList()
      ..sort((DividendChartPoint a, DividendChartPoint b) =>
          a.date.compareTo(b.date));

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color axisColor = HomeUi.borderLight(isDarkMode);
    final TextStyle axisLabelStyle = HomeUi.subtitle(isDarkMode).copyWith(
      fontSize: 11,
      height: 1.15,
      fontWeight: FontWeight.w500,
    );
    final Color lineColor = const Color(0xFFE4621E);
    final double maxAmount = points
        .map((DividendChartPoint p) => p.amount)
        .reduce((double a, double b) => a > b ? a : b);
    final double yMax = maxAmount <= 0 ? 1 : maxAmount * 1.32;

    return TickerFinnhubSectionCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HomeUi.tableToolbarHeader(
            isDarkMode,
            icon: Icons.show_chart,
            title: 'Dividend Growth',
            subtitleText: 'Historical dividend per share',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 236,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: const EdgeInsets.fromLTRB(8, 20, 14, 8),
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(width: 1, color: axisColor),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: axisLabelStyle,
                labelIntersectAction: AxisLabelIntersectAction.none,
                edgeLabelPlacement: EdgeLabelPlacement.shift,
                desiredIntervals: 5,
                plotOffset: 8,
                axisLabelFormatter: (AxisLabelRenderDetails details) {
                  final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                    details.value.toInt(),
                  );
                  return ChartAxisLabel(
                    FinnhubDisplayFormatters.formatShortDate(date),
                    details.textStyle,
                  );
                },
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: yMax,
                rangePadding: ChartRangePadding.none,
                plotOffsetEnd: 18,
                plotOffsetStart: 10,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(width: 1, color: axisColor),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: axisLabelStyle,
                axisLabelFormatter: (AxisLabelRenderDetails details) {
                  return ChartAxisLabel(
                    '\$${details.value.toStringAsFixed(2)}',
                    details.textStyle,
                  );
                },
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: HomeUi.cardBg(isDarkMode),
                borderColor: HomeUi.borderLight(isDarkMode),
                textStyle: HomeUi.tableCell(isDarkMode),
                builder: (
                  dynamic data,
                  dynamic point,
                  dynamic series,
                  int pointIndex,
                  int seriesIndex,
                ) {
                  if (data is! DividendChartPoint) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: HomeUi.cardBg(isDarkMode),
                      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                      border: Border.all(color: HomeUi.borderLight(isDarkMode)),
                    ),
                    child: Text(
                      '${data.label}\n'
                      'Amount: ${FinnhubDisplayFormatters.formatDividend(data.amount)}',
                      style: HomeUi.tableCell(isDarkMode).copyWith(fontSize: 12),
                    ),
                  );
                },
              ),
              series: <CartesianSeries<DividendChartPoint, DateTime>>[
                AreaSeries<DividendChartPoint, DateTime>(
                  dataSource: points,
                  xValueMapper: (DividendChartPoint item, _) => item.date,
                  yValueMapper: (DividendChartPoint item, _) => item.amount,
                  borderDrawMode: BorderDrawMode.top,
                  borderWidth: 2.5,
                  borderColor: lineColor,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      lineColor.withValues(alpha: isDarkMode ? 0.38 : 0.28),
                      const Color(0xFF6A2C72)
                          .withValues(alpha: isDarkMode ? 0.10 : 0.04),
                    ],
                  ),
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    color: HomeUi.cardBg(isDarkMode),
                    borderWidth: 2,
                    borderColor: lineColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
