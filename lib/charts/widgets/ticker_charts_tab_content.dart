import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/charts/controllers/ticker_quarterly_charts_controller.dart';
import 'package:musaffa_terminal/charts/models/financial_statement_type.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/models/quarterly_chart_view_model.dart';
import 'package:musaffa_terminal/charts/widgets/quarterly_bar_chart.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Charts tab body for ticker detail — live quarterly bar charts from Infomanav API.
class TickerChartsTabContent extends StatefulWidget {
  const TickerChartsTabContent({
    super.key,
    required this.symbol,
  });

  final String symbol;

  @override
  State<TickerChartsTabContent> createState() => _TickerChartsTabContentState();
}

class _TickerChartsTabContentState extends State<TickerChartsTabContent> {
  static const int _chartsPerRow = 3;

  late final TickerQuarterlyChartsController _controller;
  late final ScrollController _scrollController;
  final Map<FinancialStatementType, bool> _showPriceOverlayByStatement =
      <FinancialStatementType, bool>{
        FinancialStatementType.ic: false,
        FinancialStatementType.bs: false,
        FinancialStatementType.cf: false,
      };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = Get.put(
      TickerQuarterlyChartsController(),
      tag: widget.symbol,
    );
    _controller.load(
      widget.symbol,
      statement: FinancialStatementType.ic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TickerChartsTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _controller.load(
        widget.symbol,
        statement: _controller.selectedStatement.value,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final QuarterlyBarChartTheme baseTheme = QuarterlyBarChartTheme(
      cardBackgroundColor: HomeUi.cardBg(isDark),
      cardBorderColor: HomeUi.borderLight(isDark),
      gridLineColor: HomeUi.borderLight(isDark),
      axisLineColor: HomeUi.borderStrong(isDark),
      priceAxisLabelColor: HomeUi.accent(isDark),
      barGradient: HomeUi.chartBarGradient(isDark),
      barCornerRadius: 6,
      barWidth: 0.48,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Obx(() => _buildTopControls(isDark)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            if (_controller.isLoading.value) {
              return _buildLoading(isDark);
            }

            if (_controller.errorMessage.value.isNotEmpty &&
                !_controller.hasData) {
              return _buildError(isDark, _controller.errorMessage.value);
            }

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildChartsGrid(
                  charts: _controller.charts.toList(),
                  baseTheme: baseTheme,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTopControls(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: _buildStatementTabs(isDark)),
        const SizedBox(width: 8),
        _buildPriceToggle(isDark),
      ],
    );
  }

  Widget _buildStatementTabs(bool isDark) {
    final List<String> labels =
        FinancialStatementType.values.map((s) => s.label).toList();
    final int selectedIndex = FinancialStatementType.values
        .indexOf(_controller.selectedStatement.value)
        .clamp(0, labels.length - 1);

    return HomeUi.segmentedControl(
      dark: isDark,
      options: labels,
      selectedIndex: selectedIndex,
      onChanged: (index) =>
          _controller.selectStatement(FinancialStatementType.values[index]),
    );
  }

  Widget _buildPriceToggle(bool isDark) {
    final FinancialStatementType statement = _controller.selectedStatement.value;
    final bool isEnabled = _showPriceOverlayByStatement[statement] ?? false;

    return HomeUi.ghostAction(
      label: isEnabled ? 'Price on' : 'Add Price',
      dark: isDark,
      icon: isEnabled ? Icons.show_chart_rounded : Icons.add_chart_outlined,
      onTap: () {
        setState(() {
          _showPriceOverlayByStatement[statement] = !isEnabled;
        });
      },
    );
  }

  Widget _buildChartsGrid({
    required List<QuarterlyChartViewModel> charts,
    required QuarterlyBarChartTheme baseTheme,
  }) {
    final List<Widget> rows = <Widget>[];

    for (int index = 0; index < charts.length; index += _chartsPerRow) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 16));
      }

      final List<QuarterlyChartViewModel> rowCharts = charts.sublist(
        index,
        math.min(index + _chartsPerRow, charts.length),
      );

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int column = 0; column < _chartsPerRow; column++) ...<Widget>[
              if (column > 0) const SizedBox(width: 16),
              Expanded(
                child: column < rowCharts.length
                    ? _buildChartCard(rowCharts[column], baseTheme)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildChartCard(
    QuarterlyChartViewModel chart,
    QuarterlyBarChartTheme baseTheme,
  ) {
    final FinancialStatementType statement = _controller.selectedStatement.value;
    final bool showPrice = _showPriceOverlayByStatement[statement] ?? false;

    return SizedBox(
      height: 300,
      child: QuarterlyBarChart(
        title: chart.title,
        displayValue: chart.displayValue,
        unit: chart.unit,
        data: chart.data,
        priceData: showPrice ? chart.priceData : const <PriceDataPoint>[],
        theme: QuarterlyBarChartTheme(
          cardBackgroundColor: baseTheme.cardBackgroundColor,
          cardBorderColor: baseTheme.cardBorderColor,
          gridLineColor: baseTheme.gridLineColor,
          axisLineColor: baseTheme.axisLineColor,
          priceAxisLabelColor: baseTheme.priceAxisLabelColor,
          barGradient: baseTheme.barGradient,
          barCornerRadius: baseTheme.barCornerRadius,
          barWidth: baseTheme.barWidth,
          expandChart: true,
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    final Color base = isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade300;
    final Color highlight =
        isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade100;

    return Scrollbar(
      controller: _scrollController,
      child: ListView.separated(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int rowIndex) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int column = 0; column < _chartsPerRow; column++) ...<Widget>[
                if (column > 0) const SizedBox(width: 16),
                Expanded(
                  child: ShimmerWidgets.chartShimmer(
                    height: 300,
                    baseColor: base,
                    highlightColor: highlight,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: HomeUi.bodyText(isDark).copyWith(
            color: HomeUi.negative(isDark),
          ),
        ),
      ),
    );
  }
}
