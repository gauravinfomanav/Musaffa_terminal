import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_model.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_stock_model.dart';

class WatchlistController extends GetxController {
  // Observable variables
  final RxList<WatchlistModel> watchlists = <WatchlistModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<WatchlistModel?> selectedWatchlist = Rx<WatchlistModel?>(null);
  
  // Stocks for selected watchlist
  final RxList<WatchlistStock> watchlistStocks = <WatchlistStock>[].obs;
  final RxBool isLoadingStocks = false.obs;
  final RxString stocksErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWatchlists();
  }

  /// Fetch all watchlists from API
  Future<void> fetchWatchlists() async {
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
          final previousSelectedId = selectedWatchlist.value?.id;
          watchlists.value = watchlistResponse.data;
          
          // Try to maintain the same selected watchlist after refresh
          if (previousSelectedId != null) {
            final matchingWatchlists = watchlists.where((w) => w.id == previousSelectedId);
            if (matchingWatchlists.isNotEmpty) {
              selectedWatchlist.value = matchingWatchlists.first;
              fetchWatchlistStocks(selectedWatchlist.value!.id);
            } else if (watchlists.isNotEmpty) {
              selectedWatchlist.value = watchlists.first;
              fetchWatchlistStocks(selectedWatchlist.value!.id);
            }
          } else if (watchlists.isNotEmpty && selectedWatchlist.value == null) {
            // Auto-select first watchlist if available and nothing was selected
            selectedWatchlist.value = watchlists.first;
            fetchWatchlistStocks(selectedWatchlist.value!.id);
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
        print('Create watchlist success: ${response.data}');
        
        // Parse the response to get the new watchlist ID
        try {
          final responseData = jsonDecode(response.data!);
          String? newWatchlistId;
          
          if (responseData['status'] == 'success' && responseData['data'] != null) {
            newWatchlistId = responseData['data']['id'];
          }
          
          // Refresh the watchlists to get the updated list
          await fetchWatchlists();
          
          // Auto-select the newly created watchlist
          if (newWatchlistId != null) {
            final newWatchlists = watchlists.where((w) => w.id == newWatchlistId);
            if (newWatchlists.isNotEmpty) {
              selectedWatchlist.value = newWatchlists.first;
              fetchWatchlistStocks(selectedWatchlist.value!.id);
              print('Auto-selected new watchlist: ${selectedWatchlist.value?.name}');
            }
          } else {
            // Fallback: select the last watchlist (likely the newest)
            if (watchlists.isNotEmpty) {
              selectedWatchlist.value = watchlists.last;
              fetchWatchlistStocks(selectedWatchlist.value!.id);
              print('Auto-selected last watchlist: ${selectedWatchlist.value?.name}');
            }
          }
        } catch (parseError) {
          print('Error parsing create response: $parseError');
          // Still refresh and try to select the newest
          await fetchWatchlists();
          if (watchlists.isNotEmpty) {
            selectedWatchlist.value = watchlists.last;
            fetchWatchlistStocks(selectedWatchlist.value!.id);
          }
        }
        
        return true;
      } else {
        print('Create watchlist failed: ${response.errorMessage}');
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
          print('Fetched ${stocksResponse.count} stocks for watchlist: $watchlistId');
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

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
    stocksErrorMessage.value = '';
  }
}
