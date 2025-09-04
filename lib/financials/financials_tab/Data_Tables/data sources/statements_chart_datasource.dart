
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_quarterly.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class FinancialDataSource extends DataGridSource {
  final List<FinancialStatementModel> data;
  final List<String> years;
  List<DataGridRow> rows = [];
  Map<String, bool> expandedRows = {};
  late Map<String, Map<String, Map<String, FinancialStatementModel>>> hierarchicalData;

  FinancialDataSource({
    required this.data,
    required this.years,
  }) {
    _buildRows();
  }

 void _buildRows() {
  rows.clear();
  hierarchicalData = {};

  Map<String, Map<String, FinancialStatementModel>> itemsByNameAndYear = {};

  for (var item in data) {
    itemsByNameAndYear.putIfAbsent(item.name, () => {});
    itemsByNameAndYear[item.name]![item.year] = item;

    if (!hierarchicalData.containsKey(item.name)) {
      hierarchicalData[item.name] = {};
    }
    hierarchicalData[item.name]![item.year] = {};
    _buildHierarchy(hierarchicalData, item.name, item.year, item.subItems);
  }

  for (var itemName in itemsByNameAndYear.keys) {
    List<DataGridCell> cells = [
      DataGridCell<String>(columnName: 'metric', value: itemName),
    ];

    // Check if the row has any meaningful data
    bool hasData = false;
    for (var year in years) {
      var itemForYear = itemsByNameAndYear[itemName]?[year];
      String value = itemForYear?.originalValue ?? '-';
      cells.add(
        DataGridCell<String>(
          columnName: year,
          value: value,
        ),
      );
      if (value != '-' && value.isNotEmpty && value != '0' && value != '') {
        hasData = true;
      }
    }

    // Only add the row if it has meaningful data or sub-items with data
    bool hasSubItemsWithData = _hasDataInSubItems(itemName, hierarchicalData);
    if (hasData || hasSubItemsWithData) {
      rows.add(DataGridRow(cells: cells));

      String rowId = getRowIdentifier(itemName, 0);
      if (expandedRows[rowId] == true) {
        _addSubItemsRecursively(itemName, 1);
      }
    }
  }
}

// New method that handles recursive expansion of rows
void _addSubItemsRecursively(String parentName, int indentLevel) {
  Set<String> subItemNames = {};
  for (var year in years) {
    if (hierarchicalData.containsKey(parentName) && 
        hierarchicalData[parentName]!.containsKey(year)) {
      subItemNames.addAll(hierarchicalData[parentName]![year]!.keys);
    }
  }

  for (var subItemName in subItemNames) {
    String indentedName = '${' ' * (indentLevel * 4)}$subItemName';
    List<DataGridCell> cells = [
      DataGridCell<String>(columnName: 'metric', value: indentedName),
    ];

    bool hasData = false;
    for (var year in years) {
      var subItemForYear = hierarchicalData[parentName]?[year]?[subItemName];
      String value = subItemForYear?.originalValue ?? '-';
      cells.add(
        DataGridCell<String>(
          columnName: year,
          value: value,
        ),
      );
      if (value != '-' && value.isNotEmpty && value != '0') {
        hasData = true;
      }
    }

    bool hasSubItemsWithData = _hasDataInSubItems(subItemName, hierarchicalData);
    if (hasData || hasSubItemsWithData) {
      rows.add(DataGridRow(cells: cells));
      
      // Check if this subitem is expanded
      String rowId = getRowIdentifier(subItemName, indentLevel);
      if (expandedRows[rowId] == true && hierarchicalData.containsKey(subItemName)) {
        _addSubItemsRecursively(subItemName, indentLevel + 1);
      }
    }
  }
}

bool _hasDataInSubItems(
  String parentName,
  Map<String, Map<String, Map<String, FinancialStatementModel>>> hierarchicalData,
) {
  if (!hierarchicalData.containsKey(parentName)) return false;

  for (var year in years) {
    if (!hierarchicalData[parentName]!.containsKey(year)) continue;
    
    var subItems = hierarchicalData[parentName]![year];
    if (subItems != null) {
      for (var subItem in subItems.values) {
        if (subItem.originalValue != '-' && subItem.originalValue.isNotEmpty && subItem.originalValue != '0') {
          return true;
        }
        if (_hasDataInSubItems(subItem.name, hierarchicalData)) return true;
      }
    }
  }
  return false;
}

  void _buildHierarchy(
    Map<String, Map<String, Map<String, FinancialStatementModel>>> hierarchicalData,
    String parentName,
    String year,
    List<FinancialStatementModel> subItems,
  ) {
    for (var subItem in subItems) {
      hierarchicalData[parentName]![year]![subItem.name] = subItem;
      if (!hierarchicalData.containsKey(subItem.name)) {
        hierarchicalData[subItem.name] = {};
      }
      if (!hierarchicalData[subItem.name]!.containsKey(year)) {
        hierarchicalData[subItem.name]![year] = {};
      }
      if (subItem.subItems.isNotEmpty) {
        _buildHierarchy(hierarchicalData, subItem.name, year, subItem.subItems);
      }
    }
  }

  @override
  List<DataGridRow> get dataGridRows => rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        bool isFirstCell = cell.columnName == 'metric';
        Alignment alignment = isFirstCell ? Alignment.centerLeft : Alignment.center;
        bool isNegative = false;
        if (!isFirstCell) {
          String value = cell.value.toString();
          if (value.startsWith('(') || value.contains('-')) {
            isNegative = true;
          }
        }

        if (isFirstCell) {
          String cellValue = cell.value.toString();
          String trimmedValue = cellValue.trimLeft();
          int indentLevel = getIndentLevel(cellValue);
          String rowId = getRowIdentifier(trimmedValue, indentLevel);
          bool hasChildren = hierarchicalData.containsKey(trimmedValue) &&
              hierarchicalData[trimmedValue]!.values.any((yearData) => yearData.isNotEmpty);
          bool isExpanded = expandedRows[rowId] ?? false;

          if (hasChildren) {
            return GestureDetector(
              onTap: () => toggleRowExpansion(rowId),
              child: Tooltip(
                message: trimmedValue,
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  alignment: alignment,
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cellValue,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Tooltip(
              message: trimmedValue,
              triggerMode: TooltipTriggerMode.longPress,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                alignment: alignment,
                child: Text(
                  cellValue,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }
        }

        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: alignment,
          child: Text(
            cell.value.toString(),
            style: TextStyle(
              color: isNegative ? const Color.fromARGB(255, 23, 23, 23) : null,
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

  int getIndentLevel(String cellValue) {
    int leadingSpaces = 0;
    for (int i = 0; i < cellValue.length; i++) {
      if (cellValue[i] == ' ') {
        leadingSpaces++;
      } else {
        break;
      }
    }
    return leadingSpaces ~/ 4;
  }

  String getRowIdentifier(String name, int indentLevel) {
    String trimmedName = name.trimLeft();
    return '$indentLevel:$trimmedName';
  }

  void toggleRowExpansion(String rowId) {
    expandedRows[rowId] = !(expandedRows[rowId] ?? false);
    _buildRows();
    notifyListeners();
  }
}