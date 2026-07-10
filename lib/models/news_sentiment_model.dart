class NewsSentimentBuzz {
  const NewsSentimentBuzz({
    required this.articlesInLastWeek,
    required this.buzz,
    required this.weeklyAverage,
  });

  final num articlesInLastWeek;
  final double buzz;
  final double weeklyAverage;

  factory NewsSentimentBuzz.fromJson(Map<String, dynamic> json) {
    return NewsSentimentBuzz(
      articlesInLastWeek: _num(json['articlesInLastWeek']),
      buzz: _double(json['buzz']),
      weeklyAverage: _double(json['weeklyAverage']),
    );
  }
}

class NewsSentimentDistribution {
  const NewsSentimentDistribution({
    required this.bullishPercent,
    required this.bearishPercent,
  });

  final double bullishPercent;
  final double bearishPercent;

  factory NewsSentimentDistribution.fromJson(Map<String, dynamic> json) {
    return NewsSentimentDistribution(
      bullishPercent: _double(json['bullishPercent']),
      bearishPercent: _double(json['bearishPercent']),
    );
  }
}

class NewsSentimentModel {
  const NewsSentimentModel({
    required this.buzz,
    required this.companyNewsScore,
    required this.sectorAverageNewsScore,
    required this.sectorAverageBullishPercent,
    required this.sentiment,
  });

  final NewsSentimentBuzz buzz;
  final double companyNewsScore;
  final double sectorAverageNewsScore;
  final double sectorAverageBullishPercent;
  final NewsSentimentDistribution sentiment;

  factory NewsSentimentModel.fromJson(Map<String, dynamic> json) {
    return NewsSentimentModel(
      buzz: NewsSentimentBuzz.fromJson(
        _map(json['buzz']),
      ),
      companyNewsScore: _double(json['companyNewsScore']),
      sectorAverageNewsScore: _double(json['sectorAverageNewsScore']),
      sectorAverageBullishPercent: _double(json['sectorAverageBullishPercent']),
      sentiment: NewsSentimentDistribution.fromJson(
        _map(json['sentiment']),
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
