import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/price_target_chart_model.dart';
import 'package:musaffa_terminal/models/price_target_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TickerPriceTargetChart extends StatelessWidget {
  const TickerPriceTargetChart({
    super.key,
    required this.chartData,
    required this.priceTarget,
    required this.isDarkMode,
  });

  final PriceTargetChartData chartData;
  final PriceTargetModel priceTarget;
  final bool isDarkMode;

  static final DateFormat _axisDateFormat = DateFormat('MMM yy');
  static final DateFormat _tooltipDateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final Color axisColor =
        isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final Color textColor =
        isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final Color historicalColor =
        isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);
    const Color highColor = Color(0xFF22C55E);
    const Color meanColor = Color(0xFFF59E0B);
    const Color lowColor = Color(0xFFEF4444);

    return SizedBox(
      height: 280,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: const EdgeInsets.only(top: 4, right: 8),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          overflowMode: LegendItemOverflowMode.wrap,
          toggleSeriesVisibility: true,
          textStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: textColor,
          ),
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
            return _buildTooltip(data);
          },
        ),
        primaryXAxis: DateTimeAxis(
          minimum: chartData.historical.first.date
              .subtract(const Duration(days: 14)),
          maximum: chartData.forecastEndDate.add(const Duration(days: 14)),
          dateFormat: _axisDateFormat,
          majorGridLines: MajorGridLines(color: axisColor.withOpacity(0.3)),
          axisLine: AxisLine(color: axisColor),
          labelStyle: TextStyle(
            fontSize: 10,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: textColor,
          ),
          plotBands: <PlotBand>[
            PlotBand(
              isVisible: true,
              start: chartData.anchorDate,
              end: chartData.anchorDate,
              borderWidth: 1,
              borderColor: textColor.withOpacity(0.45),
              dashArray: const <double>[4, 4],
            ),
          ],
        ),
        primaryYAxis: NumericAxis(
          minimum: chartData.yMin,
          maximum: chartData.yMax,
          title: AxisTitle(
            text: 'Stock Price',
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: textColor,
            ),
          ),
          majorGridLines: MajorGridLines(color: axisColor.withOpacity(0.3)),
          axisLine: AxisLine(color: axisColor),
          labelStyle: TextStyle(
            fontSize: 10,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: textColor,
          ),
          axisLabelFormatter: (AxisLabelRenderDetails details) {
            return ChartAxisLabel(
              '\$${details.value.toStringAsFixed(0)}',
              details.textStyle,
            );
          },
        ),
        series: <CartesianSeries<dynamic, DateTime>>[
          LineSeries<PriceDataPoint, DateTime>(
            name: 'Historical Price',
            dataSource: chartData.historical,
            xValueMapper: (PriceDataPoint point, _) => point.date,
            yValueMapper: (PriceDataPoint point, _) => point.value,
            color: historicalColor,
            width: 2,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
          if (chartData.targetHigh.isNotEmpty)
            LineSeries<PriceTargetForecastPoint, DateTime>(
              name: 'Target High',
              dataSource: chartData.targetHigh,
              xValueMapper: (PriceTargetForecastPoint point, _) => point.date,
              yValueMapper: (PriceTargetForecastPoint point, _) => point.price,
              color: highColor,
              width: 2,
              dashArray: const <double>[6, 4],
              markerSettings: const MarkerSettings(isVisible: false),
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.outer,
                builder: (
                  dynamic data,
                  ChartPoint<dynamic> point,
                  ChartSeries<dynamic, dynamic> series,
                  int pointIndex,
                  int seriesIndex,
                ) {
                  final PriceTargetForecastPoint? item =
                      data is PriceTargetForecastPoint ? data : null;
                  if (item == null || !item.isEndPoint) {
                    return const SizedBox.shrink();
                  }
                  return _buildEndLabel(
                    label: 'High',
                    price: item.price,
                    color: highColor,
                    isDarkMode: isDarkMode,
                  );
                },
              ),
            ),
          if (chartData.targetMean.isNotEmpty)
            LineSeries<PriceTargetForecastPoint, DateTime>(
              name: 'Target Mean',
              dataSource: chartData.targetMean,
              xValueMapper: (PriceTargetForecastPoint point, _) => point.date,
              yValueMapper: (PriceTargetForecastPoint point, _) => point.price,
              color: meanColor,
              width: 2,
              dashArray: const <double>[6, 4],
              markerSettings: const MarkerSettings(isVisible: false),
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.outer,
                builder: (
                  dynamic data,
                  ChartPoint<dynamic> point,
                  ChartSeries<dynamic, dynamic> series,
                  int pointIndex,
                  int seriesIndex,
                ) {
                  final PriceTargetForecastPoint? item =
                      data is PriceTargetForecastPoint ? data : null;
                  if (item == null || !item.isEndPoint) {
                    return const SizedBox.shrink();
                  }
                  return _buildEndLabel(
                    label: 'Mean',
                    price: item.price,
                    color: meanColor,
                    isDarkMode: isDarkMode,
                  );
                },
              ),
            ),
          if (chartData.targetLow.isNotEmpty)
            LineSeries<PriceTargetForecastPoint, DateTime>(
              name: 'Target Low',
              dataSource: chartData.targetLow,
              xValueMapper: (PriceTargetForecastPoint point, _) => point.date,
              yValueMapper: (PriceTargetForecastPoint point, _) => point.price,
              color: lowColor,
              width: 2,
              dashArray: const <double>[6, 4],
              markerSettings: const MarkerSettings(isVisible: false),
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.outer,
                builder: (
                  dynamic data,
                  ChartPoint<dynamic> point,
                  ChartSeries<dynamic, dynamic> series,
                  int pointIndex,
                  int seriesIndex,
                ) {
                  final PriceTargetForecastPoint? item =
                      data is PriceTargetForecastPoint ? data : null;
                  if (item == null || !item.isEndPoint) {
                    return const SizedBox.shrink();
                  }
                  return _buildEndLabel(
                    label: 'Low',
                    price: item.price,
                    color: lowColor,
                    isDarkMode: isDarkMode,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEndLabel({
    required String label,
    required double price,
    required Color color,
    required bool isDarkMode,
  }) {
    return Text(
      '$label\n\$${price.toStringAsFixed(2)}',
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: color,
        height: 1.2,
      ),
    );
  }

  Widget _buildTooltip(dynamic data) {
    if (data is PriceDataPoint) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          'Date: ${_tooltipDateFormat.format(data.date)}\n'
          'Closing Price: \$${data.value.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 10,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: Colors.white,
          ),
        ),
      );
    }

    if (data is PriceTargetForecastPoint && data.isEndPoint) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          'Target Type: ${data.targetType}\n'
          'Target Price: \$${data.price.toStringAsFixed(2)}\n'
          'Analysts: ${data.numberAnalysts}\n'
          'Last Updated: ${FinnhubDisplayFormatters.formatDate(data.lastUpdated)}',
          style: const TextStyle(
            fontSize: 10,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: Colors.white,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
