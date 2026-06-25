import 'package:intl/intl.dart';

class ComplianceFormatters {
  static String percent(num value, {int digits = 2}) {
    return '${value.toStringAsFixed(digits)}%';
  }

  static String compactMoney(
    num value, {
    String currency = 'USD',
    bool fromOnes = false,
  }) {
    final double amount = fromOnes ? value.toDouble() : value.toDouble() * 1000000;
    if (amount.abs() >= 1e12) {
      return '\$${(amount / 1e12).toStringAsFixed(2)}T';
    }
    if (amount.abs() >= 1e9) {
      return '\$${(amount / 1e9).toStringAsFixed(2)}B';
    }
    if (amount.abs() >= 1e6) {
      return '\$${(amount / 1e6).toStringAsFixed(2)}M';
    }
    if (amount.abs() >= 1e3) {
      return '\$${(amount / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String millions(num value) {
    return '\$${NumberFormat('#,##0').format(value)}M';
  }

  static String statusLabel(String status) {
    if (status.isEmpty) return '-';
    final String key = status.trim().toUpperCase().replaceAll(' ', '_');

    switch (key) {
      case 'NON_COMPLIANT':
      case 'NOT_HALAL':
      case 'NON_COMPLIANT_REVENUE':
        return 'Not Halal';
      case 'COMPLIANT':
        return 'Halal';
      case 'QUESTIONABLE':
      case 'DOUBTFUL':
        return 'Doubtful';
      case 'PASS':
        return 'Pass';
      case 'FAIL':
        return 'Fail';
      default:
        if (key.contains('NON_COMPLIANT') || key.contains('NOT_HALAL')) {
          return 'Not Halal';
        }
        return status.replaceAll('_', ' ');
    }
  }
}
