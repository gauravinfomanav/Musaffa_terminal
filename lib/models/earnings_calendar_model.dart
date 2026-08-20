/// Finnhub earnings calendar item (`/calendar/earnings`).
///
/// EPS and revenue on this endpoint are non-GAAP/adjusted values.
class EarningsCalendarModel {
  const EarningsCalendarModel({
    required this.date,
    required this.symbol,
    this.epsActual,
    this.epsEstimate,
    this.hour,
    this.quarter,
    this.revenueActual,
    this.revenueEstimate,
    this.year,
  });

  final String date;
  final double? epsActual;
  final double? epsEstimate;
  final String? hour;
  final int? quarter;
  final double? revenueActual;
  final double? revenueEstimate;
  final String symbol;
  final int? year;

  DateTime? get dateTime {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  String get quarterLabel {
    if (quarter != null && year != null) {
      return 'Q$quarter FY$year';
    }
    if (quarter != null) {
      return 'Q$quarter';
    }
    if (year != null) {
      return 'FY$year';
    }
    return '—';
  }

  double? get epsSurprise {
    if (epsActual == null || epsEstimate == null) return null;
    return epsActual! - epsEstimate!;
  }

  double? get epsSurprisePercent {
    if (epsActual == null || epsEstimate == null || epsEstimate == 0) {
      return null;
    }
    return ((epsActual! - epsEstimate!) / epsEstimate!.abs()) * 100;
  }

  double? get revenueSurprise {
    if (revenueActual == null || revenueEstimate == null) return null;
    return revenueActual! - revenueEstimate!;
  }

  double? get revenueSurprisePercent {
    if (revenueActual == null ||
        revenueEstimate == null ||
        revenueEstimate == 0) {
      return null;
    }
    return ((revenueActual! - revenueEstimate!) / revenueEstimate!.abs()) * 100;
  }

  factory EarningsCalendarModel.fromJson(Map<String, dynamic> json) {
    return EarningsCalendarModel(
      date: (json['date'] ?? '').toString(),
      epsActual: _toDouble(json['epsActual']),
      epsEstimate: _toDouble(json['epsEstimate']),
      hour: _normalizeHour(json['hour']?.toString()),
      quarter: _toInt(json['quarter']),
      revenueActual: _toDouble(json['revenueActual']),
      revenueEstimate: _toDouble(json['revenueEstimate']),
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      year: _toInt(json['year']),
    );
  }

  Map<String, dynamic> toPassArgs() => <String, dynamic>{
        'symbol': symbol,
        'date': date,
        'quarter': quarter,
        'year': year,
        'epsActual': epsActual,
        'epsEstimate': epsEstimate,
        'revenueActual': revenueActual,
        'revenueEstimate': revenueEstimate,
        'hour': hour,
      };

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

  static String? _normalizeHour(String? raw) {
    if (raw == null) return null;
    final String h = raw.trim().toLowerCase();
    if (h.isEmpty || h == 'null' || h == 'none' || h == '-' || h == '—') {
      return null;
    }
    if (h == 'bmo' || h.contains('before')) return 'bmo';
    if (h == 'amc' || h.contains('after')) return 'amc';
    if (h == 'dmh' ||
        h.contains('during') ||
        h.contains('intraday') ||
        h == 'midday' ||
        h == 'intra') {
      return 'dmh';
    }
    return h;
  }
}
