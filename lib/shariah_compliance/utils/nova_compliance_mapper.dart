import 'dart:convert';

import 'package:musaffa_terminal/shariah_compliance/models/compliance_report.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report_period.dart';

/// Maps Nova `get_compliance_history_details` payloads into [ComplianceReport].
class NovaComplianceMapper {
  NovaComplianceMapper._();

  static List<ComplianceReportPeriod> toPeriods(List<Map<String, dynamic>> raw) {
    return raw
        .map(_toPeriod)
        .whereType<ComplianceReportPeriod>()
        .toList()
      ..sort((ComplianceReportPeriod a, ComplianceReportPeriod b) {
        final int byDate = b.reportDate.compareTo(a.reportDate);
        if (byDate != 0) return byDate;
        return b.reportPeriodDays.compareTo(a.reportPeriodDays);
      });
  }

  static ComplianceReportPeriod? _toPeriod(Map<String, dynamic> json) {
    final String reportDate = _string(json['report_date']);
    if (reportDate.isEmpty) return null;

    final String year = _string(json['report_type_year']).isNotEmpty
        ? _string(json['report_type_year'])
        : _string(json['reported_year']);
    final String quarterKey = _string(json['report_type_section']).isNotEmpty
        ? _string(json['report_type_section'])
        : _string(json['reported_quarter']);
    final int reportPeriodDays = _int(json['report_period']);

    return ComplianceReportPeriod(
      id: _string(json['id'], fallback: reportDate),
      reportDate: reportDate,
      year: year,
      quarterKey: quarterKey,
      label: periodLabel(year: year, quarterKey: quarterKey),
      shortLabel: periodShortLabel(quarterKey: quarterKey),
      startDate: _string(json['start_date']),
      endDate: _string(json['end_date']),
      reportPeriodDays: reportPeriodDays,
      report: ComplianceReport.fromJson(_toTypesenseShape(json)),
    );
  }

  static String periodLabel({
    required String year,
    required String quarterKey,
  }) {
    final String short = periodShortLabel(quarterKey: quarterKey);
    if (year.isEmpty) return short;
    if (short == 'Report') return year;
    return '$year $short';
  }

  static String periodShortLabel({required String quarterKey}) {
    final String key = quarterKey.trim().toUpperCase().replaceAll(' ', '_');
    switch (key) {
      case 'FIRST_QUARTER':
        return 'Q1';
      case 'SECOND_QUARTER':
        return 'Q2';
      case 'THIRD_QUARTER':
        return 'Q3';
      case 'FOURTH_QUARTER':
        return 'Q4';
      case 'ANNUAL':
        return 'Annual';
      default:
        if (key.contains('FIRST')) return 'Q1';
        if (key.contains('SECOND')) return 'Q2';
        if (key.contains('THIRD')) return 'Q3';
        if (key.contains('FOURTH')) return 'Q4';
        if (key.contains('ANNUAL')) return 'Annual';
        if (key.isEmpty) return 'Report';
        return key.replaceAll('_', ' ');
    }
  }

  static Map<String, dynamic> _toTypesenseShape(Map<String, dynamic> nova) {
    final Map<String, dynamic> revenue =
        _parseJsonMap(nova['revenue_breakdown_json']);
    final Map<String, dynamic> interest =
        _parseJsonMap(nova['interest_income_json']);
    final Map<String, dynamic> debt =
        _parseJsonMap(nova['interest_bearing_debt_json']);
    final Map<String, dynamic> securities =
        _parseJsonMap(nova['securities_and_assets_json']);

    final Map<String, dynamic> shaped = <String, dynamic>{
      'id': _string(nova['main_ticker']).isNotEmpty
          ? _string(nova['main_ticker'])
          : _string(nova['ticker']),
      'companyName': _string(nova['company_name']),
      'status': _deriveStatus(nova),
      'exchange': _string(nova['exchange']),
      'country': _string(nova['country']),
      'currency': _string(nova['currency'], fallback: 'USD'),
      'units': _num(nova['units'], fallback: 1000000),
      'reportDate': _string(nova['report_date']),
      'reportTypeSection': _string(nova['report_type_section']).isNotEmpty
          ? _string(nova['report_type_section'])
          : _string(nova['reported_quarter']),
      'reportSource': _string(nova['report_source']),
      'lastUpdate': _string(nova['last_update_time']).isNotEmpty
          ? _string(nova['last_update_time'])
          : _string(nova['create_date_time']),
      'ranking': _num(nova['ranking']),
      'ranking_v2': _num(nova['ranking_v2']),
      'trailing36MonAvrCap': _num(nova['trailing36mon_avr_cap']),
      'totalRevenue': _num(nova['total_revenue']),
      'halal': _numOr(nova['halal'], revenue['halalPercentage']),
      'notHalal': _numOr(nova['not_halal'], revenue['notHalalPercentage']),
      'questionable':
          _numOr(nova['questionable'], revenue['questionablePercentage']),
      'halalRevenue': _num(nova['halal_revenue']),
      'notHalalRevenue': _num(nova['not_halal_revenue']),
      'questionableRevenue': _num(nova['questionable_revenue']),
      'debt': _numOr(nova['debt'], debt['totalRetio']),
      'debtStatus': _string(nova['debt_status']),
      'revenueBreakdownStatus': _string(nova['revenue_breakdown_status']),
      'securitiesAndAssetsStatus': _string(nova['securities_and_assets_status']),
      'cbaStatus': _string(nova['cba_status']),
      'totalAssets': _num(nova['total_assets']),
      'shareOutstanding': _num(nova['share_outstanding']),
      'marketCapitalization': _num(nova['market_capitalization']).abs() > 0
          ? _num(nova['market_capitalization'])
          : _num(nova['trailing36mon_avr_cap']),
      'is_ipo': _string(nova['is_ipo']),
    };

    _flattenJson(shaped, 'revenueBreakdownJson', revenue);
    _flattenJson(shaped, 'interestIncomeJson', interest);
    _flattenJson(shaped, 'interestBearingDebtJson', debt);
    _flattenJson(shaped, 'securitiesAndAssetsJson', securities);

    return shaped;
  }

  static String _deriveStatus(Map<String, dynamic> nova) {
    final String explicit = _string(nova['status']);
    if (explicit.isNotEmpty) return explicit;

    final String revenueStatus = _string(nova['revenue_breakdown_status']);
    final String debtStatus = _string(nova['debt_status']);
    final String securitiesStatus = _string(nova['securities_and_assets_status']);

    if (_isFail(revenueStatus) ||
        _isFail(debtStatus) ||
        _isFail(securitiesStatus)) {
      return 'NON_COMPLIANT';
    }

    final String cbaStatus = _string(nova['cba_status']);
    if (cbaStatus.isNotEmpty) return cbaStatus;

    return '';
  }

  static bool _isFail(String status) {
    final String key = status.trim().toUpperCase();
    return key.contains('FAIL') ||
        key.contains('NON') ||
        key.contains('NOT');
  }

  static Map<String, dynamic> _parseJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  static void _flattenJson(
    Map<String, dynamic> target,
    String prefix,
    Map<String, dynamic> json,
  ) {
    void walk(String path, dynamic value) {
      if (value is Map) {
        value.forEach((dynamic key, dynamic nested) {
          walk('$path.$key', nested);
        });
        return;
      }
      target[path] = value;
    }

    json.forEach((dynamic key, dynamic value) {
      walk('$prefix.$key', value);
    });
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num _num(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static num _numOr(dynamic primary, dynamic fallback) {
    if (primary == null) return _num(fallback);
    final String text = primary.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return _num(fallback);
    }
    return _num(primary);
  }
}
