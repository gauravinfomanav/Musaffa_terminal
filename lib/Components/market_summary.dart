import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Controllers/market_summary_controller.dart';

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
  bool _increaseShadow = false;
  late MarketSummaryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MarketSummaryController());
    
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
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "No data available",
                  style: TextStyle(fontSize: 14),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade50,
                        ),
                        child: DataTable(
                          headingRowHeight: 20,
                          horizontalMargin: 0,
                          dataRowMinHeight: 20,
                          dataRowMaxHeight: 32,
                          columns: controller.fixedDataCols,
                          rows: controller.fixedDataRows,
                          dividerThickness: 0,
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
                          controller: _scrollController,
                          thickness: 4,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 20,
                              horizontalMargin: 0,
                              columnSpacing: 0,
                              dataRowMinHeight: 20,
                              dataRowMaxHeight: 32,
                              columns: controller.dataCols,
                              rows: controller.dataRows,
                              dividerThickness: 0,
                              showBottomBorder: false,
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
                    ],
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
