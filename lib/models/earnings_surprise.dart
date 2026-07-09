class EarningsSurprise {
  final double? actual;
  final double? estimate;
  final double? surprise;
  final double? surprisePercent;
  final DateTime period;
  final int? quarter;
  final int? year;

  const EarningsSurprise({
    this.actual,
    this.estimate,
    this.surprise,
    this.surprisePercent,
    required this.period,
    this.quarter,
    this.year,
  });

  factory EarningsSurprise.fromJson(Map<String, dynamic> json) {
    return EarningsSurprise(
      actual: _toDouble(json['actual']),
      estimate: _toDouble(json['estimate']),
      surprise: _toDouble(json['surprise']),
      surprisePercent: _toDouble(json['surprisePercent']),
      period: DateTime.parse(json['period'].toString()),
      quarter: _toInt(json['quarter']),
      year: _toInt(json['year']),
    );
  }

  String get quarterLabel {
    if (quarter != null && year != null) {
      return 'Q$quarter $year';
    }
    return '--';
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
