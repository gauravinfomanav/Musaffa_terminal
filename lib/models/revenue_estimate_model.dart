class RevenueEstimateModel {
  const RevenueEstimateModel({
    this.period,
    this.quarter,
    this.year,
    this.revenueAvg,
    this.revenueHigh,
    this.revenueLow,
    this.numberAnalysts,
  });

  final String? period;
  final int? quarter;
  final int? year;
  final double? revenueAvg;
  final double? revenueHigh;
  final double? revenueLow;
  final int? numberAnalysts;

  String get label {
    if (quarter != null && year != null) return 'Q$quarter $year';
    if (period != null && period!.isNotEmpty) return period!;
    return '—';
  }

  factory RevenueEstimateModel.fromJson(Map<String, dynamic> json) {
    return RevenueEstimateModel(
      period: json['period']?.toString(),
      quarter: _toInt(json['quarter']),
      year: _toInt(json['year']),
      revenueAvg: _toDouble(json['revenueAvg']),
      revenueHigh: _toDouble(json['revenueHigh']),
      revenueLow: _toDouble(json['revenueLow']),
      numberAnalysts: _toInt(json['numberAnalysts']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
