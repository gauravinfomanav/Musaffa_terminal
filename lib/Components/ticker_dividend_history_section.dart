import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_dividend_chart.dart';
import 'package:musaffa_terminal/Controllers/ticker_dividend_controller.dart';
import 'package:musaffa_terminal/models/dividend_entry.dart';

class TickerDividendHistorySection extends StatelessWidget {
  const TickerDividendHistorySection({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  final TickerDividendController controller;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isLoading && !controller.hasData) {
          return TickerDividendChart(
            entries: const <DividendEntry>[],
            isDarkMode: isDarkMode,
            isLoading: true,
          );
        }

        if (!controller.hasData) {
          return const SizedBox.shrink();
        }

        return TickerDividendChart(
          entries: controller.chartEntries,
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}
