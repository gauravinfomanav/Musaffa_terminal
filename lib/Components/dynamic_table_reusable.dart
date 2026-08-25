import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/ticker_cell.dart';
import 'package:musaffa_terminal/Screens/etf_details_screen.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/models/ticker_cell_model.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/models/live_price_model.dart';
import 'package:musaffa_terminal/services/live_price_service.dart';
import 'package:musaffa_terminal/services/websocket_service.dart';
import 'package:musaffa_terminal/services/table_column_preferences_service.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

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
    this.title,
    this.subtitle,
    this.toolbarLeadingIcon,
    this.showOuterShadow = false,
    this.outerBoxShadow,
    this.sortState,
    this.onSortChange,
    this.toolbar,
    this.showFixedColumn = true,
    this.considerPadding = true,
    this.columnSpacing = 40,
    this.horizontalMargin = 16,
    this.fixedColumnWidth,
    this.enableDragging = false,
    this.enableLivePrices = false,
    this.zebraStripes = false,
    this.evenRowColor,
    this.oddRowColor,
    this.onDragStarted,
    this.onDragEnd,
    this.tableId,
    this.enableColumnCustomization = false,
    this.onTickerTap,
    this.centerCellContent = false,
    this.compactHeaderText = false,
    this.showColumnActionMenu = true,
    this.showColumnResizeHandle = true,
    this.resizeHandleIndicatorHeight = 14,
    this.tickerHeaderLabel = 'COMPANY',
    this.headerHeight,
    this.rowHeight,
  }) : super(key: key);

  final List<SimpleColumn> columns;
  final List<SimpleRowModel> rows;
  final String? title;
  final String? subtitle;
  final IconData? toolbarLeadingIcon;
  final bool showOuterShadow;
  final List<BoxShadow>? outerBoxShadow;
  final SortState? sortState;
  final Function(String, String)? onSortChange;
  final Widget? toolbar;
  final bool showFixedColumn;
  final bool considerPadding;
  final double columnSpacing;
  final double horizontalMargin;
  final double? fixedColumnWidth;
  final bool enableDragging;
  final bool enableLivePrices;
  final bool zebraStripes;
  final Color? evenRowColor;
  final Color? oddRowColor;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final String? tableId; // Unique identifier for this table instance
  final bool enableColumnCustomization; // Enable column customization features
  final Function(DynamicTableRow)? onTickerTap;
  final bool centerCellContent;
  final bool compactHeaderText;
  final bool showColumnActionMenu;
  final bool showColumnResizeHandle;
  final double resizeHandleIndicatorHeight;
  final String tickerHeaderLabel;
  final double? headerHeight;
  final double? rowHeight;

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
  Color? _defaultTextColor; // Store default text color to avoid context access during dispose
  
  // Column customization
  List<SimpleColumn> _customizedColumns = [];
  TableColumnPreferencesService? _prefsService;
  int? _draggedColumnIndex;
  int? _dropTargetIndex;

  @override
  void initState() {
    init();
    sController.addListener(() {
      if (mounted) {
      setState(() {
        increaseShadow = sController.offset > 0.1;
      });
      }
    });
    
    // Initialize column customization
    if (widget.enableColumnCustomization && widget.tableId != null) {
      _initializeColumnCustomization();
    } else {
      _customizedColumns = List.from(widget.columns);
    }
    
    // Initialize live price services
    if (widget.enableLivePrices) {
      _livePriceService = Get.find<LivePriceService>();
      _webSocketService = Get.find<WebSocketService>();
      _setupLivePrices();
    }
    
    super.initState();
  }
  
  void _initializeColumnCustomization() {
    if (widget.tableId == null) return;
    
    _prefsService = Get.find<TableColumnPreferencesService>();
    final prefs = _prefsService!.getColumnPreferences(widget.tableId!);
    
    if (prefs != null) {
      // Load saved column order
      final columnOrder = (prefs['columnOrder'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      
      // Reorder columns based on saved order
      if (columnOrder != null && columnOrder.isNotEmpty) {
        _customizedColumns = [];
        final columnMap = {for (var col in widget.columns) col.fieldName: col};
        
        // Add columns in saved order
        for (var fieldName in columnOrder) {
          if (columnMap.containsKey(fieldName)) {
            _customizedColumns.add(columnMap[fieldName]!);
          }
        }
        
        // Add any new columns that weren't in saved order
        for (var col in widget.columns) {
          if (!columnOrder.contains(col.fieldName)) {
            _customizedColumns.add(col);
          }
        }
      } else {
        _customizedColumns = List.from(widget.columns);
      }
    } else {
      // No saved preferences, use defaults
      _customizedColumns = List.from(widget.columns);
    }
  }
  
  Future<void> _saveColumnPreferences() async {
    if (widget.tableId == null || _prefsService == null) return;
    
    // Save all columns as visible (no hide functionality)
    final visibleColumns = _customizedColumns.map((col) => col.fieldName).toList();
    final columnOrder = _customizedColumns.map((col) => col.fieldName).toList();
    
    await _prefsService!.saveColumnPreferences(
      widget.tableId!,
      visibleColumns,
      columnOrder,
    );
  }
  
  void _onColumnReordered(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    setState(() {
      final column = _customizedColumns.removeAt(oldIndex);
      _customizedColumns.insert(newIndex, column);
    });
    
    // Save preferences automatically
    _saveColumnPreferences();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store default text color when widget is active
    if (mounted) {
      _defaultTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }
  }

  init() {
    // Don't call generateCols here as it needs context
  }

  @override
  void didUpdateWidget(DynamicTable oldWidget) {
    init();

    // Keep customized columns in sync when incoming columns/table context changes.
    if (widget.enableColumnCustomization && widget.tableId != null) {
      if (oldWidget.tableId != widget.tableId) {
        _initializeColumnCustomization();
      } else if (oldWidget.columns != widget.columns) {
        final columnMap = {for (var col in widget.columns) col.fieldName: col};
        final nextColumns = <SimpleColumn>[];

        // Preserve current visual order for columns that still exist.
        for (var col in _customizedColumns) {
          final mapped = columnMap[col.fieldName];
          if (mapped != null) {
            nextColumns.add(mapped);
          }
        }

        // Append any new columns not present in current customized order.
        for (var col in widget.columns) {
          if (!nextColumns.any((c) => c.fieldName == col.fieldName)) {
            nextColumns.add(col);
          }
        }

        _customizedColumns = nextColumns;
      }
    } else if (oldWidget.columns != widget.columns ||
        oldWidget.enableColumnCustomization != widget.enableColumnCustomization) {
      _customizedColumns = List.from(widget.columns);
    }
    
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
          try {
          setState(() {
            _enrichedRows = _updateRowsWithLivePrices(widget.rows, livePrices);
              // Regenerate table data with updated prices (only if still mounted)
              if (mounted) {
            generateDataRows();
              }
          });
          } catch (e) {
            // Silently handle errors during widget lifecycle transitions
          }
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
        
        // Recalculate change % if original change is not empty and not 0
        // Check both 'change' and 'change1D' fields
        if (livePriceData.typesensePrice != null && livePriceData.typesensePrice! > 0) {
          // Try 'change' field first, then 'change1D'
          String? changeFieldName;
          final originalChange = row.fields['change'] ?? row.fields['change1D'];
          
          if (row.fields.containsKey('change')) {
            changeFieldName = 'change';
          } else if (row.fields.containsKey('change1D')) {
            changeFieldName = 'change1D';
          }
          
          // Check if change field exists and is not empty ('--') and not 0
          bool shouldUpdateChange = false;
          double? originalChangePercent = null;
          
          if (originalChange != null && originalChange != '--' && originalChange != '-') {
            // Try to parse the original change value
            String changeStr = originalChange.toString();
            // Remove % sign and + sign if present
            changeStr = changeStr.replaceAll('%', '').replaceAll('+', '').trim();
            originalChangePercent = double.tryParse(changeStr);
            
            // Only update if original change is not null and not 0
            if (originalChangePercent != null && originalChangePercent != 0) {
              shouldUpdateChange = true;
            }
          }
          
          if (shouldUpdateChange && changeFieldName != null) {
            // Calculate new change % based on live price vs original Typesense price
            final priceDiff = livePriceData.price - livePriceData.typesensePrice!;
            final changePercent = (priceDiff / livePriceData.typesensePrice!) * 100;
            
            // Update change % field (use the field name that exists)
            updatedFields[changeFieldName] = '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
            
            // Update change amount if field exists
            if (updatedFields.containsKey('changeAmount')) {
              updatedFields['changeAmount'] = '\$${priceDiff.toStringAsFixed(2)}';
            }
            
            // Update changePercent in the model
            row = row.copyWith(changePercent: changePercent);
          }
        }
        
        // For watchlist: Recalculate gain/loss dynamically based on live price
        if (updatedFields.containsKey('addedPrice') && updatedFields.containsKey('gainLoss')) {
          final addedPrice = updatedFields['addedPrice'];
          if (addedPrice is num) {
            final priceDiff = livePriceData.price - addedPrice;
            final gainLossPercent = addedPrice > 0 ? (priceDiff / addedPrice) * 100 : 0.0;
            
            // Update gain/loss with new calculation
            updatedFields['gainLoss'] = double.parse(priceDiff.toStringAsFixed(1));
            updatedFields['gainLossPercent'] = double.parse(gainLossPercent.toStringAsFixed(2));
            
            // Format addedPrice for display (keep as number for calculations, but format for consistency)
            // Note: addedPrice stays as number so calculations work, display logic will format it
          }
        }
        
        // Determine color based on price comparison
        Color? priceColor;
        Color? gainLossColor;
        Color? changeColor;
        
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
        
        // Update isPositive and changeColor based on change % if it was recalculated
        bool? isPositive = row.isPositive;
        if (updatedFields.containsKey('change') && updatedFields['change'] != '--' && updatedFields['change'] != '-') {
          String changeStr = updatedFields['change'].toString();
          changeStr = changeStr.replaceAll('%', '').replaceAll('+', '').trim();
          final changeValue = double.tryParse(changeStr);
          if (changeValue != null) {
            isPositive = changeValue >= 0;
            // Set color for change % column: green for positive, red for negative
            changeColor = changeValue >= 0 ? Colors.green.shade600 : Colors.red.shade600;
          }
        }
        
        return row.copyWith(
          price: livePriceData.price,
          priceSource: 'websocket',
          fields: updatedFields,
          changeColor: changeColor ?? priceColor ?? gainLossColor,
          isPositive: updatedFields.containsKey('addedPrice') ? 
            (livePriceData.price - (updatedFields['addedPrice'] as num)) >= 0 : 
            isPositive,
        );
      } else {
        return row.copyWith(priceSource: 'typesense');
      }
    }).toList();
  }

  @override
  void dispose() {
    // Cancel stream subscription first to prevent any further updates
    _priceStreamSubscription?.cancel();
    _priceStreamSubscription = null;
    
    if (widget.enableLivePrices) {
      // Remove tickers from visible list when widget is disposed
      List<String> tickers = widget.rows.map((row) => row.symbol).toList();
      _livePriceService.removeVisibleTickers(tickers);
    }
    super.dispose();
  }

  generateCols() {
    List<DataColumn> fixedLst = [];
    List<DataColumn> lst = [];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDarkMode ? Colors.white : const Color(0xFF757576);

    // Fixed column for company name
    if (widget.showFixedColumn) {
      fixedLst.add(DataColumn(
        label: SizedBox(
          width: widget.fixedColumnWidth != null && widget.fixedColumnWidth! > 10
              ? widget.fixedColumnWidth!
              : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Center(
              child: widget.compactHeaderText
                  ? AutoSizeText(
                      "COMPANY",
                      maxLines: 1,
                      minFontSize: 9,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: headerColor,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Text(
                      "COMPANY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: headerColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
          ),
        ),
      ));
    }

    // Use customized columns if customization is enabled, otherwise use original
    final columnsToUse = widget.enableColumnCustomization 
        ? _customizedColumns
        : widget.columns;

    // Dynamic columns
    for (int index = 0; index < columnsToUse.length; index++) {
      final column = columnsToUse[index];
      // Check if this is a price column that needs fixed width
      final isPriceColumn = column.fieldName == 'price' || 
                           column.fieldName == 'currentPrice' || 
                           column.fieldName == 'addedPrice';
      
      // All headers centered
      final textAlign = TextAlign.center;
      
      Widget headerLabel = Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: widget.compactHeaderText
            ? AutoSizeText(
                column.label,
                maxLines: 1,
                minFontSize: 9,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 13,
                  color: headerColor,
                  fontWeight: FontWeight.w400,
                ),
              )
            : Text(
                column.label,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 13,
                  color: headerColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
      );

      if (column.width != null) {
        headerLabel = SizedBox(
          width: column.width,
          child: headerLabel,
        );
      }
      
      if (isPriceColumn) {
        headerLabel = SizedBox(
          width: 65,
          child: Align(
            alignment: Alignment.center,
            child: headerLabel,
          ),
        );
      } else {
        headerLabel = Align(
          alignment: Alignment.center,
          child: headerLabel,
        );
      }
      
      // Make header draggable if customization is enabled
      if (widget.enableColumnCustomization) {
        headerLabel = _buildDraggableColumnHeader(
          headerLabel: headerLabel,
          columnIndex: index,
        );
      }
      
      var dataColumn = DataColumn(
        label: headerLabel,
      );
      lst.add(dataColumn);
    }

    setState(() {
      dataCols = lst;
      fixedDataCols = fixedLst;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rowsToUse = widget.enableLivePrices && _enrichedRows.isNotEmpty
        ? _enrichedRows
        : widget.rows;

    final filteredRows = rowsToUse.where((row) => _hasAnyValue(row)).toList();

    final columnsToUse = widget.enableColumnCustomization
        ? (_customizedColumns.isNotEmpty ? _customizedColumns : widget.columns)
        : widget.columns;

    final mappedColumns = columnsToUse
        .map(
          (col) => DynamicTableColumn(
            key: col.fieldName,
            label: col.label,
            headerWidget: null,
            width: col.width,
            sortable: true,
            align: col.isNumeric ? TextAlign.right : TextAlign.left,
          ),
        )
        .toList();

    final mappedRows = filteredRows.map((row) {
      final data = <String, dynamic>{...row.fields};
      data['_ticker_symbol'] = row.symbol;
      data['_company_name'] = row.name;
      data['_logo_url'] = row.logo;
      data['_is_stock'] = row.fields['isStock'] is bool ? row.fields['isStock'] : true;

      if (!data.containsKey('price') && row.price != null) {
        data['price'] = '\$${row.price!.toStringAsFixed(2)}';
      }

      return DynamicTableRow(
        id: data['_row_id']?.toString() ??
            (row.symbol.isNotEmpty ? row.symbol : row.name),
        data: data,
      );
    }).toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.considerPadding == true ? 16 : 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: HomeUi.cardBg(Theme.of(context).brightness == Brightness.dark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: widget.showOuterShadow
              ? Border.all(
                  color: HomeUi.borderLight(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                )
              : null,
          boxShadow: widget.showOuterShadow
              ? (widget.outerBoxShadow ??
                  HomeUi.cardShadow(
                    Theme.of(context).brightness == Brightness.dark,
                  ))
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          child: DynamicTableFromWeb(
            title: widget.title,
            subtitle: widget.subtitle,
            toolbarLeadingIcon: widget.toolbarLeadingIcon,
            useOuterContainer: false,
            columns: mappedColumns,
            rows: mappedRows,
            sortState: widget.sortState,
            onSortChange: widget.onSortChange,
            toolbar: widget.toolbar,
            paginated: false,
            selectable: false,
            showTickerCell: widget.showFixedColumn,
            tickerKey: '_ticker_symbol',
            companyKey: '_company_name',
            logoKey: '_logo_url',
            tickerHeaderLabel: widget.tickerHeaderLabel,
            tickerColumnWidth: widget.fixedColumnWidth,
            enableColumnVisibilityToggle: widget.enableColumnCustomization,
            enableColumnReorder: widget.enableColumnCustomization,
            enableColumnPinning: true,
            stickyHeader: true,
            showColumnActionMenu: widget.showColumnActionMenu,
            showColumnResizeHandle: widget.showColumnResizeHandle,
            resizeHandleIndicatorHeight: widget.resizeHandleIndicatorHeight,
            horizontalMargin: widget.horizontalMargin,
            columnSpacing: widget.columnSpacing,
            showHeaderTooltip: false,
            headerHeight: widget.headerHeight ?? 42,
            rowHeight: widget.rowHeight ?? 52,
            dataRowMinHeight: widget.rowHeight ?? 52,
            dataRowMaxHeight: widget.rowHeight ?? 52,
            onTickerTap: widget.onTickerTap ?? (row) {
          final ticker = row.data['_ticker_symbol']?.toString() ?? '';
          if (ticker.isEmpty || ticker == '--') return;

          final companyName = row.data['_company_name']?.toString() ?? ticker;
          final logo = row.data['_logo_url']?.toString();
          final isStock = row.data['_is_stock'] == false ? false : true;
          final priceValue = row.data['price'];
          final currentPrice = priceValue is num
              ? priceValue
              : double.tryParse(
                  priceValue?.toString().replaceAll(RegExp(r'[^\d.-]'), '') ?? '',
                );
          final changeValue = row.data['changePercent'];
          final percentChange = changeValue is num
              ? changeValue
              : double.tryParse(
                  changeValue?.toString().replaceAll(RegExp(r'[^\d.-]'), '') ?? '',
                );

          final tickerModel = TickerModel(
            symbol: ticker,
            ticker: ticker,
            mainTicker: ticker,
            name: companyName,
            companyName: companyName,
            logo: (logo != null && logo.isNotEmpty) ? logo : null,
            currentPrice: currentPrice,
            percentChange: percentChange,
            currency: row.data['currency']?.toString() ?? 'USD',
            isStock: isStock,
          );

          FeatureNavigation.pushIfAllowed(
            context,
            isStock ? FeatureKeys.tickerDetails : FeatureKeys.etfDetails,
            isStock
                ? TickerDetailScreen(ticker: tickerModel)
                : EtfDetailsScreen(ticker: tickerModel),
          );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildDraggableColumnHeader({
    required Widget headerLabel,
    required int columnIndex,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDragging = _draggedColumnIndex == columnIndex;
    
    return DragTarget<int>(
      onWillAccept: (data) {
        if (data == null) return false;
        setState(() {
          _dropTargetIndex = columnIndex;
        });
        return true;
      },
      onLeave: (data) {
        setState(() {
          _dropTargetIndex = null;
        });
      },
      onAccept: (draggedIndex) {
        if (draggedIndex != columnIndex) {
          _onColumnReordered(draggedIndex, columnIndex);
        }
        setState(() {
          _draggedColumnIndex = null;
          _dropTargetIndex = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = _dropTargetIndex == columnIndex && candidateData.isNotEmpty;
        
        return Stack(
          children: [
            if (isDropTarget)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            Draggable<int>(
              data: columnIndex,
              feedback: Material(
                elevation: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: headerLabel,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: headerLabel,
              ),
              onDragStarted: () {
                setState(() {
                  _draggedColumnIndex = columnIndex;
                });
              },
              onDragEnd: (details) {
                setState(() {
                  _draggedColumnIndex = null;
                  _dropTargetIndex = null;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isDragging 
                        ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7))
                        : Colors.transparent,
                  ),
                  child: headerLabel,
                ),
              ),
            ),
          ],
        );
      },
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
    // Safety check: don't generate rows if widget is disposed
    if (!mounted) {
      return;
    }
    
    List<DataRow> dataRowLst = [];
    List<DataRow> fixedRowLst = [];

    // Use enriched rows if live prices are enabled, otherwise use original rows
    List<SimpleRowModel> rowsToUse = widget.enableLivePrices && _enrichedRows.isNotEmpty 
        ? _enrichedRows 
        : widget.rows;


    // Filter rows that have at least one non-empty value
    List<SimpleRowModel> filteredRows = rowsToUse.where((row) => _hasAnyValue(row)).toList();

    for (int index = 0; index < filteredRows.length; index++) {
      final rowModel = filteredRows[index];
      List<DataCell> cellArr = [];
      List<DataCell> fixedRowCellArr = [];

      // Fixed column cell (Company info)
      if (widget.showFixedColumn) {

        Widget tickerCell;
        
        // If logo is null and symbol is empty, use simple text-only cell (for portfolios)
        if (rowModel.logo == null && rowModel.symbol.isEmpty) {
          tickerCell = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                rowModel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardTextStyles.stockName,
              ),
            ),
          );
        } else {
          // Use MainTickerCell for stocks/ETFs with logos
          tickerCell = MainTickerCell(
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
              stock: TickerModel(
                symbol: rowModel.symbol,
                name: rowModel.name,
                companyName: rowModel.name,
                logo: rowModel.logo,
                currentPrice: rowModel.price,
                percentChange: rowModel.changePercent,
                currency: rowModel.currency ?? 'USD',
                isStock: true,
                mainTicker: rowModel.symbol,
                ticker: rowModel.symbol,
              ),
            ),
            showBottomBorder: false,
            horizontalSpacing: 6,
            verticalSpacing: 4,
          );
        }

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
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.fixedColumnWidth != null && widget.fixedColumnWidth! > 10
                  ? widget.fixedColumnWidth! - 16 // Account for padding
                  : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 0),
              child: tickerCell,
            ),
          ),
        );
        fixedRowCellArr.add(basicCell);
        fixedRowLst.add(DataRow(
          color: _resolveRowColor(index),
          cells: fixedRowCellArr,
        ));
      }

      // Dynamic column cells
      // Use customized columns if customization is enabled, otherwise use original
      final columnsToUse = widget.enableColumnCustomization 
          ? _customizedColumns
          : widget.columns;
      
      if (columnsToUse.isNotEmpty) {
        columnsToUse.forEach((column) {
          final fieldValue = rowModel.fields[column.fieldName];
          
          DataCell cell;
          
          // Check if this is a price column that needs fixed width
          final isPriceColumn = column.fieldName == 'price' || 
                               column.fieldName == 'currentPrice' || 
                               
                               column.fieldName == 'addedPrice';
          
          // Check if the field value is a Widget (like TargetPriceCell)
          if (fieldValue is Widget) {
            Widget cellContent = Align(
              alignment: Alignment.centerLeft,
              child: fieldValue,
            );
            
            // Apply fixed width for price columns
            if (isPriceColumn) {
              cellContent = SizedBox(
                width: 65, // Fixed width for price columns
                child: cellContent,
              );
            }
            
            cell = DataCell(cellContent);
          } else {
            String cellData;
            // Format numeric price fields (like addedPrice) with currency symbol
            if ((fieldValue is num) && (column.fieldName == 'addedPrice' || column.fieldName == 'currentPrice' || column.fieldName == 'price')) {
              cellData = '\$${fieldValue.toStringAsFixed(2)}';
            } else if ((fieldValue is num) && column.fieldName == 'volume') {
              // Format volume in K, M, B format
              cellData = _formatVolume(fieldValue.toDouble());
            } else {
              cellData = fieldValue?.toString() ?? "-";
            }
            
            // Use stored text color or fallback to avoid context access during dispose
            Color textColor = _defaultTextColor ?? Colors.black;
            if (mounted) {
              // Try to get current theme color, but use fallback if context is unavailable
              try {
                final themeColor = Theme.of(context).textTheme.bodyLarge?.color;
                if (themeColor != null) {
                  textColor = themeColor;
                  _defaultTextColor = themeColor; // Update stored value
                }
              } catch (e) {
                // Context unavailable (during dispose), use stored value
              }
            }
            
            // Apply special styling for change column, price column, currentPrice column, and gainLoss column
            if ((column.fieldName == 'change' || column.fieldName == 'price' || 
                 column.fieldName == 'currentPrice' || column.fieldName == 'gainLoss') && 
                rowModel.changeColor != null) {
              textColor = rowModel.changeColor!;
            }
            
            // Determine if we should show +/- prefix for change/gainLoss columns and apply color coding
            String displayValue = cellData;
            
            // Check if this is a percentage or change field that should have color coding
            bool isPercentageField = column.fieldName.contains('change') || 
                                    column.fieldName.contains('Growth') || 
                                    column.fieldName.contains('Yield') ||
                                    column.fieldName.contains('Margin') ||
                                    column.fieldName.contains('YTD') ||
                                    column.fieldName.contains('marketCapChange') ||
                                    column.fieldName == 'change' || 
                                    column.fieldName == 'gainLoss';
            
            if (isPercentageField) {
              // Parse the numeric value to determine sign
              final numValue = double.tryParse(cellData.replaceAll(RegExp(r'[^\d.-]'), ''));
              if (numValue != null) {
                if (numValue > 0 && !cellData.startsWith('+')) {
                  displayValue = '+$cellData';
                } else if (numValue == 0 && !cellData.startsWith('+') && !cellData.startsWith('-')) {
                  displayValue = '+$cellData';
                }
                // Update color based on actual value
                if (numValue >= 0) {
                  textColor = Colors.green.shade600;
                } else {
                  textColor = Colors.red.shade600;
                }
              }
            }
            
            final textAlign = widget.centerCellContent
                ? TextAlign.center
                : TextAlign.left;

            Widget cellContent = widget.compactHeaderText
                ? AutoSizeText(
                    displayValue,
                    maxLines: 1,
                    minFontSize: 9,
                    textAlign: textAlign,
                    style: DashboardTextStyles.dataCell.copyWith(color: textColor),
                  )
                : Text(
                    displayValue,
                    textAlign: textAlign,
                    style: DashboardTextStyles.dataCell.copyWith(color: textColor),
                  );

            if (column.width != null) {
              cellContent = SizedBox(
                width: column.width,
                child: cellContent,
              );
            }
            
            // Apply fixed width for price columns to prevent shifting
            if (isPriceColumn) {
              cellContent = SizedBox(
                width: 65, // Fixed width for price columns
                child: Align(
                  alignment: widget.centerCellContent
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: cellContent,
                ),
              );
            } else {
              cellContent = Align(
                alignment: widget.centerCellContent
                    ? Alignment.center
                    : Alignment.centerLeft,
                child: cellContent,
              );
            }
            
            cell = DataCell(cellContent);
          }
          
          cellArr.add(cell);
        });
        dataRowLst.add(DataRow(
          color: _resolveRowColor(index),
          cells: cellArr,
        ));
      } else {
        // Add dummy row with single empty cell when no dynamic columns
        dataRowLst.add(DataRow(
          color: _resolveRowColor(index),
          cells: [DataCell(SizedBox.shrink())],
        ));
      }
    }

    setState(() {
      dataRows = dataRowLst;
      fixedDataRows = fixedRowLst;
    });
  }

  MaterialStateProperty<Color?>? _resolveRowColor(int index) {
    if (!widget.zebraStripes) return null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final evenColor = widget.evenRowColor ?? HomeUi.tableRowEven(isDarkMode);
    final oddColor = widget.oddRowColor ?? HomeUi.tableRowOdd(isDarkMode);
    final color = index.isEven ? evenColor : oddColor;
    return MaterialStateProperty.all(color);
  }

  String _formatVolume(double volume) {
    if (volume >= 1e9) {
      return '${(volume / 1e9).toStringAsFixed(1)}B';
    } else if (volume >= 1e6) {
      return '${(volume / 1e6).toStringAsFixed(1)}M';
    } else if (volume >= 1e3) {
      return '${(volume / 1e3).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
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