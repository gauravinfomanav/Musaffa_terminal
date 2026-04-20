import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/per_share_data_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalPerShareScreen extends StatefulWidget {
  final String symbol;
  final String currency;
  final Function(String)? onMetricSelected;

  const TerminalPerShareScreen({
    Key? key,
    required this.symbol,
    required this.currency,
    this.onMetricSelected,
  }) : super(key: key);

  @override
  State<TerminalPerShareScreen> createState() => _TerminalPerShareScreenState();
}

class _TerminalPerShareScreenState extends State<TerminalPerShareScreen> {
  late FinancialFundamentalsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FinancialFundamentalsController());
    controller.fetchFinancialFundamentals(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return ShimmerWidgets.perShareTableShimmer(
          baseColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[300]!,
          highlightColor:
              isDarkMode ? const Color(0xFF404040) : Colors.grey[100]!,
        );
      }

      final financialData = controller.financialData.value;
      if (financialData == null) {
        return Center(
          child: Text(
            'No per share data available',
            style: TextStyle(
              fontSize: 11,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      return _buildTerminalPerShareTable(financialData, isDarkMode);
    });
  }

  Widget _buildTerminalPerShareTable(
      FinancialFundamentals financialData, bool isDarkMode) {
    // Get all available years from all data sources
    Set<String> allYears = {};

    if (financialData.revenuePerShareTTM != null) {
      allYears.addAll(financialData.revenuePerShareTTM!.keys);
    }
    if (financialData.ebitPerShareTTM != null) {
      allYears.addAll(financialData.ebitPerShareTTM!.keys);
    }
    if (financialData.epsTTM != null) {
      allYears.addAll(financialData.epsTTM!.keys);
    }
    if (financialData.dividendPerShareTTM != null) {
      allYears.addAll(financialData.dividendPerShareTTM!.keys);
    }
    if (financialData.epsData != null) {
      allYears.addAll(financialData.epsData!.keys);
    }

    List<String> sortedYears = allYears.toList()
      ..sort((a, b) => a.compareTo(b));

    // Create columns for the dynamic table - include metric names as first column
    List<DynamicTableColumn> columns = [
      DynamicTableColumn(
        key: 'metric',
        label: 'Metric',
        width: 200,
        align: TextAlign.left,
        sortable: false,
      ),
      ...sortedYears.map((year) => DynamicTableColumn(
            key: year,
            label: year,
            width: 80,
            align: TextAlign.center,
            sortable: true,
          )),
    ];

    // Create expandable table data
    List<DynamicTableRow> tableData = [];

    // Add TTM metrics directly (not as a group)
    if (financialData.revenuePerShareTTM != null &&
        financialData.revenuePerShareTTM!.isNotEmpty) {
      tableData.add(DynamicTableRow(
        id: 'revenue_ttm',
        data: {
          'metric': 'Revenue per Share (TTM)',
          ..._createYearDataMap(financialData.revenuePerShareTTM!, sortedYears),
        },
      ));
    }

    if (financialData.ebitPerShareTTM != null &&
        financialData.ebitPerShareTTM!.isNotEmpty) {
      tableData.add(DynamicTableRow(
        id: 'ebit_ttm',
        data: {
          'metric': 'EBIT per Share (TTM)',
          ..._createYearDataMap(financialData.ebitPerShareTTM!, sortedYears),
        },
      ));
    }

    if (financialData.epsTTM != null && financialData.epsTTM!.isNotEmpty) {
      tableData.add(DynamicTableRow(
        id: 'eps_ttm',
        data: {
          'metric': 'Earnings per Share (EPS) (TTM)',
          ..._createYearDataMap(financialData.epsTTM!, sortedYears),
        },
      ));
    }

    if (financialData.dividendPerShareTTM != null &&
        financialData.dividendPerShareTTM!.isNotEmpty) {
      tableData.add(DynamicTableRow(
        id: 'dividend_ttm',
        data: {
          'metric': 'Dividend per Share (TTM)',
          ..._createYearDataMap(
              financialData.dividendPerShareTTM!, sortedYears),
        },
      ));
    }

    // Add Annual EPS data if available
    if (financialData.epsData != null && financialData.epsData!.isNotEmpty) {
      tableData.add(DynamicTableRow(
        id: 'eps_annual',
        data: {
          'metric': 'EPS Annual Data',
          ..._createYearDataMap(financialData.epsData!, sortedYears),
        },
      ));
    }

    // Add other metrics if available
    List<DynamicTableRow> otherMetrics = [];

    if (otherMetrics.isNotEmpty) {
      tableData.add(DynamicTableRow(
        id: 'other_group',
        data: {'metric': 'Other Metrics'},
        isExpandable: true,
        isExpanded: false,
        children: otherMetrics,
      ));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DynamicTableFromWeb(
          columns: columns,
          rows: tableData,
          paginated: false,
          selectable: false,
          showTickerCell: false,
          enableColumnFilters: false,
          loading: controller.isLoading.value,
          rowHeight: 40,
          headerHeight: 32,
          indentSize: 20,
          considerPadding: false,
          showNameColumn: false,
          compactPinnedLayout: true,
          autoPinStatColumns: false,
          showPinnedSectionDividers: false,
          columnSpacing: 22,
          onRowDoubleClick: (row) {
            final metricName = row.data['metric']?.toString() ?? '';
            if (metricName.isNotEmpty) {
              widget.onMetricSelected?.call(metricName);
            }
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _createYearDataMap(
      Map<String, double?> sourceData, List<String> years) {
    Map<String, dynamic> result = {};
    for (String year in years) {
      result[year] = sourceData[year];
    }
    return result;
  }
}
