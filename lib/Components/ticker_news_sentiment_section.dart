import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_news_sentiment_controller.dart';
import 'package:musaffa_terminal/models/news_sentiment_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TickerNewsSentimentSection extends StatelessWidget {
  const TickerNewsSentimentSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
  });

  final TickerNewsSentimentController controller;
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
            child: TickerFinnhubLoadingState(
              isDarkMode: isDarkMode,
              height: 140,
            ),
          );
        }

        if (!controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const TickerFinnhubSectionTitle(title: 'News Sentiment'),
                const SizedBox(height: 8),
                TickerFinnhubEmptyState(
                  isDarkMode: isDarkMode,
                  message: controller.error ?? 'No news sentiment data found',
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

        final NewsSentimentModel model = controller.model!;
        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const TickerFinnhubSectionTitle(title: 'News Sentiment', fontSize: 18),
              const SizedBox(height: 12),
              _buildContentWithPie(model),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentWithPie(NewsSentimentModel model) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(model),
              const SizedBox(height: 12),
              _buildSentimentNumbers(model.sentiment),
              const SizedBox(height: 12),
              _buildComparisonCard(model),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: _buildSentimentPie(model.sentiment),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(NewsSentimentModel model) {
    final List<_SummaryItem> items = <_SummaryItem>[
      _SummaryItem('Company News Score', model.companyNewsScore.toStringAsFixed(2)),
      _SummaryItem('Articles Last Week', model.buzz.articlesInLastWeek.toString()),
      _SummaryItem('Weekly Average', model.buzz.weeklyAverage.toStringAsFixed(2)),
      _SummaryItem('News Buzz', model.buzz.buzz.toStringAsFixed(2)),
    ];

    return Column(
      children: <Widget>[
        Row(
          children: items.map((_SummaryItem item) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        fontSize: 13,
                        color:
                            isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.value,
                      style: DashboardTextStyles.dataCell.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Divider(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          height: 1,
        ),
      ],
    );
  }

  Widget _buildSentimentNumbers(NewsSentimentDistribution sentiment) {
    final double bullish = sentiment.bullishPercent.clamp(0, 100);
    final double bearish = sentiment.bearishPercent.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Sentiment',
          style: DashboardTextStyles.stockName.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 6),
        _comparisonRow(
          label: 'Bullish',
          value: FinnhubDisplayFormatters.formatPercent(bullish, signed: false),
        ),
        _comparisonRow(
          label: 'Bearish',
          value: FinnhubDisplayFormatters.formatPercent(bearish, signed: false),
        ),
        const SizedBox(height: 8),
        Divider(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          height: 1,
        ),
      ],
    );
  }

  Widget _buildSentimentPie(NewsSentimentDistribution sentiment) {
    final double bullish = sentiment.bullishPercent.clamp(0, 100);
    final double bearish = sentiment.bearishPercent.clamp(0, 100);
    final List<_SentimentSlice> data = <_SentimentSlice>[
      _SentimentSlice('Bullish', bullish, const Color(0xFF0DB47D)),
      _SentimentSlice('Bearish', bearish, const Color(0xFFDB161B)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Bullish vs Bearish',
          style: DashboardTextStyles.stockName.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 270,
          child: SfCircularChart(
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              overflowMode: LegendItemOverflowMode.wrap,
              textStyle: TextStyle(
                fontSize: 12,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CircularSeries<_SentimentSlice, String>>[
              PieSeries<_SentimentSlice, String>(
                dataSource: data,
                xValueMapper: (_SentimentSlice item, _) => item.label,
                yValueMapper: (_SentimentSlice item, _) => item.value,
                pointColorMapper: (_SentimentSlice item, _) => item.color,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(NewsSentimentModel model) {
    final bool aboveScore = model.companyNewsScore >= model.sectorAverageNewsScore;
    final bool aboveBullish =
        model.sentiment.bullishPercent >= model.sectorAverageBullishPercent;
    final String scoreStatus = aboveScore ? 'Above Sector' : 'Below Sector';
    final String bullishStatus = aboveBullish ? 'Above Sector' : 'Below Sector';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Sector Comparison',
          style: DashboardTextStyles.stockName.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 6),
        _comparisonRow(
          label: 'Company News Score',
          value: model.companyNewsScore.toStringAsFixed(2),
        ),
        _comparisonRow(
          label: 'Sector Avg Score',
          value: model.sectorAverageNewsScore.toStringAsFixed(2),
          trailing: scoreStatus,
          trailingColor: aboveScore ? const Color(0xFF0DB47D) : const Color(0xFFDB161B),
        ),
        const SizedBox(height: 4),
        _comparisonRow(
          label: 'Company Bullish %',
          value: FinnhubDisplayFormatters.formatPercent(
            model.sentiment.bullishPercent,
            signed: false,
          ),
        ),
        _comparisonRow(
          label: 'Sector Bullish %',
          value: FinnhubDisplayFormatters.formatPercent(
            model.sectorAverageBullishPercent,
            signed: false,
          ),
          trailing: bullishStatus,
          trailingColor: aboveBullish ? const Color(0xFF0DB47D) : const Color(0xFFDB161B),
        ),
      ],
    );
  }

  Widget _comparisonRow({
    required String label,
    required String value,
    String? trailing,
    Color? trailingColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: DashboardTextStyles.tickerSymbol.copyWith(fontSize: 13),
            ),
          ),
          Text(
            value,
            style: DashboardTextStyles.dataCell.copyWith(fontSize: 13),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 14,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: trailingColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.title, this.value);

  final String title;
  final String value;
}

class _SentimentSlice {
  const _SentimentSlice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
