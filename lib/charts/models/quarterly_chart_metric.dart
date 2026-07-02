import 'package:musaffa_terminal/charts/models/financial_statement_type.dart';
import 'package:musaffa_terminal/charts/models/quarterly_metric_labels.dart';
import 'package:musaffa_terminal/charts/models/stock_quarterly_financials.dart';

enum QuarterlyMetricScale {
  /// Large dollar amounts in millions from API (display as B/M).
  monetary,

  /// Per-share values such as diluted EPS.
  perShare,

  /// Share counts in millions.
  shareCount,
}

/// One financial field rendered as a quarterly bar chart.
class QuarterlyChartMetric {
  const QuarterlyChartMetric({
    required this.key,
    required this.title,
    required this.scale,
    required this.valueSelector,
  });

  final String key;
  final String title;
  final QuarterlyMetricScale scale;
  final double? Function(QuarterlyFinancialPeriod period) valueSelector;

  static List<QuarterlyChartMetric> forPeriods(
    List<QuarterlyFinancialPeriod> periods,
    FinancialStatementType statement,
  ) {
    final Set<String> keys = <String>{};
    for (final QuarterlyFinancialPeriod period in periods) {
      keys.addAll(period.values.keys);
    }

    return QuarterlyMetricLabels.orderedKeys(keys, statement)
        .map(
          (String key) => QuarterlyChartMetric(
            key: key,
            title: '${QuarterlyMetricLabels.titleFor(key, statement)} Qtr',
            scale: scaleForKey(key),
            valueSelector: (QuarterlyFinancialPeriod period) =>
                period.valueFor(key),
          ),
        )
        .toList();
  }

  static QuarterlyMetricScale scaleForKey(String key) {
    final String lower = key.toLowerCase();
    if (lower.contains('eps') ||
        lower.contains('pershare') ||
        lower == 'tangiblebookvaluepershare') {
      return QuarterlyMetricScale.perShare;
    }
    if (lower.contains('shares') || lower == 'commonstock') {
      return QuarterlyMetricScale.shareCount;
    }
    return QuarterlyMetricScale.monetary;
  }
}
