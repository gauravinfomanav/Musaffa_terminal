class EpsEstimateModel {
  const EpsEstimateModel({
    this.period,
    this.quarter,
    this.year,
    this.epsAvg,
    this.epsHigh,
    this.epsLow,
    this.numberAnalysts,
  });

  final String? period;
  final int? quarter;
  final int? year;
  final double? epsAvg;
  final double? epsHigh;
  final double? epsLow;
  final int? numberAnalysts;

  String get label {
    if (quarter != null && year != null) return 'Q$quarter $year';
    if (period != null && period!.isNotEmpty) return period!;
    return '—';
  }

  factory EpsEstimateModel.fromJson(Map<String, dynamic> json) {
    return EpsEstimateModel(
      period: json['period']?.toString(),
      quarter: _toInt(json['quarter']),
      year: _toInt(json['year']),
      epsAvg: _toDouble(json['epsAvg']),
      epsHigh: _toDouble(json['epsHigh']),
      epsLow: _toDouble(json['epsLow']),
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
