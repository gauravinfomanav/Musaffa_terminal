import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musaffa_terminal/config/infomanav_api_config.dart';

class FinnhubApiException implements Exception {
  FinnhubApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reusable client for Finnhub endpoints via the Infomanav proxy.
class FinnhubApiClient {
  const FinnhubApiClient();

  static final Map<String, dynamic> _cache = <String, dynamic>{};

  Future<dynamic> get(
    String apiPath, {
    Map<String, String>? queryParameters,
    String? cacheKey,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        cacheKey != null &&
        _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final Map<String, String> params = <String, String>{
      'api': apiPath,
      if (queryParameters != null) ...queryParameters,
    };

    final Uri uri = Uri.parse(InfomanavApiConfig.baseUrl).replace(
      queryParameters: params,
    );

    final http.Response response = await http.get(
      uri,
      headers: const <String, String>{
        HttpHeaders.acceptHeader: 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FinnhubApiException(
        'Finnhub request failed (${response.statusCode})',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (cacheKey != null) {
      _cache[cacheKey] = decoded;
    }
    return decoded;
  }

  static void clearCacheForSymbol(String symbol) {
    final String normalized = symbol.trim().toUpperCase();
    _cache.removeWhere(
      (String key, _) => key.contains(normalized),
    );
  }
}
