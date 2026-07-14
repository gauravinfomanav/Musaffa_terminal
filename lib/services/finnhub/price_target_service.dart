import 'package:musaffa_terminal/models/price_target_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class PriceTargetService {
  PriceTargetService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<PriceTargetModel?> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    final dynamic decoded = await _client.get(
      'stock/price-target',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/price-target:$normalized',
    );

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final PriceTargetModel model = PriceTargetModel.fromJson(decoded);
    if (!model.hasTargets) {
      return null;
    }
    return model;
  }
}
