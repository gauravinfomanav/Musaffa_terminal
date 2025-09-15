import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/Components/ticker_cell.dart';
import 'package:musaffa_terminal/models/ticker_cell_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';

var holdingItemTitleGroup = AutoSizeGroup();

enum SYMBOLS_TYPE { STOCK, ETF, BOTH, OTHER }

class AmountWidgetObj {
  final num? amount;
  final String? currency;
  final TextStyle? textStyle;
  final bool? isGradient;
  final Gradient? gradientStyle;

  AmountWidgetObj({
    this.amount,
    this.currency,
    this.textStyle,
    this.isGradient,
    this.gradientStyle,
  });
}

class SimpleColumn {
  final String label;
  final String fieldName;
  final double? width;
  final bool isNumeric;

  const SimpleColumn({
    required this.label,
    required this.fieldName,
    this.width,
    this.isNumeric = false,
  });
}

class SimpleRowModel {
  final String symbol;
  final String name;
  final String? logo;
  final num? price;
  final num? changePercent;
  final Map<String, dynamic> fields;
  final Color? changeColor;
  final bool? isPositive;

  const SimpleRowModel({
    required this.symbol,
    required this.name,
    this.logo,
    this.price,
    this.changePercent,
    required this.fields,
    this.changeColor,
    this.isPositive,
  });
}

class DynamicTable extends StatefulWidget {
  const DynamicTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.showFixedColumn = true,
    this.considerPadding = true,
  }) : super(key: key);

  final List<SimpleColumn> columns;
  final List<SimpleRowModel> rows;
  final bool showFixedColumn;
  final bool considerPadding;

  @override
  State<DynamicTable> createState() => _DynamicTableState();
}

class _DynamicTableState extends State<DynamicTable> {
  List<DataColumn> dataCols = [];
  List<DataRow> dataRows = [];
  List<DataColumn> fixedDataCols = [];
  List<DataRow> fixedDataRows = [];
  var sController = ScrollController();
  var increaseShadow = false;

  @override
  void initState() {
    init();
    sController.addListener(() {
      setState(() {
        increaseShadow = sController.offset > 0.1;
      });
    });
    super.initState();
  }

  init() {
    // Don't call generateCols here as it needs context
  }

  @override
  void didUpdateWidget(DynamicTable oldWidget) {
    init();
    super.didUpdateWidget(oldWidget);
  }

  generateCols() {
    List<DataColumn> fixedLst = [];
    List<DataColumn> lst = [];

    // Fixed column for company name
    if (widget.showFixedColumn) {
      fixedLst.add(DataColumn(
        label: Expanded(
          child: Text(
            "Company",
            style: DashboardTextStyles.columnHeader,
          ),
        ),
      ));
    }

    // Dynamic columns
    widget.columns.forEach((column) {
      var dataColumn = DataColumn(
        label: Expanded(
          child: Text(
            column.label,
            style: DashboardTextStyles.columnHeader,
          ),
        ),
      );
      lst.add(dataColumn);
    });

    setState(() {
      dataCols = lst;
      fixedDataCols = fixedLst;
    });
  }

  @override
  Widget build(BuildContext context) {
    generateCols();
    generateDataRows();
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: widget.considerPadding == true ? 16 : 0),
      child: Row(
        children: [
          if (widget.showFixedColumn)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade50,
                boxShadow: [
                  BoxShadow(
                    color: increaseShadow
                        ? Colors.black.withOpacity(0.03)
                        : Colors.transparent,
                    blurRadius: increaseShadow ? 4 : 0,
                    spreadRadius: 0,
                    blurStyle: BlurStyle.inner,
                    offset: Offset(4, 0),
                  ),
                ],
              ),
                              child: DataTable(
                  showCheckboxColumn: false,
                  headingRowHeight: 24,
                  horizontalMargin: 0,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 48,
                  columns: fixedDataCols,
                  rows: fixedDataRows,
                dividerThickness: 0,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent, width: 0),
                ),
                border: TableBorder(
                  bottom: BorderSide.none,
                  top: BorderSide.none,
                  verticalInside: BorderSide.none,
                  horizontalInside: BorderSide.none,
                ),
              ),
            ),
          Expanded(
            child: Scrollbar(
              controller: sController,
              thickness: 4,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: sController,
                scrollDirection: Axis.horizontal,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 24,
                    horizontalMargin: 0,
                    columnSpacing: 6,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    columns: dataCols.isNotEmpty ? dataCols : [DataColumn(label: SizedBox.shrink())],
                    rows: dataRows.isNotEmpty ? dataRows : [DataRow(cells: [DataCell(SizedBox.shrink())])],
                    dividerThickness: 0,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent, width: 0),
                    ),
                    border: TableBorder(
                      bottom: BorderSide.none,
                      top: BorderSide.none,
                      verticalInside: BorderSide.none,
                      horizontalInside: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Check if a row has any non-empty values
  bool _hasAnyValue(SimpleRowModel row) {
    for (dynamic value in row.fields.values) {
      if (value != null && value != '--' && value != '-' && value != '') {
        return true;
      }
    }
    return false;
  }

  generateDataRows() {
    List<DataRow> dataRowLst = [];
    List<DataRow> fixedRowLst = [];

    // Filter rows that have at least one non-empty value
    List<SimpleRowModel> filteredRows = widget.rows.where((row) => _hasAnyValue(row)).toList();

    filteredRows.forEach((rowModel) {
      List<DataCell> cellArr = [];
      List<DataCell> fixedRowCellArr = [];

      // Fixed column cell (Company info)
      if (widget.showFixedColumn) {
        var basicCell = DataCell(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: MainTickerCell(
              model: TickerCellModel(
                currency: 'USD',
                tickerName: rowModel.symbol,
                companyName: rowModel.name,
                currentPrice: rowModel.price,
                percentchange: rowModel.changePercent,
                logoUrl: rowModel.logo,
                halalRate: null,
                ranking: null,
                hideBadge: true, // Hide the halal badge for top movers
                country: 'US',
                isStock: true,
                mainTicker: rowModel.symbol,
                showLockOnStars: false,
              ),
              showBottomBorder: false,
              horizontalSpacing: 6,
              verticalSpacing: 4,
            ),
          ),
        );
        fixedRowCellArr.add(basicCell);
        fixedRowLst.add(DataRow(cells: fixedRowCellArr));
      }

      // Dynamic column cells
      if (widget.columns.isNotEmpty) {
        widget.columns.forEach((column) {
          String cellData = rowModel.fields[column.fieldName]?.toString() ?? "-";
          Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
          
          // Apply special styling for change column
          if (column.fieldName == 'change' && rowModel.changeColor != null) {
            textColor = rowModel.changeColor!;
          }
          
          DataCell cell = DataCell(
            column.fieldName == 'change' && rowModel.isPositive != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rowModel.isPositive! ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: textColor,
                        size: 14,
                      ),
                      SizedBox(width: 2),
                      Text(
                        cellData,
                        style: DashboardTextStyles.dataCell.copyWith(color: textColor),
                      ),
                    ],
                  )
                : Text(
                    cellData,
                    style: DashboardTextStyles.dataCell.copyWith(color: textColor),
                  ),
          );
          cellArr.add(cell);
        });
        dataRowLst.add(DataRow(cells: cellArr));
      } else {
        // Add dummy row with single empty cell when no dynamic columns
        dataRowLst.add(DataRow(cells: [DataCell(SizedBox.shrink())]));
      }
    });

    setState(() {
      dataRows = dataRowLst;
      fixedDataRows = fixedRowLst;
    });
  }
}



class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}