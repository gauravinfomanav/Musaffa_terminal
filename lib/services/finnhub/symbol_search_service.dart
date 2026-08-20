import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class SymbolSearchResult {
  const SymbolSearchResult({
    required this.symbol,
    this.description,
    this.displaySymbol,
    this.type,
  });

  final String symbol;
  final String? description;
  final String? displaySymbol;
  final String? type;

  factory SymbolSearchResult.fromJson(Map<String, dynamic> json) {
    return SymbolSearchResult(
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      description: json['description']?.toString(),
      displaySymbol: json['displaySymbol']?.toString(),
      type: json['type']?.toString(),
    );
  }
}

/// Finnhub symbol lookup (`/search`).
class SymbolSearchService {
  SymbolSearchService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<SymbolSearchResult>> search(String query) async {
    final String q = query.trim();
    if (q.isEmpty) return <SymbolSearchResult>[];

    final dynamic decoded = await _client.get(
      'search',
      queryParameters: <String, String>{'q': q},
      cacheKey: 'search:${q.toLowerCase()}',
    );

    final List<dynamic> raw = decoded is Map<String, dynamic>
        ? (decoded['result'] as List<dynamic>? ?? <dynamic>[])
        : decoded is List<dynamic>
            ? decoded
            : <dynamic>[];

    return raw
        .whereType<Map>()
        .map(
          (Map item) =>
              SymbolSearchResult.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((SymbolSearchResult r) => r.symbol.isNotEmpty)
        .toList();
  }

  /// Resolves a user query to a ticker for the earnings calendar `symbol` param.
  ///
  /// Exact tickers (e.g. `AAPL`) are returned directly. Company names go through
  /// Finnhub search and use the first match.
  Future<String?> resolveToSymbol(String query) async {
    final String q = query.trim();
    if (q.isEmpty) return null;

    final bool looksLikeTicker =
        RegExp(r'^[A-Za-z][A-Za-z0-9.\-]{0,14}$').hasMatch(q) &&
            !q.contains(' ');

    if (looksLikeTicker) {
      return q.toUpperCase();
    }

    final List<SymbolSearchResult> results = await search(q);
    if (results.isEmpty) return null;
    return results.first.symbol;
  }
}
