import 'package:musaffa_terminal/models/revenue_estimate_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class RevenueEstimateService {
  RevenueEstimateService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<RevenueEstimateModel>> fetch({
    required String symbol,
    String freq = 'quarterly',
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return <RevenueEstimateModel>[];

    final dynamic decoded = await _client.get(
      'stock/revenue-estimate',
      queryParameters: <String, String>{
        'symbol': normalized,
        'freq': freq,
      },
      cacheKey: 'stock/revenue-estimate:$normalized:$freq',
      forceRefresh: forceRefresh,
    );

    final List<dynamic> raw = decoded is Map<String, dynamic>
        ? (decoded['data'] as List<dynamic>? ?? <dynamic>[])
        : decoded is List<dynamic>
            ? decoded
            : <dynamic>[];

    return raw
        .whereType<Map>()
        .map(
          (Map item) =>
              RevenueEstimateModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
