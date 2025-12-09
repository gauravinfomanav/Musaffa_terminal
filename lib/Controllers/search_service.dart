import 'dart:async';
import 'dart:convert';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/web_service.dart';
import '../utils/constants.dart';

class SearchService {
  static final WebService _webService = WebService();

  // Debounce timer
  static Timer? _debounceTimer;

  // Cancellation token — increments on every new search call.
  // Each async call captures its own token; if it no longer matches
  // the current token when results arrive, the results are discarded.
  static int _currentSearchToken = 0;

  /// Call this from your UI whenever the search field changes.
  /// [onResults] is called with the result list (or an empty list on cancel/error).
  static void searchStocksDebounced(
    String query, {
    required void Function(List<TickerModel>) onResults,
    Duration debounceDuration = const Duration(milliseconds: 400),
  }) {
    // Cancel any pending debounce
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      onResults([]);
      return;
    }

    _debounceTimer = Timer(debounceDuration, () async {
      final results = await searchStocks(query);
      onResults(results);
    });
  }

  static Future<List<TickerModel>> searchStocks(String query) async {
    // Grab a token for this specific call
    _currentSearchToken++;
    final myToken = _currentSearchToken;

    try {
      final companyProfileQuery = {
        "collection": FirestoreConstants.COMPANY_PROFILE_COLLECTION,
        "q": query,
        "query_by": "name,ticker",
        "sort_by":
            "_text_match:desc,\$stocks_data(isMainTicker:desc,usdMarketCap:desc)",
        "include_fields":
            "*,\$stocks_data(id,sharia_compliance,ranking,ranking_v2,currentPrice,current_price,previousClose,previous_close)",
        "query_by_weights": "1,2",
        "prioritize_token_position": true,
        "per_page": 250,
        "filter_by": '\$stocks_data(status:=PUBLISH&&country:=[US])',
      };

      final etfProfileQuery = {
        "collection": FirestoreConstants.ETF_PROFILE_COLLECTION,
        "q": query,
        "query_by": "name,symbol",
        "sort_by": "_text_match:desc,\$etfs_data(aum:desc)",
        "include_fields":
            "*,\$etfs_data(id,aum,domicile,shariahCompliantStatus,ranking_v2)",
        "query_by_weights": "1,2",
        "prioritize_token_position": true,
        "per_page": 250,
        "filter_by": '\$etfs_data(domicile:=[US])',
      };

      final req = {
        "searches": [companyProfileQuery, etfProfileQuery],
      };

      final response = await _webService.postTypeSense(
        ['multi_search'],
        jsonEncode(req),
        {},
      );

      // ✅ Stale response check — discard if a newer search has started
      if (myToken != _currentSearchToken) return [];

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final results = res["results"] as List<dynamic>;

        List<TickerModel> allResults = [];

        // Process company profile results
        if (results.isNotEmpty) {
          final companyHits =
              results[0]['hits'] as List<dynamic>? ?? [];

          for (final hit in companyHits) {
            final document = hit['document'] as Map<String, dynamic>?;
            if (document == null) continue;

            final rawStocksData = document['stocks_data'] ??
                document['\$stocks_data'] ??
                document['stocksData'];

            final stocksData =
                rawStocksData is List && rawStocksData.isNotEmpty
                    ? rawStocksData.first
                    : rawStocksData;

            num? price;
            if (stocksData is Map<String, dynamic>) {
              final rawPrice =
                  stocksData['currentPrice'] ??
                  stocksData['current_price'] ??
                  stocksData['previousClose'] ??
                  stocksData['previous_close'];

              if (rawPrice != null) {
                price = rawPrice is num
                    ? rawPrice
                    : double.tryParse(rawPrice.toString());
              }
            }

            allResults.add(TickerModel(
              symbol: document['ticker']?.toString(),
              companyName: document['name']?.toString(),
              exchange: document['exchange']?.toString(),
              countryName: document['country']?.toString(),
              logo: document['logo']?.toString(),
              isStock: true,
              currentPrice: price,
              currency: document['currency']?.toString(),
            ));
          }
        }

        // Process ETF results
        if (results.length > 1) {
          final etfHits =
              results[1]['hits'] as List<dynamic>? ?? [];

          for (final hit in etfHits) {
            final document = hit['document'] as Map<String, dynamic>?;
            if (document == null) continue;

            allResults.add(TickerModel(
              symbol: document['symbol']?.toString(),
              companyName: document['name']?.toString(),
              exchange: document['exchange']?.toString(),
              countryName: document['domicile']?.toString(),
              logo: document['logo']?.toString(),
              isStock: false,
              currentPrice: null,
              currency: document['currency']?.toString(),
            ));
          }
        }

        return allResults;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Call this when the search widget is disposed to clean up the timer.
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}