import 'package:musaffa_terminal/models/dividend_entry.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class DividendService {
  DividendService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<DividendEntry>> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <DividendEntry>[];
    }

    final dynamic decoded = await _client.get(
      'stock/dividend',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/dividend:$normalized',
    );

    final List<dynamic> rawList = decoded is List<dynamic>
        ? decoded
        : decoded is Map<String, dynamic>
            ? (decoded['data'] as List<dynamic>? ?? <dynamic>[])
            : <dynamic>[];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(DividendEntry.fromJson)
        .toList()
      ..sort((DividendEntry a, DividendEntry b) => b.date.compareTo(a.date));
  }
}
