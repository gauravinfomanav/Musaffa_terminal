import 'package:musaffa_terminal/models/insider_transaction_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class InsiderTradingService {
  InsiderTradingService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<InsiderTransactionModel>> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return <InsiderTransactionModel>[];

    final dynamic decoded = await _client.get(
      'stock/insider-transactions',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/insider-transactions:$normalized',
    );

    final List<dynamic> rawList = _extractList(decoded);
    final List<InsiderTransactionModel> items = rawList
        .whereType<Map<String, dynamic>>()
        .map(InsiderTransactionModel.fromJson)
        .where((InsiderTransactionModel item) => item.name.isNotEmpty)
        .toList();

    items.sort((InsiderTransactionModel a, InsiderTransactionModel b) {
      final DateTime ad = a.transactionDate ?? a.filingDate ?? DateTime(1970);
      final DateTime bd = b.transactionDate ?? b.filingDate ?? DateTime(1970);
      return bd.compareTo(ad);
    });
    return items;
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];
      if (data is List<dynamic>) return data;
      for (final dynamic value in decoded.values) {
        if (value is List<dynamic>) return value;
      }
    }
    return <dynamic>[];
  }
}
