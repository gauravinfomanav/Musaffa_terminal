import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';

// Data model for financial expandable table
class FinancialExpandableRowData {
  final String id;
  final String name;
  final Map<String, dynamic> data; // Year/Quarter -> Value mapping
  final List<FinancialExpandableRowData>? children;
  final bool isExpandable;
  final bool isExpanded;
  final int level;
  final bool isHeader; // For ratios header rows
  final String? customTitle;
  final String? customSubtitle;

  FinancialExpandableRowData({
    required this.id,
    required this.name,
    required this.data,
    this.children,
    this.isExpandable = false,
    this.isExpanded = false,
    this.level = 0,
    this.isHeader = false,
    this.customTitle,
    this.customSubtitle,
  });

  FinancialExpandableRowData copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? data,
    List<FinancialExpandableRowData>? children,
    bool? isExpandable,
    bool? isExpanded,
    int? level,
    bool? isHeader,
    String? customTitle,
    String? customSubtitle,
  }) {
    return FinancialExpandableRowData(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
      children: children ?? this.children,
      isExpandable: isExpandable ?? this.isExpandable,
      isExpanded: isExpanded ?? this.isExpanded,
      level: level ?? this.level,
      isHeader: isHeader ?? this.isHeader,
      customTitle: customTitle ?? this.customTitle,
      customSubtitle: customSubtitle ?? this.customSubtitle,
    );
  }
}

class FinancialExpandableColumn {
  final String key;
  final String title;
  final double? width;
  final bool isNumeric;
  final TextAlign alignment;

  FinancialExpandableColumn({
    required this.key,
    required this.title,
    this.width,
    this.isNumeric = false,
    this.alignment = TextAlign.center,
  });
}

class FinancialExpandableTable extends StatefulWidget {
  const FinancialExpandableTable({
    Key? key,
    required this.columns,
    required this.data,
    this.showNameColumn = true,
    this.onRowSelect,
    this.considerPadding = true,
    this.rowHeight = 48,
    this.headerHeight = 32,
    this.expandIconSize = 16,
    this.indentSize = 20,
    this.headerBackgroundColor = const Color(0xFFEFF4FF),
  }) : super(key: key);

  final List<FinancialExpandableColumn> columns;
  final List<FinancialExpandableRowData> data;
  final bool showNameColumn;
  final Function(FinancialExpandableRowData)? onRowSelect;
  final bool considerPadding;
  final double rowHeight;
  final double headerHeight;
  final double expandIconSize;
  final double indentSize;
  final Color headerBackgroundColor;

  @override
  State<FinancialExpandableTable> createState() => _FinancialExpandableTableState();
}

class _FinancialExpandableTableState extends State<FinancialExpandableTable> {
  final ScrollController _scrollController = ScrollController();
  bool _increaseShadow = false;
  Map<String, bool> _expandedRows = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _increaseShadow = _scrollController.offset > 0.1;
      });
    });
    _initializeExpandedState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeExpandedState() {
    for (var row in widget.data) {
      if (row.isExpandable) {
        _expandedRows[row.id] = row.isExpanded;
      }
    }
  }

  void _toggleExpansion(String rowId) {
    setState(() {
      _expandedRows[rowId] = !(_expandedRows[rowId] ?? false);
    });
  }

  List<FinancialExpandableRowData> _getFlattenedRows() {
    List<FinancialExpandableRowData> flattened = [];
    
    void addRowAndChildren(FinancialExpandableRowData row) {
      flattened.add(row);
      
      if (row.isExpandable && 
          row.children != null && 
          (_expandedRows[row.id] ?? false)) {
        for (var child in row.children!) {
          addRowAndChildren(child);
        }
      }
    }
    
    for (var row in widget.data) {
      addRowAndChildren(row);
    }
    
    return flattened;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.considerPadding ? 16 : 0,
      ),
      child: Row(
        children: [
          if (widget.showNameColumn) _buildNameColumn(),
          Expanded(
            child: _buildDataColumns(),
          ),
        ],
      ),
    );
  }

  Widget _buildNameColumn() {
    final flattenedRows = _getFlattenedRows();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Match main background
        boxShadow: [
          BoxShadow(
            color: _increaseShadow
                ? Colors.black.withOpacity(0.03)
                : Colors.transparent,
            blurRadius: _increaseShadow ? 4 : 0,
            spreadRadius: 0,
            blurStyle: BlurStyle.inner,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: DataTable(
          showCheckboxColumn: false,
          headingRowHeight: widget.headerHeight,
          horizontalMargin: 0,
          dataRowMinHeight: widget.rowHeight,
          dataRowMaxHeight: widget.rowHeight,
        columns: [
            DataColumn(
              label: Expanded(
                child: Text(
                  "Name",
                  style: DashboardTextStyles.columnHeader,
                ),
              ),
            ),
          ],
          rows: flattenedRows.map((row) {
            return DataRow(
              cells: [
                DataCell(
                  Padding(
                    padding: EdgeInsets.only(
                      right: 30.0,
                      left: row.level * widget.indentSize,
                    ),
                    child: _buildNameCell(row),
                  ),
                  onTap: row.isExpandable ? null : () => widget.onRowSelect?.call(row),
                ),
              ],
            );
          }).toList(),
          dividerThickness: 0,
          border: TableBorder(
            bottom: BorderSide.none,
            verticalInside: BorderSide.none,
            horizontalInside: BorderSide(
              color: Theme.of(context).primaryColorLight,
              width: 0.8,
            ),
          ),
        ),
    );
  }

  Widget _buildNameCell(FinancialExpandableRowData row) {
    return GestureDetector(
      onTap: row.isExpandable ? () => _toggleExpansion(row.id) : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4),
        decoration: row.isExpandable ? BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.transparent,
        ) : null,
        child: Row(
          children: [
            Expanded(
              child: _buildTextCell(row),
            ),
            if (row.isExpandable) ...[
              const SizedBox(width: 8),
              Text(
                (_expandedRows[row.id] ?? false) ? '−' : '+',
                style: TextStyle(
                  fontSize: widget.expandIconSize,
                  fontWeight: FontWeight.w600,
                  color: DashboardTextStyles.secondaryTextColor,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextCell(FinancialExpandableRowData row) {
    String title = row.customTitle ?? row.name;
    String? subtitle = row.customSubtitle;
    
    TextStyle titleStyle = row.isHeader 
        ? DashboardTextStyles.columnHeader.copyWith(fontWeight: FontWeight.bold)
        : DashboardTextStyles.stockName;
    
    TextStyle subtitleStyle = DashboardTextStyles.tickerSymbol;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (subtitle != null && subtitle.isNotEmpty)
          Text(
            subtitle,
            style: subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildDataColumns() {
    final flattenedRows = _getFlattenedRows();
    
    return Scrollbar(
      controller: _scrollController,
      thickness: 4,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: widget.headerHeight,
            horizontalMargin: 0,
            dataRowMinHeight: widget.rowHeight,
            dataRowMaxHeight: widget.rowHeight,
            columns: widget.columns.map((column) {
              return DataColumn(
                label: Expanded(
                  child: Text(
                    column.title,
                    style: DashboardTextStyles.columnHeader,
                    textAlign: column.alignment,
                  ),
                ),
              );
            }).toList(),
            rows: flattenedRows.map((row) {
              return DataRow(
                onSelectChanged: row.isExpandable ? null : (_) => widget.onRowSelect?.call(row),
                cells: widget.columns.map((column) {
                  return DataCell(
                    _buildCellContent(row, column),
                  );
                }).toList(),
              );
            }).toList(),
            dividerThickness: 0,
            border: TableBorder(
              bottom: BorderSide.none,
              verticalInside: BorderSide.none,
              horizontalInside: BorderSide(
                color: Theme.of(context).primaryColorLight,
                width: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(FinancialExpandableRowData row, FinancialExpandableColumn column) {
    final value = row.data[column.key];
    
    if (value == null) {
      return Text(
        "--",
        style: DashboardTextStyles.dataCell,
        textAlign: column.alignment,
      );
    }

    if (value is num) {
      String formattedValue = value.toString();
      if (column.isNumeric) {
        formattedValue = value.abs().toStringAsFixed(2);
      }
      
      return Text(
        formattedValue,
        style: DashboardTextStyles.dataCell,
        textAlign: column.alignment,
      );
    }

    if (value is String) {
      // Use different text style for metric column (first column)
      TextStyle textStyle = column.key == 'metric' 
          ? DashboardTextStyles.stockName 
          : DashboardTextStyles.dataCell;
      
      // Check if it's a change value (starts with + or -)
      Color textColor = DashboardTextStyles.primaryTextColor;
      if (value.startsWith('+')) {
        textColor = Colors.green;
      } else if (value.startsWith('-')) {
        textColor = Colors.red;
      }
      
      return Text(
        value,
        style: textStyle.copyWith(color: textColor),
        textAlign: column.alignment,
      );
    }

    return Text(
      "--",
      style: DashboardTextStyles.dataCell,
      textAlign: column.alignment,
    );
  }
}

// Helper class to transform different data structures to FinancialExpandableRowData
class FinancialDataTransformer {
  
  // Transform Financial Statements data (Annual/Quarterly)
  static List<FinancialExpandableRowData> transformFinancialStatements(
    List<dynamic> financialData,
    List<String> periods, // years or quarters
  ) {
    // Group by name to create one row per item with all periods
    Map<String, Map<String, String>> groupedData = {};
    Map<String, List<dynamic>> childrenMap = {};
    
    for (var item in financialData) {
      String name = item.name;
      String period = item.year; // or quarter
      String value = item.originalValue;
      
      groupedData.putIfAbsent(name, () => {});
      groupedData[name]![period] = value;
      
      if (item.subItems != null && item.subItems.isNotEmpty) {
        childrenMap[name] = item.subItems;
      }
    }
    
    return groupedData.entries.map((entry) {
      String name = entry.key;
      Map<String, String> periodData = entry.value;
      
      // Convert to dynamic data map
      Map<String, dynamic> data = {};
      for (var period in periods) {
        data[period] = periodData[period] ?? '--';
      }
      
      return FinancialExpandableRowData(
        id: name,
        name: name,
        data: {
          'metric': name,
          ...data,
        },
        children: childrenMap.containsKey(name) 
            ? _transformSubItems(childrenMap[name]!, periods, 1)
            : null,
        isExpandable: childrenMap.containsKey(name),
        level: 0,
      );
    }).toList();
  }
  
  static List<FinancialExpandableRowData> _transformSubItems(
    List<dynamic> subItems,
    List<String> periods,
    int level,
  ) {
    Map<String, Map<String, String>> groupedData = {};
    Map<String, List<dynamic>> childrenMap = {};
    
    for (var item in subItems) {
      String name = item.name;
      String period = item.year;
      String value = item.originalValue;
      
      groupedData.putIfAbsent(name, () => {});
      groupedData[name]![period] = value;
      
      if (item.subItems != null && item.subItems.isNotEmpty) {
        childrenMap[name] = item.subItems;
      }
    }
    
    return groupedData.entries.map((entry) {
      String name = entry.key;
      Map<String, String> periodData = entry.value;
      
      Map<String, dynamic> data = {};
      for (var period in periods) {
        data[period] = periodData[period] ?? '--';
      }
      
      return FinancialExpandableRowData(
        id: name,
        name: name,
        data: {
          'metric': name,
          ...data,
        },
        children: childrenMap.containsKey(name) 
            ? _transformSubItems(childrenMap[name]!, periods, level + 1)
            : null,
        isExpandable: childrenMap.containsKey(name),
        level: level,
      );
    }).toList();
  }
  
  // Transform Ratios data (Annual/Quarterly)
  static List<FinancialExpandableRowData> transformRatios(
    List<dynamic> ratiosData,
    List<String> periods,
  ) {
    return ratiosData.map((item) {
      Map<String, dynamic> data = {};
      for (var period in periods) {
        data[period] = item.values[period]?.toStringAsFixed(2) ?? '--';
      }
      
      return FinancialExpandableRowData(
        id: item.metric,
        name: item.metric,
        data: {
          'metric': item.metric,
          ...data,
        },
        isHeader: item.metric.startsWith('**') && item.metric.endsWith('**'),
        level: 0,
      );
    }).toList();
  }
  
  // Transform Per Share data
  static List<FinancialExpandableRowData> transformPerShareData(
    Map<String, double?> sourceData,
    List<String> periods,
    String metricName,
  ) {
    Map<String, dynamic> data = {};
    for (var period in periods) {
      double? value = sourceData[period];
      data[period] = value?.toStringAsFixed(2) ?? '--';
    }
    
    return [
      FinancialExpandableRowData(
        id: metricName,
        name: metricName,
        data: data,
        level: 0,
      ),
    ];
  }
}
