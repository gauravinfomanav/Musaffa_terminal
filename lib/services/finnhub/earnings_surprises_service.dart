import 'package:musaffa_terminal/models/earnings_surprise.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class EarningsSurprisesService {
  EarningsSurprisesService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<EarningsSurprise>> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <EarningsSurprise>[];
    }

    final dynamic decoded = await _client.get(
      'stock/earnings',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/earnings:$normalized',
    );

    final List<dynamic> rawList = decoded is List<dynamic>
        ? decoded
        : decoded is Map<String, dynamic>
            ? (decoded['earnings'] as List<dynamic>? ?? <dynamic>[])
            : <dynamic>[];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(EarningsSurprise.fromJson)
        .toList()
      ..sort((EarningsSurprise a, EarningsSurprise b) =>
          b.period.compareTo(a.period));
  }
}
