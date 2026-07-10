import 'package:musaffa_terminal/models/fund_ownership_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class FundOwnershipService {
  FundOwnershipService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<FundOwnershipModel>> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return <FundOwnershipModel>[];

    final dynamic decoded = await _client.get(
      'stock/fund-ownership',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/fund-ownership:$normalized',
    );

    final List<dynamic> rawList = _extractOwnershipList(decoded);
    final List<FundOwnershipModel> items = rawList
        .whereType<Map<String, dynamic>>()
        .map(FundOwnershipModel.fromJson)
        .where((FundOwnershipModel item) => item.name.trim().isNotEmpty)
        .toList()
      ..sort((FundOwnershipModel a, FundOwnershipModel b) => b.share.compareTo(a.share));
    return items;
  }

  List<dynamic> _extractOwnershipList(dynamic decoded) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic>) {
      final dynamic ownership = decoded['ownership'];
      if (ownership is List<dynamic>) return ownership;
      final dynamic data = decoded['data'];
      if (data is List<dynamic>) return data;
      for (final dynamic value in decoded.values) {
        if (value is List<dynamic>) return value;
      }
    }
    return <dynamic>[];
  }
}
