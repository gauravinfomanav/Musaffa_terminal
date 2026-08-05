import 'package:musaffa_terminal/shariah_compliance/models/compliance_report.dart';

/// A single browsable historical compliance filing from the Nova history API.
class ComplianceReportPeriod {
  const ComplianceReportPeriod({
    required this.id,
    required this.reportDate,
    required this.year,
    required this.quarterKey,
    required this.label,
    required this.shortLabel,
    required this.startDate,
    required this.endDate,
    required this.reportPeriodDays,
    required this.report,
  });

  final String id;
  final String reportDate;
  final String year;
  final String quarterKey;
  final String label;
  final String shortLabel;
  final String startDate;
  final String endDate;
  final int reportPeriodDays;
  final ComplianceReport report;

  bool get isAnnual =>
      quarterKey.toUpperCase().contains('ANNUAL') || reportPeriodDays >= 360;
}
