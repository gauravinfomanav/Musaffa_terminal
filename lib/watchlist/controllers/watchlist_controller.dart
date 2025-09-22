import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_model.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_stock_model.dart';
import 'package:musaffa_terminal/watchlist/models/user_preferences_model.dart';

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
          print('User preferences loaded: ${userPreferences.value?.defaultWatchlistId}');
        }
      }
    } catch (e) {
      print('Error fetching user preferences: $e');
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
        print('Default watchlist set to: $watchlistId');
        return true;
      } else {
        print('Failed to set default watchlist: ${response.errorMessage}');
        return false;
      }
    } catch (e) {
      print('Error setting default watchlist: $e');
      return false;
    } finally {
      isLoadingPreferences.value = false;
    }
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
          
          // Select watchlist based on user preferences or fallback logic
          if (watchlists.isNotEmpty) {
            WatchlistModel? watchlistToSelect;
            
            // First priority: user's default watchlist
            if (userPreferences.value?.defaultWatchlistId != null) {
              final defaultWatchlist = watchlists.where((w) => w.id == userPreferences.value!.defaultWatchlistId);
              if (defaultWatchlist.isNotEmpty) {
                watchlistToSelect = defaultWatchlist.first;
                print('Selected default watchlist: ${watchlistToSelect.name}');
              }
            }
            
            // Second priority: previously selected watchlist (for refresh scenarios)
            if (watchlistToSelect == null && previousSelectedId != null) {
              final matchingWatchlists = watchlists.where((w) => w.id == previousSelectedId);
              if (matchingWatchlists.isNotEmpty) {
                watchlistToSelect = matchingWatchlists.first;
                print('Selected previous watchlist: ${watchlistToSelect.name}');
              }
            }
            
            // Third priority: first watchlist (fallback)
            if (watchlistToSelect == null) {
              watchlistToSelect = watchlists.first;
              print('Selected first watchlist (fallback): ${watchlistToSelect.name}');
            }
            
            selectedWatchlist.value = watchlistToSelect;
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
              
              // If no default watchlist is set, set this new one as default
              if (userPreferences.value?.defaultWatchlistId == null) {
                await setDefaultWatchlist(newWatchlistId);
                print('Set new watchlist as default: ${selectedWatchlist.value?.name}');
              }
            }
          } else {
            // Fallback: select the last watchlist (likely the newest)
            if (watchlists.isNotEmpty) {
              selectedWatchlist.value = watchlists.last;
              fetchWatchlistStocks(selectedWatchlist.value!.id);
              print('Auto-selected last watchlist: ${selectedWatchlist.value?.name}');
              
              // If no default watchlist is set, set this one as default
              if (userPreferences.value?.defaultWatchlistId == null) {
                await setDefaultWatchlist(selectedWatchlist.value!.id);
                print('Set last watchlist as default: ${selectedWatchlist.value?.name}');
              }
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

      print('DEBUG: Adding stocks to watchlist ${selectedWatchlist.value!.id}');
      print('DEBUG: Stocks data: $stocks');

      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['watchlists', selectedWatchlist.value!.id, 'stocks'],
        body: {'stocks': stocks},
      );

      print('DEBUG: API Response status: ${response.status}');
      print('DEBUG: API Response data: ${response.data}');

      if (response.status == ApiStatus.SUCCESS) {
        // Refresh the stocks list to show newly added stocks
        await fetchWatchlistStocks(selectedWatchlist.value!.id);
        return true;
      } else {
        stocksErrorMessage.value = 'Failed to add stocks to watchlist';
        return false;
      }
    } catch (e) {
      print('DEBUG: Error adding stocks: $e');
      stocksErrorMessage.value = 'Error adding stocks: $e';
      return false;
    } finally {
      isLoadingStocks.value = false;
    }
  }
}
