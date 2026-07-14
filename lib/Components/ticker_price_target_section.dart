import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Components/ticker_price_target_chart.dart';
import 'package:musaffa_terminal/Controllers/ticker_price_target_controller.dart';
import 'package:musaffa_terminal/models/price_target_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TickerPriceTargetSection extends StatelessWidget {
  const TickerPriceTargetSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
  });

  final TickerPriceTargetController controller;
  final bool isDarkMode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isLoading && !controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: 12),
                TickerFinnhubLoadingState(
                  isDarkMode: isDarkMode,
                  height: 280,
                ),
              ],
            ),
          );
        }

        if (!controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: 8),
                TickerFinnhubEmptyState(
                  isDarkMode: isDarkMode,
                  message: controller.error ?? 'No analyst price target data found',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final PriceTargetModel target = controller.priceTarget!;
        final chartData = controller.chartData!;

        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 12),
              _buildSummaryCards(target),
              const SizedBox(height: 12),
              TickerPriceTargetChart(
                chartData: chartData,
                priceTarget: target,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const TickerFinnhubSectionTitle(title: 'Analyst Price Target'),
        const SizedBox(height: 4),
        Text(
          'Past 12 Months with 12 Month Forecast',
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 12,
            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(PriceTargetModel target) {
    final List<List<String>> cards = <List<String>>[
      <String>['Mean Target', _formatPrice(target.targetMean)],
      <String>['High Target', _formatPrice(target.targetHigh)],
      <String>['Low Target', _formatPrice(target.targetLow)],
      <String>['Analysts', target.numberAnalysts.toString()],
      <String>[
        'Last Updated',
        FinnhubDisplayFormatters.formatDate(target.lastUpdated),
      ],
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useTwoRows = constraints.maxWidth < 720;
        if (useTwoRows) {
          return Column(
            children: <Widget>[
              Row(
                children: cards.take(3).map(_buildSummaryCard).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: cards.skip(3).map(_buildSummaryCard).toList(),
              ),
            ],
          );
        }

        return Row(
          children: cards.map(_buildSummaryCard).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(List<String> card) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              card[0],
              style: DashboardTextStyles.tickerSymbol.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              card[1],
              style: DashboardTextStyles.dataCell.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double value) {
    if (value <= 0) return '--';
    return '\$${value.toStringAsFixed(2)}';
  }
}
