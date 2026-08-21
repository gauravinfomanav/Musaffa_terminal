import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musaffa_terminal/config/api_config.dart';

enum HttpMethod { GET, POST, PUT, DELETE, PATCH }

enum ApiStatus { SUCCESS, FAIL, EXCEPTION }

class ApiResponse {
  final ApiStatus status;
  final String? data;
  final String? errorMessage;
  final String? exceptionMessage;
  final int? statusCode;

  ApiResponse({
    required this.status,
    this.data,
    this.errorMessage,
    this.exceptionMessage,
    this.statusCode,
  });
}

class WebService {
  /// @deprecated Use [ApiConfig.terminalBaseUrl] instead.
  static const String musaffaBaseUrl = ApiConfig.terminalBaseUrl;

  static const String _typesenseUrl = ApiConfig.typesenseUrl;
  static const String _typesenseKey = ApiConfig.typesenseApiKey;
  static const String _musaffaBaseUrl = ApiConfig.terminalBaseUrl;
  static const String _typesenseInfomanavUrl = ApiConfig.typesenseInfomanavUrl;
  static const String _typesenseInfomanavKey = ApiConfig.typesenseInfomanavApiKey;

  /// Injected by [AuthController] — clears session + redirects to login.
  static Future<void> Function()? onUnauthorized;

  /// Injected by [FeatureAccessService] — handles FEATURE_DISABLED 403s.
  static Future<void> Function(String feature, String message)?
      onFeatureDisabled;

  /// Optional token reader so authenticated Terminal APIs send Bearer JWT.
  static Future<String?> Function()? tokenProvider;

  static Future<http.Response> getTypesense(
      List<String> path, [Map<String, dynamic>? params]) async {
    final headers = {
      'X-TYPESENSE-API-KEY': _typesenseKey,
      'Content-Type': 'application/json',
    };

    final uri = Uri.parse(_typesenseUrl)
        .replace(pathSegments: path, queryParameters: params);

    try {
      final resp = await http.get(uri, headers: headers);
      return resp;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static Future<http.Response> getTypesense_infomanav(
      List<String> path, [Map<String, dynamic>? params]) async {
    final headers = {
      'X-TYPESENSE-API-KEY': _typesenseInfomanavKey,
      'Content-Type': 'application/json',
    };

    final uri = Uri.parse(_typesenseInfomanavUrl)
        .replace(pathSegments: path, queryParameters: params);

    try {
      final resp = await http.get(uri, headers: headers);
      return resp;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  Future<http.Response> postTypeSense(
      List<String> path, String body, Map<String, dynamic>? params) async {
    var typesenseUrl = _typesenseUrl;
    var typesenseKey = _typesenseKey;

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      'X-TYPESENSE-API-KEY': typesenseKey,
    };

    var requestUrl = Uri.parse(typesenseUrl)
        .replace(pathSegments: path, queryParameters: params);

    try {
      var resp = await http.post(requestUrl, headers: headers, body: body);

      return resp;
    } catch (_) {
      return Future(() {
        return http.Response('', 404);
      });
    }
  }

  // Simplified API call method for Musaffa Terminal
  static Future<ApiResponse> callApi({
    required HttpMethod method,
    required List<String> path,
    Map<String, dynamic>? params,
    Map<String, dynamic>? body,
    String? baseUrl,
    bool attachAuthToken = true,
    /// When set, used instead of [tokenProvider] (e.g. logout after local clear).
    String? bearerToken,
  }) async {
    try {
      final headers = <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      };

      if (bearerToken != null && bearerToken.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $bearerToken';
      } else if (attachAuthToken && tokenProvider != null) {
        final token = await tokenProvider!();
        if (token != null && token.isNotEmpty) {
          headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
        }
      }

      final uri = Uri.parse(baseUrl ?? _musaffaBaseUrl)
          .replace(pathSegments: path, queryParameters: params);
      debugPrint('API ${method.name} $uri');
      if (body != null) {
        debugPrint('API request body: ${jsonEncode(body)}');
      }
      late http.Response response;
      
      switch (method) {
        case HttpMethod.GET:
          response = await http.get(uri, headers: headers);
          break;
        case HttpMethod.POST:
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case HttpMethod.PUT:
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case HttpMethod.DELETE:
          response = await http.delete(uri, headers: headers);
          break;
        case HttpMethod.PATCH:
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
      }

      debugPrint(
        'API response ${response.statusCode}: ${response.body.isEmpty ? "<empty>" : response.body}',
      );

      // Handle response based on status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          status: ApiStatus.SUCCESS,
          data: response.body,
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 401 && attachAuthToken) {
        final isAuthEndpoint =
            path.isNotEmpty && path.first == 'auth' && path.contains('login');
        if (!isAuthEndpoint) {
          await onUnauthorized?.call();
        }
      }

      if (response.statusCode == 403) {
        final disabled = _extractFeatureDisabled(response.body);
        if (disabled != null) {
          await onFeatureDisabled?.call(
            disabled.feature,
            disabled.message,
          );
        }
      }

      final extracted = _extractErrorMessage(response.body);
      return ApiResponse(
        status: ApiStatus.FAIL,
        data: response.body,
        statusCode: response.statusCode,
        errorMessage: extracted ??
            (response.statusCode == 429
                ? 'Too many requests. Please wait a moment and try again.'
                : 'API call failed with status: ${response.statusCode}'),
      );
    } catch (e) {
      return ApiResponse(
        status: ApiStatus.EXCEPTION,
        errorMessage: 'Network error occurred',
        exceptionMessage: e.toString(),
      );
    }
  }

  static String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    final trimmed = body.trim();
    try {
      final json = jsonDecode(trimmed);
      if (json is Map<String, dynamic>) {
        final message = json['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Plain-text error bodies (e.g. rate-limit 429).
      if (trimmed.isNotEmpty &&
          !trimmed.startsWith('{') &&
          !trimmed.startsWith('[')) {
        return trimmed;
      }
    }
    return null;
  }

  static ({String feature, String message})? _extractFeatureDisabled(
    String body,
  ) {
    if (body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;
      if (json['code']?.toString() != 'FEATURE_DISABLED') return null;
      final feature = json['feature']?.toString() ?? '';
      if (feature.isEmpty) return null;
      final message = json['message']?.toString() ??
          'Feature is disabled for this account: $feature';
      return (feature: feature, message: message);
    } catch (_) {
      return null;
    }
  }

  // User Preferences API methods
  static Future<ApiResponse> getUserPreferences() async {
    return await callApi(
      method: HttpMethod.GET,
      path: ['user', 'preferences'],
    );
  }

  static Future<ApiResponse> setDefaultWatchlist(String watchlistId) async {
    return await callApi(
      method: HttpMethod.PUT,
      path: ['user', 'preferences', 'default-watchlist'],
      body: {'watchlist_id': watchlistId},
    );
  }

  /// Financial statements from RisePython (ic / bs / cf × annual / quarterly).
  /// Example: https://risepython.infomanav.in/8010/financial_statements/AAPL?statement=ic&freq=annual
  static Future<http.Response> getFinancialStatements({
    required String symbol,
    required String statement,
    required String freq,
  }) async {
    final normalizedSymbol = symbol.trim().toUpperCase();
    final uri = Uri.parse(
      ApiConfig.risePythonFinancialStatements(normalizedSymbol),
    ).replace(queryParameters: {
      'statement': statement,
      'freq': freq,
    });

    try {
      return await http.get(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  /// Company basic financials (metric snapshot + annual/quarterly series).
  /// Example: https://risepython.infomanav.in/8010/company_basic_financials/AAPL
  static Future<http.Response> getCompanyBasicFinancials({
    required String symbol,
  }) async {
    final normalizedSymbol = symbol.trim().toUpperCase();
    final uri = Uri.parse(
      ApiConfig.risePythonCompanyBasicFinancials(normalizedSymbol),
    );

    try {
      return await http.get(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  static final Map<String, Map<String, dynamic>> _basicFinancialsCache = {};
  static final Map<String, Future<Map<String, dynamic>?>> _basicFinancialsInflight =
      {};

  /// Cached decode of [getCompanyBasicFinancials] — shared by Per Share + Ratios.
  static Future<Map<String, dynamic>?> fetchCompanyBasicFinancialsCached(
    String symbol,
  ) async {
    final key = symbol.trim().toUpperCase();
    final cached = _basicFinancialsCache[key];
    if (cached != null) return cached;

    final inflight = _basicFinancialsInflight[key];
    if (inflight != null) return inflight;

    final future = () async {
      try {
        final response = await getCompanyBasicFinancials(symbol: key);
        if (response.statusCode != 200) return null;
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return null;
        _basicFinancialsCache[key] = decoded;
        return decoded;
      } catch (_) {
        return null;
      } finally {
        _basicFinancialsInflight.remove(key);
      }
    }();

    _basicFinancialsInflight[key] = future;
    return future;
  }

  static void clearCompanyBasicFinancialsCache([String? symbol]) {
    if (symbol == null) {
      _basicFinancialsCache.clear();
      return;
    }
    _basicFinancialsCache.remove(symbol.trim().toUpperCase());
  }

  /// Convert RisePython series `[{v, period}, ...]` → year → value.
  static Map<String, double?> seriesToYearMap(
    dynamic series, {
    int? maxYears,
  }) {
    final result = <String, double?>{};
    if (series is! List) return result;

    // API is typically newest-first; keep insertion order of unique years.
    for (final item in series) {
      if (item is! Map) continue;
      final period = item['period']?.toString() ?? '';
      if (period.length < 4) continue;
      final year = period.substring(0, 4);
      if (result.containsKey(year)) continue;
      final v = item['v'];
      result[year] = v is num ? v.toDouble() : null;
    }

    if (maxYears == null || result.length <= maxYears) return result;

    final years = result.keys.toList()..sort();
    final keep = years.sublist(years.length - maxYears);
    return {for (final y in keep) y: result[y]};
  }

  /// Convert RisePython quarterly series → period (YYYY-MM-DD) → value.
  static Map<String, double?> seriesToPeriodMap(
    dynamic series, {
    int? maxPeriods,
  }) {
    final entries = <MapEntry<String, double?>>[];
    if (series is! List) return {};

    for (final item in series) {
      if (item is! Map) continue;
      final period = item['period']?.toString() ?? '';
      if (period.isEmpty) continue;
      final v = item['v'];
      entries.add(MapEntry(period, v is num ? v.toDouble() : null));
    }

    // Newest first from API; take first N then return as map.
    final sliced =
        maxPeriods == null ? entries : entries.take(maxPeriods).toList();
    return {for (final e in sliced) e.key: e.value};
  }

  /// Get historical prices for backtesting
  static Future<http.Response> getHistoricalPrices({
    required List<String> symbols,
    required String date,
  }) async {
    print('🌐 WebService: Making historical prices API call');
    print('🌐 URL: ${ApiConfig.risePythonStockCandles}');
    print('🌐 Symbols: $symbols');
    print('🌐 Date: $date');
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    final body = jsonEncode({
      'company_symbols': symbols,
      'date': date,
    });
    
    print('🌐 Request body: $body');
    
    final uri = Uri.parse(ApiConfig.risePythonStockCandles);
    
    try {
      print('🌐 Making HTTP POST request...');
      final response = await http.post(uri, headers: headers, body: body);
      print('🌐 Response status: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');
      return response;
    } catch (e) {
      print('🌐 HTTP Error: $e');
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  // Target Price API methods
  static Future<ApiResponse> getTargetPrices(String watchlistId) async {
    return await callApi(
      method: HttpMethod.GET,
      path: ['targets', 'watchlist', watchlistId],
    );
  }

  static Future<ApiResponse> createTargetPrice({
    required String ticker,
    required double targetPrice,
    required String alertType,
    required String watchlistId,
    bool isActive = true,
  }) async {
    return await callApi(
      method: HttpMethod.POST,
      path: ['targets'],
      body: {
        'ticker': ticker,
        'target_price': targetPrice,
        'alert_type': alertType,
        'watchlist_id': watchlistId,
        'is_active': isActive,
      },
    );
  }

  static Future<ApiResponse> updateTargetPrice({
    required String targetId,
    double? targetPrice,
    String? alertType,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (targetPrice != null) body['target_price'] = targetPrice;
    if (alertType != null) body['alert_type'] = alertType;
    if (isActive != null) body['is_active'] = isActive;

    return await callApi(
      method: HttpMethod.PUT,
      path: ['targets', targetId],
      body: body,
    );
  }

  static Future<ApiResponse> deleteTargetPrice(String targetId) async {
    return await callApi(
      method: HttpMethod.DELETE,
      path: ['targets', targetId],
    );
  }

  // FCM Token Management
  static Future<ApiResponse> registerFCMToken({
    required String token,
    required String deviceType,
    required String deviceName,
  }) async {
    return await callApi(
      method: HttpMethod.POST,
      path: ['fcm', 'register-token'],
      body: {
        'token': token,
        'device_type': deviceType,
        'device_name': deviceName,
      },
    );
  }

  static Future<ApiResponse> getFCMTokens() async {
    return await callApi(
      method: HttpMethod.GET,
      path: ['fcm', 'tokens'],
    );
  }

  static Future<ApiResponse> updateFCMToken({
    required String tokenId,
    String? deviceName,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (deviceName != null) body['device_name'] = deviceName;
    if (isActive != null) body['is_active'] = isActive;

    return await callApi(
      method: HttpMethod.PUT,
      path: ['fcm', 'tokens', tokenId],
      body: body,
    );
  }

  static Future<ApiResponse> deleteFCMToken(String tokenId) async {
    return await callApi(
      method: HttpMethod.DELETE,
      path: ['fcm', 'tokens', tokenId],
    );
  }
}
