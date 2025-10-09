import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/etfs_data.dart';
import 'package:musaffa_terminal/models/etf_holdings_model.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/models/company_profile.dart';
import 'package:musaffa_terminal/web_service.dart';

class EtfDetailsController extends GetxController {
  final RxBool isLoading = true.obs;
  final Rx<EtfsData?> etfData = Rx<EtfsData?>(null);
  final RxString errorMessage = ''.obs;
  
  // Holdings data
  final RxBool isLoadingHoldings = false.obs;
  final Rx<EtfHoldingsData?> holdingsData = Rx<EtfHoldingsData?>(null);
  final RxString holdingsErrorMessage = ''.obs;
  
  // Enriched holdings with stock data
  final RxList<EtfHoldingWithStockData> enrichedHoldings = <EtfHoldingWithStockData>[].obs;
  
  // Pagination for holdings
  final RxInt currentHoldingsPage = 0.obs;
  final RxInt holdingsPerPage = 10.obs;
  final RxInt totalHoldingsPages = 0.obs;
  
  // Preloaded data cache - ETF specific
  final Map<String, Map<int, List<EtfHoldingWithStockData>>> _preloadedPagesCache = {};
  
  // Current ETF symbol for cache management
  String? _currentEtfSymbol;
  
  Map<int, List<EtfHoldingWithStockData>> get _preloadedPages {
    if (_currentEtfSymbol == null) return {};
    return _preloadedPagesCache[_currentEtfSymbol!] ?? {};
  }

  Future<void> fetchEtfDetails(String symbol) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Set current ETF symbol and clear previous cache
      _currentEtfSymbol = symbol;
      enrichedHoldings.clear();
      currentHoldingsPage.value = 0;

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

  Future<void> fetchEtfHoldings(String symbol) async {
    try {
      isLoadingHoldings.value = true;
      holdingsErrorMessage.value = '';
      enrichedHoldings.clear();

      // Fetch ETF holdings data
      final response = await WebService.getTypesense([
        'collections',
        'etf_holdings_collection_2',
        'documents',
        symbol
      ], {});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        holdingsData.value = EtfHoldingsData.fromJson(data);
        
        // Calculate pagination
        final allHoldings = holdingsData.value?.holdings ?? [];
        // Sort all holdings by weight (highest first) BEFORE pagination
        allHoldings.sort((a, b) => b.percent.compareTo(a.percent));
        totalHoldingsPages.value = (allHoldings.length / holdingsPerPage.value).ceil();
        
        // Load first page
        await loadHoldingsPage(0);
      } else {
        holdingsErrorMessage.value = 'Holdings API failed with status: ${response.statusCode}';
      }
    } catch (e) {
      holdingsErrorMessage.value = 'Error fetching holdings: $e';
      print('Error fetching ETF holdings: $e');
    } finally {
      // Don't set loading to false here - let loadHoldingsPage handle it
    }
  }

  Future<void> loadHoldingsPage(int page) async {
    if (holdingsData.value == null) return;
    
    try {
      isLoadingHoldings.value = true;
      currentHoldingsPage.value = page;
      
      // Check if page is already preloaded for current ETF
      if (_preloadedPages.containsKey(page)) {
        enrichedHoldings.value = _preloadedPages[page]!;
        isLoadingHoldings.value = false;
        
        // Pre-load multiple pages in background (regardless of which page we're on)
        _preloadMultiplePages();
        return;
      }
      
      final allHoldings = holdingsData.value!.holdings;
      final startIndex = page * holdingsPerPage.value;
      final endIndex = (startIndex + holdingsPerPage.value).clamp(0, allHoldings.length);
      final pageHoldings = allHoldings.sublist(startIndex, endIndex);
      
      // Load current page data
      final pageData = await _enrichHoldingsWithStockData(pageHoldings);
      enrichedHoldings.value = pageData;
      
      // Cache this page for current ETF
      if (_currentEtfSymbol != null) {
        _preloadedPagesCache[_currentEtfSymbol!] ??= {};
        _preloadedPagesCache[_currentEtfSymbol!]![page] = pageData;
      }
      
      // Pre-load multiple pages in background for instant navigation
      _preloadMultiplePages();
    } catch (e) {
      print('Error loading holdings page: $e');
    } finally {
      isLoadingHoldings.value = false;
    }
  }


  /// Pre-load multiple pages ahead for even faster navigation
  Future<void> _preloadMultiplePages() async {
    if (_currentEtfSymbol == null) return;
    
    final currentPage = currentHoldingsPage.value;
    final pagesToPreload = [currentPage + 1, currentPage + 2, currentPage + 3];
    
    for (final pageIndex in pagesToPreload) {
      if (pageIndex >= totalHoldingsPages.value) break;
      if (_preloadedPages.containsKey(pageIndex)) continue;
      
      final startIndex = pageIndex * holdingsPerPage.value;
      final endIndex = (startIndex + holdingsPerPage.value).clamp(0, holdingsData.value!.holdings.length);
      
      if (startIndex >= holdingsData.value!.holdings.length) break;
      
      final pageHoldings = holdingsData.value!.holdings.sublist(startIndex, endIndex);
      
      // Pre-load in background
      _enrichHoldingsWithStockData(pageHoldings).then((preloadedData) {
        if (_currentEtfSymbol != null) {
          _preloadedPagesCache[_currentEtfSymbol!] ??= {};
          _preloadedPagesCache[_currentEtfSymbol!]![pageIndex] = preloadedData;
        }
      }).catchError((e) {
        print('Error preloading page $pageIndex: $e');
      });
    }
  }

  void nextHoldingsPage() {
    if (currentHoldingsPage.value < totalHoldingsPages.value - 1) {
      loadHoldingsPage(currentHoldingsPage.value + 1);
    }
  }

  void previousHoldingsPage() {
    if (currentHoldingsPage.value > 0) {
      loadHoldingsPage(currentHoldingsPage.value - 1);
    }
  }

  void goToHoldingsPage(int page) {
    if (page >= 0 && page < totalHoldingsPages.value) {
      loadHoldingsPage(page);
    }
  }

  bool get hasNextHoldingsPage => currentHoldingsPage.value < totalHoldingsPages.value - 1;
  bool get hasPreviousHoldingsPage => currentHoldingsPage.value > 0;

  Future<List<EtfHoldingWithStockData>> _enrichHoldingsWithStockData(List<EtfHolding> holdings) async {
    final enrichedList = <EtfHoldingWithStockData>[];
    
    for (final holding in holdings) {
      try {
        // Fetch stock data
        final stockResponse = await WebService.getTypesense([
          'collections',
          'stocks_data',
          'documents',
          'search'
        ], {
          "q": "*",
          "per_page": "200",
          "include_fields": "*,\$company_profile_collection_new(name,logo,cp_country,city)",
          "filter_by": "\$company_profile_collection_new(id:*)&&id:=[`${holding.symbol}`]"
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
          "filter_by": "id:=[`${holding.symbol}`]"
        });

        StocksData? stockData;
        CompanyProfile? companyProfile;

        if (stockResponse.statusCode == 200) {
          final stockDataJson = jsonDecode(stockResponse.body);
          final stockHits = stockDataJson['hits'] as List<dynamic>?;
          if (stockHits != null && stockHits.isNotEmpty) {
            final document = stockHits[0]['document'] as Map<String, dynamic>;
            stockData = StocksData.fromJson(document);
          }
        }

        if (profileResponse.statusCode == 200) {
          final profileDataJson = jsonDecode(profileResponse.body);
          final profileHits = profileDataJson['hits'] as List<dynamic>?;
          if (profileHits != null && profileHits.isNotEmpty) {
            final document = profileHits[0]['document'] as Map<String, dynamic>;
            companyProfile = CompanyProfile.fromJson(document);
          }
        }

        enrichedList.add(EtfHoldingWithStockData(
          holding: holding,
          stockData: stockData,
          companyProfile: companyProfile,
        ));
      } catch (e) {
        print('Error fetching stock data for ${holding.symbol}: $e');
        // Add holding without stock data
        enrichedList.add(EtfHoldingWithStockData(
          holding: holding,
          stockData: null,
          companyProfile: null,
        ));
      }
    }
    
    return enrichedList;
  }
}

