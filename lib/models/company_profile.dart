
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/models/ticker_model.dart' hide ShariahCompliantStatus;
import 'package:musaffa_terminal/utils/utils.dart';

class CompanyProfile {
  CompanyProfile({this.id,
    this.address,
    this.city,
    this.description,
    this.employeeTotal,
    this.gsubind,
    this.logo,
    this.name,
    this.phone,
    this.state,
    this.ticker,
    this.weburl,
    this.shariahCompliantStatus,
    this.compliantRanking,
    this.mainTicker,
    this.estimateCurrency,
    this.stocksData});

  String? id;
  String? address;
  String? city;
  String? estimateCurrency;
  String? description;
  num? employeeTotal;
  String? gsubind;
  String? logo;
  String? state;
  String? name;
  String? phone;
  String? ticker;
  String? mainTicker;
  String? weburl;
  ShariahCompliantStatus? shariahCompliantStatus;
  num? compliantRanking;
  bool? showStars;
  StocksData? stocksData;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) =>
      CompanyProfile(
          id: json["id"] == null ? null : json["id"],
          address: json["address"] == null ? null : json["address"],
          city: json["city"] == null ? null : json["city"],
          estimateCurrency: json["estimateCurrency"],
          description: json["description"] == null ? null : json["description"],
          employeeTotal: parseVariableAsNum(json["employeeTotal"]),
          gsubind: json["gsubind"] == null ? null : json["gsubind"],
          logo: json["logo"] == null ? null : json["logo"],
          name: json["name"] == null ? null : json["name"],
          phone: json["phone"] == null ? null : json["phone"],
          state: json["state"] == null ? null : json["state"],
          ticker: json["ticker"] == null ? null : json["ticker"],
          weburl: json["weburl"] == null ? null : json["weburl"],
          mainTicker: json["mainTicker"] == null ? null : json["mainTicker"],
          stocksData: json['stocks_data'] != null
              ? StocksData.fromJson(json['stocks_data'])
              : null);
}