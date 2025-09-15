import 'dart:math';
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
    this.showYoYGrowth = false,
    this.showThreeYearAvg = false,
    this.showTwoYearCAGR = false,
    this.showFiveYearCAGR = false,
    this.showStandardDeviation = false,
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
  final bool showYoYGrowth;
  final bool showThreeYearAvg;
  final bool showTwoYearCAGR;
  final bool showFiveYearCAGR;
  final bool showStandardDeviation;

  @override
  State<FinancialExpandableTable> createState() => _FinancialExpandableTableState();
}

class _FinancialExpandableTableState extends State<FinancialExpandableTable> {
  final ScrollController _scrollController = ScrollController();
  bool _increaseShadow = false;
  Map<String, bool> _expandedRows = {};
  Set<String> _splashRowIds = {}; // Track which rows should show splash effect

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

  // Recursive function to find a row by ID in the data tree
  FinancialExpandableRowData? _findRowById(String rowId, List<FinancialExpandableRowData> rows) {
    for (var row in rows) {
      if (row.id == rowId) {
        return row;
      }
      if (row.children != null) {
        var found = _findRowById(rowId, row.children!);
        if (found != null) return found;
      }
    }
    return null;
  }

  void _toggleExpansion(String rowId) {
    setState(() {
      bool wasExpanded = _expandedRows[rowId] ?? false;
      _expandedRows[rowId] = !wasExpanded;
      
      // If row is being expanded, show splash effect on all child rows
      if (!wasExpanded) {
        // Find the parent row recursively
        FinancialExpandableRowData? parentRow = _findRowById(rowId, widget.data);
        
        // Set splash effect on all child rows
        if (parentRow?.children?.isNotEmpty == true) {
          _splashRowIds.clear();
          for (var child in parentRow!.children!) {
            _splashRowIds.add(child.id);
          }
          // Remove splash effect after 1 second
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _splashRowIds.clear();
              });
            }
          });
        }
      }
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

  List<FinancialExpandableColumn> _buildAllColumns() {
    List<FinancialExpandableColumn> allColumns = List.from(widget.columns);
    
    // Add 3-Year Average column first if enabled
    if (widget.showThreeYearAvg) {
      allColumns.add(FinancialExpandableColumn(
        key: 'three_year_avg',
        title: '3Y Avg',
        isNumeric: false,
        alignment: TextAlign.center,
      ));
    }
    
    // Add YoY Growth column second if enabled
    if (widget.showYoYGrowth) {
      allColumns.add(FinancialExpandableColumn(
        key: 'yoy_growth',
        title: 'YoY Growth',
        isNumeric: false,
        alignment: TextAlign.center,
      ));
    }
    
    // Add 2-Year CAGR column if enabled
    if (widget.showTwoYearCAGR) {
      allColumns.add(FinancialExpandableColumn(
        key: 'two_year_cagr',
        title: '2Y CAGR',
        isNumeric: false,
        alignment: TextAlign.center,
      ));
    }
    
    // Add 5-Year CAGR column if enabled
    if (widget.showFiveYearCAGR) {
      allColumns.add(FinancialExpandableColumn(
        key: 'five_year_cagr',
        title: '5Y CAGR',
        isNumeric: false,
        alignment: TextAlign.center,
      ));
    }
    
    // Add Standard Deviation column if enabled (last column)
    if (widget.showStandardDeviation) {
      allColumns.add(FinancialExpandableColumn(
        key: 'standard_deviation',
        title: 'Volatility',
        isNumeric: false,
        alignment: TextAlign.center,
      ));
    }
    
    return allColumns;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.considerPadding ? 16 : 0,
      ),
      child: Row(
        children: [
          if (widget.showNameColumn) 
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.10, // 10% of screen width - consistent across all tables
              child: _buildNameColumn(),
            ),
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
                      left: 0, // No spacing for any rows
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
          Tooltip(
            message: title,
            child: Text(
              title,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (subtitle != null && subtitle.isNotEmpty)
          Tooltip(
            message: subtitle,
            child: Text(
              subtitle,
              style: subtitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
            columns: _buildAllColumns().map((column) {
              // If showNameColumn is false and this is the first column (metric), give it fixed width
              if (!widget.showNameColumn && column.key == 'metric') {
                return DataColumn(
                  label: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.16, // 10% of screen width
                    child: Text(
                      column.title,
                      style: DashboardTextStyles.columnHeader,
                      textAlign: column.alignment,
                    ),
                  ),
                );
              }
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
                color: _splashRowIds.contains(row.id) 
                    ? WidgetStateProperty.all(const Color.fromARGB(255, 105, 177, 236).withOpacity(0.1))
                    : null,
                onSelectChanged: row.isExpandable ? null : (_) => widget.onRowSelect?.call(row),
                cells: _buildAllColumns().map((column) {
                  // If showNameColumn is false and this is the first column (metric column), add expand/collapse functionality
                  if (!widget.showNameColumn && column.key == 'metric') {
                    return DataCell(
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.16, // 10% of screen width
                        child: _buildExpandableCellContent(row, column),
                      ),
                    );
                  }
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

  Widget _buildExpandableCellContent(FinancialExpandableRowData row, FinancialExpandableColumn column) {
    final value = row.data[column.key];
    
    if (value == null) {
      return Text(
        "--",
        style: DashboardTextStyles.dataCell.copyWith(color: Colors.grey),
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
      // For metric column with expandable functionality
      if (column.key == 'metric') {
        return GestureDetector(
          onTap: row.isExpandable ? () => _toggleExpansion(row.id) : null,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // No spacing for any rows
                Expanded(
                  child: Tooltip(
                    message: value,
                    child: Text(
                      value,
                      style: DashboardTextStyles.stockName,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
      
      // Check if it's a change value (starts with + or -)
      Color textColor = DashboardTextStyles.primaryTextColor;
      if (value.startsWith('+')) {
        textColor = Colors.green;
      } else if (value.startsWith('-')) {
        textColor = Colors.red;
      }
      
      return Text(
        value,
        style: DashboardTextStyles.dataCell.copyWith(color: textColor),
        textAlign: column.alignment,
      );
    }

    return Text(
      "--",
      style: DashboardTextStyles.dataCell.copyWith(color: Colors.grey),
      textAlign: column.alignment,
    );
  }

  Widget _buildCellContent(FinancialExpandableRowData row, FinancialExpandableColumn column) {
    final value = row.data[column.key];
    
    if (value == null) {
      return Text(
        "--",
        style: DashboardTextStyles.dataCell.copyWith(color: Colors.grey),
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
      style: DashboardTextStyles.dataCell.copyWith(color: Colors.grey),
      textAlign: column.alignment,
    );
  }
}

// Helper class to transform different data structures to FinancialExpandableRowData
class FinancialDataTransformer {
  
  // Transform Financial Statements data (Annual/Quarterly)
  static List<FinancialExpandableRowData> transformFinancialStatements(
    dynamic financialData, // Can be List<dynamic> or RxList
    List<String> periods, // years or quarters
  ) {
    // Convert to List if it's an RxList
    List<dynamic> dataList = financialData is List ? financialData : financialData.toList();
    // Group by name to create one row per item with all periods
    Map<String, Map<String, String>> groupedData = {};
    Map<String, List<dynamic>> childrenMap = {};
    
    for (var item in dataList) {
      String name = item.name;
      String period = item.year; // or quarter
      String value = item.originalValue;
      
      groupedData.putIfAbsent(name, () => {});
      groupedData[name]![period] = value;
      
      // Collect subItems from all occurrences of this item
      if (item.subItems != null && item.subItems.isNotEmpty) {
        if (!childrenMap.containsKey(name)) {
          childrenMap[name] = [];
        }
        // Add subItems from this occurrence (they may have data for different periods)
        childrenMap[name]!.addAll(item.subItems);
        
      }
    }
    
    
    List<FinancialExpandableRowData> result = groupedData.entries.map((entry) {
      String name = entry.key;
      Map<String, String> periodData = entry.value;
      
      // Convert to dynamic data map
      Map<String, dynamic> data = {};
      for (var period in periods) {
        data[period] = periodData[period] ?? '-';
      }
      
      // Calculate YoY Growth
      data['yoy_growth'] = _calculateYoYGrowth(periodData, periods);
      
      // Calculate 3-Year Average
      data['three_year_avg'] = _calculateThreeYearAverage(periodData, periods);
      
      // Calculate 2-Year CAGR
      data['two_year_cagr'] = _calculateTwoYearCAGR(periodData, periods);
      
      // Calculate 5-Year CAGR
      data['five_year_cagr'] = _calculateFiveYearCAGR(periodData, periods);
      
      // Calculate Standard Deviation of Growth Rates
      data['standard_deviation'] = _calculateStandardDeviation(periodData, periods);
      
      bool hasChildren = childrenMap.containsKey(name);
      List<FinancialExpandableRowData>? children = hasChildren 
          ? _transformSubItems(childrenMap[name]!, periods, 1)
          : null;
      
      return FinancialExpandableRowData(
        id: name,
        name: name,
        data: {
          'metric': name,
          ...data,
        },
        children: children,
        isExpandable: hasChildren,
        level: 0,
      );
    }).toList();
    
    return result;
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
        if (!childrenMap.containsKey(name)) {
          childrenMap[name] = [];
        }
        // Add subItems from this occurrence (they may have data for different periods)
        childrenMap[name]!.addAll(item.subItems);
      }
    }
    
    
    return groupedData.entries.map((entry) {
      String name = entry.key;
      Map<String, String> periodData = entry.value;
      
      Map<String, dynamic> data = {};
      for (var period in periods) {
        data[period] = periodData[period] ?? '-';
      }
      
      // Calculate YoY Growth for sub-items
      data['yoy_growth'] = _calculateYoYGrowth(periodData, periods);
      
      // Calculate 3-Year Average for sub-items
      data['three_year_avg'] = _calculateThreeYearAverage(periodData, periods);
      
      // Calculate 2-Year CAGR for sub-items
      data['two_year_cagr'] = _calculateTwoYearCAGR(periodData, periods);
      
      // Calculate 5-Year CAGR for sub-items
      data['five_year_cagr'] = _calculateFiveYearCAGR(periodData, periods);
      
      // Calculate Standard Deviation of Growth Rates for sub-items
      data['standard_deviation'] = _calculateStandardDeviation(periodData, periods);
      
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
  
  // Calculate Year-on-Year Growth
  static String _calculateYoYGrowth(Map<String, String> periodData, List<String> periods) {
    if (periods.length < 2) return '-';
    
    String currentYear = periods.last;
    String previousYear = periods[periods.length - 2];
    
    String? currentValueStr = periodData[currentYear];
    String? previousValueStr = periodData[previousYear];
    
    if (currentValueStr == null || previousValueStr == null || 
        currentValueStr == '-' || previousValueStr == '-') {
      return '-';
    }
    
    double? current = _parseFinancialValue(currentValueStr);
    double? previous = _parseFinancialValue(previousValueStr);
    
    if (current == null || previous == null || previous == 0) {
      return '-';
    }
    
    double growth = ((current - previous) / previous) * 100;
    
    // Format with + or - sign
    if (growth > 0) {
      return '+${growth.toStringAsFixed(1)}%';
    } else if (growth < 0) {
      return '${growth.toStringAsFixed(1)}%';
    } else {
      return '0.0%';
    }
  }
  
  // Calculate 3-Year Average
  static String _calculateThreeYearAverage(Map<String, String> periodData, List<String> periods) {
    if (periods.length < 3) return '-';
    
    // Get the last 3 years
    List<String> lastThreeYears = periods.skip(periods.length - 3).toList();
    List<double> values = [];
    
    for (String year in lastThreeYears) {
      String? valueStr = periodData[year];
      if (valueStr != null && valueStr != '-') {
        double? value = _parseFinancialValue(valueStr);
        if (value != null) {
          values.add(value);
        }
      }
    }
    
    if (values.isEmpty) return '-';
    
    double average = values.reduce((a, b) => a + b) / values.length;
    
    // Format the average based on the magnitude
    if (average >= 1000000000000) {
      // Trillions
      return '${(average / 1000000000000).toStringAsFixed(1)}T';
    } else if (average >= 1000000000) {
      // Billions
      return '${(average / 1000000000).toStringAsFixed(1)}B';
    } else if (average >= 1000000) {
      // Millions
      return '${(average / 1000000).toStringAsFixed(1)}M';
    } else if (average >= 1000) {
      // Thousands
      return '${(average / 1000).toStringAsFixed(1)}K';
    } else {
      // Regular numbers
      return average.toStringAsFixed(2);
    }
  }
  
  // Calculate 2-Year CAGR (Compound Annual Growth Rate)
  static String _calculateTwoYearCAGR(Map<String, String> periodData, List<String> periods) {
    if (periods.length < 2) return '-';
    
    // Get the last 2 years
    List<String> lastTwoYears = periods.skip(periods.length - 2).toList();
    String oldestYear = lastTwoYears.first;
    String latestYear = lastTwoYears.last;
    
    String? oldestValueStr = periodData[oldestYear];
    String? latestValueStr = periodData[latestYear];
    
    if (oldestValueStr == null || latestValueStr == null || 
        oldestValueStr == '-' || latestValueStr == '-') {
      return '-';
    }
    
    double? oldestValue = _parseFinancialValue(oldestValueStr);
    double? latestValue = _parseFinancialValue(latestValueStr);
    
    if (oldestValue == null || latestValue == null || oldestValue <= 0) {
      return '-';
    }
    
    // Calculate CAGR: (Latest Year / Oldest Year)^(1/2) - 1
    double cagr = pow(latestValue / oldestValue, 1.0 / 2.0) - 1.0;
    
    // Format as percentage with + or - sign
    if (cagr > 0) {
      return '+${(cagr * 100).toStringAsFixed(1)}%';
    } else if (cagr < 0) {
      return '${(cagr * 100).toStringAsFixed(1)}%';
    } else {
      return '0.0%';
    }
  }
  
  // Calculate Standard Deviation of Growth Rates
  static String _calculateStandardDeviation(Map<String, String> periodData, List<String> periods) {
    if (periods.length < 2) return '-';
    
    List<double> growthRates = [];
    
    // Calculate year-over-year growth rates
    for (int i = 1; i < periods.length; i++) {
      String currentPeriod = periods[i];
      String previousPeriod = periods[i - 1];
      
      String? currentValueStr = periodData[currentPeriod];
      String? previousValueStr = periodData[previousPeriod];
      
      if (currentValueStr == null || previousValueStr == null || 
          currentValueStr == '-' || previousValueStr == '-') {
        continue;
      }
      
      double? currentValue = _parseFinancialValue(currentValueStr);
      double? previousValue = _parseFinancialValue(previousValueStr);
      
      if (currentValue == null || previousValue == null || previousValue == 0) {
        continue;
      }
      
      // Calculate growth rate: (Current - Previous) / Previous
      double growthRate = (currentValue - previousValue) / previousValue;
      growthRates.add(growthRate);
    }
    
    if (growthRates.length < 2) return '-';
    
    // Calculate mean
    double mean = growthRates.reduce((a, b) => a + b) / growthRates.length;
    
    // Calculate variance
    double variance = growthRates
        .map((rate) => pow(rate - mean, 2))
        .reduce((a, b) => a + b) / growthRates.length;
    
    // Calculate standard deviation
    double standardDeviation = sqrt(variance);
    
    // Format as percentage
    return '${(standardDeviation * 100).toStringAsFixed(1)}%';
  }
  
  // Calculate 5-Year CAGR (Compound Annual Growth Rate)
  static String _calculateFiveYearCAGR(Map<String, String> periodData, List<String> periods) {
    if (periods.length < 5) return '-';
    
    // Get the first and last 5 years
    List<String> lastFiveYears = periods.skip(periods.length - 5).toList();
    String oldestYear = lastFiveYears.first;
    String latestYear = lastFiveYears.last;
    
    String? oldestValueStr = periodData[oldestYear];
    String? latestValueStr = periodData[latestYear];
    
    if (oldestValueStr == null || latestValueStr == null || 
        oldestValueStr == '-' || latestValueStr == '-') {
      return '-';
    }
    
    double? oldestValue = _parseFinancialValue(oldestValueStr);
    double? latestValue = _parseFinancialValue(latestValueStr);
    
    if (oldestValue == null || latestValue == null || oldestValue <= 0) {
      return '-';
    }
    
    // Calculate CAGR: (Latest Year / Oldest Year)^(1/5) - 1
    double cagr = pow(latestValue / oldestValue, 1.0 / 5.0) - 1.0;
    
    // Format as percentage with + or - sign
    if (cagr > 0) {
      return '+${(cagr * 100).toStringAsFixed(1)}%';
    } else if (cagr < 0) {
      return '${(cagr * 100).toStringAsFixed(1)}%';
    } else {
      return '0.0%';
    }
  }
  
  // Parse financial values like "1.2B", "3.5T", "500M", "1.5K"
  static double? _parseFinancialValue(String value) {
    if (value == '--' || value.isEmpty) return null;
    
    // Remove any whitespace and convert to uppercase
    String cleanValue = value.trim().toUpperCase();
    
    // Try to parse as regular number first
    double? number = double.tryParse(cleanValue);
    if (number != null) return number;
    
    // Handle suffixes: B (billion), T (trillion), M (million), K (thousand)
    if (cleanValue.endsWith('B')) {
      String numStr = cleanValue.substring(0, cleanValue.length - 1);
      double? num = double.tryParse(numStr);
      return num != null ? num * 1000000000 : null;
    } else if (cleanValue.endsWith('T')) {
      String numStr = cleanValue.substring(0, cleanValue.length - 1);
      double? num = double.tryParse(numStr);
      return num != null ? num * 1000000000000 : null;
    } else if (cleanValue.endsWith('M')) {
      String numStr = cleanValue.substring(0, cleanValue.length - 1);
      double? num = double.tryParse(numStr);
      return num != null ? num * 1000000 : null;
    } else if (cleanValue.endsWith('K')) {
      String numStr = cleanValue.substring(0, cleanValue.length - 1);
      double? num = double.tryParse(numStr);
      return num != null ? num * 1000 : null;
    }
    
    // If no suffix, try parsing as regular number
    return double.tryParse(cleanValue);
  }
}
