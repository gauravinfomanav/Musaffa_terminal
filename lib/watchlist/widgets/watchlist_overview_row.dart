import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_market_summary_card.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_performance_card.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_top_movers_card.dart';

/// Compact three-card overview: Performance | Market Summary | Top Movers.
class WatchlistOverviewRow extends StatelessWidget {
  const WatchlistOverviewRow({
    super.key,
    required this.tableData,
    required this.isDarkMode,
    this.isTableLoading = false,
  });

  final List<SimpleRowModel> tableData;
  final bool isDarkMode;
  final bool isTableLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = constraints.maxWidth < 980;

        final Widget performance = WatchlistPerformanceCard(
          tableData: tableData,
          isDarkMode: isDarkMode,
          compact: true,
        );
        final Widget market = WatchlistMarketSummaryCard(isDarkMode: isDarkMode);
        final Widget movers = WatchlistTopMoversCard(
          tableData: tableData,
          isDarkMode: isDarkMode,
          isLoading: isTableLoading,
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 168, child: performance),
              const SizedBox(height: 10),
              SizedBox(
                height: 168,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: market),
                    const SizedBox(width: 10),
                    Expanded(child: movers),
                  ],
                ),
              ),
            ],
          );
        }

        return SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: performance),
              const SizedBox(width: 10),
              Expanded(flex: 4, child: market),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: movers),
            ],
          ),
        );
      },
    );
  }
}
