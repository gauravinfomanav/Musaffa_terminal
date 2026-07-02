import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/models/financial_statement_type.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/models/quarterly_chart_metric.dart';
import 'package:musaffa_terminal/charts/models/quarterly_chart_view_model.dart';
import 'package:musaffa_terminal/charts/models/stock_quarterly_financials.dart';

/// Maps Infomanav quarterly financials into [QuarterlyBarChart] data points.
class QuarterlyFinancialsMapper {
  const QuarterlyFinancialsMapper._();

  static const int defaultQuarterCount = 8;

  static final NumberFormat _headerFormat = NumberFormat('#,##0.0');
  static final NumberFormat _perShareFormat = NumberFormat('#,##0.00');

  static List<QuarterlyFinancialPeriod> latestQuarters(
    List<QuarterlyFinancialPeriod> financials, {
    int count = defaultQuarterCount,
  }) {
    final List<QuarterlyFinancialPeriod> sorted =
        List<QuarterlyFinancialPeriod>.from(financials)
          ..sort(
            (QuarterlyFinancialPeriod a, QuarterlyFinancialPeriod b) =>
                a.periodDate.compareTo(b.periodDate),
          );

    if (sorted.length <= count) {
      return sorted;
    }
    return sorted.sublist(sorted.length - count);
  }

  static List<QuarterlyChartViewModel> buildAllCharts(
    List<QuarterlyFinancialPeriod> quarters, {
    FinancialStatementType statement = FinancialStatementType.ic,
  }) {
    return QuarterlyChartMetric.forPeriods(quarters, statement)
        .map(
          (QuarterlyChartMetric metric) => buildChartForMetric(
            quarters: quarters,
            metric: metric,
          ),
        )
        .where((QuarterlyChartViewModel chart) => chart.hasData)
        .toList();
  }

  static QuarterlyChartViewModel buildChartForMetric({
    required List<QuarterlyFinancialPeriod> quarters,
    required QuarterlyChartMetric metric,
  }) {
    final List<QuarterDataPoint> data = toChartData(
      quarters,
      metric.valueSelector,
      metric.scale,
    );

    final double? latestRaw = quarters.isEmpty
        ? null
        : metric.valueSelector(quarters.last);

    return QuarterlyChartViewModel(
      metricKey: metric.key,
      title: metric.title,
      displayValue: latestRaw == null
          ? '--'
          : formatDisplayValue(latestRaw, metric.scale),
      unit: latestRaw == null ? '' : displayUnit(latestRaw, metric.scale),
      data: data,
    );
  }

  static List<QuarterDataPoint> toChartData(
    List<QuarterlyFinancialPeriod> quarters,
    double? Function(QuarterlyFinancialPeriod period) valueSelector,
    QuarterlyMetricScale scale,
  ) {
    return quarters
        .map((QuarterlyFinancialPeriod period) {
          final double? raw = valueSelector(period);
          if (raw == null) {
            return null;
          }
          return QuarterDataPoint(
            label: formatQuarterLabel(period.period),
            value: toChartValue(raw, scale),
          );
        })
        .whereType<QuarterDataPoint>()
        .toList();
  }

  static double toChartValue(double raw, QuarterlyMetricScale scale) {
    switch (scale) {
      case QuarterlyMetricScale.monetary:
        return toMonetaryChartValue(raw);
      case QuarterlyMetricScale.perShare:
      case QuarterlyMetricScale.shareCount:
        return raw;
    }
  }

  /// API monetary values are in millions; chart uses billions when |value| >= 1000M.
  static double toMonetaryChartValue(double valueInMillions) {
    if (valueInMillions.abs() >= 1000) {
      return valueInMillions / 1000;
    }
    return valueInMillions;
  }

  static String formatDisplayValue(double raw, QuarterlyMetricScale scale) {
    switch (scale) {
      case QuarterlyMetricScale.monetary:
        return _headerFormat.format(toMonetaryChartValue(raw));
      case QuarterlyMetricScale.perShare:
        return _perShareFormat.format(raw);
      case QuarterlyMetricScale.shareCount:
        return _headerFormat.format(raw);
    }
  }

  static String displayUnit(double raw, QuarterlyMetricScale scale) {
    switch (scale) {
      case QuarterlyMetricScale.monetary:
        return raw.abs() >= 1000 ? 'B' : 'M';
      case QuarterlyMetricScale.perShare:
        return '';
      case QuarterlyMetricScale.shareCount:
        return 'M';
    }
  }

  static String formatQuarterLabel(String period) {
    final DateTime? date = DateTime.tryParse(period);
    if (date == null) {
      return period;
    }

    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String year = (date.year % 100).toString().padLeft(2, '0');
    return "${months[date.month - 1]} '$year";
  }
}
