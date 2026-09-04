import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/models/recommendation_model.dart';
import 'package:musaffa_terminal/models/recommendation_trend_model.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class RecommendationWidget extends StatefulWidget {
  final String symbol;
  final RecommendationController controller;

  const RecommendationWidget({
    Key? key,
    required this.symbol,
    required this.controller,
  }) : super(key: key);

  @override
  State<RecommendationWidget> createState() => _RecommendationWidgetState();
}

class _RecommendationWidgetState extends State<RecommendationWidget> {
  static const Color _strongBuy = Color(0xFF059669);
  static const Color _buy = Color(0xFF34D399);
  static const Color _hold = Color(0xFFE4621E);
  static const Color _sell = Color(0xFFF87171);
  static const Color _strongSell = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    if (!widget.controller.isLoading &&
        widget.controller.recommendation == null &&
        widget.controller.error == null) {
      widget.controller.fetchRecommendation(widget.symbol);
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return _buildShimmerLoading();
        }

        if (widget.controller.error != null) {
          return const SizedBox.shrink();
        }

        final recommendation = widget.controller.recommendation;
        if (recommendation == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeUi.tableToolbarHeader(
                _isDark,
                icon: Icons.thumbs_up_down_outlined,
                title: 'Recommendation Trend',
                subtitleText: 'Analyst consensus over the last 12 months',
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTrendPanel(recommendation),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: _buildRatingsPanel(recommendation),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendPanel(RecommendationModel recommendation) {
    if (widget.controller.isTrendLoading &&
        widget.controller.trendHistory.isEmpty) {
      return _buildTrendLoading();
    }
    if (widget.controller.trendError != null &&
        widget.controller.trendHistory.isEmpty) {
      return _buildTrendError();
    }
    if (widget.controller.trendHistory.isEmpty) {
      return _buildTrendEmpty();
    }

    final List<RecommendationTrendModel> trends = widget.controller.trendHistory;
    final RecommendationTrendModel latest = trends.last;
    final RecommendationTrendModel? previous =
        trends.length > 1 ? trends[trends.length - 2] : null;
    final String trendText = _deriveTrendText(latest, previous);
    final Color? trendColor = trendText == 'More Bullish'
        ? HomeUi.positive(_isDark)
        : trendText == 'More Bearish'
            ? HomeUi.negative(_isDark)
            : null;
    final Color? consensusColor = latest.consensusText.toLowerCase().contains('buy')
        ? HomeUi.positive(_isDark)
        : latest.consensusText.toLowerCase().contains('sell')
            ? HomeUi.negative(_isDark)
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HomeUi.detailSummaryMetricsRow(
          dark: _isDark,
          items: [
            (
              label: 'Current Consensus',
              value: latest.consensusText,
              valueColor: consensusColor,
            ),
            (
              label: 'Latest Analysts',
              value: latest.total.toString(),
              valueColor: null,
            ),
            (
              label: 'Trend',
              value: trendText,
              valueColor: trendColor,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 248,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.fromLTRB(0, 8, 8, 0),
            legend: Legend(
              isVisible: false,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: Colors.transparent,
              borderColor: Colors.transparent,
              elevation: 0,
              builder: (
                dynamic data,
                dynamic point,
                dynamic series,
                int pointIndex,
                int seriesIndex,
              ) {
                if (pointIndex < 0 || pointIndex >= trends.length) {
                  return const SizedBox.shrink();
                }
                return _trendTooltip(trends[pointIndex]);
              },
            ),
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              axisLine: AxisLine(width: 1, color: HomeUi.borderLight(_isDark)),
              labelPlacement: LabelPlacement.onTicks,
              labelIntersectAction: AxisLabelIntersectAction.none,
              maximumLabels: 6,
              labelStyle: HomeUi.subtitle(_isDark).copyWith(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: const MajorGridLines(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              axisLine: AxisLine(width: 1, color: HomeUi.borderLight(_isDark)),
              labelStyle: HomeUi.subtitle(_isDark).copyWith(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
            series: <CartesianSeries<RecommendationTrendModel, String>>[
              _trendLine('Strong Buy', _strongBuy, trends, (t) => t.strongBuy),
              _trendLine('Buy', _buy, trends, (t) => t.buy),
              _trendLine('Hold', _hold, trends, (t) => t.hold),
              _trendLine('Sell', _sell, trends, (t) => t.sell),
              _trendLine('Strong Sell', _strongSell, trends, (t) => t.strongSell),
            ],
          ),
        ),
      ],
    );
  }

  SplineSeries<RecommendationTrendModel, String> _trendLine(
    String name,
    Color color,
    List<RecommendationTrendModel> trends,
    int Function(RecommendationTrendModel) y,
  ) {
    return SplineSeries<RecommendationTrendModel, String>(
      name: name,
      color: color,
      width: 2.4,
      dataSource: trends,
      xValueMapper: (RecommendationTrendModel t, _) => _formatPeriod(t.period),
      yValueMapper: (RecommendationTrendModel t, _) => y(t),
      markerSettings: const MarkerSettings(isVisible: false),
      legendIconType: LegendIconType.horizontalLine,
    );
  }

  Widget _trendTooltip(RecommendationTrendModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(_isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(_isDark)),
        boxShadow: HomeUi.cardShadow(_isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _formatPeriod(p.period),
            style: HomeUi.tableCellSecondary(_isDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Strong Buy  ${p.strongBuy}\n'
            'Buy  ${p.buy}\n'
            'Hold  ${p.hold}\n'
            'Sell  ${p.sell}\n'
            'Strong Sell  ${p.strongSell}',
            style: HomeUi.tableCellEmphasis(_isDark).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsPanel(RecommendationModel recommendation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYST RATINGS',
          style: HomeUi.overline(_isDark).copyWith(
            fontSize: 10,
            letterSpacing: 1.1,
            color: HomeUi.title(_isDark),
          ),
        ),
        const SizedBox(height: 14),
        _ratingRow('Strong Buy', recommendation.strongBuy, _strongBuy,
            widget.controller.getStrongBuyPercentage()),
        _ratingRow('Buy', recommendation.buy, _buy,
            widget.controller.getBuyPercentage()),
        _ratingRow('Hold', recommendation.hold, _hold,
            widget.controller.getHoldPercentage()),
        _ratingRow('Sell', recommendation.sell, _sell,
            widget.controller.getSellPercentage()),
        _ratingRow('Strong Sell', recommendation.strongSell, _strongSell,
            widget.controller.getStrongSellPercentage()),
        const SizedBox(height: 14),
        Text(
          'Total  ${widget.controller.totalRecommendations}',
          style: HomeUi.tableCellSecondary(_isDark),
        ),
      ],
    );
  }

  Widget _ratingRow(String label, int count, Color color, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: HomeUi.tableCellSecondary(_isDark).copyWith(fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    Container(color: HomeUi.elevatedBg(_isDark)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (percentage / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: HomeUi.tableNumeric(_isDark),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              count.toString(),
              textAlign: TextAlign.right,
              style: HomeUi.tableCellEmphasis(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPeriod(String period) {
    final DateTime? date = DateTime.tryParse(period);
    if (date == null) return period;
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String year = (date.year % 100).toString().padLeft(2, '0');
    return "${months[date.month - 1]} '$year";
  }

  String _deriveTrendText(
    RecommendationTrendModel latest,
    RecommendationTrendModel? previous,
  ) {
    if (previous == null) return 'Stable';
    final int bullishLatest = latest.strongBuy + latest.buy;
    final int bullishPrevious = previous.strongBuy + previous.buy;
    if (bullishLatest > bullishPrevious) return 'More Bullish';
    if (bullishLatest < bullishPrevious) return 'More Bearish';
    return 'Stable';
  }

  Widget _buildTrendLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShimmerWidgets.box(height: 56, width: double.infinity),
        const SizedBox(height: 14),
        ShimmerWidgets.box(height: 220, width: double.infinity),
      ],
    );
  }

  Widget _buildTrendError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Unable to load recommendation trend',
          style: HomeUi.subtitle(_isDark),
        ),
        const SizedBox(height: 10),
        HomeUi.ghostAction(
          label: 'Retry',
          onTap: () => widget.controller.fetchRecommendationTrends(
            widget.symbol,
            forceRefresh: true,
          ),
          dark: _isDark,
        ),
      ],
    );
  }

  Widget _buildTrendEmpty() {
    return Text(
      'No recommendation trend data found',
      style: HomeUi.subtitle(_isDark),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                ShimmerWidgets.box(height: 36, width: 220),
                const SizedBox(height: 16),
                ShimmerWidgets.box(height: 220, width: double.infinity),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidgets.box(height: 14, width: 100),
                const SizedBox(height: 16),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ShimmerWidgets.box(height: 11, width: 70),
          const SizedBox(width: 8),
          Expanded(child: ShimmerWidgets.box(height: 10, width: double.infinity)),
          const SizedBox(width: 8),
          ShimmerWidgets.box(height: 11, width: 28),
        ],
      ),
    );
  }
}
