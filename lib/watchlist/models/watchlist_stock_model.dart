import 'dart:convert';

class WatchlistStock {
  final String id;
  final String ticker;
  final double currentPrice;
  final WatchlistStockDate dateAdded;

  WatchlistStock({
    required this.id,
    required this.ticker,
    required this.currentPrice,
    required this.dateAdded,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistStock &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory WatchlistStock.fromJson(Map<String, dynamic> json) {
    return WatchlistStock(
      id: json['id'] ?? '',
      ticker: json['ticker'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      dateAdded: WatchlistStockDate.fromJson(json['date_added'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticker': ticker,
      'current_price': currentPrice,
      'date_added': dateAdded.toJson(),
    };
  }

  static List<WatchlistStock> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => WatchlistStock.fromJson(json)).toList();
  }
}

class WatchlistStockDate {
  final int seconds;
  final int nanoseconds;

  WatchlistStockDate({
    required this.seconds,
    required this.nanoseconds,
  });

  factory WatchlistStockDate.fromJson(Map<String, dynamic> json) {
    return WatchlistStockDate(
      seconds: json['_seconds'] ?? 0,
      nanoseconds: json['_nanoseconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_seconds': seconds,
      '_nanoseconds': nanoseconds,
    };
  }

  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000 + (nanoseconds / 1000000).round(),
    );
  }
}

class WatchlistStocksResponse {
  final String status;
  final List<WatchlistStock> data;
  final int count;

  WatchlistStocksResponse({
    required this.status,
    required this.data,
    required this.count,
  });

  factory WatchlistStocksResponse.fromJson(Map<String, dynamic> json) {
    return WatchlistStocksResponse(
      status: json['status'] ?? '',
      data: WatchlistStock.fromJsonList(json['data'] ?? []),
      count: json['count'] ?? 0,
    );
  }

  static WatchlistStocksResponse fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return WatchlistStocksResponse.fromJson(json);
  }
}
