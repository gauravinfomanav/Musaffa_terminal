import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

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
    this.headerTextColor,
    this.cellTextColor,
    this.nameColumnBackgroundColor,
    this.useChangeColors = true,
    this.nameColumnWidth,
    this.fontFamily,
    this.headerFontSize = 12,
    this.cellFontSize = 12,
    this.headerFontWeight = FontWeight.w500,
    this.cellFontWeight = FontWeight.w500,
    this.nameFontSize = 12,
    this.nameFontWeight = FontWeight.w500,
    this.disableHoverHighlight = false,
  }) : super(key: key);

  final List<TableColumn> columns;
  final List<TableRowData> data;
  final bool showNameColumn;
  final Function(TableRowData)? onRowSelect;
  final bool considerPadding;
  final double rowHeight;
  final double headerHeight;
  final Color? headerTextColor;
  final Color? cellTextColor;
  final Color? nameColumnBackgroundColor;
  final bool useChangeColors;
  final double? nameColumnWidth;
  final String? fontFamily;
  final double headerFontSize;
  final double cellFontSize;
  final FontWeight headerFontWeight;
  final FontWeight cellFontWeight;
  final double nameFontSize;
  final FontWeight nameFontWeight;
  final bool disableHoverHighlight;

  @override
  State<DynamicTable> createState() => _DynamicTableState();
}

class _DynamicTableState extends State<DynamicTable> {
  final ScrollController _scrollController = ScrollController();
  bool _increaseShadow = false;
  String? _hoveredRowId;
  int _rowHoverGeneration = 0;

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

  void _onRowHoverEnter(String rowId) {
    _rowHoverGeneration++;
    if (_hoveredRowId == rowId) return;
    setState(() => _hoveredRowId = rowId);
  }

  void _onRowHoverExit(String rowId) {
    final int generation = _rowHoverGeneration;
    Future<void>.delayed(const Duration(milliseconds: 20), () {
      if (!mounted) return;
      if (_rowHoverGeneration != generation) return;
      if (_hoveredRowId != rowId) return;
      setState(() => _hoveredRowId = null);
    });
  }

  Widget _wrapRowHover(String rowId, Widget child) {
    return MouseRegion(
      onEnter: (_) => _onRowHoverEnter(rowId),
      onExit: (_) => _onRowHoverExit(rowId),
      child: child,
    );
  }

  Color _rowColor(String rowId, bool isDark) {
    return _hoveredRowId == rowId
        ? HomeUi.tableRowHover(isDark)
        : Colors.transparent;
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
    return SizedBox(
      width: widget.nameColumnWidth,
      child: Container(
        decoration: BoxDecoration(
          color: widget.nameColumnBackgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
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
          dataRowColor: widget.disableHoverHighlight
              ? MaterialStateProperty.all(Colors.transparent)
              : null,
          headingRowColor: WidgetStateProperty.all(
            HomeUi.tableHeaderBg(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
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
                    fontSize: widget.headerFontSize,
                    color: widget.headerTextColor ?? const Color(0xff81AACE),
                    fontWeight: widget.headerFontWeight,
                    fontFamily: widget.fontFamily ?? Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            ),
          ],
          rows: widget.data.asMap().entries.map((entry) {
            final row = entry.value;
            final bool isDark =
                Theme.of(context).brightness == Brightness.dark;
            return DataRow(
              color: WidgetStateProperty.all(_rowColor(row.id, isDark)),
              cells: [
                DataCell(
                  _wrapRowHover(
                    row.id,
                    Padding(
                      padding: const EdgeInsets.only(right: 30.0),
                      child: BasicTickerCell(
                        model: BasicCellModel(
                          logo: row.logo,
                          symbol: row.symbol,
                          name: row.name,
                          nameFontSize: widget.nameFontSize,
                          nameFontWeight: widget.nameFontWeight,
                          fontFamily: widget.fontFamily ?? Constants.FONT_DEFAULT_NEW,
                        ),
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
              color: HomeUi.tableBorder(
                Theme.of(context).brightness == Brightness.dark,
              ),
              width: 0.5,
            ),
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
            dataRowColor: widget.disableHoverHighlight
                ? MaterialStateProperty.all(Colors.transparent)
                : null,
            headingRowColor: WidgetStateProperty.all(
              HomeUi.tableHeaderBg(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
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
                      fontSize: widget.headerFontSize,
                      color: widget.headerTextColor ?? const Color(0xff81AACE),
                      fontWeight: widget.headerFontWeight,
                      fontFamily: widget.fontFamily ?? Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              );
            }).toList(),
            rows: _getFilteredRows().map((row) {
              final bool isDark =
                  Theme.of(context).brightness == Brightness.dark;
              return DataRow(
                color: WidgetStateProperty.all(_rowColor(row.id, isDark)),
                onSelectChanged: (_) => widget.onRowSelect?.call(row),
                cells: widget.columns.map((column) {
                  return DataCell(
                    _wrapRowHover(row.id, _buildCellContent(row, column)),
                  );
                }).toList(),
              );
            }).toList(),
            dividerThickness: 0,
            border: TableBorder(
              bottom: BorderSide.none,
              verticalInside: BorderSide.none,
              horizontalInside: BorderSide(
                color: HomeUi.tableBorder(
                  Theme.of(context).brightness == Brightness.dark,
                ),
                width: 0.5,
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
      return Text(
        '-',
        style: TextStyle(
          fontSize: widget.cellFontSize,
          color: widget.cellTextColor ?? Theme.of(context).primaryColor,
          fontWeight: widget.cellFontWeight,
          fontFamily: widget.fontFamily ?? Constants.FONT_DEFAULT_NEW,
        ),
      );
    }

    if (value is num) {
      final text = value.toString();
      return Text(
        HomeUi.truncateTableText(text),
        style: TextStyle(
          fontSize: widget.cellFontSize,
          color: widget.cellTextColor ?? Theme.of(context).primaryColor,
          fontWeight: widget.cellFontWeight,
          fontFamily: widget.fontFamily ?? Constants.FONT_DEFAULT_NEW,
        ),
      );
    }

    if (value is String) {
      // Check if it's a change value (starts with + or -)
      Color textColor = widget.cellTextColor ?? Theme.of(context).primaryColor;
      if (widget.useChangeColors) {
        if (value.startsWith('+')) {
          textColor = Colors.green;
        } else if (value.startsWith('-')) {
          textColor = Colors.red;
        }
      }
      
      return Text(
        HomeUi.truncateTableText(value),
        style: TextStyle(
          fontSize: widget.cellFontSize,
          color: textColor,
          fontWeight: widget.cellFontWeight,
          fontFamily: widget.fontFamily ?? Constants.FONT_DEFAULT_NEW,
        ),
      );
    }

    return Text(
      '-',
      style: TextStyle(
        fontSize: widget.cellFontSize,
        color: widget.cellTextColor ?? Theme.of(context).primaryColor,
        fontWeight: widget.cellFontWeight,
        fontFamily: widget.fontFamily ?? Constants.FONT_DEFAULT_NEW,
      ),
    );
  }
}

class BasicCellModel {
  final String? logo;
  final String? symbol;
  final String? name;
  final double? nameFontSize;
  final FontWeight? nameFontWeight;
  final String? fontFamily;

  BasicCellModel({
    this.logo,
    this.symbol,
    this.name,
    this.nameFontSize = 14,
    this.nameFontWeight = FontWeight.w500,
    this.fontFamily,
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
    final String symbol = model.symbol ?? "";

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
                      HomeUi.truncateTableText(symbol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: model.nameFontSize,
                        fontWeight: model.nameFontWeight,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontFamily: model.fontFamily ?? Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  if (model.name != null && model.name!.isNotEmpty)
                    Text(
                      HomeUi.truncateTableText(model.name!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontFamily: model.fontFamily ?? Constants.FONT_DEFAULT_NEW,
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
