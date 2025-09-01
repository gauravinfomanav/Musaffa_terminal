import 'dart:convert';

List<TickerModel> tickerModelsFromJson(String str) =>
    List<TickerModel>.from(
        json.decode(str).map((x) => TickerModel.fromJson(x)));

List<TickerModel> tickerModelsFromMap(List<dynamic> map) =>
    List<TickerModel>.from(map.map((x) => TickerModel.fromJson(x)));

class TickerModel {
  TickerModel({
    this.stockName,
    this.companyName,
    // this.isin,
    this.sectorname,
    this.shariahCompliantStatus,
    this.lastPrice,
    this.currency,
    this.availableWatchlistIds,
    this.exchange,
    this.countryName,
    this.country,
    this.canAddToWatchlist = false,
    this.compliantRanking,
    this.etfCompany,
    this.symbol,
    this.navCurrency,
    this.domicile,
    this.name,
    this.ticker,
    this.notifyOnComplianceChange = false,
    this.logo,
    this.currentPrice,
    required this.isStock,
    this.analystRating,
    this.mainTicker,
    this.percentChange
  });

  String? exchange;
  String? logo;
  String? country;
  num? currentPrice;
  num? percentChange;

  // OLD
  String? stockName;
  String? companyName;

  // String? isin;
  String? currency;
  
  ShariahCompliantStatus? shariahCompliantStatus;
  double? lastPrice;
  bool canAddToWatchlist;
  List<String>? availableWatchlistIds;

  String? countryName;
  num? compliantRanking;

  String? etfCompany;
  String? symbol;
  String? navCurrency;
  String? domicile;
  String? name;
  String? ticker;
  bool? notifyOnComplianceChange;
  String? mainTicker;
  bool isStock;
  String? analystRating;
  
  String? sectorname;

  factory TickerModel.fromJson(Map<String, dynamic> json) =>
      TickerModel(
          currentPrice: json['currentPrice'] == null
              ? null
              : json["currentPrice"],
          stockName: json["stockName"] == null ? null : json["stockName"],
          sectorname: json['musaffaSector'],
          country: json["country"] == null ? null : json["country"],
          companyName: json["companyName"] == null ? null : json["companyName"],
          // isin: json["isin"] == null ? null : json["isin"],
          shariahCompliantStatus: json["shariahCompliantStatus"] == null
              ? null : shariahCompliantStatusValues
              .map[json["shariahCompliantStatus"]],
          lastPrice:
          json["lastPrice"] == null ? null : json["lastPrice"].toDouble(),
          currency: json["currency"],
          canAddToWatchlist: json["canAddToWatchlist"] == null
              ? false
              : json["canAddToWatchlist"],
          exchange: json["exchange"] == null ? null : json["exchange"],
          countryName: json["countryName"] == null ? null : json["countryName"],
          availableWatchlistIds: json["availableWatchlistIds"] == null
              ? null
              : List<String>.from(json["availableWatchlistIds"].map((x) => x)),
          compliantRanking: json['compliantRanking'],
          etfCompany: json['etfCompany'],
          symbol: json['symbol'],
          navCurrency: json['navCurrency'].toString(),
          domicile: json['domicile'],
          ticker: json['ticker'],
          name: json['name'],
          notifyOnComplianceChange: json['notifyOnComplianceChange'] == null
              ? false
              : json['notifyOnComplianceChange'],
          logo: json['logo'],
          isStock: json['isStock'],
          mainTicker: json['mainTicker'],
      );
}

enum ShariahCompliantStatus {
  NOT_UNDER_COVERAGE,
  NON_COMPLIANT,
  QUESTIONABLE,
  COMPLIANT,
  DEFAULT,
}

final shariahCompliantStatusValues = EnumValues({
  "NOT_UNDER_COVERAGE": ShariahCompliantStatus.NOT_UNDER_COVERAGE,
  "COMPLIANT": ShariahCompliantStatus.COMPLIANT,
  "QUESTIONABLE": ShariahCompliantStatus.QUESTIONABLE,
  "NON_COMPLIANT": ShariahCompliantStatus.NON_COMPLIANT,
  "DEFAULT": ShariahCompliantStatus.DEFAULT,
});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String>? reverseMap;

  EnumValues(this.map);

  Map<T, String>? get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}
