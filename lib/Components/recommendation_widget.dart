import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/models/recommendation_model.dart';
import 'package:musaffa_terminal/models/recommendation_trend_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
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
  @override
  void initState() {
    super.initState();
    // Fetch is now called from ticker_detail_screen.dart to ensure it happens even if widget is hidden
    // Only fetch here if controller doesn't have data and isn't loading
    if (!widget.controller.isLoading && widget.controller.recommendation == null && widget.controller.error == null) {
    widget.controller.fetchRecommendation(widget.symbol);
    }
  }

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

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left side: Recommendation Trend chart
              Expanded(
                flex: 2,
                child: _buildTrendPanel(recommendation),
              ),
              const SizedBox(width: 24),
              // Right side: Recommendation bars
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Analyst Ratings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendationBar('Strong Buy', recommendation.strongBuy, Colors.green, widget.controller.getStrongBuyPercentage()),
                    _buildRecommendationBar('Buy', recommendation.buy, Colors.lightGreen, widget.controller.getBuyPercentage()),
                    _buildRecommendationBar('Hold', recommendation.hold, Colors.orange, widget.controller.getHoldPercentage()),
                    _buildRecommendationBar('Sell', recommendation.sell, Colors.red, widget.controller.getSellPercentage()),
                    _buildRecommendationBar('Strong Sell', recommendation.strongSell, Colors.red[900]!, widget.controller.getStrongSellPercentage()),
                    const SizedBox(height: 20),
                    Text(
                      'Total: ${widget.controller.totalRecommendations}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendPanel(RecommendationModel recommendation) {
    if (widget.controller.isTrendLoading && widget.controller.trendHistory.isEmpty) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Recommendation Trend',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _summaryCard('Current Consensus', latest.consensusText),
            const SizedBox(width: 8),
            _summaryCard('Latest Analysts', latest.total.toString()),
            const SizedBox(width: 8),
            _summaryCard('Trend', trendText),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: SfCartesianChart(
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              overflowMode: LegendItemOverflowMode.wrap,
              textStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                if (pointIndex < 0 || pointIndex >= trends.length) {
                  return const SizedBox.shrink();
                }
                final RecommendationTrendModel p = trends[pointIndex];
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Period: ${p.period}\n'
                    'Strong Buy: ${p.strongBuy}\n'
                    'Buy: ${p.buy}\n'
                    'Hold: ${p.hold}\n'
                    'Sell: ${p.sell}\n'
                    'Strong Sell: ${p.strongSell}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                );
              },
            ),
            primaryXAxis: CategoryAxis(
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
            primaryYAxis: NumericAxis(
              title: const AxisTitle(
                text: 'No. of Recommendations',
                textStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
            series: <CartesianSeries<RecommendationTrendModel, String>>[
              LineSeries<RecommendationTrendModel, String>(
                name: 'Strong Buy',
                color: Colors.green,
                dataSource: trends,
                xValueMapper: (RecommendationTrendModel t, _) => t.period,
                yValueMapper: (RecommendationTrendModel t, _) => t.strongBuy,
              ),
              LineSeries<RecommendationTrendModel, String>(
                name: 'Buy',
                color: Colors.lightGreen,
                dataSource: trends,
                xValueMapper: (RecommendationTrendModel t, _) => t.period,
                yValueMapper: (RecommendationTrendModel t, _) => t.buy,
              ),
              LineSeries<RecommendationTrendModel, String>(
                name: 'Hold',
                color: Colors.orange,
                dataSource: trends,
                xValueMapper: (RecommendationTrendModel t, _) => t.period,
                yValueMapper: (RecommendationTrendModel t, _) => t.hold,
              ),
              LineSeries<RecommendationTrendModel, String>(
                name: 'Sell',
                color: const Color(0xFFFF8A65),
                dataSource: trends,
                xValueMapper: (RecommendationTrendModel t, _) => t.period,
                yValueMapper: (RecommendationTrendModel t, _) => t.sell,
              ),
              LineSeries<RecommendationTrendModel, String>(
                name: 'Strong Sell',
                color: Colors.red,
                dataSource: trends,
                xValueMapper: (RecommendationTrendModel t, _) => t.period,
                yValueMapper: (RecommendationTrendModel t, _) => t.strongSell,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ],
      ),
    );
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
        ShimmerWidgets.box(height: 14, width: 150),
        const SizedBox(height: 10),
        ShimmerWidgets.box(height: 180, width: double.infinity),
      ],
    );
  }

  Widget _buildTrendError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Recommendation Trend',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Unable to load recommendation trend',
          style: TextStyle(
            fontSize: 12,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => widget.controller.fetchRecommendationTrends(
            widget.symbol,
            forceRefresh: true,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildTrendEmpty() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Recommendation Trend',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'No recommendation trend data found',
          style: TextStyle(
            fontSize: 12,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left side: Trend shimmer
          Expanded(
            flex: 2,
            child: Column(
              children: [
                ShimmerWidgets.box(
                  height: 14,
                  width: 120,
                ),
                const SizedBox(height: 12),
                ShimmerWidgets.box(
                  height: 140,
                  width: double.infinity,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right side: Bars shimmer
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidgets.box(
                  height: 14,
                  width: 100,
                ),
                const SizedBox(height: 12),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                const SizedBox(height: 16),
                ShimmerWidgets.box(
                  height: 11,
                  width: 80,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ShimmerWidgets.box(
            height: 11,
            width: 70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ShimmerWidgets.box(
              height: 14,
              width: double.infinity,
            ),
          ),
          const SizedBox(width: 8),
          ShimmerWidgets.box(
            height: 11,
            width: 25,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationBar(String label, int count, Color color, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(9),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  if (percentage > 5)
                    Center(
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: percentage > 50 ? Colors.white : Colors.black87,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                  ),
                ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
