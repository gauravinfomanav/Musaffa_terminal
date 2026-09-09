import 'package:musaffa_terminal/charts/engine/quarterly_bar_chart_engine.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';

/// Ready-to-render quarterly chart built from live API data.
class QuarterlyChartViewModel {
  const QuarterlyChartViewModel({
    required this.metricKey,
    required this.title,
    required this.displayValue,
    required this.unit,
    required this.data,
    this.priceData = const <PriceDataPoint>[],
  });

  final String metricKey;
  final String title;
  final String displayValue;
  final String unit;
  final List<QuarterDataPoint> data;
  final List<PriceDataPoint> priceData;

  bool get hasData => data.isNotEmpty;

  /// Bars + price overlay clipped to an inclusive period range.
  QuarterlyChartViewModel inPeriodRange(DateTime start, DateTime end) {
    final DateTime rangeStart = DateTime(start.year, start.month, start.day);
    final DateTime rangeEnd = DateTime(end.year, end.month, end.day);

    bool inRange(DateTime date) {
      final DateTime day = DateTime(date.year, date.month, date.day);
      return !day.isBefore(rangeStart) && !day.isAfter(rangeEnd);
    }

    final List<QuarterDataPoint> filteredData =
        data.where((QuarterDataPoint point) => inRange(point.date)).toList();
    final List<PriceDataPoint> filteredPrice = priceData
        .where((PriceDataPoint point) => inRange(point.date))
        .toList();

    if (filteredData.isEmpty) {
      return QuarterlyChartViewModel(
        metricKey: metricKey,
        title: title,
        displayValue: displayValue,
        unit: unit,
        data: filteredData,
        priceData: filteredPrice,
      );
    }

    final QuarterDataPoint latest = filteredData.last;
    return QuarterlyChartViewModel(
      metricKey: metricKey,
      title: title,
      displayValue: QuarterlyBarChartEngine.formatValue(latest.value),
      unit: unit,
      data: filteredData,
      priceData: filteredPrice,
    );
  }
}
