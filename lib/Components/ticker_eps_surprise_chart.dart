import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Components/ticker_earnings_compact_chart.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/earnings_surprise.dart';

class TickerEpsSurpriseChart extends StatelessWidget {
  const TickerEpsSurpriseChart({
    super.key,
    required this.surprises,
    required this.isDarkMode,
    this.isLoading = false,
    this.containerHeight,
  });

  final List<EarningsSurprise> surprises;
  final bool isDarkMode;
  final bool isLoading;
  final double? containerHeight;

  @override
  Widget build(BuildContext context) {
    final double resolvedHeight =
        containerHeight ?? TickerEarningsCompactChart.defaultHeight;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: ShimmerWidgets.chartShimmer(
          height: resolvedHeight,
          baseColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey.shade300,
          highlightColor:
              isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade100,
        ),
      );
    }

    final List<QuarterDataPoint> points = surprises
        .where((EarningsSurprise item) => item.surprisePercent != null)
        .map(
          (EarningsSurprise item) => QuarterDataPoint(
            date: item.period,
            label: item.quarterLabel,
            value: item.surprisePercent!,
          ),
        )
        .toList()
      ..sort(
        (QuarterDataPoint a, QuarterDataPoint b) => a.date.compareTo(b.date),
      );

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final QuarterDataPoint latest = points.last;

    return TickerEarningsCompactChart.build(
      title: 'EPS Surprise %',
      displayValue: latest.value.toStringAsFixed(1),
      unit: '%',
      data: points,
      isDarkMode: isDarkMode,
      containerHeight: resolvedHeight,
    );
  }
}
