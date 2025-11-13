import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_model.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_stock_model.dart';
import 'package:musaffa_terminal/watchlist/models/user_preferences_model.dart';
import 'package:musaffa_terminal/watchlist/models/target_price_model.dart';

class WatchlistController extends GetxController {
  // Observable variables
  final RxList<WatchlistModel> watchlists = <WatchlistModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<WatchlistModel?> selectedWatchlist = Rx<WatchlistModel?>(null);
  
  // User preferences
  final Rx<UserPreferencesModel?> userPreferences = Rx<UserPreferencesModel?>(null);
  final RxBool isLoadingPreferences = false.obs;
  
  // Stocks for selected watchlist
  final RxList<WatchlistStock> watchlistStocks = <WatchlistStock>[].obs;
  final RxBool isLoadingStocks = false.obs;
  final RxString stocksErrorMessage = ''.obs;

  // Target prices for selected watchlist
  final RxList<TargetPriceModel> targetPrices = <TargetPriceModel>[].obs;
  final RxBool isLoadingTargetPrices = false.obs; // For initial fetch only
  final RxMap<String, bool> loadingTargetPricesByTicker = <String, bool>{}.obs; // Per-ticker loading
  final RxString targetPricesErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserPreferences();
  }

  /// Fetch user preferences
  Future<void> fetchUserPreferences() async {
    try {
      isLoadingPreferences.value = true;

      final response = await WebService.getUserPreferences();

      if (response.status == ApiStatus.SUCCESS) {
        final responseData = jsonDecode(response.data!);
        if (responseData['status'] == 'success') {
          userPreferences.value = UserPreferencesModel.fromJson(responseData['data']);
        }
      }
    } catch (e) {
      // Silently fail - user preferences are optional
    } finally {
      isLoadingPreferences.value = false;
      // After preferences are loaded, fetch watchlists
      fetchWatchlists();
    }
  }

  /// Set default watchlist
  Future<bool> setDefaultWatchlist(String watchlistId) async {
    try {
      isLoadingPreferences.value = true;

      final response = await WebService.setDefaultWatchlist(watchlistId);

      if (response.status == ApiStatus.SUCCESS) {
        // Update local preferences
        if (userPreferences.value != null) {
          userPreferences.value = UserPreferencesModel(
            userId: userPreferences.value!.userId,
            defaultWatchlistId: watchlistId,
            dateSet: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      isLoadingPreferences.value = false;
    }
  }

  /// Fetch all watchlists from API
  /// skipAutoSelect: if true, won't auto-select a watchlist (used when creating new watchlist)
  Future<void> fetchWatchlists({bool skipAutoSelect = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['watchlists'],
      );

      if (response.status == ApiStatus.SUCCESS) {
        final watchlistResponse = WatchlistResponse.fromJsonString(response.data!);
        
        if (watchlistResponse.status == 'success') {
          watchlists.value = watchlistResponse.data;
          
          // Only auto-select if not skipped
          if (!skipAutoSelect) {
            // Select watchlist based on user preferences or fallback logic
            if (watchlists.isNotEmpty) {
              WatchlistModel? watchlistToSelect;
              
              // First priority: user's default watchlist (ALWAYS use if set)
              if (userPreferences.value?.defaultWatchlistId != null) {
                final defaultWatchlist = watchlists.where((w) => w.id == userPreferences.value!.defaultWatchlistId);
                if (defaultWatchlist.isNotEmpty) {
                  watchlistToSelect = defaultWatchlist.first;
                }
              }
              
              // Second priority: first watchlist (fallback if no default)
              if (watchlistToSelect == null) {
                watchlistToSelect = watchlists.first;
              }
              
              selectedWatchlist.value = watchlistToSelect;
              fetchWatchlistStocks(selectedWatchlist.value!.id);
            }
          }
        } else {
          errorMessage.value = 'Failed to fetch watchlists';
        }
      } else {
        errorMessage.value = response.errorMessage ?? 'Network error occurred';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching watchlists: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a watchlist and fetch its stocks
  void selectWatchlist(WatchlistModel watchlist) {
    selectedWatchlist.value = watchlist;
    fetchWatchlistStocks(watchlist.id);
  }

  /// Reset to default watchlist (called when opening watchlist sidebar)
  void resetToDefaultWatchlist() {
    if (watchlists.isEmpty) return;
    
    WatchlistModel? watchlistToSelect;
    
    // First priority: user's default watchlist
    if (userPreferences.value?.defaultWatchlistId != null) {
      final defaultWatchlist = watchlists.where((w) => w.id == userPreferences.value!.defaultWatchlistId);
      if (defaultWatchlist.isNotEmpty) {
        watchlistToSelect = defaultWatchlist.first;
      }
    }
    
    // Fallback: first watchlist
    if (watchlistToSelect == null) {
      watchlistToSelect = watchlists.first;
    }
    
    // Only change if different from current selection
    if (selectedWatchlist.value?.id != watchlistToSelect.id) {
      selectedWatchlist.value = watchlistToSelect;
      fetchWatchlistStocks(watchlistToSelect.id);
    }
  }

  /// Check if watchlists are empty
  bool get isEmpty => watchlists.isEmpty;

  /// Check if watchlists are not empty
  bool get isNotEmpty => watchlists.isNotEmpty;

  /// Get watchlist count
  int get count => watchlists.length;

  /// Refresh watchlists
  Future<void> refresh() async {
    await fetchWatchlists();
  }

  /// Create a new watchlist
  Future<bool> createWatchlist(String name) async {
    if (name.trim().isEmpty) {
      errorMessage.value = 'Watchlist name cannot be empty';
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['watchlists'],
        body: {'name': name.trim()},
      );

      if (response.status == ApiStatus.SUCCESS) {
        // Parse the response to get the new watchlist ID
        try {
          final responseData = jsonDecode(response.data!);
          String? newWatchlistId;
          
          if (responseData['status'] == 'success' && responseData['data'] != null) {
            newWatchlistId = responseData['data']['id'];
          }
          
          // Clear current stocks to show empty state immediately
          watchlistStocks.clear();
          
          // Refresh the watchlists to get the updated list (skip auto-select)
          await fetchWatchlists(skipAutoSelect: true);
          
          // Auto-select the newly created watchlist
          if (newWatchlistId != null) {
            final newWatchlists = watchlists.where((w) => w.id == newWatchlistId);
            if (newWatchlists.isNotEmpty) {
              selectedWatchlist.value = newWatchlists.first;
              await fetchWatchlistStocks(selectedWatchlist.value!.id);
              
              // If no default watchlist is set, set this new one as default
              if (userPreferences.value?.defaultWatchlistId == null) {
                await setDefaultWatchlist(newWatchlistId);
              }
            }
          } else {
            // Fallback: select the last watchlist (likely the newest)
            if (watchlists.isNotEmpty) {
              selectedWatchlist.value = watchlists.last;
              await fetchWatchlistStocks(selectedWatchlist.value!.id);
              
              // If no default watchlist is set, set this one as default
              if (userPreferences.value?.defaultWatchlistId == null) {
                await setDefaultWatchlist(selectedWatchlist.value!.id);
              }
            }
          }
        } catch (parseError) {
          // Still refresh and try to select the newest
          await fetchWatchlists(skipAutoSelect: true);
          if (watchlists.isNotEmpty) {
            selectedWatchlist.value = watchlists.last;
            await fetchWatchlistStocks(selectedWatchlist.value!.id);
          }
        }
        
        return true;
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to create watchlist';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating watchlist: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch stocks for a specific watchlist
  Future<void> fetchWatchlistStocks(String watchlistId) async {
    if (watchlistId.isEmpty) return;

    try {
      isLoadingStocks.value = true;
      stocksErrorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['watchlists', watchlistId, 'stocks'],
      );

      if (response.status == ApiStatus.SUCCESS) {
        final stocksResponse = WatchlistStocksResponse.fromJsonString(response.data!);
        
        if (stocksResponse.status == 'success') {
          watchlistStocks.value = stocksResponse.data;
          // Fetch target prices after stocks are loaded
          await fetchTargetPrices();
        } else {
          stocksErrorMessage.value = 'Failed to fetch stocks';
          watchlistStocks.value = [];
        }
      } else {
        stocksErrorMessage.value = response.errorMessage ?? 'Network error occurred';
        watchlistStocks.value = [];
      }
    } catch (e) {
      stocksErrorMessage.value = 'Error fetching stocks: $e';
      watchlistStocks.value = [];
    } finally {
      isLoadingStocks.value = false;
    }
  }

  /// Check if watchlist stocks are empty
  bool get isStocksEmpty => watchlistStocks.isEmpty;

  /// Check if watchlist stocks are not empty
  bool get isStocksNotEmpty => watchlistStocks.isNotEmpty;

  /// Get stocks count
  int get stocksCount => watchlistStocks.length;

  /// Check if a watchlist is the default watchlist
  bool isDefaultWatchlist(String watchlistId) {
    return userPreferences.value?.defaultWatchlistId == watchlistId;
  }

  /// Get the default watchlist ID
  String? get defaultWatchlistId => userPreferences.value?.defaultWatchlistId;

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
    stocksErrorMessage.value = '';
  }

  /// Add stocks to the selected watchlist
  Future<bool> addStocksToWatchlist(List<Map<String, dynamic>> stocks) async {
    if (selectedWatchlist.value == null) {
      stocksErrorMessage.value = 'No watchlist selected';
      return false;
    }

    try {
      isLoadingStocks.value = true;
      stocksErrorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['watchlists', selectedWatchlist.value!.id, 'stocks'],
        body: {'stocks': stocks},
      );

      if (response.status == ApiStatus.SUCCESS) {
        // Refresh the stocks list to show newly added stocks
        await fetchWatchlistStocks(selectedWatchlist.value!.id);
        return true;
      } else {
        stocksErrorMessage.value = 'Failed to add stocks to watchlist';
        return false;
      }
    } catch (e) {
      stocksErrorMessage.value = 'Error adding stocks: $e';
      return false;
    } finally {
      isLoadingStocks.value = false;
    }
  }

  /// Create a new watchlist and add stocks to it
  Future<bool> addStocksToNewWatchlist(String watchlistName, List<String> stockTickers) async {
    try {
      // First create the watchlist
      final watchlistCreated = await createWatchlist(watchlistName);
      
      if (!watchlistCreated) {
        return false;
      }

      // Fetch real-time prices for the stocks
      final stocksWithPrices = await _fetchRealTimePricesForStocks(stockTickers);

      // Add stocks to the newly created watchlist
      final stocksAdded = await addStocksToWatchlist(stocksWithPrices);
      
      return stocksAdded;
    } catch (e) {
      errorMessage.value = 'Error creating watchlist with stocks: $e';
      return false;
    }
  }

  /// Fetch real-time prices for stocks from Typesense
  Future<List<Map<String, dynamic>>> _fetchRealTimePricesForStocks(List<String> stockTickers) async {
    final stocksToAdd = <Map<String, dynamic>>[];
    
    try {
      // Process stocks in batches of 250 (Typesense limit)
      final batchSize = 250;
      final priceMap = <String, double>{};
      
      for (int i = 0; i < stockTickers.length; i += batchSize) {
        final batch = stockTickers.skip(i).take(batchSize).toList();
        
        final params = {
          'q': '*',
          'filter_by': 'id:=[${batch.map((id) => '`$id`').join(',')}]',
          'include_fields': r'$stocks_data(id,currentPrice)',
          'per_page': '250'
        };
        
        final response = await WebService.getTypesense(['collections', 'stocks_data', 'documents', 'search'], params);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final hits = data['hits'] as List<dynamic>? ?? [];
          
          // Create a map of ticker -> current price
          for (final hit in hits) {
            final document = hit['document'] as Map<String, dynamic>?;
            if (document != null) {
              final ticker = document['id']?.toString() ?? '';
              final price = document['currentPrice']?.toDouble() ?? 0.0;
              if (price > 0) { // Only add if price is valid
                priceMap[ticker] = price;
              }
            }
          }
        }
      }
      
      // Build stocks data with real-time prices
      for (String selectedTicker in stockTickers) {
        final currentPrice = priceMap[selectedTicker] ?? 0.0; // Use 0.0 if no price found
        stocksToAdd.add({
          'ticker': selectedTicker,
          'current_price': currentPrice,
        });
      }
      
    } catch (e) {
      // Fallback: use 0.0 as price if error occurs
      for (String selectedTicker in stockTickers) {
        stocksToAdd.add({
          'ticker': selectedTicker,
          'current_price': 0.0,
        });
      }
    }
    
    return stocksToAdd;
  }

  // Target Price Methods
  /// Fetch target prices for the selected watchlist
  Future<void> fetchTargetPrices() async {
    if (selectedWatchlist.value == null) return;

    try {
      isLoadingTargetPrices.value = true;
      targetPricesErrorMessage.value = '';

      final response = await WebService.getTargetPrices(selectedWatchlist.value!.id);

      if (response.status == ApiStatus.SUCCESS) {
        final responseData = jsonDecode(response.data!);
        if (responseData['status'] == 'success') {
          final List<dynamic> targetsData = responseData['data'] ?? [];
          targetPrices.value = targetsData
              .map((data) => TargetPriceModel.fromJson(data))
              .toList();
        }
      } else {
        targetPricesErrorMessage.value = 'Failed to fetch target prices';
      }
    } catch (e) {
      targetPricesErrorMessage.value = 'Error fetching target prices: $e';
    } finally {
      isLoadingTargetPrices.value = false;
    }
  }

  /// Get target price for a specific ticker
  TargetPriceModel? getTargetPriceForTicker(String ticker) {
    try {
      return targetPrices.firstWhere((target) => target.ticker == ticker);
    } catch (e) {
      return null;
    }
  }

  /// Create a new target price
  Future<void> createTargetPrice(String ticker, double targetPrice, String alertType) async {
    if (selectedWatchlist.value == null) return;

    try {
      loadingTargetPricesByTicker[ticker] = true;
      final response = await WebService.createTargetPrice(
        ticker: ticker,
        targetPrice: targetPrice,
        alertType: alertType,
        watchlistId: selectedWatchlist.value!.id,
      );

      if (response.status == ApiStatus.SUCCESS) {
        // Refresh target prices
        await fetchTargetPrices();
      } else {
        throw Exception('Failed to set target price');
      }
    } catch (e) {
      throw Exception('Error setting target price: $e');
    } finally {
      loadingTargetPricesByTicker[ticker] = false;
    }
  }

  /// Update an existing target price
  Future<void> updateTargetPrice(String targetId, double targetPrice, String alertType) async {
    // Find the ticker for this targetId
    final target = targetPrices.firstWhereOrNull((t) => t.targetId == targetId);
    final ticker = target?.ticker;
    
    try {
      if (ticker != null) {
        loadingTargetPricesByTicker[ticker] = true;
      }
      final response = await WebService.updateTargetPrice(
        targetId: targetId,
        targetPrice: targetPrice,
        alertType: alertType,
      );

      if (response.status == ApiStatus.SUCCESS) {
        // Refresh target prices
        await fetchTargetPrices();
      } else {
        throw Exception('Failed to update target price');
      }
    } catch (e) {
      throw Exception('Error updating target price: $e');
    } finally {
      if (ticker != null) {
        loadingTargetPricesByTicker[ticker] = false;
      }
    }
  }

  /// Delete a target price
  Future<void> deleteTargetPrice(String targetId) async {
    // Find the ticker for this targetId
    final target = targetPrices.firstWhereOrNull((t) => t.targetId == targetId);
    final ticker = target?.ticker;
    
    try {
      if (ticker != null) {
        loadingTargetPricesByTicker[ticker] = true;
      }
      final response = await WebService.deleteTargetPrice(targetId);

      if (response.status == ApiStatus.SUCCESS) {
        // Refresh target prices
        await fetchTargetPrices();
      } else {
        throw Exception('Failed to delete target price');
      }
    } catch (e) {
      throw Exception('Error deleting target price: $e');
    } finally {
      if (ticker != null) {
        loadingTargetPricesByTicker[ticker] = false;
      }
    }
  }
}
