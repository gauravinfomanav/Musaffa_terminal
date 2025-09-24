import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';

class SectorStocksController extends GetxController {
  final RxList<StocksData> _allSectorStocks = <StocksData>[].obs;
  final RxList<StocksData> _sectorStocks = <StocksData>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, String> _logoMap = <String, String>{}.obs;
  
  // Pagination
  final RxInt _currentPage = 0.obs;
  final RxInt _pageSize = 10.obs;
  final RxInt _totalStocks = 0.obs;

  // Getters
  List<StocksData> get sectorStocks => _sectorStocks;
  List<StocksData> get allSectorStocks => _allSectorStocks;
  int get stocksCount => _sectorStocks.length;
  Map<String, String> get logoMap => _logoMap;
  
  // Pagination getters
  int get currentPage => _currentPage.value;
  int get pageSize => _pageSize.value;
  int get totalStocks => _totalStocks.value;
  int get totalPages => (_totalStocks.value / _pageSize.value).ceil();
  bool get hasNextPage => _currentPage.value < totalPages - 1;
  bool get hasPreviousPage => _currentPage.value > 0;

  /// Fetch stocks for a specific sector
  Future<void> fetchStocksBySector({
    required String sectorName,
    String country = 'US',
    int limit = 200, // Increased to fetch all stocks
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      

      // Filter by country, sector, and volume > 0 using stocks_data collection
      var params = {
        "q": "*",
        "include_fields": "id,ticker,country,sector,usdMarketCap,currentPrice,priceChange1DPercent,currency,company_symbol,industry,volume",
        "filter_by": "country:=$country&&sector:=$sectorName&&volume:>0",
        "sort_by": "usdMarketCap:desc", // Sort by descending market cap
        "page": "1",
        "per_page": "$limit",
      };


      // Use stocks_data collection like peer comparison controller
      final response = await WebService.getTypesense([
        'collections', 'stocks_data', 'documents', 'search'
      ], params);
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        var hits = (data['hits'] as List?) ?? [];
        
        
        // Parse the response and create StocksData objects
        List<StocksData> stocks = [];
        List<String> tickers = [];
        
        for (var hit in hits) {
          var document = hit['document'];
          
          if (document != null && document['ticker'] != null) {
            try {
              // Create StocksData object from document
              StocksData stock = StocksData.fromJson(document);
              
              // Additional client-side filter: exclude stocks with 0 or null volume
              if (stock.volume != null && stock.volume! > 0) {
                stocks.add(stock);
                tickers.add(document['ticker']);
              } else {
              }
            } catch (e) {
              // Continue with next stock
            }
          }
        }
        
        // Clear existing logos - will be loaded per page
        _logoMap.value = {};
        
        // Store all stocks and update pagination
        _allSectorStocks.value = stocks;
        _totalStocks.value = stocks.length;
        _currentPage.value = 0;
        _updatePaginatedStocks();
        
n      } else {
        errorMessage.value = 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching sector stocks: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch stocks for multiple sectors (for mapped sectors)
  Future<void> fetchStocksForMappedSectors({
    required List<String> sectorNames,
    String country = 'US',
    int limitPerSector = 200, // Increased to fetch all stocks
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      

      List<StocksData> allStocks = [];
      
      // Fetch stocks for each sector
      for (String sectorName in sectorNames) {
        try {
          var params = {
            "q": "*",
            "include_fields": "id,ticker,country,sector,usdMarketCap,currentPrice,priceChange1DPercent,currency,company_symbol,industry,volume",
            "filter_by": "country:=$country&&sector:=$sectorName&&volume:>0",
            "sort_by": "usdMarketCap:desc",
            "page": "1",
            "per_page": "$limitPerSector",
          };


          final response = await WebService.getTypesense([
            'collections', 'stocks_data', 'documents', 'search'
          ], params);
          
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body) as Map<String, dynamic>;
            var hits = (data['hits'] as List?) ?? [];
            
            
            // Parse the response
            for (var hit in hits) {
              var document = hit['document'];
              
              if (document != null && document['ticker'] != null) {
                try {
                  StocksData stock = StocksData.fromJson(document);
                  
                  // Additional client-side filter: exclude stocks with 0 or null volume
                  if (stock.volume != null && stock.volume! > 0) {
                    allStocks.add(stock);
                  } else {
                  }
                } catch (e) {
                }
              }
            }
          }
        } catch (e) {
          // Continue with next sector
        }
      }
      
      // Remove duplicates based on ticker
      Map<String, StocksData> uniqueStocks = {};
      List<String> uniqueTickers = [];
      for (StocksData stock in allStocks) {
        if (stock.ticker != null && !uniqueStocks.containsKey(stock.ticker)) {
          uniqueStocks[stock.ticker!] = stock;
          uniqueTickers.add(stock.ticker!);
        }
      }
      
      // Clear existing logos - will be loaded per page
      _logoMap.value = {};
      
      // Store all stocks and update pagination
      _allSectorStocks.value = uniqueStocks.values.toList();
      _totalStocks.value = _allSectorStocks.length;
      _currentPage.value = 0;
      _updatePaginatedStocks();
      
      
    } catch (e) {
      errorMessage.value = 'Error fetching mapped sector stocks: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch company logos from company profile collection
  Future<Map<String, String>> _fetchCompanyLogos(List<String> tickers) async {
    Map<String, String> logoMap = {};
    
    if (tickers.isEmpty) return logoMap;
    
    try {
      // Create filter for multiple tickers
      String tickerFilter = tickers.map((ticker) => 'ticker:=$ticker').join('||');
      
      var params = {
        "q": "*",
        "include_fields": "ticker,logo",
        "filter_by": tickerFilter,
        "per_page": "50", // Smaller batch size for better performance
      };


      final response = await WebService.getTypesense([
        'collections', 'company_profile_collection_new', 'documents', 'search'
      ], params);
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        var hits = (data['hits'] as List?) ?? [];
        
        
        for (var hit in hits) {
          var document = hit['document'];
          if (document != null && document['ticker'] != null && document['logo'] != null) {
            logoMap[document['ticker']] = document['logo'];
          }
        }
        
      } else {
      }
    } catch (e) {
    }
    
    return logoMap;
  }

  /// Update paginated stocks based on current page
  void _updatePaginatedStocks() {
    final startIndex = _currentPage.value * _pageSize.value;
    final endIndex = (startIndex + _pageSize.value).clamp(0, _allSectorStocks.length);
    _sectorStocks.value = _allSectorStocks.sublist(startIndex, endIndex);
    
    // Load logos for current page stocks only
    _loadLogosForCurrentPage();
  }
  
  /// Load logos only for stocks on the current page
  Future<void> _loadLogosForCurrentPage() async {
    if (_sectorStocks.isEmpty) return;
    
    // Get tickers for current page
    List<String> currentPageTickers = _sectorStocks
        .where((stock) => stock.ticker != null)
        .map((stock) => stock.ticker!)
        .toList();
    
    if (currentPageTickers.isEmpty) return;
    
    
    // Fetch logos for current page only
    Map<String, String> pageLogos = await _fetchCompanyLogos(currentPageTickers);
    
    // Update logo map with current page logos
    _logoMap.value = {..._logoMap, ...pageLogos};
    
  }
  
  /// Go to next page
  void nextPage() {
    if (hasNextPage) {
      _currentPage.value++;
      _updatePaginatedStocks();
    }
  }
  
  /// Go to previous page
  void previousPage() {
    if (hasPreviousPage) {
      _currentPage.value--;
      _updatePaginatedStocks();
    }
  }
  
  /// Go to specific page
  void goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _currentPage.value = page;
      _updatePaginatedStocks();
    }
  }

  /// Clear the current stocks
  void clearStocks() {
    _allSectorStocks.clear();
    _sectorStocks.clear();
    _logoMap.clear();
    _currentPage.value = 0;
    _totalStocks.value = 0;
    errorMessage.value = '';
  }
}
