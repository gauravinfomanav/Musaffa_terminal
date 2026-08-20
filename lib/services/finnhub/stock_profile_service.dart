import 'package:musaffa_terminal/models/stock_profile_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class StockProfileService {
  StockProfileService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<StockProfileModel?> fetchBySymbol(
    String symbol, {
    bool forceRefresh = false,
  }) {
    return _fetch(
      queryParameters: <String, String>{'symbol': symbol.trim().toUpperCase()},
      cacheKey: 'stock/profile:symbol:${symbol.trim().toUpperCase()}',
      forceRefresh: forceRefresh,
    );
  }

  Future<StockProfileModel?> fetchByIsin(
    String isin, {
    bool forceRefresh = false,
  }) {
    return _fetch(
      queryParameters: <String, String>{'isin': isin.trim().toUpperCase()},
      cacheKey: 'stock/profile:isin:${isin.trim().toUpperCase()}',
      forceRefresh: forceRefresh,
    );
  }

  Future<StockProfileModel?> fetchByCusip(
    String cusip, {
    bool forceRefresh = false,
  }) {
    return _fetch(
      queryParameters: <String, String>{'cusip': cusip.trim()},
      cacheKey: 'stock/profile:cusip:${cusip.trim()}',
      forceRefresh: forceRefresh,
    );
  }

  /// Free Company Profile 2 endpoint preferred by Finnhub docs.
  Future<StockProfileModel?> fetchProfile2(
    String symbol, {
    bool forceRefresh = false,
  }) {
    return _fetch(
      apiPath: 'stock/profile2',
      queryParameters: <String, String>{'symbol': symbol.trim().toUpperCase()},
      cacheKey: 'stock/profile2:symbol:${symbol.trim().toUpperCase()}',
      forceRefresh: forceRefresh,
    );
  }

  Future<StockProfileModel?> _fetch({
    String apiPath = 'stock/profile',
    required Map<String, String> queryParameters,
    required String cacheKey,
    required bool forceRefresh,
  }) async {
    final dynamic decoded = await _client.get(
      apiPath,
      queryParameters: queryParameters,
      cacheKey: cacheKey,
      forceRefresh: forceRefresh,
    );

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final model = StockProfileModel.fromJson(decoded);
    return model.hasContent ? model : null;
  }
}
