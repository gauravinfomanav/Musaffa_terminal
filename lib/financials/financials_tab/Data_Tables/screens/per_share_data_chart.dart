import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../controllers/per_share_data_controller.dart';
import '../data sources/financial_data_source.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class FinancialTable extends StatelessWidget {
  final String symbol;

  const FinancialTable({Key? key, required this.symbol}) : super(key: key); // Removed unused currency parameter

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinancialFundamentalsController());
    controller.fetchFinancialFundamentals(symbol);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final financialData = controller.financialData.value;
      if (financialData == null) {
        return const Center(child: Text('No data available.'));
      }

      final years = _getAllYears(financialData); // Extract years here
      final financialDataSource = FinancialDataSource(financialData: financialData, years: years);
      final columns = _buildColumns(years);

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
              columns: columns,
              frozenColumnsCount: 1,
              columnWidthMode: ColumnWidthMode.auto,
              gridLinesVisibility: GridLinesVisibility.horizontal,
              headerGridLinesVisibility: GridLinesVisibility.none,
              verticalScrollPhysics: const NeverScrollableScrollPhysics(),
              horizontalScrollPhysics: const AlwaysScrollableScrollPhysics(),
              shrinkWrapRows: true,
            ),
          ),
        ),
      );
    });
  }

  List<String> _getAllYears(FinancialFundamentals financialData) {
    Set<String> allYears = {};

    void addYearsFromData(Map<String, double?>? data) {
      if (data != null) {
        allYears.addAll(data.keys);
      }
    }

    addYearsFromData(financialData.revenuePerShareTTM);
    addYearsFromData(financialData.ebitPerShareTTM);
    addYearsFromData(financialData.epsTTM);
    addYearsFromData(financialData.dividendPerShareTTM);
    if (financialData.epsData != null) {
      allYears.addAll(financialData.epsData!.keys);
    }

    return allYears.toList()..sort();
  }

  List<GridColumn> _buildColumns(List<String> years) {
    List<GridColumn> columns = [
      GridColumn(
        columnName: 'metric',
        label: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(color: Color(0xFFEFF4FF)),
          child: const Text(
            "Currency: USD",
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: Constants.FONT_DEFAULT_NEW),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: Constants.FONT_DEFAULT_NEW),
          ),
        ),
      );
    }).toList());

    return columns;
  }
}