import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/etfs_data.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/models/etf_compliance_report.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_formatters.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_charts.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/constants.dart';
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

  bool _isCompliantStatus(String status) {
    final String normalized = status.toUpperCase();
    return normalized.contains('COMPLIANT') && !normalized.contains('NON');
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
    final Color primary =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A);
    final Color secondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final EtfComplianceReport report = widget.report;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEtfHeaderRow(primary, secondary, isDark, report),
        const SizedBox(height: 16),
        _buildOverviewSection(report, isDark),
        const SizedBox(height: 16),
        _buildScreeningSection(report, isDark, secondary),
      ],
    );
  }

  Widget _sectionLabel(String text, bool isDark, {double? fontSize}) {
    if (isDark) {
      return Text(
        text,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: fontSize ?? 16,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: fontSize ?? 14,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _infoCard(bool isDark, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  Widget _overviewRow(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: DashboardTextStyles.tickerSymbol.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DashboardTextStyles.tickerSymbol.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (isDark
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFF0A0A0A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineComplianceBadge(String status) {
    final bool compliant = _isCompliantStatus(status);
    final Color color =
        compliant ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        ComplianceFormatters.statusLabel(status),
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEtfHeaderRow(
    Color primary,
    Color secondary,
    bool isDark,
    EtfComplianceReport report,
  ) {
    final EtfsData? etf = widget.etfData;
    final String name = report.name.isNotEmpty
        ? report.name
        : widget.ticker?.companyName ??
            widget.ticker?.name ??
            widget.tickerSymbol;
    final String logo = widget.ticker?.logo ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _infoCard(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      showLogo(
                        widget.tickerSymbol,
                        logo,
                        sideWidth: 32,
                        name: widget.tickerSymbol,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: DashboardTextStyles.stockName.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  widget.tickerSymbol.toUpperCase(),
                                  style:
                                      DashboardTextStyles.tickerSymbol.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: secondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _inlineComplianceBadge(report.complianceStatus),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.onOpenEtfDetail != null)
                        TextButton.icon(
                          onPressed: widget.onOpenEtfDetail,
                          icon: Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF3B82F6),
                          ),
                          label: Text(
                            'Full Analysis',
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF3B82F6),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Price',
                            style: DashboardTextStyles.tickerSymbol.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtPrice(etf?.currentPrice),
                            style: DashboardTextStyles.stockName.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: primary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Change',
                            style: DashboardTextStyles.tickerSymbol.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            etf?.priceChange1D != null
                                ? '${etf!.priceChange1D! >= 0 ? '+' : ''}${etf.priceChange1D!.toStringAsFixed(2)}'
                                : '--',
                            style: DashboardTextStyles.stockName.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: etf?.priceChange1D != null
                                  ? (etf!.priceChange1D! >= 0
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626))
                                  : secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AUM: ${etf?.aum != null ? Constants.getShortenedMarketCapV2(etf!.aum) : _denominatorLabel()}',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primary,
                        ),
                      ),
                      Text(
                        'Volume: ${etf?.volume != null ? '${((etf!.volume!) / 1000000).toStringAsFixed(1)}M' : '--'}',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _infoCard(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fund Information',
                    style: DashboardTextStyles.stockName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _overviewRow(
                    'Asset Class:',
                    report.assetClass.isNotEmpty
                        ? report.assetClass
                        : etf?.assetClass ?? '--',
                    isDark,
                  ),
                  _overviewRow(
                    'Segment:',
                    report.investmentSegment.isNotEmpty
                        ? report.investmentSegment
                        : etf?.investmentSegment ?? '--',
                    isDark,
                  ),
                  _overviewRow(
                    'ETF Type:',
                    report.etfType.isNotEmpty ? report.etfType : '--',
                    isDark,
                  ),
                  _overviewRow(
                    'Holdings:',
                    report.numberOfHoldings > 0
                        ? report.numberOfHoldings.toString()
                        : etf?.numberOfHoldings?.toString() ?? '--',
                    isDark,
                  ),
                  // _overviewRow(
                  //   'ISIN:',
                  //   report.isin.isNotEmpty ? report.isin : '--',
                  //   isDark,
                  // ),
                  _overviewRow(
                    'Market:',
                    report.market.isNotEmpty
                        ? report.market
                        : etf?.domicile ?? '--',
                    isDark,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _infoCard(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Metrics',
                    style: DashboardTextStyles.stockName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _overviewRow(
                    'Expense Ratio:',
                    etf?.expenseRatio != null
                        ? _fmtPercent(etf!.expenseRatio)
                        : '--',
                    isDark,
                  ),
                  _overviewRow(
                    'NAV:',
                    _fmtPrice(etf?.nav),
                    isDark,
                  ),
                  _overviewRow(
                    '52W High:',
                    _fmtPrice(etf?.d52WeekHigh),
                    isDark,
                  ),
                  _overviewRow(
                    '52W Low:',
                    _fmtPrice(etf?.d52WeekLow),
                    isDark,
                  ),
                  _overviewRow(
                    'Leveraged ETF:',
                    report.isLeveraged == '1' ? 'Yes' : 'No',
                    isDark,
                  ),
                  // _overviewRow(
                  //   'Inverse:',
                  //   report.isInverse == '1' ? 'Yes' : 'No',
                  //   isDark,
                  // ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(EtfComplianceReport report, bool isDark) {
    final Color accent = const Color(0xFF16A34A);
    return ComplianceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Screening Overview', isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _overviewPanel(
                  title: 'Our Analysis',
                  status: report.complianceStatus,
                  isDark: isDark,
                  accent: accent,
                  lines: <_PanelLine>[
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
                      value: ComplianceFormatters.percent(report.totalHalalRatio),
                      valueColor: const Color(0xFF16A34A),
                    ),
                    _PanelLine(
                      label: 'Not Halal',
                      value:
                          ComplianceFormatters.percent(report.totalNotHalalRatio),
                      valueColor: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _overviewPanel(
                  title: 'CBA Screening',
                  status: report.cbaStatus,
                  isDark: isDark,
                  accent: const Color(0xFF3B82F6),
                  lines: <_PanelLine>[
                    _PanelLine(
                      label: 'Business Activity',
                      value: ComplianceFormatters.statusLabel(
                        report.revenueBreakdownStatus,
                      ),
                      valueColor: _isFailStatus(report.revenueBreakdownStatus)
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                    _PanelLine(
                      label: 'IB Securities',
                      value: ComplianceFormatters.statusLabel(
                        report.securitiesAndAssetsStatus,
                      ),
                      valueColor:
                          _isFailStatus(report.securitiesAndAssetsStatus)
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                    ),
                    _PanelLine(
                      label: 'IB Debt',
                      value: ComplianceFormatters.statusLabel(report.debtStatus),
                      valueColor: _isFailStatus(report.debtStatus)
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report.shariahReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _formatReasonText(report.shariahReason),
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _overviewPanel({
    required String title,
    required String status,
    required Color accent,
    required bool isDark,
    required List<_PanelLine> lines,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ComplianceStatusBadge(
                label: status,
                compact: true,
                fontSize: 13,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map(_panelDataLine),
        ],
      ),
    );
  }

  Widget _panelDataLine(_PanelLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            line.label,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          Text(
            line.value,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: line.valueColor,
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
          _sectionLabel('Screening', isDark),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _screeningColumn(
                  title: 'Business Activity',
                  status: report.revenueBreakdownStatus,
                  isDark: isDark,
                  onViewCalculation: () => _showBusinessCalculationDialog(
                    report,
                    isDark,
                  ),
                  child: _buildBusinessContent(report, isDark),
                ),
                const SizedBox(width: 10),
                _screeningColumn(
                  title: 'IB Securities',
                  status: report.securitiesAndAssetsStatus,
                  isDark: isDark,
                  secondary: secondary,
                  toggleSectionKey: 'securities',
                  child: _buildSecuritiesContent(report, isDark),
                ),
                const SizedBox(width: 10),
                _screeningColumn(
                  title: 'IB Debt',
                  status: report.debtStatus,
                  isDark: isDark,
                  secondary: secondary,
                  toggleSectionKey: 'debt',
                  child: _buildDebtContent(report, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _screeningColumn({
    required String title,
    required String status,
    required bool isDark,
    required Widget child,
    Color? secondary,
    String? toggleSectionKey,
    VoidCallback? onViewCalculation,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          ),
        ),
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
                        title,
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ComplianceStatusBadge(
                        label: status,
                        compact: true,
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
                if (toggleSectionKey != null && secondary != null)
                  _buildPercentCurrencyToggle(
                    secondary,
                    isDark,
                    toggleSectionKey,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: child),
            if (onViewCalculation != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: onViewCalculation,
                child: Text(
                  'View calculation',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPercentCurrencyToggle(
    Color secondary,
    bool isDark,
    String sectionKey,
  ) {
    final bool showPercent = _sectionShowPercent(sectionKey);
    return CupertinoSlidingSegmentedControl<bool>(
      padding: const EdgeInsets.all(2),
      groupValue: showPercent,
      thumbColor: isDark ? const Color(0xFF4B5563) : CupertinoColors.white,
      backgroundColor:
          isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
      children: <bool, Widget>{
        true: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            '%',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        false: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            '\$',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      },
      onValueChanged: (bool? value) {
        if (value != null) _setSectionShowPercent(sectionKey, value);
      },
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
            halalColor: const Color(0xFF16A34A),
            doubtfulColor: const Color(0xFFF59E0B),
            notHalalColor: const Color(0xFFDC2626),
            size: isDark ? 180 : 190,
            bottomSpacing: 20,
          ),
        ),
        const SizedBox(height: 4),
        _legendRow(
          'Aggregate Halal Sales & Income of ETF',
          report.totalHalalRatio,
          const Color(0xFF16A34A),
          isDark,
        ),
        _legendRow(
          'Aggregate Doubtful Sales & Income of ETF',
          report.totalDoubtfulRatio,
          const Color(0xFFF59E0B),
          isDark,
        ),
        _legendRow(
          'Aggregate Non Halal Sales & Income of ETF',
          report.totalNotHalalRatio,
          const Color(0xFFDC2626),
          isDark,
        ),
        _legendRow(
          'Aggregate Revenue of ETF',
          100,
          const Color(0xFF6B7280),
          isDark,
        ),
        const Spacer(),
        Text(
          'Not Halal Business Activity Percentage must not exceed 5% of Aggregate Revenue of ETF.',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _legendRow(String label, num value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: isDark ? 12 : 8, height: isDark ? 12 : 8, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            ComplianceFormatters.percent(value),
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritiesContent(EtfComplianceReport report, bool isDark) {
    final bool showPercent = _sectionShowPercent('securities');
    final bool pass = !_isFailStatus(report.securitiesAndAssetsStatus);
    final String numerator = showPercent
        ? ComplianceFormatters.percent(report.totalIbSecAssetRatio)
        : ComplianceFormatters.compactMoney(
            report.totalIbSecAssetRevenue,
            fromOnes: true,
          );
    final String denominator = _denominatorLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _complianceRatioBar(
          value: report.totalIbSecAssetRatio.toDouble(),
          threshold: 30,
          pass: pass,
          numeratorLabel: 'Interest-bearing securities and assets',
          numeratorValue: ComplianceFormatters.compactMoney(
            report.totalIbSecAssetRevenue,
            fromOnes: true,
          ),
          denominatorValue: denominator,
          denominatorLabel: 'Market Value',
        ),
        const SizedBox(height: 8),
        Text(
          'Current: $numerator / $denominator',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtContent(EtfComplianceReport report, bool isDark) {
    final bool showPercent = _sectionShowPercent('debt');
    final bool pass = !_isFailStatus(report.debtStatus);
    final String numerator = showPercent
        ? ComplianceFormatters.percent(report.totalDebtRatio)
        : ComplianceFormatters.compactMoney(
            report.totalIbDebtRevenue,
            fromOnes: true,
          );
    final String denominator = _denominatorLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _complianceRatioBar(
          value: report.totalDebtRatio.toDouble(),
          threshold: 30,
          pass: pass,
          numeratorLabel: 'Total Interest-bearing debt',
          numeratorValue: ComplianceFormatters.compactMoney(
            report.totalIbDebtRevenue,
            fromOnes: true,
          ),
          denominatorValue: denominator,
          denominatorLabel: 'Market Value',
        ),
        const SizedBox(height: 8),
        Text(
          'Current: $numerator / $denominator',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
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
    final Color statusColor =
        pass ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final double fillFactor = (value.clamp(0.0, 100.0) / 100).clamp(0.0, 1.0);
    final double thresholdFactor = (threshold / 100).clamp(0.0, 1.0);
    final double thresholdX = -1.0 + (2.0 * thresholdFactor);
    final String valueText = '${value.toStringAsFixed(2)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Current ratio',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 8,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fillFactor,
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(thresholdX, 0),
                child: Container(
                  width: 2,
                  height: 14,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '0%',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(thresholdX, 0),
                child: Text(
                  '${threshold.toInt()}% limit',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '100%',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numeratorLabel ÷ $denominatorLabel',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$numeratorValue ÷ $denominatorValue = $valueText',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pass
              ? 'Pass — ratio is below the ${threshold.toInt()}% Shariah screening limit.'
              : 'Fail — ratio exceeds the ${threshold.toInt()}% Shariah screening limit.',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 14,
            color: pass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  void _showBusinessCalculationDialog(EtfComplianceReport report, bool isDark) {
    final String numerator = ComplianceFormatters.compactMoney(
      report.impermissibleAmount,
      fromOnes: true,
    );
    final String denominator = ComplianceFormatters.compactMoney(
      report.etfTotalRevenue,
      fromOnes: true,
    );
    final String result =
        ComplianceFormatters.percent(report.impermissibleRatio);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final Color bg =
            isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final Color border =
            isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);

        return Dialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Not Halal Business Activity Percentage of ETF',
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Not Halal Business Activity Percentage of ETF =',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '( Aggregate Non Halal Sales & Income of ETF + Aggregate Doubtful Sales & Income of ETF )',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '( Aggregate Revenue of ETF )',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111827)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$numerator ÷ $denominator = $result',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${ComplianceFormatters.compactMoney(report.totalNotHalalRevenue, fromOnes: true)} + ${ComplianceFormatters.compactMoney(report.totalDoubtfulRevenue, fromOnes: true)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
