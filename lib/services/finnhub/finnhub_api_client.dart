import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musaffa_terminal/config/infomanav_api_config.dart';

class FinnhubApiException implements Exception {
  FinnhubApiException(
    this.message, {
    this.statusCode,
    this.isAccessDenied = false,
    this.isRateLimited = false,
  });

  final String message;
  final int? statusCode;
  final bool isAccessDenied;
  final bool isRateLimited;

  bool get isPremiumUnavailable => isAccessDenied;

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

    late http.Response response;
    try {
      response = await http
          .get(
            uri,
            headers: const <String, String>{
              HttpHeaders.acceptHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw FinnhubApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException catch (e) {
      throw FinnhubApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw FinnhubApiException('Request timed out. Please try again.');
    }

    final int code = response.statusCode;
    if (code == 401 || code == 403) {
      throw FinnhubApiException(
        'This data is unavailable on the current API plan.',
        statusCode: code,
        isAccessDenied: true,
      );
    }
    if (code == 429) {
      throw FinnhubApiException(
        'Rate limit exceeded. Please wait a moment and try again.',
        statusCode: code,
        isRateLimited: true,
      );
    }
    if (code < 200 || code >= 300) {
      throw FinnhubApiException(
        'Finnhub request failed ($code)',
        statusCode: code,
      );
    }

    final String body = response.body.trim();
    if (body.isEmpty) {
      throw FinnhubApiException('Empty response from Finnhub.');
    }

    final String lower = body.toLowerCase();
    if (lower.contains("don't have access") ||
        lower.contains('does not have access') ||
        (lower.contains('premium') && lower.contains('access')) ||
        lower.contains('permission denied')) {
      throw FinnhubApiException(
        'This data is unavailable on the current API plan.',
        statusCode: code,
        isAccessDenied: true,
      );
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw FinnhubApiException('Malformed response from Finnhub.');
    }

    if (decoded is Map<String, dynamic>) {
      final String? err = decoded['error']?.toString() ??
          decoded['Error']?.toString();
      if (err != null && err.isNotEmpty) {
        final String errLower = err.toLowerCase();
        final bool access = errLower.contains('access') ||
            errLower.contains('premium') ||
            errLower.contains('permission') ||
            errLower.contains('unauthorized');
        throw FinnhubApiException(
          err,
          statusCode: code,
          isAccessDenied: access,
        );
      }
    }

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

  static void clearCacheKey(String key) {
    _cache.remove(key);
  }

  static void clearAllCache() {
    _cache.clear();
  }
}
