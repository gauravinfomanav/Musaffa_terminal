import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';

/// Controller for filtering and displaying stocks with pagination
/// 
/// Usage Example:
/// ```dart
/// final filterController = Get.put(FilterController());
/// 
/// // Fetch stocks with default filters (no filters applied)
/// await filterController.fetchStocks();
/// 
/// // Fetch stocks with custom filters
/// await filterController.fetchStocks(
///   filters: {
///     'sector': 'Technology',
///     'sharia_compliance': ['COMPLIANT'],
///     'usdMarketCapMin': 1000, // in millions
///     'priceChange1DPercentMin': 0,
///   },
///   sortBy: 'priceChange1DPercent:desc',
/// );
/// 
/// // Convert to SimpleRowModel for DynamicTable (similar to sector_details_screen.dart)
/// List<SimpleRowModel> rows = filterController.stocks.map((stock) {
///   final isPositive = (stock.priceChange1DPercent ?? 0) >= 0;
///   final changeColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
///   
///   return SimpleRowModel(
///     symbol: stock.ticker ?? '',
///     name: filterController.companyNamesMap[stock.ticker] ?? stock.companySymbol ?? stock.ticker ?? '',
///     logo: filterController.logoMap[stock.ticker],
///     price: stock.currentPrice,
///     changePercent: stock.priceChange1DPercent,
///     currency: stock.currency ?? 'USD',
///     fields: {
///       'price': stock.currentPrice != null ? '\$${stock.currentPrice!.toStringAsFixed(2)}' : '--',
///       'change': stock.priceChange1DPercent != null ? '${stock.priceChange1DPercent! >= 0 ? '+' : ''}${stock.priceChange1DPercent!.toStringAsFixed(2)}%' : '--',
///       'marketCap': stock.usdMarketCap != null ? getShortenedT(stock.usdMarketCap! * 1000000) : '--',
///       'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
///       // Add more fields as needed
///     },
///     changeColor: changeColor,
///     isPositive: isPositive,
///   );
/// }).toList();
/// 
/// // Use with DynamicTable
/// DynamicTable(
///   columns: const [
///     SimpleColumn(label: 'PRICE', fieldName: 'price', isNumeric: true),
///     SimpleColumn(label: 'CHANGE %', fieldName: 'change', isNumeric: true),
///     SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
///     SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
///   ],
///   rows: rows,
///   showFixedColumn: true,
///   enableLivePrices: true,
/// )
/// ```
class FilterController extends GetxController {
  final RxList<StocksData> _allStocks = <StocksData>[].obs;
  final RxList<StocksData> _stocks = <StocksData>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, String> _logoMap = <String, String>{}.obs;
  final RxMap<String, String> _companyNamesMap = <String, String>{}.obs;
  
  // Pagination
  final RxInt _currentPage = 0.obs;
  final RxInt _pageSize = 15.obs;
  final RxInt _totalStocks = 0.obs;
  final RxInt _totalFound = 0.obs; 

  // Getters
  List<StocksData> get stocks => _stocks;
  List<StocksData> get allStocks => _allStocks;
  int get stocksCount => _stocks.length;
  Map<String, String> get logoMap => _logoMap;
  Map<String, String> get companyNamesMap => _companyNamesMap;
  
  // Pagination getters
  int get currentPage => _currentPage.value;
  int get pageSize => _pageSize.value;
  int get totalStocks => _totalStocks.value;
  int get totalFound => _totalFound.value;
  int get totalPages => (_totalFound.value / _pageSize.value).ceil();
  bool get hasNextPage => _currentPage.value < totalPages - 1;
  bool get hasPreviousPage => _currentPage.value > 0;

  Future<void> fetchStocks({
    Map<String, dynamic>? filters,
    String? sortBy,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      print('📊 [FilterController] fetchStocks called');
      print('   Filters: $filters');
      print('   Sort: ${sortBy ?? 'usdMarketCap:desc'}');
      print('   Page: $page, PerPage: $perPage');
      
      isLoading.value = true;
      errorMessage.value = '';
      
      // Build filter query
      String filterQuery = _buildFilterQuery(filters);
      print('   Built filter query: $filterQuery');
      
      // Default sort if not provided
      String sortQuery = sortBy ?? 'usdMarketCap:desc';
      
      var params = {
        "q": "*",
        "include_fields": "id,ticker,country,sector,usdMarketCap,currentPrice,priceChange1DPercent,currency,company_symbol,industry,volume,beta,peTTM,pbAnnual,psTTM,currentDividendYieldTTM,avgVolume10days,avgVolume30days,52WeekHigh,52WeekLow,change1D,sharia_compliance,marketCapClassification,exchange",
        "filter_by": filterQuery,
        "sort_by": sortQuery,
        "page": "$page",
        "per_page": "$perPage",
      };
      
      print('   API params: $params');

      final response = await WebService.getTypesense([
        'collections', 'stocks_data', 'documents', 'search'
      ], params);
      
      print('   API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        var hits = (data['hits'] as List?) ?? [];
        var found = data['found'] ?? 0;
        
        print('✅ [FilterController] API Success');
        print('   Found: $found results');
        print('   Hits returned: ${hits.length}');
        
        // Update total found
        _totalFound.value = found;
        
        // Parse the response and create StocksData objects
        List<StocksData> stocks = [];
        List<String> tickers = [];
        
        for (var hit in hits) {
          var document = hit['document'];
          
          if (document != null && document['ticker'] != null) {
            try {
              // Create StocksData object from document
              StocksData stock = StocksData.fromJson(document);
              stocks.add(stock);
              tickers.add(document['ticker']);
            } catch (e) {
              print('⚠️ [FilterController] Error parsing stock: ${document['ticker']} - $e');
            }
          }
        }
        
        print('   Successfully parsed ${stocks.length} stocks');
        print('   Tickers: ${tickers.take(5).join(", ")}${tickers.length > 5 ? "..." : ""}');
        
        // Clear existing logos - will be loaded per page
        _logoMap.value = {};
        _companyNamesMap.value = {};
        
        // Store stocks and update pagination
        _allStocks.value = stocks;
        _stocks.value = stocks;
        _totalStocks.value = stocks.length;
        _currentPage.value = page - 1; // Convert to 0-based index
        
        // Load logos and company names for current page
        if (tickers.isNotEmpty) {
          print('   Fetching logos and names for ${tickers.length} tickers...');
          Map<String, String> pageLogos = await _fetchCompanyLogos(tickers);
          Map<String, String> pageNames = await _fetchCompanyNames(tickers);
          
          print('   Fetched ${pageLogos.length} logos and ${pageNames.length} names');
          
          _logoMap.value = pageLogos;
          _companyNamesMap.value = pageNames;
        }
        
        print('🎉 [FilterController] fetchStocks completed successfully');
        
      } else {
        print('❌ [FilterController] API Error: ${response.statusCode}');
        print('   Response body: ${response.body}');
        errorMessage.value = 'API Error: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      print('❌ [FilterController] Exception: $e');
      print('   Stack trace: $stackTrace');
      errorMessage.value = 'Error fetching stocks: $e';
    } finally {
      isLoading.value = false;
      print('   Loading state: ${isLoading.value}');
    }
  }

  /// Build filter query from filters map
  String _buildFilterQuery(Map<String, dynamic>? filters) {
    print('🔍 [FilterController] Building filter query');
    print('   Input filters: $filters');
    
    if (filters == null || filters.isEmpty) {
      // Default filter when no filters are applied
      String defaultFilter = 'status:=PUBLISH&&isMainTicker:=1&&country:=US&&exchange:=[`NYSE`,`NASDAQ`,`XASE`]&&sharia_compliance:=[`COMPLIANT`,`NON_COMPLIANT`,`QUESTIONABLE`]';
      print('   Using default filter: $defaultFilter');
      return defaultFilter;
    }
    
    List<String> filterParts = [];
    
    // Always include status and isMainTicker
    filterParts.add('status:=PUBLISH');
    filterParts.add('isMainTicker:=1');
    
    // Country filter
    if (filters.containsKey('country')) {
      if (filters['country'] is List) {
        List<String> countries = (filters['country'] as List).map((e) => '`$e`').toList();
        filterParts.add('country:=[${countries.join(',')}]');
      } else {
        filterParts.add('country:=${filters['country']}');
      }
    } else {
      filterParts.add('country:=US'); // Default country
    }
    
    // Exchange filter
    if (filters.containsKey('exchange')) {
      if (filters['exchange'] is List) {
        List<String> exchanges = (filters['exchange'] as List).map((e) => '`$e`').toList();
        filterParts.add('exchange:=[${exchanges.join(',')}]');
      } else {
        filterParts.add('exchange:=${filters['exchange']}');
      }
    } else {
      filterParts.add('exchange:=[`NYSE`,`NASDAQ`,`XASE`]'); // Default exchanges
    }
    
    // Sharia compliance filter
    if (filters.containsKey('sharia_compliance')) {
      if (filters['sharia_compliance'] is List) {
        List<String> compliance = (filters['sharia_compliance'] as List).map((e) => '`$e`').toList();
        filterParts.add('sharia_compliance:=[${compliance.join(',')}]');
      } else {
        filterParts.add('sharia_compliance:=${filters['sharia_compliance']}');
      }
    } else {
      filterParts.add('sharia_compliance:=[`COMPLIANT`,`NON_COMPLIANT`,`QUESTIONABLE`]'); // Default compliance
    }
    
    // Sector filter
    if (filters.containsKey('sector')) {
      if (filters['sector'] is List) {
        List<String> sectors = (filters['sector'] as List).map((e) => '`$e`').toList();
        filterParts.add('sector:=[${sectors.join(',')}]');
      } else {
        filterParts.add('sector:=${filters['sector']}');
      }
    }
    
    // Industry filter
    if (filters.containsKey('industry')) {
      if (filters['industry'] is List) {
        List<String> industries = (filters['industry'] as List).map((e) => '`$e`').toList();
        filterParts.add('industry:=[${industries.join(',')}]');
      } else {
        filterParts.add('industry:=${filters['industry']}');
      }
    }
    
    // Market cap classification filter
    if (filters.containsKey('marketCapClassification')) {
      if (filters['marketCapClassification'] is List) {
        List<String> classifications = (filters['marketCapClassification'] as List).map((e) => '`$e`').toList();
        filterParts.add('marketCapClassification:=[${classifications.join(',')}]');
      } else {
        filterParts.add('marketCapClassification:=${filters['marketCapClassification']}');
      }
    }
    
    // Numeric range filters
    // Market cap range (in millions)
    if (filters.containsKey('usdMarketCapMin')) {
      filterParts.add('usdMarketCap:>=${filters['usdMarketCapMin']}');
    }
    if (filters.containsKey('usdMarketCapMax')) {
      filterParts.add('usdMarketCap:<=${filters['usdMarketCapMax']}');
    }
    
    // Price range
    if (filters.containsKey('currentPriceMin')) {
      filterParts.add('currentPrice:>=${filters['currentPriceMin']}');
    }
    if (filters.containsKey('currentPriceMax')) {
      filterParts.add('currentPrice:<=${filters['currentPriceMax']}');
    }
    
    // Volume range
    if (filters.containsKey('volumeMin')) {
      filterParts.add('volume:>=${filters['volumeMin']}');
    }
    if (filters.containsKey('volumeMax')) {
      filterParts.add('volume:<=${filters['volumeMax']}');
    }
    
    // PE Ratio range
    if (filters.containsKey('peTTMMin')) {
      filterParts.add('peTTM:>=${filters['peTTMMin']}');
    }
    if (filters.containsKey('peTTMMax')) {
      filterParts.add('peTTM:<=${filters['peTTMMax']}');
    }
    
    // Price change range
    if (filters.containsKey('priceChange1DPercentMin')) {
      filterParts.add('priceChange1DPercent:>=${filters['priceChange1DPercentMin']}');
    }
    if (filters.containsKey('priceChange1DPercentMax')) {
      filterParts.add('priceChange1DPercent:<=${filters['priceChange1DPercentMax']}');
    }
    
    // Beta range
    if (filters.containsKey('betaMin')) {
      filterParts.add('beta:>=${filters['betaMin']}');
    }
    if (filters.containsKey('betaMax')) {
      filterParts.add('beta:<=${filters['betaMax']}');
    }
    
    // Dividend yield range
    if (filters.containsKey('currentDividendYieldTTMMin')) {
      filterParts.add('currentDividendYieldTTM:>=${filters['currentDividendYieldTTMMin']}');
    }
    if (filters.containsKey('currentDividendYieldTTMMax')) {
      filterParts.add('currentDividendYieldTTM:<=${filters['currentDividendYieldTTMMax']}');
    }
    
    String finalFilter = filterParts.join('&&');
    print('   Final filter: $finalFilter');
    return finalFilter;
  }

  /// Fetch company names for a list of tickers
  Future<Map<String, String>> _fetchCompanyNames(List<String> tickers) async {
    Map<String, String> namesMap = {};
    
    if (tickers.isEmpty) return namesMap;
    
    try {
      print('   📝 Fetching company names for ${tickers.length} tickers');
      // Create filter for tickers (batch by 50)
      for (int i = 0; i < tickers.length; i += 50) {
        List<String> batchTickers = tickers.skip(i).take(50).toList();
        final tickerFilter = batchTickers.map((ticker) => 'id:=`$ticker`').join('||');
        print('      Batch ${(i ~/ 50) + 1}: ${batchTickers.length} tickers');
        
        var params = {
          "q": "*",
          "include_fields": "id,name",
          "filter_by": tickerFilter,
          "per_page": "50",
        };

        final response = await WebService.getTypesense([
          'collections', 'company_profile_collection_new', 'documents', 'search'
        ], params);
        
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body) as Map<String, dynamic>;
          var hits = (data['hits'] as List?) ?? [];
          
          for (var hit in hits) {
            var document = hit['document'];
            if (document != null && document['id'] != null && document['name'] != null) {
              namesMap[document['id']] = document['name'];
            }
          }
        }
      }
      print('   ✅ Fetched ${namesMap.length} company names');
    } catch (e) {
      print('   ⚠️ Error fetching company names: $e');
    }
    
    return namesMap;
  }

  /// Fetch company logos from company profile collection
  Future<Map<String, String>> _fetchCompanyLogos(List<String> tickers) async {
    Map<String, String> logoMap = {};
    
    if (tickers.isEmpty) return logoMap;
    
    try {
      print('   🖼️  Fetching company logos for ${tickers.length} tickers');
      // Create filter for multiple tickers (batch by 50)
      for (int i = 0; i < tickers.length; i += 50) {
        List<String> batchTickers = tickers.skip(i).take(50).toList();
        String tickerFilter = batchTickers.map((ticker) => 'ticker:=$ticker').join('||');
        print('      Batch ${(i ~/ 50) + 1}: ${batchTickers.length} tickers');
        
        var params = {
          "q": "*",
          "include_fields": "ticker,logo",
          "filter_by": tickerFilter,
          "per_page": "50",
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
        }
      }
      print('   ✅ Fetched ${logoMap.length} company logos');
    } catch (e) {
      print('   ⚠️ Error fetching company logos: $e');
    }
    
    return logoMap;
  }

  /// Go to next page
  Future<void> nextPage({Map<String, dynamic>? filters, String? sortBy}) async {
    print('➡️ [FilterController] nextPage called');
    if (hasNextPage) {
      await fetchStocks(
        filters: filters,
        sortBy: sortBy,
        page: _currentPage.value + 2, // Convert to 1-based index
        perPage: _pageSize.value,
      );
    } else {
      print('   ⚠️ No next page available');
    }
  }
  
  /// Go to previous page
  Future<void> previousPage({Map<String, dynamic>? filters, String? sortBy}) async {
    print('⬅️ [FilterController] previousPage called');
    if (hasPreviousPage) {
      await fetchStocks(
        filters: filters,
        sortBy: sortBy,
        page: _currentPage.value, // Current page is 0-based, API needs 1-based
        perPage: _pageSize.value,
      );
    } else {
      print('   ⚠️ No previous page available');
    }
  }
  
  /// Go to specific page
  Future<void> goToPage(int page, {Map<String, dynamic>? filters, String? sortBy}) async {
    if (page >= 0 && page < totalPages) {
      await fetchStocks(
        filters: filters,
        sortBy: sortBy,
        page: page + 1, // Convert to 1-based index
        perPage: _pageSize.value,
      );
    }
  }

  /// Refresh data with current page
  Future<void> refresh({Map<String, dynamic>? filters, String? sortBy}) async {
    await fetchStocks(
      filters: filters,
      sortBy: sortBy,
      page: _currentPage.value + 1,
      perPage: _pageSize.value,
    );
  }

  /// Clear the current stocks
  void clearStocks() {
    print('🧹 [FilterController] Clearing all stocks');
    _allStocks.clear();
    _stocks.clear();
    _logoMap.clear();
    _companyNamesMap.clear();
    _currentPage.value = 0;
    _totalStocks.value = 0;
    _totalFound.value = 0;
    errorMessage.value = '';
    print('   ✅ Cleared');
  }

  /// Change page size
  Future<void> setPageSize(int newPageSize, {Map<String, dynamic>? filters, String? sortBy}) async {
    _pageSize.value = newPageSize;
    // Reset to first page when changing page size
    await fetchStocks(
      filters: filters,
      sortBy: sortBy,
      page: 1,
      perPage: newPageSize,
    );
  }
}

