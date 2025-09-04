import 'dart:convert';
// import 'package:amana_trade/Screens/financials_tab/models/per_share_data_model.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';


class FinancialFundamentalsController extends GetxController {
  var financialData = Rxn<FinancialFundamentals>();  
  var isLoading = true.obs; 

  // Function to fetch the financial fundamentals data based on a symbol
  Future<void> fetchFinancialFundamentals(String symbol) async {
    try {
      isLoading.value = true;
      final webService = WebService();  // Web service instance

      // Fetch both financial fundamentals and EPS data concurrently
      final results = await Future.wait([
        // Fetch financial fundamentals data
        WebService.getTypesense_infomanav(
          ['collections', 'financial_fundamentals', 'documents', symbol],
          null,
        ),
        
        // Fetch EPS data
        WebService.getTypesense_infomanav(
          ['collections', 'company_financials_series', 'documents', 'search'],
          {
            'q': '*',
            'filter_by': 'company_symbol:$symbol&&name:eps&&time_period:annual',
            'per_page': '250',
            'sort_by': 'period:desc'
          },
        ),
      ]);

      // https://typesense.infomanav.in/collections/company_financials_series/
      // documents/search?q=*&filter_by=company_symbol:NVDA&&name:eps&&time_period:
      // annual&per_page=4&sort_by=period:desc

      // Process the response for financial fundamentals data
      if (results[0].statusCode == 200) {
        final decodedData = jsonDecode(results[0].body);
        // print(decodedData);
        financialData.value = FinancialFundamentals.fromJson(decodedData);
      } else {
        // print('Failed to fetch financial fundamentals: ${results[0].statusCode}');
        // Optionally, handle errors (e.g., show user-friendly message)
      }

      // Process the response for EPS data
      if (results[1].statusCode == 200) {
        final decodedData = jsonDecode(results[1].body);
        financialData.value!.updateEPSData(decodedData);
        financialData.refresh();
        // Assuming that the second call (EPS data) is merged into `FinancialFundamentals` or you can handle it separately
        // If needed, you can store EPS in a separate variable (e.g., `epsData`)
        // You may merge it into `financialData` if required
      } else {
        // print('Failed to fetch EPS data: ${results[1].statusCode}');
        // Optionally, handle errors (e.g., show user-friendly message)
      }
    } catch (e) {
      // print('Error fetching data: $e');
      // Optionally, show an error message to the user
    } finally {
      isLoading.value = false;
    }
  }
}


class FinancialFundamentals {
  final Map<String, double?>? revenuePerShareTTM;
  final Map<String, double?>? ebitPerShareTTM;
  final Map<String, double?>? epsTTM;
  final Map<String, double?>? dividendPerShareTTM;
  final String? companySymbol;
  Map<String, double>? epsData; 

  FinancialFundamentals({
    this.revenuePerShareTTM,
    this.ebitPerShareTTM,
    this.epsTTM,
    this.dividendPerShareTTM,
    this.companySymbol,
    this.epsData,
  });

  factory FinancialFundamentals.fromJson(Map<String, dynamic> json) {
    return FinancialFundamentals(
      revenuePerShareTTM: _convertToDoubleMap(json['revenue_per_share']),
      ebitPerShareTTM: _convertToDoubleMap(json['ebit_per_share']),
      epsTTM: _convertToDoubleMap(json['epsTTM']),
      dividendPerShareTTM: _convertToDoubleMap(json['dividendPerShareTTM']),
      
      companySymbol: json['company_symbol'],
    );
  }

  static Map<String, double?>? _convertToDoubleMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data.map((key, value) => MapEntry(key, value?.toDouble()));
  }

  // Add method to update EPS data
  void updateEPSData(Map<String, dynamic> epsResponse) {
    if (epsResponse['hits'] != null) {
      epsData = {};
      for (var hit in epsResponse['hits']) {
        if (hit['document'] != null) {
          var doc = hit['document'];
          String period = doc['period'] ?? '';
          double value = (doc['v'] ?? 0.0).toDouble();
          String year = period.substring(0, 4);
          epsData![year] = value;
        }
      }
    }
  }
}