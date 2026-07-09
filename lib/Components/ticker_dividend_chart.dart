import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/models/dividend_entry.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
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
        .where((DividendEntry entry) => entry.amount != null)
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

    final Color axisColor =
        isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final Color textColor =
        isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final Color lineColor =
        isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);

    return TickerFinnhubSectionCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TickerFinnhubSectionTitle(title: 'Dividend Growth'),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: const EdgeInsets.only(top: 8, right: 8),
              primaryXAxis: CategoryAxis(
                majorGridLines: MajorGridLines(color: axisColor.withOpacity(0.3)),
                axisLine: AxisLine(color: axisColor),
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: textColor,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(color: axisColor.withOpacity(0.3)),
                axisLine: AxisLine(color: axisColor),
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: textColor,
                ),
                numberFormat: null,
                axisLabelFormatter: (AxisLabelRenderDetails details) {
                  return ChartAxisLabel(
                    '\$${details.value.toStringAsFixed(2)}',
                    details.textStyle,
                  );
                },
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF374151),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: Colors.white,
                ),
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
                  final DividendChartPoint item = data;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      '${item.label}\n'
                      'Amount: ${FinnhubDisplayFormatters.formatDividend(item.amount)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              series: <CartesianSeries<DividendChartPoint, String>>[
                LineSeries<DividendChartPoint, String>(
                  dataSource: points,
                  xValueMapper: (DividendChartPoint item, _) => item.label,
                  yValueMapper: (DividendChartPoint item, _) => item.amount,
                  color: lineColor,
                  width: 2,
                  markerSettings: const MarkerSettings(isVisible: true, height: 4, width: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
