
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/ratios_quarterly_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class QuarterlyRatiosDataSource extends DataGridSource {
  final List<quarterlyRatioDataModel> tableData;
  final List<String> quarters;
  
  QuarterlyRatiosDataSource({required this.tableData, required this.quarters});
  
  @override
  List<DataGridRow> get rows {
    return tableData.map((model) {
      List<DataGridCell> cells = [
        DataGridCell<String>(
          columnName: 'metric',
          value: model.metric,
        ),
      ];
      
      // For header rows, add empty cells for all quarters
      if (model.metric.startsWith('**') && model.metric.endsWith('**')) {
        for (var quarter in quarters) {
          cells.add(DataGridCell<String>(
            columnName: quarter,
            value: '',
          ));
        }
      } else {
        // Regular data cells
        for (var quarter in quarters) {
          // Check if this quarter exists in the values map
          String formattedValue = '-';
          if (model.values.containsKey(quarter) && model.values[quarter] != null) {
            formattedValue = model.values[quarter]!.toStringAsFixed(2);
          }
          
          cells.add(DataGridCell<String>(
            columnName: quarter,
            value: formattedValue,
          ));
        }
      }
      
      return DataGridRow(cells: cells);
    }).toList();
  }
  
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    // Check if this is a header row
    bool isHeader = row.getCells()[0].value.toString().startsWith('**');
    
    return DataGridRowAdapter(
      color: isHeader ? Color(0xFFEEEEEE) : Colors.white, // Gray background for headers
      cells: [
        Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            row.getCells()[0].value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        ...row.getCells().skip(1).map((cell) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: Text(
              cell.value.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }),
      ],
    );
  }
}