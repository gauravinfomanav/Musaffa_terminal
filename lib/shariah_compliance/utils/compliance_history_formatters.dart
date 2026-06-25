import 'package:intl/intl.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_history_item.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_formatters.dart';

/// Display helpers for historical compliance report table rows.
class ComplianceHistoryFormatters {
  ComplianceHistoryFormatters._();

  static String period(ComplianceHistoryItem item) {
    final String start = formatDate(item.startDate);
    final String end = formatDate(item.endDate);
    if (start != '-' && end != '-') {
      return '$start → $end';
    }
    if (item.reportDate.isNotEmpty) {
      return formatDate(item.reportDate);
    }
    return '-';
  }

  static String reportDate(ComplianceHistoryItem item) {
    return formatDate(item.reportDate);
  }

  static String coverageFrom(ComplianceHistoryItem item) {
    return formatDate(_safeText(item.startDate));
  }

  static String coverageTo(ComplianceHistoryItem item) {
    return formatDate(_safeText(item.endDate));
  }

  static String fiscalQuarter(ComplianceHistoryItem item) {
    final String quarter = _safeText(item.reportedQuarter);
    final String year = _safeText(item.reportedYear);
    if (quarter.isEmpty && year.isEmpty) return '-';

    final String label = quarterLabel(quarter);
    if (year.isEmpty) return label;
    return '$label $year';
  }

  /// API `report_period` is cumulative fiscal days (91, 182, 273, 364).
  static String reportPeriod(ComplianceHistoryItem item) {
    final String quarter = _safeText(item.reportedQuarter).toUpperCase();
    if (quarter.contains('ANNUAL')) return '12 Months';

    final int days = item.reportPeriod;
    if (days <= 0) return quarterPeriodLabel(quarter);

    if (days >= 360) return '12 Months';
    if (days >= 270) return '9 Months';
    if (days >= 180) return '6 Months';
    if (days >= 90) return '3 Months';
    return '$days Days';
  }

  static String _safeText(String? value) => (value ?? '').trim();

  static String ticker(ComplianceHistoryItem item) {
    final String main = _safeText(item.mainTicker);
    if (main.isNotEmpty) return main.toUpperCase();
    final String symbol = _safeText(item.ticker);
    return symbol.isEmpty ? '-' : symbol.toUpperCase();
  }

  static String isin(ComplianceHistoryItem item) {
    final String value = _safeText(item.isin);
    return value.isEmpty ? '-' : value.toUpperCase();
  }

  static String currency(ComplianceHistoryItem item) {
    final String value = _safeText(item.currency);
    if (value.isNotEmpty) return value.toUpperCase();
    final String sub = _safeText(item.subtickerCurrency);
    return sub.isEmpty ? '-' : sub.toUpperCase();
  }

  static String createdAt(ComplianceHistoryItem item) {
    return formatDateTime(_safeText(item.createDateTime));
  }

  static String isIpo(ComplianceHistoryItem item) {
    final String value = _safeText(item.isIpo);
    if (value.isEmpty) return '-';
    if (value == '1' || value.toLowerCase() == 'true') return 'Yes';
    if (value == '0' || value.toLowerCase() == 'false') return 'No';
    return value;
  }

  static String quarterLabel(String raw) {
    final String key = _quarterKey(raw);
    switch (key) {
      case 'FIRST_QUARTER':
        return '1st Quarter';
      case 'SECOND_QUARTER':
        return '2nd Quarter';
      case 'THIRD_QUARTER':
        return '3rd Quarter';
      case 'FOURTH_QUARTER':
        return '4th Quarter';
      case 'ANNUAL':
        return 'Annual Report';
      default:
        if (key.contains('FIRST')) return '1st Quarter';
        if (key.contains('SECOND')) return '2nd Quarter';
        if (key.contains('THIRD')) return '3rd Quarter';
        if (key.contains('FOURTH')) return '4th Quarter';
        if (key.contains('ANNUAL')) return 'Annual Report';
        return raw.replaceAll('_', ' ');
    }
  }

  static String quarterPeriodLabel(String raw) {
    final String key = _quarterKey(raw);
    switch (key) {
      case 'FIRST_QUARTER':
        return '3 Months';
      case 'SECOND_QUARTER':
        return '6 Months';
      case 'THIRD_QUARTER':
        return '9 Months';
      case 'FOURTH_QUARTER':
        return '12 Months';
      case 'ANNUAL':
        return '12 Months';
      default:
        return '-';
    }
  }

  static String _quarterKey(String raw) {
    var key = raw.trim().toUpperCase().replaceAll(' ', '_');
    if (key.startsWith('Q')) {
      key = key.substring(1);
    }
    return key;
  }

  static String formatDate(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';

    final DateTime? parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return DateFormat('MMM d, yyyy').format(parsed.toLocal());
    }

    return trimmed;
  }

  static String formatDateTime(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';

    final DateTime? parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return DateFormat('MMM d, yyyy').format(parsed.toLocal());
    }

    return trimmed;
  }

  static String notHalalAmount(ComplianceHistoryItem item) {
    return formatMoney(item.notHalalAmount);
  }

  static String doubtfulAmount(ComplianceHistoryItem item) {
    return formatMoney(item.doubtfulAmount);
  }

  static String sharesOutstanding(ComplianceHistoryItem item) {
    return formatMillions(item.shareOutstanding);
  }

  static String status(ComplianceHistoryItem item) {
    return ComplianceFormatters.statusLabel(item.complianceStatus);
  }

  static String formatMoney(num value) {
    if (value == 0) return '-';
    return ComplianceFormatters.compactMoney(value, fromOnes: true);
  }

  static String formatMillions(num value) {
    if (value == 0) return '-';
    return '${NumberFormat('#,##0.##').format(value)}M';
  }

  static String formatNumber(num value, {int digits = 2}) {
    if (value == 0) return '-';
    return NumberFormat('#,##0.${'#' * digits}').format(value);
  }
}
