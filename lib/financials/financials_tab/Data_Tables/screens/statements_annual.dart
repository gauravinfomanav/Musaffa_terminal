import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../controllers/statements_chart_annual.dart' as annual;
import '../controllers/statements_chart_quarterly.dart' as quarterly;
import '../data sources/statements_chart_datasource.dart';

class FinancialStatementsTable extends StatefulWidget {
  final String symbol;
  final String reportType;
  final String title;

  const FinancialStatementsTable({
    Key? key,
    required this.symbol,
    required this.reportType,
    required this.title,
  }) : super(key: key);

  @override
  State<FinancialStatementsTable> createState() => _FinancialStatementsTableState();
}

class _FinancialStatementsTableState extends State<FinancialStatementsTable> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(annual.FinancialStatementsController());
    controller.fetchFinancialReport(widget.symbol, widget.reportType);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.financialData.isEmpty) {
        return const Center(child: Text('No data available.'));
      }

      // Convert annual model to quarterly model format (they have identical structure)
      final convertedData = controller.financialData.map((item) => 
        quarterly.FinancialStatementModel(
          name: item.name,
          year: item.year,
          originalValue: item.originalValue,
          isSubItem: item.isSubItem,
          subItems: item.subItems.map((subItem) => 
            quarterly.FinancialStatementModel(
              name: subItem.name,
              year: subItem.year,
              originalValue: subItem.originalValue,
              isSubItem: subItem.isSubItem,
              subItems: const [],
            )
          ).toList(),
        )
      ).toList();

      final financialDataSource = FinancialDataSource(
        data: convertedData,
        years: controller.years.toList(),
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
              columns: _buildColumns(controller.years, widget.title),
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
                    final rowId = financialDataSource.getRowIdentifier(cellValue, rowIndex);
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

  List<GridColumn> _buildColumns(List<String> years, String title) {
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
            ),
          ),
        ),
        width: 150,
      ),
    ];

    columns.addAll(years.map((year) {
      return GridColumn(
        columnName: year,
        label: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFEFF4FF)),
          child: Text(
            year,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        width: 90,
      );
    }));

    return columns;
  }
}