import 'package:musaffa_terminal/models/news_sentiment_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class NewsSentimentService {
  NewsSentimentService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<NewsSentimentModel?> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final dynamic decoded = await _client.get(
      'news-sentiment',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'news-sentiment:$normalized',
    );

    if (decoded is! Map<String, dynamic>) return null;
    return NewsSentimentModel.fromJson(decoded);
  }
}
