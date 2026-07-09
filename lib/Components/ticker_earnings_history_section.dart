import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Components/ticker_earnings_compact_chart.dart';
import 'package:musaffa_terminal/Controllers/ticker_earnings_controller.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';

typedef _EarningsValueSelector = double? Function(EarningsCalendarEntry entry);

class TickerEarningsHistorySection extends StatelessWidget {
  const TickerEarningsHistorySection({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  final TickerEarningsController controller;
  final bool isDarkMode;

  static const double _chartHeight = TickerEarningsCompactChart.defaultHeight;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isLoadingCalendar &&
            controller.lastFourHistoricalQuarters.isEmpty) {
          return _buildLoadingRow();
        }

        final List<EarningsCalendarEntry> quarters =
            controller.lastFourHistoricalQuarters;
        if (quarters.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<_MetricChartConfig> charts = <_MetricChartConfig>[
          _MetricChartConfig(
            title: 'EPS Estimate',
            unit: '',
            selector: (EarningsCalendarEntry entry) => entry.epsEstimate,
            formatDisplay: _formatEps,
          ),
          _MetricChartConfig(
            title: 'EPS Actual',
            unit: '',
            selector: (EarningsCalendarEntry entry) => entry.epsActual,
            formatDisplay: _formatEps,
          ),
          _MetricChartConfig(
            title: 'Revenue Estimate',
            unit: 'B',
            selector: (EarningsCalendarEntry entry) =>
                _toRevenueBillions(entry.revenueEstimate),
            formatDisplay: _formatRevenueBillions,
          ),
          _MetricChartConfig(
            title: 'Revenue Actual',
            unit: 'B',
            selector: (EarningsCalendarEntry entry) =>
                _toRevenueBillions(entry.revenueActual),
            formatDisplay: _formatRevenueBillions,
          ),
        ];

        final List<Widget> rowChildren = <Widget>[];
        for (int index = 0; index < charts.length; index++) {
          if (index > 0) {
            rowChildren.add(const SizedBox(width: 16));
          }

          final _MetricChartConfig config = charts[index];
          final List<QuarterDataPoint> points =
              _buildPoints(quarters, config.selector);

          rowChildren.add(
            Expanded(
              child: points.isEmpty
                  ? const SizedBox.shrink()
                  : TickerEarningsCompactChart.build(
                      title: config.title,
                      displayValue: config.formatDisplay(points.last.value),
                      unit: config.unit,
                      data: points,
                      isDarkMode: isDarkMode,
                      containerHeight: _chartHeight,
                    ),
            ),
          );
        }

        final bool hasAnyChart = charts.any(
          (_MetricChartConfig config) =>
              _buildPoints(quarters, config.selector).isNotEmpty,
        );
        if (!hasAnyChart) {
          return const SizedBox.shrink();
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        );
      },
    );
  }

  Widget _buildLoadingRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int index = 0; index < 4; index++) ...<Widget>[
          if (index > 0) const SizedBox(width: 16),
          Expanded(
            child: ShimmerWidgets.chartShimmer(
              height: _chartHeight,
              baseColor:
                  isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey.shade300,
              highlightColor:
                  isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade100,
            ),
          ),
        ],
      ],
    );
  }

  List<QuarterDataPoint> _buildPoints(
    List<EarningsCalendarEntry> quarters,
    _EarningsValueSelector selector,
  ) {
    return quarters
        .map((EarningsCalendarEntry entry) {
          final double? value = selector(entry);
          if (value == null) {
            return null;
          }
          return QuarterDataPoint(
            date: entry.date,
            label: entry.quarterLabel,
            value: value,
          );
        })
        .whereType<QuarterDataPoint>()
        .toList();
  }

  static double? _toRevenueBillions(double? value) {
    if (value == null) {
      return null;
    }
    return value / 1000000000;
  }

  static String _formatEps(double value) {
    return value.toStringAsFixed(2);
  }

  static String _formatRevenueBillions(double value) {
    return value.toStringAsFixed(1);
  }
}

class _MetricChartConfig {
  const _MetricChartConfig({
    required this.title,
    required this.unit,
    required this.selector,
    required this.formatDisplay,
  });

  final String title;
  final String unit;
  final _EarningsValueSelector selector;
  final String Function(double value) formatDisplay;
}
