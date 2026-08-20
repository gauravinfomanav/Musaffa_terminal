import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplianceFormatters {
  static const Color halalColor = Color(0xFF1CA25B);
  static const Color notHalalColor = Color(0xFFE62026);
  static const Color doubtfulColor = Color(0xFFD88704);
  static const FontWeight statusFontWeight = FontWeight.w400;
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
      case 'FAILED':
        return 'Fail';
      default:
        if (key.contains('NON_COMPLIANT') || key.contains('NOT_HALAL')) {
          return 'Not Halal';
        }
        return status.replaceAll('_', ' ');
    }
  }

  /// Semantic tone for status badges and inline status text.
  static ComplianceStatusTone statusTone(String status) {
    if (status.isEmpty) return ComplianceStatusTone.neutral;

    final String key = status.trim().toUpperCase().replaceAll(' ', '_');
    if (key.contains('FAIL') ||
        key.contains('NON_COMPLIANT') ||
        key.contains('NOT_HALAL') ||
        (key.contains('NON') && key.contains('COMPLIANT'))) {
      return ComplianceStatusTone.negative;
    }
    if (key.contains('QUESTION') || key.contains('DOUBTFUL')) {
      return ComplianceStatusTone.caution;
    }
    if (key == 'PASS' ||
        key == 'COMPLIANT' ||
        key == 'HALAL' ||
        (key.contains('COMPLIANT') && !key.contains('NON'))) {
      return ComplianceStatusTone.positive;
    }

    switch (statusLabel(status)) {
      case 'Pass':
        return ComplianceStatusTone.positive;
      case 'Fail':
        return ComplianceStatusTone.negative;
      case 'Not Halal':
        return ComplianceStatusTone.negative;
      case 'Halal':
        return ComplianceStatusTone.positive;
      case 'Doubtful':
        return ComplianceStatusTone.caution;
      default:
        return ComplianceStatusTone.neutral;
    }
  }

  static Color statusColor(String status) {
    switch (statusTone(status)) {
      case ComplianceStatusTone.positive:
        return halalColor;
      case ComplianceStatusTone.negative:
        return notHalalColor;
      case ComplianceStatusTone.caution:
        return doubtfulColor;
      case ComplianceStatusTone.neutral:
        return const Color(0xFF6B7280);
    }
  }

  static Color statusSoftBackground(String status, {required bool isDark}) {
    return statusColor(status).withValues(alpha: isDark ? 0.14 : 0.10);
  }
}

enum ComplianceStatusTone { positive, negative, caution, neutral }
