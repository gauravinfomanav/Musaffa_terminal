import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/per_share_data_controller.dart';
import 'package:musaffa_terminal/Components/expandable_dynamic_table.dart';
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
          highlightColor: isDarkMode ? const Color(0xFF404040) : Colors.grey[100]!,
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
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      return _buildTerminalPerShareTable(financialData, isDarkMode);
    });
  }

  Widget _buildTerminalPerShareTable(FinancialFundamentals financialData, bool isDarkMode) {
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
    
    List<String> sortedYears = allYears.toList()..sort((a, b) => a.compareTo(b));

    // Create columns for the expandable table - include metric names as first column
    List<ExpandableTableColumn> columns = [
      ExpandableTableColumn(
        key: 'metric',
        title: 'Metric',
        width: 200,
        alignment: TextAlign.left,
      ),
      ...sortedYears.map((year) => ExpandableTableColumn(
        key: year,
        title: year,
        width: 80,
        isNumeric: true,
        alignment: TextAlign.right,
      )),
    ];

    // Create expandable table data
    List<ExpandableTableRowData> tableData = [];

    // Add TTM metrics directly (not as a group)
    if (financialData.revenuePerShareTTM != null && financialData.revenuePerShareTTM!.isNotEmpty) {
      tableData.add(ExpandableTableRowData(
        id: 'revenue_ttm',
        name: 'Revenue per Share (TTM)',
        data: {
          'metric': 'Revenue per Share (TTM)',
          ..._createYearDataMap(financialData.revenuePerShareTTM!, sortedYears),
        },
      ));
    }
    
    if (financialData.ebitPerShareTTM != null && financialData.ebitPerShareTTM!.isNotEmpty) {
      tableData.add(ExpandableTableRowData(
        id: 'ebit_ttm',
        name: 'EBIT per Share (TTM)',
        data: {
          'metric': 'EBIT per Share (TTM)',
          ..._createYearDataMap(financialData.ebitPerShareTTM!, sortedYears),
        },
      ));
    }
    
    if (financialData.epsTTM != null && financialData.epsTTM!.isNotEmpty) {
      tableData.add(ExpandableTableRowData(
        id: 'eps_ttm',
        name: 'Earnings per Share (EPS) (TTM)',
        data: {
          'metric': 'Earnings per Share (EPS) (TTM)',
          ..._createYearDataMap(financialData.epsTTM!, sortedYears),
        },
      ));
    }
    
    if (financialData.dividendPerShareTTM != null && financialData.dividendPerShareTTM!.isNotEmpty) {
      tableData.add(ExpandableTableRowData(
        id: 'dividend_ttm',
        name: 'Dividend per Share (TTM)',
        data: {
          'metric': 'Dividend per Share (TTM)',
          ..._createYearDataMap(financialData.dividendPerShareTTM!, sortedYears),
        },
      ));
    }

    // Add Annual EPS data if available
    if (financialData.epsData != null && financialData.epsData!.isNotEmpty) {
      tableData.add(ExpandableTableRowData(
        id: 'eps_annual',
        name: 'EPS Annual Data',
        data: {
          'metric': 'EPS Annual Data',
          ..._createYearDataMap(financialData.epsData!, sortedYears),
        },
      ));
    }

    // Add other metrics if available
    List<ExpandableTableRowData> otherMetrics = [];
  
    if (otherMetrics.isNotEmpty) {
      tableData.add(ExpandableTableRowData(
        id: 'other_group',
        name: 'Other Metrics',
        data: {},
        isExpandable: true,
        isExpanded: false,
        children: otherMetrics,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
      child: ExpandableDynamicTable(
        columns: columns,
        data: tableData,
        considerPadding: false,
        showNameColumn: false, // Don't show separate name column since we have metric column
        onRowSelect: (row) {
          // Handle row selection and notify parent
          print('Selected: ${row.name}');
          widget.onMetricSelected?.call(row.name);
        },
      ),
    );
  }

  Map<String, dynamic> _createYearDataMap(Map<String, double?> sourceData, List<String> years) {
    Map<String, dynamic> result = {};
    for (String year in years) {
      result[year] = sourceData[year];
    }
    return result;
  }
}
