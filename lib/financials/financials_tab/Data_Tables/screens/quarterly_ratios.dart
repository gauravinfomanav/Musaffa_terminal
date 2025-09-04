import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../controllers/ratios_quarterly_controller.dart';
import '../data sources/quarterly_ratio_data_source.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class QuarterlyRatiosTable extends StatelessWidget {
  final String symbol;
  final String title;

  const QuarterlyRatiosTable({
    Key? key,
    required this.symbol,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuarterlyRatiosController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!controller.processingComplete.value || controller.tableData.isEmpty) {
        return const Center(child: Text('No data available.'));
      }

      final sortedData = _sortTableData(controller.tableData);
      final allQuarters = _ensureAllQuarters(controller.quarters);

      final dataSource = QuarterlyRatiosDataSource(
        tableData: sortedData,
        quarters: allQuarters,
      );

      final screenHeight = MediaQuery.of(context).size.height;
      const double minRowHeight = 50.0;
      const double maxRowHeight = 60.0;
      const double heightFraction = 0.03;
      double rowHeight = (screenHeight * heightFraction).clamp(minRowHeight, maxRowHeight);
      double tableHeight = (sortedData.length + 1) * rowHeight;
      tableHeight = tableHeight.clamp(200.0, double.infinity);

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: tableHeight),
              child: SfDataGridTheme(
                data: SfDataGridThemeData(
                  frozenPaneLineWidth: 0,
                  frozenPaneLineColor: Colors.transparent,
                ),
                child: SfDataGrid(
                  source: dataSource,
                  columns: _buildColumns(allQuarters, title),
                  columnWidthMode: ColumnWidthMode.auto,
                  gridLinesVisibility: GridLinesVisibility.horizontal,
                  headerGridLinesVisibility: GridLinesVisibility.none,
                  frozenColumnsCount: 1,
                  rowHeight: rowHeight,
                  verticalScrollPhysics: const NeverScrollableScrollPhysics(),
                  horizontalScrollPhysics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrapRows: true,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

 List<quarterlyRatioDataModel> _sortTableData(List<quarterlyRatioDataModel> data) {
  final orderedMetrics = [
    'Net Margin',
    'Quick Ratio',
    'Current Ratio',
    'Price to Earnings (TTM)',
    'Price to Sales (TTM)',
    'Price to Book',
    'Free Cash Flow Margin',
    'Payout Ratio (TTM)',
    'Gross Margin',
    'Operating Margin',
    'Long-Term Debt to Equity (TTM)',
    'Total Debt to Total Asset (TTM)',
    'Long-Term Debt to Total Asset (TTM)',
    'Total Debt to Total Capital',
    'Inventory Turnover (TTM)',
    'Receivables Turnover (TTM)',
    'Asset Turnover (TTM)',
    'Return on Equity (TTM)',
    'Return on Assets (TTM)',
  ];

  Map<String, int> orderMap = {};
  for (int i = 0; i < orderedMetrics.length; i++) {
    orderMap[orderedMetrics[i]] = i;
  }

  // Add debugging
  print('Raw tableData metrics: ${data.map((e) => e.metric).toList()}');
  var filteredData = data.where((item) => orderedMetrics.contains(item.metric)).toList();
  print('Filtered data: ${filteredData.map((e) => e.metric).toList()}');

  return filteredData..sort((a, b) {
    int indexA = orderMap[a.metric] ?? 999;
    int indexB = orderMap[b.metric] ?? 999;
    return indexA.compareTo(indexB);
  });
}

  List<String> _ensureAllQuarters(List<String> existingQuarters) {
    String year = "";
    if (existingQuarters.isNotEmpty) {
      final parts = existingQuarters[0].split(' ');
      if (parts.length > 1) {
        year = parts[1];
      }
    } else {
      year = DateTime.now().year.toString();
    }

    final allQuarters = ['Q1 $year', 'Q2 $year', 'Q3 $year', 'Q4 $year'];
    return allQuarters;
  }

  List<GridColumn> _buildColumns(List<String> quarters, String title) {
    List<GridColumn> columns = [
      GridColumn(
        columnName: 'metric',
        label: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(color: Color(0xFFEFF4FF)),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
        width: 150,
      ),
    ];

    columns.addAll(quarters.map((quarter) {
      return GridColumn(
        columnName: quarter,
        label: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFEFF4FF)),
          child: Text(
            quarter,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
        width: 80,
      );
    }));

    return columns;
  }
}