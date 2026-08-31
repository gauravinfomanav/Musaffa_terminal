import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/controllers/ticker_custom_charts_controller.dart';
import 'package:musaffa_terminal/charts/custom/premium_chart_theme.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PremiumPricePerformanceChart extends StatelessWidget {
  const PremiumPricePerformanceChart({
    super.key,
    required this.symbol,
    required this.companyName,
    required this.stockData,
    required this.isDark,
    required this.controller,
    this.livePrice,
  });

  final String symbol;
  final String companyName;
  final StocksData? stockData;
  final bool isDark;
  final TickerCustomChartsController controller;
  final double? livePrice;

  @override
  Widget build(BuildContext context) {
    final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);

    return Obx(() {
      final List<OhlcCandlePoint> data = controller.visibleCandles;
      final bool loading = controller.isLoadingPrice.value;
      final PremiumPriceChartMode mode = controller.chartMode.value;

      return PremiumChartCard(
        isDark: isDark,
        icon: Icons.show_chart_rounded,
        title: companyName.isNotEmpty ? companyName : symbol,
        subtitle: 'Price performance',
        trailing: _buildModeToggle(theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildQuoteHeader(theme, data),
            const SizedBox(height: 14),
            PremiumChartPillBar(
              isDark: isDark,
              options: PremiumPriceRange.valuesOrdered
                  .map((PremiumPriceRange r) => r.label)
                  .toList(),
              selectedIndex: PremiumPriceRange.valuesOrdered
                  .indexOf(controller.selectedRange.value),
              onChanged: (int index) => controller
                  .selectRange(PremiumPriceRange.valuesOrdered[index]),
            ),
            const SizedBox(height: 16),
            if (loading)
              SizedBox(
                height: 360,
                child: Center(child: _buildLoader(theme)),
              )
            else if (data.isEmpty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No chart data available',
                    style: HomeUi.bodyText(isDark),
                  ),
                ),
              )
            else
              SizedBox(
                height: mode == PremiumPriceChartMode.candlestick ? 400 : 360,
                child: mode == PremiumPriceChartMode.candlestick
                    ? _buildCandlestickChart(theme, data)
                    : _buildAreaChart(theme, data),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildModeToggle(PremiumChartTheme theme) {
    return Obx(() {
      final bool isCandle =
          controller.chartMode.value == PremiumPriceChartMode.candlestick;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _modeChip(theme, 'Area', !isCandle, () {
            controller.setChartMode(PremiumPriceChartMode.area);
          }),
          const SizedBox(width: 6),
          _modeChip(theme, 'Candles', isCandle, () {
            controller.setChartMode(PremiumPriceChartMode.candlestick);
          }),
        ],
      );
    });
  }

  Widget _modeChip(
    PremiumChartTheme theme,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? theme.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(color: theme.border),
          ),
          child: Text(
            label,
            style: theme.axisLabel(size: 10).copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? theme.accent : theme.muted,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteHeader(PremiumChartTheme theme, List<OhlcCandlePoint> data) {
    final double? displayPrice = livePrice ??
        stockData?.currentPrice?.toDouble() ??
        controller.latestCandle?.close;
    final double? changePct = controller.rangeChangePercent ??
        stockData?.change1DPercent?.toDouble();
    final double? changeAbs = controller.rangeChangeAbsolute;
    final bool? isPositive =
        changePct == null ? null : changePct >= 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          symbol,
          style: theme.axisLabel(size: 12).copyWith(
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
                color: theme.muted,
              ),
        ),
        const SizedBox(width: 16),
        Text(
          PremiumChartFormatters.price(displayPrice),
          style: HomeUi.tableNumeric(isDark).copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(width: 12),
        if (changePct != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                PremiumChartFormatters.percent(changePct),
                style: HomeUi.tableNumeric(
                  isDark,
                  positiveValue: isPositive,
                ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (changeAbs != null)
                Text(
                  PremiumChartFormatters.change(changeAbs, changePct),
                  style: theme.axisLabel(size: 10),
                ),
            ],
          ),
        const Spacer(),
        if (data.isNotEmpty)
          Text(
            'Updated ${PremiumChartFormatters.tooltipDate(data.last.date, includeTime: controller.selectedRange.value == PremiumPriceRange.oneDay)}',
            style: theme.axisLabel(size: 10),
          ),
      ],
    );
  }

  Widget _buildAreaChart(PremiumChartTheme theme, List<OhlcCandlePoint> data) {
    final bool intraday =
        controller.selectedRange.value == PremiumPriceRange.oneDay;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.only(top: 8, right: 4),
      crosshairBehavior: CrosshairBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: CrosshairLineType.both,
        lineColor: theme.borderStrong.withValues(alpha: 0.65),
        lineWidth: 1,
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
        lineType: TrackballLineType.vertical,
        lineColor: theme.borderStrong.withValues(alpha: 0.55),
        lineWidth: 1,
        markerSettings: TrackballMarkerSettings(
          markerVisibility: TrackballVisibilityMode.visible,
          height: 8,
          width: 8,
          color: PremiumChartTheme.brandLine,
          borderWidth: 2,
          borderColor: theme.surface,
        ),
        builder: (
          BuildContext context,
          TrackballDetails details,
        ) {
          final dynamic point = details.point?.x;
          final dynamic value = details.point?.y;
          if (point is! DateTime || value is! num) {
            return const SizedBox.shrink();
          }
          return _buildTooltip(
            theme,
            PremiumChartFormatters.tooltipDate(point, includeTime: intraday),
            'Close  ${PremiumChartFormatters.price(value.toDouble())}',
          );
        },
      ),
      primaryXAxis: DateTimeAxis(
        majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
        minorGridLines: const MinorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: theme.axisLabel(),
        dateFormat: intraday ? DateFormat('h:mm a') : DateFormat('MMM yy'),
        labelIntersectAction: AxisLabelIntersectAction.none,
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
        minorGridLines: const MinorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: theme.axisLabel(),
        numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
      ),
      series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
        SplineAreaSeries<OhlcCandlePoint, DateTime>(
          dataSource: data,
          xValueMapper: (OhlcCandlePoint point, _) => point.date,
          yValueMapper: (OhlcCandlePoint point, _) => point.close,
          borderWidth: 1.5,
          borderColor: PremiumChartTheme.brandLine,
          color: PremiumChartTheme.brandLine.withValues(alpha: isDark ? 0.14 : 0.10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              PremiumChartTheme.brandLine.withValues(alpha: isDark ? 0.28 : 0.18),
              PremiumChartTheme.brandSecondary.withValues(alpha: isDark ? 0.04 : 0.02),
            ],
          ),
          splineType: SplineType.cardinal,
          cardinalSplineTension: 0.2,
          markerSettings: const MarkerSettings(isVisible: false),
        ),
      ],
    );
  }

  Widget _buildCandlestickChart(
    PremiumChartTheme theme,
    List<OhlcCandlePoint> data,
  ) {
    final bool intraday =
        controller.selectedRange.value == PremiumPriceRange.oneDay;
    final bool showVolume = data.any((OhlcCandlePoint c) => c.volume > 0);

    Widget buildTooltip(OhlcCandlePoint candle) {
      return _buildTooltip(
        theme,
        PremiumChartFormatters.tooltipDate(candle.date, includeTime: intraday),
        'O ${PremiumChartFormatters.price(candle.open)}\n'
        'H ${PremiumChartFormatters.price(candle.high)}\n'
        'L ${PremiumChartFormatters.price(candle.low)}\n'
        'C ${PremiumChartFormatters.price(candle.close)}\n'
        'Vol ${PremiumChartFormatters.volume(candle.volume)}',
      );
    }

    OhlcCandlePoint? findCandle(dynamic x) {
      if (x is! DateTime) return null;
      for (final OhlcCandlePoint candle in data) {
        if (candle.date == x) return candle;
      }
      return null;
    }

    final TrackballBehavior trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      lineType: TrackballLineType.vertical,
      lineColor: theme.borderStrong.withValues(alpha: 0.55),
      builder: (BuildContext context, TrackballDetails details) {
        if (details.groupingModeInfo?.points.isEmpty ?? true) {
          return const SizedBox.shrink();
        }
        final dynamic x = details.groupingModeInfo!.points.first.x;
        final OhlcCandlePoint? candle = findCandle(x);
        if (candle == null) return const SizedBox.shrink();
        return buildTooltip(candle);
      },
    );

    final DateTimeAxis xAxis = DateTimeAxis(
      majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
      axisLine: AxisLine(width: 0),
      majorTickLines: const MajorTickLines(size: 0),
      labelStyle: theme.axisLabel(),
      dateFormat: intraday ? DateFormat('h:mm a') : DateFormat('MMM yy'),
    );

    return Column(
      children: <Widget>[
        Expanded(
          flex: showVolume ? 3 : 1,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.only(top: 8, right: 4),
            crosshairBehavior: CrosshairBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              lineType: CrosshairLineType.both,
              lineColor: theme.borderStrong.withValues(alpha: 0.65),
              lineWidth: 1,
            ),
            trackballBehavior: trackball,
            primaryXAxis: xAxis,
            primaryYAxis: NumericAxis(
              opposedPosition: true,
              majorGridLines: MajorGridLines(width: 0.5, color: theme.grid),
              axisLine: AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelStyle: theme.axisLabel(),
              numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
            ),
            series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
              CandleSeries<OhlcCandlePoint, DateTime>(
                dataSource: data,
                xValueMapper: (OhlcCandlePoint point, _) => point.date,
                lowValueMapper: (OhlcCandlePoint point, _) => point.low,
                highValueMapper: (OhlcCandlePoint point, _) => point.high,
                openValueMapper: (OhlcCandlePoint point, _) => point.open,
                closeValueMapper: (OhlcCandlePoint point, _) => point.close,
                bearColor: theme.negative.withValues(alpha: 0.85),
                bullColor: theme.positive.withValues(alpha: 0.85),
                spacing: 0.35,
                width: 0.7,
              ),
            ],
          ),
        ),
        if (showVolume)
          Expanded(
            flex: 1,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: const EdgeInsets.only(right: 4, bottom: 0),
              primaryXAxis: DateTimeAxis(isVisible: false),
              primaryYAxis: NumericAxis(
                opposedPosition: true,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: theme.axisLabel(size: 10),
                numberFormat: NumberFormat.compact(),
              ),
              series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
                ColumnSeries<OhlcCandlePoint, DateTime>(
                  dataSource: data,
                  xValueMapper: (OhlcCandlePoint point, _) => point.date,
                  yValueMapper: (OhlcCandlePoint point, _) => point.volume,
                  color: theme.muted.withValues(alpha: 0.35),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(1)),
                  spacing: 0.35,
                  width: 0.7,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTooltip(PremiumChartTheme theme, String title, String body) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: theme.tooltipDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title, style: theme.tooltipTitle()),
          const SizedBox(height: 6),
          Text(body, style: theme.tooltipValue()),
        ],
      ),
    );
  }

  Widget _buildLoader(PremiumChartTheme theme) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
      ),
    );
  }
}