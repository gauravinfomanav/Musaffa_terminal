import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/screener_strategy.dart';
import 'package:musaffa_terminal/web_service.dart';

class ScreenerStrategyController extends GetxController {
  final RxList<ScreenerStrategy> strategies = <ScreenerStrategy>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Save a new strategy
  Future<ScreenerStrategy?> saveStrategy({
    required String name,
    String? description,
    required Map<String, dynamic> filters,
    String? sortBy,
    bool isDefault = false,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final body = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'filters': filters,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        'isDefault': isDefault,
      };

      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['api', 'screener', 'strategies'],
        body: body,
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final strategy = ScreenerStrategy.fromJson(jsonData['data'] as Map<String, dynamic>);
          
          // Add to list
          strategies.add(strategy);
          
          isLoading.value = false;
          return strategy;
        } else {
          errorMessage.value = jsonData['message'] ?? 'Failed to save strategy';
          isLoading.value = false;
          return null;
        }
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to save strategy';
        isLoading.value = false;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error saving strategy: $e';
      isLoading.value = false;
      return null;
    }
  }

  /// Get all strategies
  Future<void> fetchStrategies({
    bool includeDefault = true,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final params = {
        'includeDefault': includeDefault.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['api', 'screener', 'strategies'],
        params: params,
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        final strategyResponse = ScreenerStrategyListResponse.fromJson(jsonData as Map<String, dynamic>);
        
        strategies.value = strategyResponse.strategies;
        isLoading.value = false;
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to fetch strategies';
        strategies.value = [];
        isLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching strategies: $e';
      strategies.value = [];
      isLoading.value = false;
    }
  }

  /// Get a specific strategy by ID
  Future<ScreenerStrategy?> getStrategy(String strategyId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['api', 'screener', 'strategies', strategyId],
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final strategy = ScreenerStrategy.fromJson(jsonData['data'] as Map<String, dynamic>);
          isLoading.value = false;
          return strategy;
        } else {
          errorMessage.value = jsonData['message'] ?? 'Strategy not found';
          isLoading.value = false;
          return null;
        }
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to fetch strategy';
        isLoading.value = false;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching strategy: $e';
      isLoading.value = false;
      return null;
    }
  }

  /// Delete a strategy
  Future<bool> deleteStrategy(String strategyId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.DELETE,
        path: ['api', 'screener', 'strategies', strategyId],
      );

      if (response.status == ApiStatus.SUCCESS) {
        // Remove from list
        strategies.removeWhere((s) => s.id == strategyId);
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to delete strategy';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error deleting strategy: $e';
      isLoading.value = false;
      return false;
    }
  }

  /// Update a strategy
  Future<ScreenerStrategy?> updateStrategy({
    required String strategyId,
    String? name,
    String? description,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? isDefault,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (filters != null) body['filters'] = filters;
      if (sortBy != null) body['sortBy'] = sortBy;
      if (isDefault != null) body['isDefault'] = isDefault;

      final response = await WebService.callApi(
        method: HttpMethod.PUT,
        path: ['api', 'screener', 'strategies', strategyId],
        body: body,
      );

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final strategy = ScreenerStrategy.fromJson(jsonData['data'] as Map<String, dynamic>);
          
          // Update in list
          final index = strategies.indexWhere((s) => s.id == strategyId);
          if (index != -1) {
            strategies[index] = strategy;
          }
          
          isLoading.value = false;
          return strategy;
        } else {
          errorMessage.value = jsonData['message'] ?? 'Failed to update strategy';
          isLoading.value = false;
          return null;
        }
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to update strategy';
        isLoading.value = false;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error updating strategy: $e';
      isLoading.value = false;
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Load strategies on initialization
    fetchStrategies();
  }
}

