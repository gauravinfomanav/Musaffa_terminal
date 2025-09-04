
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class RatioDefinition {
  final String key;
  final String displayName;

  const RatioDefinition({required this.key, required this.displayName});
}

class RatiosDataSource {
  static const Map<String, String> ratioDisplayNames = {
    'netMargin': 'Net Margin',
    'quickRatio': 'Quick Ratio',
    'currentRatio': 'Current Ratio',
    'pb': 'Price to Book',
    'fcfMargin': 'Free Cash Flow Margin',
    'grossMargin': 'Gross Margin',
    'roa': 'Return on Assets',
    'roic': 'Return on Invested Capital',
    'longtermDebtTotalEquity': 'Long-Term Debt to Equity',
    'totalDebtToTotalAsset': 'Total Debt to Total Asset',
    'longtermDebtTotalAsset': 'Long-Term Debt to Total Asset',
    'totalDebtToTotalCapital': 'Total Debt to Total Capital',
    'operatingMargin': 'Operating Margin',
    'peTTM': 'P/E (TTM)',
    'psTTM': 'P/S (TTM)',
    'payoutRatioTTM': 'Payout Ratio (TTM)',
    'roeTTM': 'ROE (TTM)',
    'roaTTM': 'ROA (TTM)',
    'inventoryTurnoverTTM': 'Inventory Turnover (TTM)',
    'receivablesTurnoverTTM': 'Receivables Turnover (TTM)',
    'assetTurnoverTTM': 'Asset Turnover (TTM)',
  };

  // Define custom order for labels (prioritize "quickRatio" first, then others)
  static const List<String> customLabelOrder = [
    'netMargin',
    'quickRatio', 
    'currentRatio',
    'pb',
    'fcfMargin',
    'grossMargin',
    'roa',
    'roic',
    'longtermDebtTotalEquity',
    'totalDebtToTotalAsset',
    'totalDebtToTotalCapital',
    'operatingMargin',
  ];
}

class FinancialRatiosDataSource extends DataGridSource {
  final Map<String, Map<String, double?>> ratiosData;
  List<DataGridRow> _dataGridRows = [];

  FinancialRatiosDataSource({required this.ratiosData}) {
    _generateDataGridRows();
  }

  void _generateDataGridRows() {
    // Filter and sort metrics based on custom order
    final orderedMetrics = RatiosDataSource.customLabelOrder
        .where((key) => ratiosData.containsKey(key))
        .toList();

    _dataGridRows = orderedMetrics.map((metricKey) {
      final cells = [
        DataGridCell<String>(
          columnName: 'metric',
          value: RatiosDataSource.ratioDisplayNames[metricKey] ?? metricKey,
        ),
      ];

      // Add cells for each year, using the order from the first metric's data
      final years = ratiosData.values.firstOrNull?.keys.toList() ?? [];
      years.forEach((year) {
        final value = ratiosData[metricKey]?[year];
        cells.add(
          DataGridCell<String>(
            columnName: year,
            value: value?.toStringAsFixed(2) ?? '-',
          ),
        );
      });

      return DataGridRow(cells: cells);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Container(
          alignment: cell.columnName == 'metric'
              ? Alignment.centerLeft
              : Alignment.center,
          padding: const EdgeInsets.all(10.0),
          child: Text(
            cell.value.toString(),
            style: const TextStyle(fontFamily: Constants.FONT_DEFAULT_NEW),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
    );
  }
}