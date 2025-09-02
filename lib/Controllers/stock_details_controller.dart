import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/models/company_profile.dart';
import 'package:musaffa_terminal/web_service.dart';

class StockDetailsController extends GetxController {
  final RxBool isLoading = true.obs;
  final Rx<StocksData?> stockData = Rx<StocksData?>(null);
  final Rx<CompanyProfile?> companyProfile = Rx<CompanyProfile?>(null);
  final RxString errorMessage = ''.obs;

  Future<void> fetchStockDetails(String ticker) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Fetch stock data
      final stockResponse = await WebService.getTypesense([
        'collections',
        'stocks_data',
        'documents',
        'search'
      ], {
        "q": "*",
        "per_page": "200",
        "include_fields": "\$stocks_data(name,logo,cp_country,city),",
        "filter_by": "\$company_profile_collection_new(id:*)&&id:=[`$ticker`]"
      });

      // Fetch company profile data
      final profileResponse = await WebService.getTypesense([
        'collections',
        'company_profile_collection_new',
        'documents',
        'search'
      ], {
        "q": "*",
        "per_page": "200",
        "include_fields": "id,name,logo,weburl,cp_country,city,phone,address,state,description",
        "filter_by": "id:=[`$ticker`]"
      });

      if (stockResponse.statusCode == 200 && profileResponse.statusCode == 200) {
        final stockData = jsonDecode(stockResponse.body);
        final profileData = jsonDecode(profileResponse.body);
        
        final stockHits = stockData['hits'] as List<dynamic>?;
        final profileHits = profileData['hits'] as List<dynamic>?;
        
        if (stockHits != null && stockHits.isNotEmpty) {
          final document = stockHits[0]['document'] as Map<String, dynamic>;
          this.stockData.value = StocksData.fromJson(document);
        }
        
        if (profileHits != null && profileHits.isNotEmpty) {
          final document = profileHits[0]['document'] as Map<String, dynamic>;
          companyProfile.value = CompanyProfile.fromJson(document);
        }
        
        if (stockHits == null || stockHits.isEmpty) {
          errorMessage.value = 'No stock data found for $ticker';
        }
      } else {
        errorMessage.value = 'API failed with status: ${stockResponse.statusCode} or ${profileResponse.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
