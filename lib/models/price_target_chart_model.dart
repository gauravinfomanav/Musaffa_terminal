import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';

class PriceTargetForecastPoint {
  const PriceTargetForecastPoint({
    required this.date,
    required this.price,
    required this.targetType,
    required this.numberAnalysts,
    required this.lastUpdated,
    this.isEndPoint = false,
  });

  final DateTime date;
  final double price;
  final String targetType;
  final int numberAnalysts;
  final DateTime? lastUpdated;
  final bool isEndPoint;
}

class PriceTargetChartData {
  const PriceTargetChartData({
    required this.historical,
    required this.targetHigh,
    required this.targetMean,
    required this.targetLow,
    required this.anchorDate,
    required this.forecastEndDate,
    required this.yMin,
    required this.yMax,
  });

  final List<PriceDataPoint> historical;
  final List<PriceTargetForecastPoint> targetHigh;
  final List<PriceTargetForecastPoint> targetMean;
  final List<PriceTargetForecastPoint> targetLow;
  final DateTime anchorDate;
  final DateTime forecastEndDate;
  final double yMin;
  final double yMax;

  bool get hasHistorical => historical.isNotEmpty;
  bool get hasForecast =>
      targetHigh.length >= 2 ||
      targetMean.length >= 2 ||
      targetLow.length >= 2;
}
