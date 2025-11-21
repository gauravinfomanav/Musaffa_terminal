import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

enum HttpMethod { GET, POST, PUT, DELETE }

enum ApiStatus { SUCCESS, FAIL, EXCEPTION }

class ApiResponse {
  final ApiStatus status;
  final String? data;
  final String? errorMessage;
  final String? exceptionMessage;

  ApiResponse({
    required this.status,
    this.data,
    this.errorMessage,
    this.exceptionMessage,
  });
}

class WebService {
  static const String _typesenseUrl =
      'https://0bs2hegi5nmtad4op.a1.typesense.net';
  static const String _typesenseKey =
      'GRhZdTOnzVKId4Ln9G1PIvuIgn1TK0fH';
      
  // Musaffa Terminal API base URL
  static const String _musaffaBaseUrl = 'https://terminal.musaffa.us';
      
  // New Typesense instance for infomanav
  static const String _typesenseInfomanavUrl =
      'https://typesense.infomanav.in';
  static const String _typesenseInfomanavKey =
      'v0R3WozafhWeECu5MVuKr6HPcXI0hLPh';

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
  }) async {
    try {
      final headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      };

      final uri = Uri.parse(baseUrl ?? _musaffaBaseUrl)
          .replace(pathSegments: path, queryParameters: params);
      print("url will be this: $uri");
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
      }

      // Handle response based on status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          status: ApiStatus.SUCCESS,
          data: response.body,
        );
      } else {
        return ApiResponse(
          status: ApiStatus.FAIL,
          data: response.body,
          errorMessage: 'API call failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(
        status: ApiStatus.EXCEPTION,
        errorMessage: 'Network error occurred',
        exceptionMessage: e.toString(),
      );
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

  /// Get historical prices for backtesting
  static Future<http.Response> getHistoricalPrices({
    required List<String> symbols,
    required String date,
  }) async {
    print('🌐 WebService: Making historical prices API call');
    print('🌐 URL: https://risepython.infomanav.in/8009/latest_stock_candles/');
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
    
    final uri = Uri.parse('https://risepython.infomanav.in/8009/latest_stock_candles/');
    
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
