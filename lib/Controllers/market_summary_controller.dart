import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/Screens/sector_details_screen.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class MarketSummaryDefaults {
  String? displayName;
  String? field;

  MarketSummaryDefaults({this.displayName, this.field});

  MarketSummaryDefaults.fromJson(Map<String, dynamic> json) {
    displayName = json['display_name'];
    field = json['field'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['display_name'] = this.displayName;
    data['field'] = this.field;
    return data;
  }
}

class MarketSummaryController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxList<DataColumn> dataCols = <DataColumn>[].obs;
  final RxList<DataRow> dataRows = <DataRow>[].obs;
  final RxList<DataColumn> fixedDataCols = <DataColumn>[].obs;
  final RxList<DataRow> fixedDataRows = <DataRow>[].obs;
  final RxMap<String, dynamic> data = <String, dynamic>{}.obs;
  final RxList<MarketSummaryDefaults> dataFieldsToDisplay = <MarketSummaryDefaults>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMarketSummaryData();
  }

  Future<void> fetchMarketSummaryData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final marketSummaryResponse = await WebService.getTypesense([
        'collections',
        'market_summary',
        'documents',
        'search'
      ], {
        "q": "*",
        "filter_by": "Country:=US",
        "sort_by": "sort_order:asc",
        "per_page": "250"
      });

      if (marketSummaryResponse.statusCode == 200) {
        var marketSummaryApiData = jsonDecode(marketSummaryResponse.body);
        
        final defaultConfigData = [
          MarketSummaryDefaults(displayName: "1D", field: "1 Day"),
          MarketSummaryDefaults(displayName: "1W", field: "1 Week"),
          MarketSummaryDefaults(displayName: "1M", field: "1 Month"),
          MarketSummaryDefaults(displayName: "3M", field: "3 Months"),
          MarketSummaryDefaults(displayName: "6M", field: "6 Months"),
          MarketSummaryDefaults(displayName: "1Y", field: "1 Year"),
        ];

        data.value = marketSummaryApiData;
        dataFieldsToDisplay.value = defaultConfigData;

        generateColumns();
        generateDataRows();

        isLoading.value = false;
      } else {
        data.value = {"hits": []};
        dataFieldsToDisplay.value = [];
        errorMessage.value = 'API failed with status: ${marketSummaryResponse.statusCode}';
        isLoading.value = false;
      }
    } catch (e) {
      data.value = {"hits": []};
      dataFieldsToDisplay.value = [];
      errorMessage.value = 'Error: $e';
      isLoading.value = false;
    }
  }

  void generateColumns() {
    List<DataColumn> fixedLst = [];
    List<DataColumn> lst = [];

    final isDarkMode = Get.context?.theme.brightness == Brightness.dark;
    final headerStyle = HomeUi.tableHeader(isDarkMode == true);

    fixedLst.add(DataColumn(
      headingRowAlignment: MainAxisAlignment.start,
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "SECTOR",
          style: headerStyle,
          textAlign: TextAlign.left,
        ),
      ),
    ));

    dataFieldsToDisplay.forEach((element) {
      var widget = DataColumn(
        headingRowAlignment: MainAxisAlignment.center,
        label: Padding(
          padding: EdgeInsets.zero,
          child: Text(
            (element.displayName ?? '').toUpperCase(),
            style: headerStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      lst.add(widget);
    });

    fixedDataCols.value = fixedLst;
    dataCols.value = lst;
  }

  void generateDataRows() {
    final isDarkMode = Get.context?.theme.brightness == Brightness.dark;
    final rowTextStyle = HomeUi.tableCell(isDarkMode == true);
    List<DataRow> dataRowLst = [];
    List<DataRow> fixedRowLst = [];

    final hits = data['hits'] as List?;

    if (hits != null) {
      for (int i = 0; i < hits.length; i++) {
        var obj = hits[i];
        var document = obj['document'] as Map<String, dynamic>?;
        
        if (document == null) {
          continue;
        }

        List<DataCell> cellArr = [];
        List<DataCell> fixedRowCellArr = [];

        var sector = document['Sector']?.toString() ?? 'Unknown';

        var sectorCell = DataCell(
          HomeUi.premiumTooltip(
            message: sector,
            waitDuration: const Duration(milliseconds: 350),
            child: GestureDetector(
              onTap: () {
                FeatureNavigation.toIfAllowed(
                  FeatureKeys.sectorDetails,
                  () => SectorDetailsScreen(sectorName: sector),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    sector,
                    style: rowTextStyle,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );

        fixedRowCellArr.add(sectorCell);
        fixedRowLst.add(DataRow(cells: fixedRowCellArr));

        dataFieldsToDisplay.forEach((displayElement) {
          final fieldName = displayElement.field;
          final matchedFieldValue = document[fieldName];

          double? numericValue;
          if (matchedFieldValue != null) {
            if (matchedFieldValue is num) {
              numericValue = matchedFieldValue.toDouble();
            } else if (matchedFieldValue is String) {
              numericValue = double.tryParse(matchedFieldValue);
            }
          }

          var matchedFieldStr = "0.0%";
          var isPos = false;

          if (numericValue != null) {
            matchedFieldStr = "${numericValue.toStringAsFixed(1)}%";
            isPos = numericValue > 0;
            if (isPos) {
              matchedFieldStr = "+$matchedFieldStr";
            }
          }

          var valueCell = DataCell(Align(
            alignment: Alignment.center,
            child: numericValue == null || numericValue == 0
                ? Text(
                    numericValue == null ? '—' : '0.0%',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: HomeUi.tableNumeric(isDarkMode == true),
                  )
                : HomeUi.signedPercentPill(
                    isDarkMode == true,
                    matchedFieldStr,
                    numericValue,
                  ),
          ));
          cellArr.add(valueCell);
        });

        dataRowLst.add(DataRow(cells: cellArr));
      }
    }

    fixedDataRows.value = fixedRowLst;
    dataRows.value = dataRowLst;
  }

  void refreshData() {
    fetchMarketSummaryData();
  }

  /// Estimated full height of the "Previous day closing data" table widget
  /// (title + spacing + padded table body). Matches [MarketSummaryDynamicTable].
  double estimatedTableWidgetHeight(double screenWidth) {
    final bool isLargeScreen = screenWidth >= 1600;
    final dataRowMaxHeight = isLargeScreen ? 44.0 : 42.0;
    final rowCount = dataRows.isEmpty ? 11 : dataRows.length;
    final tableBodyHeight = 40 + (rowCount * dataRowMaxHeight) + 1;
    const headerChrome = 60.0;
    return headerChrome + tableBodyHeight;
  }
}
