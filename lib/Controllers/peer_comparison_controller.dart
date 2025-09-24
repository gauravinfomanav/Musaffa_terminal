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
    // Check if sector has direct mapping in the new service
    if (SectorMappingService.hasSectorMapping(sector)) {
      List<String>? mappedSectors = SectorMappingService.getMappedSectors(sector);
      if (mappedSectors != null && mappedSectors.isNotEmpty) {
        // Return the first mapped sector as the primary one
        return mappedSectors.first;
      }
    }
    
    // Fallback: return original sector name
    return sector;
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
        
       
        // Parse the response - only get unique tickers
        Set<String> uniqueTickers = {};
        for (var hit in hits) {
          var document = hit['document'];
          
          if (document != null && document['ticker'] != null) {
            String ticker = document['ticker'];
            // Skip the current stock and add to set for deduplication
            if (ticker != currentStockTicker) {
              uniqueTickers.add(ticker);
            }
          }
        }
        
        // Convert set to list to maintain order
        List<String> peerTickers = uniqueTickers.toList();
        
       
        
        _peerTickers.value = peerTickers;
        
        // Debug: Show unique peer tickers
        print("Unique peers: ${peerTickers.take(3).join(', ')}");
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