
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_quarterly.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class FinancialQuarterlyDataSource extends DataGridSource {
  final List<FinancialStatementModel> data;
  final List<String> quarters;
  List<DataGridRow> rows = [];
  Map<String, bool> expandedRows = {};

  FinancialQuarterlyDataSource({
    required this.data,
    required this.quarters,
  }) {
    _buildRows();
  }

  void _buildRows() {
    rows.clear();
    
    // Group data by name to collect all quarters for each item
    Map<String, Map<String, FinancialStatementModel>> itemsByNameAndQuarter = {};
    
    // Create a structure that maintains parent-child relationships
    Map<String, Map<String, Map<String, FinancialStatementModel>>> hierarchicalData = {};
    
    for (var item in data) {
      // Add to the flat map (used for top-level items)
      itemsByNameAndQuarter.putIfAbsent(item.name, () => {});
      itemsByNameAndQuarter[item.name]![item.year] = item;
      
      // Build hierarchical structure for all quarters
      if (!hierarchicalData.containsKey(item.name)) {
        hierarchicalData[item.name] = {};
      }
      hierarchicalData[item.name]![item.year] = {};
      
      // Process subitems recursively to build complete hierarchy
      _buildHierarchy(hierarchicalData, item.name, item.year, item.subItems);
    }
    
    // Process each unique item
    for (var itemName in itemsByNameAndQuarter.keys) {
      // Check if this row has any valid data
      bool hasData = false;
      for (var quarter in quarters) {
        var itemForQuarter = itemsByNameAndQuarter[itemName]?[quarter];
        if (itemForQuarter?.originalValue != null && 
            itemForQuarter?.originalValue != '-' && 
            itemForQuarter?.originalValue != '') {
          hasData = true;
          break;
        }
      }
      
      // Skip this row if it has no data
      if (!hasData) continue;
      
      // Create a list of cells for this row
      List<DataGridCell> cells = [
        DataGridCell<String>(columnName: 'metric', value: itemName),
      ];
      
      // Add cells for each quarter
      for (var quarter in quarters) {
        var itemForQuarter = itemsByNameAndQuarter[itemName]?[quarter];
        cells.add(
          DataGridCell<String>(
            columnName: quarter,
            value: itemForQuarter?.originalValue ?? '-',
          ),
        );
      }
      
      // Add the row
      rows.add(DataGridRow(cells: cells));
      
      // Process sub-items if this row is expanded
      String rowId = getRowIdentifier(itemName, 0);
      if (expandedRows[rowId] == true) {
        // Get all subitems for all quarters for this parent
        if (hierarchicalData.containsKey(itemName)) {
          _addSubItemsFromHierarchy(hierarchicalData, itemName, 1);
        }
      }
    }
  }

  // Build the hierarchical data structure for all quarters
  void _buildHierarchy(
    Map<String, Map<String, Map<String, FinancialStatementModel>>> hierarchicalData,
    String parentName,
    String quarter,
    List<FinancialStatementModel> subItems,
  ) {
    for (var subItem in subItems) {
      hierarchicalData[parentName]![quarter]![subItem.name] = subItem;
      if (!hierarchicalData.containsKey(subItem.name)) {
        hierarchicalData[subItem.name] = {};
      }
      if (!hierarchicalData[subItem.name]!.containsKey(quarter)) {
        hierarchicalData[subItem.name]![quarter] = {};
      }
      if (subItem.subItems.isNotEmpty) {
        _buildHierarchy(hierarchicalData, subItem.name, quarter, subItem.subItems);
      }
    }
  }

  // Helper function to check if a value represents "no data"
  bool _hasNoData(String? value) {
    return value == null || value == '-' || value == '';
  }

  // Add subitem rows using the hierarchical data structure
  void _addSubItemsFromHierarchy(
    Map<String, Map<String, Map<String, FinancialStatementModel>>> hierarchicalData,
    String parentName,
    int indentLevel,
  ) {
    Set<String> subItemNames = {};
    for (var quarter in quarters) {
      if (hierarchicalData[parentName]!.containsKey(quarter)) {
        subItemNames.addAll(hierarchicalData[parentName]![quarter]!.keys);
      }
    }
    
    for (var subItemName in subItemNames) {
      // Check if this subitem has any valid data across quarters
      bool hasData = false;
      for (var quarter in quarters) {
        var subItemForQuarter = hierarchicalData[parentName]?[quarter]?[subItemName];
        if (!_hasNoData(subItemForQuarter?.originalValue)) {
          hasData = true;
          break;
        }
      }
      
      // Skip this row if it has no data
      if (!hasData) continue;
      
      String indentedName = '${' ' * (indentLevel * 4)}$subItemName';
      List<DataGridCell> cells = [
        DataGridCell<String>(columnName: 'metric', value: indentedName),
      ];
      for (var quarter in quarters) {
        var subItemForQuarter = hierarchicalData[parentName]?[quarter]?[subItemName];
        cells.add(
          DataGridCell<String>(
            columnName: quarter,
            value: subItemForQuarter?.originalValue ?? '-',
          ),
        );
      }
      rows.add(DataGridRow(cells: cells));
      
      String rowId = getRowIdentifier(subItemName, indentLevel);
      if (expandedRows[rowId] == true && hierarchicalData.containsKey(subItemName)) {
        _addSubItemsFromHierarchy(hierarchicalData, subItemName, indentLevel + 1);
      }
    }
  }

  @override
  List<DataGridRow> get dataGridRows => rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    // Rebuild hierarchicalData locally for this method to avoid class-level changes
    Map<String, Map<String, Map<String, FinancialStatementModel>>> hierarchicalData = {};
    for (var item in data) {
      if (!hierarchicalData.containsKey(item.name)) {
        hierarchicalData[item.name] = {};
      }
      hierarchicalData[item.name]![item.year] = {};
      _buildHierarchy(hierarchicalData, item.name, item.year, item.subItems);
    }

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
              hierarchicalData[trimmedValue]!.values.any((quarterData) => quarterData.isNotEmpty);
          bool isExpanded = expandedRows[rowId] ?? false;

          if (hasChildren) {
            return Tooltip(
              message: trimmedValue, // Show full text in tooltip
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
            );
          } else {
            // For cells without children, still add tooltip
            return Tooltip(
              message: trimmedValue, // Show full text in tooltip
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
              color: isNegative ? const Color.fromARGB(255, 36, 36, 36) : null,
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

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}