import 'package:musaffa_terminal/models/eps_estimate_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class EpsEstimateService {
  EpsEstimateService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<EpsEstimateModel>> fetch({
    required String symbol,
    String freq = 'quarterly',
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return <EpsEstimateModel>[];

    final dynamic decoded = await _client.get(
      'stock/eps-estimate',
      queryParameters: <String, String>{
        'symbol': normalized,
        'freq': freq,
      },
      cacheKey: 'stock/eps-estimate:$normalized:$freq',
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
              EpsEstimateModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
