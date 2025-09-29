class LivePriceData {
  final String symbol;
  final double price;
  final int? volume;
  final int timestamp;
  final String dateTimeUtc;
  final double? typesensePrice; // Store original Typesense price for comparison

  LivePriceData({
    required this.symbol,
    required this.price,
    this.volume,
    required this.timestamp,
    required this.dateTimeUtc,
    this.typesensePrice,
  });

  factory LivePriceData.fromJson(Map<String, dynamic> json, {double? typesensePrice}) {
    return LivePriceData(
      symbol: json['symbol'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      volume: json['volume'],
      timestamp: json['timestamp'] ?? 0,
      dateTimeUtc: json['date_time_utc'] ?? '',
      typesensePrice: typesensePrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'volume': volume,
      'timestamp': timestamp,
      'date_time_utc': dateTimeUtc,
      'typesense_price': typesensePrice,
    };
  }

  /// Get color based on price comparison with Typesense price
  /// Green if live price > typesense price
  /// Red if live price < typesense price
  /// null if same or no typesense price available
  String? getPriceColor() {
    if (typesensePrice == null) return null;
    
    if (price > typesensePrice!) {
      return 'green';
    } else if (price < typesensePrice!) {
      return 'red';
    } else {
      return 'same';
    }
  }

  /// Check if price has increased compared to Typesense price
  bool get isPriceUp => typesensePrice != null && price > typesensePrice!;

  /// Check if price has decreased compared to Typesense price
  bool get isPriceDown => typesensePrice != null && price < typesensePrice!;

  /// Check if price is same as Typesense price
  bool get isPriceSame => typesensePrice != null && price == typesensePrice!;

  @override
  String toString() {
    return 'LivePriceData(symbol: $symbol, price: $price, volume: $volume, timestamp: $timestamp, typesensePrice: $typesensePrice)';
  }
}

class LivePriceResponse {
  final String status;
  final String type;
  final Map<String, LivePriceData> data;

  LivePriceResponse({
    required this.status,
    required this.type,
    required this.data,
  });

  factory LivePriceResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = <String, LivePriceData>{};
    
    if (json['data'] != null) {
      final dataJson = json['data'] as Map<String, dynamic>;
      dataJson.forEach((key, value) {
        dataMap[key] = LivePriceData.fromJson(value);
      });
    }

    return LivePriceResponse(
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      data: dataMap,
    );
  }

  @override
  String toString() {
    return 'LivePriceResponse(status: $status, type: $type, data: $data)';
  }
}
