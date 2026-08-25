import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_revenue_breakdown_controller.dart';
import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TickerRevenueBreakdownSection extends StatelessWidget {
  const TickerRevenueBreakdownSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
  });

  final TickerRevenueBreakdownController controller;
  final bool isDarkMode;
  final VoidCallback onRetry;

  static const List<Color> _palette = <Color>[
    Color(0xFF1F4E79),
    Color(0xFFE4681F),
    Color(0xFF5B7C99),
    Color(0xFFC42329),
    Color(0xFF6B7280),
    Color(0xFF2F5D50),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isLoading && !controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(),
                const SizedBox(height: 16),
                TickerFinnhubLoadingState(
                  isDarkMode: isDarkMode,
                  height: 180,
                ),
              ],
            ),
          );
        }

        if (!controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(),
                const SizedBox(height: 10),
                TickerFinnhubEmptyState(
                  isDarkMode: isDarkMode,
                  message:
                      controller.error ?? 'No revenue breakdown data found',
                ),
                const SizedBox(height: 10),
                HomeUi.ghostAction(
                  label: 'Retry',
                  dark: isDarkMode,
                  icon: Icons.refresh_rounded,
                  onTap: onRetry,
                ),
              ],
            ),
          );
        }

        final RevenueBreakdownSlice? product = controller.product;
        final RevenueBreakdownSlice? geography = controller.geography;

        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _header(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool sideBySide = constraints.maxWidth >= 720 &&
                      product != null &&
                      geography != null;
                  if (sideBySide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _sliceColumn(product)),
                        const SizedBox(width: 20),
                        Expanded(child: _sliceColumn(geography)),
                      ],
                    );
                  }
                  return Column(
                    children: <Widget>[
                      if (product != null) _sliceColumn(product),
                      if (product != null && geography != null)
                        const SizedBox(height: 20),
                      if (geography != null) _sliceColumn(geography),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return const TickerFinnhubSectionTitle(
      title: 'Revenue Breakdown',
      icon: Icons.pie_chart_outline_rounded,
      subtitle: 'Product mix and geography from company filings',
    );
  }

  Widget _sliceColumn(RevenueBreakdownSlice slice) {
    final RevenueBreakdownItem? largest = slice.largest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          slice.title,
          style: HomeUi.sectionTitle(isDarkMode).copyWith(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          slice.periodLabel,
          style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 11.5),
        ),
        if (largest != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            '${largest.label}  ·  ${_fmtPercent(largest.percentage)} of ${_fmtRevenue(slice.total)}',
            style: HomeUi.bodyText(isDarkMode).copyWith(fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 196,
          child: SfCircularChart(
            margin: EdgeInsets.zero,
            legend: const Legend(isVisible: false),
            annotations: <CircularChartAnnotation>[
              if (largest != null)
                CircularChartAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _fmtPercent(largest.percentage),
                        style: HomeUi.tableCellEmphasis(isDarkMode).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 88,
                        child: Text(
                          largest.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: HomeUi.overline(isDarkMode).copyWith(
                            fontSize: 10,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (
                dynamic data,
                dynamic point,
                dynamic series,
                int pointIndex,
                int seriesIndex,
              ) {
                if (data is! RevenueBreakdownItem) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    '${data.label}\n${_fmtRevenue(data.revenue)}  ·  ${_fmtPercent(data.percentage)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            series: <CircularSeries<RevenueBreakdownItem, String>>[
              DoughnutSeries<RevenueBreakdownItem, String>(
                dataSource: slice.items,
                xValueMapper: (RevenueBreakdownItem item, _) => item.label,
                yValueMapper: (RevenueBreakdownItem item, _) => item.revenue,
                pointColorMapper: (RevenueBreakdownItem item, int index) =>
                    _palette[index % _palette.length],
                radius: '88%',
                innerRadius: '64%',
                strokeWidth: 2,
                strokeColor: isDarkMode
                    ? const Color(0xFF14161A)
                    : Colors.white,
                explode: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...slice.items.asMap().entries.map((MapEntry<int, RevenueBreakdownItem> entry) {
          final Color color = _palette[entry.key % _palette.length];
          final RevenueBreakdownItem item = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
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
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeUi.bodyText(isDarkMode).copyWith(fontSize: 12.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmtRevenue(item.revenue),
                  style: HomeUi.tableCellEmphasis(isDarkMode).copyWith(
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Text(
                    _fmtPercent(item.percentage),
                    textAlign: TextAlign.right,
                    style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _fmtRevenue(num value) {
    return valueWithCurrency(
      price: value,
      currency: 'USD',
      showCurrencySymbol: true,
      shorten: true,
    );
  }

  String _fmtPercent(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)}%';
  }
}
