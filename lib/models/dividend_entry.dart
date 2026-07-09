class DividendEntry {
  final double? amount;
  final double? adjustedAmount;
  final String? currency;
  final DateTime date;
  final DateTime? declarationDate;
  final DateTime? payDate;
  final DateTime? recordDate;
  final int? frequency;

  const DividendEntry({
    this.amount,
    this.adjustedAmount,
    this.currency,
    required this.date,
    this.declarationDate,
    this.payDate,
    this.recordDate,
    this.frequency,
  });

  factory DividendEntry.fromJson(Map<String, dynamic> json) {
    return DividendEntry(
      amount: _toDouble(json['amount']),
      adjustedAmount: _toDouble(json['adjustedAmount']),
      currency: json['currency']?.toString(),
      date: _parseDate(json['date']) ?? DateTime.now(),
      declarationDate: _parseDate(json['declarationDate']),
      payDate: _parseDate(json['payDate']),
      recordDate: _parseDate(json['recordDate']),
      frequency: _toInt(json['frequency']),
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case 1:
        return 'Annual';
      case 2:
        return 'Semi-Annual';
      case 4:
        return 'Quarterly';
      case 12:
        return 'Monthly';
      case 24:
        return 'Bi-Monthly';
      case 52:
        return 'Weekly';
      default:
        return frequency == null ? '--' : '${frequency}x/yr';
    }
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
