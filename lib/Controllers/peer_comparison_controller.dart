import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/services/sector_mapping_service.dart';

class PeerComparisonController extends GetxController {
  
  final RxList<String> _peerTickers = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Map sector to database format using existing service
  String _mapSectorToDatabase(String sector, String industry) {
    // Use the existing SectorMappingService
    String bucketKey = SectorMappingService.mapSectorToBucket(sector, industry);
    
    // Map bucket keys to database sector names
    switch (bucketKey.toLowerCase()) {
      case 'technology':
        return 'Information Technology';
      case 'financials':
        return 'Financials';
      case 'energy':
        return 'Energy';
      case 'communications':
        return 'Communication Services';
      case 'consumer_goods':
        return 'Consumer Discretionary';
      case 'health_care':
        return 'Health Care';
      case 'industrials':
        return 'Industrials';
      case 'building_materials':
        return 'Materials';
      case 'real_estate':
        return 'Real Estate';
      case 'utilities':
        return 'Utilities';
      default:
        return sector; // Return original if no mapping found
    }
  }

  // Getters
  List<String> get peerTickers => _peerTickers;
  List<String> getTopPeerTickers() => _peerTickers.take(3).toList();
  List<String> getAllPeerTickers() => _peerTickers;

  /// Fetch peer stocks based on sector - simple approach like other controllers
  Future<void> fetchPeerStocks({
    required String currentStockTicker,
    required String sector,
    required String industry,
    String country = 'US',
    int limit = 5,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      
      String mappedSector = _mapSectorToDatabase(sector, industry);
      

      // Filter by country, sector, and exclude current ticker using stocks_data collection
      var params = {
        "q": "*",
        "include_fields": "id,ticker,country,sector,usdMarketCap",
        "filter_by": "country:=$country&&sector:=$mappedSector&&id:!=$currentStockTicker",
        "sort_by": "usdMarketCap:desc", // Sort by descending for biggest market cap peers
        "page": "1",
        "per_page": "${limit + 1}",
      };

      // Use stocks_data collection like your working URL
      final response = await WebService.getTypesense([
        'collections', 'stocks_data', 'documents', 'search'
      ], params);
      
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        var hits = (data['hits'] as List?) ?? [];
        
       
        // Parse the response - only get tickers
        List<String> peerTickers = [];
        for (var hit in hits) {
          var document = hit['document'];
          
          if (document != null && document['ticker'] != null) {
            String ticker = document['ticker'];
            // Skip the current stock
            if (ticker != currentStockTicker) {
              peerTickers.add(ticker);
            }
          }
        }
        
       
        
        _peerTickers.value = peerTickers;
      } else {
        errorMessage.value = 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching peer stocks: $e';
    } finally {
      isLoading.value = false;
    }
  }
}