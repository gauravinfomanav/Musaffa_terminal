import 'package:musaffa_terminal/models/financial_statement_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class FinancialsService {
  FinancialsService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  /// [statement]: `bs` | `ic` | `cf`
  /// [freq]: `annual` | `quarterly` | `ttm` | `ytd`
  Future<FinancialStatementModel?> fetch({
    required String symbol,
    required String statement,
    String freq = 'quarterly',
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final dynamic decoded = await _client.get(
      'stock/financials',
      queryParameters: <String, String>{
        'symbol': normalized,
        'statement': statement,
        'freq': freq,
      },
      cacheKey: 'stock/financials:$normalized:$statement:$freq',
      forceRefresh: forceRefresh,
    );

    if (decoded is! Map<String, dynamic>) return null;
    final FinancialStatementModel model = FinancialStatementModel.fromJson(
      decoded,
      statement: statement,
      frequency: freq,
    );
    return model.hasContent ? model : null;
  }
}
