import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_sunburst_chart.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Additional premium finance charts — custom US palette, no defaults.
class PremiumFinanceExtraCharts {
  PremiumFinanceExtraCharts._();

  static Widget marginTrend(bool dark) => _ChartShell(
        dark: dark,
        caption: 'PROFIT MARGINS · TREND',
        height: 280,
        child: _marginChart(dark),
      );

  static Widget cashFlowStack(bool dark) => _ChartShell(
        dark: dark,
        caption: 'CASH FLOW · ANNUAL · \$B',
        height: 280,
        child: _cashFlowChart(dark),
      );

  static Widget valuationMultiples(bool dark) => _ChartShell(
        dark: dark,
        caption: 'VALUATION MULTIPLES',
        height: 280,
        child: _valuationChart(dark),
      );

  static Widget epsSurprise(bool dark) => _ChartShell(
        dark: dark,
        caption: 'EPS · ESTIMATE VS ACTUAL',
        height: 280,
        child: _epsChart(dark),
      );

  static Widget range52Week(bool dark) => _ChartShell(
        dark: dark,
        caption: '52-WEEK PRICE RANGE',
        height: 280,
        child: _Range52WeekBar(dark: dark, data: StaticPremiumChartData.range52Week),
      );

  static Widget geographicRevenue(bool dark) => _ChartShell(
        dark: dark,
        caption: 'BULLET CHART · EVALUATION',
        height: 280,
        child: _BulletChartPanel(dark: dark),
      );

  static Widget correlationMatrix(bool dark) => _ChartShell(
        dark: dark,
        caption: 'CORRELATION MATRIX',
        height: 280,
        child: _correlationChart(dark),
      );

  static Widget volumePriceCombo(bool dark) => _ChartShell(
        dark: dark,
        caption: 'PRICE · VOLUME REGIME',
        height: 300,
        child: _volumePriceCombo(dark),
      );

  static Widget tornadoChart(bool dark) => _ChartShell(
        dark: dark,
        caption: 'TORNADO · ONLINE VS IN-STORE',
        height: 340,
        child: _tornadoChart(dark),
      );

  static Widget sunburstChart(bool dark) => _ChartShell(
        dark: dark,
        caption: 'SUNBURST · PORTFOLIO EXPOSURE',
        height: 280,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double side =
                (constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight) *
                0.82;
            return Center(
              child: SizedBox(
                width: side,
                height: side,
                child: PremiumSunburstChart(
                  dark: dark,
                  nodes: StaticPremiumChartData.sunburstNodes,
                  rootLabel: 'Portfolio',
                  rootTotal: StaticPremiumChartData.sunburstTotal,
                ),
              ),
            );
          },
        ),
      );

  static Widget _marginChart(bool dark) {
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticMarginPoint> data = StaticPremiumChartData.marginTrend;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        shared: true,
        color: UsPremiumPalette.surface(dark),
        borderColor: UsPremiumPalette.border(dark),
        borderWidth: 1,
        elevation: 10,
        header: '',
        textStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      primaryXAxis: CategoryAxis(
        axisLine: AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: _axis(dark),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        axisLine: AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
        numberFormat: NumberFormat('#\'%'),
      ),
      series: <CartesianSeries<StaticMarginPoint, String>>[
        SplineSeries<StaticMarginPoint, String>(
          name: 'Gross Margin',
          dataSource: data,
          xValueMapper: (StaticMarginPoint p, _) => p.period,
          yValueMapper: (StaticMarginPoint p, _) => p.gross,
          color: c.grossMargin,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: false),
        ),
        SplineSeries<StaticMarginPoint, String>(
          name: 'Operating Margin',
          dataSource: data,
          xValueMapper: (StaticMarginPoint p, _) => p.period,
          yValueMapper: (StaticMarginPoint p, _) => p.operating,
          color: c.operatingMargin,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: false),
        ),
        SplineSeries<StaticMarginPoint, String>(
          name: 'Net Margin',
          dataSource: data,
          xValueMapper: (StaticMarginPoint p, _) => p.period,
          yValueMapper: (StaticMarginPoint p, _) => p.net,
          color: c.netMargin,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: false),
        ),
      ],
    );
  }

  static Widget _cashFlowChart(bool dark) {
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticCashFlowYear> data = StaticPremiumChartData.cashFlowTrend;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        shared: true,
        color: UsPremiumPalette.surface(dark),
        borderColor: UsPremiumPalette.border(dark),
        borderWidth: 1,
        elevation: 10,
        header: '',
        textStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      primaryXAxis: CategoryAxis(
        axisLine: AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: _axis(dark),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        axisLine: AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
      ),
      series: <CartesianSeries<StaticCashFlowYear, String>>[
        StackedColumnSeries<StaticCashFlowYear, String>(
          name: 'Operating',
          dataSource: data,
          xValueMapper: (StaticCashFlowYear p, _) => p.year,
          yValueMapper: (StaticCashFlowYear p, _) => p.operating,
          color: c.cfOperating,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          width: 0.5,
        ),
        StackedColumnSeries<StaticCashFlowYear, String>(
          name: 'Investing',
          dataSource: data,
          xValueMapper: (StaticCashFlowYear p, _) => p.year,
          yValueMapper: (StaticCashFlowYear p, _) => p.investing,
          color: c.cfInvesting,
          width: 0.5,
        ),
        StackedColumnSeries<StaticCashFlowYear, String>(
          name: 'Financing',
          dataSource: data,
          xValueMapper: (StaticCashFlowYear p, _) => p.year,
          yValueMapper: (StaticCashFlowYear p, _) => p.financing,
          color: c.cfFinancing,
          width: 0.5,
        ),
      ],
    );
  }

  static Widget _valuationChart(bool dark) {
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticValuationPoint> data = StaticPremiumChartData.valuationMultiples;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        shared: true,
        color: UsPremiumPalette.surface(dark),
        borderColor: UsPremiumPalette.border(dark),
        borderWidth: 1,
        elevation: 10,
        header: '',
        textStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      primaryXAxis: CategoryAxis(
        axisLine: AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: _axis(dark),
      ),
      primaryYAxis: NumericAxis(
        name: 'pe',
        opposedPosition: true,
        axisLine: AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
      ),
      axes: <ChartAxis>[
        NumericAxis(
          name: 'ev',
          opposedPosition: false,
          axisLine: AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: _axis(dark),
        ),
      ],
      series: <CartesianSeries<StaticValuationPoint, String>>[
        SplineSeries<StaticValuationPoint, String>(
          name: 'P/E',
          dataSource: data,
          xValueMapper: (StaticValuationPoint p, _) => p.year,
          yValueMapper: (StaticValuationPoint p, _) => p.pe,
          yAxisName: 'pe',
          color: c.peRatio,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: false),
        ),
        SplineSeries<StaticValuationPoint, String>(
          name: 'EV/Revenue',
          dataSource: data,
          xValueMapper: (StaticValuationPoint p, _) => p.year,
          yValueMapper: (StaticValuationPoint p, _) => p.evRevenue,
          yAxisName: 'ev',
          color: c.evRevenue,
          width: 2,
          dashArray: const <double>[5, 4],
          markerSettings: const MarkerSettings(isVisible: false),
        ),
      ],
    );
  }

  static Widget _epsChart(bool dark) {
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticEpsSurprise> data = StaticPremiumChartData.epsSurprises;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        shared: true,
        color: UsPremiumPalette.surface(dark),
        borderColor: UsPremiumPalette.border(dark),
        borderWidth: 1,
        elevation: 10,
        header: '',
        textStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      primaryXAxis: CategoryAxis(
        axisLine: AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: _axis(dark),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        axisLine: AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
        numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 2),
      ),
      series: <CartesianSeries<StaticEpsSurprise, String>>[
        ColumnSeries<StaticEpsSurprise, String>(
          name: 'Estimate',
          dataSource: data,
          xValueMapper: (StaticEpsSurprise e, _) => e.quarter,
          yValueMapper: (StaticEpsSurprise e, _) => e.estimate,
          color: c.epsEstimate,
          borderRadius: BorderRadius.circular(4),
          width: 0.38,
          spacing: 0.14,
        ),
        ColumnSeries<StaticEpsSurprise, String>(
          name: 'Actual',
          dataSource: data,
          xValueMapper: (StaticEpsSurprise e, _) => e.quarter,
          yValueMapper: (StaticEpsSurprise e, _) => e.actual,
          color: c.epsActual,
          borderRadius: BorderRadius.circular(4),
          width: 0.38,
          spacing: 0.14,
        ),
      ],
    );
  }

  static Widget _correlationChart(bool dark) {
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticCorrelationCell> cells = StaticPremiumChartData.correlationMatrix;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const int columns = 3;
        const double gap = 5;
        final int rows = (cells.length / columns).ceil();
        final double tileWidth = (constraints.maxWidth - ((columns - 1) * gap)) / columns;
        final double tileHeight = (constraints.maxHeight - ((rows - 1) * gap)) / rows;
        final double ratio = tileWidth / tileHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: ratio,
          ),
          itemCount: cells.length,
          itemBuilder: (_, int i) {
            final StaticCorrelationCell cell = cells[i];
            final double v = cell.value;
            final Color bg = v >= 0
                ? c.heatmapPositive(v.abs())
                : c.heatmapNegative(v.abs());
            return Tooltip(
              message: '${cell.assetA} / ${cell.assetB}\nρ = ${v.toStringAsFixed(2)}',
              preferBelow: false,
              decoration: BoxDecoration(
                color: UsPremiumPalette.surface(dark),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: UsPremiumPalette.border(dark)),
              ),
              textStyle: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 10,
                color: UsPremiumPalette.text(dark),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: UsPremiumPalette.border(dark)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${cell.assetA}·${cell.assetB}',
                      style: _axis(dark, size: 8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      v.toStringAsFixed(2),
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: UsPremiumPalette.text(dark),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _volumePriceCombo(bool dark) {
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticVolumePricePoint> data =
        StaticPremiumChartData.volumePriceTrend;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        shared: true,
        color: UsPremiumPalette.surface(dark),
        borderColor: UsPremiumPalette.border(dark),
        borderWidth: 1,
        elevation: 10,
        header: '',
        textStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      primaryXAxis: DateTimeAxis(
        axisLine: AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
        dateFormat: DateFormat('MMM yy'),
        intervalType: DateTimeIntervalType.months,
      ),
      primaryYAxis: NumericAxis(
        name: 'volume',
        axisLine: AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: c.grid),
        labelStyle: _axis(dark),
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          final double v = details.value.toDouble();
          final String label = v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}M' : '${v.toStringAsFixed(0)}k';
          return ChartAxisLabel(label, details.textStyle);
        },
      ),
      axes: <ChartAxis>[
        NumericAxis(
          name: 'price',
          opposedPosition: true,
          axisLine: AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: _axis(dark),
          numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 0),
        ),
      ],
      series: <CartesianSeries<StaticVolumePricePoint, DateTime>>[
        ColumnSeries<StaticVolumePricePoint, DateTime>(
          name: 'Volume',
          dataSource: data,
          xValueMapper: (StaticVolumePricePoint p, _) => p.date,
          yValueMapper: (StaticVolumePricePoint p, _) => p.volumeK,
          yAxisName: 'volume',
          color: c.seriesAt(0).withValues(alpha: dark ? 0.32 : 0.24),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          width: 0.62,
          spacing: 0.12,
        ),
        SplineSeries<StaticVolumePricePoint, DateTime>(
          name: 'Price',
          dataSource: data,
          xValueMapper: (StaticVolumePricePoint p, _) => p.date,
          yValueMapper: (StaticVolumePricePoint p, _) => p.price,
          yAxisName: 'price',
          color: c.priceLine,
          width: 2,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 4,
            width: 4,
            color: c.priceLine,
            borderColor: UsPremiumPalette.surface(dark),
            borderWidth: 1,
          ),
        ),
      ],
    );
  }

  static Widget _tornadoChart(bool dark) {
    final UsPremiumChartColors c = chartColors(dark);
    final List<StaticButterflyItem> items = List<StaticButterflyItem>.from(
      StaticPremiumChartData.butterflySales,
    )..sort(
        (StaticButterflyItem a, StaticButterflyItem b) =>
            math.max(b.online, b.inStore).compareTo(math.max(a.online, a.inStore)),
      );

    final double maxSide = items.fold<double>(
      0,
      (double m, StaticButterflyItem i) => math.max(m, math.max(i.online, i.inStore)),
    );
    final double bound = (maxSide * 1.12).ceilToDouble();

    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _metricPill(
                    dark,
                    label: 'ONLINE SALES (\$)',
                    color: c.butterflyLeft,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _metricPill(
                    dark,
                    label: 'IN-STORE SALES (\$)',
                    color: c.butterflyRight,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 34),
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.zero,
            isTransposed: true,
            tooltipBehavior: TooltipBehavior(
              enable: true,
              shared: true,
              color: Colors.transparent,
              borderColor: Colors.transparent,
              elevation: 0,
              builder: (dynamic data, _, __, ___, ____) {
                if (data is! StaticButterflyItem) return const SizedBox.shrink();
                return _comparisonTip(
                  dark,
                  title: data.category,
                  leftLabel: 'Online',
                  leftValue: '\$${data.online.toStringAsFixed(0)}',
                  leftColor: c.butterflyLeft,
                  rightLabel: 'In-Store',
                  rightValue: '\$${data.inStore.toStringAsFixed(0)}',
                  rightColor: c.butterflyRight,
                );
              },
            ),
            primaryXAxis: CategoryAxis(
              axisLine: AxisLine(width: 0),
              majorGridLines: const MajorGridLines(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelStyle: _axis(dark, size: 10),
            ),
            primaryYAxis: NumericAxis(
              axisLine: AxisLine(width: 0),
              majorGridLines: MajorGridLines(width: 0.55, color: c.grid),
              majorTickLines: const MajorTickLines(size: 0),
              labelStyle: _axis(dark, size: 9),
              minimum: -bound,
              maximum: bound,
              interval: (bound / 3).ceilToDouble(),
              plotBands: <PlotBand>[
                PlotBand(
                  isVisible: true,
                  start: 0,
                  end: 0,
                  borderWidth: 1.2,
                  borderColor: UsPremiumPalette.border(dark).withValues(alpha: 0.95),
                ),
              ],
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                if (details.value == 0) {
                  return ChartAxisLabel('', details.textStyle);
                }
                return ChartAxisLabel(
                  '\$${details.value.abs().toStringAsFixed(0)}',
                  details.textStyle,
                );
              },
            ),
            annotations: <CartesianChartAnnotation>[
              CartesianChartAnnotation(
                coordinateUnit: CoordinateUnit.logicalPixel,
                x: 0,
                y: 8,
                region: AnnotationRegion.chart,
                horizontalAlignment: ChartAlignment.center,
                verticalAlignment: ChartAlignment.near,
                widget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: UsPremiumPalette.surface(dark),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: UsPremiumPalette.border(dark)),
                  ),
                  child: Text(
                    '0',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: UsPremiumPalette.muted(dark),
                    ),
                  ),
                ),
              ),
            ],
            series: <CartesianSeries<StaticButterflyItem, String>>[
              BarSeries<StaticButterflyItem, String>(
                name: 'Online Sales',
                dataSource: items,
                xValueMapper: (StaticButterflyItem item, _) => item.category,
                yValueMapper: (StaticButterflyItem item, _) => -item.online,
                color: c.butterflyLeft.withValues(alpha: 0.88),
                borderColor: c.butterflyLeft.withValues(alpha: 0.98),
                borderWidth: 0.8,
                borderRadius: BorderRadius.circular(6),
                width: 0.56,
                spacing: 0.12,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.middle,
                  textStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                dataLabelMapper: (StaticButterflyItem item, _) =>
                    '\$${item.online.toStringAsFixed(0)}',
              ),
              BarSeries<StaticButterflyItem, String>(
                name: 'In-Store Sales',
                dataSource: items,
                xValueMapper: (StaticButterflyItem item, _) => item.category,
                yValueMapper: (StaticButterflyItem item, _) => item.inStore,
                color: c.butterflyRight.withValues(alpha: 0.88),
                borderColor: c.butterflyRight.withValues(alpha: 0.98),
                borderWidth: 0.8,
                borderRadius: BorderRadius.circular(6),
                width: 0.56,
                spacing: 0.12,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.middle,
                  textStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                dataLabelMapper: (StaticButterflyItem item, _) =>
                    '\$${item.inStore.toStringAsFixed(0)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static TextStyle _axis(bool dark, {double size = 10}) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: UsPremiumPalette.muted(dark),
      );

  static Widget _metricPill(
    bool dark, {
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.35,
            color: color,
          ),
        ),
      );

  static Widget _comparisonTip(
    bool dark, {
    required String title,
    required String leftLabel,
    required String leftValue,
    required Color leftColor,
    required String rightLabel,
    required String rightValue,
    required Color rightColor,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: UsPremiumPalette.surface(dark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: UsPremiumPalette.border(dark)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: UsPremiumPalette.text(dark),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _tipMetric(dark, label: leftLabel, value: leftValue, color: leftColor),
                const SizedBox(width: 10),
                _tipMetric(dark, label: rightLabel, value: rightValue, color: rightColor),
              ],
            ),
          ],
        ),
      );

  static Widget _tipMetric(
    bool dark, {
    required String label,
    required String value,
    required Color color,
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 10,
                    color: UsPremiumPalette.muted(dark),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: UsPremiumPalette.text(dark),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({
    required this.dark,
    required this.caption,
    required this.height,
    required this.child,
  });

  final bool dark;
  final String caption;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UsPremiumPalette.border(dark)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            caption,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: UsPremiumPalette.muted(dark),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Range52WeekBar extends StatelessWidget {
  const _Range52WeekBar({required this.dark, required this.data});

  final bool dark;
  final StaticRange52Week data;

  @override
  Widget build(BuildContext context) {
    final UsPremiumChartColors c = chartColors(dark);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('\$${data.low.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 11,
                      color: UsPremiumPalette.muted(dark),
                    )),
                Text('\$${data.current.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.priceLine,
                    )),
                Text('\$${data.high.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 11,
                      color: UsPremiumPalette.muted(dark),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: c.rangeTrack,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: data.position,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            c.rangeFill.withValues(alpha: 0.4),
                            c.rangeFill,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 24) * data.position,
                    top: -5,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: c.rangeMarker,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: UsPremiumPalette.surface(dark),
                          width: 2.5,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: c.rangeMarker.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(data.position * 100).toStringAsFixed(0)}% of 52-week range',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 10,
                color: UsPremiumPalette.muted(dark),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Two Evaluation bullet rows — gradient + discrete qualitative ranges.
class _BulletChartPanel extends StatelessWidget {
  const _BulletChartPanel({required this.dark});

  final bool dark;

  static const double _value = 65;
  static const double _target = 83;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: <Widget>[
          Expanded(
            child: _BulletRow(
              dark: dark,
              label: 'Evaluation',
              value: _value,
              target: _target,
              style: _BulletStyle.gradient,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _BulletRow(
              dark: dark,
              label: 'Evaluation',
              value: _value,
              target: _target,
              style: _BulletStyle.bands,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BulletStyle { gradient, bands }

class _BulletRow extends StatefulWidget {
  const _BulletRow({
    required this.dark,
    required this.label,
    required this.value,
    required this.target,
    required this.style,
  });

  final bool dark;
  final String label;
  final double value;
  final double target;
  final _BulletStyle style;

  @override
  State<_BulletRow> createState() => _BulletRowState();
}

class _BulletRowState extends State<_BulletRow> {
  static const Duration _animDuration = Duration(milliseconds: 180);
  static const Curve _animCurve = Curves.easeOutCubic;

  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double labelW = 78;
        const double axisH = 18;
        final double trackH =
            math.max(28.0, (constraints.maxHeight - axisH) * 0.55);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: labelW,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: UsPremiumPalette.text(widget.dark),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: trackH,
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints trackBox) {
                          final double w = trackBox.maxWidth;
                          final double h = trackBox.maxHeight;
                          final double valueX =
                              w * (widget.value.clamp(0, 100) / 100);
                          final double targetX =
                              w * (widget.target.clamp(0, 100) / 100);

                          return MouseRegion(
                            onEnter: (_) => setState(() => _hovering = true),
                            onExit: (_) => setState(() => _hovering = false),
                            cursor: SystemMouseCursors.basic,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _BulletPainter(
                                      dark: widget.dark,
                                      value: widget.value.clamp(0, 100),
                                      target: widget.target.clamp(0, 100),
                                      style: widget.style,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: valueX + 6,
                                  top: (h - 22) / 2,
                                  child: _AnimatedBulletCallout(
                                    visible: _hovering,
                                    text: '${widget.value.round()}%',
                                    duration: _animDuration,
                                    curve: _animCurve,
                                  ),
                                ),
                                Positioned(
                                  left: targetX + 6,
                                  top: (h - 22) / 2,
                                  child: _AnimatedBulletCallout(
                                    visible: _hovering,
                                    text: '${widget.target.round()}%',
                                    duration: _animDuration,
                                    curve: _animCurve,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: axisH,
              child: Padding(
                padding: const EdgeInsets.only(left: labelW),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i <= 10; i++)
                      Expanded(
                        child: Align(
                          alignment: i == 0
                              ? Alignment.centerLeft
                              : (i == 10
                                  ? Alignment.centerRight
                                  : Alignment.center),
                          child: Text(
                            '${i * 10}%',
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: UsPremiumPalette.muted(widget.dark),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedBulletCallout extends StatelessWidget {
  const _AnimatedBulletCallout({
    required this.visible,
    required this.text,
    required this.duration,
    required this.curve,
  });

  final bool visible;
  final String text;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: curve,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(-0.12, 0),
          duration: duration,
          curve: curve,
          child: _BulletCallout(text: text),
        ),
      ),
    );
  }
}

/// Black pill tooltip with a left-pointing caret — matches reference callouts.
class _BulletCallout extends StatelessWidget {
  const _BulletCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CustomPaint(
          size: const Size(7, 10),
          painter: const _CalloutCaretPainter(),
        ),
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 0.8,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalloutCaretPainter extends CustomPainter {
  const _CalloutCaretPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF111111));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BulletPainter extends CustomPainter {
  _BulletPainter({
    required this.dark,
    required this.value,
    required this.target,
    required this.style,
  });

  final bool dark;
  final double value;
  final double target;
  final _BulletStyle style;

  static const List<Color> _bandColors = <Color>[
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFFFEB3B),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final RRect track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(3),
    );
    canvas.save();
    canvas.clipRRect(track);

    if (style == _BulletStyle.gradient) {
      final Paint fill = Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFF4CAF50),
            Color(0xFFCDDC39),
            Color(0xFFFFEB3B),
            Color(0xFFFF9800),
            Color(0xFFF44336),
          ],
          stops: <double>[0, 0.28, 0.5, 0.75, 1],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, fill);
    } else {
      final double bandW = size.width / _bandColors.length;
      for (int i = 0; i < _bandColors.length; i++) {
        canvas.drawRect(
          Rect.fromLTWH(i * bandW, 0, bandW + 0.5, size.height),
          Paint()..color = _bandColors[i],
        );
      }
    }
    canvas.restore();

    final double barH = size.height * 0.42;
    final double barTop = (size.height - barH) / 2;
    final double barW = size.width * (value / 100);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barTop, barW, barH),
        const Radius.circular(1.5),
      ),
      Paint()..color = dark ? const Color(0xFF0F172A) : const Color(0xFF111827),
    );

    final double tx = size.width * (target / 100);
    final Paint tick = Paint()
      ..color = dark ? const Color(0xFF0F172A) : const Color(0xFF111827)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(tx, size.height * 0.12),
      Offset(tx, size.height * 0.88),
      tick,
    );
  }

  @override
  bool shouldRepaint(covariant _BulletPainter old) {
    return old.dark != dark ||
        old.value != value ||
        old.target != target ||
        old.style != style;
  }
}
