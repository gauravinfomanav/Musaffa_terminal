import 'package:flutter/material.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report_period.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_history_formatters.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

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
    this.compact = false,
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
  final bool compact;

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

    final List<Widget> selectorContent = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PeriodTabChip(
            label: 'Current Report',
            selected: !viewingHistorical,
            isDark: isDark,
            onTap: onSelectCurrent,
            compact: compact,
          ),
          ...years.map(
            (String year) => _PeriodTabChip(
              label: '$year (${grouped[year]?.length ?? 0})',
              selected: viewingHistorical && activeYear == year,
              isDark: isDark,
              onTap: () => onSelectYear(year),
              compact: compact,
            ),
          ),
        ],
      ),
      if (viewingHistorical && quarterOptions.isNotEmpty) ...[
        SizedBox(height: compact ? 12 : 14),
        Text(
          'Available filings',
          style: HomeUi.overline(isDark).copyWith(
            fontSize: 10.5,
            letterSpacing: 0.9,
            color: secondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quarterOptions
              .map(
                (ComplianceReportPeriod period) => _PeriodTabChip(
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
    ];

    return ComplianceSectionCard(
      fillHeight: compact,
      padding: EdgeInsets.all(compact ? 14 : 16),
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
                    HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.calendar_month_outlined,
                      title: 'Report Period',
                      subtitleText: compact
                          ? 'Current and archived filings'
                          : 'Browse current and previous Shariah compliance filings',
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final bool stackTiles = constraints.maxWidth < 340;
                        final List<Widget> tiles = <Widget>[
                          _PeriodInfoTile(
                            isDark: isDark,
                            eyebrow: 'Active View',
                            value: viewingHistorical ? 'Historical' : 'Current',
                            accent: HomeUi.accent(isDark),
                            compact: compact,
                          ),
                          _PeriodInfoTile(
                            isDark: isDark,
                            eyebrow: 'Archive',
                            value: '${periods.length} reports',
                            accent: HomeUi.positive(isDark),
                            compact: compact,
                          ),
                        ];
                        if (stackTiles) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              tiles[0],
                              const SizedBox(height: 8),
                              tiles[1],
                            ],
                          );
                        }
                        return Row(
                          children: <Widget>[
                            Expanded(child: tiles[0]),
                            const SizedBox(width: 8),
                            Expanded(child: tiles[1]),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: HomeUi.positiveSoft(isDark),
                    borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                    border: Border.all(
                      color: HomeUi.positive(isDark).withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    '${periods.length} historical reports',
                    style: HomeUi.control(isDark, active: true).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HomeUi.positive(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          if (compact) ...<Widget>[
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectorContent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CompactPeriodInsight(
              isDark: isDark,
              secondary: secondary,
              viewingHistorical: viewingHistorical,
              reportsCount: periods.length,
            ),
            const SizedBox(height: 12),
            _buildPeriodSummaryCard(
              isDark: isDark,
              secondary: secondary,
              viewingHistorical: viewingHistorical,
              selectedPeriod: selectedPeriod,
              compact: compact,
            ),
            const SizedBox(height: 12),
            const Spacer(),
          ] else ...<Widget>[
            ...selectorContent,
            SizedBox(height: compact ? 12 : 16),
            _buildPeriodSummaryCard(
              isDark: isDark,
              secondary: secondary,
              viewingHistorical: viewingHistorical,
              selectedPeriod: selectedPeriod,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSummaryCard({
    required bool isDark,
    required Color secondary,
    required bool viewingHistorical,
    required ComplianceReportPeriod? selectedPeriod,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                HomeUi.accent(true).withValues(alpha: 0.08),
                HomeUi.cardBg(true),
              )
            : const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(
          color: HomeUi.accent(isDark).withValues(alpha: 0.14),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: compact ? 14 : 22,
            offset: Offset(0, compact ? 6 : 10),
          ),
        ],
      ),
      child: viewingHistorical && selectedPeriod != null
          ? _SummaryLine(
              isDark: isDark,
              secondary: secondary,
              title: 'Viewing: ${selectedPeriod.label}',
              subtitle: _coverageLine(selectedPeriod),
              note: compact
                  ? null
                  : 'Historical report — some fields may not be available for this period.',
              compact: compact,
            )
          : _SummaryLine(
              isDark: isDark,
              secondary: secondary,
              title: 'Viewing: Current Report (latest filing)',
              subtitle: compact
                  ? 'Pick a year above for archives.'
                  : 'Switch to a year above to explore previous filings.',
              compact: compact,
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

class _CompactPeriodInsight extends StatelessWidget {
  const _CompactPeriodInsight({
    required this.isDark,
    required this.secondary,
    required this.viewingHistorical,
    required this.reportsCount,
  });

  final bool isDark;
  final Color secondary;
  final bool viewingHistorical;
  final int reportsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                HomeUi.accent(true).withValues(alpha: 0.06),
                HomeUi.elevatedBg(true),
              )
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: HomeUi.accent(isDark).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              viewingHistorical
                  ? Icons.history_toggle_off_rounded
                  : Icons.auto_awesome_rounded,
              size: 15,
              color: HomeUi.accent(isDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  viewingHistorical ? 'Archive mode' : 'Quick archive access',
                  style: HomeUi.control(isDark, active: true).copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: HomeUi.title(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewingHistorical
                      ? 'You are exploring past filings from $reportsCount saved reports.'
                      : 'Switch years anytime to compare this filing with previous reports.',
                  style: HomeUi.subtitle(isDark).copyWith(
                    fontSize: 11.5,
                    color: secondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.isDark,
    required this.secondary,
    required this.title,
    required this.subtitle,
    this.note,
    this.compact = false,
  });


  final bool isDark;
  final Color secondary;
  final String title;
  final String subtitle;
  final String? note;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          decoration: BoxDecoration(
            gradient: HomeUi.iconFillGradient,
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: HomeUi.buttonBorder.withValues(alpha: 0.65),
            ),
          ),
          child: Icon(
            Icons.visibility_rounded,
            size: compact ? 14 : 16,
            color: Colors.white,
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: HomeUi.control(isDark, active: true).copyWith(
                  fontSize: compact ? 12.5 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: HomeUi.title(isDark),
                ),
              ),
              SizedBox(height: compact ? 4 : 5),
              Text(
                subtitle,
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: compact ? 11.5 : 12.5,
                  height: 1.4,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: HomeUi.negativeSoft(isDark),
                    borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                    border: Border.all(
                      color: HomeUi.negative(isDark).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    note!,
                    style: HomeUi.subtitle(isDark).copyWith(
                      fontSize: 11.5,
                      color: HomeUi.negative(isDark),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodInfoTile extends StatelessWidget {
  const _PeriodInfoTile({
    required this.isDark,
    required this.eyebrow,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  final bool isDark;
  final String eyebrow;
  final String value;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color surface = isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.10), HomeUi.cardBg(true))
        : Color.alphaBlend(accent.withValues(alpha: 0.08), Colors.white);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(color: accent.withValues(alpha: isDark ? 0.20 : 0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
            blurRadius: compact ? 10 : 16,
            offset: Offset(0, compact ? 4 : 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 22 : 24,
                height: compact ? 22 : 24,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: compact ? 11 : 12,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.overline(isDark).copyWith(
                    fontSize: 10,
                    letterSpacing: 0.85,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.control(isDark, active: true).copyWith(
                    fontSize: compact ? 12.5 : 13,
                    fontWeight: FontWeight.w700,
                    color: HomeUi.title(isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodTabChip extends StatefulWidget {
  const _PeriodTabChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_PeriodTabChip> createState() => _PeriodTabChipState();
}

class _PeriodTabChipState extends State<_PeriodTabChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final bool isDark = widget.isDark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 12,
              vertical: widget.compact ? 7 : 8,
            ),
            decoration: selected
                ? BoxDecoration(
                    color: HomeUi.cardBg(isDark),
                    borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                    border: Border.all(
                      color: HomeUi.accent(isDark).withValues(alpha: 0.28),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.10 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: _hovered
                        ? Color.alphaBlend(
                            HomeUi.accent(isDark).withValues(alpha: 0.04),
                            HomeUi.elevatedBg(isDark),
                          )
                        : HomeUi.elevatedBg(isDark),
                    borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                    border: Border.all(color: HomeUi.borderLight(isDark)),
                  ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: HomeUi.control(isDark, active: true).copyWith(
                fontSize: widget.compact ? 11 : 11.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? HomeUi.accent(isDark)
                    : HomeUi.body(isDark),
              ),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
