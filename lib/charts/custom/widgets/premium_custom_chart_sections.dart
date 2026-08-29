import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/ticker_price_target_chart.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_dividend_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_earnings_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_news_sentiment_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_peer_comparison_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_price_target_controller.dart';
import 'package:musaffa_terminal/charts/custom/premium_chart_theme.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/models/dividend_entry.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';
import 'package:musaffa_terminal/models/news_sentiment_model.dart';
import 'package:musaffa_terminal/models/peer_comparison_row.dart';
import 'package:musaffa_terminal/models/price_target_chart_model.dart';
import 'package:musaffa_terminal/models/price_target_model.dart';
import 'package:musaffa_terminal/models/recommendation_trend_model.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PremiumKpiSparklineRow extends StatelessWidget {
  const PremiumKpiSparklineRow({
    super.key,
    required this.stockData,
    required this.isDark,
    required this.priceHistory,
  });

  final StocksData stockData;
  final bool isDark;
  final List<OhlcCandlePoint> priceHistory;

  @override
  Widget build(BuildContext context) {
    final List<_KpiItem> items = <_KpiItem>[
      _KpiItem(
        'Market Cap',
        PremiumChartFormatters.marketCap(stockData.usdMarketCap),
        stockData.priceChange1MPercent?.toDouble(),
        _sparklineFromHistory(priceHistory, 30),
      ),
      _KpiItem(
        'P/E (TTM)',
        stockData.peTTM?.toStringAsFixed(2) ?? '--',
        null,
        const <double>[],
      ),
      _KpiItem(
        'Revenue Growth',
        PremiumChartFormatters.percent(stockData.revenueGrowth1Y?.toDouble()),
        stockData.revenueGrowth1Y?.toDouble(),
        const <double>[],
      ),
      _KpiItem(
        'Dividend Yield',
        PremiumChartFormatters.percent(stockData.currentDividendYieldTTM?.toDouble()),
        null,
        const <double>[],
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 900;
        if (compact) {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _KpiSparklineCard(item: item, isDark: isDark),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _KpiSparklineCard(item: item, isDark: isDark),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<double> _sparklineFromHistory(List<OhlcCandlePoint> history, int days) {
    if (history.length < 2) return <double>[];
    final List<OhlcCandlePoint> slice = history.length <= days
        ? history
        : history.sublist(history.length - days);
    return slice.map((OhlcCandlePoint c) => c.close).toList();
  }
}

class _KpiItem {
  const _KpiItem(this.label, this.value, this.changePercent, this.sparkline);

  final String label;
  final String value;
  final double? changePercent;
  final List<double> sparkline;
}

class _KpiSparklineCard extends StatelessWidget {
  const _KpiSparklineCard({required this.item, required this.isDark});

  final _KpiItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);
    final bool? positive =
        item.changePercent == null ? null : item.changePercent! >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: theme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.label, style: theme.axisLabel(size: 10)),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: HomeUi.tableNumeric(isDark).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.changePercent != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              PremiumChartFormatters.percent(item.changePercent),
              style: HomeUi.tableNumeric(
                isDark,
                positiveValue: positive,
              ).copyWith(fontSize: 12),
            ),
          ],
          if (item.sparkline.length >= 2) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                margin: EdgeInsets.zero,
                primaryXAxis: const NumericAxis(isVisible: false),
                primaryYAxis: const NumericAxis(isVisible: false),
                series: <CartesianSeries<double, int>>[
                  SplineSeries<double, int>(
                    dataSource: item.sparkline,
                    xValueMapper: (double value, int index) => index,
                    yValueMapper: (double value, _) => value,
                    width: 1.2,
                    color: PremiumChartTheme.brandLine.withValues(alpha: 0.85),
                    splineType: SplineType.cardinal,
                    markerSettings: const MarkerSettings(isVisible: false),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumPerformanceHeatmapChart extends StatelessWidget {
  const PremiumPerformanceHeatmapChart({
    super.key,
    required this.stockData,
    required this.isDark,
  });

  final StocksData stockData;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> performanceData = <String, double>{
      '1D': stockData.change1DPercent?.toDouble() ?? 0,
      '1W': stockData.priceChange1WPercent?.toDouble() ?? 0,
      '1M': stockData.priceChange1MPercent?.toDouble() ?? 0,
      '3M': stockData.priceChange3MPercent?.toDouble() ?? 0,
      '6M': stockData.priceChange6MPercent?.toDouble() ?? 0,
      '1Y': stockData.priceChange1YPercent?.toDouble() ?? 0,
      '3Y': stockData.priceChange3YPercent?.toDouble() ?? 0,
      '5Y': stockData.priceChange5YPercent?.toDouble() ?? 0,
      'YTD': stockData.priceChangeYTDPercent?.toDouble() ?? 0,
    };

    return PremiumChartCard(
      isDark: isDark,
      icon: Icons.grid_view_rounded,
      title: 'Performance Heatmap',
      subtitle: 'Returns across timeframes',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
        ),
        itemCount: performanceData.length,
        itemBuilder: (BuildContext context, int index) {
          final String period = performanceData.keys.elementAt(index);
          final double value = performanceData[period] ?? 0;
          return _HeatmapCell(period: period, value: value, isDark: isDark);
        },
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.period,
    required this.value,
    required this.isDark,
  });

  final String period;
  final double value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);
    final bool isPositive = value >= 0;
    final double absValue = value.abs();
    final double intensity = (absValue / 20).clamp(0.15, 1.0);
    final Color tone = isPositive ? theme.positive : theme.negative;
    final Color fill = absValue == 0
        ? theme.elevated
        : Color.lerp(
            tone.withValues(alpha: isDark ? 0.10 : 0.06),
            tone.withValues(alpha: isDark ? 0.34 : 0.20),
            intensity,
          )!;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(
          color: absValue == 0 ? theme.border : tone.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            period,
            style: HomeUi.overline(isDark).copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              color: absValue == 0 ? theme.muted : tone,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            PremiumChartFormatters.percent(value, digits: 1),
            style: HomeUi.tableNumeric(
              isDark,
              positiveValue: absValue == 0 ? null : isPositive,
            ).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class PremiumPeerMarketCapChart extends StatelessWidget {
  const PremiumPeerMarketCapChart({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final TickerPeerComparisonController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        if (controller.isLoading) {
          return _loadingCard(isDark, 'Peer Market Cap');
        }
        if (!controller.hasData) return const SizedBox.shrink();

        final List<PeerComparisonRow> sorted =
            List<PeerComparisonRow>.from(controller.rows)
              ..sort(
                (PeerComparisonRow a, PeerComparisonRow b) =>
                    (b.stockData.usdMarketCap ?? 0)
                        .compareTo(a.stockData.usdMarketCap ?? 0),
              );

        final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);

        return PremiumChartCard(
          isDark: isDark,
          icon: Icons.leaderboard_outlined,
          title: 'Peer Market Cap',
          subtitle: 'Ranked by market capitalization',
          child: SizedBox(
            height: (sorted.length * 34.0).clamp(180, 320),
            child: SfCartesianChart(
              isTransposed: true,
              plotAreaBorderWidth: 0,
              margin: const EdgeInsets.only(right: 8),
              primaryXAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
                axisLine: AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: theme.axisLabel(size: 10),
                numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
              ),
              primaryYAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: theme.axisLabel(size: 11),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: Colors.transparent,
                borderColor: Colors.transparent,
                elevation: 0,
                builder: (dynamic data, _, __, ___, ____) {
                  if (data is! _PeerBarPoint) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: theme.tooltipDecoration(),
                    child: Text(
                      '${data.label}\n${PremiumChartFormatters.marketCap(data.value)}',
                      style: theme.tooltipValue(size: 12),
                    ),
                  );
                },
              ),
              series: <CartesianSeries<_PeerBarPoint, String>>[
                BarSeries<_PeerBarPoint, String>(
                  dataSource: sorted
                      .map(
                        (PeerComparisonRow row) => _PeerBarPoint(
                          label: row.ticker,
                          value: row.stockData.usdMarketCap?.toDouble() ?? 0,
                          isCurrent: row.isCurrent,
                        ),
                      )
                      .toList(),
                  xValueMapper: (_PeerBarPoint point, _) => point.label,
                  yValueMapper: (_PeerBarPoint point, _) => point.value,
                  borderRadius: BorderRadius.circular(4),
                  pointColorMapper: (_PeerBarPoint point, _) =>
                      point.isCurrent
                          ? PremiumChartTheme.brandLine
                          : theme.accent.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeerBarPoint {
  const _PeerBarPoint({
    required this.label,
    required this.value,
    this.isCurrent = false,
  });

  final String label;
  final double value;
  final bool isCurrent;
}

class PremiumPeerRiskReturnChart extends StatelessWidget {
  const PremiumPeerRiskReturnChart({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final TickerPeerComparisonController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        if (controller.isLoading || !controller.hasData) {
          return const SizedBox.shrink();
        }

        final List<_RiskReturnPoint> points = controller.rows
            .where(
              (PeerComparisonRow row) =>
                  row.stockData.beta != null &&
                  row.stockData.revenueGrowth1Y != null,
            )
            .map(
              (PeerComparisonRow row) => _RiskReturnPoint(
                label: row.ticker,
                risk: row.stockData.beta!.toDouble(),
                returnPct: row.stockData.revenueGrowth1Y!.toDouble(),
                isCurrent: row.isCurrent,
              ),
            )
            .toList();

        if (points.length < 2) return const SizedBox.shrink();

        final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);

        return PremiumChartCard(
          isDark: isDark,
          icon: Icons.scatter_plot_outlined,
          title: 'Risk / Return Profile',
          subtitle: 'Beta vs revenue growth (peers)',
          child: SizedBox(
            height: 280,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: NumericAxis(
                title: AxisTitle(text: 'Beta (risk)', textStyle: theme.axisLabel()),
                majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                  text: 'Revenue growth %',
                  textStyle: theme.axisLabel(),
                ),
                majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: Colors.transparent,
                borderColor: Colors.transparent,
                elevation: 0,
                builder: (dynamic data, _, __, ___, ____) {
                  if (data is! _RiskReturnPoint) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: theme.tooltipDecoration(),
                    child: Text(
                      '${data.label}\nBeta ${data.risk.toStringAsFixed(2)}\n'
                      'Growth ${PremiumChartFormatters.percent(data.returnPct)}',
                      style: theme.tooltipValue(size: 12),
                    ),
                  );
                },
              ),
              series: <CartesianSeries<_RiskReturnPoint, double>>[
                ScatterSeries<_RiskReturnPoint, double>(
                  dataSource: points,
                  xValueMapper: (_RiskReturnPoint point, _) => point.risk,
                  yValueMapper: (_RiskReturnPoint point, _) => point.returnPct,
                  pointColorMapper: (_RiskReturnPoint point, _) =>
                      point.isCurrent
                          ? PremiumChartTheme.brandLine
                          : theme.accent.withValues(alpha: 0.65),
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 8,
                    width: 8,
                    shape: DataMarkerType.circle,
                    borderWidth: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RiskReturnPoint {
  const _RiskReturnPoint({
    required this.label,
    required this.risk,
    required this.returnPct,
    required this.isCurrent,
  });

  final String label;
  final double risk;
  final double returnPct;
  final bool isCurrent;
}

class PremiumSentimentDonutChart extends StatelessWidget {
  const PremiumSentimentDonutChart({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final TickerNewsSentimentController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        if (controller.isLoading) {
          return _loadingCard(isDark, 'News Sentiment');
        }

        final NewsSentimentModel? model = controller.model;
        if (model == null) return const SizedBox.shrink();

        final double bullish = model.sentiment.bullishPercent;
        final double bearish = model.sentiment.bearishPercent;
        final double neutral =
            (100 - bullish - bearish).clamp(0, 100).toDouble();

        final List<_SentimentSlice> slices = <_SentimentSlice>[
          _SentimentSlice('Bullish', bullish, HomeUi.positive(isDark)),
          _SentimentSlice('Neutral', neutral, HomeUi.muted(isDark)),
          _SentimentSlice('Bearish', bearish, HomeUi.negative(isDark)),
        ].where((slice) => slice.value > 0).toList();

        if (slices.isEmpty) return const SizedBox.shrink();

        final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);

        return PremiumChartCard(
          isDark: isDark,
          icon: Icons.donut_large_outlined,
          title: 'News Sentiment',
          subtitle: 'Bullish / neutral / bearish distribution',
          child: SizedBox(
            height: 240,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: SfCircularChart(
                    margin: EdgeInsets.zero,
                    legend: Legend(isVisible: false),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CircularSeries<_SentimentSlice, String>>[
                      DoughnutSeries<_SentimentSlice, String>(
                        dataSource: slices,
                        xValueMapper: (_SentimentSlice slice, _) => slice.label,
                        yValueMapper: (_SentimentSlice slice, _) => slice.value,
                        pointColorMapper: (_SentimentSlice slice, _) =>
                            slice.color,
                        innerRadius: '88%',
                        radius: '98%',
                        dataLabelSettings: const DataLabelSettings(isVisible: false),
                      ),
                    ],
                    annotations: <CircularChartAnnotation>[
                      CircularChartAnnotation(
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              PremiumChartFormatters.percent(bullish, digits: 0),
                              style: HomeUi.tableNumeric(isDark).copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text('Bullish', style: theme.axisLabel(size: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: slices
                        .map(
                          (slice) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: slice.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(slice.label, style: theme.axisLabel()),
                                ),
                                Text(
                                  PremiumChartFormatters.percent(slice.value, digits: 1),
                                  style: HomeUi.tableNumeric(isDark),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SentimentSlice {
  const _SentimentSlice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class PremiumDividendAreaChart extends StatelessWidget {
  const PremiumDividendAreaChart({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final TickerDividendController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        if (controller.isLoading) {
          return _loadingCard(isDark, 'Dividend History');
        }

        final List<DividendEntry> entries = controller.chartEntries;
        if (entries.isEmpty) return const SizedBox.shrink();

        final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);

        return PremiumChartCard(
          isDark: isDark,
          icon: Icons.payments_outlined,
          title: 'Dividend History',
          subtitle: 'Historical dividend per share',
          child: SizedBox(
            height: 240,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: DateTimeAxis(
                majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(),
                numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
              ),
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                lineType: TrackballLineType.vertical,
                builder: (_, TrackballDetails details) {
                  final dynamic x = details.point?.x;
                  if (x is! DateTime) return const SizedBox.shrink();
                  DividendEntry? entry;
                  for (final DividendEntry item in entries) {
                    if (item.date == x) {
                      entry = item;
                      break;
                    }
                  }
                  if (entry?.amount == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: theme.tooltipDecoration(),
                    child: Text(
                      '${FinnhubDisplayFormatters.formatShortDate(entry!.date)}\n'
                      '\$${entry.amount!.toStringAsFixed(4)}',
                      style: theme.tooltipValue(size: 12),
                    ),
                  );
                },
              ),
              series: <CartesianSeries<DividendEntry, DateTime>>[
                SplineAreaSeries<DividendEntry, DateTime>(
                  dataSource: entries,
                  xValueMapper: (DividendEntry entry, _) => entry.date,
                  yValueMapper: (DividendEntry entry, _) => entry.amount,
                  borderWidth: 1.5,
                  borderColor: PremiumChartTheme.brandLine,
                  color: PremiumChartTheme.brandLine.withValues(alpha: 0.12),
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PremiumEarningsComparisonChart extends StatelessWidget {
  const PremiumEarningsComparisonChart({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final TickerEarningsController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        if (controller.isLoading) {
          return _loadingCard(isDark, 'Earnings Comparison');
        }

        final List<EarningsCalendarEntry> quarters =
            controller.lastFourHistoricalQuarters;
        if (quarters.isEmpty) return const SizedBox.shrink();

        final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);

        return PremiumChartCard(
          isDark: isDark,
          icon: Icons.bar_chart_rounded,
          title: 'Earnings Comparison',
          subtitle: 'EPS estimate vs actual (last 4 quarters)',
          child: SizedBox(
            height: 260,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              legend: Legend(
                isVisible: true,
                position: LegendPosition.top,
                textStyle: theme.axisLabel(size: 11),
                iconHeight: 8,
                iconWidth: 14,
              ),
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(),
              ),
              series: <CartesianSeries<dynamic, String>>[
                ColumnSeries<_EarningsBarPoint, String>(
                  name: 'Estimate',
                  dataSource: quarters
                      .map(
                        (EarningsCalendarEntry q) => _EarningsBarPoint(
                          label: 'Q${q.quarter ?? ''} ${q.year ?? ''}',
                          value: q.epsEstimate,
                        ),
                      )
                      .toList(),
                  xValueMapper: (_EarningsBarPoint point, _) => point.label,
                  yValueMapper: (_EarningsBarPoint point, _) => point.value,
                  color: theme.muted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                  width: 0.35,
                  spacing: 0.15,
                ),
                ColumnSeries<_EarningsBarPoint, String>(
                  name: 'Actual',
                  dataSource: quarters
                      .map(
                        (EarningsCalendarEntry q) => _EarningsBarPoint(
                          label: 'Q${q.quarter ?? ''} ${q.year ?? ''}',
                          value: q.epsActual,
                        ),
                      )
                      .toList(),
                  xValueMapper: (_EarningsBarPoint point, _) => point.label,
                  yValueMapper: (_EarningsBarPoint point, _) => point.value,
                  color: PremiumChartTheme.brandLine.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                  width: 0.35,
                  spacing: 0.15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EarningsBarPoint {
  const _EarningsBarPoint({required this.label, required this.value});

  final String label;
  final double? value;
}

class PremiumAnalystTrendChart extends StatelessWidget {
  const PremiumAnalystTrendChart({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final RecommendationController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        if (controller.isTrendLoading && controller.trendHistory.isEmpty) {
          return _loadingCard(isDark, 'Analyst Recommendations');
        }
        if (controller.trendHistory.isEmpty) return const SizedBox.shrink();

        final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);
        final List<RecommendationTrendModel> history = controller.trendHistory;

        return PremiumChartCard(
          isDark: isDark,
          icon: Icons.thumbs_up_down_outlined,
          title: 'Analyst Recommendations',
          subtitle: 'Rating trend over time',
          child: SizedBox(
            height: 260,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              legend: Legend(
                isVisible: true,
                position: LegendPosition.top,
                overflowMode: LegendItemOverflowMode.wrap,
                toggleSeriesVisibility: true,
                textStyle: theme.axisLabel(size: 11),
              ),
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(size: 10),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
                axisLine: AxisLine(width: 0),
                labelStyle: theme.axisLabel(),
              ),
              series: <CartesianSeries<RecommendationTrendModel, String>>[
                StackedAreaSeries<RecommendationTrendModel, String>(
                  name: 'Strong Buy',
                  dataSource: history,
                  xValueMapper: (RecommendationTrendModel m, _) => m.period,
                  yValueMapper: (RecommendationTrendModel m, _) => m.strongBuy,
                  color: const Color(0xFF059669).withValues(alpha: 0.75),
                ),
                StackedAreaSeries<RecommendationTrendModel, String>(
                  name: 'Buy',
                  dataSource: history,
                  xValueMapper: (RecommendationTrendModel m, _) => m.period,
                  yValueMapper: (RecommendationTrendModel m, _) => m.buy,
                  color: const Color(0xFF34D399).withValues(alpha: 0.65),
                ),
                StackedAreaSeries<RecommendationTrendModel, String>(
                  name: 'Hold',
                  dataSource: history,
                  xValueMapper: (RecommendationTrendModel m, _) => m.period,
                  yValueMapper: (RecommendationTrendModel m, _) => m.hold,
                  color: PremiumChartTheme.brandLine.withValues(alpha: 0.55),
                ),
                StackedAreaSeries<RecommendationTrendModel, String>(
                  name: 'Sell',
                  dataSource: history,
                  xValueMapper: (RecommendationTrendModel m, _) => m.period,
                  yValueMapper: (RecommendationTrendModel m, _) => m.sell,
                  color: const Color(0xFFF87171).withValues(alpha: 0.55),
                ),
                StackedAreaSeries<RecommendationTrendModel, String>(
                  name: 'Strong Sell',
                  dataSource: history,
                  xValueMapper: (RecommendationTrendModel m, _) => m.period,
                  yValueMapper: (RecommendationTrendModel m, _) => m.strongSell,
                  color: const Color(0xFFDC2626).withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PremiumPriceTargetSection extends StatelessWidget {
  const PremiumPriceTargetSection({
    super.key,
    required this.controller,
    required this.isDark,
  });

  final TickerPriceTargetController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        if (controller.isLoading) {
          return _loadingCard(isDark, 'Price Target');
        }

        final PriceTargetChartData? chartData = controller.chartData;
        final PriceTargetModel? target = controller.priceTarget;
        if (chartData == null || target == null) return const SizedBox.shrink();

        return PremiumChartCard(
          isDark: isDark,
          icon: Icons.flag_outlined,
          title: 'Analyst Price Target',
          subtitle: 'Historical price vs analyst targets',
          child: TickerPriceTargetChart(
            chartData: chartData,
            priceTarget: target,
            isDarkMode: isDark,
          ),
        );
      },
    );
  }
}

Widget _loadingCard(bool isDark, String title) {
  return PremiumChartCard(
    isDark: isDark,
    title: title,
    child: SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(HomeUi.accent(isDark)),
          ),
        ),
      ),
    ),
  );
}
