import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_revenue_geography_controller.dart';
import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TickerRevenueGeographySection extends StatelessWidget {
  const TickerRevenueGeographySection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
  });

  final TickerRevenueGeographyController controller;
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
            child: TickerFinnhubLoadingState(isDarkMode: isDarkMode, height: 180),
          );
        }

        if (!controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const TickerFinnhubSectionTitle(title: 'Revenue by Geography'),
                const SizedBox(height: 8),
                TickerFinnhubEmptyState(
                  isDarkMode: isDarkMode,
                  message: controller.error ?? 'No geography revenue data found',
                ),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          );
        }

        final RevenueBreakdownModel model = controller.model!;
        final RevenueBreakdownItem largest = controller.largestRegion!;
        final List<RevenueBreakdownItem> items = model.items;

        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const TickerFinnhubSectionTitle(title: 'Revenue by Geography'),
              const SizedBox(height: 8),
              _buildSummary(largest, controller.totalRevenue),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: SfCircularChart(
                  legend: const Legend(isVisible: false),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                      if (data is! RevenueBreakdownItem) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(
                          '${data.region}\n'
                          '${_fmtRevenue(data.revenue)}\n'
                          '${_fmtPercent(data.percentage)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  series: <CircularSeries<RevenueBreakdownItem, String>>[
                    PieSeries<RevenueBreakdownItem, String>(
                      dataSource: items,
                      xValueMapper: (RevenueBreakdownItem i, _) => i.region,
                      yValueMapper: (RevenueBreakdownItem i, _) => i.revenue,
                      pointColorMapper: (RevenueBreakdownItem i, int index) {
                        final List<Color> palette = <Color>[
                          const Color(0xFF3B82F6),
                          const Color(0xFF81AACE),
                          const Color(0xFF99CD44),
                          const Color(0xFFF59E0B),
                          const Color(0xFF8B5CF6),
                          const Color(0xFFEF4444),
                        ];
                        return palette[index % palette.length];
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildLegendTable(items),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(RevenueBreakdownItem largest, num total) {
    final List<List<String>> summary = <List<String>>[
      <String>[
        'Largest Region',
        '${largest.region} (${_fmtPercent(largest.percentage)})',
      ],
      <String>['Total Geographic Revenue', _fmtRevenue(total)],
    ];

    return Row(
      children: summary
          .map((List<String> item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item[0], style: DashboardTextStyles.tickerSymbol.copyWith(fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(item[1], style: DashboardTextStyles.dataCell.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildLegendTable(List<RevenueBreakdownItem> items) {
    final List<SimpleColumn> columns = <SimpleColumn>[
      const SimpleColumn(label: 'REGION', fieldName: 'region', width: 180),
      const SimpleColumn(label: 'REVENUE', fieldName: 'revenue', isNumeric: true, width: 140),
      const SimpleColumn(label: 'SHARE %', fieldName: 'share', isNumeric: true, width: 100),
    ];
    final List<SimpleRowModel> rows = items.map((RevenueBreakdownItem item) {
      return SimpleRowModel(
        symbol: item.region,
        name: '',
        fields: <String, dynamic>{
          'region': item.region,
          'revenue': _fmtRevenue(item.revenue),
          'share': _fmtPercent(item.percentage),
        },
      );
    }).toList();

    return DynamicTable(
      columns: columns,
      rows: rows,
      showFixedColumn: false,
      considerPadding: false,
      columnSpacing: 12,
      enableLivePrices: false,
      zebraStripes: false,
      enableColumnCustomization: false,
      showColumnActionMenu: false,
      showColumnResizeHandle: false,
      compactHeaderText: true,
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
