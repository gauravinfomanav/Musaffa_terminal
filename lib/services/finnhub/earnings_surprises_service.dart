import 'package:musaffa_terminal/models/earnings_surprise.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class EarningsSurprisesService {
  EarningsSurprisesService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<EarningsSurprise>> fetchForSymbol(
    String symbol, {
    int? limit,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <EarningsSurprise>[];
    }

    final Map<String, String> params = <String, String>{
      'symbol': normalized,
      if (limit != null) 'limit': '$limit',
    };

    final dynamic decoded = await _client.get(
      'stock/earnings',
      queryParameters: params,
      cacheKey: 'stock/earnings:$normalized:${limit ?? 'all'}',
    );

    final List<dynamic> rawList = decoded is List<dynamic>
        ? decoded
        : decoded is Map<String, dynamic>
            ? (decoded['earnings'] as List<dynamic>? ?? <dynamic>[])
            : <dynamic>[];

    final List<EarningsSurprise> items = rawList
        .whereType<Map<String, dynamic>>()
        .map(EarningsSurprise.fromJson)
        .toList()
      ..sort((EarningsSurprise a, EarningsSurprise b) =>
          b.period.compareTo(a.period));

    if (limit != null && items.length > limit) {
      return items.take(limit).toList();
    }
    return items;
  }
}
