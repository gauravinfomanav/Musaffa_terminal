import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

class _CacheEntry {
  _CacheEntry(this.value) : timestamp = DateTime.now();

  final dynamic value;
  final DateTime timestamp;

  bool isExpired(Duration ttl) => DateTime.now().difference(timestamp) > ttl;
}

/// Single centralized gateway for every Finnhub call in the app (quotes,
/// candles, financials, profile, dividends, news, etc — all ~20 services
/// route through this one client).
///
/// The upstream Infomanav proxy is flaky by nature (observed: bursts of
/// concurrent requests fail with 503 ~90% of the time, and cold requests can
/// hang up to ~8s before the proxy itself times out reaching Finnhub). This
/// client is built around that reality:
///  - In-flight de-duplication: N widgets asking for the same symbol at the
///    same time share one network call instead of piling on the proxy.
///  - Short-TTL fresh cache so re-renders don't refetch needlessly.
///  - Stale-while-error: if a refetch fails for any reason, we serve the
///    last known-good value instead of surfacing an error / blank UI.
///  - Bounded retries that don't hold a concurrency slot while backing off,
///    and a hard wall-clock cap per call so no request can hang forever.
class FinnhubApiClient {
  const FinnhubApiClient();

  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  static final Map<String, Future<dynamic>> _inflight = <String, Future<dynamic>>{};
  static final List<Completer<void>> _waiters = <Completer<void>>[];
  static int _active = 0;
  static final Random _random = Random();

  // A single page (watchlist + detail panel) can fire a dozen-plus distinct
  // requests at once on first load. Too few slots means most of them just
  // sit in queue behind each other's retries — which looked like "broken"
  // widgets that mysteriously fixed themselves once the page was revisited
  // and everything was warm in cache. More slots + slightly less aggressive
  // per-request retrying drains that initial burst much faster.
  static const int _maxConcurrent = 12;
  static const Duration _perAttemptTimeout = Duration(seconds: 7);
  static const int _maxAttempts = 3;
  static const Duration _overallTimeout = Duration(seconds: 10);

  Future<dynamic> get(
    String apiPath, {
    Map<String, String>? queryParameters,
    String? cacheKey,
    bool forceRefresh = false,
  }) async {
    final Duration ttl = _ttlFor(apiPath, queryParameters);
    final _CacheEntry? entry = cacheKey != null ? _cache[cacheKey] : null;

    if (!forceRefresh && entry != null && !entry.isExpired(ttl)) {
      return entry.value;
    }

    final String inflightKey =
        cacheKey ?? '$apiPath:${queryParameters ?? const <String, String>{}}';

    final Future<dynamic>? pending =
        forceRefresh ? null : _inflight[inflightKey];
    final bool owns = pending == null;
    final Future<dynamic> request = pending ??
        _fetchFresh(apiPath, queryParameters: queryParameters).timeout(
          _overallTimeout,
          onTimeout: () => throw FinnhubApiException(
            'Request timed out. Please try again.',
          ),
        );
    if (owns) {
      _inflight[inflightKey] = request;
    }

    try {
      final dynamic fresh = await request;
      // Finnhub's "no data yet" candle payload (`{"s":"no_data"}`) is a
      // perfectly valid HTTP 200, so it would otherwise get cached as if it
      // were good data for up to 30 minutes — permanently blocking a UI
      // that only needed a moment to retry. Don't let that stick around.
      if (cacheKey != null && !_isEmptyCandleResult(apiPath, fresh)) {
        _cache[cacheKey] = _CacheEntry(fresh);
      }
      return fresh;
    } catch (e) {
      // Stale-while-error: never show a blank chart/quote if we have
      // something to show, even if it's a little old.
      if (entry != null) return entry.value;
      rethrow;
    } finally {
      if (owns && identical(_inflight[inflightKey], request)) {
        _inflight.remove(inflightKey);
      }
    }
  }

  /// Finnhub candles can legitimately come back as `{"s":"no_data"}` — a
  /// successful HTTP response that just means "nothing published yet" (very
  /// common right after a symbol's data lags on the upstream proxy). A
  /// couple of short retries here clear up the vast majority of these
  /// without the caller ever seeing a blank chart.
  static const int _maxNoDataRetries = 1;

  Future<dynamic> _fetchFresh(
    String apiPath, {
    Map<String, String>? queryParameters,
  }) async {
    dynamic decoded;
    for (int i = 0; i <= _maxNoDataRetries; i++) {
      decoded = await _fetchOnce(apiPath, queryParameters: queryParameters);
      if (!_isEmptyCandleResult(apiPath, decoded)) return decoded;
      if (i < _maxNoDataRetries) await _backoff(i);
    }
    return decoded;
  }

  Future<dynamic> _fetchOnce(
    String apiPath, {
    Map<String, String>? queryParameters,
  }) async {
    final Map<String, String> params = <String, String>{
      'api': apiPath,
      if (queryParameters != null) ...queryParameters,
    };

    final Uri uri = Uri.parse(InfomanavApiConfig.baseUrl).replace(
      queryParameters: params,
    );

    http.Response? response;
    for (int attempt = 0; attempt < _maxAttempts; attempt++) {
      final bool lastAttempt = attempt == _maxAttempts - 1;
      http.Response current;
      try {
        current = await _withSlot(
          () => http
              .get(
                uri,
                headers: const <String, String>{
                  HttpHeaders.acceptHeader: 'application/json',
                },
              )
              .timeout(_perAttemptTimeout),
        );
      } on SocketException {
        if (!lastAttempt) {
          await _backoff(attempt);
          continue;
        }
        throw FinnhubApiException(
          'No internet connection. Please check your network and try again.',
        );
      } on http.ClientException catch (e) {
        if (!lastAttempt) {
          await _backoff(attempt);
          continue;
        }
        throw FinnhubApiException('Network error: ${e.message}');
      } on TimeoutException {
        if (!lastAttempt) {
          await _backoff(attempt);
          continue;
        }
        throw FinnhubApiException('Request timed out. Please try again.');
      }

      response = current;
      if (_isTransientStatus(current.statusCode) && !lastAttempt) {
        await _backoff(attempt);
        continue;
      }
      break;
    }

    if (response == null) {
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

    late final dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw FinnhubApiException('Malformed response from Finnhub.');
    }

    if (decoded is String && _isAccessDeniedMessage(decoded)) {
      throw FinnhubApiException(
        'This data is unavailable on the current API plan.',
        statusCode: code,
        isAccessDenied: true,
      );
    }

    if (decoded is Map<String, dynamic>) {
      final String? err = decoded['error']?.toString() ??
          decoded['Error']?.toString();
      if (err != null && err.isNotEmpty) {
        final bool access = _isAccessDeniedMessage(err);
        throw FinnhubApiException(
          access
              ? 'This data is unavailable on the current API plan.'
              : err,
          statusCode: code,
          isAccessDenied: access,
        );
      }
    }

    return decoded;
  }

  static Future<T> _withSlot<T>(Future<T> Function() run) async {
    if (_active >= _maxConcurrent) {
      final Completer<void> waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
    _active++;
    try {
      return await run();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete();
      }
    }
  }

  static Future<void> _backoff(int attempt) {
    final int jitter = _random.nextInt(150);
    return Future<void>.delayed(
      Duration(milliseconds: 350 * (attempt + 1) + jitter),
    );
  }

  /// How long a successful response stays "fresh" before we bother
  /// refetching. Live quotes and intraday candles refresh often; slow-moving
  /// reference data (financials, profile, dividends, etc.) barely changes.
  static Duration _ttlFor(String apiPath, Map<String, String>? qp) {
    if (apiPath == 'quote') return const Duration(seconds: 20);
    if (apiPath == 'stock/candle') {
      final String? resolution = qp?['resolution'];
      final bool daily = resolution == null ||
          resolution == 'D' ||
          resolution == 'W' ||
          resolution == 'M';
      return daily
          ? const Duration(minutes: 30)
          : const Duration(seconds: 45);
    }
    return const Duration(hours: 6);
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

  static bool _isAccessDeniedMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains("don't have access") ||
        lower.contains('does not have access') ||
        lower.contains('you dont have access') ||
        lower.contains('permission denied') ||
        lower.contains('unauthorized') ||
        (lower.contains('premium') && lower.contains('access'));
  }

  static bool _isEmptyCandleResult(String apiPath, dynamic value) {
    if (apiPath != 'stock/candle') return false;
    return value is Map && value['s'] != 'ok';
  }

  static bool _isTransientStatus(int code) =>
      code == 429 ||
      code == 500 ||
      code == 502 ||
      code == 503 ||
      code == 504;
}
