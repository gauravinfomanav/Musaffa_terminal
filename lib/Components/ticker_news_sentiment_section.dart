import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_news_sentiment_controller.dart';
import 'package:musaffa_terminal/models/news_sentiment_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
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
              const TickerFinnhubSectionTitle(
                title: 'News Sentiment',
                fontSize: 18,
              ),
              const SizedBox(height: 12),
              _buildContentWithPie(context, model),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentWithPie(BuildContext context, NewsSentimentModel model) {
    final bool useVerticalLayout = MediaQuery.of(context).size.width < 1120;

    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSummaryCards(model),
        const SizedBox(height: 16),
        _buildSentimentNumbers(model.sentiment),
        const SizedBox(height: 16),
        _buildComparisonCard(model),
      ],
    );

    final Widget chart = _buildSentimentPie(model.sentiment);

    if (useVerticalLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          chart,
          const SizedBox(height: 16),
          details,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 5, child: details),
        const SizedBox(width: 18),
        Expanded(flex: 4, child: chart),
      ],
    );
  }

  Widget _buildSummaryCards(NewsSentimentModel model) {
    final List<_SummaryItem> items = <_SummaryItem>[
      _SummaryItem(
        'Company News Score',
        model.companyNewsScore.toStringAsFixed(2),
        Icons.auto_graph_rounded,
        const Color(0xFF3B82F6),
      ),
      _SummaryItem(
        'Articles Last Week',
        model.buzz.articlesInLastWeek.toString(),
        Icons.article_outlined,
        const Color(0xFF8B5CF6),
      ),
      _SummaryItem(
        'Weekly Average',
        model.buzz.weeklyAverage.toStringAsFixed(2),
        Icons.calendar_view_week_rounded,
        const Color(0xFFF59E0B),
      ),
      _SummaryItem(
        'News Buzz',
        model.buzz.buzz.toStringAsFixed(2),
        Icons.bolt_rounded,
        const Color(0xFF0DB47D),
      ),
    ];

    final Color line =
        isDarkMode ? const Color(0xFF2A2F3A) : const Color(0xFFE7EBF0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF151821) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2A2F3A) : const Color(0xFFE7EBF0),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: isDarkMode ? 0.28 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: i > 0
                          ? BorderSide(color: line)
                          : BorderSide.none,
                    ),
                  ),
                  child: _buildMetricTile(
                    label: items[i].title,
                    value: items[i].value,
                    icon: items[i].icon,
                    iconColor: items[i].iconColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                iconColor.withValues(alpha: isDarkMode ? 0.28 : 0.16),
                iconColor.withValues(alpha: isDarkMode ? 0.12 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: iconColor.withValues(alpha: isDarkMode ? 0.35 : 0.22),
            ),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 11,
            letterSpacing: 0.2,
            color: isDarkMode
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardTextStyles.dataCell.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel({
    required String title,
    required Widget child,
    IconData? icon,
    Color? accentColor,
  }) {
    final Color accent = accentColor ?? const Color(0xFF0DB47D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF151821) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2A2F3A) : const Color(0xFFE7EBF0),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: isDarkMode ? 0.28 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        accent.withValues(alpha: isDarkMode ? 0.28 : 0.16),
                        accent.withValues(alpha: isDarkMode ? 0.12 : 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: isDarkMode ? 0.35 : 0.22),
                    ),
                  ),
                  child: Icon(icon, color: accent, size: 17),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: DashboardTextStyles.stockName.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: DashboardTextStyles.tickerSymbol.copyWith(
                fontSize: 13,
                color: isDarkMode
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value,
            style: DashboardTextStyles.dataCell.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    final bool above = label.toLowerCase().contains('above');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: isDarkMode ? 0.28 : 0.16),
            color.withValues(alpha: isDarkMode ? 0.12 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: isDarkMode ? 0.22 : 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            above ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBanner(NewsSentimentDistribution sentiment) {
    final String label = _dominantSentimentLabel(sentiment);
    final Color color = _dominantSentimentColor(sentiment);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            color.withValues(alpha: isDarkMode ? 0.22 : 0.14),
            color.withValues(alpha: isDarkMode ? 0.10 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label based on recent news flow',
              style: DashboardTextStyles.dataCell.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentNumbers(NewsSentimentDistribution sentiment) {
    final double bullish = sentiment.bullishPercent.clamp(0, 100);
    final double bearish = sentiment.bearishPercent.clamp(0, 100);

    return _buildInfoPanel(
      title: 'Sentiment Snapshot',
      icon: Icons.insights_rounded,
      accentColor: const Color(0xFF0DB47D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildOverviewBanner(sentiment),
          const SizedBox(height: 12),
          _buildStatRow(
            label: 'Bullish',
            value:
                FinnhubDisplayFormatters.formatPercent(bullish, signed: false),
            valueColor: const Color(0xFF0DB47D),
          ),
          _buildStatRow(
            label: 'Bearish',
            value:
                FinnhubDisplayFormatters.formatPercent(bearish, signed: false),
            valueColor: const Color(0xFFDB161B),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentPie(NewsSentimentDistribution sentiment) {
    final double bullish = sentiment.bullishPercent.clamp(0, 100);
    final double bearish = sentiment.bearishPercent.clamp(0, 100);
    final List<_SentimentSlice> data = <_SentimentSlice>[
      _SentimentSlice('Bullish', bullish, const Color(0xFF0DB47D)),
      _SentimentSlice('Bearish', bearish, const Color(0xFFDB161B)),
    ];

    return _buildInfoPanel(
      title: 'Bullish vs Bearish',
      icon: Icons.donut_large_rounded,
      accentColor: const Color(0xFF3B82F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 320,
            child: SfCircularChart(
              margin: const EdgeInsets.fromLTRB(12, 28, 12, 28),
              annotations: <CircularChartAnnotation>[
                CircularChartAnnotation(
                  widget: _buildSentimentCenter(sentiment),
                ),
              ],
              legend: const Legend(isVisible: false),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CircularSeries<_SentimentSlice, String>>[
                DoughnutSeries<_SentimentSlice, String>(
                  dataSource: data,
                  xValueMapper: (_SentimentSlice item, _) => item.label,
                  yValueMapper: (_SentimentSlice item, _) => item.value,
                  pointColorMapper: (_SentimentSlice item, _) => item.color,
                  radius: '80%',
                  innerRadius: '70%',
                  strokeWidth: 3,
                  strokeColor:
                      isDarkMode ? const Color(0xFF111827) : Colors.white,
                  dataLabelMapper: (_SentimentSlice item, _) =>
                      '${item.value.toStringAsFixed(1)}%',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    connectorLineSettings: ConnectorLineSettings(
                      length: '18%',
                      type: ConnectorType.curve,
                    ),
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildChartLegend(data),
        ],
      ),
    );
  }

  Widget _buildSentimentCenter(NewsSentimentDistribution sentiment) {
    final String label = _dominantSentimentLabel(sentiment);
    final Color color = _dominantSentimentColor(sentiment);
    final double dominant = sentiment.bullishPercent >= sentiment.bearishPercent
        ? sentiment.bullishPercent
        : sentiment.bearishPercent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${dominant.toStringAsFixed(0)}%',
          style: DashboardTextStyles.dataCell.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 12,
            color:
                isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(List<_SentimentSlice> data) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: data.map((_SentimentSlice item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 12,
                  color: isDarkMode
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.value.toStringAsFixed(1),
                style: DashboardTextStyles.dataCell.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonCard(NewsSentimentModel model) {
    final bool aboveScore =
        model.companyNewsScore >= model.sectorAverageNewsScore;
    final bool aboveBullish =
        model.sentiment.bullishPercent >= model.sectorAverageBullishPercent;
    final Color line =
        isDarkMode ? const Color(0xFF2A2F3A) : const Color(0xFFE7EBF0);

    Widget comparisonRow({
      required Widget left,
      required Widget right,
    }) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: left),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: line)),
                ),
                child: right,
              ),
            ),
          ],
        ),
      );
    }

    return _buildInfoPanel(
      title: 'Sector Comparison',
      icon: Icons.compare_arrows_rounded,
      accentColor: _scoreAccent(model.companyNewsScore),
      child: Column(
        children: <Widget>[
          comparisonRow(
            left: _buildComparisonTile(
              label: 'Company News Score',
              value: model.companyNewsScore.toStringAsFixed(2),
            ),
            right: _buildComparisonTile(
              label: 'Sector Avg Score',
              value: model.sectorAverageNewsScore.toStringAsFixed(2),
              badgeLabel: aboveScore ? 'Above Sector' : 'Below Sector',
              badgeColor: aboveScore
                  ? const Color(0xFF0DB47D)
                  : const Color(0xFFDB161B),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, thickness: 1, color: line),
          ),
          comparisonRow(
            left: _buildComparisonTile(
              label: 'Company Bullish %',
              value: FinnhubDisplayFormatters.formatPercent(
                model.sentiment.bullishPercent,
                signed: false,
              ),
            ),
            right: _buildComparisonTile(
              label: 'Sector Bullish %',
              value: FinnhubDisplayFormatters.formatPercent(
                model.sectorAverageBullishPercent,
                signed: false,
              ),
              badgeLabel: aboveBullish ? 'Above Sector' : 'Below Sector',
              badgeColor: aboveBullish
                  ? const Color(0xFF0DB47D)
                  : const Color(0xFFDB161B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTile({
    required String label,
    required String value,
    String? badgeLabel,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 11,
              letterSpacing: 0.2,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTextStyles.dataCell.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
              if (badgeLabel != null && badgeColor != null) ...<Widget>[
                const SizedBox(width: 8),
                _buildStatusBadge(badgeLabel, badgeColor),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _dominantSentimentLabel(NewsSentimentDistribution sentiment) {
    final double bullish = sentiment.bullishPercent.clamp(0, 100);
    final double bearish = sentiment.bearishPercent.clamp(0, 100);
    return bullish >= bearish ? 'Bullish Bias' : 'Bearish Bias';
  }

  Color _dominantSentimentColor(NewsSentimentDistribution sentiment) {
    final double bullish = sentiment.bullishPercent.clamp(0, 100);
    final double bearish = sentiment.bearishPercent.clamp(0, 100);
    return bullish >= bearish
        ? const Color(0xFF0DB47D)
        : const Color(0xFFDB161B);
  }

  Color _scoreAccent(double score) {
    if (score >= 0.7) return const Color(0xFF0DB47D);
    if (score >= 0.4) return const Color(0xFFF59E0B);
    return const Color(0xFFDB161B);
  }
}

class _SummaryItem {
  const _SummaryItem(this.title, this.value, this.icon, this.iconColor);

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
}

class _SentimentSlice {
  const _SentimentSlice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
