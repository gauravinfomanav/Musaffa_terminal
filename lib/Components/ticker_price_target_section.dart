import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Components/ticker_price_target_chart.dart';
import 'package:musaffa_terminal/Controllers/ticker_price_target_controller.dart';
import 'package:musaffa_terminal/models/price_target_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

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
                HomeUi.ghostAction(
                  label: 'Retry',
                  onTap: onRetry,
                  dark: isDarkMode,
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
              const SizedBox(height: 16),
              _buildSummaryCards(target),
              const SizedBox(height: 16),
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
        const TickerFinnhubSectionTitle(
          title: 'Analyst Price Target',
          icon: Icons.ads_click_outlined,
          subtitle: 'Past 12 months with 12-month forecast',
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
              _buildSummaryRow(cards.take(3).toList()),
              const SizedBox(height: 10),
              _buildSummaryRow(cards.skip(3).toList()),
            ],
          );
        }

        return _buildSummaryRow(cards);
      },
    );
  }

  Widget _buildSummaryRow(List<List<String>> cards) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < cards.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: HomeUi.detailSummaryMetric(
              dark: isDarkMode,
              label: cards[i][0],
              value: cards[i][1],
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(double value) {
    if (value <= 0) return '--';
    return '\$${value.toStringAsFixed(2)}';
  }
}
