import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';


class ExpandableTableRowData {
  final String id;
  final String name;
  final String? symbol;
  final String? logo;
  final Map<String, dynamic> data;
  final List<ExpandableTableRowData>? children; 
  final bool isExpandable;
  final bool isExpanded;
  final int level; 
  final bool showAsId; 
  final String? customTitle; 
  final String? customSubtitle; 

  ExpandableTableRowData({
    required this.id,
    required this.name,
    this.symbol,
    this.logo,
    required this.data,
    this.children,
    this.isExpandable = false,
    this.isExpanded = false,
    this.level = 0,
    this.showAsId = false,
    this.customTitle,
    this.customSubtitle,
  });

  ExpandableTableRowData copyWith({
    String? id,
    String? name,
    String? symbol,
    String? logo,
    Map<String, dynamic>? data,
    List<ExpandableTableRowData>? children,
    bool? isExpandable,
    bool? isExpanded,
    int? level,
    bool? showAsId,
    String? customTitle,
    String? customSubtitle,
  }) {
    return ExpandableTableRowData(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      logo: logo ?? this.logo,
      data: data ?? this.data,
      children: children ?? this.children,
      isExpandable: isExpandable ?? this.isExpandable,
      isExpanded: isExpanded ?? this.isExpanded,
      level: level ?? this.level,
      showAsId: showAsId ?? this.showAsId,
      customTitle: customTitle ?? this.customTitle,
      customSubtitle: customSubtitle ?? this.customSubtitle,
    );
  }
}


class ExpandableTableColumn {
  final String key;
  final String title;
  final double? width;
  final bool isNumeric;
  final TextAlign alignment;

  ExpandableTableColumn({
    required this.key,
    required this.title,
    this.width,
    this.isNumeric = false,
    this.alignment = TextAlign.center,
  });
}

class ExpandableDynamicTable extends StatefulWidget {
  const ExpandableDynamicTable({
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
  }) : super(key: key);

  final List<ExpandableTableColumn> columns;
  final List<ExpandableTableRowData> data;
  final bool showNameColumn;
  final Function(ExpandableTableRowData)? onRowSelect;
  final bool considerPadding;
  final double rowHeight;
  final double headerHeight;
  final double expandIconSize;
  final double indentSize;

  @override
  State<ExpandableDynamicTable> createState() => _ExpandableDynamicTableState();
}

class _ExpandableDynamicTableState extends State<ExpandableDynamicTable> {
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

  List<ExpandableTableRowData> _getFlattenedRows() {
    List<ExpandableTableRowData> flattened = [];
    
    void addRowAndChildren(ExpandableTableRowData row) {
      // Only add row if it has at least one non-empty value
      if (_hasAnyValue(row)) {
        flattened.add(row);
      }
      
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

  // Check if a row has any non-empty values
  bool _hasAnyValue(ExpandableTableRowData row) {
    for (dynamic value in row.data.values) {
      if (value != null && value != '--' && value != '-' && value != '') {
        return true;
      }
    }
    return false;
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dataTableTheme: DataTableThemeData(
            dataRowColor: WidgetStateProperty.all(Theme.of(context).scaffoldBackgroundColor),
            headingRowColor: WidgetStateProperty.all(Theme.of(context).scaffoldBackgroundColor),
          ),
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
      ),
    );
  }

  Widget _buildNameCell(ExpandableTableRowData row) {
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
              child: _buildTickerCell(row),
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

  Widget _buildTickerCell(ExpandableTableRowData row) {
    // Determine what to display based on options - only titles, no tickers
    String title = row.customTitle ?? row.name;
    String? subtitle = row.customSubtitle;
    
    // Choose appropriate text styles based on content type
    TextStyle titleStyle = row.showAsId 
        ? DashboardTextStyles.tickerSymbol.copyWith(fontSize: 11) 
        : DashboardTextStyles.stockName;
    
    TextStyle subtitleStyle = row.showAsId 
        ? DashboardTextStyles.tickerSymbol.copyWith(fontSize: 10) 
        : DashboardTextStyles.tickerSymbol;

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
              maxLines: row.showAsId ? 2 : 1, // Allow 2 lines for IDs
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

  Widget _buildCellContent(ExpandableTableRowData row, ExpandableTableColumn column) {
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
      style: DashboardTextStyles.dataCell,
      textAlign: column.alignment,
    );
  }
}
