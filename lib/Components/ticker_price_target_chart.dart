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

  @override
  Widget build(BuildContext context) {
    final Color gridColor = isDarkMode
        ? const Color(0xFF2A3038)
        : const Color(0xFFEEF1F5);
    final Color axisColor = HomeUi.borderLight(isDarkMode);
    final TextStyle axisLabelStyle = HomeUi.subtitle(isDarkMode).copyWith(
      fontSize: 11,
      height: 1.15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: isDarkMode
          ? const Color(0xFF9AA3B2)
          : const Color(0xFF64748B),
    );

    // Cohesive terminal palette — solid tones, no brand gradient wash.
    final Color historicalColor = HomeUi.chartBarColor(isDarkMode);
    final Color highColor =
        isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF059669);
    final Color meanColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final Color lowColor =
        isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final Color rangeBandColor = meanColor.withValues(
      alpha: isDarkMode ? 0.14 : 0.08,
    );
    final Color dividerColor = isDarkMode
        ? const Color(0xFF4B5563)
        : const Color(0xFFCBD5E1);

    final List<_ForecastRangePoint> rangeBand = _buildRangeBand();
    final List<_ForecastMarker> endMarkers = _buildEndMarkers(
      highColor: highColor,
      meanColor: meanColor,
      lowColor: lowColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LegendRow(
          isDarkMode: isDarkMode,
          historicalColor: historicalColor,
          highColor: highColor,
          meanColor: meanColor,
          lowColor: lowColor,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.fromLTRB(2, 10, 14, 2),
            legend: const Legend(isVisible: false),
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
            annotations: <CartesianChartAnnotation>[
              CartesianChartAnnotation(
                widget: Text(
                  'Forecast',
                  style: HomeUi.subtitle(isDarkMode).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                coordinateUnit: CoordinateUnit.point,
                x: chartData.anchorDate.add(const Duration(days: 28)),
                y: chartData.yMax,
                horizontalAlignment: ChartAlignment.near,
                verticalAlignment: ChartAlignment.far,
              ),
            ],
            primaryXAxis: DateTimeAxis(
              minimum: chartData.historical.first.date
                  .subtract(const Duration(days: 14)),
              maximum:
                  chartData.forecastEndDate.add(const Duration(days: 14)),
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
                  end: chartData.forecastEndDate
                      .add(const Duration(days: 14)),
                  color: isDarkMode
                      ? const Color(0xFF94A3B8).withValues(alpha: 0.04)
                      : const Color(0xFF64748B).withValues(alpha: 0.03),
                ),
                PlotBand(
                  isVisible: true,
                  start: chartData.anchorDate,
                  end: chartData.anchorDate,
                  borderWidth: 1.25,
                  borderColor: dividerColor,
                  dashArray: const <double>[3, 4],
                ),
              ],
            ),
            primaryYAxis: NumericAxis(
              minimum: chartData.yMin,
              maximum: chartData.yMax,
              majorGridLines: MajorGridLines(
                width: 1,
                color: gridColor,
                dashArray: const <double>[4, 4],
              ),
              majorTickLines: const MajorTickLines(size: 0),
              axisLine: const AxisLine(width: 0),
              labelStyle: axisLabelStyle,
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                return ChartAxisLabel(
                  '\$${details.value.toStringAsFixed(0)}',
                  details.textStyle,
                );
              },
            ),
            series: <CartesianSeries<dynamic, DateTime>>[
              if (rangeBand.length >= 2)
                RangeAreaSeries<_ForecastRangePoint, DateTime>(
                  name: 'Target Range',
                  dataSource: rangeBand,
                  xValueMapper: (_ForecastRangePoint p, _) => p.date,
                  highValueMapper: (_ForecastRangePoint p, _) => p.high,
                  lowValueMapper: (_ForecastRangePoint p, _) => p.low,
                  color: rangeBandColor,
                  borderColor: Colors.transparent,
                  borderWidth: 0,
                  enableTooltip: false,
                  animationDuration: 450,
                ),
              SplineAreaSeries<PriceDataPoint, DateTime>(
                name: 'Historical Price',
                dataSource: chartData.historical,
                xValueMapper: (PriceDataPoint point, _) => point.date,
                yValueMapper: (PriceDataPoint point, _) => point.value,
                borderWidth: 2.6,
                borderColor: historicalColor,
                color: historicalColor.withValues(
                  alpha: isDarkMode ? 0.22 : 0.14,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    historicalColor.withValues(
                      alpha: isDarkMode ? 0.28 : 0.18,
                    ),
                    historicalColor.withValues(alpha: 0.0),
                  ],
                ),
                markerSettings: const MarkerSettings(isVisible: false),
                animationDuration: 450,
              ),
              if (chartData.targetHigh.isNotEmpty)
                SplineSeries<PriceTargetForecastPoint, DateTime>(
                  name: 'Target High',
                  dataSource: chartData.targetHigh,
                  xValueMapper: (PriceTargetForecastPoint point, _) =>
                      point.date,
                  yValueMapper: (PriceTargetForecastPoint point, _) =>
                      point.price,
                  color: highColor,
                  width: 2.1,
                  dashArray: const <double>[7, 4],
                  markerSettings: const MarkerSettings(isVisible: false),
                  animationDuration: 450,
                ),
              if (chartData.targetMean.isNotEmpty)
                SplineSeries<PriceTargetForecastPoint, DateTime>(
                  name: 'Target Mean',
                  dataSource: chartData.targetMean,
                  xValueMapper: (PriceTargetForecastPoint point, _) =>
                      point.date,
                  yValueMapper: (PriceTargetForecastPoint point, _) =>
                      point.price,
                  color: meanColor,
                  width: 2.2,
                  dashArray: const <double>[7, 4],
                  markerSettings: const MarkerSettings(isVisible: false),
                  animationDuration: 450,
                ),
              if (chartData.targetLow.isNotEmpty)
                SplineSeries<PriceTargetForecastPoint, DateTime>(
                  name: 'Target Low',
                  dataSource: chartData.targetLow,
                  xValueMapper: (PriceTargetForecastPoint point, _) =>
                      point.date,
                  yValueMapper: (PriceTargetForecastPoint point, _) =>
                      point.price,
                  color: lowColor,
                  width: 2.1,
                  dashArray: const <double>[7, 4],
                  markerSettings: const MarkerSettings(isVisible: false),
                  animationDuration: 450,
                ),
              if (endMarkers.isNotEmpty)
                ScatterSeries<_ForecastMarker, DateTime>(
                  name: 'Targets',
                  dataSource: endMarkers,
                  xValueMapper: (_ForecastMarker m, _) => m.date,
                  yValueMapper: (_ForecastMarker m, _) => m.price,
                  pointColorMapper: (_ForecastMarker m, _) => m.color,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 8,
                    width: 8,
                    shape: DataMarkerType.circle,
                    borderWidth: 2,
                    borderColor: HomeUi.cardBg(isDarkMode),
                  ),
                  animationDuration: 450,
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<_ForecastRangePoint> _buildRangeBand() {
    final int n = chartData.targetHigh.length < chartData.targetLow.length
        ? chartData.targetHigh.length
        : chartData.targetLow.length;
    if (n < 2) return const <_ForecastRangePoint>[];

    return List<_ForecastRangePoint>.generate(n, (int i) {
      final PriceTargetForecastPoint high = chartData.targetHigh[i];
      final PriceTargetForecastPoint low = chartData.targetLow[i];
      return _ForecastRangePoint(
        date: high.date,
        high: high.price,
        low: low.price,
      );
    });
  }

  List<_ForecastMarker> _buildEndMarkers({
    required Color highColor,
    required Color meanColor,
    required Color lowColor,
  }) {
    final List<_ForecastMarker> markers = <_ForecastMarker>[];

    void addEnd(
      List<PriceTargetForecastPoint> series,
      Color color,
    ) {
      if (series.isEmpty) return;
      final PriceTargetForecastPoint end = series.lastWhere(
        (PriceTargetForecastPoint p) => p.isEndPoint,
        orElse: () => series.last,
      );
      markers.add(
        _ForecastMarker(date: end.date, price: end.price, color: color),
      );
    }

    addEnd(chartData.targetHigh, highColor);
    addEnd(chartData.targetMean, meanColor);
    addEnd(chartData.targetLow, lowColor);
    return markers;
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
    } else if (data is _ForecastMarker) {
      title = 'Target';
      body = '\$${data.price.toStringAsFixed(2)}';
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

class _ForecastRangePoint {
  const _ForecastRangePoint({
    required this.date,
    required this.high,
    required this.low,
  });

  final DateTime date;
  final double high;
  final double low;
}

class _ForecastMarker {
  const _ForecastMarker({
    required this.date,
    required this.price,
    required this.color,
  });

  final DateTime date;
  final double price;
  final Color color;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.isDarkMode,
    required this.historicalColor,
    required this.highColor,
    required this.meanColor,
    required this.lowColor,
  });

  final bool isDarkMode;
  final Color historicalColor;
  final Color highColor;
  final Color meanColor;
  final Color lowColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: <Widget>[
        _LegendItem(
          label: 'Price',
          color: historicalColor,
          isDarkMode: isDarkMode,
          solid: true,
        ),
        _LegendItem(
          label: 'High',
          color: highColor,
          isDarkMode: isDarkMode,
        ),
        _LegendItem(
          label: 'Mean',
          color: meanColor,
          isDarkMode: isDarkMode,
        ),
        _LegendItem(
          label: 'Low',
          color: lowColor,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.isDarkMode,
    this.solid = false,
  });

  final String label;
  final Color color;
  final bool isDarkMode;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 18,
          height: 10,
          child: CustomPaint(
            painter: _LegendStrokePainter(color: color, solid: solid),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: HomeUi.subtitle(isDarkMode).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? const Color(0xFF9AA3B2)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _LegendStrokePainter extends CustomPainter {
  const _LegendStrokePainter({required this.color, required this.solid});

  final Color color;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2;
    if (solid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }

    const double dash = 4;
    const double gap = 3;
    double x = 0;
    while (x < size.width) {
      final double end = (x + dash).clamp(0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LegendStrokePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.solid != solid;
  }
}
