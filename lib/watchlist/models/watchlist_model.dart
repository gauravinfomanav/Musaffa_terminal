import 'dart:convert';

class WatchlistModel {
  final String id;
  final String name;
  final WatchlistDate dateCreated;
  final int stockCount;

  WatchlistModel({
    required this.id,
    required this.name,
    required this.dateCreated,
    required this.stockCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory WatchlistModel.fromJson(Map<String, dynamic> json) {
    return WatchlistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dateCreated: WatchlistDate.fromJson(json['date_created'] ?? {}),
      stockCount: json['stock_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date_created': dateCreated.toJson(),
      'stock_count': stockCount,
    };
  }

  static List<WatchlistModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => WatchlistModel.fromJson(json)).toList();
  }
}

class WatchlistDate {
  final int seconds;
  final int nanoseconds;

  WatchlistDate({
    required this.seconds,
    required this.nanoseconds,
  });

  factory WatchlistDate.fromJson(Map<String, dynamic> json) {
    return WatchlistDate(
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

class WatchlistResponse {
  final String status;
  final List<WatchlistModel> data;
  final int count;

  WatchlistResponse({
    required this.status,
    required this.data,
    required this.count,
  });

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) {
    return WatchlistResponse(
      status: json['status'] ?? '',
      data: WatchlistModel.fromJsonList(json['data'] ?? []),
      count: json['count'] ?? 0,
    );
  }

  static WatchlistResponse fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return WatchlistResponse.fromJson(json);
  }
}
