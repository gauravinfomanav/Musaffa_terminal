import 'package:musaffa_terminal/models/basic_financials_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class BasicFinancialsService {
  BasicFinancialsService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<BasicFinancialsModel?> fetchAll(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final dynamic decoded = await _client.get(
      'stock/metric',
      queryParameters: <String, String>{
        'symbol': normalized,
        'metric': 'all',
      },
      cacheKey: 'stock/metric:$normalized:all',
      forceRefresh: forceRefresh,
    );

    if (decoded is! Map<String, dynamic>) return null;
    final BasicFinancialsModel model = BasicFinancialsModel.fromJson(decoded);
    return model.hasContent ? model : null;
  }
}
