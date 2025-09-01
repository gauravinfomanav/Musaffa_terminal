import 'dart:convert';
import 'package:musaffa_terminal/utils/utils.dart';

SocketMessage socketMessageFromJson(String str) =>
    SocketMessage.fromJson(json.decode(str));

class SocketMessage {
  SocketMessage(
      {required this.id,
      this.currentPrice,
      this.change,
      this.percentChange,
      this.todaysHigh,
      this.todaysLow,
      this.todaysOpen,
      this.fiftyTwoWeekHigh,
      this.fiftyTwoWeekLow,
      this.avgVolume30days,
      this.volume,
      this.dividendYield,
      this.priceLastUpdated,
      this.aum,
      this.priceToBook,
      this.priceToEarnings,
      this.expenseRatio,
      this.peAnnual});

  num? currentPrice;
  num? change;
  num? percentChange;
  num? todaysHigh;
  num? todaysLow;
  num? todaysOpen;
  num? fiftyTwoWeekHigh;
  num? fiftyTwoWeekLow;
  num? avgVolume30days;
  num? volume;
  String id;
  DateTime? priceLastUpdated;
  num? dividendYield;
  num? peAnnual;
  num? aum;
  num? priceToBook;
  num? priceToEarnings;
  num? expenseRatio;

  factory SocketMessage.fromJson(Map<String, dynamic> json) => SocketMessage(
        currentPrice: parseVariableAsNum(json["currentPrice"]),
        change: parseVariableAsNum(json["priceChange1D"]),
        percentChange: parseVariableAsNum(json["priceChange1DPercent"]),
        todaysHigh: parseVariableAsNum(json["high"]),
        todaysLow: parseVariableAsNum(json["low"]),
        todaysOpen: parseVariableAsNum(json["open"]),
        fiftyTwoWeekHigh: parseVariableAsNum(json["52WeekHigh"]),
        fiftyTwoWeekLow: parseVariableAsNum(json["52WeekLow"]),
        avgVolume30days: parseVariableAsNum(json["avgVolume30days"]),
        volume: json["volume"],
        id: json["id"],

        priceLastUpdated: json["priceLastUpdated"] == null
            ? null
            : DateTime.tryParse(json["priceLastUpdated"]),
        dividendYield: json["currentDividendYieldTTM"],
        peAnnual: json["peAnnual"],

        // etf fields
        aum: json['aum'],
        priceToBook: json['priceToBook'],
        priceToEarnings: json['priceToEarnings'],
        expenseRatio: json['expenseRatio'],
      );
}

class SocketMessageCollection {
  List<Hits>? hits;
  int? page;
  bool? searchCutoff;
  int? searchTimeMs;

  SocketMessageCollection(
      {
      this.hits,

      this.page,
      this.searchCutoff,
      this.searchTimeMs});

  SocketMessageCollection.fromJson(Map<String, dynamic> json) {

    if (json['hits'] != null) {
      hits = <Hits>[];
      json['hits'].forEach((v) {
        hits!.add(new Hits.fromJson(v));
      });
    }
    page = json['page'];

    searchCutoff = json['search_cutoff'];
    searchTimeMs = json['search_time_ms'];
  }
}

class Hits {
  SocketMessage? document;
  List<Null>? highlights;
  int? textMatch;

  Hits({this.document, this.highlights, this.textMatch});

  Hits.fromJson(Map<String, dynamic> json) {
    document = json['document'] != null
        ? new SocketMessage.fromJson(json['document'])
        : null;

    textMatch = json['text_match'];
  }
}
