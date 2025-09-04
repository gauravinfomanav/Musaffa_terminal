import 'package:flutter/material.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/per_share_data_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class FinancialDataSource extends DataGridSource {
  final FinancialFundamentals financialData;
  final List<String> years; // Added years parameter
  List<DataGridRow> _dataRows = [];

  FinancialDataSource({
    required this.financialData,
    required this.years,
  }) {
    _buildDataRows();
  }

  bool _isRowEmpty(Map<String, double?>? data) {
    if (data == null) return true;
    return years.every((year) => data[year] == null || data[year] == 0);
  }

  String _formatValue(double? value) {
    if (value == null || value == 0) return '-';
    return value.abs().toStringAsFixed(2);
  }

  void _buildDataRows() {
    _dataRows = [];

    // Define metrics with their data
    final metrics = [
      {
        'name': 'Revenue per Share (TTM)',
        'data': financialData.revenuePerShareTTM,
      },
      {
        'name': 'EBIT per Share (TTM)',
        'data': financialData.ebitPerShareTTM,
      },
      {
        'name': 'Earnings per Share (EPS) (TTM)',
        'data': financialData.epsTTM,
      },
      {
        'name': 'Dividend per Share (TTM)',
        'data': financialData.dividendPerShareTTM,
      },
    ];

    // Build rows for metrics that have data
    for (var metric in metrics) {
      if (!_isRowEmpty(metric['data'] as Map<String, double?>?)) {
        List<DataGridCell> cells = [
          DataGridCell(columnName: 'metric', value: metric['name'] as String),
        ];

        // Ensure a cell for every year, even if data is missing
        for (var year in years) {
          final data = metric['data'] as Map<String, double?>?;
          final value = data?[year];
          cells.add(DataGridCell(
            columnName: year,
            value: _formatValue(value),
          ));
        }

        _dataRows.add(DataGridRow(cells: cells));
      }
    }

    // Add EPS Forward row
    List<DataGridCell> epsForwardCells = [
      DataGridCell(columnName: 'metric', value: 'EPS Forward'),
    ];
    bool hasForwardData = false;
    for (var year in years) {
      String displayValue = '-';
      if (financialData.epsData != null &&
          financialData.epsData!.containsKey(year) &&
          int.parse(year) >= DateTime.now().year) {
        final value = financialData.epsData![year];
        if (value != null && value != 0) {
          displayValue = value.abs().toStringAsFixed(2);
          hasForwardData = true;
        }
      }
      epsForwardCells.add(DataGridCell(columnName: year, value: displayValue));
    }
    if (hasForwardData) {
      _dataRows.add(DataGridRow(cells: epsForwardCells));
    }

    // Add EPS Annual Data row
    if (financialData.epsData != null && financialData.epsData!.isNotEmpty) {
      List<DataGridCell> epsAnnualCells = [
        DataGridCell(columnName: 'metric', value: 'EPS Annual'),
      ];
      bool hasAnnualData = false;
      for (var year in years) {
        String displayValue = '-';
        if (financialData.epsData!.containsKey(year)) {
          final value = financialData.epsData![year];
          if (value != null && value != 0) {
            displayValue = value.abs().toStringAsFixed(2);
            hasAnnualData = true;
          }
        }
        epsAnnualCells.add(DataGridCell(columnName: year, value: displayValue));
      }
      if (hasAnnualData) {
        _dataRows.add(DataGridRow(cells: epsAnnualCells));
      }
    }
  }

  @override
  List<DataGridRow> get rows => _dataRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Container(
          alignment: cell.columnName == 'metric'
              ? Alignment.centerLeft
              : Alignment.center,
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            cell.value.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}