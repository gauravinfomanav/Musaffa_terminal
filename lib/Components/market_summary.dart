import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Controllers/market_summary_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class MarketSummaryDynamicTable extends StatefulWidget {
  const MarketSummaryDynamicTable({
    Key? key,
  }) : super(key: key);

  @override
  State<MarketSummaryDynamicTable> createState() =>
      _MarketSummaryDynamicTableState();
}

class _MarketSummaryDynamicTableState extends State<MarketSummaryDynamicTable> {
  final ScrollController _scrollController = ScrollController();
  late MarketSummaryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MarketSummaryController());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
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
              return Column(
                children: [
                  Row(
                    children: [
                      Text(                        
                        "Previous day closing data",
                        textAlign: TextAlign.start,
                        style: DashboardTextStyles.titleSmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : DashboardTextStyles.newtextcolor,
                        ),
                        
                       
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Get available width for the table
                      final availableWidth = constraints.maxWidth;
                      final fixedColumnWidth =
                          180.0; // Fixed "Sector" column width
                      final scrollableAreaWidth =
                          availableWidth - fixedColumnWidth;

                      // Determine row height based on screen width
                      final screenWidth = MediaQuery.of(context).size.width;
                      final bool isLargeScreen = screenWidth >= 1600;
                      final double dataRowMaxHeight =
                          isLargeScreen ? 35.0 : 30.0;

                      // Calculate minimum width needed for 6 columns with base spacing
                      final baseColumnSpacing = 10.0;
                      final numColumns =
                          6; // 1D, 1W, 1M, 3M, 6M, 1Y
                      final estimatedColumnWidth =
                          80.0; // Estimated width per column
                      final minWidthNeeded = (numColumns * estimatedColumnWidth) +
                          ((numColumns - 1) * baseColumnSpacing);

                      // Calculate dynamic spacing to fill available space
                      double dynamicSpacing;
                      if (scrollableAreaWidth > minWidthNeeded) {
                        // We have extra space - increase spacing
                        final extraSpace =
                            scrollableAreaWidth - minWidthNeeded;
                        final additionalSpacing =
                            extraSpace / (numColumns - 1);
                        dynamicSpacing =
                            baseColumnSpacing + additionalSpacing;
                        // Cap maximum spacing at 50px for readability
                        dynamicSpacing =
                            dynamicSpacing.clamp(baseColumnSpacing, 50.0);
                      } else {
                        // Use base spacing if not enough space
                        dynamicSpacing = baseColumnSpacing;
                      }

                      final borderWidth = isLargeScreen ? 0.5 : 0.25;
                      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                      final borderColor = Theme.of(context).primaryColorLight;

                      return Row(
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              minWidth: fixedColumnWidth,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                            ),
                            child: DataTable(
                              headingRowHeight: 20,
                              horizontalMargin: 6,
                              dataRowMinHeight: 20,
                              dataRowMaxHeight: dataRowMaxHeight,
                              columns: controller.fixedDataCols,
                              rows: controller.fixedDataRows,
                              dividerThickness: borderWidth,
                              border: TableBorder(
                                bottom: BorderSide.none,
                                top: BorderSide.none,
                                verticalInside: BorderSide.none,
                                horizontalInside: BorderSide(
                                  color: borderColor,
                                  width: borderWidth,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thickness: 4,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 20,
                                  horizontalMargin: 0,
                                  columnSpacing: dynamicSpacing,
                                  dataRowMinHeight: 20,
                                  dataRowMaxHeight: dataRowMaxHeight,
                                  columns: controller.dataCols,
                                  rows: controller.dataRows,
                                  dividerThickness: borderWidth,
                                  showBottomBorder: false,
                                  border: TableBorder(
                                    bottom: BorderSide.none,
                                    top: BorderSide.none,
                                    verticalInside: BorderSide.none,
                                    horizontalInside: BorderSide(
                                      color: borderColor,
                                      width: borderWidth,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Column(
      children: List.generate(15, (index) => 
        Padding(
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
                  children: List.generate(6, (colIndex) => 
                    Padding(
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
