import 'dart:convert';

import 'package:musaffa_terminal/models/peer_comparison_row.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';
import 'package:musaffa_terminal/web_service.dart';

class PeerComparisonService {
  PeerComparisonService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<String>> fetchPeerSymbols(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <String>[];
    }

    final dynamic decoded = await _client.get(
      'stock/peers',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/peers:$normalized',
    );

    final List<String> peers = (decoded is List<dynamic>)
        ? decoded
            .whereType<String>()
            .map((String item) => item.trim().toUpperCase())
            .where((String item) => item.isNotEmpty && item != normalized)
            .toSet()
            .toList()
        : <String>[];
    return peers;
  }

  Future<PeerComparisonRow?> fetchStockRow(
    String symbol, {
    bool isCurrent = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    try {
      final List futures = await Future.wait<dynamic>(<Future<dynamic>>[
        WebService.getTypesense(<String>[
          'collections',
          'stocks_data',
          'documents',
          'search',
        ], <String, dynamic>{
          'q': '*',
          'per_page': '1',
          'filter_by': 'id:=[`$normalized`]',
        }),
        WebService.getTypesense(<String>[
          'collections',
          'company_profile_collection_new',
          'documents',
          'search',
        ], <String, dynamic>{
          'q': '*',
          'per_page': '1',
          'include_fields': 'id,name,logo',
          'filter_by': 'id:=[`$normalized`]',
        }),
      ]);

      final dynamic stockResponse = futures[0];
      final dynamic profileResponse = futures[1];
      if (stockResponse.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> stockBody =
          jsonDecode(stockResponse.body) as Map<String, dynamic>;
      final List<dynamic> stockHits = stockBody['hits'] as List<dynamic>? ?? <dynamic>[];
      if (stockHits.isEmpty) {
        return null;
      }

      final Map<String, dynamic> stockDocument =
          stockHits.first['document'] as Map<String, dynamic>;
      final StocksData stockData = StocksData.fromJson(stockDocument);

      String companyName = stockData.ticker ?? normalized;
      String logo = '';

      if (profileResponse.statusCode == 200) {
        final Map<String, dynamic> profileBody =
            jsonDecode(profileResponse.body) as Map<String, dynamic>;
        final List<dynamic> profileHits =
            profileBody['hits'] as List<dynamic>? ?? <dynamic>[];
        if (profileHits.isNotEmpty) {
          final Map<String, dynamic> profileDoc =
              profileHits.first['document'] as Map<String, dynamic>;
          companyName = (profileDoc['name'] ?? companyName).toString();
          logo = (profileDoc['logo'] ?? '').toString();
        }
      }

      return PeerComparisonRow(
        ticker: normalized,
        companyName: companyName,
        logo: logo,
        stockData: stockData,
        isCurrent: isCurrent,
      );
    } catch (_) {
      return null;
    }
  }
}
