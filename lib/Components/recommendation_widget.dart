import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/recommendation_model.dart';
import 'package:musaffa_terminal/models/recommendation_trend_model.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';
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
  /// Steel navy — reads clearly over green/orange stacks (not pale lime).
  static const Color _priceLine = Color(0xFF1F3A5F);
  static const Color _priceLineDark = Color(0xFF7BA3C9);

  bool _showPrice = false;
  bool _priceLoading = false;
  final Map<String, double> _priceByPeriod = <String, double>{};
  final StockCandleService _candleService = StockCandleService();

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      _isDark,
                      icon: Icons.thumbs_up_down_outlined,
                      title: 'Recommendation Trend',
                      subtitleText: _showPrice
                          ? 'Analyst consensus with price overlay'
                          : 'Analyst consensus over the last 12 months',
                    ),
                  ),
                  HomeUi.ghostAction(
                    label: _showPrice ? 'Hide price' : 'Add price',
                    icon: _showPrice
                        ? Icons.show_chart
                        : Icons.add_chart_outlined,
                    onTap: () {
                      _togglePrice();
                    },
                    dark: _isDark,
                  ),
                ],
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
          child: _priceLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.fromLTRB(0, 8, 8, 0),
            legend: const Legend(isVisible: false),
            tooltipBehavior: TooltipBehavior(enable: false),
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
              lineType: TrackballLineType.vertical,
              lineWidth: 1.25,
              lineDashArray: const <double>[4, 3],
              lineColor: (_isDark ? _priceLineDark : _priceLine)
                  .withValues(alpha: 0.55),
              markerSettings: TrackballMarkerSettings(
                markerVisibility: TrackballVisibilityMode.visible,
                height: 7,
                width: 7,
                borderWidth: 2,
                borderColor: _isDark ? const Color(0xFF151821) : Colors.white,
                color: _isDark ? _priceLineDark : _priceLine,
              ),
              builder: (BuildContext context, TrackballDetails details) {
                final RecommendationTrendModel? point =
                    _trendFromTrackball(details, trends);
                if (point == null) return const SizedBox.shrink();
                return _trendTooltip(point);
              },
            ),
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              axisLine: AxisLine(width: 1, color: HomeUi.borderLight(_isDark)),
              labelPlacement: LabelPlacement.betweenTicks,
              labelIntersectAction: AxisLabelIntersectAction.none,
              maximumLabels: 6,
              labelStyle: HomeUi.subtitle(_isDark).copyWith(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
            primaryYAxis: NumericAxis(
              name: 'ratings',
              majorGridLines: MajorGridLines(
                width: 1,
                dashArray: const <double>[4, 4],
                color: HomeUi.borderLight(_isDark),
              ),
              majorTickLines: const MajorTickLines(size: 0),
              axisLine: AxisLine(width: 0),
              labelStyle: HomeUi.subtitle(_isDark).copyWith(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
            axes: _showPrice
                ? <ChartAxis>[
                    NumericAxis(
                      name: 'price',
                      opposedPosition: true,
                      majorGridLines: const MajorGridLines(width: 0),
                      majorTickLines: const MajorTickLines(size: 4),
                      axisLine: AxisLine(
                        width: 1,
                        color: HomeUi.borderLight(_isDark),
                      ),
                      labelStyle: HomeUi.subtitle(_isDark).copyWith(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                      numberFormat: NumberFormat.simpleCurrency(
                        name: 'USD',
                        decimalDigits: 0,
                      ),
                    ),
                  ]
                : const <ChartAxis>[],
            series: <CartesianSeries<RecommendationTrendModel, String>>[
              _trendBar('Strong Buy', _strongBuy, trends, (t) => t.strongBuy),
              _trendBar('Buy', _buy, trends, (t) => t.buy),
              _trendBar('Hold', _hold, trends, (t) => t.hold),
              _trendBar('Sell', _sell, trends, (t) => t.sell),
              _trendBar('Strong Sell', _strongSell, trends, (t) => t.strongSell),
              if (_showPrice && _priceByPeriod.isNotEmpty)
                LineSeries<RecommendationTrendModel, String>(
                  name: 'Price',
                  color: _isDark ? _priceLineDark : _priceLine,
                  width: 2.5,
                  yAxisName: 'price',
                  dataSource: trends,
                  xValueMapper: (RecommendationTrendModel t, _) =>
                      _formatPeriod(t.period),
                  yValueMapper: (RecommendationTrendModel t, _) =>
                      _priceByPeriod[_formatPeriod(t.period)],
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 5,
                    width: 5,
                    borderWidth: 1.5,
                    borderColor: _isDark ? _priceLineDark : _priceLine,
                    color: _isDark ? const Color(0xFF151821) : Colors.white,
                    shape: DataMarkerType.circle,
                  ),
                  legendIconType: LegendIconType.horizontalLine,
                ),
            ],
          ),
        ),
      ],
    );
  }

  StackedColumnSeries<RecommendationTrendModel, String> _trendBar(
    String name,
    Color color,
    List<RecommendationTrendModel> trends,
    int Function(RecommendationTrendModel) y,
  ) {
    return StackedColumnSeries<RecommendationTrendModel, String>(
      name: name,
      color: color,
      yAxisName: 'ratings',
      groupName: 'ratings',
      width: 0.62,
      spacing: 0.12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      dataSource: trends,
      xValueMapper: (RecommendationTrendModel t, _) => _formatPeriod(t.period),
      yValueMapper: (RecommendationTrendModel t, _) => y(t),
      legendIconType: LegendIconType.rectangle,
    );
  }

  RecommendationTrendModel? _trendFromTrackball(
    TrackballDetails details,
    List<RecommendationTrendModel> trends,
  ) {
    if (trends.isEmpty) return null;

    final int? index = details.pointIndex ??
        (details.groupingModeInfo?.currentPointIndices.isNotEmpty == true
            ? details.groupingModeInfo!.currentPointIndices.first
            : null);
    if (index != null && index >= 0 && index < trends.length) {
      return trends[index];
    }

    final dynamic x = details.point?.x;
    if (x != null) {
      final String label = x.toString();
      for (final RecommendationTrendModel t in trends) {
        if (_formatPeriod(t.period) == label) return t;
      }
    }
    return null;
  }

  Widget _trendTooltip(RecommendationTrendModel p) {
    final String period = _formatPeriod(p.period);
    final double? price = _showPrice ? _priceByPeriod[period] : null;
    final List<({String label, int count, Color color})> rows =
        <({String label, int count, Color color})>[
      (label: 'Strong Buy', count: p.strongBuy, color: _strongBuy),
      (label: 'Buy', count: p.buy, color: _buy),
      (label: 'Hold', count: p.hold, color: _hold),
      (label: 'Sell', count: p.sell, color: _sell),
      (label: 'Strong Sell', count: p.strongSell, color: _strongSell),
    ];
    final int total = rows.fold<int>(0, (int s, r) => s + r.count);

    // Syncfusion trackball applies a tight maxHeight; UnconstrainedBox lets
    // the card size to its content so the footer never overflows.
    return UnconstrainedBox(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 176,
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF151821) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HomeUi.borderLight(_isDark)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDark ? 0.35 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                period,
                style: HomeUi.tableCellSecondary(_isDark).copyWith(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              if (price != null) ...[
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: HomeUi.tableCellEmphasis(_isDark).copyWith(
                    fontSize: 15,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: _isDark ? _priceLineDark : _priceLine,
                  ),
                ),
                Text(
                  'Price',
                  style: HomeUi.subtitle(_isDark).copyWith(
                    fontSize: 10,
                    height: 1.15,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final r in rows)
                if (r.count > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: r.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            r.label,
                            style: HomeUi.subtitle(_isDark).copyWith(
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${r.count}',
                          style: HomeUi.tableNumeric(_isDark).copyWith(
                            fontSize: 11.5,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              if (total > 0) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: HomeUi.borderLight(_isDark),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Analysts',
                        style: HomeUi.subtitle(_isDark).copyWith(
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      '$total',
                      style: HomeUi.tableCellEmphasis(_isDark).copyWith(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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

  String _priceTooltipLine(RecommendationTrendModel p) {
    final double? price = _priceByPeriod[_formatPeriod(p.period)];
    if (!_showPrice || price == null) return '';
    return '\nPrice  \$${price.toStringAsFixed(2)}';
  }

  Future<void> _togglePrice() async {
    if (_showPrice) {
      setState(() => _showPrice = false);
      return;
    }
    setState(() {
      _showPrice = true;
      if (_priceByPeriod.isEmpty) _priceLoading = true;
    });
    if (_priceByPeriod.isEmpty) {
      await _loadPriceOverlay();
    }
  }

  Future<void> _loadPriceOverlay() async {
    final List<RecommendationTrendModel> trends =
        widget.controller.trendHistory;
    if (trends.isEmpty) {
      if (mounted) setState(() => _priceLoading = false);
      return;
    }

    DateTime? from;
    DateTime? to;
    for (final RecommendationTrendModel trend in trends) {
      final DateTime? date = DateTime.tryParse(trend.period);
      if (date == null) continue;
      from = from == null || date.isBefore(from) ? date : from;
      to = to == null || date.isAfter(to) ? date : to;
    }
    from ??= DateTime.now().subtract(const Duration(days: 400));
    to ??= DateTime.now();

    try {
      final List<PriceDataPoint> candles = await _candleService.fetchDailyCloses(
        widget.symbol,
        from: from.subtract(const Duration(days: 10)),
        to: to.add(const Duration(days: 10)),
      );
      if (!mounted) return;
      final Map<String, double> mapped = <String, double>{};
      for (final RecommendationTrendModel trend in trends) {
        final DateTime? periodDate = DateTime.tryParse(trend.period);
        final double? price = _priceOnOrBefore(candles, periodDate);
        if (price != null) {
          mapped[_formatPeriod(trend.period)] = price;
        }
      }
      setState(() {
        _priceByPeriod
          ..clear()
          ..addAll(mapped);
        _priceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _priceLoading = false);
    }
  }

  double? _priceOnOrBefore(List<PriceDataPoint> candles, DateTime? period) {
    if (candles.isEmpty) return null;
    if (period == null) return candles.last.value;
    PriceDataPoint? best;
    for (final PriceDataPoint point in candles) {
      if (!point.date.isAfter(period.add(const Duration(days: 5)))) {
        best = point;
      }
    }
    return best?.value ?? candles.first.value;
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
