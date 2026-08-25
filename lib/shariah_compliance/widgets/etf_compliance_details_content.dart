import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/etfs_data.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/models/etf_compliance_report.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_formatters.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_charts.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_ratio_bar.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class EtfComplianceDetailsContent extends StatefulWidget {
  const EtfComplianceDetailsContent({
    super.key,
    required this.report,
    required this.tickerSymbol,
    this.etfData,
    this.ticker,
    this.onOpenEtfDetail,
  });

  final EtfComplianceReport report;
  final String tickerSymbol;
  final EtfsData? etfData;
  final TickerModel? ticker;
  final VoidCallback? onOpenEtfDetail;

  @override
  State<EtfComplianceDetailsContent> createState() =>
      _EtfComplianceDetailsContentState();
}

class _EtfComplianceDetailsContentState extends State<EtfComplianceDetailsContent> {
  final Map<String, bool> _showPercentBySection = <String, bool>{
    'revenue': true,
    'securities': true,
    'debt': true,
  };

  bool _sectionShowPercent(String sectionKey) =>
      _showPercentBySection[sectionKey] ?? true;

  void _setSectionShowPercent(String sectionKey, bool showPercent) {
    setState(() => _showPercentBySection[sectionKey] = showPercent);
  }

  bool _isFailStatus(String status) {
    final String normalized = status.toUpperCase();
    return normalized.contains('FAIL') ||
        normalized.contains('NON') ||
        normalized.contains('NOT');
  }

  String _formatReasonText(String text) {
    if (text.isEmpty) return text;

    return text
        .replaceAll('NON_COMPLIANT', 'Not Halal')
        .replaceAll('NOT_HALAL', 'Not Halal')
        .replaceAll('COMPLIANT', 'Halal')
        .replaceAll('QUESTIONABLE', 'Doubtful');
  }

  String _fmtPrice(num? value) =>
      value != null ? '\$${value.toStringAsFixed(2)}' : '--';

  String _fmtPercent(num? value) =>
      value != null ? '${value.toStringAsFixed(2)}%' : '--';

  String _denominatorLabel() => ComplianceFormatters.compactMoney(
        widget.report.marketValue > 0
            ? widget.report.marketValue
            : widget.report.aum,
        fromOnes: true,
      );

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = HomeUi.muted(isDark);
    final EtfComplianceReport report = widget.report;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEtfHeaderRow(isDark, report),
            const SizedBox(height: 16),
            _buildSnapshotAndRevenueRow(
              report: report,
              secondary: secondary,
              isDark: isDark,
              maxWidth: constraints.maxWidth,
            ),
            const SizedBox(height: 16),
            _buildOverviewSection(report, isDark),
            const SizedBox(height: 16),
            _buildScreeningSection(report, isDark, secondary),
          ],
        );
      },
    );
  }

  Widget _headerKv(
    bool isDark,
    String label,
    String value, {
    int maxLines = 1,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: HomeUi.tableCellEmphasis(isDark).copyWith(
                fontSize: 13,
                color: valueColor ?? HomeUi.title(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineComplianceBadge(String status) {
    return ComplianceStatusBadge(
      label: status,
      compact: true,
      fontSize: 10,
    );
  }

  Widget _buildEtfHeaderRow(bool isDark, EtfComplianceReport report) {
    final EtfsData? etf = widget.etfData;
    final String name = report.name.isNotEmpty
        ? report.name
        : widget.ticker?.companyName ??
            widget.ticker?.name ??
            widget.tickerSymbol;
    final String logo = widget.ticker?.logo ?? '';
    final String ticker = widget.tickerSymbol.toUpperCase();
    final String status = report.complianceStatus;
    final num? change =
        etf?.change1DPercent ?? etf?.priceChange1DPercent;
    final bool isUp = change != null && change >= 0;

    return Container(
      decoration: HomeUi.cardDecoration(isDark),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: HomeUi.elevatedBg(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: HomeUi.borderLight(isDark)),
                          ),
                          child: showLogo(
                            ticker,
                            logo,
                            sideWidth: 24,
                            name: ticker,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : ticker,
                                style: HomeUi.sectionTitle(isDark)
                                    .copyWith(fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    ticker,
                                    style: HomeUi.overline(isDark).copyWith(
                                      letterSpacing: 1.2,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (status.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    _inlineComplianceBadge(status),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.onOpenEtfDetail != null) ...[
                          const SizedBox(width: 8),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: widget.onOpenEtfDetail,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HomeUi.brandIcon(
                                    icon: Icons.open_in_new_rounded,
                                    size: HomeUi.iconXs,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Full Analysis',
                                    style: HomeUi.control(isDark, active: true)
                                        .copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: HomeUi.accent(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT PRICE',
                                style: HomeUi.overline(isDark).copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fmtPrice(etf?.currentPrice),
                                style: HomeUi.display(isDark).copyWith(
                                  fontSize: 24,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            change == null
                                ? '--'
                                : '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                            style: HomeUi.tableNumeric(
                              isDark,
                              positiveValue: change == null ? null : isUp,
                            ).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _headerKv(
                      isDark,
                      'AUM',
                      etf?.aum != null
                          ? Constants.getShortenedMarketCapV2(etf!.aum)
                          : _denominatorLabel(),
                    ),
                    _headerKv(
                      isDark,
                      'Volume',
                      etf?.volume != null
                          ? '${((etf!.volume!) / 1000000).toStringAsFixed(1)}M'
                          : '--',
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: HomeUi.borderLight(isDark),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.account_balance_outlined,
                      title: 'Fund Information',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDark,
                      'Asset Class',
                      report.assetClass.isNotEmpty
                          ? report.assetClass
                          : etf?.assetClass ?? '--',
                      maxLines: 2,
                    ),
                    _headerKv(
                      isDark,
                      'Segment',
                      report.investmentSegment.isNotEmpty
                          ? report.investmentSegment
                          : etf?.investmentSegment ?? '--',
                      maxLines: 2,
                    ),
                    _headerKv(
                      isDark,
                      'ETF Type',
                      report.etfType.isNotEmpty ? report.etfType : '--',
                    ),
                    _headerKv(
                      isDark,
                      'Holdings',
                      report.numberOfHoldings > 0
                          ? report.numberOfHoldings.toString()
                          : etf?.numberOfHoldings?.toString() ?? '--',
                    ),
                    _headerKv(
                      isDark,
                      'Market',
                      report.market.isNotEmpty
                          ? report.market
                          : etf?.domicile ?? '--',
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: HomeUi.borderLight(isDark),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.auto_graph_outlined,
                      title: 'Key Metrics',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDark,
                      'Expense Ratio',
                      etf?.expenseRatio != null
                          ? _fmtPercent(etf!.expenseRatio)
                          : '--',
                    ),
                    _headerKv(isDark, 'NAV', _fmtPrice(etf?.nav)),
                    _headerKv(isDark, '52W High', _fmtPrice(etf?.d52WeekHigh)),
                    _headerKv(isDark, '52W Low', _fmtPrice(etf?.d52WeekLow)),
                    _headerKv(
                      isDark,
                      'Leveraged ETF',
                      report.isLeveraged == '1' ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotAndRevenueRow({
    required EtfComplianceReport report,
    required Color secondary,
    required bool isDark,
    required double maxWidth,
  }) {
    final bool sideBySide = maxWidth >= 980;
    final Widget snapshot = _buildComplianceSnapshotCard(
      report,
      isDark,
      fillHeight: sideBySide,
    );
    final Widget revenue = _buildRevenueBreakdownCard(
      report,
      secondary,
      isDark,
      fillHeight: sideBySide,
    );

    if (!sideBySide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          snapshot,
          const SizedBox(height: 16),
          revenue,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: snapshot),
          const SizedBox(width: 16),
          Expanded(child: revenue),
        ],
      ),
    );
  }

  Widget _buildComplianceSnapshotCard(
    EtfComplianceReport report,
    bool isDark, {
    bool fillHeight = false,
  }) {
    final Color ourAccent =
        ComplianceFormatters.statusColor(report.complianceStatus);
    final Color cbaAccent = ComplianceFormatters.statusColor(report.cbaStatus);
    final Color ourSoft = _isFailStatus(report.complianceStatus)
        ? HomeUi.negativeSoft(isDark)
        : HomeUi.positiveSoft(isDark);
    final Color cbaSoft = _isFailStatus(report.cbaStatus)
        ? HomeUi.negativeSoft(isDark)
        : HomeUi.positiveSoft(isDark);

    return ComplianceSectionCard(
      fillHeight: fillHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.verified_outlined,
            title: 'Compliance Snapshot',
            subtitleText: 'Current ETF screening status',
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _snapshotTile(
                    isDark: isDark,
                    label: 'Our Status',
                    value: ComplianceFormatters.statusLabel(
                      report.complianceStatus,
                    ),
                    accent: ourAccent,
                    soft: ourSoft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _snapshotTile(
                    isDark: isDark,
                    label: 'CBA Status',
                    value: ComplianceFormatters.statusLabel(report.cbaStatus),
                    accent: cbaAccent,
                    soft: cbaSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pillarChip(
                isDark,
                'Business',
                report.revenueBreakdownStatus,
              ),
              _pillarChip(
                isDark,
                'IB Securities',
                report.securitiesAndAssetsStatus,
              ),
              _pillarChip(isDark, 'IB Debt', report.debtStatus),
            ],
          ),
          if (fillHeight) ...<Widget>[
            const Spacer(),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: HomeUi.elevatedBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: HomeUi.iconFillGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Viewing: Current ETF report',
                        style: HomeUi.control(isDark, active: true).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.shariahReason.isNotEmpty
                            ? _formatReasonText(report.shariahReason)
                            : 'Live compliance view for this ETF filing.',
                        style: HomeUi.subtitle(isDark).copyWith(
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapshotTile({
    required bool isDark,
    required String label,
    required String value,
    required Color accent,
    required Color soft,
  }) {
    final Color surface = isDark
        ? Color.alphaBlend(soft.withValues(alpha: 0.18), HomeUi.elevatedBg(true))
        : Color.alphaBlend(soft.withValues(alpha: 0.65), Colors.white);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: HomeUi.overline(isDark).copyWith(
              fontSize: 10,
              letterSpacing: 0.85,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
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
                    fontSize: 13,
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

  Widget _pillarChip(bool isDark, String label, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 11.5),
          ),
          const SizedBox(width: 8),
          ComplianceStatusBadge(
            label: status,
            compact: true,
            fontSize: 10.5,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownCard(
    EtfComplianceReport report,
    Color secondary,
    bool isDark, {
    bool fillHeight = false,
  }) {
    final bool showPercent = _sectionShowPercent('revenue');
    final double halalShare = report.totalHalalRatio.toDouble().clamp(0, 100);
    final double notHalalShare =
        report.totalNotHalalRatio.toDouble().clamp(0, 100);
    final double doubtfulShare =
        report.totalDoubtfulRatio.toDouble().clamp(0, 100);
    final double totalShare = (halalShare + notHalalShare + doubtfulShare) <= 0
        ? 1
        : (halalShare + notHalalShare + doubtfulShare);

    String moneyOrPercent(num percent, num amount) {
      if (showPercent) return ComplianceFormatters.percent(percent);
      return ComplianceFormatters.compactMoney(amount, fromOnes: true);
    }

    return ComplianceSectionCard(
      fillHeight: fillHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: HomeUi.tableToolbarHeader(
                  isDark,
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Revenue Breakdown',
                  subtitleText: 'Halal vs non-compliant mix',
                ),
              ),
              const SizedBox(width: 10),
              _buildPercentCurrencyToggle(
                secondary,
                isDark,
                'revenue',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Color.alphaBlend(
                      HomeUi.accent(true).withValues(alpha: 0.06),
                      HomeUi.elevatedBg(true),
                    )
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(HomeUi.radiusLg),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _revenueMixStat(
                        isDark: isDark,
                        label: 'Halal',
                        value: ComplianceFormatters.percent(
                          report.totalHalalRatio,
                        ),
                        color: ComplianceFormatters.halalColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: HomeUi.borderLight(isDark),
                    ),
                    Expanded(
                      child: _revenueMixStat(
                        isDark: isDark,
                        label: 'Not Halal',
                        value: ComplianceFormatters.percent(
                          report.totalNotHalalRatio,
                        ),
                        color: ComplianceFormatters.notHalalColor,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: (halalShare / totalShare * 1000)
                              .round()
                              .clamp(1, 1000),
                          child: ColoredBox(
                            color: ComplianceFormatters.halalColor,
                          ),
                        ),
                        if (doubtfulShare > 0)
                          Expanded(
                            flex: (doubtfulShare / totalShare * 1000)
                                .round()
                                .clamp(1, 1000),
                            child: ColoredBox(
                              color: ComplianceFormatters.doubtfulColor,
                            ),
                          ),
                        Expanded(
                          flex: (notHalalShare / totalShare * 1000)
                              .round()
                              .clamp(1, 1000),
                          child: ColoredBox(
                            color: ComplianceFormatters.notHalalColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _aggregateRevenuePanel(
            isDark: isDark,
            title: 'Halal Revenue',
            value: moneyOrPercent(
              report.totalHalalRatio,
              report.totalHalalRevenue,
            ),
            accent: ComplianceFormatters.halalColor,
            soft: HomeUi.positiveSoft(isDark),
          ),
          const SizedBox(height: 8),
          _aggregateRevenuePanel(
            isDark: isDark,
            title: 'Doubtful Revenue',
            value: moneyOrPercent(
              report.totalDoubtfulRatio,
              report.totalDoubtfulRevenue,
            ),
            accent: ComplianceFormatters.doubtfulColor,
            soft: isDark ? const Color(0xFF3A2A10) : const Color(0xFFFFF7ED),
          ),
          const SizedBox(height: 8),
          _aggregateRevenuePanel(
            isDark: isDark,
            title: 'Not Halal Revenue',
            value: moneyOrPercent(
              report.totalNotHalalRatio,
              report.totalNotHalalRevenue,
            ),
            accent: ComplianceFormatters.notHalalColor,
            soft: HomeUi.negativeSoft(isDark),
          ),
          if (fillHeight) const Spacer(),
        ],
      ),
    );
  }

  Widget _revenueMixStat({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: HomeUi.overline(isDark).copyWith(
            fontSize: 10,
            letterSpacing: 0.85,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: HomeUi.control(isDark, active: true).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _aggregateRevenuePanel({
    required bool isDark,
    required String title,
    required String value,
    required Color accent,
    required Color soft,
  }) {
    final Color surface = isDark
        ? Color.alphaBlend(soft.withValues(alpha: 0.18), HomeUi.elevatedBg(true))
        : Color.alphaBlend(soft.withValues(alpha: 0.7), Colors.white);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: HomeUi.cardTitle(isDark).copyWith(fontSize: 13),
            ),
          ),
          Text(
            value,
            style: HomeUi.tableCellEmphasis(isDark).copyWith(
              fontSize: 13,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(EtfComplianceReport report, bool isDark) {
    return ComplianceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.verified_outlined,
            title: 'Screening Overview',
            subtitleText: 'Our analysis versus CBA screening',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final List<Widget> cards = <Widget>[
                _comparisonStatCard(
                  isDark: isDark,
                  label: 'Frameworks',
                  value: '2 models',
                  accent: HomeUi.accent(isDark),
                ),
                _comparisonStatCard(
                  isDark: isDark,
                  label: 'Our Status',
                  value: ComplianceFormatters.statusLabel(
                    report.complianceStatus,
                  ),
                  accent: ComplianceFormatters.statusColor(
                    report.complianceStatus,
                  ),
                ),
                _comparisonStatCard(
                  isDark: isDark,
                  label: 'CBA Status',
                  value: ComplianceFormatters.statusLabel(report.cbaStatus),
                  accent: ComplianceFormatters.statusColor(report.cbaStatus),
                ),
              ];
              final double available =
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 900;
              final double desiredWidth =
                  ((available - 24) / 3).clamp(170.0, 220.0);

              return Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map(
                        (Widget card) =>
                            SizedBox(width: desiredWidth, child: card),
                      )
                      .toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double available =
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 900;
              final bool sideBySide = available >= 560;
              final Color ourAccent = ComplianceFormatters.statusColor(
                report.complianceStatus,
              );
              final Color cbaAccent =
                  ComplianceFormatters.statusColor(report.cbaStatus);
              final Color ourTone = _isFailStatus(report.complianceStatus)
                  ? HomeUi.negativeSoft(isDark)
                  : HomeUi.positiveSoft(isDark);
              final Color cbaTone = _isFailStatus(report.cbaStatus)
                  ? HomeUi.negativeSoft(isDark)
                  : HomeUi.positiveSoft(isDark);

              final Widget ourPanel = _methodologyPanel(
                title: 'Our Analysis',
                status: report.complianceStatus,
                isDark: isDark,
                accent: ourAccent,
                tone: ourTone,
                stretch: sideBySide,
                denominatorLabel: 'Denominator',
                denominatorValue: 'Market Value',
                metricLabel: 'Market Value',
                metricValue: _denominatorLabel(),
                structuredLines: <_PanelLine>[
                  const _PanelLine(
                    label: 'Denominator',
                    value: 'Market Value',
                  ),
                  _PanelLine(
                    label: 'Market Value',
                    value: _denominatorLabel(),
                  ),
                  _PanelLine(
                    label: 'Halal',
                    value: ComplianceFormatters.percent(
                      report.totalHalalRatio,
                    ),
                    valueColor: ComplianceFormatters.halalColor,
                  ),
                  _PanelLine(
                    label: 'Not Halal',
                    value: ComplianceFormatters.percent(
                      report.totalNotHalalRatio,
                    ),
                    valueColor: ComplianceFormatters.notHalalColor,
                  ),
                ],
              );
              final Widget cbaPanel = _methodologyPanel(
                title: 'CBA Screening',
                status: report.cbaStatus,
                isDark: isDark,
                accent: cbaAccent,
                tone: cbaTone,
                stretch: sideBySide,
                denominatorLabel: 'Screening Model',
                denominatorValue: 'CBA Framework',
                metricLabel: 'Overall CBA',
                metricValue: ComplianceFormatters.statusLabel(
                  report.cbaStatus,
                ),
                structuredLines: <_PanelLine>[
                  _PanelLine(
                    label: 'Business Activity',
                    value: ComplianceFormatters.statusLabel(
                      report.revenueBreakdownStatus,
                    ),
                    valueColor: _isFailStatus(report.revenueBreakdownStatus)
                        ? ComplianceFormatters.notHalalColor
                        : ComplianceFormatters.halalColor,
                  ),
                  _PanelLine(
                    label: 'IB Securities',
                    value: ComplianceFormatters.statusLabel(
                      report.securitiesAndAssetsStatus,
                    ),
                    valueColor: _isFailStatus(report.securitiesAndAssetsStatus)
                        ? ComplianceFormatters.notHalalColor
                        : ComplianceFormatters.halalColor,
                  ),
                  _PanelLine(
                    label: 'IB Debt',
                    value: ComplianceFormatters.statusLabel(
                      report.debtStatus,
                    ),
                    valueColor: _isFailStatus(report.debtStatus)
                        ? ComplianceFormatters.notHalalColor
                        : ComplianceFormatters.halalColor,
                  ),
                ],
              );

              if (!sideBySide) {
                return Column(
                  children: <Widget>[
                    ourPanel,
                    const SizedBox(height: 12),
                    cbaPanel,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: ourPanel),
                    const SizedBox(width: 12),
                    Expanded(child: cbaPanel),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _comparisonStatCard({
    required bool isDark,
    required String label,
    required String value,
    required Color accent,
  }) {
    final Color surface = isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.10), HomeUi.cardBg(true))
        : Color.alphaBlend(accent.withValues(alpha: 0.08), Colors.white);
    return Container(
      constraints: const BoxConstraints(minWidth: 156),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 12,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: HomeUi.overline(isDark).copyWith(
                  fontSize: 10,
                  letterSpacing: 0.85,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                    fontSize: 13,
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

  Widget _methodologyPanel({
    required String title,
    required String status,
    required Color accent,
    required bool isDark,
    required Color tone,
    required String denominatorLabel,
    required String denominatorValue,
    required String metricLabel,
    required String metricValue,
    required List<_PanelLine> structuredLines,
    bool stretch = false,
  }) {
    final Color bgColor = isDark
        ? Color.alphaBlend(tone.withValues(alpha: 0.12), HomeUi.elevatedBg(true))
        : Color.alphaBlend(tone.withValues(alpha: 0.55), Colors.white);

    return Container(
      constraints: const BoxConstraints(minWidth: 280),
      height: stretch ? double.infinity : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(color: accent.withValues(alpha: isDark ? 0.22 : 0.18)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: HomeUi.cardTitle(isDark).copyWith(fontSize: 15),
                  ),
                ),
                ComplianceStatusBadge(
                  label: status,
                  compact: true,
                  fontSize: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  denominatorLabel,
                  style: HomeUi.overline(isDark).copyWith(
                    fontSize: 10,
                    letterSpacing: 0.85,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  denominatorValue,
                  style: HomeUi.tableCellEmphasis(isDark).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  metricLabel,
                  style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  metricValue,
                  style: HomeUi.cardTitle(isDark).copyWith(
                    fontSize: 18,
                    color: HomeUi.title(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (stretch)
            Expanded(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(isDark)
                      .withValues(alpha: isDark ? 0.55 : 0.7),
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  border: Border.all(
                    color: HomeUi.borderLight(isDark).withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: structuredLines.map(_panelDataLine).toList(),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:
                    HomeUi.cardBg(isDark).withValues(alpha: isDark ? 0.55 : 0.7),
                borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                border: Border.all(
                  color: HomeUi.borderLight(isDark).withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: structuredLines.map(_panelDataLine).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panelDataLine(_PanelLine line) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.label,
              style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
            ),
          ),
          Text(
            line.value,
            style: HomeUi.tableCellEmphasis(isDark).copyWith(
              fontSize: 13,
              color: line.valueColor ?? HomeUi.title(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningSection(
    EtfComplianceReport report,
    bool isDark,
    Color secondary,
  ) {
    return ComplianceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.fact_check_outlined,
            title: 'Screening',
            subtitleText: 'Business activity, securities, and debt',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double available =
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 900;
              final bool useEqualHeightRow = available >= 720;

              final List<Widget> columns = <Widget>[
                _screeningColumn(
                  title: 'Business Activity',
                  status: report.revenueBreakdownStatus,
                  isDark: isDark,
                  secondary: secondary,
                  stretchContent: useEqualHeightRow,
                  onViewCalculation: () => _showBusinessCalculationDialog(
                    report,
                    isDark,
                  ),
                  child: _buildBusinessContent(report, isDark),
                ),
                _screeningColumn(
                  title: 'IB Securities',
                  status: report.securitiesAndAssetsStatus,
                  isDark: isDark,
                  secondary: secondary,
                  stretchContent: useEqualHeightRow,
                  toggleSectionKey: 'securities',
                  child: _buildSecuritiesContent(report, isDark),
                ),
                _screeningColumn(
                  title: 'IB Debt',
                  status: report.debtStatus,
                  isDark: isDark,
                  secondary: secondary,
                  stretchContent: useEqualHeightRow,
                  toggleSectionKey: 'debt',
                  child: _buildDebtContent(report, isDark),
                ),
              ];

              if (useEqualHeightRow) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int i = 0; i < columns.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: columns[i]),
                      ],
                    ],
                  ),
                );
              }

              final double columnWidth =
                  ((available - 24) / 3).clamp(220.0, available);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: columns
                    .map(
                      (Widget column) => SizedBox(
                        width: columnWidth,
                        child: column,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _screeningColumn({
    required String title,
    required String status,
    required bool isDark,
    required Color secondary,
    required Widget child,
    String? toggleSectionKey,
    VoidCallback? onViewCalculation,
    bool stretchContent = false,
  }) {
    final Color accent = ComplianceFormatters.statusColor(status);
    final Color surface = isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.08), HomeUi.cardBg(true))
        : Color.alphaBlend(accent.withValues(alpha: 0.05), Colors.white);

    final Widget contentBox = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: child,
    );

    return Container(
      height: stretchContent ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: HomeUi.cardTitle(isDark).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ComplianceStatusBadge(
                        label: status,
                        compact: true,
                        fontSize: 11.5,
                      ),
                    ],
                  ),
                ),
                if (toggleSectionKey != null) ...[
                  const SizedBox(width: 8),
                  _buildPercentCurrencyToggle(
                    secondary,
                    isDark,
                    toggleSectionKey,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (stretchContent)
            Expanded(child: contentBox)
          else
            contentBox,
          if (onViewCalculation != null) ...[
            const SizedBox(height: 12),
            ComplianceViewCalculationButton(
              isDark: isDark,
              onTap: onViewCalculation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPercentCurrencyToggle(
    Color secondary,
    bool isDark,
    String sectionKey,
  ) {
    final bool showPercent = _sectionShowPercent(sectionKey);
    return SizedBox(
      width: 76,
      height: 30,
      child: HomeUi.segmentedControlLight(
        dark: isDark,
        height: 30,
        options: const <String>['%', '\$'],
        selectedIndex: showPercent ? 0 : 1,
        onChanged: (int index) =>
            _setSectionShowPercent(sectionKey, index == 0),
      ),
    );
  }

  Widget _buildBusinessContent(EtfComplianceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ComplianceDonutChart(
            halal: report.totalHalalRatio.toDouble(),
            doubtful: report.totalDoubtfulRatio.toDouble(),
            notHalal: report.totalNotHalalRatio.toDouble(),
            halalColor: ComplianceFormatters.halalColor,
            doubtfulColor: ComplianceFormatters.doubtfulColor,
            notHalalColor: ComplianceFormatters.notHalalColor,
            size: isDark ? 144 : 152,
            bottomSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: HomeUi.negativeSoft(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(
              color: ComplianceFormatters.notHalalColor.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Non-halal activity',
                  style:
                      HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
                ),
              ),
              Text(
                ComplianceFormatters.percent(report.impermissibleRatio > 0
                    ? report.impermissibleRatio
                    : report.totalNotHalalRatio),
                style: HomeUi.tableCellEmphasis(isDark).copyWith(
                  fontSize: 13,
                  color: ComplianceFormatters.notHalalColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _legendRow(
          'Halal Sales & Income',
          report.totalHalalRatio,
          ComplianceFormatters.halalColor,
          isDark,
        ),
        _legendRow(
          'Doubtful Sales & Income',
          report.totalDoubtfulRatio,
          ComplianceFormatters.doubtfulColor,
          isDark,
        ),
        _legendRow(
          'Non Halal Sales & Income',
          report.totalNotHalalRatio,
          ComplianceFormatters.notHalalColor,
          isDark,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: HomeUi.negativeSoft(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(
              color: ComplianceFormatters.notHalalColor.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            'Not Halal Business Activity Percentage must not exceed 5% of Aggregate Revenue of ETF.',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 12,
              height: 1.35,
              color:
                  isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendRow(String label, num value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusMd),
          border: Border.all(color: HomeUi.borderLight(isDark)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  color: HomeUi.title(isDark),
                ),
              ),
            ),
            Text(
              ComplianceFormatters.percent(value),
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: HomeUi.title(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritiesContent(EtfComplianceReport report, bool isDark) {
    final bool showPercent = _sectionShowPercent('securities');
    final bool pass = !_isFailStatus(report.securitiesAndAssetsStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _complianceRatioBar(
          value: report.totalIbSecAssetRatio.toDouble(),
          threshold: 30,
          pass: pass,
          numeratorLabel: 'Interest-bearing securities and assets',
          numeratorValue: showPercent
              ? ComplianceFormatters.percent(report.totalIbSecAssetRatio)
              : ComplianceFormatters.compactMoney(
                  report.totalIbSecAssetRevenue,
                  fromOnes: true,
                ),
          denominatorValue: showPercent
              ? '100%'
              : _denominatorLabel(),
          denominatorLabel: 'Market Value',
        ),
      ],
    );
  }

  Widget _buildDebtContent(EtfComplianceReport report, bool isDark) {
    final bool showPercent = _sectionShowPercent('debt');
    final bool pass = !_isFailStatus(report.debtStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _complianceRatioBar(
          value: report.totalDebtRatio.toDouble(),
          threshold: 30,
          pass: pass,
          numeratorLabel: 'Total Interest-bearing debt',
          numeratorValue: showPercent
              ? ComplianceFormatters.percent(report.totalDebtRatio)
              : ComplianceFormatters.compactMoney(
                  report.totalIbDebtRevenue,
                  fromOnes: true,
                ),
          denominatorValue: showPercent ? '100%' : _denominatorLabel(),
          denominatorLabel: 'Market Value',
        ),
      ],
    );
  }

  Widget _complianceRatioBar({
    required double value,
    required double threshold,
    required bool pass,
    required String numeratorLabel,
    required String numeratorValue,
    required String denominatorValue,
    required String denominatorLabel,
  }) {
    return ComplianceRatioBar(
      value: value,
      threshold: threshold,
      pass: pass,
      numeratorLabel: numeratorLabel,
      numeratorValue: numeratorValue,
      denominatorValue: denominatorValue,
      denominatorLabel: denominatorLabel,
    );
  }

  void _showBusinessCalculationDialog(EtfComplianceReport report, bool isDark) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _EtfCalculationDialog(
        report: report,
        isDark: isDark,
      ),
    );
  }
}

class _EtfCalculationDialog extends StatelessWidget {
  const _EtfCalculationDialog({
    required this.report,
    required this.isDark,
  });

  final EtfComplianceReport report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final String status = report.revenueBreakdownStatus;
    final Color accent = ComplianceFormatters.statusColor(status);
    final num numeratorAmount =
        report.totalNotHalalRevenue + report.totalDoubtfulRevenue;
    final String resultPercent = ComplianceFormatters.percent(
      report.impermissibleRatio > 0
          ? report.impermissibleRatio
          : report.totalNotHalalRatio + report.totalDoubtfulRatio,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: HomeUi.cardBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      accent.withValues(alpha: isDark ? 0.08 : 0.05),
                      HomeUi.cardBg(isDark),
                    ),
                    border: Border(
                      bottom: BorderSide(color: HomeUi.borderLight(isDark)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                        ),
                        child: Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 20,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Not Halal Business Activity Percentage of ETF',
                              style: HomeUi.sectionTitle(isDark).copyWith(
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ComplianceStatusBadge(
                              label: status,
                              compact: true,
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius:
                              BorderRadius.circular(HomeUi.radiusPill),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: HomeUi.elevatedBg(isDark),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: HomeUi.borderLight(isDark),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: HomeUi.muted(isDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionCard(
                          title: 'Breakdown',
                          children: <Widget>[
                            _breakdownRow(
                              'Halal Sales & Income',
                              ComplianceFormatters.percent(
                                report.totalHalalRatio,
                              ),
                            ),
                            _breakdownRow(
                              'Doubtful Sales & Income',
                              ComplianceFormatters.percent(
                                report.totalDoubtfulRatio,
                              ),
                            ),
                            _breakdownRow(
                              'Non Halal Sales & Income',
                              ComplianceFormatters.percent(
                                report.totalNotHalalRatio,
                              ),
                            ),
                            _breakdownRow(
                              'Aggregate Revenue of ETF',
                              '100%',
                              emphasized: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _formulaPanel(
                          formulaLabel:
                              'Not Halal Business Activity Percentage of ETF =',
                          numerator:
                              '( Aggregate Non Halal Sales & Income of ETF + Aggregate Doubtful Sales & Income of ETF )',
                          denominator: '( Aggregate Revenue of ETF )',
                          result:
                              '${ComplianceFormatters.compactMoney(numeratorAmount, fromOnes: true)} / ${ComplianceFormatters.compactMoney(report.etfTotalRevenue, fromOnes: true)} = $resultPercent',
                          detail:
                              '${ComplianceFormatters.compactMoney(report.totalNotHalalRevenue, fromOnes: true)} + ${ComplianceFormatters.compactMoney(report.totalDoubtfulRevenue, fromOnes: true)}',
                          threshold: 'Threshold: 5.00%',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _modalPanelDecoration() {
    return BoxDecoration(
      color: isDark
          ? Color.alphaBlend(
              Colors.white.withValues(alpha: 0.03),
              HomeUi.elevatedBg(isDark),
            )
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(HomeUi.radiusLg),
      border: Border.all(
        color: isDark
            ? HomeUi.borderLight(isDark)
            : const Color(0xFFE8ECF0),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: _modalPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title.toUpperCase(),
              style: HomeUi.overline(isDark).copyWith(
                fontSize: 10,
                letterSpacing: 1.05,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (int index = 0; index < children.length; index++) ...<Widget>[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: HomeUi.borderLight(isDark).withValues(alpha: 0.75),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: children[index],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {bool emphasized = false}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: (emphasized
                    ? HomeUi.control(isDark, active: true)
                    : HomeUi.tableCellSecondary(isDark))
                .copyWith(
              fontSize: emphasized ? 13.5 : 13,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: HomeUi.tableCellEmphasis(isDark).copyWith(
            fontSize: emphasized ? 14.5 : 14,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _formulaPanel({
    required String formulaLabel,
    required String numerator,
    required String denominator,
    required String result,
    required String threshold,
    String? detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _modalPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            formulaLabel,
            style: HomeUi.control(isDark, active: true).copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numerator,
                  style: HomeUi.tableCellSecondary(isDark).copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    height: 1,
                    color: HomeUi.borderLight(isDark).withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  denominator,
                  style: HomeUi.tableCellSecondary(isDark).copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(
                color: HomeUi.accent(isDark).withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result,
                  style: HomeUi.tableCellEmphasis(isDark).copyWith(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: HomeUi.subtitle(isDark).copyWith(fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              border: Border.all(
                color: HomeUi.borderLight(isDark),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.tune_rounded,
                  size: 13,
                  color: HomeUi.muted(isDark),
                ),
                const SizedBox(width: 6),
                Text(
                  threshold,
                  style: HomeUi.subtitle(isDark).copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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

class _PanelLine {
  const _PanelLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}
