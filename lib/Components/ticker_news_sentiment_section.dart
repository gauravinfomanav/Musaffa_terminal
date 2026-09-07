import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_news_sentiment_controller.dart';
import 'package:musaffa_terminal/models/news_sentiment_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// News sentiment — calm editorial layout (no icon wells / gradient chrome).
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'News Sentiment',
                style: HomeUi.sectionTitle(isDarkMode).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                _readingLine(model.sentiment),
                style: HomeUi.subtitle(isDarkMode).copyWith(
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _buildContent(context, model),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, NewsSentimentModel model) {
    final bool useVerticalLayout = MediaQuery.of(context).size.width < 1120;

    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildMetrics(model),
        const SizedBox(height: 18),
        _buildSentimentSplit(model.sentiment),
        const SizedBox(height: 18),
        _buildSectorCompare(model),
      ],
    );

    final Widget chart = _buildDonut(model.sentiment);

    if (useVerticalLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _softPanel(child: chart),
          const SizedBox(height: 14),
          _softPanel(child: details),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: _softPanel(child: details),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: _softPanel(
              child: chart,
              align: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _softPanel({
    required Widget child,
    AlignmentGeometry align = Alignment.topLeft,
  }) {
    return Container(
      width: double.infinity,
      alignment: align,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildMetrics(NewsSentimentModel model) {
    final List<({String label, String value})> items =
        <({String label, String value})>[
      (
        label: 'Company score',
        value: model.companyNewsScore.toStringAsFixed(2),
      ),
      (
        label: 'Articles (7d)',
        value: model.buzz.articlesInLastWeek.toString(),
      ),
      (
        label: 'Weekly avg',
        value: model.buzz.weeklyAverage.toStringAsFixed(1),
      ),
      (
        label: 'Buzz',
        value: model.buzz.buzz.toStringAsFixed(2),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final ({String label, String value}) item in items)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.label.toUpperCase(), style: _eyebrow),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: HomeUi.tableCellEmphasis(isDarkMode).copyWith(
                    fontSize: 18,
                    letterSpacing: -0.35,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSentimentSplit(NewsSentimentDistribution sentiment) {
    final double bullish = _toPercent(sentiment.bullishPercent);
    final double bearish = _toPercent(sentiment.bearishPercent);
    final double total = (bullish + bearish).clamp(0.0001, 200);
    final double bullShare = (bullish / total).clamp(0.0, 1.0);
    final Color bull = HomeUi.positive(isDarkMode);
    final Color bear = HomeUi.negative(isDarkMode);

    return _sectionBlock(
      title: 'Coverage mix',
      subtitle: 'Share of bullish vs bearish news coverage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: (bullShare * 1000).round().clamp(1, 999),
                    child: ColoredBox(color: bull),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: ((1 - bullShare) * 1000).round().clamp(1, 999),
                    child: ColoredBox(color: bear),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _splitStat(
                label: 'Bullish',
                value: _pctLabel(bullish),
                color: bull,
              ),
              const SizedBox(width: 36),
              _splitStat(
                label: 'Bearish',
                value: _pctLabel(bearish),
                color: bear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _splitStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: HomeUi.tableCellEmphasis(isDarkMode).copyWith(
            fontSize: 22,
            letterSpacing: -0.5,
            height: 1.1,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectorCompare(NewsSentimentModel model) {
    final bool aboveScore =
        model.companyNewsScore >= model.sectorAverageNewsScore;
    final bool aboveBullish = _toPercent(model.sentiment.bullishPercent) >=
        _toPercent(model.sectorAverageBullishPercent);

    return _sectionBlock(
      title: 'Sector context',
      subtitle: 'How this company compares with its sector',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _compareRow(
            leftLabel: 'Company news score',
            leftValue: model.companyNewsScore.toStringAsFixed(2),
            rightLabel: 'Sector average',
            rightValue: model.sectorAverageNewsScore.toStringAsFixed(2),
            note: aboveScore ? 'Above sector' : 'Below sector',
            notePositive: aboveScore,
          ),
          const SizedBox(height: 12),
          _compareRow(
            leftLabel: 'Company bullish',
            leftValue: _pctLabel(_toPercent(model.sentiment.bullishPercent)),
            rightLabel: 'Sector bullish',
            rightValue: _pctLabel(
              _toPercent(model.sectorAverageBullishPercent),
            ),
            note: aboveBullish ? 'Above sector' : 'Below sector',
            notePositive: aboveBullish,
          ),
        ],
      ),
    );
  }

  /// Clear group header — distinct from metric field labels.
  Widget _sectionBlock({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final Color rule =
        isDarkMode ? const Color(0xFF2A2F3A) : const Color(0xFFE4E7EC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(height: 1, thickness: 1, color: rule),
        const SizedBox(height: 14),
        Text(
          title,
          style: HomeUi.sectionTitle(isDarkMode).copyWith(
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: HomeUi.subtitle(isDarkMode).copyWith(
            fontSize: 12,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  Widget _compareRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    required String note,
    required bool notePositive,
  }) {
    final Color noteColor = notePositive
        ? HomeUi.positive(isDarkMode)
        : HomeUi.negative(isDarkMode);

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _compareCell(label: leftLabel, value: leftValue),
          ),
          Expanded(
            child: _compareCell(
              label: rightLabel,
              value: rightValue,
              trailing: Text(
                note,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: noteColor,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareCell({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                value,
                style: HomeUi.tableCellEmphasis(isDarkMode).copyWith(
                  fontSize: 18,
                  letterSpacing: -0.35,
                ),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 10),
              trailing,
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDonut(NewsSentimentDistribution sentiment) {
    final double bullish = _toPercent(sentiment.bullishPercent);
    final double bearish = _toPercent(sentiment.bearishPercent);
    final Color bull = HomeUi.positive(isDarkMode);
    final Color bear = HomeUi.negative(isDarkMode);
    final List<_SentimentSlice> data = <_SentimentSlice>[
      _SentimentSlice('Bullish', bullish, bull),
      _SentimentSlice('Bearish', bearish, bear),
    ];
    final bool leanBull = bullish >= bearish;
    final Color leanColor = leanBull ? bull : bear;
    final String leanLabel = leanBull ? 'Bullish' : 'Bearish';
    final double leanPct = leanBull ? bullish : bearish;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'Bullish vs bearish',
          style: HomeUi.sectionTitle(isDarkMode).copyWith(
            fontSize: 14,
            letterSpacing: -0.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Distribution of scored articles',
          style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 236,
          width: double.infinity,
          child: SfCircularChart(
            margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            annotations: <CircularChartAnnotation>[
              CircularChartAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _pctLabel(leanPct, decimals: 0),
                      style: HomeUi.tableCellEmphasis(isDarkMode).copyWith(
                        fontSize: 28,
                        letterSpacing: -0.8,
                        height: 1.05,
                        color: leanColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leanLabel,
                      style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
                    ),
                  ],
                ),
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
                radius: '88%',
                innerRadius: '72%',
                strokeWidth: 5,
                strokeColor: _panelBg,
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _legendDot(label: 'Bullish', value: _pctLabel(bullish), color: bull),
            const SizedBox(width: 20),
            _legendDot(label: 'Bearish', value: _pctLabel(bearish), color: bear),
          ],
        ),
      ],
    );
  }

  Widget _legendDot({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label  $value',
          style: HomeUi.subtitle(isDarkMode).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  TextStyle get _eyebrow => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDarkMode ? const Color(0xFF8B93A7) : const Color(0xFF7B8494),
      );

  Color get _panelBg =>
      isDarkMode ? const Color(0xFF12151C) : const Color(0xFFF6F7F9);

  /// Finnhub returns 0–1 fractions; some feeds already use 0–100.
  static double _toPercent(double raw) {
    if (raw < 0) return 0;
    if (raw <= 1.0) return raw * 100;
    return raw.clamp(0, 100);
  }

  static String _pctLabel(double percent, {int decimals = 0}) {
    if (decimals <= 0) {
      return '${percent.round()}%';
    }
    return '${percent.toStringAsFixed(decimals)}%';
  }

  String _readingLine(NewsSentimentDistribution sentiment) {
    final double bullish = _toPercent(sentiment.bullishPercent);
    final double bearish = _toPercent(sentiment.bearishPercent);
    if ((bullish - bearish).abs() < 8) {
      return 'Recent coverage is roughly balanced between bullish and bearish tone.';
    }
    if (bullish >= bearish) {
      return 'Recent coverage leans bullish — about ${_pctLabel(bullish, decimals: 0)} of scored articles.';
    }
    return 'Recent coverage leans bearish — about ${_pctLabel(bearish, decimals: 0)} of scored articles.';
  }
}

class _SentimentSlice {
  const _SentimentSlice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
