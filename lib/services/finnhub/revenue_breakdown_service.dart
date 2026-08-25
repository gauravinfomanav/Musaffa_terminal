import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class RevenueBreakdownService {
  RevenueBreakdownService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<RevenueBreakdownModel?> fetchLatestForSymbol(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final dynamic decoded = await _client.get(
      'stock/revenue-breakdown',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/revenue-breakdown:$normalized',
      forceRefresh: forceRefresh,
    );

    final RevenueBreakdownModel? parsed = RevenueBreakdownModel.parse(decoded);
    if (parsed == null || !parsed.hasData) return null;
    return parsed;
  }
}
