import 'package:flutter/material.dart';

// Simple data model for table rows
class TableRowData {
  final String id;
  final String name;
  final String symbol;
  final String? logo;
  final Map<String, dynamic> data;

  TableRowData({
    required this.id,
    required this.name,
    required this.symbol,
    this.logo,
    required this.data,
  });
}

// Column definition
class TableColumn {
  final String key;
  final String title;
  final double? width;
  final bool isCustomWidget;

  TableColumn({
    required this.key,
    required this.title,
    this.width,
    this.isCustomWidget = false,
  });
}

class DynamicTable extends StatefulWidget {
  const DynamicTable({
    Key? key,
    required this.columns,
    required this.data,
    this.showNameColumn = true,
    this.onRowSelect,
    this.considerPadding = true,
    this.rowHeight = 64,
    this.headerHeight = 30,
  }) : super(key: key);

  final List<TableColumn> columns;
  final List<TableRowData> data;
  final bool showNameColumn;
  final Function(TableRowData)? onRowSelect;
  final bool considerPadding;
  final double rowHeight;
  final double headerHeight;

  @override
  State<DynamicTable> createState() => _DynamicTableState();
}

class _DynamicTableState extends State<DynamicTable> {
  final ScrollController _scrollController = ScrollController();
  bool _increaseShadow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _increaseShadow = _scrollController.offset > 0.1;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Get filtered rows that have at least one non-empty value
  List<TableRowData> _getFilteredRows() {
    return widget.data.where((row) => _hasAnyValue(row)).toList();
  }

  // Check if a row has any non-empty values
  bool _hasAnyValue(TableRowData row) {
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
          if (widget.showNameColumn) _buildNameColumn(),
          Expanded(
            child: _buildDataColumns(),
          ),
        ],
      ),
    );
  }

  Widget _buildNameColumn() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xff81AACE),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
        rows: widget.data.map((row) {
          return DataRow(
            cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: BasicTickerCell(
                    model: BasicCellModel(
                      logo: row.logo,
                      symbol: row.symbol,
                      name: row.name,
                    ),
                  ),
                ),
                onTap: () => widget.onRowSelect?.call(row),
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

  Widget _buildDataColumns() {
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
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xff81AACE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
            rows: _getFilteredRows().map((row) {
              return DataRow(
                onSelectChanged: (_) => widget.onRowSelect?.call(row),
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

  Widget _buildCellContent(TableRowData row, TableColumn column) {
    final value = row.data[column.key];
    
    if (value == null) {
      return const Text("-");
    }

    if (value is num) {
      return Text(
        value.toString(),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (value is String) {
      // Check if it's a change value (starts with + or -)
      Color textColor = Theme.of(context).primaryColor;
      if (value.startsWith('+')) {
        textColor = Colors.green;
      } else if (value.startsWith('-')) {
        textColor = Colors.red;
      }
      
      return Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return const Text("-");
  }
}

class BasicCellModel {
  final String? logo;
  final String? symbol;
  final String? name;
  final double? nameFontSize;
  final FontWeight? nameFontWeight;

  BasicCellModel({
    this.logo,
    this.symbol,
    this.name,
    this.nameFontSize = 14,
    this.nameFontWeight = FontWeight.w500,
  });
}

class BasicTickerCell extends StatelessWidget {
  const BasicTickerCell({
    Key? key,
    required this.model,
  }) : super(key: key);

  final BasicCellModel model;

  @override
  Widget build(BuildContext context) {
    String symbol = model.symbol ?? "";
    if (symbol.length > 15) {
      symbol = symbol.substring(0, 15) + "...";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (model.logo != null) ...[
                _buildLogo(),
                const SizedBox(width: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: model.nameFontSize,
                        fontWeight: model.nameFontWeight,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (model.name != null && model.name!.isNotEmpty)
                    Text(
                      model.name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: model.logo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                model.logo!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.business,
                    size: 16,
                    color: Colors.grey[600],
                  );
                },
              ),
            )
          : Icon(
              Icons.business,
              size: 16,
              color: Colors.grey[600],
            ),
    );
  }
}
