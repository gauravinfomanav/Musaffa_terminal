import 'package:musaffa_terminal/models/quote_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class QuoteService {
  QuoteService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<QuoteModel?> fetchQuote(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final dynamic decoded = await _client.get(
      'quote',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'quote:$normalized',
      forceRefresh: forceRefresh,
    );

    if (decoded is! Map<String, dynamic>) return null;
    final QuoteModel quote = QuoteModel.fromJson(decoded);
    return quote.hasContent ? quote : null;
  }
}
