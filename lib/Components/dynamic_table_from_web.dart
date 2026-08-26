import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/table_pagination_bar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

/// Default gap between DataTable columns (was 40 — felt sparse).
const double _kDefaultColumnSpacing = 8;

// ============================================================================
// DATA MODELS
// ============================================================================

/// Column definition for dynamic table
class DynamicTableColumn {
  final String key;
  final String label;
  /// Full header name for tooltips when [label] is abbreviated.
  final String? tooltipLabel;
  final Widget? headerWidget;
  final double? width;
  final bool sortable;
  final bool filterable;
  final bool searchable;
  final bool pinnable;
  final String? filterType; // 'text' or 'select'
  final List<dynamic>? filterOptions;
  final bool Function(dynamic value, Map<String, dynamic> row)? render;
  final TextAlign align;
  final bool editable;

  const DynamicTableColumn({
    required this.key,
    required this.label,
    this.tooltipLabel,
    this.headerWidget,
    this.width,
    this.sortable = true,
    this.filterable = false,
    this.searchable = true,
    this.pinnable = true,
    this.filterType = 'text',
    this.filterOptions,
    this.render,
    this.align = TextAlign.left,
    this.editable = false,
  });

  String get fullLabel => (tooltipLabel ?? label).trim();
}

/// Row data model
class DynamicTableRow {
  final String id;
  final Map<String, dynamic> data;
  final bool? isSelectable;
  final bool isExpandable;
  final bool isExpanded;
  final List<DynamicTableRow>? children;
  final int level;

  const DynamicTableRow({
    required this.id,
    required this.data,
    this.isSelectable = true,
    this.isExpandable = false,
    this.isExpanded = false,
    this.children,
    this.level = 0,
  });

  DynamicTableRow copyWith({
    String? id,
    Map<String, dynamic>? data,
    bool? isSelectable,
    bool? isExpandable,
    bool? isExpanded,
    List<DynamicTableRow>? children,
    int? level,
  }) {
    return DynamicTableRow(
      id: id ?? this.id,
      data: data ?? this.data,
      isSelectable: isSelectable ?? this.isSelectable,
      isExpandable: isExpandable ?? this.isExpandable,
      isExpanded: isExpanded ?? this.isExpanded,
      children: children ?? this.children,
      level: level ?? this.level,
    );
  }
}

/// Sort state
class SortState {
  final String key;
  final String direction; // 'asc' or 'desc'

  SortState({required this.key, required this.direction});

  SortState copyWith({String? key, String? direction}) {
    return SortState(
      key: key ?? this.key,
      direction: direction ?? this.direction,
    );
  }
}

// ============================================================================
// DYNAMIC TABLE WIDGET
// ============================================================================

class DynamicTableFromWeb extends StatefulWidget {
  final List<DynamicTableColumn> columns;
  final List<DynamicTableRow> rows;
  final String? title;
  final String? subtitle;
  final IconData? toolbarLeadingIcon;
  final bool searchable;
  final bool paginated;
  final bool selectable;
  final bool enableColumnVisibilityToggle;
  final bool enableColumnReorder;
  final bool enableColumnPinning;
  final bool enableRowReorder;
  final bool enableColumnFilters;
  final bool stickyHeader;
  final bool showSortIndicators;
  final int pageSize;
  final double? maxHeight;
  final String rowKey;
  final Function(List<DynamicTableRow>)? onSelectionChange;
  final Function(String, String)? onSortChange;
  final Function(List<DynamicTableRow>)? onRowReorder;
  final Function(DynamicTableRow)? onRowDoubleClick;
  final Widget? toolbar;
  final Map<String, String>? columnFilter;
  final SortState? sortState;
  final bool manualPagination;
  final int totalRecords;
  final int currentPage;
  final Function(int)? onPageChange;
  final bool loading;
  final String emptyStateTitle;
  final String emptyStateDescription;
  final bool showTickerCell;
  final String tickerKey;
  final String companyKey;
  final String? logoKey;
  final String tickerHeaderLabel;
  final double? tickerColumnWidth;
  final Function(DynamicTableRow)? onTickerTap;
  final double headingRowHeight;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;
  final double horizontalMargin;
  final double? columnSpacing;
  final double? dividerThickness;
  final TableBorder? tableBorder;
  final bool showBottomBorder;
  final bool useOuterContainer;
  final bool showOuterShadow;
  final List<BoxShadow>? outerBoxShadow;
  final bool showColumnActionMenu;
  final bool showColumnResizeHandle;
  final double resizeHandleIndicatorHeight;
  final bool enforceColumnWidths;
  final List<String> initialPinnedLeftColumnKeys;
  final List<String> initialPinnedRightColumnKeys;
  final bool showYoYGrowth;
  final bool showThreeYearAvg;
  final bool showTwoYearCAGR;
  final bool showFiveYearCAGR;
  final bool showStandardDeviation;
  final double indentSize;
  final bool considerPadding;
  final bool showNameColumn;
  final double? rowHeight;
  final double? headerHeight;
  final bool compactPinnedLayout;
  final bool autoPinMetricColumn;
  final bool autoPinStatColumns;
  final bool showPinnedSectionDividers;
  final bool showHeaderTooltip;
  /// When true, visible columns expand to fill unused horizontal space.
  final bool enableColumnStretch;
  /// Optional override for header/cell horizontal insets inside each column.
  final EdgeInsets? columnCellPadding;
  /// Optional override for the title/toolbar row insets.
  final EdgeInsets? toolbarPadding;

  const DynamicTableFromWeb({
    Key? key,
    required this.columns,
    required this.rows,
    this.title,
    this.subtitle,
    this.toolbarLeadingIcon,
    this.searchable = true,
    this.paginated = true,
    this.selectable = false,
    this.enableColumnVisibilityToggle = true,
    this.enableColumnReorder = true,
    this.enableColumnPinning = true,
    this.enableRowReorder = true,
    this.enableColumnFilters = false,
    this.stickyHeader = true,
    this.showSortIndicators = false,
    this.pageSize = 10,
    this.maxHeight,
    this.rowKey = 'id',
    this.onSelectionChange,
    this.onSortChange,
    this.onRowReorder,
    this.onRowDoubleClick,
    this.toolbar,
    this.columnFilter,
    this.sortState,
    this.manualPagination = false,
    this.totalRecords = 0,
    this.currentPage = 1,
    this.onPageChange,
    this.loading = false,
    this.emptyStateTitle = 'No records found',
    this.emptyStateDescription =
        'Try adjusting filters or searching with different keywords.',
    this.showTickerCell = false,
    this.tickerKey = 'ticker',
    this.companyKey = 'company',
    this.logoKey,
    this.tickerHeaderLabel = 'Ticker',
    this.tickerColumnWidth,
    this.onTickerTap,
    this.headingRowHeight = 44,
    this.dataRowMinHeight = 48,
    this.dataRowMaxHeight = 48,
    this.horizontalMargin = 16,
    this.columnSpacing,
    this.dividerThickness,
    this.tableBorder,
    this.showBottomBorder = false,
    this.useOuterContainer = true,
    this.showOuterShadow = false,
    this.outerBoxShadow,
    this.showColumnActionMenu = true,
    this.showColumnResizeHandle = true,
    this.resizeHandleIndicatorHeight = 18,
    this.enforceColumnWidths = true,
    this.initialPinnedLeftColumnKeys = const <String>[],
    this.initialPinnedRightColumnKeys = const <String>[],
    this.showYoYGrowth = false,
    this.showThreeYearAvg = false,
    this.showTwoYearCAGR = false,
    this.showFiveYearCAGR = false,
    this.showStandardDeviation = false,
    this.indentSize = 20,
    this.considerPadding = false,
    this.showNameColumn = true,
    this.rowHeight,
    this.headerHeight,
    this.compactPinnedLayout = false,
    this.autoPinMetricColumn = true,
    this.autoPinStatColumns = true,
    this.showPinnedSectionDividers = true,
    this.showHeaderTooltip = true,
    this.enableColumnStretch = true,
    this.columnCellPadding,
    this.toolbarPadding,
  }) : super(key: key);

  @override
  State<DynamicTableFromWeb> createState() => _DynamicTableFromWebState();
}

class _DynamicTableFromWebState extends State<DynamicTableFromWeb> {
  late List<String> _columnOrder;
  late Set<String> _visibleColumns;
  late Set<String> _selectedRowIds;
  late Map<String, dynamic> _columnFilterValues;
  late Map<String, double> _columnWidths;
  late int _currentPage;
  late int _pageSize;
  late SortState? _sortState;
  late final ScrollController _horizontalScrollController;
  late final ScrollController _verticalScrollController;

  String? _draggingColumnKey;
  String? _dragOverColumnKey;
  String? _hoveredResizeColumnKey;
  String? _hoveredRowId;
  int _rowHoverGeneration = 0;
  final Set<String> _pinnedLeftColumns = <String>{};
  final Set<String> _pinnedRightColumns = <String>{};
  final Map<String, double> _naturalMinWidths = <String, double>{};
  final Set<String> _expandedRowIds = <String>{};

  @override
  void initState() {
    super.initState();
    _columnOrder = _getEffectiveColumns().map((c) => c.key).toList();
    _visibleColumns = Set.from(_columnOrder);
    _selectedRowIds = <String>{};
    _columnFilterValues = <String, dynamic>{};
    _columnWidths = <String, double>{};
    _currentPage = widget.currentPage;
    _pageSize = widget.pageSize;
    _sortState = widget.sortState;
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _pinnedLeftColumns.addAll(widget.initialPinnedLeftColumnKeys);
    _pinnedRightColumns.addAll(widget.initialPinnedRightColumnKeys);
    _initializeExpandedRows(widget.rows);
  }

  @override
  void didUpdateWidget(DynamicTableFromWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortState != widget.sortState) {
      _sortState = widget.sortState;
    }
    if (oldWidget.currentPage != widget.currentPage) {
      _currentPage = widget.currentPage;
    }
    if (oldWidget.pageSize != widget.pageSize) {
      _pageSize = widget.pageSize;
    }
    if (oldWidget.columns != widget.columns ||
        oldWidget.showYoYGrowth != widget.showYoYGrowth ||
        oldWidget.showThreeYearAvg != widget.showThreeYearAvg ||
        oldWidget.showTwoYearCAGR != widget.showTwoYearCAGR ||
        oldWidget.showFiveYearCAGR != widget.showFiveYearCAGR ||
        oldWidget.showStandardDeviation != widget.showStandardDeviation) {
      final effectiveKeys = _getEffectiveColumns().map((c) => c.key).toSet();
      final nextOrder = <String>[];
      for (final key in _columnOrder) {
        if (effectiveKeys.contains(key)) {
          nextOrder.add(key);
        }
      }
      for (final col in _getEffectiveColumns()) {
        if (!nextOrder.contains(col.key)) {
          nextOrder.add(col.key);
        }
      }
      _columnOrder = nextOrder;
      _visibleColumns = _visibleColumns.intersection(effectiveKeys);
      _visibleColumns.addAll(nextOrder);
      _naturalMinWidths.clear();
    }
    if (oldWidget.rows != widget.rows) {
      _initializeExpandedRows(widget.rows);
      _naturalMinWidths.clear();
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
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

  List<DynamicTableColumn> _getEffectiveColumns() {
    final columns = <DynamicTableColumn>[...widget.columns];
    final existingKeys = columns.map((c) => c.key).toSet();

    DynamicTableColumn statColumn(String key, String label) {
      return DynamicTableColumn(
        key: key,
        label: label,
        width: 110,
        sortable: true,
        searchable: false,
        pinnable: true,
        align: TextAlign.right,
      );
    }

    if (widget.showYoYGrowth && !existingKeys.contains('yoy_growth')) {
      columns.add(statColumn('yoy_growth', 'YoY Growth'));
    }
    if (widget.showThreeYearAvg && !existingKeys.contains('three_year_avg')) {
      columns.add(statColumn('three_year_avg', '3-Year Avg'));
    }
    if (widget.showTwoYearCAGR && !existingKeys.contains('two_year_cagr')) {
      columns.add(statColumn('two_year_cagr', '2Y CAGR'));
    }
    if (widget.showFiveYearCAGR && !existingKeys.contains('five_year_cagr')) {
      columns.add(statColumn('five_year_cagr', '5Y CAGR'));
    }
    if (widget.showStandardDeviation &&
        !existingKeys.contains('standard_deviation')) {
      columns.add(statColumn('standard_deviation', 'Std Dev'));
    }

    return columns;
  }

  Set<String> _getEnabledStatColumnKeys() {
    final keys = <String>{};
    if (widget.showYoYGrowth) keys.add('yoy_growth');
    if (widget.showThreeYearAvg) keys.add('three_year_avg');
    if (widget.showTwoYearCAGR) keys.add('two_year_cagr');
    if (widget.showFiveYearCAGR) keys.add('five_year_cagr');
    if (widget.showStandardDeviation) keys.add('standard_deviation');
    return keys;
  }

  double get _headerActionReserve => widget.showColumnActionMenu ? 20 : 0;
  double get _headerResizeReserve => widget.showColumnResizeHandle ? 8 : 0;
  double get _headerTrailing => 8 + _headerActionReserve + _headerResizeReserve;
  static const double _headerLeading = 8;

  bool _isEndAlign(TextAlign align) =>
      align == TextAlign.right || align == TextAlign.end;

  bool _isCenterAlign(TextAlign align) => align == TextAlign.center;

  Alignment _alignmentFor(TextAlign align) {
    if (_isEndAlign(align)) return Alignment.centerRight;
    if (_isCenterAlign(align)) return Alignment.center;
    return Alignment.centerLeft;
  }

  MainAxisAlignment _headingAlignmentFor(TextAlign align) {
    if (_isEndAlign(align)) return MainAxisAlignment.end;
    if (_isCenterAlign(align)) return MainAxisAlignment.center;
    return MainAxisAlignment.start;
  }

  EdgeInsets _columnInsets() {
    return widget.columnCellPadding ??
        EdgeInsets.only(left: _headerLeading, right: _headerTrailing);
  }

  double get _effectiveHeadingRowHeight =>
      widget.headerHeight ?? widget.headingRowHeight;

  double get _effectiveDataRowHeight =>
      widget.rowHeight ?? widget.dataRowMaxHeight;

  void _initializeExpandedRows(List<DynamicTableRow> rows) {
    void collect(List<DynamicTableRow> input) {
      for (final row in input) {
        if (row.isExpandable && row.isExpanded) {
          _expandedRowIds.add(row.id);
        }
        if (row.children != null && row.children!.isNotEmpty) {
          collect(row.children!);
        }
      }
    }

    _expandedRowIds.clear();
    collect(rows);
  }

  void _toggleRowExpansion(DynamicTableRow row) {
    if (!row.isExpandable) return;
    setState(() {
      if (_expandedRowIds.contains(row.id)) {
        _expandedRowIds.remove(row.id);
      } else {
        _expandedRowIds.add(row.id);
      }
    });
  }

  List<DynamicTableRow> _flattenRows(List<DynamicTableRow> rows,
      {int level = 0}) {
    final flattened = <DynamicTableRow>[];

    for (final row in rows) {
      final currentLevel = row.level > 0 ? row.level : level;
      final normalized = row.copyWith(level: currentLevel);
      flattened.add(normalized);

      if (normalized.isExpandable &&
          normalized.children != null &&
          normalized.children!.isNotEmpty &&
          _expandedRowIds.contains(normalized.id)) {
        flattened.addAll(
            _flattenRows(normalized.children!, level: currentLevel + 1));
      }
    }

    return flattened;
  }

  List<DynamicTableRow> _getFilteredRows() {
    var filtered = widget.rows;

    // Apply column filters
    if (widget.enableColumnFilters &&
        _columnFilterValues.values
            .any((v) => v != null && v.toString().trim().isNotEmpty)) {
      filtered = filtered.where((row) {
        return widget.columns.where((col) => col.filterable).every((col) {
          final filterVal = _columnFilterValues[col.key];
          if (filterVal == null || filterVal.toString().trim().isEmpty) {
            return true;
          }
          final cellValue = row.data[col.key];
          if (cellValue == null) return false;
          return cellValue.toString().contains(filterVal.toString());
        });
      }).toList();
    }

    return filtered;
  }

  List<DynamicTableRow> _getSortedRows(List<DynamicTableRow> rows) {
    if (_sortState == null) return rows;
    final sortCol = _getEffectiveColumns()
        .firstWhereOrNull((c) => c.key == _sortState!.key);
    if (sortCol == null) return rows;

    return _sortRowsRecursively(rows, sortCol);
  }

  List<DynamicTableRow> _sortRowsRecursively(
    List<DynamicTableRow> rows,
    DynamicTableColumn sortCol,
  ) {
    final sorted = [...rows];

    sorted.sort((a, b) {
      final aVal = _extractComparableValue(a.data[sortCol.key]);
      final bVal = _extractComparableValue(b.data[sortCol.key]);
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return 1;
      if (bVal == null) return -1;

      final cmp = _compareValues(aVal, bVal);
      return _sortState!.direction == 'asc' ? cmp : -cmp;
    });

    return sorted.map((row) {
      final children = row.children;
      if (children == null || children.isEmpty) {
        return row;
      }
      return row.copyWith(children: _sortRowsRecursively(children, sortCol));
    }).toList();
  }

  dynamic _extractComparableValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = _parseNumericString(value);
      return parsed ?? value.toLowerCase();
    }
    if (value is Text) {
      final text = value.data ?? value.textSpan?.toPlainText();
      if (text == null) return null;
      final parsed = _parseNumericString(text);
      return parsed ?? text.toLowerCase();
    }
    if (value is Padding) {
      return _extractComparableValue(value.child);
    }
    if (value is Align) {
      return _extractComparableValue(value.child);
    }
    if (value is Center) {
      return _extractComparableValue(value.child);
    }
    if (value is Container) {
      return _extractComparableValue(value.child);
    }
    if (value is SizedBox) {
      return _extractComparableValue(value.child);
    }
    if (value is GestureDetector) {
      return _extractComparableValue(value.child);
    }
    return value.toString().toLowerCase();
  }

  double? _parseNumericString(String value) {
    final normalized = value
        .replaceAll(',', '')
        .replaceAll('%', '')
        .replaceAll('\$', '')
        .replaceAll('−', '-')
        .trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }
    return a.toString().compareTo(b.toString());
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  double _cellRightPadding(DynamicTableColumn col) {
    return _headerTrailing;
  }

  void _refreshNaturalMinWidths(List<DynamicTableColumn> columns) {
    final headerStyle = HomeUi.tableHeader(false);
    final cellStyle = HomeUi.tableCell(false).copyWith(
      fontWeight: FontWeight.w600,
    );
    const double maxShortContentWidth = 160;
    const double maxLabelContentWidth = 260;

    for (final col in columns) {
      final headerWidth = _measureTextWidth(
        HomeUi.shortTableHeader(
          label: col.fullLabel.toUpperCase(),
          key: col.key,
        ).toUpperCase(),
        headerStyle,
      );
      // Content/header driven — do not floor at col.width or every numeric
      // column inherits the same large preferred width and looks identical.
      var minWidth = headerWidth + 8 + _headerTrailing + 4;
      final double contentCap = HomeUi.isWideLabelTableColumn(col.key)
          ? maxLabelContentWidth
          : maxShortContentWidth;

      for (final row in widget.rows) {
        final value = row.data[col.key];
        if (value == null || value is Widget) continue;
        final text = value.toString().trim();
        if (text.isEmpty || text == '--' || text == '—') continue;
        if (HomeUi.isCommentLikeTableText(text, columnKey: col.key)) continue;
        final contentWidth =
            _measureTextWidth(text, cellStyle) + 8 + _cellRightPadding(col);
        if (contentWidth > minWidth) {
          minWidth =
              contentWidth > contentCap ? contentCap : contentWidth;
        }
      }
      // Prefer explicit width as a floor for wide label columns (e.g. Sector).
      if (col.width != null &&
          HomeUi.isWideLabelTableColumn(col.key) &&
          col.width! > minWidth) {
        minWidth = col.width!;
      }
      // Price must show full values (e.g. $213.45) — never squeeze under content.
      if (HomeUi.isPriceTableColumn(col.key)) {
        const double priceFloor = 100;
        if (minWidth < priceFloor) minWidth = priceFloor;
        if (col.width != null && col.width! > minWidth) {
          minWidth = col.width!;
        }
      }
      // Compact enum cols (REC / Buy) stay content-tight — ignore large presets.
      if (HomeUi.isCompactTableColumn(col.key)) {
        final double headerOnly = headerWidth + 8 + _headerTrailing + 4;
        final double contentOnly = minWidth;
        minWidth = contentOnly < 88 ? contentOnly.clamp(headerOnly, 88) : 88;
      }
      _naturalMinWidths[col.key] = minWidth;
    }
  }

  double _getNaturalMinWidth(DynamicTableColumn col) {
    return _naturalMinWidths[col.key] ?? col.width ?? 96;
  }

  double _resolveColumnWidth(DynamicTableColumn col) {
    final minWidth = _getNaturalMinWidth(col);
    final stretched = _stretchedColumnWidths[col.key];
    if (stretched != null) return stretched;
    // Manual resize only — ignore static col.width so columns pack to content
    // and stretch fills leftover table width when columns are few.
    if (_columnWidths.containsKey(col.key)) {
      final double w = _columnWidths[col.key]!;
      return w < minWidth ? minWidth : w;
    }
    return minWidth;
  }

  /// Stretched widths computed per-frame so visible columns fill available space.
  Map<String, double> _stretchedColumnWidths = <String, double>{};

  void _computeStretchedWidths(
    List<DynamicTableColumn> columns,
    double availableWidth, {
    bool includeTicker = false,
  }) {
    _stretchedColumnWidths = <String, double>{};
    if (!widget.enableColumnStretch || columns.isEmpty) return;

    // Natural mins must be fresh before we share leftover width.
    _refreshNaturalMinWidths(columns);

    // Account for ticker column, horizontal margins, and DataTable spacing.
    final double spacing = widget.columnSpacing ?? _kDefaultColumnSpacing;
    double reserved = widget.horizontalMargin * 2;
    if (includeTicker) {
      reserved += (widget.tickerColumnWidth ?? 200) + 8;
    }
    reserved += spacing * (columns.length - 1).clamp(0, 999);
    final usable = availableWidth - reserved;
    if (usable <= 0) return;

    final baseWidths = <String, double>{};
    double totalStretchBase = 0;
    double compactReserved = 0;
    for (final col in columns) {
      final base = _getNaturalMinWidth(col);
      baseWidths[col.key] = base;
      if (HomeUi.isCompactTableColumn(col.key)) {
        compactReserved += base;
        _stretchedColumnWidths[col.key] = base; // no stretch share
      } else {
        totalStretchBase += base;
      }
    }

    if (totalStretchBase <= 0) return;
    final usableForStretch = usable - compactReserved;
    if (usableForStretch <= totalStretchBase) return;

    final extra = usableForStretch - totalStretchBase;
    for (final col in columns) {
      if (HomeUi.isCompactTableColumn(col.key)) continue;
      final base = baseWidths[col.key]!;
      final share = base / totalStretchBase;
      _stretchedColumnWidths[col.key] = base + extra * share;
    }
  }

  void _handleColumnDrop(String targetColumnKey) {
    if (!widget.enableColumnReorder || _draggingColumnKey == null) return;
    if (_draggingColumnKey == targetColumnKey) return;

    final fromIndex = _columnOrder.indexOf(_draggingColumnKey!);
    final toIndex = _columnOrder.indexOf(targetColumnKey);
    if (fromIndex < 0 || toIndex < 0) return;

    setState(() {
      final next = [..._columnOrder];
      final moved = next.removeAt(fromIndex);
      next.insert(toIndex, moved);
      _columnOrder = next;
      _draggingColumnKey = null;
      _dragOverColumnKey = null;
    });
  }

  void _applyColumnAction(DynamicTableColumn col, String action) {
    setState(() {
      switch (action) {
        case 'sort_asc':
          if (!col.sortable) return;
          _sortState = SortState(key: col.key, direction: 'asc');
          widget.onSortChange?.call(_sortState!.key, _sortState!.direction);
          break;
        case 'sort_desc':
          if (!col.sortable) return;
          _sortState = SortState(key: col.key, direction: 'desc');
          widget.onSortChange?.call(_sortState!.key, _sortState!.direction);
          break;
        case 'pin_left':
          _pinnedRightColumns.remove(col.key);
          _pinnedLeftColumns.add(col.key);
          break;
        case 'pin_right':
          _pinnedLeftColumns.remove(col.key);
          _pinnedRightColumns.add(col.key);
          break;
        case 'unpin':
          _pinnedLeftColumns.remove(col.key);
          _pinnedRightColumns.remove(col.key);
          break;
      }
    });
  }

  Widget _buildColumnActionMenu(
    BuildContext context,
    DynamicTableColumn col,
    Color iconColor,
  ) {
    if (!widget.showColumnActionMenu) {
      return const SizedBox.shrink();
    }

    final isPinned = _pinnedLeftColumns.contains(col.key) ||
        _pinnedRightColumns.contains(col.key);
    PopupMenuItem<String> menuItem({
      required String value,
      required IconData icon,
      required String label,
      bool enabled = true,
    }) {
      return PopupMenuItem<String>(
        value: value,
        enabled: enabled,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  enabled ? const Color(0xFF1F2937) : const Color(0xFFD1D5DB),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color:
                    enabled ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: widget.showHeaderTooltip ? 'Column actions' : '',
      onSelected: (value) => _applyColumnAction(col, value),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 180),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      padding: EdgeInsets.zero,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Icon(
            Icons.more_vert,
            size: 16,
            color: iconColor,
          ),
        ),
      ),
      itemBuilder: (context) => [
        menuItem(
            value: 'sort_asc',
            icon: Icons.north,
            label: 'Sort Ascending',
            enabled: col.sortable),
        menuItem(
            value: 'sort_desc',
            icon: Icons.south,
            label: 'Sort Descending',
            enabled: col.sortable),
        menuItem(
            value: 'pin_left',
            icon: Icons.push_pin_outlined,
            label: 'Pin Left',
            enabled: widget.enableColumnPinning),
        menuItem(
            value: 'pin_right',
            icon: Icons.push_pin_outlined,
            label: 'Pin Right',
            enabled: widget.enableColumnPinning),
        menuItem(
            value: 'unpin',
            icon: Icons.vertical_align_center,
            label: 'Unpin',
            enabled: widget.enableColumnPinning && isPinned),
      ],
    );
  }

  Widget _buildTickerCell(
      DynamicTableRow row, Color textColor, Color mutedColor) {
    final ticker = (row.data[widget.tickerKey]?.toString() ?? '').trim();
    final company = (row.data[widget.companyKey]?.toString() ?? '').trim();
    final logoUrl = widget.logoKey != null
        ? row.data[widget.logoKey!]?.toString() ?? ''
        : '';
    final hasTicker = ticker.isNotEmpty && ticker != '--';
    final hasCompany = company.isNotEmpty && company != '--';
    final sameLabel = hasTicker &&
        hasCompany &&
        ticker.toLowerCase() == company.toLowerCase();
    final showTickerSubtitle = hasTicker && hasCompany && !sameLabel;
    final fullTitle = (hasCompany ? company : (hasTicker ? ticker : '--'))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final tickerSubtitle = showTickerSubtitle
        ? (fullTitle.toLowerCase() == company.toLowerCase() ? ticker : company)
        : '';
    final split = showTickerSubtitle
        ? (title: fullTitle, subtitle: tickerSubtitle)
        : _splitSingleLabel(fullTitle);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: showLogo(
            hasTicker ? ticker : fullTitle,
            logoUrl,
            sideWidth: 32,
            circular: true,
            name: fullTitle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeUi.premiumTooltip(
            message: fullTitle,
            waitDuration: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  HomeUi.truncateTableText(split.title),
                  maxLines: 1,
                  overflow: HomeUi.tableCellOverflow(split.title),
                  style: HomeUi.tableCellEmphasis(isDark),
                ),
                if (split.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    HomeUi.truncateTableText(split.subtitle),
                    maxLines: 1,
                    overflow: HomeUi.tableCellOverflow(split.subtitle),
                    style: HomeUi.tableCellSecondary(isDark).copyWith(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  ({String title, String subtitle}) _splitSingleLabel(String name) {
    if (name.length <= 22) return (title: name, subtitle: '');
    var idx = name.lastIndexOf(' ', 22);
    if (idx < 8) idx = name.indexOf(' ', 8);
    if (idx < 0) return (title: name, subtitle: '');
    final title = name.substring(0, idx).trim();
    final subtitle = name.substring(idx).trim();
    if (title.isEmpty || subtitle.isEmpty) {
      return (title: name, subtitle: '');
    }
    return (title: title, subtitle: subtitle);
  }

  Widget _maybeHeaderTooltip(String message, Widget child) {
    // Header label owns premium tooltips (short name → full name on hover).
    return child;
  }

  Widget _headerLabel({
    required DynamicTableColumn col,
    required TextStyle headerStyle,
  }) {
    final sorted = _sortState?.key == col.key;
    final fullLabel = col.fullLabel.toUpperCase();
    final displayLabel = HomeUi.shortTableHeader(
      label: fullLabel,
      key: col.key,
    ).toUpperCase();
    Widget label = col.headerWidget ??
        Text(
          displayLabel,
          style: headerStyle,
          textAlign: col.align,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        );

    if (sorted && widget.showSortIndicators) {
      final icon = Icon(
        _sortState!.direction == 'asc'
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        size: 11,
        color: headerStyle.color,
      );
      label = Row(
        mainAxisSize: MainAxisSize.min,
        children: _isEndAlign(col.align)
            ? [icon, const SizedBox(width: 4), label]
            : [label, const SizedBox(width: 4), icon],
      );
    }

    // Short / sorted headers: hover shows the full original name.
    if (col.headerWidget == null &&
        (sorted ||
            widget.showHeaderTooltip ||
            displayLabel != fullLabel)) {
      label = HomeUi.premiumTooltip(message: fullLabel, child: label);
    }
    return label;
  }

  DataColumn _buildHeaderColumn(
    BuildContext context,
    DynamicTableColumn col,
    Color mutedColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerStyle = HomeUi.tableHeader(isDark);
    final headerTextColor = headerStyle.color ?? mutedColor;
    final resolvedWidth =
        widget.enforceColumnWidths ? _resolveColumnWidth(col) : null;

    return DataColumn(
      numeric: _isEndAlign(col.align),
      headingRowAlignment: _headingAlignmentFor(col.align),
      label: _maybeHeaderTooltip(
        col.fullLabel.toUpperCase(),
        DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            if (!widget.enableColumnReorder) return false;
            final canAccept = details.data != col.key;
            if (canAccept) {
              setState(() {
                _dragOverColumnKey = col.key;
              });
            }
            return canAccept;
          },
          onLeave: (data) {
            if (_dragOverColumnKey == col.key) {
              setState(() {
                _dragOverColumnKey = null;
              });
            }
          },
          onAcceptWithDetails: (details) {
            _handleColumnDrop(col.key);
          },
          builder: (context, candidateData, rejectedData) {
            final isDragOver = _dragOverColumnKey == col.key;
            return Draggable<String>(
              data: col.key,
              maxSimultaneousDrags: widget.enableColumnReorder ? 1 : 0,
              onDragStarted: () {
                setState(() {
                  _draggingColumnKey = col.key;
                });
              },
              onDragEnd: (_) {
                setState(() {
                  _draggingColumnKey = null;
                  _dragOverColumnKey = null;
                });
              },
              onDraggableCanceled: (_, __) {
                setState(() {
                  _draggingColumnKey = null;
                  _dragOverColumnKey = null;
                });
              },
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    col.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.45,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    col.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ),
              child: MouseRegion(
                onHover: (_) {
                  if (_draggingColumnKey != null &&
                      _draggingColumnKey != col.key) {
                    setState(() {
                      _dragOverColumnKey = col.key;
                    });
                  }
                },
                onExit: (_) {
                  if (_dragOverColumnKey == col.key &&
                      _draggingColumnKey != null) {
                    setState(() {
                      _dragOverColumnKey = null;
                    });
                  }
                },
                cursor:
                    col.sortable ? SystemMouseCursors.click : MouseCursor.defer,
                  child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: col.sortable
                      ? () {
                          setState(() {
                            if (_sortState?.key == col.key) {
                              _sortState = SortState(
                                key: col.key,
                                direction: _sortState!.direction == 'asc'
                                    ? 'desc'
                                    : 'asc',
                              );
                            } else {
                              _sortState =
                                  SortState(key: col.key, direction: 'asc');
                            }
                          });
                          widget.onSortChange?.call(
                            _sortState!.key,
                            _sortState!.direction,
                          );
                        }
                      : null,
                  child: Align(
                    alignment: _alignmentFor(col.align),
                    child: SizedBox(
                    width: resolvedWidth,
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.zero,
                          decoration: isDragOver
                              ? BoxDecoration(
                                  color:
                                      const Color(0xFF3B82F6).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: Stack(
                            children: [
                              Align(
                                alignment: _alignmentFor(col.align),
                                child: Padding(
                                  padding: _columnInsets(),
                                  child: _headerLabel(
                                    col: col,
                                    headerStyle: headerStyle,
                                  ),
                                ),
                              ),
                              if (widget.showColumnActionMenu)
                                Positioned(
                                  right: _headerResizeReserve,
                                  top: 0,
                                  bottom: 0,
                                  child: SizedBox(
                                    width: 20,
                                    height: 24,
                                    child: _buildColumnActionMenu(
                                      context,
                                      col,
                                      headerTextColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.showColumnResizeHandle &&
                            widget.enforceColumnWidths)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeColumn,
                              onEnter: (_) {
                                setState(() {
                                  _hoveredResizeColumnKey = col.key;
                                });
                              },
                              onExit: (_) {
                                if (_hoveredResizeColumnKey == col.key) {
                                  setState(() {
                                    _hoveredResizeColumnKey = null;
                                  });
                                }
                              },
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragUpdate: (details) {
                                  final minWidth = _getNaturalMinWidth(col);
                                  final currentWidth = _columnWidths[col.key] ??
                                      col.width ??
                                      minWidth;
                                  final nextWidth =
                                      (currentWidth + details.delta.dx)
                                          .clamp(minWidth, double.infinity)
                                          .toDouble();
                                  setState(() {
                                    _columnWidths[col.key] = nextWidth;
                                  });
                                },
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 120),
                                  opacity: _hoveredResizeColumnKey == col.key
                                      ? 1
                                      : 0.45,
                                  child: SizedBox(
                                    width: 8,
                                    child: Center(
                                      child: Container(
                                        width: 1.5,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: HomeUi.borderStrong(
                                            Theme.of(context).brightness ==
                                                Brightness.dark,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<DataCell> _buildRowCellsForColumns(
    DynamicTableRow row,
    List<DynamicTableColumn> columns,
    Color textColor,
    String? expanderColumnKey,
  ) {
    return columns.map((col) {
      final value = row.data[col.key];
      final resolvedWidth =
          widget.enforceColumnWidths ? _resolveColumnWidth(col) : null;
      final cellText = value?.toString() ?? '--';
      final isDark = Theme.of(context).brightness == Brightness.dark;
      Widget defaultCell;

      if (value is Widget) {
        defaultCell = SizedBox(
          height: _effectiveDataRowHeight,
          child: Align(
            alignment: _alignmentFor(col.align),
            child: value,
          ),
        );
      } else {
        final parsed = _parseNumericString(cellText);
        final looksPercent = cellText.contains('%');
        final looksSigned = cellText.startsWith('+') ||
            cellText.startsWith('-') ||
            cellText.startsWith('−');
        final isEmpty = cellText == '--' || cellText == '—';
        final isEmphasis = HomeUi.isEmphasisTableColumn(col.key);
        final isSecondary = HomeUi.isSecondaryTableColumn(col.key);

        TextStyle style;
        if (isEmpty) {
          style = HomeUi.tableCellSecondary(isDark);
        } else if (isEmphasis) {
          style = HomeUi.tableCellEmphasis(isDark);
        } else if (isSecondary) {
          style = HomeUi.tableCellSecondary(isDark);
        } else if (parsed != null && looksPercent) {
          style = HomeUi.tableNumeric(isDark);
        } else if (col.align == TextAlign.right || parsed != null) {
          style = HomeUi.tableCell(isDark).copyWith(
            color: HomeUi.body(isDark),
            fontWeight: FontWeight.w600,
          );
        } else {
          style = HomeUi.tableCell(isDark).copyWith(color: textColor);
        }

        if (parsed != null && looksSigned) {
          defaultCell = Align(
            alignment: _alignmentFor(col.align),
            child: HomeUi.signedPercentPill(isDark, cellText, parsed),
          );
        } else if (cellText.toLowerCase() == 'buy' ||
            cellText.toLowerCase() == 'sell') {
          final isBuy = cellText.toLowerCase() == 'buy';
          defaultCell = Align(
            alignment: _alignmentFor(col.align),
            child: HomeUi.signedPercentPill(
              isDark,
              cellText,
              isBuy ? 1 : -1,
            ),
          );
        } else {
          final commentLike =
              HomeUi.isCommentLikeTableText(cellText, columnKey: col.key);
          final isPrice = HomeUi.isPriceTableColumn(col.key);
          // Keep sector / industry / labels intact — only truncate long prose.
          // Never character-truncate prices.
          final String displayText = (commentLike && !isPrice)
              ? HomeUi.truncateTableText(cellText, columnKey: col.key)
              : cellText;
          Widget text = Text(
            displayText,
            maxLines: 1,
            softWrap: false,
            overflow: HomeUi.tableCellOverflow(cellText, columnKey: col.key),
            textAlign: col.align,
            style: style,
          );
          if (commentLike || displayText != cellText) {
            text = HomeUi.premiumTooltip(
              message: cellText,
              waitDuration: const Duration(milliseconds: 400),
              child: text,
            );
          }
          defaultCell = Align(
            alignment: _alignmentFor(col.align),
            child: text,
          );
        }
      }

      final isExpanderColumn =
          expanderColumnKey != null && col.key == expanderColumnKey;

      final content = isExpanderColumn && (row.isExpandable || row.level > 0)
          ? Padding(
              padding: EdgeInsets.only(left: row.level * widget.indentSize),
              child: Row(
                children: [
                  if (row.isExpandable)
                    Icon(
                      _expandedRowIds.contains(row.id)
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: textColor,
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 4),
                  Expanded(child: defaultCell),
                ],
              ),
            )
          : defaultCell;

      return DataCell(
        _wrapRowHover(
          row.id,
          Align(
            alignment: _alignmentFor(col.align),
            child: SizedBox(
              width: resolvedWidth,
              height: _effectiveDataRowHeight,
              child: Padding(
                padding: _columnInsets(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.basic,
                  child: content,
                ),
              ),
            ),
          ),
        ),
        onTap: (isExpanderColumn && row.isExpandable)
            ? () => _toggleRowExpansion(row)
            : widget.onRowDoubleClick != null
                ? () => widget.onRowDoubleClick!(row)
                : null,
      );
    }).toList();
  }

  /// Horizontally scrollable center columns, width-clamped so [AnimatedSize]
  /// cannot expand past the flex slot and trigger RIGHT OVERFLOWED.
  Widget _buildScrollableCenterSection({
    required List<DynamicTableColumn> centerColumns,
    required List<DynamicTableRow> paginatedRows,
    required Color textColor,
    required Color mutedColor,
    required String? expanderColumnKey,
  }) {
    if (centerColumns.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        if (availableW <= 0) return const SizedBox.shrink();

        _computeStretchedWidths(centerColumns, availableW);
        return SizedBox(
          width: availableW,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubicEmphasized,
            alignment: Alignment.topLeft,
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              trackVisibility: false,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: availableW),
                  child: _buildAnimatedTableSection(
                    key: ValueKey<String>(
                      'center:${centerColumns.map((c) => c.key).join('|')}',
                    ),
                    child: _buildTableSection(
                      context: context,
                      columns: centerColumns,
                      rows: paginatedRows,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      expanderColumnKey: expanderColumnKey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinnedScrollBody({
    required BuildContext context,
    required Color bgColor,
    required Color borderColor,
    required List<DynamicTableColumn> leftPinnedColumns,
    required List<DynamicTableColumn> centerColumns,
    required List<DynamicTableColumn> rightPinnedColumns,
    required List<DynamicTableRow> paginatedRows,
    required Color textColor,
    required Color mutedColor,
    required String? expanderColumnKey,
  }) {
    final row = Row(
      mainAxisSize: widget.compactPinnedLayout
          ? MainAxisSize.min
          : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPinnedSectionSlot(
          slotKey: 'left',
          visible: widget.selectable ||
              widget.showTickerCell ||
              leftPinnedColumns.isNotEmpty,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: widget.showPinnedSectionDividers
                  ? Border(right: BorderSide(color: borderColor))
                  : null,
            ),
            child: _buildAnimatedTableSection(
              key: ValueKey<String>(
                'left:${leftPinnedColumns.map((c) => c.key).join('|')}:${widget.selectable}:${widget.showTickerCell}',
              ),
              child: _buildTableSection(
                context: context,
                columns: leftPinnedColumns,
                rows: paginatedRows,
                textColor: textColor,
                mutedColor: mutedColor,
                expanderColumnKey: expanderColumnKey,
                includeSelectable: widget.selectable,
                includeTicker: widget.showTickerCell,
              ),
            ),
          ),
        ),
        if (widget.compactPinnedLayout)
          Flexible(
            fit: FlexFit.loose,
            child: _buildScrollableCenterSection(
              centerColumns: centerColumns,
              paginatedRows: paginatedRows,
              textColor: textColor,
              mutedColor: mutedColor,
              expanderColumnKey: expanderColumnKey,
            ),
          )
        else
          Expanded(
            child: _buildScrollableCenterSection(
              centerColumns: centerColumns,
              paginatedRows: paginatedRows,
              textColor: textColor,
              mutedColor: mutedColor,
              expanderColumnKey: expanderColumnKey,
            ),
          ),
        _buildPinnedSectionSlot(
          slotKey: 'right',
          visible: rightPinnedColumns.isNotEmpty,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: widget.showPinnedSectionDividers
                  ? Border(left: BorderSide(color: borderColor))
                  : null,
            ),
            child: _buildAnimatedTableSection(
              key: ValueKey<String>(
                'right:${rightPinnedColumns.map((c) => c.key).join('|')}',
              ),
              child: _buildTableSection(
                context: context,
                columns: rightPinnedColumns,
                rows: paginatedRows,
                textColor: textColor,
                mutedColor: mutedColor,
                expanderColumnKey: expanderColumnKey,
              ),
            ),
          ),
        ),
      ],
    );

    // Null maxHeight: no outer vertical scroll — keeps Row width bounded.
    final maxH = widget.maxHeight;
    if (maxH == null) return row;

    return SizedBox(
      height: maxH,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: row,
      ),
    );
  }

  Widget _buildTableSection({
    required BuildContext context,
    required List<DynamicTableColumn> columns,
    required List<DynamicTableRow> rows,
    required Color textColor,
    required Color mutedColor,
    required String? expanderColumnKey,
    bool includeSelectable = false,
    bool includeTicker = false,
  }) {
    final hasContent = includeSelectable || includeTicker || columns.isNotEmpty;
    if (!hasContent) {
      return const SizedBox.shrink();
    }

    _refreshNaturalMinWidths(columns);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color line = widget.tableBorder?.horizontalInside.color ??
        widget.tableBorder?.verticalInside.color ??
        HomeUi.tableBorder(isDark);
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: line,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        dividerTheme: DividerThemeData(
          color: line,
          thickness: widget.dividerThickness ?? 0.5,
          space: 0,
        ),
      ),
      child: DataTable(
        showCheckboxColumn: false,
        headingRowHeight: _effectiveHeadingRowHeight,
        dataRowMinHeight: widget.rowHeight ?? widget.dataRowMinHeight,
        dataRowMaxHeight: _effectiveDataRowHeight,
        horizontalMargin: widget.horizontalMargin,
        columnSpacing: widget.columnSpacing ?? _kDefaultColumnSpacing,
        dividerThickness: widget.dividerThickness ?? 0.5,
        showBottomBorder: widget.showBottomBorder,
        border: widget.tableBorder ??
            TableBorder(
              horizontalInside: BorderSide(
                color: line,
                width: 0.5,
              ),
              top: BorderSide(
                color: line,
                width: 0.5,
              ),
              bottom: BorderSide.none,
              verticalInside: BorderSide.none,
            ),
        headingRowColor: WidgetStatePropertyAll(HomeUi.tableHeaderBg(isDark)),
        dataRowColor: const WidgetStatePropertyAll(Colors.transparent),
        columns: [
          if (includeSelectable)
            DataColumn(
              label: Checkbox(
                value: _selectedRowIds.length == rows.length && rows.isNotEmpty,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedRowIds.clear();
                      _selectedRowIds.addAll(rows.map((r) => r.id));
                    } else {
                      _selectedRowIds.clear();
                    }
                  });
                },
              ),
            ),
          if (includeTicker)
            DataColumn(
              tooltip: widget.showHeaderTooltip ? widget.tickerHeaderLabel : null,
              headingRowAlignment: MainAxisAlignment.start,
              label: SizedBox(
                width: widget.tickerColumnWidth,
                child: Padding(
                  // Match card toolbar inset via DataTable.horizontalMargin only.
                  padding: const EdgeInsets.only(right: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.tickerHeaderLabel.toUpperCase(),
                      style: HomeUi.tableHeader(isDark),
                    ),
                  ),
                ),
              ),
            ),
          ...columns.map((col) => _buildHeaderColumn(context, col, mutedColor)),
        ],
        rows: rows.asMap().entries.map((entry) {
          final row = entry.value;
          return DataRow(
            color: WidgetStateProperty.all(
              _hoveredRowId == row.id
                  ? HomeUi.tableRowHover(isDark)
                  : Colors.transparent,
            ),
            cells: [
              if (includeSelectable)
                DataCell(
                  _wrapRowHover(
                    row.id,
                    Checkbox(
                      value: _selectedRowIds.contains(row.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedRowIds.add(row.id);
                          } else {
                            _selectedRowIds.remove(row.id);
                          }
                        });
                        widget.onSelectionChange?.call(
                          widget.rows
                              .where((r) => _selectedRowIds.contains(r.id))
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
              if (includeTicker)
                DataCell(
                  _wrapRowHover(
                    row.id,
                    SizedBox(
                      width: widget.tickerColumnWidth,
                      height: _effectiveDataRowHeight,
                      child: Padding(
                        // Match card toolbar inset via DataTable.horizontalMargin only.
                        padding: const EdgeInsets.only(right: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildTickerCell(row, textColor, mutedColor),
                        ),
                      ),
                    ),
                  ),
                  onTap: widget.onTickerTap != null
                      ? () => widget.onTickerTap!(row)
                      : widget.onRowDoubleClick != null
                          ? () => widget.onRowDoubleClick!(row)
                          : null,
                ),
              ..._buildRowCellsForColumns(
                row,
                columns,
                textColor,
                expanderColumnKey,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnimatedTableSection({
    required Key key,
    required Widget child,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeInOutCubicEmphasized,
      switchOutCurve: Curves.easeInOutCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (widget, animation) {
        final fade =
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        final size = CurvedAnimation(
            parent: animation, curve: Curves.easeInOutCubicEmphasized);
        final slide = Tween<Offset>(
          begin: const Offset(0.012, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: animation, curve: Curves.easeInOutCubicEmphasized));

        return FadeTransition(
          opacity: fade,
          child: SizeTransition(
            axis: Axis.horizontal,
            axisAlignment: -1,
            sizeFactor: size,
            child: SlideTransition(
              position: slide,
              child: widget,
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: key,
        child: child,
      ),
    );
  }

  Widget _buildPinnedSectionSlot({
    required String slotKey,
    required bool visible,
    required Widget child,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      reverseDuration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeInOutCubicEmphasized,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (widget, animation) {
        final fade =
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        final size = CurvedAnimation(
            parent: animation, curve: Curves.easeInOutCubicEmphasized);
        return FadeTransition(
          opacity: fade,
          child: SizeTransition(
            axis: Axis.horizontal,
            axisAlignment: slotKey == 'left' ? -1 : 1,
            sizeFactor: size,
            child: widget,
          ),
        );
      },
      child: visible
          ? KeyedSubtree(
              key: ValueKey<String>('${slotKey}_visible'),
              child: child,
            )
          : SizedBox(
              key: ValueKey<String>('${slotKey}_hidden'),
              width: 0,
              height: 0,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _stretchedColumnWidths = <String, double>{};

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = HomeUi.cardBg(isDark);
    final borderColor = HomeUi.tableBorder(isDark);
    final textColor = HomeUi.title(isDark);
    final mutedColor = HomeUi.muted(isDark);

    final effectiveColumns = _getEffectiveColumns();
    final filteredRows = _getFilteredRows();
    final sortedRows = _getSortedRows(filteredRows);
    final flattenedRows = _flattenRows(sortedRows);

    final pages = widget.paginated
        ? (flattenedRows.length / _pageSize)
            .ceil()
            .clamp(1, double.infinity)
            .toInt()
        : 1;
    final safePage = _currentPage.clamp(1, pages);
    final paginatedRows = widget.paginated
        ? flattenedRows
            .skip((safePage - 1) * _pageSize)
            .take(_pageSize)
            .toList()
        : flattenedRows;

    final allVisibleColumns = _columnOrder
        .map((key) => effectiveColumns.firstWhereOrNull((c) => c.key == key))
        .whereType<DynamicTableColumn>()
        .where((c) => _visibleColumns.contains(c.key))
        .toList();

    final metricKeys = allVisibleColumns
        .where((c) => c.key == 'metric')
        .map((c) => c.key)
        .toSet();
    final statKeys = _getEnabledStatColumnKeys();
    final effectiveLeftPinned = <String>{
      ..._pinnedLeftColumns,
      if (widget.autoPinMetricColumn) ...metricKeys,
    };
    final effectiveRightPinned = <String>{
      ..._pinnedRightColumns,
      if (widget.autoPinStatColumns) ...statKeys,
    };

    final leftPinnedColumns = allVisibleColumns
        .where((c) => effectiveLeftPinned.contains(c.key))
        .toList();
    final centerColumns = allVisibleColumns
        .where(
          (c) =>
              !effectiveLeftPinned.contains(c.key) &&
              !effectiveRightPinned.contains(c.key),
        )
        .toList();
    final rightPinnedColumns = allVisibleColumns
        .where((c) => effectiveRightPinned.contains(c.key))
        .toList();

    final expanderColumnKey = flattenedRows.any((r) => r.isExpandable)
        ? (allVisibleColumns.isNotEmpty ? allVisibleColumns.first.key : null)
        : null;

    final tableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        if (widget.title != null ||
            widget.subtitle != null ||
            widget.enableColumnVisibilityToggle ||
            widget.toolbar != null)
          Container(
            padding: widget.toolbarPadding ??
                const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.title != null || widget.subtitle != null)
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      title: widget.title ?? '',
                      subtitleText: widget.subtitle,
                      icon: widget.toolbarLeadingIcon,
                    ),
                  ),
                if (widget.title == null &&
                    widget.subtitle == null &&
                    widget.toolbar != null)
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: widget.toolbar!,
                    ),
                  ),
                if (widget.enableColumnVisibilityToggle) ...[
                  const SizedBox(width: 12),
                  ColumnVisibilityButton(
                    columns: effectiveColumns,
                    visibleColumns: _visibleColumns,
                    onColumnToggle: (key) {
                      setState(() {
                        if (_visibleColumns.contains(key)) {
                          _visibleColumns.remove(key);
                        } else {
                          _visibleColumns.add(key);
                        }
                      });
                    },
                    isDark: isDark,
                  ),
                ],
                if ((widget.title != null || widget.subtitle != null) &&
                    widget.toolbar != null) ...[
                  const SizedBox(width: 12),
                  widget.toolbar!,
                ],
              ],
            ),
          ),
        if (widget.title != null || widget.subtitle != null)
          Divider(
            height: 1,
            thickness: 1,
            color: HomeUi.tableBorder(isDark),
          ),
        // Table
        if (widget.loading)
          SizedBox(
            height: widget.maxHeight ?? 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(color: mutedColor),
                  ),
                ],
              ),
            ),
          )
        else if (paginatedRows.isEmpty)
          SizedBox(
            height: widget.maxHeight ?? 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: mutedColor),
                  const SizedBox(height: 12),
                  Text(
                    widget.emptyStateTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.emptyStateDescription,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          _buildPinnedScrollBody(
            context: context,
            bgColor: bgColor,
            borderColor: borderColor,
            leftPinnedColumns: leftPinnedColumns,
            centerColumns: centerColumns,
            rightPinnedColumns: rightPinnedColumns,
            paginatedRows: paginatedRows,
            textColor: textColor,
            mutedColor: mutedColor,
            expanderColumnKey: expanderColumnKey,
          ),
        // Pagination
        if (widget.paginated && paginatedRows.isNotEmpty)
          TablePaginationBar(
            isDark: isDark,
            currentPage: safePage,
            totalPages: pages,
            summaryText: '${flattenedRows.length} rows',
            rowsPerPage: _pageSize,
            onRowsPerPageChanged: (int size) {
              setState(() {
                _pageSize = size;
                _currentPage = 1;
              });
            },
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
              widget.onPageChange?.call(page);
            },
          ),
      ],
    );

    final paddedTableContent = widget.considerPadding
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: tableContent,
          )
        : tableContent;

    if (!widget.useOuterContainer) {
      return paddedTableContent;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        boxShadow: widget.showOuterShadow
            ? (widget.outerBoxShadow ?? HomeUi.cardShadow(isDark))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: paddedTableContent,
    );
  }
}

// ============================================================================
// COLUMN VISIBILITY BUTTON
// ============================================================================

class ColumnVisibilityButton extends StatefulWidget {
  final List<DynamicTableColumn> columns;
  final Set<String> visibleColumns;
  final Function(String) onColumnToggle;
  final bool isDark;

  const ColumnVisibilityButton({
    required this.columns,
    required this.visibleColumns,
    required this.onColumnToggle,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  State<ColumnVisibilityButton> createState() => _ColumnVisibilityButtonState();
}

class _ColumnVisibilityButtonState extends State<ColumnVisibilityButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _menuOpen = false;
  Set<String> _overlayVisibleColumns = <String>{};

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_menuOpen && mounted) {
      setState(() {
        _menuOpen = false;
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _overlayVisibleColumns = Set<String>.from(widget.visibleColumns);

    setState(() {
      _menuOpen = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = widget.isDark;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * -6),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 268,
                    constraints: const BoxConstraints(maxHeight: 380),
                    decoration: BoxDecoration(
                      color: HomeUi.cardBg(isDark),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: HomeUi.borderStrong(isDark),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.40 : 0.10),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Text(
                            'SHOW COLUMNS',
                            style: HomeUi.overline(isDark).copyWith(
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: HomeUi.borderLight(isDark),
                        ),
                        Flexible(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            shrinkWrap: true,
                            itemCount: widget.columns.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final col = widget.columns[index];
                              final isVisible =
                                  _overlayVisibleColumns.contains(col.key);
                              return _ColumnMenuRow(
                                label: col.label,
                                selected: isVisible,
                                isDark: isDark,
                                onTap: () {
                                  if (isVisible) {
                                    _overlayVisibleColumns.remove(col.key);
                                  } else {
                                    _overlayVisibleColumns.add(col.key);
                                  }
                                  widget.onColumnToggle(col.key);
                                  _overlayEntry?.markNeedsBuild();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _showOverlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: HomeUi.controlHeight,
            decoration: BoxDecoration(
              color: _menuOpen
                  ? HomeUi.elevatedBg(widget.isDark)
                  : HomeUi.cardBg(widget.isDark),
              border: Border.all(
                color: _menuOpen
                    ? HomeUi.iconWellBorder
                    : HomeUi.borderLight(widget.isDark),
              ),
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_column_rounded,
                  size: 16,
                  color: HomeUi.muted(widget.isDark),
                ),
                const SizedBox(width: 6),
                Text(
                  'Columns',
                  style: HomeUi.control(widget.isDark, active: true).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _menuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more,
                    size: 16,
                    color: HomeUi.muted(widget.isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnMenuRow extends StatefulWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ColumnMenuRow({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ColumnMenuRow> createState() => _ColumnMenuRowState();
}

class _ColumnMenuRowState extends State<_ColumnMenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    const radius = 10.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: _hover ? HomeUi.iconFillGradient : null,
            color: _hover ? null : HomeUi.borderLight(dark),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  dark ? (_hover ? 0.28 : 0.16) : (_hover ? 0.08 : 0.04),
                ),
                blurRadius: _hover ? 10 : 6,
                offset: Offset(0, _hover ? 4 : 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(_hover ? 1.5 : 1),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(dark),
              borderRadius: BorderRadius.circular(radius - 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: widget.selected ? HomeUi.iconFillGradient : null,
                    color: widget.selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: widget.selected
                          ? HomeUi.buttonBorder
                          : HomeUi.borderStrong(dark),
                      width: 1,
                    ),
                  ),
                  child: widget.selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeUi.control(dark, active: true).copyWith(
                      fontSize: 12.5,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
