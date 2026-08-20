import 'package:intl/intl.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';

class FinnhubDisplayFormatters {
  const FinnhubDisplayFormatters._();

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final NumberFormat _revenueFormat = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return _dateFormat.format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return _shortDateFormat.format(date);
  }

  static String formatEps(double? value) {
    if (value == null) {
      return '-';
    }
    return _currencyFormat.format(value);
  }

  static String formatRevenue(double? value) {
    if (value == null) {
      return '-';
    }
    if (value.abs() >= 1000000) {
      return _revenueFormat.format(value);
    }
    return '\$${_currencyFormat.format(value)}';
  }

  static String formatPercent(double? value, {bool signed = true}) {
    if (value == null) {
      return '-';
    }
    final String sign = signed && value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String formatDividend(double? value) {
    if (value == null) {
      return '-';
    }
    return '\$${value.toStringAsFixed(4)}';
  }

  static String formatAnnouncementHour(String? hour) {
    switch (hour?.toLowerCase()) {
      case 'bmo':
        return 'Before Market Open';
      case 'amc':
        return 'After Market Close';
      case 'dmh':
        return 'During Market Hours';
      default:
        return hour == null || hour.isEmpty
            ? 'Time not available'
            : hour.toUpperCase();
    }
  }

  static String formatHourBadge(String? hour) {
    switch (hour?.toLowerCase()) {
      case 'bmo':
        return 'BMO';
      case 'amc':
        return 'AMC';
      case 'dmh':
        return 'DMH';
      default:
        return '—';
    }
  }

  /// Formats large currency values as `$91.82B`, `$2.35T`, etc.
  static String formatCompactCurrency(num? value) {
    if (value == null) return '—';
    final double abs = value.abs().toDouble();
    final String sign = value < 0 ? '-' : '';
    if (abs >= 1e12) {
      return '$sign\$${(abs / 1e12).toStringAsFixed(2)}T';
    }
    if (abs >= 1e9) {
      return '$sign\$${(abs / 1e9).toStringAsFixed(2)}B';
    }
    if (abs >= 1e6) {
      return '$sign\$${(abs / 1e6).toStringAsFixed(2)}M';
    }
    if (abs >= 1e3) {
      return '$sign\$${(abs / 1e3).toStringAsFixed(2)}K';
    }
    return '$sign\$${abs.toStringAsFixed(2)}';
  }

  static String dashIfNull(String? value) {
    if (value == null || value.trim().isEmpty) return '—';
    return value;
  }

  static int? daysUntil(DateTime date) {
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    final DateTime targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.difference(todayDate).inDays;
  }

  static String formatDaysRemaining(EarningsCalendarEntry entry) {
    final int? days = daysUntil(entry.date);
    if (days == null) {
      return '-';
    }
    if (days == 0) {
      return 'Today';
    }
    if (days == 1) {
      return '1 day';
    }
    return '$days days';
  }
}
