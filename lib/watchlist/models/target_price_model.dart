class TargetPriceModel {
  final String targetId;
  final String ticker;
  final double targetPrice;
  final String alertType;
  final String watchlistId;
  final String watchlistName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool triggered;
  final DateTime? triggeredAt;
  final double currentPrice;

  TargetPriceModel({
    required this.targetId,
    required this.ticker,
    required this.targetPrice,
    required this.alertType,
    required this.watchlistId,
    required this.watchlistName,
    required this.isActive,
    required this.createdAt,
    required this.lastUpdated,
    required this.triggered,
    this.triggeredAt,
    required this.currentPrice,
  });

  factory TargetPriceModel.fromJson(Map<String, dynamic> json) {
    return TargetPriceModel(
      targetId: json['target_id'] ?? '',
      ticker: json['ticker'] ?? '',
      targetPrice: (json['target_price'] ?? 0.0).toDouble(),
      alertType: json['alert_type'] ?? 'above',
      watchlistId: json['watchlist_id'] ?? '',
      watchlistName: json['watchlist_name'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: _parseDateTime(json['created_at']),
      lastUpdated: _parseDateTime(json['last_updated']),
      triggered: json['triggered'] ?? false,
      triggeredAt: json['triggered_at'] != null ? _parseDateTime(json['triggered_at']) : null,
      currentPrice: (json['current_price'] ?? 0.0).toDouble(),
    );
  }

  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData is Map<String, dynamic>) {
      // Handle Firestore timestamp format
      final seconds = dateData['_seconds'] ?? 0;
      final nanoseconds = dateData['_nanoseconds'] ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + (nanoseconds / 1000000).round(),
      );
    } else if (dateData is String) {
      return DateTime.parse(dateData);
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'target_id': targetId,
      'ticker': ticker,
      'target_price': targetPrice,
      'alert_type': alertType,
      'watchlist_id': watchlistId,
      'watchlist_name': watchlistName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'triggered': triggered,
      'triggered_at': triggeredAt?.toIso8601String(),
      'current_price': currentPrice,
    };
  }

  TargetPriceModel copyWith({
    String? targetId,
    String? ticker,
    double? targetPrice,
    String? alertType,
    String? watchlistId,
    String? watchlistName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? triggered,
    DateTime? triggeredAt,
    double? currentPrice,
  }) {
    return TargetPriceModel(
      targetId: targetId ?? this.targetId,
      ticker: ticker ?? this.ticker,
      targetPrice: targetPrice ?? this.targetPrice,
      alertType: alertType ?? this.alertType,
      watchlistId: watchlistId ?? this.watchlistId,
      watchlistName: watchlistName ?? this.watchlistName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      triggered: triggered ?? this.triggered,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }

  @override
  String toString() {
    return 'TargetPriceModel(targetId: $targetId, ticker: $ticker, targetPrice: $targetPrice, alertType: $alertType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TargetPriceModel &&
        other.targetId == targetId &&
        other.ticker == ticker &&
        other.targetPrice == targetPrice &&
        other.alertType == alertType;
  }

  @override
  int get hashCode {
    return targetId.hashCode ^
        ticker.hashCode ^
        targetPrice.hashCode ^
        alertType.hashCode;
  }
}
