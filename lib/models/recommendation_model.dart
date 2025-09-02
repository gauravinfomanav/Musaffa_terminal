class RecommendationModel {
  final int buy;
  final int hold;
  final String id;
  final String period;
  final int sell;
  final int strongBuy;
  final int strongSell;
  final String symbol;
  final String ticker;

  RecommendationModel({
    required this.buy,
    required this.hold,
    required this.id,
    required this.period,
    required this.sell,
    required this.strongBuy,
    required this.strongSell,
    required this.symbol,
    required this.ticker,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      buy: json['buy'] ?? 0,
      hold: json['hold'] ?? 0,
      id: json['id'] ?? '',
      period: json['period'] ?? '',
      sell: json['sell'] ?? 0,
      strongBuy: json['strongBuy'] ?? 0,
      strongSell: json['strongSell'] ?? 0,
      symbol: json['symbol'] ?? '',
      ticker: json['ticker'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buy': buy,
      'hold': hold,
      'id': id,
      'period': period,
      'sell': sell,
      'strongBuy': strongBuy,
      'strongSell': strongSell,
      'symbol': symbol,
      'ticker': ticker,
    };
  }

  // Calculate weighted average for recommendation
  double get weightedAverage {
    int total = strongBuy + buy + hold + sell + strongSell;
    if (total == 0) return 0.0;
    
    // Weighted calculation: Strong Buy = 5, Buy = 4, Hold = 3, Sell = 2, Strong Sell = 1
    double weightedSum = (strongBuy * 5) + (buy * 4) + (hold * 3) + (sell * 2) + (strongSell * 1);
    return weightedSum / total;
  }

  // Get recommendation text based on weighted average
  String get recommendationText {
    if (weightedAverage >= 4.5) return 'Strong Buy';
    if (weightedAverage >= 3.5) return 'Buy';
    if (weightedAverage >= 2.5) return 'Hold';
    if (weightedAverage >= 1.5) return 'Sell';
    return 'Strong Sell';
  }

  // Get recommendation color
  int get recommendationColor {
    if (weightedAverage >= 4.5) return 0xFF99CD44; // Green
    if (weightedAverage >= 3.5) return 0xFF81AACE; // Blue
    if (weightedAverage >= 2.5) return 0xFFFFAD35; // Orange
    if (weightedAverage >= 1.5) return 0xFFFF6B35; // Red-Orange
    return 0xFFFF0000; // Red
  }
}
