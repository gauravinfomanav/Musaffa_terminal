import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/charts/controllers/ticker_quarterly_charts_controller.dart';
import 'package:musaffa_terminal/charts/models/financial_statement_type.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/models/quarterly_chart_view_model.dart';
import 'package:musaffa_terminal/charts/widgets/quarterly_bar_chart.dart';
import 'package:musaffa_terminal/utils/constants.dart';

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
      cardBackgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      cardBorderColor:
          isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
      gridLineColor:
          isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
      axisLineColor:
          isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Obx(() => _buildStatementTabs(isDark)),
        ),
        const SizedBox(height: 8),
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
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

  Widget _buildStatementTabs(bool isDark) {
    final FinancialStatementType selected = _controller.selectedStatement.value;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(90),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          FinancialStatementType.values.length,
          (int index) {
            final FinancialStatementType statement =
                FinancialStatementType.values[index];
            final bool isSelected = selected == statement;

            return GestureDetector(
              onTap: () => _controller.selectStatement(statement),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(90),
                ),
                child: Text(
                  statement.label,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
    return QuarterlyBarChart(
      title: chart.title,
      displayValue: chart.displayValue,
      unit: chart.unit,
      data: chart.data,
      theme: QuarterlyBarChartTheme(
        cardBackgroundColor: baseTheme.cardBackgroundColor,
        cardBorderColor: baseTheme.cardBorderColor,
        gridLineColor: baseTheme.gridLineColor,
        axisLineColor: baseTheme.axisLineColor,
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    final Color base = isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade300;
    final Color highlight =
        isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade100;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: Column(
          children: List<Widget>.generate(5, (int rowIndex) {
            return Padding(
              padding: EdgeInsets.only(top: rowIndex == 0 ? 0 : 16),
              child: Row(
                children: <Widget>[
                  for (int column = 0;
                      column < _chartsPerRow;
                      column++) ...<Widget>[
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
              ),
            );
          }),
        ),
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
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
