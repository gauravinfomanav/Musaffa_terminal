import 'dart:convert';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/web_service.dart';
import '../utils/constants.dart';

class SearchService {
  static final WebService _webService = WebService();

  static Future<List<TickerModel>> searchStocks(String query) async {
    try {
      // Create the search request exactly like the web version
      final companyProfileQuery = {
        "collection": FirestoreConstants.COMPANY_PROFILE_COLLECTION,
        "q": query,
        "query_by": "name,ticker",
        "sort_by": "_text_match:desc,\$stocks_data(isMainTicker:desc,usdMarketCap:desc)",
        "include_fields": "*,\$stocks_data(id,sharia_compliance,ranking,ranking_v2)",
        "query_by_weights": "1,2",
        "prioritize_token_position": true,
        "per_page": 20,
        "filter_by": '\$stocks_data(status:=PUBLISH&&country:=[PH,US,SE,PK,NZ,KW,NO,TR,TH,SG,MX,SA,ZA,TW,PT,BE,CA,BR,DE,AE,CL,BD,ES,AT,CH,DK,EG,CZ,BH,FR,CN,ID,CO,FI,HU,IS,GB,KR,GR,NL,PL,MY,HK,IE,IN,IT,JP,QA,RU,AU,AR])',
      };

      final etfProfileQuery = {
        "collection": FirestoreConstants.ETF_PROFILE_COLLECTION,
        "q": query,
        "query_by": "name,symbol",
        "sort_by": "_text_match:desc,\$etfs_data(aum:desc)",
        "include_fields": "*,\$etfs_data(id,aum,domicile,shariahCompliantStatus,ranking_v2)",
        "query_by_weights": "1,2",
        "prioritize_token_position": true,
        "per_page": 20,
        "filter_by": '\$etfs_data(domicile:=[US,CA,DE,GB,IN])',
      };

      final searchesArr = [companyProfileQuery, etfProfileQuery];
      final req = {"searches": searchesArr};

      final response = await _webService.postTypeSense(['multi_search'], jsonEncode(req), {});
      
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final results = res["results"] as List<dynamic>;
        
        List<TickerModel> allResults = [];
        
        // Process company profile results
        if (results.isNotEmpty) {
          final companyResults = results[0];
          final companyHits = companyResults['hits'] as List<dynamic>? ?? [];
          
          for (final hit in companyHits) {
            final document = hit['document'] as Map<String, dynamic>?;
            if (document != null) {
              allResults.add(TickerModel(
                symbol: document['ticker']?.toString(),
                companyName: document['name']?.toString(),
                exchange: document['exchange']?.toString(),
                countryName: document['country']?.toString(),
                logo: document['logo']?.toString(),
                isStock: true,
                currentPrice: null,
                currency: document['currency']?.toString(),
              ));
            }
          }
        }
        
        // Process ETF results
        if (results.length > 1) {
          final etfResults = results[1];
          final etfHits = etfResults['hits'] as List<dynamic>? ?? [];
          
          for (final hit in etfHits) {
            final document = hit['document'] as Map<String, dynamic>?;
            if (document != null) {
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
        }
        
        return allResults;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
}
