import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

/// Column definition for dynamic table
class DynamicTableColumn {
  final String key;
  final String label;
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
}

/// Row data model
class DynamicTableRow {
  final String id;
  final Map<String, dynamic> data;
  final bool? isSelectable;

  const DynamicTableRow({
    required this.id,
    required this.data,
    this.isSelectable = true,
  });
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
  final bool showColumnActionMenu;
  final bool showColumnResizeHandle;
  final bool enforceColumnWidths;
  final List<String> initialPinnedLeftColumnKeys;
  final List<String> initialPinnedRightColumnKeys;

  const DynamicTableFromWeb({
    Key? key,
    required this.columns,
    required this.rows,
    this.title,
    this.subtitle,
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
    this.onTickerTap,
    this.headingRowHeight = 44,
    this.dataRowMinHeight = 48,
    this.dataRowMaxHeight = 48,
    this.horizontalMargin = 24,
    this.columnSpacing,
    this.dividerThickness,
    this.tableBorder,
    this.showBottomBorder = false,
    this.useOuterContainer = true,
    this.showColumnActionMenu = true,
    this.showColumnResizeHandle = true,
    this.enforceColumnWidths = true,
    this.initialPinnedLeftColumnKeys = const <String>[],
    this.initialPinnedRightColumnKeys = const <String>[],
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
  late SortState? _sortState;
  late final ScrollController _horizontalScrollController;
  late final ScrollController _verticalScrollController;

  String? _draggingColumnKey;
  String? _dragOverColumnKey;
  String? _hoveredResizeColumnKey;
  final Set<String> _pinnedLeftColumns = <String>{};
  final Set<String> _pinnedRightColumns = <String>{};
  final Map<String, double> _naturalMinWidths = <String, double>{};

  @override
  void initState() {
    super.initState();
    _columnOrder = widget.columns.map((c) => c.key).toList();
    _visibleColumns = Set.from(_columnOrder);
    _selectedRowIds = <String>{};
    _columnFilterValues = <String, dynamic>{};
    _columnWidths = <String, double>{};
    _currentPage = widget.currentPage;
    _sortState = widget.sortState;
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _pinnedLeftColumns.addAll(widget.initialPinnedLeftColumnKeys);
    _pinnedRightColumns.addAll(widget.initialPinnedRightColumnKeys);
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
    if (oldWidget.columns != widget.columns) {
      _naturalMinWidths.clear();
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
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
    final sortCol =
        widget.columns.firstWhereOrNull((c) => c.key == _sortState!.key);
    if (sortCol == null) return rows;

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
    return sorted;
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

  double _getNaturalMinWidth(DynamicTableColumn col) {
    if (col.width != null) return col.width!;
    final cached = _naturalMinWidths[col.key];
    if (cached != null) return cached;

    final painter = TextPainter(
      text: TextSpan(
        text: col.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: Constants.FONT_DEFAULT_NEW,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    // label width + header padding/menu affordance
    final measured = painter.width + 64;
    final minWidth = measured < 120 ? 120.0 : measured;
    _naturalMinWidths[col.key] = minWidth;
    return minWidth;
  }

  double _resolveColumnWidth(DynamicTableColumn col) {
    final minWidth = _getNaturalMinWidth(col);
    final resolved = _columnWidths[col.key] ?? col.width ?? minWidth;
    return resolved < minWidth ? minWidth : resolved;
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
      tooltip: 'Column actions',
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
      child: Padding(
        padding: EdgeInsets.zero,
        child: Icon(
          Icons.more_vert,
          size: 16,
          color: iconColor,
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
    final ticker = row.data[widget.tickerKey]?.toString() ?? '--';
    final company = row.data[widget.companyKey]?.toString() ?? '--';
    final logoUrl = widget.logoKey != null
        ? row.data[widget.logoKey!]?.toString() ?? ''
        : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: showLogo(
            ticker,
            logoUrl,
            sideWidth: 24,
            circular: true,
            name: company,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ticker,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
              Text(
                company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataColumn _buildHeaderColumn(
    BuildContext context,
    DynamicTableColumn col,
    Color mutedColor,
  ) {
    const headerTextColor = Color(0xFF475569);
    final resolvedWidth =
        widget.enforceColumnWidths ? _resolveColumnWidth(col) : null;

    return DataColumn(
      label: Tooltip(
        message: col.label,
        child: DragTarget<String>(
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
                  child: SizedBox(
                    width: resolvedWidth,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
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
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: widget.showColumnActionMenu ? 28 : 0,
                                  ),
                                  child: col.headerWidget ??
                                      Text(
                                        col.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: headerTextColor,
                                          fontFamily:
                                              Constants.FONT_DEFAULT_NEW,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                ),
                              ),
                              if (widget.showColumnActionMenu)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: SizedBox(
                                    width: 24,
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
                                      : 1,
                                  child: Container(
                                    width: 1,
                                    color: const Color.fromARGB(
                                        255, 172, 173, 174),
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
  ) {
    return columns.map((col) {
      final value = row.data[col.key];
      final resolvedWidth =
          widget.enforceColumnWidths ? _resolveColumnWidth(col) : null;
      return DataCell(
        SizedBox(
          width: resolvedWidth,
          child: MouseRegion(
            cursor: SystemMouseCursors.basic,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 150),
              child: value is Widget
                  ? value
                  : Text(
                      value?.toString() ?? '--',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
            ),
          ),
        ),
        onTap: () {
          widget.onRowDoubleClick?.call(row);
        },
      );
    }).toList();
  }

  Widget _buildTableSection({
    required BuildContext context,
    required List<DynamicTableColumn> columns,
    required List<DynamicTableRow> rows,
    required Color textColor,
    required Color mutedColor,
    bool includeSelectable = false,
    bool includeTicker = false,
  }) {
    final hasContent = includeSelectable || includeTicker || columns.isNotEmpty;
    if (!hasContent) {
      return const SizedBox.shrink();
    }

    return DataTable(
      headingRowHeight: widget.headingRowHeight,
      dataRowMinHeight: widget.dataRowMinHeight,
      dataRowMaxHeight: widget.dataRowMaxHeight,
      horizontalMargin: widget.horizontalMargin,
      columnSpacing: widget.columnSpacing,
      dividerThickness: widget.dividerThickness,
      showBottomBorder: widget.showBottomBorder,
      border: widget.tableBorder,
      headingRowColor: const MaterialStatePropertyAll(Color(0xFFF5F7FA)),
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
            label: Text(
              widget.tickerHeaderLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
                letterSpacing: 0.04,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
        ...columns.map((col) => _buildHeaderColumn(context, col, mutedColor)),
      ],
      rows: rows.map((row) {
        return DataRow(
          cells: [
            if (includeSelectable)
              DataCell(
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
            if (includeTicker)
              DataCell(
                _buildTickerCell(row, textColor, mutedColor),
                onTap: () {
                  if (widget.onTickerTap != null) {
                    widget.onTickerTap!.call(row);
                    return;
                  }
                  widget.onRowDoubleClick?.call(row);
                },
              ),
            ..._buildRowCellsForColumns(row, columns, textColor),
          ],
        );
      }).toList(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
    const borderColor = Color(0xFFF1F5F9);
    final textColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final mutedColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final filteredRows = _getFilteredRows();
    final sortedRows = _getSortedRows(filteredRows);

    final pages = widget.paginated
        ? (sortedRows.length / widget.pageSize)
            .ceil()
            .clamp(1, double.infinity)
            .toInt()
        : 1;
    final safePage = _currentPage.clamp(1, pages);
    final paginatedRows = widget.paginated
        ? sortedRows
            .skip((safePage - 1) * widget.pageSize)
            .take(widget.pageSize)
            .toList()
        : sortedRows;

    final allVisibleColumns = _columnOrder
        .map((key) => widget.columns.firstWhereOrNull((c) => c.key == key))
        .whereType<DynamicTableColumn>()
        .where((c) => _visibleColumns.contains(c.key))
        .toList();

    final leftPinnedColumns = allVisibleColumns
        .where((c) => _pinnedLeftColumns.contains(c.key))
        .toList();
    final centerColumns = allVisibleColumns
        .where(
          (c) =>
              !_pinnedLeftColumns.contains(c.key) &&
              !_pinnedRightColumns.contains(c.key),
        )
        .toList();
    final rightPinnedColumns = allVisibleColumns
        .where((c) => _pinnedRightColumns.contains(c.key))
        .toList();

    final tableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        if (widget.title != null ||
            widget.subtitle != null ||
            widget.enableColumnVisibilityToggle ||
            widget.toolbar != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                // Title & Subtitle
                if (widget.title != null || widget.subtitle != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: mutedColor,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                    ],
                  ),
                const Spacer(),
                if (widget.enableColumnVisibilityToggle && widget.title != null)
                  const SizedBox(width: 12),
                // Columns visibility toggle
                if (widget.enableColumnVisibilityToggle)
                  ColumnVisibilityButton(
                    columns: widget.columns,
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
                // Custom toolbar
                if (widget.toolbar != null) widget.toolbar!,
              ],
            ),
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
          SizedBox(
            height: widget.maxHeight,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              scrollDirection: Axis.vertical,
              child: Row(
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
                        border: Border(
                          right: BorderSide(color: borderColor),
                        ),
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
                          includeSelectable: widget.selectable,
                          includeTicker: widget.showTickerCell,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubicEmphasized,
                      alignment: Alignment.topLeft,
                      child: centerColumns.isNotEmpty
                          ? Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              trackVisibility: false,
                              scrollbarOrientation: ScrollbarOrientation.bottom,
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
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
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  _buildPinnedSectionSlot(
                    slotKey: 'right',
                    visible: rightPinnedColumns.isNotEmpty,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          left: BorderSide(color: borderColor),
                        ),
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Pagination
        if (widget.paginated && paginatedRows.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${(safePage - 1) * widget.pageSize + 1}–${(safePage * widget.pageSize).clamp(0, sortedRows.length)} of ${sortedRows.length}',
                  style: TextStyle(fontSize: 13, color: mutedColor),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: mutedColor),
                      onPressed: safePage > 1
                          ? () {
                              setState(() => _currentPage--);
                              widget.onPageChange?.call(_currentPage);
                            }
                          : null,
                    ),
                    Text(
                      '$safePage / $pages',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: mutedColor),
                      onPressed: safePage < pages
                          ? () {
                              setState(() => _currentPage++);
                              widget.onPageChange?.call(_currentPage);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );

    if (!widget.useOuterContainer) {
      return tableContent;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: tableContent,
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
        final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final borderColor =
            isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
        final textColor =
            isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);

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
              offset: const Offset(0, 46),
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
                        offset: Offset(0, (1 - value) * -8),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 250,
                      constraints: const BoxConstraints(maxHeight: 320),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        children: widget.columns.map((col) {
                          final isVisible =
                              _overlayVisibleColumns.contains(col.key);
                          return InkWell(
                            onTap: () {
                              if (isVisible) {
                                _overlayVisibleColumns.remove(col.key);
                              } else {
                                _overlayVisibleColumns.add(col.key);
                              }
                              widget.onColumnToggle(col.key);
                              _overlayEntry?.markNeedsBuild();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isVisible
                                        ? Icons.check_box_outlined
                                        : Icons.check_box_outline_blank,
                                    size: 17,
                                    color: textColor,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      col.label,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: Constants.FONT_DEFAULT_NEW,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
      child: GestureDetector(
        onTap: _showOverlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 40,
          decoration: BoxDecoration(
            boxShadow: _menuOpen
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
            border: Border.all(
              color: _menuOpen
                  ? (widget.isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8))
                  : (widget.isDark
                      ? const Color(0xFF404040)
                      : const Color(0xFFE5E7EB)),
              width: _menuOpen ? 1.2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Columns',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _menuOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.expand_more,
                  size: 16,
                  color: widget.isDark
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
