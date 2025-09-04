import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../data sources/quarterly_financial_datasource.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import '../controllers/statements_chart_quarterly.dart';



class FinancialStatementsQuarterlyTable extends StatefulWidget {
  final String symbol;
  final String reportType;
  final String title;

  const FinancialStatementsQuarterlyTable({
    Key? key,
    required this.symbol,
    required this.reportType,
    required this.title,
  }) : super(key: key);

  @override
  State<FinancialStatementsQuarterlyTable> createState() => _FinancialStatementsQuarterlyTableState();
}

class _FinancialStatementsQuarterlyTableState extends State<FinancialStatementsQuarterlyTable> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinancialStatementsQuarterlyController());
    controller.fetchFinancialReport(widget.symbol, widget.reportType);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.financialData.isEmpty) {
        return const Center(child: Text('No quarterly data available.'));
      }

      final financialDataSource = FinancialQuarterlyDataSource(
        data: controller.financialData,
        quarters: controller.quarters,
      );

      final screenHeight = MediaQuery.of(context).size.height;
      const double minRowHeight = 50.0;
      const double maxRowHeight = 60.0;
      const double heightFraction = 0.03;
      double rowHeight = (screenHeight * heightFraction).clamp(minRowHeight, maxRowHeight);

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
          child: SfDataGridTheme(
            data: SfDataGridThemeData(
              frozenPaneLineWidth: 0,
              frozenPaneLineColor: Colors.transparent,
            ),
            child: SfDataGrid(
              source: financialDataSource,
              columns: _buildColumns(controller.quarters, widget.title),
              columnWidthMode: ColumnWidthMode.auto,
              gridLinesVisibility: GridLinesVisibility.horizontal,
              headerGridLinesVisibility: GridLinesVisibility.none,
              frozenColumnsCount: 1,
              rowHeight: rowHeight,
              verticalScrollPhysics: const NeverScrollableScrollPhysics(),
              horizontalScrollPhysics: const AlwaysScrollableScrollPhysics(),
              shrinkWrapRows: true,
              allowColumnsResizing: true,
             onCellTap: (details) {
                if (details.column.columnName == 'metric') {
                  final rowIndex = details.rowColumnIndex.rowIndex - 1;
                  if (rowIndex >= 0 && rowIndex < financialDataSource.rows.length) {
                    final cellValue = financialDataSource.rows[rowIndex].getCells()[0].value.toString();
                    final indentLevel = financialDataSource.getIndentLevel(cellValue);
                    final trimmedValue = cellValue.replaceAll(RegExp(r'^[>v]\s'), '').trimLeft();
                    final rowId = '$indentLevel:$trimmedValue'; // Match _addRow's rowId
                    financialDataSource.toggleRowExpansion(rowId);
                  }
                }
              },
            ),
          ),
        ),
      );
    });
  }

  List<GridColumn> _buildColumns(List<String> quarters, String title) {
    List<GridColumn> columns = [
      GridColumn(
        columnName: 'metric',
        label: Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(color: Color(0xFFEFF4FF)),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
        width: 150, // Increased width to accommodate icons
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
        width: 90,
      );
    }));

    return columns;
  }
}