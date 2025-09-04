
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/ratios_annual_controller.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/data%20sources/ratios_annual_datasource.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class AnnualRatios extends StatefulWidget {
  final String symbol;

  const AnnualRatios({super.key, required this.symbol});

  @override
  State<AnnualRatios> createState() => _AnnualRatiosState();
}

class _AnnualRatiosState extends State<AnnualRatios> {
  late final RatiosController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(RatiosController());
    controller.fetchRatio(widget.symbol);
  }

  List<GridColumn> _buildColumns(List<String> years) {
    return [
      GridColumn(
        columnName: 'metric',
        label: Container(
          padding: const EdgeInsets.all(16.0),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(color: Color(0xFFEFF4FF)),
          child: const Text(
            'Financial Ratios',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: Constants.FONT_DEFAULT_NEW),
          ),
        ),
        width: 120,
      ),
      ...years.map((year) => GridColumn(
            columnName: year,
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFEFF4FF)),
              child: Text(
                year,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: Constants.FONT_DEFAULT_NEW),
              ),
            ),
          )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final data = controller.getFinancialDataForYears();
      final dataSource = FinancialRatiosDataSource(ratiosData: data);
      final years = controller.years;

      // Calculate dynamic row height based on screen height
      final screenHeight = MediaQuery.of(context).size.height;
      const double minRowHeight = 50.0; // Minimum readable height
      const double maxRowHeight = 60.0; // Maximum height for readability
      const double heightFraction = 0.03; // Fraction of screen height (e.g., 3% of screen height)
      double rowHeight = (screenHeight * heightFraction).clamp(minRowHeight, maxRowHeight);

      // Calculate dynamic table height based on row count
      double tableHeight = (data.length + 1) * rowHeight; // +1 for header row
      tableHeight = tableHeight.clamp(200.0, double.infinity); // Allow full height if needed, but constrain minimum

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          // Remove fixed height and use dynamic sizing with SingleChildScrollView
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
                  columns: _buildColumns(years),
                  columnWidthMode: ColumnWidthMode.auto,
                  gridLinesVisibility: GridLinesVisibility.horizontal,
                  headerGridLinesVisibility: GridLinesVisibility.none,
                  frozenColumnsCount: 1,
                  rowHeight: rowHeight, // Use dynamic row height
                  verticalScrollPhysics: const NeverScrollableScrollPhysics(), // Enable scrolling if content exceeds height
                  horizontalScrollPhysics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrapRows: true, // Allow grid to size itself
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}