class HistoricalPrice {
  final String exchangeSymbol;
  final String companySymbol;
  final String resolution;
  final double close;
  final double high;
  final double low;
  final double open;
  final double volume;
  final String datetime;
  final String createdDate;

  HistoricalPrice({
    required this.exchangeSymbol,
    required this.companySymbol,
    required this.resolution,
    required this.close,
    required this.high,
    required this.low,
    required this.open,
    required this.volume,
    required this.datetime,
    required this.createdDate,
  });

  factory HistoricalPrice.fromJson(Map<String, dynamic> json) {
    return HistoricalPrice(
      exchangeSymbol: json['exchange_symbol'] ?? '',
      companySymbol: json['company_symbol'] ?? '',
      resolution: json['resolution'] ?? 'D',
      close: (json['c'] as num).toDouble(),
      high: (json['h'] as num).toDouble(),
      low: (json['l'] as num).toDouble(),
      open: (json['o'] as num).toDouble(),
      volume: (json['v'] as num).toDouble(),
      datetime: json['datetime'] ?? '',
      createdDate: json['created_date'] ?? '',
    );
  }

  /// Get formatted close price
  String get formattedClosePrice {
    return '\$${close.toStringAsFixed(2)}';
  }

  /// Get formatted volume
  String get formattedVolume {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }

  /// Get price change from open to close
  double get priceChange {
    return close - open;
  }

  /// Get price change percentage
  double get priceChangePercent {
    return ((close - open) / open) * 100;
  }

  /// Get formatted price change
  String get formattedPriceChange {
    final change = priceChange;
    final sign = change >= 0 ? '+' : '';
    return '$sign\$${change.toStringAsFixed(2)}';
  }

  /// Get formatted price change percentage
  String get formattedPriceChangePercent {
    final changePercent = priceChangePercent;
    final sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }
}
