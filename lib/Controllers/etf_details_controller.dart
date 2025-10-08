import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/etfs_data.dart';
import 'package:musaffa_terminal/web_service.dart';

class EtfDetailsController extends GetxController {
  final RxBool isLoading = true.obs;
  final Rx<EtfsData?> etfData = Rx<EtfsData?>(null);
  final RxString errorMessage = ''.obs;

  Future<void> fetchEtfDetails(String symbol) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Fetch ETF data with profile information
      final response = await WebService.getTypesense([
        'collections',
        'etfs_data',
        'documents',
        'search'
      ], {
        "q": "*",
        "per_page": "200",
        "include_fields": "\$etf_profile_collection_4(name,navCurrency,symbol,description)",
        "filter_by": "\$etf_profile_collection_4(id:*)&&id:=[`$symbol`]"
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List<dynamic>?;
        
        if (hits != null && hits.isNotEmpty) {
          final document = hits[0]['document'] as Map<String, dynamic>;
          etfData.value = EtfsData.fromJson(document);
        } else {
          errorMessage.value = 'No ETF data found for $symbol';
        }
      } else {
        errorMessage.value = 'API failed with status: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      print('Error fetching ETF details: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

