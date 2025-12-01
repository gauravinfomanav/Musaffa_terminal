import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/web_service.dart';

class PortfolioController extends GetxController {
  final RxList<PortfolioSummary> activePortfolios = <PortfolioSummary>[].obs;
  final RxList<PortfolioSummary> draftPortfolios = <PortfolioSummary>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isSaving = false.obs;
  final RxString saveError = ''.obs;

  /// Create a new active portfolio
  Future<Portfolio?> createPortfolio({
    required String portfolioName,
    required String clientName,
    required double initialCapital,
    required List<PortfolioHolding> holdings,
    int? clientAge,
    String? riskProfile,
    String? strategyType,
    String? benchmark,
    String? objective,
    String? investmentHorizon,
    double? expectedRateOfReturn,
    String? commentary,
  }) async {
    try {
      isSaving.value = true;
      saveError.value = '';

      final body = {
        'portfolio_name': portfolioName,
        'client_name': clientName,
        'initial_capital': initialCapital,
        'holdings': holdings.map((h) => h.toJson()).toList(),
        if (clientAge != null) 'client_age': clientAge,
        if (riskProfile != null && riskProfile.isNotEmpty) 'risk_profile': riskProfile,
        if (strategyType != null && strategyType.isNotEmpty) 'strategy_type': strategyType,
        if (benchmark != null && benchmark.isNotEmpty) 'benchmark': benchmark,
        if (objective != null && objective.isNotEmpty) 'objective': objective,
        if (investmentHorizon != null && investmentHorizon.isNotEmpty) 'investment_horizon': investmentHorizon,
        if (expectedRateOfReturn != null) 'expected_rate_of_return': expectedRateOfReturn,
        if (commentary != null && commentary.isNotEmpty) 'commentary': commentary,
        'status': 'active',
      };

      print('📤 [PortfolioController] Creating portfolio...');
      print('📤 Request body: ${jsonEncode(body)}');
      
      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['api', 'portfolios'],
        body: body,
      );

      print('📥 [PortfolioController] Create Portfolio Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final portfolio = Portfolio.fromJson(jsonData['data'] as Map<String, dynamic>);
          isSaving.value = false;
          return portfolio;
        } else {
          saveError.value = jsonData['message'] ?? 'Failed to save portfolio';
          isSaving.value = false;
          return null;
        }
      } else {
        final decoded = _tryDecode(response.data);
        saveError.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to save portfolio';
        isSaving.value = false;
        return null;
      }
    } catch (e) {
      saveError.value = 'Error saving portfolio: $e';
      isSaving.value = false;
      return null;
    }
  }

  /// Save a draft portfolio
  Future<Portfolio?> saveDraft({
    required String portfolioName,
    String? clientName,
    double? initialCapital,
    List<PortfolioHolding>? holdings,
    int? clientAge,
    String? riskProfile,
    String? strategyType,
    String? benchmark,
    String? objective,
    String? investmentHorizon,
    double? expectedRateOfReturn,
    String? commentary,
  }) async {
    try {
      isSaving.value = true;
      saveError.value = '';

      final body = <String, dynamic>{
        'portfolio_name': portfolioName,
      };

      if (clientName != null && clientName.isNotEmpty) body['client_name'] = clientName;
      if (initialCapital != null) body['initial_capital'] = initialCapital;
      if (holdings != null && holdings.isNotEmpty) {
        body['holdings'] = holdings.map((h) => h.toJson()).toList();
      } else {
        body['holdings'] = [];
      }
      if (clientAge != null) body['client_age'] = clientAge;
      if (riskProfile != null && riskProfile.isNotEmpty) body['risk_profile'] = riskProfile;
      if (strategyType != null && strategyType.isNotEmpty) body['strategy_type'] = strategyType;
      if (benchmark != null && benchmark.isNotEmpty) body['benchmark'] = benchmark;
      if (objective != null && objective.isNotEmpty) body['objective'] = objective;
      if (investmentHorizon != null && investmentHorizon.isNotEmpty) body['investment_horizon'] = investmentHorizon;
      if (expectedRateOfReturn != null) body['expected_rate_of_return'] = expectedRateOfReturn;
      if (commentary != null && commentary.isNotEmpty) body['commentary'] = commentary;

      print('📤 [PortfolioController] Saving draft...');
      print('📤 Request body: ${jsonEncode(body)}');
      
      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['api', 'portfolios', 'drafts'],
        body: body,
      );

      print('📥 [PortfolioController] Save Draft Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final portfolio = Portfolio.fromJson(jsonData['data'] as Map<String, dynamic>);
          isSaving.value = false;
          return portfolio;
        } else {
          saveError.value = jsonData['message'] ?? 'Failed to save draft';
          isSaving.value = false;
          return null;
        }
      } else {
        final decoded = _tryDecode(response.data);
        saveError.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to save draft';
        isSaving.value = false;
        return null;
      }
    } catch (e) {
      saveError.value = 'Error saving draft: $e';
      isSaving.value = false;
      return null;
    }
  }

  /// Update an existing portfolio
  Future<Portfolio?> updatePortfolio({
    required String portfolioId,
    String? portfolioName,
    String? clientName,
    double? initialCapital,
    List<PortfolioHolding>? holdings,
    int? clientAge,
    String? riskProfile,
    String? strategyType,
    String? benchmark,
    String? objective,
    String? investmentHorizon,
    double? expectedRateOfReturn,
    String? commentary,
  }) async {
    try {
      isSaving.value = true;
      saveError.value = '';

      final body = <String, dynamic>{};
      if (portfolioName != null && portfolioName.isNotEmpty) body['portfolio_name'] = portfolioName;
      if (clientName != null && clientName.isNotEmpty) body['client_name'] = clientName;
      if (initialCapital != null) body['initial_capital'] = initialCapital;
      if (holdings != null) body['holdings'] = holdings.map((h) => h.toJson()).toList();
      if (clientAge != null) body['client_age'] = clientAge;
      if (riskProfile != null && riskProfile.isNotEmpty) body['risk_profile'] = riskProfile;
      if (strategyType != null && strategyType.isNotEmpty) body['strategy_type'] = strategyType;
      if (benchmark != null && benchmark.isNotEmpty) body['benchmark'] = benchmark;
      if (objective != null && objective.isNotEmpty) body['objective'] = objective;
      if (investmentHorizon != null && investmentHorizon.isNotEmpty) body['investment_horizon'] = investmentHorizon;
      if (expectedRateOfReturn != null) body['expected_rate_of_return'] = expectedRateOfReturn;
      if (commentary != null && commentary.isNotEmpty) body['commentary'] = commentary;

      print('📤 [PortfolioController] Updating portfolio: $portfolioId');
      print('📤 Request body: ${jsonEncode(body)}');
      
      final response = await WebService.callApi(
        method: HttpMethod.PUT,
        path: ['api', 'portfolios', portfolioId],
        body: body,
      );

      print('📥 [PortfolioController] Update Portfolio Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final portfolio = Portfolio.fromJson(jsonData['data'] as Map<String, dynamic>);
          isSaving.value = false;
          return portfolio;
        } else {
          saveError.value = jsonData['message'] ?? 'Failed to update portfolio';
          isSaving.value = false;
          return null;
        }
      } else {
        final decoded = _tryDecode(response.data);
        saveError.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to update portfolio';
        isSaving.value = false;
        return null;
      }
    } catch (e) {
      saveError.value = 'Error updating portfolio: $e';
      isSaving.value = false;
      return null;
    }
  }

  /// Fetch active portfolios
  Future<void> fetchActivePortfolios({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? search,
  }) async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (sortBy != null) params['sort_by'] = sortBy;
      if (sortOrder != null) params['sort_order'] = sortOrder;
      if (search != null && search.isNotEmpty) params['search'] = search;

      print('📤 [PortfolioController] Fetching active portfolios...');
      print('📤 Params: $params');
      
      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['api', 'portfolios', 'active'],
        params: params,
      );

      print('📥 [PortfolioController] Fetch Active Portfolios Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        final listResponse = PortfolioListResponse.fromJson(jsonData as Map<String, dynamic>);
        activePortfolios.value = listResponse.portfolios;
        print('📥 Loaded ${activePortfolios.length} active portfolios');
        isLoading.value = false;
      } else {
        final decoded = _tryDecode(response.data);
        errorMessage.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to load portfolios';
        activePortfolios.value = [];
        isLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = 'Error loading portfolios: $e';
      activePortfolios.value = [];
      isLoading.value = false;
    }
  }

  /// Fetch draft portfolios
  Future<void> fetchDraftPortfolios({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? search,
  }) async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (sortBy != null) params['sort_by'] = sortBy;
      if (sortOrder != null) params['sort_order'] = sortOrder;
      if (search != null && search.isNotEmpty) params['search'] = search;

      print('📤 [PortfolioController] Fetching draft portfolios...');
      print('📤 Params: $params');
      
      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['api', 'portfolios', 'drafts'],
        params: params,
      );

      print('📥 [PortfolioController] Fetch Draft Portfolios Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        final listResponse = PortfolioListResponse.fromJson(jsonData as Map<String, dynamic>);
        draftPortfolios.value = listResponse.portfolios;
        print('📥 Loaded ${draftPortfolios.length} draft portfolios');
        isLoading.value = false;
      } else {
        final decoded = _tryDecode(response.data);
        errorMessage.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to load drafts';
        draftPortfolios.value = [];
        isLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = 'Error loading drafts: $e';
      draftPortfolios.value = [];
      isLoading.value = false;
    }
  }


  /// Convert draft to active portfolio
  Future<bool> convertDraftToActive(String portfolioId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📤 [PortfolioController] Converting draft to active: $portfolioId');

      // First, fetch the portfolio to get all required fields
      final portfolio = await getPortfolio(portfolioId);
      if (portfolio == null) {
        errorMessage.value = 'Portfolio not found';
        isLoading.value = false;
        return false;
      }

      // Prepare update body with all required fields
      final body = <String, dynamic>{
        'portfolio_name': portfolio.portfolioName,
        'client_name': portfolio.clientName,
        'initial_capital': portfolio.initialCapital,
        'holdings': portfolio.holdings.map((h) => h.toJson()).toList(),
        'status': 'active',
      };

      // Add optional fields if they exist
      if (portfolio.clientAge != null) body['client_age'] = portfolio.clientAge;
      if (portfolio.riskProfile != null && portfolio.riskProfile!.isNotEmpty) {
        body['risk_profile'] = portfolio.riskProfile;
      }
      if (portfolio.strategyType != null && portfolio.strategyType!.isNotEmpty) {
        body['strategy_type'] = portfolio.strategyType;
      }
      if (portfolio.benchmark != null && portfolio.benchmark!.isNotEmpty) {
        body['benchmark'] = portfolio.benchmark;
      }
      if (portfolio.objective != null && portfolio.objective!.isNotEmpty) {
        body['objective'] = portfolio.objective;
      }
      if (portfolio.investmentHorizon != null && portfolio.investmentHorizon!.isNotEmpty) {
        body['investment_horizon'] = portfolio.investmentHorizon;
      }
      if (portfolio.expectedRateOfReturn != null) {
        body['expected_rate_of_return'] = portfolio.expectedRateOfReturn;
      }
      if (portfolio.commentary != null && portfolio.commentary!.isNotEmpty) {
        body['commentary'] = portfolio.commentary;
      }

      print('📤 Request body: ${jsonEncode(body)}');

      final response = await WebService.callApi(
        method: HttpMethod.PUT,
        path: ['api', 'portfolios', portfolioId],
        body: body,
      );

      print('📥 [PortfolioController] Convert to Active Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS) {
        // Remove from draft list
        draftPortfolios.removeWhere((p) => p.id == portfolioId);
        // Refresh active list
        await fetchActivePortfolios();
        isLoading.value = false;
        return true;
      } else {
        final decoded = _tryDecode(response.data);
        errorMessage.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to convert to active';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error converting to active: $e';
      isLoading.value = false;
      return false;
    }
  }

  /// Convert active to draft portfolio
  Future<bool> convertActiveToDraft(String portfolioId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📤 [PortfolioController] Converting active to draft: $portfolioId');

      // First, fetch the portfolio to get all required fields
      final portfolio = await getPortfolio(portfolioId);
      if (portfolio == null) {
        errorMessage.value = 'Portfolio not found';
        isLoading.value = false;
        return false;
      }

      // Prepare update body with all required fields
      final body = <String, dynamic>{
        'portfolio_name': portfolio.portfolioName,
        'client_name': portfolio.clientName,
        'initial_capital': portfolio.initialCapital,
        'holdings': portfolio.holdings.map((h) => h.toJson()).toList(),
        'status': 'draft',
      };

      // Add optional fields if they exist
      if (portfolio.clientAge != null) body['client_age'] = portfolio.clientAge;
      if (portfolio.riskProfile != null && portfolio.riskProfile!.isNotEmpty) {
        body['risk_profile'] = portfolio.riskProfile;
      }
      if (portfolio.strategyType != null && portfolio.strategyType!.isNotEmpty) {
        body['strategy_type'] = portfolio.strategyType;
      }
      if (portfolio.benchmark != null && portfolio.benchmark!.isNotEmpty) {
        body['benchmark'] = portfolio.benchmark;
      }
      if (portfolio.objective != null && portfolio.objective!.isNotEmpty) {
        body['objective'] = portfolio.objective;
      }
      if (portfolio.investmentHorizon != null && portfolio.investmentHorizon!.isNotEmpty) {
        body['investment_horizon'] = portfolio.investmentHorizon;
      }
      if (portfolio.expectedRateOfReturn != null) {
        body['expected_rate_of_return'] = portfolio.expectedRateOfReturn;
      }
      if (portfolio.commentary != null && portfolio.commentary!.isNotEmpty) {
        body['commentary'] = portfolio.commentary;
      }

      print('📤 Request body: ${jsonEncode(body)}');

      final response = await WebService.callApi(
        method: HttpMethod.PUT,
        path: ['api', 'portfolios', portfolioId],
        body: body,
      );

      print('📥 [PortfolioController] Convert to Draft Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS) {
        // Remove from active list
        activePortfolios.removeWhere((p) => p.id == portfolioId);
        // Refresh draft list
        await fetchDraftPortfolios();
        isLoading.value = false;
        return true;
      } else {
        final decoded = _tryDecode(response.data);
        errorMessage.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to convert to draft';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error converting to draft: $e';
      isLoading.value = false;
      return false;
    }
  }

  /// Fetch a single portfolio by ID
  Future<Portfolio?> getPortfolio(String portfolioId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📤 [PortfolioController] Fetching portfolio: $portfolioId');
      
      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['api', 'portfolios', portfolioId],
      );

      print('📥 [PortfolioController] Get Portfolio Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final portfolio = Portfolio.fromJson(jsonData['data'] as Map<String, dynamic>);
          isLoading.value = false;
          return portfolio;
        } else {
          errorMessage.value = jsonData['message'] ?? 'Portfolio not found';
          isLoading.value = false;
          return null;
        }
      } else {
        final decoded = _tryDecode(response.data);
        errorMessage.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to fetch portfolio';
        isLoading.value = false;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching portfolio: $e';
      isLoading.value = false;
      return null;
    }
  }


  /// Delete a portfolio
  Future<bool> deletePortfolio(String portfolioId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📤 [PortfolioController] Deleting portfolio: $portfolioId');
      
      final response = await WebService.callApi(
        method: HttpMethod.DELETE,
        path: ['api', 'portfolios', portfolioId],
      );

      print('📥 [PortfolioController] Delete Portfolio Response:');
      print('📥 Status: ${response.status}');
      print('📥 Data: ${response.data}');
      print('📥 Error: ${response.errorMessage}');

      if (response.status == ApiStatus.SUCCESS) {
        // Remove from all lists
        activePortfolios.removeWhere((p) => p.id == portfolioId);
        draftPortfolios.removeWhere((p) => p.id == portfolioId);
        print('📥 Portfolio deleted successfully');
        isLoading.value = false;
        return true;
      } else {
        final decoded = _tryDecode(response.data);
        errorMessage.value = decoded?['message'] ?? response.errorMessage ?? 'Failed to delete portfolio';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error deleting portfolio: $e';
      isLoading.value = false;
      return false;
    }
  }

  Map<String, dynamic>? _tryDecode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

