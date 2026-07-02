import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';

/// Ready-to-render quarterly chart built from live API data.
class QuarterlyChartViewModel {
  const QuarterlyChartViewModel({
    required this.metricKey,
    required this.title,
    required this.displayValue,
    required this.unit,
    required this.data,
  });

  final String metricKey;
  final String title;
  final String displayValue;
  final String unit;
  final List<QuarterDataPoint> data;

  bool get hasData => data.isNotEmpty;
}
