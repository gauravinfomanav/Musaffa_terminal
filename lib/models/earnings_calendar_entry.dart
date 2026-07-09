class EarningsCalendarEntry {
  final String symbol;
  final DateTime date;
  final double? epsActual;
  final double? epsEstimate;
  final double? revenueActual;
  final double? revenueEstimate;
  final String? hour;
  final int? quarter;
  final int? year;

  const EarningsCalendarEntry({
    required this.symbol,
    required this.date,
    this.epsActual,
    this.epsEstimate,
    this.revenueActual,
    this.revenueEstimate,
    this.hour,
    this.quarter,
    this.year,
  });

  factory EarningsCalendarEntry.fromJson(Map<String, dynamic> json) {
    return EarningsCalendarEntry(
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      date: DateTime.parse(json['date'].toString()),
      epsActual: _toDouble(json['epsActual']),
      epsEstimate: _toDouble(json['epsEstimate']),
      revenueActual: _toDouble(json['revenueActual']),
      revenueEstimate: _toDouble(json['revenueEstimate']),
      hour: json['hour']?.toString(),
      quarter: _toInt(json['quarter']),
      year: _toInt(json['year']),
    );
  }

  String get quarterLabel {
    if (quarter != null && year != null) {
      return 'Q$quarter $year';
    }
    if (year != null) {
      return year.toString();
    }
    return '--';
  }

  bool get isUpcoming {
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    final DateTime entryDate = DateTime(date.year, date.month, date.day);
    return !entryDate.isBefore(todayDate);
  }

  bool get isHistorical => !isUpcoming;

  double? get surprisePercent {
    if (epsActual == null || epsEstimate == null || epsEstimate == 0) {
      return null;
    }
    return ((epsActual! - epsEstimate!) / epsEstimate!.abs()) * 100;
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
