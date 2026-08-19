import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/price_target_chart_model.dart';
import 'package:musaffa_terminal/models/price_target_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
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

  static const Color _brandOrange = Color(0xFFE4621E);
  static const Color _brandPurple = Color(0xFF6A2C72);

  @override
  Widget build(BuildContext context) {
    final Color axisColor = HomeUi.borderLight(isDarkMode);
    final TextStyle axisLabelStyle = HomeUi.subtitle(isDarkMode).copyWith(
      fontSize: 11,
      height: 1.15,
      fontWeight: FontWeight.w500,
    );
    final Color historicalColor = _brandOrange;
    final Color highColor = HomeUi.positive(isDarkMode);
    final Color meanColor = _brandPurple;
    final Color lowColor = HomeUi.negative(isDarkMode);

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: const EdgeInsets.fromLTRB(4, 8, 12, 0),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          overflowMode: LegendItemOverflowMode.wrap,
          toggleSeriesVisibility: true,
          padding: 0,
          itemPadding: 12,
          iconHeight: 10,
          iconWidth: 18,
          textStyle: HomeUi.tableCellSecondary(isDarkMode).copyWith(
            fontSize: 12,
          ),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: Colors.transparent,
          borderColor: Colors.transparent,
          elevation: 0,
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
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          axisLine: AxisLine(width: 1, color: axisColor),
          labelStyle: axisLabelStyle,
          labelIntersectAction: AxisLabelIntersectAction.none,
          plotBands: <PlotBand>[
            PlotBand(
              isVisible: true,
              start: chartData.anchorDate,
              end: chartData.anchorDate,
              borderWidth: 1,
              borderColor: HomeUi.borderStrong(isDarkMode),
              dashArray: const <double>[4, 4],
            ),
          ],
        ),
        primaryYAxis: NumericAxis(
          minimum: chartData.yMin,
          maximum: chartData.yMax,
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          axisLine: AxisLine(width: 1, color: axisColor),
          labelStyle: axisLabelStyle,
          axisLabelFormatter: (AxisLabelRenderDetails details) {
            return ChartAxisLabel(
              '\$${details.value.toStringAsFixed(0)}',
              details.textStyle,
            );
          },
        ),
        series: <CartesianSeries<dynamic, DateTime>>[
          SplineAreaSeries<PriceDataPoint, DateTime>(
            name: 'Historical Price',
            dataSource: chartData.historical,
            xValueMapper: (PriceDataPoint point, _) => point.date,
            yValueMapper: (PriceDataPoint point, _) => point.value,
            borderWidth: 2.5,
            borderColor: historicalColor,
            color: historicalColor.withValues(alpha: 0.12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                historicalColor.withValues(alpha: isDarkMode ? 0.32 : 0.22),
                _brandPurple.withValues(alpha: isDarkMode ? 0.08 : 0.03),
              ],
            ),
            markerSettings: const MarkerSettings(isVisible: false),
            legendIconType: LegendIconType.horizontalLine,
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
            ),
        ],
      ),
    );
  }

  Widget _buildTooltip(dynamic data) {
    String title;
    String body;
    if (data is PriceDataPoint) {
      title = _tooltipDateFormat.format(data.date);
      body = 'Close  \$${data.value.toStringAsFixed(2)}';
    } else if (data is PriceTargetForecastPoint && data.isEndPoint) {
      title = data.targetType;
      body =
          'Target  \$${data.price.toStringAsFixed(2)}\n'
          'Analysts  ${data.numberAnalysts}\n'
          'Updated  ${FinnhubDisplayFormatters.formatDate(data.lastUpdated)}';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDarkMode),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDarkMode)),
        boxShadow: HomeUi.cardShadow(isDarkMode),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title, style: HomeUi.tableCellSecondary(isDarkMode)),
          const SizedBox(height: 6),
          Text(body, style: HomeUi.tableCellEmphasis(isDarkMode)),
        ],
      ),
    );
  }
}
