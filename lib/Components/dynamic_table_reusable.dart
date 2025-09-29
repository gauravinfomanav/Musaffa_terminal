import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/ticker_cell.dart';
import 'package:musaffa_terminal/models/ticker_cell_model.dart';
import 'package:musaffa_terminal/models/live_price_model.dart';
import 'package:musaffa_terminal/services/live_price_service.dart';
import 'package:musaffa_terminal/services/websocket_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

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
  final String? currency;
  final Map<String, dynamic> fields;
  final Color? changeColor;
  final bool? isPositive;
  final String? priceSource; // 'typesense' or 'websocket'

  const SimpleRowModel({
    required this.symbol,
    required this.name,
    this.logo,
    this.price,
    this.changePercent,
    this.currency,
    required this.fields,
    this.changeColor,
    this.isPositive,
    this.priceSource,
  });

  SimpleRowModel copyWith({
    String? symbol,
    String? name,
    String? logo,
    num? price,
    num? changePercent,
    String? currency,
    Map<String, dynamic>? fields,
    Color? changeColor,
    bool? isPositive,
    String? priceSource,
  }) {
    return SimpleRowModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      currency: currency ?? this.currency,
      fields: fields ?? this.fields,
      changeColor: changeColor ?? this.changeColor,
      isPositive: isPositive ?? this.isPositive,
      priceSource: priceSource ?? this.priceSource,
    );
  }
}

class DynamicTable extends StatefulWidget {
  const DynamicTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.showFixedColumn = true,
    this.considerPadding = true,
    this.columnSpacing = 6,
    this.horizontalMargin = 0,
    this.fixedColumnWidth,
    this.enableDragging = false,
    this.enableLivePrices = false,
    this.onDragStarted,
    this.onDragEnd,
  }) : super(key: key);

  final List<SimpleColumn> columns;
  final List<SimpleRowModel> rows;
  final bool showFixedColumn;
  final bool considerPadding;
  final double columnSpacing;
  final double horizontalMargin;
  final double? fixedColumnWidth;
  final bool enableDragging;
  final bool enableLivePrices;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

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
  
  // Live price services
  late LivePriceService _livePriceService;
  late WebSocketService _webSocketService;
  List<SimpleRowModel> _enrichedRows = [];
  StreamSubscription<Map<String, dynamic>>? _priceStreamSubscription;
  int _updateCounter = 0;

  @override
  void initState() {
    init();
    sController.addListener(() {
      setState(() {
        increaseShadow = sController.offset > 0.1;
      });
    });
    
    // Initialize live price services
    if (widget.enableLivePrices) {
      _livePriceService = Get.find<LivePriceService>();
      _webSocketService = Get.find<WebSocketService>();
      _setupLivePrices();
    }
    
    super.initState();
  }

  init() {
    // Don't call generateCols here as it needs context
  }

  @override
  void didUpdateWidget(DynamicTable oldWidget) {
    init();
    
    // Update live prices if enabled and rows changed
    if (widget.enableLivePrices && oldWidget.rows != widget.rows) {
      _setupLivePrices();
    }
    
    super.didUpdateWidget(oldWidget);
  }

  void _setupLivePrices() {
    if (!widget.enableLivePrices) return;
    
    // Extract tickers from rows
    List<String> tickers = widget.rows.map((row) => row.symbol).toList();
    
    // Store Typesense prices for comparison
    Map<String, double> typesensePrices = {};
    for (var row in widget.rows) {
      if (row.price != null) {
        typesensePrices[row.symbol] = row.price!.toDouble();
      }
    }
    _webSocketService.setTypesensePrices(typesensePrices);
    
    // Add tickers to visible list
    _livePriceService.addVisibleTickers(tickers);
    
    // Cancel previous subscription if exists
    _priceStreamSubscription?.cancel();
    
    // Listen to live price updates
    _priceStreamSubscription = _webSocketService.priceStream.listen(
      (livePrices) {
        if (mounted) {
          setState(() {
            _enrichedRows = _updateRowsWithLivePrices(widget.rows, livePrices);
            _updateCounter++;
            // Regenerate table data with updated prices
            generateDataRows();
          });
        }
      },
      onError: (error) {
        // Handle error silently
      },
    );
  }

  List<SimpleRowModel> _updateRowsWithLivePrices(List<SimpleRowModel> originalRows, Map<String, LivePriceData> livePrices) {
    return originalRows.map((row) {
      final livePriceData = livePrices[row.symbol];
      if (livePriceData != null) {
        // Update the fields map with the new live price
        Map<String, dynamic> updatedFields = Map.from(row.fields);
        // Update both 'price' and 'currentPrice' fields to cover different table configurations
        updatedFields['price'] = '\$${livePriceData.price.toStringAsFixed(2)}';
        updatedFields['currentPrice'] = '\$${livePriceData.price.toStringAsFixed(2)}';
        
        // For watchlist: Recalculate gain/loss dynamically based on live price
        if (updatedFields.containsKey('addedPrice') && updatedFields.containsKey('gainLoss')) {
          final addedPrice = updatedFields['addedPrice'];
          if (addedPrice is num) {
            final priceDiff = livePriceData.price - addedPrice;
            final gainLossPercent = addedPrice > 0 ? (priceDiff / addedPrice) * 100 : 0.0;
            
            // Update gain/loss with new calculation
            updatedFields['gainLoss'] = double.parse(priceDiff.toStringAsFixed(1));
            updatedFields['gainLossPercent'] = double.parse(gainLossPercent.toStringAsFixed(2));
          }
        }
        
        // Determine color based on price comparison
        Color? priceColor;
        Color? gainLossColor;
        
        if (livePriceData.typesensePrice != null) {
          if (livePriceData.price > livePriceData.typesensePrice!) {
            priceColor = Colors.green.shade600; // Live price higher than Typesense
          } else if (livePriceData.price < livePriceData.typesensePrice!) {
            priceColor = Colors.red.shade600; // Live price lower than Typesense
          }
          // If equal, keep original color (null)
        }
        
        // For watchlist: Set gain/loss color based on dynamic calculation
        if (updatedFields.containsKey('addedPrice')) {
          final addedPrice = updatedFields['addedPrice'];
          if (addedPrice is num) {
            final priceDiff = livePriceData.price - addedPrice;
            gainLossColor = priceDiff >= 0 ? Colors.green.shade600 : Colors.red.shade600;
          }
        }
        
        return row.copyWith(
          price: livePriceData.price,
          priceSource: 'websocket',
          fields: updatedFields,
          changeColor: priceColor ?? gainLossColor,
          isPositive: updatedFields.containsKey('addedPrice') ? 
            (livePriceData.price - (updatedFields['addedPrice'] as num)) >= 0 : 
            row.isPositive,
        );
      } else {
        return row.copyWith(priceSource: 'typesense');
      }
    }).toList();
  }

  @override
  void dispose() {
    if (widget.enableLivePrices) {
      // Cancel stream subscription
      _priceStreamSubscription?.cancel();
      
      // Remove tickers from visible list when widget is disposed
      List<String> tickers = widget.rows.map((row) => row.symbol).toList();
      _livePriceService.removeVisibleTickers(tickers);
    }
    super.dispose();
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
            Expanded(
              flex: widget.fixedColumnWidth?.toInt() ?? 3,
              child: Container(
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
                  key: ValueKey('fixed_$_updateCounter'),
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
                    key: ValueKey('table_$_updateCounter'),
                    showCheckboxColumn: false,
                    headingRowHeight: 24,
                    horizontalMargin: widget.horizontalMargin,
                    columnSpacing: widget.columnSpacing,
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

    // Use enriched rows if live prices are enabled, otherwise use original rows
    List<SimpleRowModel> rowsToUse = widget.enableLivePrices && _enrichedRows.isNotEmpty 
        ? _enrichedRows 
        : widget.rows;


    // Filter rows that have at least one non-empty value
    List<SimpleRowModel> filteredRows = rowsToUse.where((row) => _hasAnyValue(row)).toList();

    filteredRows.forEach((rowModel) {
      List<DataCell> cellArr = [];
      List<DataCell> fixedRowCellArr = [];

      // Fixed column cell (Company info)
      if (widget.showFixedColumn) {

        Widget tickerCell = MainTickerCell(
          model: TickerCellModel(
            currency: rowModel.currency ?? 'USD',
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
        );

        // Wrap with Draggable if dragging is enabled
        if (widget.enableDragging) {
          tickerCell = Draggable<SimpleRowModel>(
            data: rowModel,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF2D2D2D) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF404040) 
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    showLogo(rowModel.symbol, rowModel.logo ?? "",
                        sideWidth: 20,
                        circular: true,
                        name: rowModel.name),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rowModel.name,
                            style: DashboardTextStyles.stockName.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            rowModel.symbol,
                            style: DashboardTextStyles.tickerSymbol.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    if (rowModel.price != null)
                      Text(
                        '\$${rowModel.price!.toStringAsFixed(2)}',
                        style: DashboardTextStyles.dataCell.copyWith(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: tickerCell,
            ),
            onDragStarted: () {
              widget.onDragStarted?.call();
            },
            onDragEnd: (details) {
              widget.onDragEnd?.call();
            },
            child: tickerCell,
          );
        }

        var basicCell = DataCell(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: tickerCell,
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
          
          // Apply special styling for change column, price column, currentPrice column, and gainLoss column
          if ((column.fieldName == 'change' || column.fieldName == 'price' || 
               column.fieldName == 'currentPrice' || column.fieldName == 'gainLoss') && 
              rowModel.changeColor != null) {
            textColor = rowModel.changeColor!;
          }
          
          DataCell cell = DataCell(
            (column.fieldName == 'change' || column.fieldName == 'gainLoss') && rowModel.isPositive != null
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