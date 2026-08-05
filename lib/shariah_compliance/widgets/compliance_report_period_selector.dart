import 'package:flutter/material.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report_period.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_history_formatters.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class ComplianceReportPeriodSelector extends StatelessWidget {
  const ComplianceReportPeriodSelector({
    super.key,
    required this.periods,
    required this.viewingHistorical,
    required this.selectedYear,
    required this.selectedPeriodId,
    required this.onSelectCurrent,
    required this.onSelectYear,
    required this.onSelectPeriod,
    required this.isDark,
    required this.secondary,
  });

  final List<ComplianceReportPeriod> periods;
  final bool viewingHistorical;
  final String? selectedYear;
  final String? selectedPeriodId;
  final VoidCallback onSelectCurrent;
  final ValueChanged<String> onSelectYear;
  final ValueChanged<ComplianceReportPeriod> onSelectPeriod;
  final bool isDark;
  final Color secondary;

  Map<String, List<ComplianceReportPeriod>> get _periodsByYear {
    final Map<String, List<ComplianceReportPeriod>> grouped =
        <String, List<ComplianceReportPeriod>>{};
    for (final ComplianceReportPeriod period in periods) {
      final String year = period.year.isNotEmpty
          ? period.year
          : period.reportDate.substring(0, 4);
      grouped.putIfAbsent(year, () => <ComplianceReportPeriod>[]).add(period);
    }
    for (final List<ComplianceReportPeriod> list in grouped.values) {
      list.sort((ComplianceReportPeriod a, ComplianceReportPeriod b) {
        return b.reportDate.compareTo(a.reportDate);
      });
    }
    return grouped;
  }

  List<String> get _years => _periodsByYear.keys.toList()
    ..sort((String a, String b) => b.compareTo(a));

  ComplianceReportPeriod? get _selectedPeriod {
    if (selectedPeriodId == null) return null;
    for (final ComplianceReportPeriod period in periods) {
      if (period.id == selectedPeriodId) return period;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    final Map<String, List<ComplianceReportPeriod>> grouped = _periodsByYear;
    final List<String> years = _years;
    final String? activeYear =
        viewingHistorical ? (selectedYear ?? years.first) : null;
    final List<ComplianceReportPeriod> quarterOptions = activeYear == null
        ? const <ComplianceReportPeriod>[]
        : grouped[activeYear] ?? const <ComplianceReportPeriod>[];
    final ComplianceReportPeriod? selectedPeriod = _selectedPeriod;

    return ComplianceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPORT PERIOD',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: isDark ? 12 : 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse current and previous Shariah compliance filings',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: isDark ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF14532D).withOpacity(0.35)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF16A34A).withOpacity(0.45)
                        : const Color(0xFF86EFAC),
                  ),
                ),
                child: Text(
                  '${periods.length} historical reports',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PeriodChip(
                label: 'Current Report',
                selected: !viewingHistorical,
                isDark: isDark,
                emphasized: true,
                onTap: onSelectCurrent,
              ),
              ...years.map(
                (String year) => _PeriodChip(
                  label: '$year (${grouped[year]?.length ?? 0})',
                  selected: viewingHistorical && activeYear == year,
                  isDark: isDark,
                  onTap: () => onSelectYear(year),
                ),
              ),
            ],
          ),
          if (viewingHistorical && quarterOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quarterOptions
                  .map(
                    (ComplianceReportPeriod period) => _PeriodChip(
                      label: period.shortLabel,
                      selected: selectedPeriodId == period.id,
                      isDark: isDark,
                      compact: true,
                      onTap: () => onSelectPeriod(period),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: viewingHistorical && selectedPeriod != null
                ? _SummaryLine(
                    isDark: isDark,
                    secondary: secondary,
                    title: 'Viewing: ${selectedPeriod.label}',
                    subtitle: _coverageLine(selectedPeriod),
                    note:
                        'Historical report — some fields may not be available for this period.',
                  )
                : _SummaryLine(
                    isDark: isDark,
                    secondary: secondary,
                    title: 'Viewing: Current Report (latest filing)',
                    subtitle: 'Switch to a year above to explore previous filings.',
                  ),
          ),
        ],
      ),
    );
  }

  String _coverageLine(ComplianceReportPeriod period) {
    final String start =
        ComplianceHistoryFormatters.formatDate(period.startDate);
    final String end = ComplianceHistoryFormatters.formatDate(period.endDate);
    if (start != '-' && end != '-') {
      return 'Coverage: $start – $end';
    }
    return 'Report date: ${ComplianceHistoryFormatters.formatDate(period.reportDate)}';
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.isDark,
    required this.secondary,
    required this.title,
    required this.subtitle,
    this.note,
  });

  final bool isDark;
  final Color secondary;
  final String title;
  final String subtitle;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 12,
            color: secondary,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note!,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
            ),
          ),
        ],
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.emphasized = false,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color activeBg = isDark
        ? const Color(0xFF14532D)
        : const Color(0xFF16A34A);
    final Color idleBg =
        isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);
    final Color activeFg = Colors.white;
    final Color idleFg =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : (emphasized ? 14 : 12),
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: selected ? activeBg : idleBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? activeBg
                  : (isDark
                      ? const Color(0xFF404040)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: compact ? 12 : 13,
              fontWeight: selected || emphasized ? FontWeight.w600 : FontWeight.w500,
              color: selected ? activeFg : idleFg,
            ),
          ),
        ),
      ),
    );
  }
}
