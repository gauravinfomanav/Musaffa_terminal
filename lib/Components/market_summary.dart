import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Controllers/market_summary_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class MarketSummaryDynamicTable extends StatefulWidget {
  const MarketSummaryDynamicTable({
    Key? key,
  }) : super(key: key);

  @override
  State<MarketSummaryDynamicTable> createState() =>
      _MarketSummaryDynamicTableState();
}

class _MarketSummaryDynamicTableState extends State<MarketSummaryDynamicTable> {
  late MarketSummaryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MarketSummaryController());
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _extractTextFromWidget(Widget widget) {
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText() ?? '';
    }
    if (widget is Padding && widget.child != null) {
      return _extractTextFromWidget(widget.child!);
    }
    if (widget is Container && widget.child != null) {
      return _extractTextFromWidget(widget.child!);
    }
    if (widget is Align && widget.child != null) {
      return _extractTextFromWidget(widget.child!);
    }
    if (widget is Center && widget.child != null) {
      return _extractTextFromWidget(widget.child!);
    }
    return '';
  }

  List<DynamicTableColumn> _mapToDynamicColumns({
    required double fixedSectorColumnWidth,
    required double periodColumnWidth,
  }) {
    final columns = <DynamicTableColumn>[];

    if (controller.fixedDataCols.isNotEmpty) {
      final fixedColumn = controller.fixedDataCols.first;
      columns.add(
        DynamicTableColumn(
          key: 'sector',
          label: _extractTextFromWidget(fixedColumn.label),
          headerWidget: fixedColumn.label,
          width: fixedSectorColumnWidth,
          sortable: true,
          searchable: false,
          pinnable: true,
          align: TextAlign.left,
        ),
      );
    }

    for (var i = 0; i < controller.dataCols.length; i++) {
      final column = controller.dataCols[i];
      columns.add(
        DynamicTableColumn(
          key: 'period_$i',
          label: _extractTextFromWidget(column.label),
          headerWidget: column.label,
          width: periodColumnWidth,
          sortable: true,
          searchable: false,
          pinnable: true,
          align: TextAlign.right,
        ),
      );
    }

    return columns;
  }

  List<DynamicTableRow> _mapToDynamicRows() {
    final rows = <DynamicTableRow>[];
    final rowCount =
        math.min(controller.fixedDataRows.length, controller.dataRows.length);

    for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      final fixedRowCells = controller.fixedDataRows[rowIndex].cells;
      final dataRowCells = controller.dataRows[rowIndex].cells;

      final rowData = <String, dynamic>{
        'sector': fixedRowCells.isNotEmpty ? fixedRowCells.first.child : '--',
      };

      for (var colIndex = 0;
          colIndex < controller.dataCols.length;
          colIndex++) {
        rowData['period_$colIndex'] = colIndex < dataRowCells.length
            ? dataRowCells[colIndex].child
            : '--';
      }

      rows.add(
        DynamicTableRow(
          id: 'market_summary_row_$rowIndex',
          data: rowData,
        ),
      );
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Obx(() {
            if (controller.errorMessage.isNotEmpty) {
              return Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: DashboardTextStyles.errorMessage,
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),
          Obx(() {
            if (controller.isLoading.value) {
              return _buildShimmerLoader();
            } else if (controller.data['hits']?.isEmpty == true) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  "No data available",
                  style: DashboardTextStyles.noData,
                ),
              );
            } else {
              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;
                  final Color tableBorderColor = HomeUi.tableBorder(isDarkMode);
              return Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: HomeUi.cardDecoration(isDarkMode).copyWith(
                  border: Border.all(
                    color: tableBorderColor,
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Text(
                        "Previous day closing data",
                        textAlign: TextAlign.start,
                        style: HomeUi.cardTitle(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: tableBorderColor,
                    ),
                    LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;

                      final screenWidth = MediaQuery.of(context).size.width;
                      final bool isLargeScreen = screenWidth >= 1600;
                      final dataRowMaxHeight = isLargeScreen ? 44.0 : 42.0;
                      const headingRowHeight = 40.0;
                      const columnSpacing = 6.0;
                      const horizontalMargin = 0.0;
                      // Default 12px edge inset — SECTOR / 1Y stay off the card rim.

                      // Minimum widths only — DynamicTableFromWeb stretch fills
                      // leftover so the table always spans the full card width.
                      const double periodMin = 56.0;
                      const double sectorIdeal = 220.0;

                      final dynamicColumns = _mapToDynamicColumns(
                        fixedSectorColumnWidth: sectorIdeal,
                        periodColumnWidth: periodMin,
                      );
                      final dynamicRows = _mapToDynamicRows();

                      final calculatedTableHeight =
                          headingRowHeight + (dynamicRows.length * dataRowMaxHeight) + 1;
                      final tableMaxHeight = calculatedTableHeight < 60
                          ? 60.0
                          : calculatedTableHeight;

                      return SizedBox(
                        width: availableWidth,
                        child: DynamicTableFromWeb(
                          columns: dynamicColumns,
                          rows: dynamicRows,
                          title: null,
                          subtitle: null,
                          paginated: false,
                          selectable: false,
                          searchable: false,
                          showTickerCell: false,
                          toolbar: null,
                          loading: controller.isLoading.value,
                          maxHeight: tableMaxHeight,
                          enableColumnVisibilityToggle: false,
                          enableColumnReorder: false,
                          enableColumnPinning: true,
                          enableRowReorder: false,
                          showSortIndicators: false,
                          headingRowHeight: headingRowHeight,
                          dataRowMinHeight: 32,
                          dataRowMaxHeight: dataRowMaxHeight,
                          horizontalMargin: horizontalMargin,
                          tableEdgeInset: const EdgeInsets.symmetric(horizontal: 12),
                          columnSpacing: columnSpacing,
                          columnCellPadding:
                              const EdgeInsets.only(left: 0, right: 4),
                          dividerThickness: 0.5,
                          showBottomBorder: false,
                          tableBorder: TableBorder(
                            bottom: BorderSide.none,
                            top: BorderSide.none,
                            verticalInside: BorderSide.none,
                            horizontalInside: BorderSide(
                              color: tableBorderColor,
                              width: 0.5,
                            ),
                          ),
                          useOuterContainer: false,
                          showColumnActionMenu: false,
                          showColumnResizeHandle: false,
                          showHeaderTooltip: false,
                          enforceColumnWidths: true,
                          enableColumnStretch: true,
                          showPinnedSectionDividers: true,
                          initialPinnedLeftColumnKeys: const <String>['sector'],
                        ),
                      );
                    },
                  ),
                ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Column(
      children: List.generate(
        15,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              ShimmerWidgets.box(
                height: 20,
                width: 100,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Row(
                  children: List.generate(
                    6,
                    (colIndex) => Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: ShimmerWidgets.box(
                        height: 20,
                        width: 75,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
