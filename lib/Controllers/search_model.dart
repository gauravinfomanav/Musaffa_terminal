import 'dart:convert';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/web_service.dart';
import '../utils/constants.dart';

extension SearchStocks on WebService {
  Future<WebResponse<List<TickerModel>, String>> searchStocksTypesense(
      {required String query,
      String searchType = "all",
      List<String>? CountryList,
      List<String>? ActiveETFCountryList}) async {
    CountryList = CountryList ?? [];
    ActiveETFCountryList = ActiveETFCountryList ?? [];

    var companyFilters = "";
    if (CountryList.isNotEmpty == true) {
      companyFilters = '\$stocks_data(status:=PUBLISH&&country:=${[CountryList.join(",")]})';
    } else {
      companyFilters = '\$stocks_data(status:=PUBLISH)';
    }

    var etfFilters = "";
    if (ActiveETFCountryList.isNotEmpty) {
      etfFilters = '\$etfs_data(domicile:=${[ActiveETFCountryList.join(",")]})';
    } else {
      etfFilters = '';
    }
    var companyProfileQuery = {
      "collection": FirestoreConstants.COMPANY_PROFILE_COLLECTION,
      "q": query,
      "query_by": "name,ticker",
      "sort_by": "_text_match:desc,tickerIsMain:desc,usdMarketCap:desc",
      "include_fields": "\$stocks_data(sharia_compliance,ranking_v2)",
      "query_by_weights": "1,2",
      "prioritize_token_position": true,
      "per_page": 20,
      "filter_by": companyFilters,
    };

    var etfProfileQuery = {
      "collection": FirestoreConstants.ETF_PROFILE_COLLECTION,
      "q": query,
      "query_by": "symbol,name",
      "sort_by": "_text_match:desc,aum:desc",
      "include_fields": "\$etfs_data(shariahCompliantStatus,ranking)",
      "query_by_weights": "1,2",
      "prioritize_token_position": true,
      "per_page": 20,
      "filter_by": etfFilters,
    };

    var usersCountryCompanyProfileQuery = {
      "collection": FirestoreConstants.COMPANY_PROFILE_COLLECTION,
      "q": query,
      "query_by": "name,ticker",
      "sort_by": "_text_match:desc,tickerIsMain:desc,usdMarketCap:desc",
      "include_fields": "\$stocks_data(sharia_compliance,ranking_v2)",
      "query_by_weights": "1,2",
      "prioritize_token_position": true,
      "per_page": 20,
      "filter_by": '\$stocks_data(status:=PUBLISH&&country:=US)',
    };

    var searchesArr = [];
    if (searchType == "all") {
      searchesArr.add(companyProfileQuery);
      searchesArr.add(etfProfileQuery);
      searchesArr.add(usersCountryCompanyProfileQuery);
    } else if (searchType == "stock") {
      searchesArr.add(companyProfileQuery);
      searchesArr.add(usersCountryCompanyProfileQuery);
    } else if (searchType == "etf") {
      searchesArr.add(etfProfileQuery);
    }

    var req = {"searches": searchesArr};

    final response = await postTypeSense(['multi_search'], jsonEncode(req), {});
    var res = jsonDecode(response.body);
    List<dynamic> results = res["results"];

    List<TickerModel> tickerModel = [];
    List<TickerModelResponse> tickerModelResponse = [];

    var companyProfileResults;
    var etfProfileResults;
    var defaultCountryCompanyProfileResults;

    List<TickerModelResponse> companyProfileTickerModelList = [];
    List<TickerModelResponse> etfProfileTickerModelList = [];
    List<TickerModelResponse> defaultCountryCompanyProfileTickerModelList = [];

    if (searchType == "all") {
      companyProfileResults = results[0];
      etfProfileResults = results[1];
      defaultCountryCompanyProfileResults = results[2];

      companyProfileTickerModelList =
          generateTickerResponseModelListForStock(result: companyProfileResults,query: query);
      etfProfileTickerModelList =
          generateTickerResponseModelListForEtf(etfProfileResults, query);
      defaultCountryCompanyProfileTickerModelList =
          generateTickerResponseModelListForStock(result: defaultCountryCompanyProfileResults, query: query,doubleTextMatchForMatchingMainTicker: true);
    } else if (searchType == "stock") {
      companyProfileResults = results[0];
      defaultCountryCompanyProfileResults = results[1];

      companyProfileTickerModelList =
          generateTickerResponseModelListForStock(result: companyProfileResults, query: query);
      defaultCountryCompanyProfileTickerModelList =
          generateTickerResponseModelListForStock(result: defaultCountryCompanyProfileResults, query: query,doubleTextMatchForMatchingMainTicker: true);
    } else if (searchType =="etf") {
      etfProfileResults = results[0];
      etfProfileTickerModelList =
          generateTickerResponseModelListForEtf(etfProfileResults, query);
    }

    // remove duplicates from companyProfile
    var matchingCountryStockTickers = defaultCountryCompanyProfileTickerModelList.map((e) => e.stockName ?? "").toList();
    companyProfileTickerModelList.removeWhere((element) => matchingCountryStockTickers.contains(element.stockName));
    tickerModelResponse.addAll(defaultCountryCompanyProfileTickerModelList);
    tickerModelResponse.addAll(companyProfileTickerModelList);
    tickerModelResponse.addAll(etfProfileTickerModelList);



    // tickerModelResponse.sort((a, b) => b.textMatch!.compareTo(a.textMatch!));
    tickerModelResponse.sort((a, b) {
      var textCompareValue = b.textMatch!.compareTo(a.textMatch!);
      return textCompareValue;
      if (textCompareValue == 0) {
        return b.amount!.compareTo(a.amount!);
      } else {
        return textCompareValue;
      }
      // if(b.textMatch == a.textMatch!)
      //   return b.amount!.compareTo(a.amount!);
      // else{
      //   return b.textMatch!.compareTo(a.textMatch!);
      // }
    });

    tickerModelResponse.forEach(
      (model) {

        tickerModel.add(
          TickerModel(
              currency: model.currency,
              canAddToWatchlist: model.canAddToWatchList!,
              stockName: model.stockName,
              companyName: model.companyName,
              exchange: model.exchange,
              countryName: model.countryName,
              isStock: model.isStock,
              shariahCompliantStatus: shariahCompliantStatusValues.map[model.shariahStates],
              compliantRanking: model.ranking,
              symbol: model.stockName,
              logo: model.logo),
        );
      },
    );

    try {
      return WebResponse(payload: tickerModel);
    } catch (e) {
      return WebResponse(errorMessage: 'Connection error');
    }
  }
}

List<TickerModelResponse> generateTickerResponseModelListForStock({
  required dynamic result, required String query, bool doubleTextMatchForMatchingMainTicker = false
}) {
  var hits = result['hits'] ?? [];
  List<TickerModelResponse> tickerModelResponse = [];
  hits.forEach((hit) {
    String companyName = hit['document']['name'];
    companyName = companyName.toUpperCase();
    List<String> companyNameSegments = companyName.split(' ');

    List<String> tickerSegments = hit['document']['ticker'].split('.');

    if (tickerSegments.contains(query.toUpperCase()) || companyNameSegments.contains(query.toUpperCase())){
      hit['text_match'] += hit['text_match'];
      if(doubleTextMatchForMatchingMainTicker)
        hit['text_match'] *=4;
    }


    var obj = TickerModelResponse(
      canAddToWatchList: true,
      companyName: hit['document']['name'],
      countryName: hit['document']['country'],
      exchange: hit['document']['exchange'],
      stockName: hit['document']['ticker'],
      identifier: hit['document']['identifier'],
      textMatch: hit['text_match'],
      isin: hit['document']['isin'],
      amount: hit['document']['usdMarketCap'],
      currency: hit['document']['currency'],
      shariahStates: hit['document']?['stocks_data']?['sharia_compliance'],
      ranking: hit['document']?['stocks_data']?['ranking_v2'],
      isStock: true,
      logo: hit['document']['logo'],
    );
    tickerModelResponse.add(obj);
  });
  return tickerModelResponse;
}

List<TickerModelResponse> generateTickerResponseModelListForEtf(
    dynamic result, String query) {
  List<TickerModelResponse> tickerModelResponse = [];
  var hits = result['hits'] ?? [];
  hits.forEach((hit) {
    List<String> tickerSegments = hit['document']['symbol'].split('.');
    if (tickerSegments.contains(query.toUpperCase()))
      hit['text_match'] += hit['text_match'];
    var obj = TickerModelResponse(
        currency: hit['document']['currency'],
        canAddToWatchList: true,
        stockName: hit['document']['symbol'],
        companyName: hit['document']['name'],
        exchange: hit['document']['exchange'],
        countryName: hit['document']['domicile'],
        identifier: hit['document']['identifier'],
        textMatch: hit['text_match'],
        amount: hit['document']['aum'],
        shariahStates: hit['document']?['etfs_data']?['shariahCompliantStatus'],
        ranking: hit['document']?['etfs_data']?['ranking'],
        isStock: false);
    tickerModelResponse.add(obj);
  });

  return tickerModelResponse;
}

class TickerModelResponse {
  final bool? canAddToWatchList;
  final String? stockName;
  final String? companyName;
  final String? exchange;
  final String? countryName;
  final String? identifier;
  final int? textMatch;
  final String? isin;
  final num? amount;
  final String? currency;
  String? shariahStates;
  num? ranking;
  final bool isStock;
  final String? logo;

  TickerModelResponse(
      {this.canAddToWatchList,
      this.stockName,
      this.companyName,
      this.exchange,
      this.countryName,
      this.identifier,
      this.textMatch,
      this.isin,
      this.amount,
      this.currency,
      this.shariahStates,
      required this.isStock,
      this.logo,
      this.ranking});
}
