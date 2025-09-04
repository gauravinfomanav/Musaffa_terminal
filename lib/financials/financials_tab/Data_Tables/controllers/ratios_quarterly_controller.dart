import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';

class quarterlyRatioDataModel {
  final String metric;
  final Map<String, double> values;

  quarterlyRatioDataModel({required this.metric, required this.values});
}

class QuarterlyRatiosController extends GetxController {
  var isLoading = true.obs;
  var quarterlyData = <Map<String, dynamic>>[].obs;
  final WebService webService = WebService();

  // New properties for processed table data
  var processingComplete = false.obs;
  var tableData = <quarterlyRatioDataModel>[].obs;
  var quarters = <String>[].obs;
  var currency = "USD".obs;

  get nameMapping => null;

  Future<void> fetchQuarterlyRatios(String symbol) async {
    try {
      isLoading.value = true;

      Map<String, dynamic> params = {
        'q': '*',
        'filter_by':
            'company_symbol:$symbol&&name:[netMargin,quickRatio,currentRatio,peTTM,psTTM,pb,fcfMargin,payoutRatioTTM,grossMargin,operatingMargin,longtermDebtTotalEquity,totalDebtToTotalAsset,longtermDebtTotalAsset,totalDebtToTotalCapital,inventoryTurnoverTTM,receivablesTurnoverTTM,roeTTM,roaTTM,roic,assetTurnoverTTM]&&time_period:quarterly',
        'per_page': '150',
        'sort_by': 'period:desc',
        'page': '1'
      };

      final response = await WebService.getTypesense_infomanav(
        ['collections', 'company_financials_series', 'documents', 'search'],
        params,
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> hits = decodedData['hits'];

        // Mapping of metric names to display names
        Map<String, String> nameMapping = {
          "netMargin": "Net Margin",
          "quickRatio": "Quick Ratio",
          "currentRatio": "Current Ratio",
          "peTTM": "Price to Earnings (TTM)",
          "psTTM": "Price to Sales (TTM)",
          "pb": "Price to Book",
          "fcfMargin": "Free Cash Flow Margin",
          "payoutRatioTTM": "Payout Ratio (TTM)",
          "grossMargin": "Gross Margin",
          "operatingMargin": "Operating Margin",
          "longtermDebtTotalEquity": "Long-Term Debt to Equity (TTM)",
          "totalDebtToTotalAsset": "Total Debt to Total Asset (TTM)",
          "longtermDebtTotalAsset": "Long-Term Debt to Total Asset (TTM)",
          "totalDebtToTotalCapital": "Total Debt to Total Capital",
          "inventoryTurnoverTTM": "Inventory Turnover (TTM)",
          "receivablesTurnoverTTM": "Receivables Turnover (TTM)",
          "assetTurnoverTTM": "Asset Turnover (TTM)",
          "roeTTM": "Return on Equity (TTM)",
          // "roaTTM": "Return on Assets (TTM)",
          "roaTTM": "Return on Assets (TTM)",
        };

        // Processing data
        List<Map<String, dynamic>> formattedData = [];
        for (var hit in hits) {
          var doc = hit["document"];
          String period = doc["period"];

          if (period.startsWith("2024")) {
            String quarter = getQuarter(period);

            formattedData.add({
              "Quarter": quarter,
              "Metric": nameMapping[doc["name"]] ??
                  doc["name"], // This should handle all metrics
              "Value": doc["v"]
            });
          }
        }

        // Sorting by quarter (Q1 -> Q4)
        formattedData.sort((a, b) => a["Quarter"].compareTo(b["Quarter"]));

        // Updating observable list
        quarterlyData.value = formattedData;

        // Process data for table display
        processDataForTable();
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching turnover ratios: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Process data into a format suitable for table display
  void processDataForTable() {
    // Get unique quarters
    quarters.value =
        quarterlyData.map((item) => item["Quarter"] as String).toSet().toList();

    // Sort quarters chronologically
    quarters.sort((a, b) {
      // Extract quarter number and year for comparison
      int quarterA = int.parse(a.split(" ")[0].substring(1));
      int quarterB = int.parse(b.split(" ")[0].substring(1));
      int yearA = int.parse(a.split(" ")[1]);
      int yearB = int.parse(b.split(" ")[1]);

      if (yearA != yearB) {
        return yearA.compareTo(yearB);
      }
      return quarterA.compareTo(quarterB);
    });

    // Get unique metrics
    Set<String> metrics =
        quarterlyData.map((item) => item["Metric"] as String).toSet();

    // Create table data
    List<quarterlyRatioDataModel> result = [];

    for (String metric in metrics) {
      Map<String, double> values = {};

      for (String quarter in quarters) {
        var item = quarterlyData.firstWhereOrNull((element) =>
            element["Metric"] == metric && element["Quarter"] == quarter);

        if (item != null) {
          values[quarter] = item["Value"] is double
              ? item["Value"]
              : double.parse(item["Value"].toString());
        } else {
          values[quarter] = 0.0; // Default if no data
        }
      }

      result.add(quarterlyRatioDataModel(metric: metric, values: values));
    }

    tableData.value = result;
    processingComplete.value = true;
    
  }

  // Function to determine quarter from period
  String getQuarter(String period) {
    if (period.startsWith("2024-12") ||
        period.startsWith("2024-11") ||
        period.startsWith("2024-10")) return "Q4 2024";
    if (period.startsWith("2024-09") ||
        period.startsWith("2024-08") ||
        period.startsWith("2024-07")) return "Q3 2024";
    if (period.startsWith("2024-06") ||
        period.startsWith("2024-05") ||
        period.startsWith("2024-04")) return "Q2 2024";
    if (period.startsWith("2024-03") ||
        period.startsWith("2024-02") ||
        period.startsWith("2024-01")) return "Q1 2024";
    return "Unknown";
  }

  // Format for display - shows Q1'24 instead of Q1 2024
  String formatQuarterForDisplay(String quarter) {
    // Split the quarter string, e.g., "Q1 2024"
    List<String> parts = quarter.split(" ");
    if (parts.length != 2) return quarter;

    String quarterPart = parts[0];
    String yearPart = parts[1].substring(2); // Get last two digits of year

    return "$quarterPart'$yearPart";
  }
}
