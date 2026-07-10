import 'package:musaffa_terminal/models/recommendation_trend_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class RecommendationTrendService {
  RecommendationTrendService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<RecommendationTrendModel>> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return <RecommendationTrendModel>[];

    final dynamic decoded = await _client.get(
      'stock/recommendation',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/recommendation:$normalized',
    );

    final List<dynamic> rawList = decoded is List<dynamic> ? decoded : <dynamic>[];
    final List<RecommendationTrendModel> trends = rawList
        .whereType<Map<String, dynamic>>()
        .map(RecommendationTrendModel.fromJson)
        .where((RecommendationTrendModel e) => e.period.isNotEmpty)
        .toList()
      ..sort((RecommendationTrendModel a, RecommendationTrendModel b) =>
          a.period.compareTo(b.period));
    return trends;
  }
}
