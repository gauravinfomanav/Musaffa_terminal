class RecommendationTrendModel {
  const RecommendationTrendModel({
    required this.period,
    required this.strongBuy,
    required this.buy,
    required this.hold,
    required this.sell,
    required this.strongSell,
  });

  final String period;
  final int strongBuy;
  final int buy;
  final int hold;
  final int sell;
  final int strongSell;

  factory RecommendationTrendModel.fromJson(Map<String, dynamic> json) {
    return RecommendationTrendModel(
      period: (json['period'] ?? '').toString(),
      strongBuy: _toInt(json['strongBuy']),
      buy: _toInt(json['buy']),
      hold: _toInt(json['hold']),
      sell: _toInt(json['sell']),
      strongSell: _toInt(json['strongSell']),
    );
  }

  int get total => strongBuy + buy + hold + sell + strongSell;

  String get consensusText {
    if (total == 0) return '--';
    final double weighted = ((strongBuy * 5) +
            (buy * 4) +
            (hold * 3) +
            (sell * 2) +
            (strongSell * 1)) /
        total;
    if (weighted >= 4.5) return 'Strong Buy';
    if (weighted >= 3.5) return 'Buy';
    if (weighted >= 2.5) return 'Hold';
    if (weighted >= 1.5) return 'Sell';
    return 'Strong Sell';
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
