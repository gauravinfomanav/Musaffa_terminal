import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Sector mapping data
  Map<String, List<String>> _sectorMapping = {};
  
  // Pagination
  final RxInt _currentPage = 0.obs;
  final RxInt _pageSize = 14.obs;
  final RxInt _totalStocks = 0.obs;
  final RxInt _totalFound = 0.obs; 

  @override
  void onInit() {
    super.onInit();
    _loadSectorMapping();
  }

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
    int perPage = 14,
  }) async {
    try {
      
      isLoading.value = true;
      errorMessage.value = '';
      
      // Build filter query
      String filterQuery = _buildFilterQuery(filters);
      // Default sort if not provided
      String sortQuery = sortBy ?? 'usdMarketCap:desc';
      
      print('Filter selected: $filters');
      print('Query passed: $filterQuery');
      
      var params = {
        "q": "*",
        "include_fields": "id,ticker,country,sector,usdMarketCap,currentPrice,priceChange1DPercent,currency,company_symbol,industry,volume,beta,peTTM,pbAnnual,psTTM,currentDividendYieldTTM,avgVolume10days,avgVolume30days,52WeekHigh,52WeekLow,change1D,sharia_compliance,marketCapClassification,exchange",
        "filter_by": filterQuery,
        "sort_by": sortQuery,
        "page": "$page",
        "per_page": "$perPage",
      };
      

      final response = await WebService.getTypesense([
        'collections', 'stocks_data', 'documents', 'search'
      ], params);
      
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        var hits = (data['hits'] as List?) ?? [];
        var found = data['found'] ?? 0;
        
        
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
              // Skip invalid stock data
            }
          }
        }
        
        
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
          Map<String, String> pageLogos = await _fetchCompanyLogos(tickers);
          Map<String, String> pageNames = await _fetchCompanyNames(tickers);
          
          _logoMap.value = pageLogos;
          _companyNamesMap.value = pageNames;
        }
        
        
      } else {
        errorMessage.value = 'API Error: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Error fetching stocks: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Build filter query from filters map
  String _buildFilterQuery(Map<String, dynamic>? filters) {
    
    List<String> filterParts = [];
    
    // Always include status and isMainTicker
    filterParts.add('status:=PUBLISH');
    filterParts.add('isMainTicker:=1');
    
    // Check if filters are empty or all values are "any"
    bool hasValidFilters = false;
    if (filters != null && filters.isNotEmpty) {
      for (var entry in filters.entries) {
        if (entry.value != null && entry.value != "any" && entry.value.toString().isNotEmpty) {
          hasValidFilters = true;
          break;
        }
      }
    }
    
    if (!hasValidFilters) {
      // Default filter when no valid filters are applied
      String defaultFilter = 'status:=PUBLISH&&isMainTicker:=1&&country:=US&&exchange:=[`NYSE`,`NASDAQ`]';
      return defaultFilter;
    }
    
    // Ensure filters is not null for the rest of the method
    if (filters == null) {
      String defaultFilter = 'status:=PUBLISH&&isMainTicker:=1&&country:=US&&exchange:=[`NYSE`,`NASDAQ`]';
      return defaultFilter;
    }
    
    // Country filter
    if (filters.containsKey('country') && filters['country'] != null && filters['country'] != "any") {
      if (filters['country'] is List) {
        List<String> countries = (filters['country'] as List).map((e) => '`$e`').toList();
        filterParts.add('country:=[${countries.join(',')}]');
      } else {
        filterParts.add('country:=${filters['country']}');
      }
    } else {
      filterParts.add('country:=US'); // Default country
    }
    
    // Currency filter (from UI)
    if (filters.containsKey('currency') && filters['currency'] != null && filters['currency'] != "any") {
      if (filters['currency'] is List) {
        List<String> currencies = (filters['currency'] as List).map((e) => '`$e`').toList();
        filterParts.add('currency:=[${currencies.join(',')}]');
      } else {
        filterParts.add('currency:=${filters['currency']}');
      }
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
      filterParts.add('exchange:=[`NYSE`,`NASDAQ`]'); 
    }
    
    
    // Sector filter with mapping
    if (filters.containsKey('sector') && filters['sector'] != null && filters['sector'] != "any") {
      List<String> mappedSectors = [];
      
      if (filters['sector'] is List) {
        for (String sector in filters['sector']) {
          List<String> apiSectors = _mapSectorToApiValues(sector);
          mappedSectors.addAll(apiSectors);
        }
      } else {
        String sector = filters['sector'].toString();
        List<String> apiSectors = _mapSectorToApiValues(sector);
        mappedSectors.addAll(apiSectors);
      }
      
      if (mappedSectors.isNotEmpty) {
        List<String> quotedSectors = mappedSectors.map((e) => '`$e`').toList();
        filterParts.add('sector:=[${quotedSectors.join(',')}]');
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
    if (filters.containsKey('marketCapClassification') && filters['marketCapClassification'] != null && filters['marketCapClassification'] != "any") {
      String classificationValue = filters['marketCapClassification'].toString();
      
      // Map UI values to API values
      String apiValue;
      switch (classificationValue) {
        case 'Mega Cap':
          apiValue = 'MEGA_CAP';
          break;
        case 'Large Cap':
          apiValue = 'LARGE_CAP';
          break;
        case 'Mid Cap':
          apiValue = 'MID_CAP';
          break;
        case 'Small Cap':
          apiValue = 'SMALL_CAP';
          break;
        case 'Micro Cap':
          apiValue = 'MICRO_CAP';
          break;
        case 'Nano Cap':
          apiValue = 'NANO_CAP';
          break;
        default:
          apiValue = classificationValue;
          break;
      }
      
      filterParts.add('marketCapClassification:=`$apiValue`');
    }
    
    // Market Cap filter (from UI - handle ranges like "300m_2b")
    if (filters.containsKey('marketCap') && filters['marketCap'] != null && filters['marketCap'] != "any") {
      String marketCapValue = filters['marketCap'].toString();
      
      // Handle different market cap ranges
      switch (marketCapValue) {
        case '300m_2b':
          filterParts.add('usdMarketCap:>=300&&usdMarketCap:<=2000');
          break;
        case '2b_10b':
          filterParts.add('usdMarketCap:>=2000&&usdMarketCap:<=10000');
          break;
        case '10b_50b':
          filterParts.add('usdMarketCap:>=10000&&usdMarketCap:<=50000');
          break;
        case '50b_plus':
          filterParts.add('usdMarketCap:>=50000');
          break;
        case 'over_200b':
          filterParts.add('usdMarketCap:>=200000');
          break;
        case 'under_300m':
          filterParts.add('usdMarketCap:<300');
          break;
        default:
          // Try to parse as direct value
          if (marketCapValue.contains('_')) {
            var parts = marketCapValue.split('_');
            if (parts.length == 2) {
              var min = parts[0].replaceAll(RegExp(r'[^\d]'), '');
              var max = parts[1].replaceAll(RegExp(r'[^\d]'), '');
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('usdMarketCap:>=$min&&usdMarketCap:<=$max');
              }
            }
          }
          break;
      }
    }
    
    // Price filter (from UI - handle ranges like "50_100")
    if (filters.containsKey('price') && filters['price'] != null && filters['price'] != "any") {
      String priceValue = filters['price'].toString();
      
      // Handle different price ranges
      switch (priceValue) {
        case 'under_1':
          filterParts.add('currentPrice:<1');
          break;
        case '1_5':
          filterParts.add('currentPrice:>=1&&currentPrice:<=5');
          break;
        case '5_10':
          filterParts.add('currentPrice:>=5&&currentPrice:<=10');
          break;
        case '10_20':
          filterParts.add('currentPrice:>=10&&currentPrice:<=20');
          break;
        case '20_50':
          filterParts.add('currentPrice:>=20&&currentPrice:<=50');
          break;
        case '50_100':
          filterParts.add('currentPrice:>=50&&currentPrice:<=100');
          break;
        case 'over_100':
          filterParts.add('currentPrice:>100');
          break;
        default:
          // Try to parse as direct value
          if (priceValue.contains('_')) {
            var parts = priceValue.split('_');
            if (parts.length == 2) {
              var min = parts[0];
              var max = parts[1];
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('currentPrice:>=$min&&currentPrice:<=$max');
              }
            }
          }
          break;
      }
    }
    
    // Volume filter (from UI - handle ranges like "over_5m")
    if (filters.containsKey('volume') && filters['volume'] != null && filters['volume'] != "any") {
      String volumeValue = filters['volume'].toString();
      
      // Handle different volume ranges
      switch (volumeValue) {
        case 'under_50k':
          filterParts.add('volume:<50000');
          break;
        case '50k_100k':
          filterParts.add('volume:>=50000&&volume:<=100000');
          break;
        case '100k_500k':
          filterParts.add('volume:>=100000&&volume:<=500000');
          break;
        case '500k_1m':
          filterParts.add('volume:>=500000&&volume:<=1000000');
          break;
        case '1m_5m':
          filterParts.add('volume:>=1000000&&volume:<=5000000');
          break;
        case 'over_5m':
          filterParts.add('volume:>5000000');
          break;
        default:
          // Try to parse as direct value
          if (volumeValue.contains('_')) {
            var parts = volumeValue.split('_');
            if (parts.length == 2) {
              var min = parts[0].replaceAll(RegExp(r'[^\d]'), '');
              var max = parts[1].replaceAll(RegExp(r'[^\d]'), '');
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('volume:>=$min&&volume:<=$max');
              }
            }
          }
          break;
      }
    }
    
    // Avg Volume 10 Days filter (from UI - handle ranges like "over_5m")
    if (filters.containsKey('volume10Days') && filters['volume10Days'] != null && filters['volume10Days'] != "any") {
      String volumeValue = filters['volume10Days'].toString();
      
      // Handle different volume ranges
      switch (volumeValue) {
        case 'under_50k':
          filterParts.add('avgVolume10days:<50000');
          break;
        case '50k_100k':
          filterParts.add('avgVolume10days:>=50000&&avgVolume10days:<=100000');
          break;
        case '100k_500k':
          filterParts.add('avgVolume10days:>=100000&&avgVolume10days:<=500000');
          break;
        case '500k_1m':
          filterParts.add('avgVolume10days:>=500000&&avgVolume10days:<=1000000');
          break;
        case '1m_5m':
          filterParts.add('avgVolume10days:>=1000000&&avgVolume10days:<=5000000');
          break;
        case 'over_5m':
          filterParts.add('avgVolume10days:>5000000');
          break;
        default:
          // Try to parse as direct value
          if (volumeValue.contains('_')) {
            var parts = volumeValue.split('_');
            if (parts.length == 2) {
              var min = parts[0].replaceAll(RegExp(r'[^\d]'), '');
              var max = parts[1].replaceAll(RegExp(r'[^\d]'), '');
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('avgVolume10days:>=$min&&avgVolume10days:<=$max');
              }
            }
          }
          break;
      }
    }
    
    // Avg Volume 30 Days filter (from UI - handle ranges like "over_5m")
    if (filters.containsKey('volume30Days') && filters['volume30Days'] != null && filters['volume30Days'] != "any") {
      String volumeValue = filters['volume30Days'].toString();
      
      // Handle different volume ranges
      switch (volumeValue) {
        case 'under_50k':
          filterParts.add('avgVolume30days:<50000');
          break;
        case '50k_100k':
          filterParts.add('avgVolume30days:>=50000&&avgVolume30days:<=100000');
          break;
        case '100k_500k':
          filterParts.add('avgVolume30days:>=100000&&avgVolume30days:<=500000');
          break;
        case '500k_1m':
          filterParts.add('avgVolume30days:>=500000&&avgVolume30days:<=1000000');
          break;
        case '1m_5m':
          filterParts.add('avgVolume30days:>=1000000&&avgVolume30days:<=5000000');
          break;
        case 'over_5m':
          filterParts.add('avgVolume30days:>5000000');
          break;
        default:
          // Try to parse as direct value
          if (volumeValue.contains('_')) {
            var parts = volumeValue.split('_');
            if (parts.length == 2) {
              var min = parts[0].replaceAll(RegExp(r'[^\d]'), '');
              var max = parts[1].replaceAll(RegExp(r'[^\d]'), '');
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('avgVolume30days:>=$min&&avgVolume30days:<=$max');
              }
            }
          }
          break;
      }
    }
    
    // YTD Performance filter (from UI - handle ranges like "under_minus30")
    if (filters.containsKey('priceChangeYTD') && filters['priceChangeYTD'] != null && filters['priceChangeYTD'] != "any") {
      String ytdValue = filters['priceChangeYTD'].toString();
      
      // Handle different YTD performance ranges
      switch (ytdValue) {
        case 'under_minus30':
          filterParts.add('priceChangeYTDPercent:<-30');
          break;
        case 'minus30_minus20':
          filterParts.add('priceChangeYTDPercent:>=-30&&priceChangeYTDPercent:<=-20');
          break;
        case 'minus20_minus10':
          filterParts.add('priceChangeYTDPercent:>=-20&&priceChangeYTDPercent:<=-10');
          break;
        case 'minus10_0':
          filterParts.add('priceChangeYTDPercent:>=-10&&priceChangeYTDPercent:<=0');
          break;
        case '0_10':
          filterParts.add('priceChangeYTDPercent:>=0&&priceChangeYTDPercent:<=10');
          break;
        case '10_20':
          filterParts.add('priceChangeYTDPercent:>=10&&priceChangeYTDPercent:<=20');
          break;
        case '20_30':
          filterParts.add('priceChangeYTDPercent:>=20&&priceChangeYTDPercent:<=30');
          break;
        case 'over_30':
          filterParts.add('priceChangeYTDPercent:>30');
          break;
        default:
          // Try to parse as direct value
          if (ytdValue.contains('_')) {
            var parts = ytdValue.split('_');
            if (parts.length == 2) {
              var min = parts[0].replaceAll('minus', '-');
              var max = parts[1].replaceAll('minus', '-');
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('priceChangeYTDPercent:>=$min&&priceChangeYTDPercent:<=$max');
              }
            }
          }
          break;
      }
    }
    
    // ROE filter (from UI - handle ranges like "over_20")
    if (filters.containsKey('roe') && filters['roe'] != null && filters['roe'] != "any") {
      String roeValue = filters['roe'].toString();
      
      // Handle different ROE ranges
      switch (roeValue) {
        case 'negative':
          filterParts.add('ROE:<0');
          break;
        case '0_5':
          filterParts.add('ROE:>=0&&ROE:<=5');
          break;
        case '5_10':
          filterParts.add('ROE:>=5&&ROE:<=10');
          break;
        case '10_15':
          filterParts.add('ROE:>=10&&ROE:<=15');
          break;
        case '15_20':
          filterParts.add('ROE:>=15&&ROE:<=20');
          break;
        case 'over_20':
          filterParts.add('ROE:>20');
          break;
        default:
          // Try to parse as direct value
          if (roeValue.contains('_')) {
            var parts = roeValue.split('_');
            if (parts.length == 2) {
              var min = parts[0];
              var max = parts[1];
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('ROE:>=$min&&ROE:<=$max');
              }
            }
          }
          break;
      }
    }
    
    // P/E Annual filter
    if (filters.containsKey('peAnnual') && filters['peAnnual'] != null && filters['peAnnual'] != "any") {
      String peValue = filters['peAnnual'].toString();
      
      switch (peValue) {
        case 'under_5':
          filterParts.add('peAnnual:<5');
          break;
        case '5_10':
          filterParts.add('peAnnual:>=5&&peAnnual:<=10');
          break;
        case '10_15':
          filterParts.add('peAnnual:>=10&&peAnnual:<=15');
          break;
        case '15_20':
          filterParts.add('peAnnual:>=15&&peAnnual:<=20');
          break;
        case '20_25':
          filterParts.add('peAnnual:>=20&&peAnnual:<=25');
          break;
        case '25_30':
          filterParts.add('peAnnual:>=25&&peAnnual:<=30');
          break;
        case 'over_30':
          filterParts.add('peAnnual:>30');
          break;
      }
    }
    
    // P/E TTM filter
    if (filters.containsKey('peTTM') && filters['peTTM'] != null && filters['peTTM'] != "any") {
      String peValue = filters['peTTM'].toString();
      
      switch (peValue) {
        case 'under_5':
          filterParts.add('peTTM:<5');
          break;
        case '5_10':
          filterParts.add('peTTM:>=5&&peTTM:<=10');
          break;
        case '10_15':
          filterParts.add('peTTM:>=10&&peTTM:<=15');
          break;
        case '15_20':
          filterParts.add('peTTM:>=15&&peTTM:<=20');
          break;
        case '20_25':
          filterParts.add('peTTM:>=20&&peTTM:<=25');
          break;
        case '25_30':
          filterParts.add('peTTM:>=25&&peTTM:<=30');
          break;
        case 'over_30':
          filterParts.add('peTTM:>30');
          break;
      }
    }
    
    // P/B Annual filter
    if (filters.containsKey('pbAnnual') && filters['pbAnnual'] != null && filters['pbAnnual'] != "any") {
      String pbValue = filters['pbAnnual'].toString();
      
      switch (pbValue) {
        case 'under_1':
          filterParts.add('pbAnnual:<1');
          break;
        case '1_2':
          filterParts.add('pbAnnual:>=1&&pbAnnual:<=2');
          break;
        case '2_3':
          filterParts.add('pbAnnual:>=2&&pbAnnual:<=3');
          break;
        case '3_5':
          filterParts.add('pbAnnual:>=3&&pbAnnual:<=5');
          break;
        case 'over_5':
          filterParts.add('pbAnnual:>5');
          break;
      }
    }
    
    // P/S Annual filter
    if (filters.containsKey('psAnnual') && filters['psAnnual'] != null && filters['psAnnual'] != "any") {
      String psValue = filters['psAnnual'].toString();
      
      switch (psValue) {
        case 'under_1':
          filterParts.add('psAnnual:<1');
          break;
        case '1_2':
          filterParts.add('psAnnual:>=1&&psAnnual:<=2');
          break;
        case '2_3':
          filterParts.add('psAnnual:>=2&&psAnnual:<=3');
          break;
        case '3_5':
          filterParts.add('psAnnual:>=3&&psAnnual:<=5');
          break;
        case '5_10':
          filterParts.add('psAnnual:>=5&&psAnnual:<=10');
          break;
        case 'over_10':
          filterParts.add('psAnnual:>10');
          break;
      }
    }
    
    // P/S TTM filter
    if (filters.containsKey('psTTM') && filters['psTTM'] != null && filters['psTTM'] != "any") {
      String psValue = filters['psTTM'].toString();
      
      switch (psValue) {
        case 'under_1':
          filterParts.add('psTTM:<1');
          break;
        case '1_2':
          filterParts.add('psTTM:>=1&&psTTM:<=2');
          break;
        case '2_3':
          filterParts.add('psTTM:>=2&&psTTM:<=3');
          break;
        case '3_5':
          filterParts.add('psTTM:>=3&&psTTM:<=5');
          break;
        case '5_10':
          filterParts.add('psTTM:>=5&&psTTM:<=10');
          break;
        case 'over_10':
          filterParts.add('psTTM:>10');
          break;
      }
    }
    
    // Current Ratio filter
    if (filters.containsKey('currentRatio') && filters['currentRatio'] != null && filters['currentRatio'] != "any") {
      String ratioValue = filters['currentRatio'].toString();
      
      switch (ratioValue) {
        case 'under_1':
          filterParts.add('currentRatioAnnual:<1');
          break;
        case '1_2':
          filterParts.add('currentRatioAnnual:>=1&&currentRatioAnnual:<=2');
          break;
        case '2_3':
          filterParts.add('currentRatioAnnual:>=2&&currentRatioAnnual:<=3');
          break;
        case 'over_3':
          filterParts.add('currentRatioAnnual:>3');
          break;
      }
    }
    
    // Debt/Equity filter
    if (filters.containsKey('debtEquity') && filters['debtEquity'] != null && filters['debtEquity'] != "any") {
      String debtValue = filters['debtEquity'].toString();
      
      switch (debtValue) {
        case 'under_0.5':
          filterParts.add('totalDebt_totalEquityAnnual:<0.5');
          break;
        case '0.5_1':
          filterParts.add('totalDebt_totalEquityAnnual:>=0.5&&totalDebt_totalEquityAnnual:<=1');
          break;
        case '1_2':
          filterParts.add('totalDebt_totalEquityAnnual:>=1&&totalDebt_totalEquityAnnual:<=2');
          break;
        case 'over_2':
          filterParts.add('totalDebt_totalEquityAnnual:>2');
          break;
      }
    }
    
    // Net Margin filter
    if (filters.containsKey('netMargin') && filters['netMargin'] != null && filters['netMargin'] != "any") {
      String marginValue = filters['netMargin'].toString();
      
      switch (marginValue) {
        case 'negative':
          filterParts.add('netProfitMarginAnnual:<0');
          break;
        case '0_5':
          filterParts.add('netProfitMarginAnnual:>=0&&netProfitMarginAnnual:<=5');
          break;
        case '5_10':
          filterParts.add('netProfitMarginAnnual:>=5&&netProfitMarginAnnual:<=10');
          break;
        case '10_20':
          filterParts.add('netProfitMarginAnnual:>=10&&netProfitMarginAnnual:<=20');
          break;
        case 'over_20':
          filterParts.add('netProfitMarginAnnual:>20');
          break;
      }
    }
    
    // ROI filter
    if (filters.containsKey('roi') && filters['roi'] != null && filters['roi'] != "any") {
      String roiValue = filters['roi'].toString();
      
      switch (roiValue) {
        case 'negative':
          filterParts.add('roiAnnual:<0');
          break;
        case '0_5':
          filterParts.add('roiAnnual:>=0&&roiAnnual:<=5');
          break;
        case '5_10':
          filterParts.add('roiAnnual:>=5&&roiAnnual:<=10');
          break;
        case '10_20':
          filterParts.add('roiAnnual:>=10&&roiAnnual:<=20');
          break;
        case 'over_20':
          filterParts.add('roiAnnual:>20');
          break;
      }
    }
    
    // Dividend Yield filter
    if (filters.containsKey('dividendYield') && filters['dividendYield'] != null && filters['dividendYield'] != "any") {
      String yieldValue = filters['dividendYield'].toString();
      
      switch (yieldValue) {
        case '0':
          filterParts.add('currentDividendYieldTTM:=0');
          break;
        case '0_2':
          filterParts.add('currentDividendYieldTTM:>0&&currentDividendYieldTTM:<=2');
          break;
        case '2_4':
          filterParts.add('currentDividendYieldTTM:>=2&&currentDividendYieldTTM:<=4');
          break;
        case '4_6':
          filterParts.add('currentDividendYieldTTM:>=4&&currentDividendYieldTTM:<=6');
          break;
        case 'over_6':
          filterParts.add('currentDividendYieldTTM:>6');
          break;
      }
    }
    
    // Analyst Recommendation filter (string values: "Buy", "Hold", "Sell", etc.)
    if (filters.containsKey('analystRecommendation') && filters['analystRecommendation'] != null && filters['analystRecommendation'] != "any") {
      String recommendationValue = filters['analystRecommendation'].toString();
      
      switch (recommendationValue) {
        case '1_1.5':
          filterParts.add('analyst_recommendation_weighted_avg:=Strong Buy');
          break;
        case '1.5_2.5':
          filterParts.add('analyst_recommendation_weighted_avg:=Buy');
          break;
        case '2.5_3.5':
          filterParts.add('analyst_recommendation_weighted_avg:=Hold');
          break;
        case '3.5_4.5':
          filterParts.add('analyst_recommendation_weighted_avg:=Sell');
          break;
        case '4.5_5':
          filterParts.add('analyst_recommendation_weighted_avg:=Strong Sell');
          break;
      }
    }
    
    // Gross Margin filter
    if (filters.containsKey('grossMargin') && filters['grossMargin'] != null && filters['grossMargin'] != "any") {
      String marginValue = filters['grossMargin'].toString();
      
      switch (marginValue) {
        case 'negative':
          filterParts.add('grossMarginAnnual:<0');
          break;
        case '0_10':
          filterParts.add('grossMarginAnnual:>=0&&grossMarginAnnual:<=10');
          break;
        case '10_20':
          filterParts.add('grossMarginAnnual:>=10&&grossMarginAnnual:<=20');
          break;
        case '20_30':
          filterParts.add('grossMarginAnnual:>=20&&grossMarginAnnual:<=30');
          break;
        case '30_50':
          filterParts.add('grossMarginAnnual:>=30&&grossMarginAnnual:<=50');
          break;
        case 'over_50':
          filterParts.add('grossMarginAnnual:>50');
          break;
      }
    }
    
    // Operating Margin filter
    if (filters.containsKey('operatingMargin') && filters['operatingMargin'] != null && filters['operatingMargin'] != "any") {
      String marginValue = filters['operatingMargin'].toString();
      
      switch (marginValue) {
        case 'negative':
          filterParts.add('operatingMarginAnnual:<0');
          break;
        case '0_5':
          filterParts.add('operatingMarginAnnual:>=0&&operatingMarginAnnual:<=5');
          break;
        case '5_10':
          filterParts.add('operatingMarginAnnual:>=5&&operatingMarginAnnual:<=10');
          break;
        case '10_15':
          filterParts.add('operatingMarginAnnual:>=10&&operatingMarginAnnual:<=15');
          break;
        case '15_20':
          filterParts.add('operatingMarginAnnual:>=15&&operatingMarginAnnual:<=20');
          break;
        case 'over_20':
          filterParts.add('operatingMarginAnnual:>20');
          break;
      }
    }
    
    // Quick Ratio filter
    if (filters.containsKey('quickRatio') && filters['quickRatio'] != null && filters['quickRatio'] != "any") {
      String ratioValue = filters['quickRatio'].toString();
      
      switch (ratioValue) {
        case 'under_0.5':
          filterParts.add('quickRatioAnnual:<0.5');
          break;
        case '0.5_1':
          filterParts.add('quickRatioAnnual:>=0.5&&quickRatioAnnual:<=1');
          break;
        case '1_1.5':
          filterParts.add('quickRatioAnnual:>=1&&quickRatioAnnual:<=1.5');
          break;
        case '1.5_2':
          filterParts.add('quickRatioAnnual:>=1.5&&quickRatioAnnual:<=2');
          break;
        case 'over_2':
          filterParts.add('quickRatioAnnual:>2');
          break;
      }
    }
    
    // Asset Turnover filter
    if (filters.containsKey('assetTurnover') && filters['assetTurnover'] != null && filters['assetTurnover'] != "any") {
      String turnoverValue = filters['assetTurnover'].toString();
      
      switch (turnoverValue) {
        case 'under_0.5':
          filterParts.add('assetTurnoverAnnual:<0.5');
          break;
        case '0.5_1':
          filterParts.add('assetTurnoverAnnual:>=0.5&&assetTurnoverAnnual:<=1');
          break;
        case '1_1.5':
          filterParts.add('assetTurnoverAnnual:>=1&&assetTurnoverAnnual:<=1.5');
          break;
        case '1.5_2':
          filterParts.add('assetTurnoverAnnual:>=1.5&&assetTurnoverAnnual:<=2');
          break;
        case 'over_2':
          filterParts.add('assetTurnoverAnnual:>2');
          break;
      }
    }
    
    // Inventory Turnover filter
    if (filters.containsKey('inventoryTurnover') && filters['inventoryTurnover'] != null && filters['inventoryTurnover'] != "any") {
      String turnoverValue = filters['inventoryTurnover'].toString();
      
      switch (turnoverValue) {
        case 'under_2':
          filterParts.add('inventoryTurnoverAnnual:<2');
          break;
        case '2_5':
          filterParts.add('inventoryTurnoverAnnual:>=2&&inventoryTurnoverAnnual:<=5');
          break;
        case '5_10':
          filterParts.add('inventoryTurnoverAnnual:>=5&&inventoryTurnoverAnnual:<=10');
          break;
        case '10_20':
          filterParts.add('inventoryTurnoverAnnual:>=10&&inventoryTurnoverAnnual:<=20');
          break;
        case 'over_20':
          filterParts.add('inventoryTurnoverAnnual:>20');
          break;
      }
    }
    
    // Receivables Turnover filter
    if (filters.containsKey('receivablesTurnover') && filters['receivablesTurnover'] != null && filters['receivablesTurnover'] != "any") {
      String turnoverValue = filters['receivablesTurnover'].toString();
      
      switch (turnoverValue) {
        case 'under_2':
          filterParts.add('receivablesTurnoverTTM:<2');
          break;
        case '2_5':
          filterParts.add('receivablesTurnoverTTM:>=2&&receivablesTurnoverTTM:<=5');
          break;
        case '5_10':
          filterParts.add('receivablesTurnoverTTM:>=5&&receivablesTurnoverTTM:<=10');
          break;
        case '10_20':
          filterParts.add('receivablesTurnoverTTM:>=10&&receivablesTurnoverTTM:<=20');
          break;
        case 'over_20':
          filterParts.add('receivablesTurnoverTTM:>20');
          break;
      }
    }
    
    // Payout Ratio filter
    if (filters.containsKey('payoutRatio') && filters['payoutRatio'] != null && filters['payoutRatio'] != "any") {
      String ratioValue = filters['payoutRatio'].toString();
      
      switch (ratioValue) {
        case '0':
          filterParts.add('payoutRatioTTM:=0');
          break;
        case '0_20':
          filterParts.add('payoutRatioTTM:>0&&payoutRatioTTM:<=20');
          break;
        case '20_40':
          filterParts.add('payoutRatioTTM:>=20&&payoutRatioTTM:<=40');
          break;
        case '40_60':
          filterParts.add('payoutRatioTTM:>=40&&payoutRatioTTM:<=60');
          break;
        case 'over_60':
          filterParts.add('payoutRatioTTM:>60');
          break;
      }
    }
    
    // EPS Growth filter
    if (filters.containsKey('epsGrowth') && filters['epsGrowth'] != null && filters['epsGrowth'] != "any") {
      String growthValue = filters['epsGrowth'].toString();
      
      switch (growthValue) {
        case 'negative':
          filterParts.add('eps_growth_1y:<0');
          break;
        case '0_5':
          filterParts.add('eps_growth_1y:>=0&&eps_growth_1y:<=5');
          break;
        case '5_10':
          filterParts.add('eps_growth_1y:>=5&&eps_growth_1y:<=10');
          break;
        case '10_20':
          filterParts.add('eps_growth_1y:>=10&&eps_growth_1y:<=20');
          break;
        case 'over_20':
          filterParts.add('eps_growth_1y:>20');
          break;
      }
    }
    
    // Revenue Growth filter
    if (filters.containsKey('revenueGrowth') && filters['revenueGrowth'] != null && filters['revenueGrowth'] != "any") {
      String growthValue = filters['revenueGrowth'].toString();
      
      switch (growthValue) {
        case 'negative':
          filterParts.add('revenueGrowth1Y:<0');
          break;
        case '0_5':
          filterParts.add('revenueGrowth1Y:>=0&&revenueGrowth1Y:<=5');
          break;
        case '5_10':
          filterParts.add('revenueGrowth1Y:>=5&&revenueGrowth1Y:<=10');
          break;
        case '10_20':
          filterParts.add('revenueGrowth1Y:>=10&&revenueGrowth1Y:<=20');
          break;
        case 'over_20':
          filterParts.add('revenueGrowth1Y:>20');
          break;
      }
    }
    
    // EV/EBIT filter
    if (filters.containsKey('evEbit') && filters['evEbit'] != null && filters['evEbit'] != "any") {
      String evValue = filters['evEbit'].toString();
      
      switch (evValue) {
        case 'under_5':
          filterParts.add('ev_ebit:<5');
          break;
        case '5_10':
          filterParts.add('ev_ebit:>=5&&ev_ebit:<=10');
          break;
        case '10_15':
          filterParts.add('ev_ebit:>=10&&ev_ebit:<=15');
          break;
        case '15_25':
          filterParts.add('ev_ebit:>=15&&ev_ebit:<=25');
          break;
        case 'over_25':
          filterParts.add('ev_ebit:>25');
          break;
      }
    }
    
    // EV/FCF filter
    if (filters.containsKey('evFcf') && filters['evFcf'] != null && filters['evFcf'] != "any") {
      String evValue = filters['evFcf'].toString();
      
      switch (evValue) {
        case 'under_10':
          filterParts.add('ev_fcf:<10');
          break;
        case '10_20':
          filterParts.add('ev_fcf:>=10&&ev_fcf:<=20');
          break;
        case '20_30':
          filterParts.add('ev_fcf:>=20&&ev_fcf:<=30');
          break;
        case '30_50':
          filterParts.add('ev_fcf:>=30&&ev_fcf:<=50');
          break;
        case 'over_50':
          filterParts.add('ev_fcf:>50');
          break;
      }
    }
    
    // Long-term Debt/Equity filter
    if (filters.containsKey('longTermDebtEquity') && filters['longTermDebtEquity'] != null && filters['longTermDebtEquity'] != "any") {
      String debtValue = filters['longTermDebtEquity'].toString();
      
      switch (debtValue) {
        case 'under_0.5':
          filterParts.add('longTermDebt_equityAnnual:<0.5');
          break;
        case '0.5_1':
          filterParts.add('longTermDebt_equityAnnual:>=0.5&&longTermDebt_equityAnnual:<=1');
          break;
        case '1_2':
          filterParts.add('longTermDebt_equityAnnual:>=1&&longTermDebt_equityAnnual:<=2');
          break;
        case '2_5':
          filterParts.add('longTermDebt_equityAnnual:>=2&&longTermDebt_equityAnnual:<=5');
          break;
        case 'over_5':
          filterParts.add('longTermDebt_equityAnnual:>5');
          break;
      }
    }
    
    // Interest Coverage filter
    if (filters.containsKey('interestCoverage') && filters['interestCoverage'] != null && filters['interestCoverage'] != "any") {
      String coverageValue = filters['interestCoverage'].toString();
      
      switch (coverageValue) {
        case 'under_1':
          filterParts.add('netInterestCoverageAnnual:<1');
          break;
        case '1_2':
          filterParts.add('netInterestCoverageAnnual:>=1&&netInterestCoverageAnnual:<=2');
          break;
        case '2_5':
          filterParts.add('netInterestCoverageAnnual:>=2&&netInterestCoverageAnnual:<=5');
          break;
        case '5_10':
          filterParts.add('netInterestCoverageAnnual:>=5&&netInterestCoverageAnnual:<=10');
          break;
        case 'over_10':
          filterParts.add('netInterestCoverageAnnual:>10');
          break;
      }
    }
    
    // Pretax Margin filter
    if (filters.containsKey('pretaxMargin') && filters['pretaxMargin'] != null && filters['pretaxMargin'] != "any") {
      String marginValue = filters['pretaxMargin'].toString();
      
      switch (marginValue) {
        case 'negative':
          filterParts.add('pretaxMarginAnnual:<0');
          break;
        case '0_5':
          filterParts.add('pretaxMarginAnnual:>=0&&pretaxMarginAnnual:<=5');
          break;
        case '5_10':
          filterParts.add('pretaxMarginAnnual:>=5&&pretaxMarginAnnual:<=10');
          break;
        case '10_20':
          filterParts.add('pretaxMarginAnnual:>=10&&pretaxMarginAnnual:<=20');
          break;
        case 'over_20':
          filterParts.add('pretaxMarginAnnual:>20');
          break;
      }
    }
    
    // EPS Annual filter
    if (filters.containsKey('epsAnnual') && filters['epsAnnual'] != null && filters['epsAnnual'] != "any") {
      String epsValue = filters['epsAnnual'].toString();
      
      switch (epsValue) {
        case 'negative':
          filterParts.add('epsAnnual:<0');
          break;
        case 'under_1':
          filterParts.add('epsAnnual:>=0&&epsAnnual:<1');
          break;
        case '1_2':
          filterParts.add('epsAnnual:>=1&&epsAnnual:<2');
          break;
        case '2_5':
          filterParts.add('epsAnnual:>=2&&epsAnnual:<5');
          break;
        case '5_10':
          filterParts.add('epsAnnual:>=5&&epsAnnual:<10');
          break;
        case 'over_10':
          filterParts.add('epsAnnual:>=10');
          break;
      }
    }
    
    // Book Value Per Share filter
    if (filters.containsKey('bookValuePerShare') && filters['bookValuePerShare'] != null && filters['bookValuePerShare'] != "any") {
      String bookValue = filters['bookValuePerShare'].toString();
      
      switch (bookValue) {
        case 'under_5':
          filterParts.add('bookValuePerShareAnnual:<5');
          break;
        case '5_10':
          filterParts.add('bookValuePerShareAnnual:>=5&&bookValuePerShareAnnual:<10');
          break;
        case '10_20':
          filterParts.add('bookValuePerShareAnnual:>=10&&bookValuePerShareAnnual:<20');
          break;
        case '20_50':
          filterParts.add('bookValuePerShareAnnual:>=20&&bookValuePerShareAnnual:<50');
          break;
        case 'over_50':
          filterParts.add('bookValuePerShareAnnual:>=50');
          break;
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
    
    // Equity to Assets filter (from UI)
    if (filters.containsKey('equityToAssets') && filters['equityToAssets'] != null && filters['equityToAssets'] != "any") {
      String equityToAssetsValue = filters['equityToAssets'].toString();
      
      // Handle different equity to assets ranges
      switch (equityToAssetsValue) {
        case '0_20':
          filterParts.add('equity_to_assets_annual:>=0&&equity_to_assets_annual:<=20');
          break;
        case '20_40':
          filterParts.add('equity_to_assets_annual:>=20&&equity_to_assets_annual:<=40');
          break;
        case '40_60':
          filterParts.add('equity_to_assets_annual:>=40&&equity_to_assets_annual:<=60');
          break;
        case '60_80':
          filterParts.add('equity_to_assets_annual:>=60&&equity_to_assets_annual:<=80');
          break;
        case '80_100':
          filterParts.add('equity_to_assets_annual:>=80&&equity_to_assets_annual:<=100');
          break;
        default:
          // Try to parse as direct value
          if (equityToAssetsValue.contains('_')) {
            var parts = equityToAssetsValue.split('_');
            if (parts.length == 2) {
              var min = parts[0];
              var max = parts[1];
              if (min.isNotEmpty && max.isNotEmpty) {
                filterParts.add('equity_to_assets_annual:>=$min&&equity_to_assets_annual:<=$max');
              }
            }
          }
          break;
      }
    }
    
    String finalFilter = filterParts.join('&&');
    return finalFilter;
  }

  /// Fetch company names for a list of tickers
  Future<Map<String, String>> _fetchCompanyNames(List<String> tickers) async {
    Map<String, String> namesMap = {};
    
    if (tickers.isEmpty) return namesMap;
    
    try {
      // Create filter for tickers (batch by 50)
      for (int i = 0; i < tickers.length; i += 50) {
        List<String> batchTickers = tickers.skip(i).take(50).toList();
        final tickerFilter = batchTickers.map((ticker) => 'id:=`$ticker`').join('||');
        
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
    } catch (e) {
    }
    
    return namesMap;
  }

  /// Fetch company logos from company profile collection
  Future<Map<String, String>> _fetchCompanyLogos(List<String> tickers) async {
    Map<String, String> logoMap = {};
    
    if (tickers.isEmpty) return logoMap;
    
    try {
      // Create filter for multiple tickers (batch by 50)
      for (int i = 0; i < tickers.length; i += 50) {
        List<String> batchTickers = tickers.skip(i).take(50).toList();
        String tickerFilter = batchTickers.map((ticker) => 'ticker:=$ticker').join('||');
        
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
    } catch (e) {
    }
    
    return logoMap;
  }

  /// Go to next page
  Future<void> nextPage({Map<String, dynamic>? filters, String? sortBy}) async {
    if (hasNextPage) {
      await fetchStocks(
        filters: filters,
        sortBy: sortBy,
        page: _currentPage.value + 2, // Convert to 1-based index
        perPage: _pageSize.value,
      );
    } else {
    }
  }
  
  /// Go to previous page
  Future<void> previousPage({Map<String, dynamic>? filters, String? sortBy}) async {
    if (hasPreviousPage) {
      await fetchStocks(
        filters: filters,
        sortBy: sortBy,
        page: _currentPage.value, // Current page is 0-based, API needs 1-based
        perPage: _pageSize.value,
      );
    } else {
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
    _allStocks.clear();
    _stocks.clear();
    _logoMap.clear();
    _companyNamesMap.clear();
    _currentPage.value = 0;
    _totalStocks.value = 0;
    _totalFound.value = 0;
    errorMessage.value = '';
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

  /// Load sector mapping from JSON file
  Future<void> _loadSectorMapping() async {
    try {
      final String jsonString = await rootBundle.loadString('lib/utils/sector_api_mapping.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _sectorMapping = jsonData.map((key, value) => 
        MapEntry(key, List<String>.from(value)));
    } catch (e) {
    }
  }

  /// Map UI sector to API sector values
  List<String> _mapSectorToApiValues(String uiSector) {
    // First try direct mapping
    if (_sectorMapping.containsKey(uiSector)) {
      return _sectorMapping[uiSector]!;
    }
    
    // If no direct mapping found, return the original sector
    return [uiSector];
  }
}

