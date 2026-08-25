import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/shariah_compliance_etf_details_screen.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_history_item.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report_period.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_api_service.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_history_details_service.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_history_service.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_formatters.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_history_formatters.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_charts.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_detail_search.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_report_period_selector.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ShariahComplianceDetailsScreen extends StatefulWidget {
  const ShariahComplianceDetailsScreen({
    super.key,
    required this.tickerSymbol,
    this.companyName,
    this.ticker,
  });

  final String tickerSymbol;
  final String? companyName;
  final TickerModel? ticker;

  @override
  State<ShariahComplianceDetailsScreen> createState() =>
      _ShariahComplianceDetailsScreenState();
}

class _ShariahComplianceDetailsScreenState
    extends State<ShariahComplianceDetailsScreen> {
  final ShariahComplianceApiService _apiService = ShariahComplianceApiService();
  final ShariahComplianceHistoryService _historyService =
      ShariahComplianceHistoryService();
  final ShariahComplianceHistoryDetailsService _historyDetailsService =
      ShariahComplianceHistoryDetailsService();
  final StockDetailsController _stockController = StockDetailsController();

  ComplianceReport? _currentReport;
  StocksData? _stockData;
  List<ComplianceHistoryItem> _history = const <ComplianceHistoryItem>[];
  List<ComplianceReportPeriod> _historicalPeriods =
      const <ComplianceReportPeriod>[];
  bool _viewingHistorical = false;
  String? _selectedHistoricalYear;
  String? _selectedHistoricalPeriodId;
  bool _isLoading = true;
  final Map<String, bool> _showPercentBySection = <String, bool>{
    'revenue': true,
    'securities': true,
    'debt': true,
  };
  final Set<String> _expandedRows = <String>{};
  int? _hoveredHistoryRow;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadStockData();

    try {
      final results = await Future.wait<dynamic>([
        _apiService.fetchCompliance(widget.tickerSymbol),
        _historyService.fetchHistory(widget.tickerSymbol),
        _historyDetailsService.fetchPeriods(widget.tickerSymbol),
      ]);

      if (!mounted) return;

      final ShariahComplianceResult apiResult =
          results[0] as ShariahComplianceResult;
      final ComplianceReport? currentReport = apiResult.isSuccess
          ? ComplianceReport.fromJson(apiResult.data!)
          : null;
      setState(() {
        _currentReport = currentReport;
        _history = results[1] as List<ComplianceHistoryItem>;
        _historicalPeriods = _dedupeHistoricalPeriods(
          results[2] as List<ComplianceReportPeriod>,
          currentReport,
        );
        _viewingHistorical = false;
        _selectedHistoricalYear = null;
        _selectedHistoricalPeriodId = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentReport = null;
        _history = const <ComplianceHistoryItem>[];
        _historicalPeriods = const <ComplianceReportPeriod>[];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStockData() async {
    try {
      await _stockController
          .fetchStockDetails(widget.tickerSymbol)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Leave stock metrics as placeholders when the secondary request stalls.
    }

    if (!mounted) return;
    setState(() {
      _stockData = _stockController.stockData.value;
    });
  }

  ComplianceReport? get _activeReport =>
      _viewingHistorical ? _selectedHistoricalPeriod?.report : _currentReport;

  ComplianceReportPeriod? get _selectedHistoricalPeriod {
    if (_selectedHistoricalPeriodId == null) return null;
    for (final ComplianceReportPeriod period in _historicalPeriods) {
      if (period.id == _selectedHistoricalPeriodId) return period;
    }
    return null;
  }

  bool get _showMsciPanel {
    final ComplianceReport? report = _activeReport;
    if (report == null) return false;
    if (_viewingHistorical) return false;
    return report.msciStatus.isNotEmpty ||
        report.msciSecuritiesRatio > 0 ||
        report.msciDebtRatio > 0 ||
        report.msciTotalAssets > 0;
  }

  List<ComplianceReportPeriod> _dedupeHistoricalPeriods(
    List<ComplianceReportPeriod> periods,
    ComplianceReport? currentReport,
  ) {
    if (currentReport == null) return periods;
    return periods
        .where(
          (ComplianceReportPeriod period) =>
              period.reportDate != currentReport.reportDate,
        )
        .toList();
  }

  void _selectCurrentReport() {
    setState(() {
      _viewingHistorical = false;
      _selectedHistoricalYear = null;
      _selectedHistoricalPeriodId = null;
    });
  }

  void _selectHistoricalYear(String year) {
    final List<ComplianceReportPeriod> options = _historicalPeriods
        .where((ComplianceReportPeriod period) => period.year == year)
        .toList();
    if (options.isEmpty) return;

    setState(() {
      _viewingHistorical = true;
      _selectedHistoricalYear = year;
      _selectedHistoricalPeriodId = options.first.id;
    });
  }

  void _selectHistoricalPeriod(ComplianceReportPeriod period) {
    setState(() {
      _viewingHistorical = true;
      _selectedHistoricalYear = period.year;
      _selectedHistoricalPeriodId = period.id;
    });
  }

  bool _sectionShowPercent(String sectionKey) =>
      _showPercentBySection[sectionKey] ?? true;

  void _setSectionShowPercent(String sectionKey, bool showPercent) {
    setState(() => _showPercentBySection[sectionKey] = showPercent);
  }

  void _openTickerDetail() {
    final StocksData? stock = _stockData;
    final TickerModel ticker = widget.ticker ??
        TickerModel(
          symbol: widget.tickerSymbol,
          ticker: widget.tickerSymbol,
          companyName: _currentReport?.companyName ?? widget.companyName,
          name: _currentReport?.companyName ?? widget.companyName,
          stockName: _currentReport?.companyName ?? widget.companyName,
          exchange: _currentReport?.exchange ?? stock?.exchange,
          sectorname: widget.ticker?.sectorname,
          logo: widget.ticker?.logo,
          currentPrice: stock?.currentPrice,
          percentChange: stock?.change1DPercent,
          isStock: true,
        );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TickerDetailScreen(ticker: ticker),
      ),
    );
  }

  void _goBack() => Navigator.of(context).maybePop();

  void _exitScreening() {
    Navigator.of(context, rootNavigator: true).popUntil((Route<dynamic> route) {
      return route.isFirst;
    });
  }

  void _openComplianceResult(TickerModel ticker) {
    final String symbol = (ticker.symbol ?? ticker.ticker ?? '').trim();
    if (symbol.isEmpty) return;

    final String? name = ticker.companyName ?? ticker.name ?? ticker.stockName;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ticker.isStock
            ? ShariahComplianceDetailsScreen(
                tickerSymbol: symbol,
                companyName: name,
                ticker: ticker,
              )
            : ShariahComplianceEtfDetailsScreen(
                tickerSymbol: symbol,
                companyName: name,
                ticker: ticker,
              ),
      ),
    );
  }

  void _showCalculationDialog(
    ComplianceReport report,
    _CalculationDialogType type,
    bool isDark,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _CalculationDialog(
        report: report,
        type: type,
        isDark: isDark,
      ),
    );
  }

  void _toggleExpanded(String key) {
    setState(() {
      if (_expandedRows.contains(key)) {
        _expandedRows.remove(key);
      } else {
        _expandedRows.add(key);
      }
    });
  }

  Future<void> _openSource(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isCompliantStatus(String status) {
    final String normalized = status.toUpperCase();
    return normalized.contains('COMPLIANT') && !normalized.contains('NON');
  }

  bool _isFailStatus(String status) {
    final String normalized = status.toUpperCase();
    return normalized.contains('FAIL') ||
        normalized.contains('NON') ||
        normalized.contains('NOT');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = HomeUi.title(isDark);
    final Color secondary = HomeUi.muted(isDark);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _exitScreening,
      },
      child: Scaffold(
        backgroundColor: HomeUi.pageBg(isDark),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HomeUi.accent(isDark),
                  ),
                )
              : _currentReport == null
                  ? _buildError(primary, secondary)
                  : LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final EdgeInsets pagePadding =
                            HomeUi.pagePadding(constraints.maxWidth);
                        return Column(
                          children: [
                            _buildTopBar(
                              primary,
                              secondary,
                              isDark,
                              pagePadding,
                            ),
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  padding: pagePadding.copyWith(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildStockHeaderRow(isDark),
                                      const SizedBox(height: 16),
                                      _buildPeriodAndRevenueRow(
                                        primary: primary,
                                        secondary: secondary,
                                        isDark: isDark,
                                        maxWidth: constraints.maxWidth -
                                            pagePadding.horizontal,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildMethodologySection(
                                        _activeReport!,
                                        isDark,
                                        showMsciPanel: _showMsciPanel,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildScreeningSection(
                                        _activeReport!,
                                        isDark,
                                      ),
                                      if (_history.isNotEmpty) ...<Widget>[
                                        const SizedBox(height: 16),
                                        _buildHistorySection(
                                          _activeReport!,
                                          secondary,
                                          isDark,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildError(Color primary, Color secondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Unable to load compliance data for ${widget.tickerSymbol}',
            style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW, color: primary),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _goBack,
            child: Text(
              'Go back',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark, {double? fontSize}) {
    return Text(
      text,
      style: HomeUi.sectionTitle(isDark).copyWith(fontSize: fontSize ?? 15),
    );
  }

  Widget _topBarCompliancePill(String status, {double fontSize = 13}) {
    return ComplianceStatusBadge(
      label: status,
      fontSize: fontSize,
    );
  }

  Widget _historyStatusChip(String status) {
    return ComplianceStatusBadge(
      label: status,
      compact: true,
      fontSize: 11,
    );
  }

  Widget _inlineComplianceBadge(String status) {
    return ComplianceStatusBadge(
      label: status,
      compact: true,
      fontSize: 10,
    );
  }

  String _fmtPrice(num? value) =>
      value != null ? '\$${value.toStringAsFixed(2)}' : '--';

  String _fmtPercent(num? value) =>
      value != null ? '${value.toStringAsFixed(2)}%' : '--';

  String _fmtNum(num? value, {int digits = 2}) =>
      value != null ? value.toStringAsFixed(digits) : '--';

  Widget _buildTopBar(
    Color primary,
    Color secondary,
    bool isDark,
    EdgeInsets pagePadding,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        12,
        pagePadding.right,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: HomeUi.filterFieldHeight,
            child: Center(
              child: HomeUi.ghostAction(
                label: 'Back',
                dark: isDark,
                icon: Icons.arrow_back_rounded,
                onTap: _goBack,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Center(
              child: ComplianceDetailSearch(
                onSelectTicker: _openComplianceResult,
                maxWidth: 520,
                compact: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: HomeUi.filterFieldHeight,
            child: Center(
              child: HomeUi.ghostAction(
                label: 'Exit',
                dark: isDark,
                icon: Icons.close_rounded,
                onTap: _exitScreening,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildStockHeaderRow(bool isDark) {
    final String name = _activeReport?.companyName ??
        widget.companyName ??
        widget.ticker?.companyName ??
        widget.ticker?.name ??
        '';
    final String status = _activeReport?.status ?? '';
    final String logo = widget.ticker?.logo ?? '';
    final String ticker = widget.tickerSymbol.toUpperCase();
    final StocksData? stock = _stockData;
    final num? change = stock?.change1DPercent;
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
                        const SizedBox(width: 8),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _openTickerDetail,
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
                                _fmtPrice(stock?.currentPrice),
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
                      'Market Cap',
                      stock?.usdMarketCap != null
                          ? Constants.formatMarketCapFromMillions(
                              stock!.usdMarketCap)
                          : '--',
                    ),
                    _headerKv(
                      isDark,
                      'Volume',
                      stock?.volume != null
                          ? '${((stock!.volume!) / 1000000).toStringAsFixed(1)}M'
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
                      icon: Icons.public_outlined,
                      title: 'Market Overview',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDark,
                      'Industry',
                      stock?.industry ?? '--',
                      maxLines: 2,
                    ),
                    _headerKv(
                      isDark,
                      'Shares Out',
                      stock?.sharesOutStanding != null
                          ? Constants.getShortenedMarketCapV2(
                                  stock!.sharesOutStanding! * 1000000)
                              .replaceAll('\$', '')
                          : '--',
                    ),
                    _headerKv(isDark, 'IPO Date', stock?.ipoDate ?? '--'),
                    _headerKv(isDark, 'Beta', _fmtNum(stock?.beta)),
                    _headerKv(
                        isDark, '52W High', _fmtPrice(stock?.d52WeekHigh)),
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
                      title: 'Key Highlights',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDark,
                      'Book Value',
                      stock?.bookValuePerShareAnnual != null
                          ? _fmtPrice(stock!.bookValuePerShareAnnual)
                          : '--',
                    ),
                    _headerKv(
                      isDark,
                      'Cash/Share',
                      stock?.cashPerSharePerShareAnnual != null
                          ? _fmtPrice(stock!.cashPerSharePerShareAnnual)
                          : '--',
                    ),
                    _headerKv(
                      isDark,
                      'Dividend Yield',
                      _fmtPercent(stock?.currentDividendYieldTTM),
                    ),
                    _headerKv(
                      isDark,
                      'Enterprise Value',
                      stock?.enterpriseValue != null
                          ? Constants.getShortenedMarketCapV2(
                              stock!.enterpriseValue)
                          : '--',
                    ),
                    _headerKv(isDark, 'P/B Ratio', _fmtNum(stock?.pbAnnual)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentCurrencyToggle(
      Color secondary, bool isDark, String sectionKey,
      {double fontSize = 13}) {
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

  Widget _sectionHeaderWithToggle(
    String title,
    bool isDark,
    Color secondary, {
    String? sectionKey,
    double? labelFontSize,
    double? toggleFontSize,
  }) {
    return Row(
      children: [
        Expanded(child: _sectionLabel(title, isDark, fontSize: labelFontSize)),
        if (sectionKey != null)
          _buildPercentCurrencyToggle(secondary, isDark, sectionKey,
              fontSize: toggleFontSize ?? 13),
      ],
    );
  }

  Widget _metaDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: HomeUi.borderLight(isDark),
    );
  }

  Widget _buildMetadataStrip(
      ComplianceReport report, Color secondary, bool isDark) {
    final List<Widget> items = <Widget>[
      _metaItem('Report Date', report.reportDate, isDark),
      _metaDivider(isDark),
      _metaItem(
          'Period', report.reportTypeSection.replaceAll('_', ' '), isDark),
      _metaDivider(isDark),
      _metaItem('Exchange', report.exchange, isDark),
      _metaDivider(isDark),
      _metaItem(
          'Ranking', '#${report.ranking} / #${report.rankingV2} v2', isDark),
      _metaDivider(isDark),
      _metaItem(
        '36M Avg Cap',
        ComplianceFormatters.compactMoney(
          report.trailing36MonAvgCap,
          fromOnes: true,
        ),
        isDark,
      ),
      _metaDivider(isDark),
      _metaItem('Units', 'x${report.units}', isDark),
    ];

    if (report.reportSource.isNotEmpty) {
      items.addAll(<Widget>[
        _metaDivider(isDark),
        InkWell(
          onTap: () => _openSource(report.reportSource),
          child: isDark
              ? Text(
                  'SEC Filing',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.accent(isDark),
                    decoration: TextDecoration.underline,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEC Filing',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 10,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SEC Filing',
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: HomeUi.accent(isDark),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_outward,
                          size: 12,
                          color: HomeUi.accent(isDark),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ]);
    }

    if (isDark) {
      return ComplianceSectionCard(
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: <Widget>[
            _metaItem('Report Date', report.reportDate, isDark),
            _metaItem('Period', report.reportTypeSection.replaceAll('_', ' '),
                isDark),
            _metaItem('Exchange', report.exchange, isDark),
            _metaItem('Ranking', '#${report.ranking} / #${report.rankingV2} v2',
                isDark),
            _metaItem(
              '36M Avg Cap',
              ComplianceFormatters.compactMoney(
                report.trailing36MonAvgCap,
                fromOnes: true,
              ),
              isDark,
            ),
            _metaItem('Units', 'x${report.units}', isDark),
            if (report.reportSource.isNotEmpty)
              InkWell(
                onTap: () => _openSource(report.reportSource),
                child: Text(
                  'SEC Filing',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.accent(isDark),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
      ),
    );
  }

  Widget _metaItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: HomeUi.overline(isDark)
              .copyWith(fontSize: 10, letterSpacing: 0.8),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: HomeUi.control(isDark, active: true).copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HomeUi.title(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodologySection(
    ComplianceReport report,
    bool isDark, {
    required bool showMsciPanel,
  }) {
    return ComplianceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.verified_outlined,
            title: 'Screening Overview',
            subtitleText: 'Our analysis versus MSCI screening',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final List<Widget> cards = <Widget>[
                _comparisonStatCard(
                  isDark: isDark,
                  label: 'Frameworks',
                  value: showMsciPanel ? '2 models' : '1 model',
                  accent: HomeUi.accent(isDark),
                ),
                _comparisonStatCard(
                  isDark: isDark,
                  label: 'Our Status',
                  value: ComplianceFormatters.statusLabel(report.status),
                  accent: ComplianceFormatters.statusColor(report.status),
                ),
                if (showMsciPanel)
                  _comparisonStatCard(
                    isDark: isDark,
                    label: 'MSCI Status',
                    value: ComplianceFormatters.statusLabel(report.msciStatus),
                    accent: ComplianceFormatters.statusColor(report.msciStatus),
                  ),
              ];
              final double available =
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 900;
              final double desiredWidth = showMsciPanel
                  ? ((available - 24) / 3).clamp(170.0, 220.0)
                  : ((available - 12) / 2).clamp(170.0, 220.0);

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
              final double panelWidth = showMsciPanel
                  ? ((available - 12) / 2).clamp(260.0, available)
                  : (available < 560 ? available : 560);
              return Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: panelWidth,
                      child: _methodologyPanel(
                        title: 'Our Analysis',
                        status: report.status,
                        isDark: isDark,
                        accent: ComplianceFormatters.halalColor,
                        tone: HomeUi.positiveSoft(isDark),
                        denominatorLabel: 'Denominator',
                        denominatorValue: 'Trailing 36M Avg Market Cap',
                        metricValue: ComplianceFormatters.compactMoney(
                          report.trailing36MonAvgCap,
                          fromOnes: true,
                        ),
                        metricLabel: 'Market Cap',
                        lines: isDark
                            ? <String>[
                                'Denominator: Trailing 36M Avg Market Cap',
                                ComplianceFormatters.compactMoney(
                                  report.trailing36MonAvgCap,
                                  fromOnes: true,
                                ),
                                'Halal ${ComplianceFormatters.percent(report.halalPercent)}',
                                'Not Halal ${ComplianceFormatters.percent(report.notHalalPercent)}',
                              ]
                            : null,
                        structuredLines: isDark
                            ? null
                            : <_PanelLine>[
                                const _PanelLine(
                                  label: 'Denominator',
                                  value: 'Trailing 36M Avg Market Cap',
                                ),
                                _PanelLine(
                                  label: 'Market Cap',
                                  value: ComplianceFormatters.compactMoney(
                                    report.trailing36MonAvgCap,
                                    fromOnes: true,
                                  ),
                                ),
                                _PanelLine(
                                  label: 'Halal',
                                  value: ComplianceFormatters.percent(
                                      report.halalPercent),
                                  valueColor: ComplianceFormatters.halalColor,
                                ),
                                _PanelLine(
                                  label: 'Not Halal',
                                  value: ComplianceFormatters.percent(
                                      report.notHalalPercent),
                                  valueColor: ComplianceFormatters.notHalalColor,
                                ),
                              ],
                      ),
                    ),
                    if (showMsciPanel)
                      SizedBox(
                        width: panelWidth,
                        child: _methodologyPanel(
                          title: 'MSCI',
                          status: report.msciStatus,
                          isDark: isDark,
                          accent: ComplianceFormatters.notHalalColor,
                          tone: HomeUi.negativeSoft(isDark),
                          denominatorLabel: 'Denominator',
                          denominatorValue: 'Total Assets',
                          metricValue: ComplianceFormatters.compactMoney(
                            report.msciTotalAssets,
                          ),
                          metricLabel: 'Total Assets',
                          lines: isDark
                              ? <String>[
                                  'Denominator: Total Assets',
                                  ComplianceFormatters.compactMoney(
                                    report.msciTotalAssets,
                                  ),
                                  'IB Securities ${ComplianceFormatters.percent(report.msciSecuritiesRatio)}',
                                  'IB Debt ${ComplianceFormatters.percent(report.msciDebtRatio)}',
                                ]
                              : null,
                          structuredLines: isDark
                              ? null
                              : <_PanelLine>[
                                  const _PanelLine(
                                    label: 'Denominator',
                                    value: 'Total Assets',
                                  ),
                                  _PanelLine(
                                    label: 'Total Assets',
                                    value: ComplianceFormatters.compactMoney(
                                      report.msciTotalAssets,
                                    ),
                                  ),
                                  _PanelLine(
                                    label: 'IB Securities',
                                    value: ComplianceFormatters.percent(
                                        report.msciSecuritiesRatio),
                                    valueColor:
                                        _isFailStatus(report.msciSecuritiesStatus)
                                            ? ComplianceFormatters.notHalalColor
                                            : null,
                                  ),
                                  _PanelLine(
                                    label: 'IB Debt',
                                    value: ComplianceFormatters.percent(
                                        report.msciDebtRatio),
                                    valueColor:
                                        _isFailStatus(report.msciDebtStatus)
                                            ? ComplianceFormatters.notHalalColor
                                            : null,
                                  ),
                                ],
                        ),
                      ),
                  ],
                ),
              );
            },
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
    List<String>? lines,
    List<_PanelLine>? structuredLines,
  }) {
    final List<_PanelLine> rows = structuredLines ??
        (lines ?? const <String>[])
            .map((String line) => _PanelLine(label: '', value: line))
            .toList();
    final Color bgColor = isDark
        ? Color.alphaBlend(tone.withValues(alpha: 0.12), HomeUi.elevatedBg(true))
        : Color.alphaBlend(tone.withValues(alpha: 0.55), Colors.white);

    return Container(
      constraints: const BoxConstraints(minWidth: 280),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark).withValues(alpha: isDark ? 0.55 : 0.7),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(
                color: HomeUi.borderLight(isDark).withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              children: rows.map(_panelDataLine).toList(),
            ),
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

  Widget _panelDataLine(_PanelLine line) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (line.label.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          line.value,
          style: HomeUi.tableCell(isDark).copyWith(fontSize: 13),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.label,
              style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildScreeningSection(ComplianceReport report, bool isDark) {
    final Color secondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

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
                  onViewCalculation: () => _showCalculationDialog(
                    report,
                    _CalculationDialogType.business,
                    isDark,
                  ),
                  child: _buildBusinessScreeningContent(report, isDark),
                ),
                _screeningColumn(
                  title: 'IB Securities',
                  status: report.securitiesStatus,
                  isDark: isDark,
                  secondary: secondary,
                  stretchContent: useEqualHeightRow,
                  toggleSectionKey: 'securities',
                  onViewCalculation: () => _showCalculationDialog(
                    report,
                    _CalculationDialogType.securities,
                    isDark,
                  ),
                  child: _buildSecuritiesScreeningContent(report, isDark),
                ),
                _screeningColumn(
                  title: 'IB Debt',
                  status: report.debtStatus,
                  isDark: isDark,
                  secondary: secondary,
                  stretchContent: useEqualHeightRow,
                  toggleSectionKey: 'debt',
                  onViewCalculation: () => _showCalculationDialog(
                    report,
                    _CalculationDialogType.debt,
                    isDark,
                  ),
                  child: _buildDebtScreeningContent(report, isDark),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: child,
    );

    return Container(
      height: stretchContent ? double.infinity : null,
      padding: const EdgeInsets.all(12),
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: HomeUi.cardTitle(isDark).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      ComplianceStatusBadge(
                        label: status,
                        compact: true,
                        fontSize: 11.5,
                      ),
                    ],
                  ),
                ),
                if (toggleSectionKey != null)
                  _buildPercentCurrencyToggle(
                    secondary,
                    isDark,
                    toggleSectionKey,
                    fontSize: 14,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (stretchContent)
            Expanded(child: contentBox)
          else
            contentBox,
          if (onViewCalculation != null) ...[
            const SizedBox(height: 10),
            ComplianceViewCalculationButton(
              isDark: isDark,
              onTap: onViewCalculation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBusinessScreeningContent(ComplianceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ComplianceDonutChart(
            halal: report.halalPercent.toDouble(),
            doubtful: report.questionablePercent.toDouble(),
            notHalal: report.notHalalPercent.toDouble(),
            halalColor: ComplianceFormatters.halalColor,
            doubtfulColor: ComplianceFormatters.doubtfulColor,
            notHalalColor: ComplianceFormatters.notHalalColor,
            size: isDark ? 144 : 152,
            bottomSpacing: 8,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: HomeUi.positiveSoft(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(
              color: ComplianceFormatters.halalColor.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Current ratio',
                  style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
                ),
              ),
              Text(
                ComplianceFormatters.percent(report.businessActivityFailPercent),
                style: HomeUi.tableCellEmphasis(isDark).copyWith(
                  fontSize: 13,
                  color: ComplianceFormatters.halalColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _legendRow('Halal Sales & Income', report.halalPercent,
            ComplianceFormatters.halalColor, isDark),
        _legendRow('Doubtful Sales & Income', report.questionablePercent,
            ComplianceFormatters.doubtfulColor, isDark),
        _legendRow('Non Halal Sales & Income', report.notHalalPercent,
            ComplianceFormatters.notHalalColor, isDark),
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
            'Not Halal Business Activity Percentage must not exceed 5% of Total Revenue.',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 12,
              color:
                  isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritiesScreeningContent(
      ComplianceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDark)
          ComplianceGaugeChart(
            value: report.securitiesRatio.toDouble(),
            threshold: 30,
            passColor: ComplianceFormatters.halalColor,
            failColor: ComplianceFormatters.notHalalColor,
            size: 160,
          )
        else
          _complianceRatioBar(
            value: report.securitiesRatio.toDouble(),
            threshold: 30,
            pass: !_isFailStatus(report.securitiesStatus),
            numeratorLabel: 'Interest-bearing securities and assets',
            numeratorValue: ComplianceFormatters.millions(
              report.securitiesTotalAmount,
            ),
            denominatorValue: ComplianceFormatters.compactMoney(
              report.trailing36MonAvgCap,
              fromOnes: true,
            ),
          ),
        const SizedBox(height: 6),
        if (report.securitiesLongTerm != null) ...[
          const SizedBox(height: 6),
          _debtTermBlock(
            'Long-term',
            report.securitiesLongTerm!,
            isDark,
            'securities-lt',
            forceExpanded: true,
          ),
        ],
        if (report.securitiesShortTerm != null)
          _debtTermBlock(
            'Short-term',
            report.securitiesShortTerm!,
            isDark,
            'securities-st',
            forceExpanded: true,
          ),
      ],
    );
  }

  Widget _buildDebtScreeningContent(ComplianceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDark)
          ComplianceGaugeChart(
            value: report.debtRatio.toDouble(),
            threshold: 30,
            passColor: ComplianceFormatters.halalColor,
            failColor: ComplianceFormatters.notHalalColor,
            size: 160,
          )
        else
          _complianceRatioBar(
            value: report.debtRatio.toDouble(),
            threshold: 30,
            pass: !_isFailStatus(report.debtStatus),
            numeratorLabel: 'Total Interest-bearing debt',
            numeratorValue:
                ComplianceFormatters.millions(report.debtTotalAmount),
            denominatorValue: ComplianceFormatters.compactMoney(
              report.trailing36MonAvgCap,
              fromOnes: true,
            ),
          ),
        const SizedBox(height: 6),
        if (report.debtLongTerm != null) ...[
          const SizedBox(height: 6),
          _debtTermBlock(
            'Long-term',
            report.debtLongTerm!,
            isDark,
            'debt-lt',
            forceExpanded: true,
          ),
        ],
        if (report.debtShortTerm != null)
          _debtTermBlock(
            'Short-term',
            report.debtShortTerm!,
            isDark,
            'debt-st',
            forceExpanded: true,
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
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color statusColor =
        pass ? ComplianceFormatters.halalColor : ComplianceFormatters.notHalalColor;
    final double clampedValue = value.clamp(0.0, 100.0);
    final double thresholdFactor = (threshold / 100).clamp(0.0, 1.0);
    final double fillFactor = (clampedValue / 100).clamp(0.0, 1.0);
    final double thresholdX = -1.0 + (2.0 * thresholdFactor);
    final String valueText = '${value.toStringAsFixed(2)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(color: statusColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Text(
                'Current ratio',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  color: HomeUi.subtitle(isDark).color,
                ),
              ),
              const Spacer(),
              Text(
                valueText,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 8,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF24292F) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fillFactor,
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 8,
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
                  color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
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
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
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
                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
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
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: HomeUi.cardBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(color: HomeUi.borderLight(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numeratorLabel ÷ Trailing 36M Avg Market Cap',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  color: HomeUi.subtitle(isDark).color,
                ),
              ),
              const SizedBox(height: 3),
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
        const SizedBox(height: 4),
        Text(
          pass
              ? 'Pass — ratio is below the ${threshold.toInt()}% Shariah screening limit.'
              : 'Fail — ratio exceeds the ${threshold.toInt()}% Shariah screening limit.',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: pass ? ComplianceFormatters.halalColor : ComplianceFormatters.notHalalColor,
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
              ),
            ),
          ),
          Text(
            ComplianceFormatters.percent(value),
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _debtTermBlock(
      String title, ComplianceDebtTerm term, bool isDark, String keyPrefix,
      {bool forceExpanded = false}) {
    final String key = '$keyPrefix-$title';
    final bool expanded = forceExpanded || _expandedRows.contains(key);
    final String sectionKey =
        keyPrefix.startsWith('securities') ? 'securities' : 'debt';
    final bool showPercent = _sectionShowPercent(sectionKey);
    final String amountText = showPercent
        ? ComplianceFormatters.percent(term.ratio)
        : ComplianceFormatters.millions(term.amount);

    if (isDark) {
      return ExpansionTile(
        initiallyExpanded: forceExpanded,
        title: Text(
          '$title • $amountText',
          style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        children: term.items
            .map(
              (item) => ListTile(
                dense: true,
                title: Text(item.name,
                    style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW, fontSize: 14)),
                trailing: Text(
                  showPercent
                      ? ComplianceFormatters.percent(item.percentage)
                      : formatLineAmount(item, showPercent: false),
                  style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW, fontSize: 15),
                ),
              ),
            )
            .toList(),
      );
    }

    if (forceExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  amountText,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...term.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  border: Border.all(color: HomeUi.borderLight(isDark)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Text(
                      showPercent
                          ? ComplianceFormatters.percent(item.percentage)
                          : formatLineAmount(item, showPercent: false),
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpanded(key),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  amountText,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (expanded)
          ...term.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  border: Border.all(color: HomeUi.borderLight(isDark)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Text(
                      showPercent
                          ? ComplianceFormatters.percent(item.percentage)
                          : formatLineAmount(item, showPercent: false),
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodAndRevenueRow({
    required Color primary,
    required Color secondary,
    required bool isDark,
    required double maxWidth,
  }) {
    final ComplianceReport report = _activeReport!;
    final bool hasPeriods = _historicalPeriods.isNotEmpty;
    final Widget revenue = _buildRevenueSection(
      report,
      primary,
      secondary,
      isDark,
      compact: hasPeriods && maxWidth >= 980,
    );

    if (!hasPeriods) {
      return revenue;
    }

    final Widget period = ComplianceReportPeriodSelector(
      periods: _historicalPeriods,
      viewingHistorical: _viewingHistorical,
      selectedYear: _selectedHistoricalYear,
      selectedPeriodId: _selectedHistoricalPeriodId,
      onSelectCurrent: _selectCurrentReport,
      onSelectYear: _selectHistoricalYear,
      onSelectPeriod: _selectHistoricalPeriod,
      isDark: isDark,
      secondary: secondary,
      compact: maxWidth >= 980,
    );

    if (maxWidth < 980) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          period,
          const SizedBox(height: 16),
          revenue,
        ],
      );
    }

    final double sharedHeight = maxWidth >= 1240 ? 520 : 480;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: sharedHeight,
            child: period,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: sharedHeight,
            child: revenue,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueSection(
    ComplianceReport report,
    Color primary,
    Color secondary,
    bool isDark, {
    bool compact = false,
  }) {
    final bool showPercent = _sectionShowPercent('revenue');
    final List<ComplianceLineItem> halalItems = report.revenueItems
        .where((ComplianceLineItem e) =>
            e.selector.toUpperCase().contains('COMPLIANT') &&
            !e.selector.toUpperCase().contains('NON'))
        .toList();
    final List<ComplianceLineItem> notHalalItems = report.revenueItems
        .where((ComplianceLineItem e) =>
            !(e.selector.toUpperCase().contains('COMPLIANT') &&
                !e.selector.toUpperCase().contains('NON')))
        .toList();

    final double halalShare = report.halalPercent.toDouble().clamp(0, 100);
    final double notHalalShare =
        report.notHalalPercent.toDouble().clamp(0, 100);
    final double totalShare =
        (halalShare + notHalalShare) <= 0 ? 1 : (halalShare + notHalalShare);

    final Widget breakdownContent = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool sideBySide = !compact && constraints.maxWidth >= 560;
        final Widget halalColumn = _revenueCategoryPanel(
          title: 'Halal Revenue',
          percent: report.halalPercent,
          accent: ComplianceFormatters.halalColor,
          soft: HomeUi.positiveSoft(isDark),
          items: halalItems,
          primary: primary,
          secondary: secondary,
          isDark: isDark,
          showPercent: showPercent,
          compact: compact,
        );
        final Widget notHalalColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _revenueCategoryPanel(
              title: 'Not Halal Revenue',
              percent: report.notHalalPercent,
              accent: ComplianceFormatters.notHalalColor,
              soft: HomeUi.negativeSoft(isDark),
              items: notHalalItems,
              primary: primary,
              secondary: secondary,
              isDark: isDark,
              showPercent: showPercent,
              compact: compact,
            ),
            if (report.interestIncomeItems.isNotEmpty) ...<Widget>[
              SizedBox(height: compact ? 10 : 12),
              _revenueCategoryPanel(
                title: 'Other Income',
                percent: report.interestIncomeItems.fold<num>(
                  0,
                  (num sum, ComplianceLineItem item) => sum + item.percentage,
                ),
                accent: ComplianceFormatters.doubtfulColor,
                soft: isDark
                    ? const Color(0xFF3A2A10)
                    : const Color(0xFFFFF7ED),
                items: report.interestIncomeItems,
                primary: primary,
                secondary: secondary,
                isDark: isDark,
                showPercent: showPercent,
                compact: compact,
              ),
            ],
          ],
        );

        if (!sideBySide) {
          return Column(
            children: <Widget>[
              halalColumn,
              SizedBox(height: compact ? 10 : 12),
              notHalalColumn,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: halalColumn),
            const SizedBox(width: 14),
            Expanded(child: notHalalColumn),
          ],
        );
      },
    );

    return ComplianceSectionCard(
      fillHeight: compact,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 12 : 16,
      ),
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
                  subtitleText: compact
                      ? 'Halal vs non-compliant mix'
                      : 'Product-level Shariah revenue mix',
                ),
              ),
              const SizedBox(width: 10),
              _buildPercentCurrencyToggle(
                secondary,
                isDark,
                'revenue',
                fontSize: 13,
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 14,
              compact ? 10 : 12,
              compact ? 12 : 14,
              compact ? 10 : 12,
            ),
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
                        value: ComplianceFormatters.percent(report.halalPercent),
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
                            report.notHalalPercent),
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
                          flex: (halalShare / totalShare * 1000).round().clamp(
                                1,
                                1000,
                              ),
                          child: ColoredBox(color: ComplianceFormatters.halalColor),
                        ),
                        Expanded(
                          flex: (notHalalShare / totalShare * 1000)
                              .round()
                              .clamp(1, 1000),
                          child: ColoredBox(color: ComplianceFormatters.notHalalColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 14),
          if (compact)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: breakdownContent,
              ),
            )
          else
            breakdownContent,
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
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: HomeUi.control(isDark, active: true).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: HomeUi.title(isDark),
          ),
        ),
      ],
    );
  }

  Widget _revenueCategoryPanel({
    required String title,
    required num percent,
    required Color accent,
    required Color soft,
    required List<ComplianceLineItem> items,
    required Color primary,
    required Color secondary,
    required bool isDark,
    required bool showPercent,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 14,
              compact ? 10 : 12,
              compact ? 12 : 14,
              compact ? 10 : 12,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: HomeUi.control(isDark, active: true).copyWith(
                      fontSize: compact ? 13 : 13.5,
                      fontWeight: FontWeight.w700,
                      color: HomeUi.title(isDark),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: HomeUi.cardBg(isDark),
                    borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                    border: Border.all(color: accent.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    ComplianceFormatters.percent(percent),
                    style: HomeUi.control(isDark, active: true).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 14,
                0,
                compact ? 12 : 14,
                compact ? 12 : 14,
              ),
              child: Text(
                'No line items',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 12.5),
              ),
            )
          else
            ...items.asMap().entries.map(
              (MapEntry<int, ComplianceLineItem> entry) {
                final bool isLast = entry.key == items.length - 1;
                return _revenueRow(
                  entry.value,
                  primary,
                  secondary,
                  isDark,
                  showPercent,
                  compact: compact,
                  showDivider: !isLast,
                );
              },
            ),
        ],
      ),
    );
  }

  bool _revenueRowCanExpand(ComplianceLineItem item) {
    return (item.comment?.isNotEmpty ?? false) || item.items.isNotEmpty;
  }

  Widget _revenueRow(
    ComplianceLineItem item,
    Color primary,
    Color secondary,
    bool isDark,
    bool showPercent, {
    bool compact = false,
    bool showDivider = true,
  }) {
    final String key = '${item.id}-${item.name}';
    final bool expanded = _expandedRows.contains(key);
    final bool canExpand = _revenueRowCanExpand(item);

    return Column(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canExpand ? () => _toggleExpanded(key) : null,
            hoverColor: HomeUi.accent(isDark).withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 14,
                compact ? 9 : 10,
                compact ? 10 : 12,
                compact ? 9 : 10,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: primary,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    showPercent
                        ? ComplianceFormatters.percent(item.percentage)
                        : formatLineAmount(item, showPercent: false),
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: compact ? 13 : 13.5,
                      fontWeight: FontWeight.w700,
                      color: HomeUi.title(isDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ComplianceStatusBadge(
                    label: item.selector,
                    compact: true,
                    fontSize: compact ? 11 : 11.5,
                  ),
                  if (canExpand) ...<Widget>[
                    const SizedBox(width: 2),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: secondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (expanded && canExpand) ...<Widget>[
          if (item.comment?.isNotEmpty ?? false)
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 14,
                0,
                compact ? 12 : 14,
                8,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  border: Border.all(color: HomeUi.borderLight(isDark)),
                ),
                child: Text(
                  item.comment!,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12.5,
                    height: 1.4,
                    color: secondary,
                  ),
                ),
              ),
            ),
          ...item.items.map(
            (ComplianceLineItem nested) => Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 20 : 24,
                0,
                compact ? 12 : 14,
                8,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      nested.name,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 12.5,
                        color: secondary,
                      ),
                    ),
                  ),
                  Text(
                    showPercent
                        ? ComplianceFormatters.percent(nested.percentage)
                        : formatLineAmount(nested, showPercent: false),
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: compact ? 12 : 14,
            endIndent: compact ? 12 : 14,
            color: HomeUi.borderLight(isDark).withValues(alpha: 0.85),
          ),
      ],
    );
  }

  Widget _statusTextOnly(String status) {
    return Text(
      ComplianceFormatters.statusLabel(status),
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 12,
        fontWeight: ComplianceFormatters.statusFontWeight,
        color: ComplianceFormatters.statusColor(status),
      ),
    );
  }

  Widget _buildMsciSection(ComplianceReport report, bool isDark) {
    return ComplianceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('MSCI Screening Detail', isDark),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFEFF6FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      isDark ? null : Border.all(color: HomeUi.accent(isDark)),
                ),
                child: Text(
                  'External methodology',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF1D4ED8)
                        : HomeUi.accent(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _msciCard(
                'IB Securities & Assets',
                ComplianceFormatters.percent(report.msciSecuritiesRatio),
                report.msciSecuritiesStatus,
                isDark,
              ),
              _msciCard(
                'Interest-Bearing Debt',
                ComplianceFormatters.percent(report.msciDebtRatio),
                report.msciDebtStatus,
                isDark,
              ),
              _msciCard(
                'AR + Cash',
                ComplianceFormatters.percent(report.msciArCashRatio),
                report.msciArCashStatus,
                isDark,
              ),
              _msciCard(
                'Revenue Breakdown',
                'Halal ${ComplianceFormatters.percent(report.msciHalalPercent)}',
                'Pass',
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('MSCI: ',
                  style: TextStyle(fontFamily: Constants.FONT_DEFAULT_NEW)),
              isDark
                  ? ComplianceStatusBadge(label: report.msciStatus)
                  : _topBarCompliancePill(report.msciStatus),
              const SizedBox(width: 16),
              Text('Our Analysis: ',
                  style: TextStyle(fontFamily: Constants.FONT_DEFAULT_NEW)),
              isDark
                  ? ComplianceStatusBadge(label: report.status)
                  : _topBarCompliancePill(report.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _msciCard(String title, String value, String status, bool isDark) {
    return Container(
      width: isDark ? 220 : 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDark ? 10 : 8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: isDark ? 12 : 11,
              fontWeight: isDark ? FontWeight.w600 : FontWeight.w400,
              color: isDark ? null : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: isDark ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: isDark ? null : const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 6),
          isDark
              ? ComplianceStatusBadge(label: status, compact: true)
              : _statusTextOnly(status),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
      ComplianceReport report, Color secondary, bool isDark) {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: HomeUi.cardDecoration(isDark),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: HomeUi.tableToolbarHeader(
              isDark,
              icon: Icons.history_rounded,
              title: 'Historical Reports',
              subtitleText: 'Past compliance filings for this ticker',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: _buildHistoryTable(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<_HistoryTableColumn> _historyTableColumns() {
    return <_HistoryTableColumn>[
      _HistoryTableColumn(
        label: 'Report Date',
        width: 128,
        value: ComplianceHistoryFormatters.reportDate,
      ),
      _HistoryTableColumn(
        label: 'Fiscal Quarter',
        width: 158,
        value: ComplianceHistoryFormatters.fiscalQuarter,
      ),
      _HistoryTableColumn(
        label: 'Report Period',
        width: 118,
        value: ComplianceHistoryFormatters.reportPeriod,
      ),
      _HistoryTableColumn(
        label: 'Coverage From',
        width: 128,
        value: ComplianceHistoryFormatters.coverageFrom,
      ),
      _HistoryTableColumn(
        label: 'Coverage To',
        width: 128,
        value: ComplianceHistoryFormatters.coverageTo,
      ),
      _HistoryTableColumn(
        label: 'Ticker',
        width: 88,
        value: ComplianceHistoryFormatters.ticker,
      ),
      _HistoryTableColumn(
        label: 'Not Halal',
        width: 118,
        value: ComplianceHistoryFormatters.notHalalAmount,
        tone: _HistoryValueTone.negative,
        highlightWhen: (ComplianceHistoryItem item) => item.notHalalAmount > 0,
        align: TextAlign.right,
      ),
      _HistoryTableColumn(
        label: 'Doubtful',
        width: 118,
        value: ComplianceHistoryFormatters.doubtfulAmount,
        tone: _HistoryValueTone.warning,
        highlightWhen: (ComplianceHistoryItem item) => item.doubtfulAmount > 0,
        align: TextAlign.right,
      ),
      _HistoryTableColumn(
        label: 'Shares O/S',
        width: 126,
        value: ComplianceHistoryFormatters.sharesOutstanding,
        align: TextAlign.right,
      ),
      _HistoryTableColumn(
        label: 'Currency',
        width: 96,
        value: ComplianceHistoryFormatters.currency,
      ),
      _HistoryTableColumn(
        label: 'Created',
        width: 128,
        value: ComplianceHistoryFormatters.createdAt,
      ),
      _HistoryTableColumn(
        label: 'Status',
        width: 118,
        isStatus: true,
      ),
    ];
  }

  List<double> _historyColumnWidths(
    List<_HistoryTableColumn> columns,
    double targetWidth,
  ) {
    final double minTableWidth = columns.fold<double>(
      0,
      (double sum, _HistoryTableColumn column) => sum + column.width,
    );
    if (!targetWidth.isFinite || targetWidth <= minTableWidth) {
      return columns.map((_HistoryTableColumn c) => c.width).toList();
    }

    final double extra = targetWidth - minTableWidth;
    return columns
        .map(
          (_HistoryTableColumn column) =>
              column.width + extra * (column.width / minTableWidth),
        )
        .toList();
  }

  Widget _buildHistoryTable({
    required bool isDark,
  }) {
    final List<_HistoryTableColumn> columns = _historyTableColumns();
    final int lastIndex = columns.length - 1;
    final Color warning =
        isDark ? const Color(0xFFFBBF24) : ComplianceFormatters.doubtfulColor;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minTableWidth = columns.fold<double>(
          0,
          (double sum, _HistoryTableColumn column) => sum + column.width,
        );
        final double availableWidth = constraints.maxWidth;
        final double tableWidth = availableWidth.isFinite
            ? max(availableWidth, minTableWidth)
            : minTableWidth;
        final List<double> columnWidths =
            _historyColumnWidths(columns, tableWidth);

        Widget tableContent = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: HomeUi.tableHeaderBg(isDark),
                border: Border(
                  top: BorderSide(color: HomeUi.tableBorder(isDark)),
                  bottom: BorderSide(color: HomeUi.tableBorder(isDark)),
                ),
              ),
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < columns.length; i++)
                    SizedBox(
                      width: columnWidths[i],
                      child: _historyHeaderCell(
                        columns[i].label,
                        isDark: isDark,
                        padding: _historyCellPadding(i, lastIndex),
                        align: columns[i].align,
                      ),
                    ),
                ],
              ),
            ),
            ..._history
                .asMap()
                .entries
                .map((MapEntry<int, ComplianceHistoryItem> e) {
              final int index = e.key;
              final ComplianceHistoryItem item = e.value;
              final bool lastRow = index == _history.length - 1;

              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredHistoryRow = index),
                onExit: (_) {
                  if (_hoveredHistoryRow == index) {
                    setState(() => _hoveredHistoryRow = null);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 52,
                  decoration: BoxDecoration(
                    color: _hoveredHistoryRow == index
                        ? HomeUi.tableRowHover(isDark)
                        : Colors.transparent,
                    border: lastRow
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: HomeUi.tableBorder(isDark),
                            ),
                          ),
                  ),
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < columns.length; i++)
                        SizedBox(
                          width: columnWidths[i],
                          child: columns[i].isStatus
                              ? Padding(
                                  padding: _historyCellPadding(i, lastIndex),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _historyStatusChip(
                                      item.complianceStatus,
                                    ),
                                  ),
                                )
                              : _historyDataCell(
                                  columns[i].value!(item),
                                  isDark: isDark,
                                  padding: _historyCellPadding(i, lastIndex),
                                  color: _historyValueColor(
                                    columns[i],
                                    item,
                                    isDark,
                                    warning,
                                  ),
                                  align: columns[i].align,
                                ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );

        final Widget table = SizedBox(
          width: tableWidth,
          child: tableContent,
        );

        if (tableWidth > availableWidth) {
          return Scrollbar(
            controller: _historyScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 6,
            radius: const Radius.circular(999),
            child: SingleChildScrollView(
              controller: _historyScrollController,
              scrollDirection: Axis.horizontal,
              child: table,
            ),
          );
        }

        return table;
      },
    );
  }

  EdgeInsets _historyCellPadding(int index, int lastIndex) {
    return EdgeInsets.fromLTRB(
      index == 0 ? 16 : 12,
      0,
      index == lastIndex ? 16 : 12,
      0,
    );
  }

  Color? _historyValueColor(
    _HistoryTableColumn column,
    ComplianceHistoryItem item,
    bool isDark,
    Color warning,
  ) {
    if (column.tone == null) return null;
    if (column.highlightWhen?.call(item) != true) return null;
    switch (column.tone!) {
      case _HistoryValueTone.negative:
        return ComplianceFormatters.notHalalColor;
      case _HistoryValueTone.warning:
        return ComplianceFormatters.doubtfulColor;
    }
  }

  Widget _historyHeaderCell(
    String label, {
    required bool isDark,
    required EdgeInsets padding,
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      height: 46,
      child: Padding(
        padding: padding,
        child: Align(
          alignment: align == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            label.toUpperCase(),
            style: HomeUi.tableHeader(isDark),
            textAlign: align,
            softWrap: false,
          ),
        ),
      ),
    );
  }

  Widget _historyDataCell(
    String value, {
    required bool isDark,
    required EdgeInsets padding,
    Color? color,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: align == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          value,
          textAlign: align,
          style: color != null
              ? HomeUi.tableNumeric(isDark).copyWith(color: color)
              : align == TextAlign.right
                  ? HomeUi.tableNumeric(isDark)
                  : HomeUi.tableCell(isDark),
          softWrap: false,
        ),
      ),
    );
  }
}

class _HistoryTableColumn {
  const _HistoryTableColumn({
    required this.label,
    required this.width,
    this.value,
    this.tone,
    this.highlightWhen,
    this.isStatus = false,
    this.align = TextAlign.left,
  });

  final String label;
  final double width;
  final String Function(ComplianceHistoryItem item)? value;
  final _HistoryValueTone? tone;
  final bool Function(ComplianceHistoryItem item)? highlightWhen;
  final bool isStatus;
  final TextAlign align;
}

enum _HistoryValueTone { negative, warning }

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

enum _CalculationDialogType { business, securities, debt }

class _CalculationDialog extends StatelessWidget {
  const _CalculationDialog({
    required this.report,
    required this.type,
    required this.isDark,
  });

  final ComplianceReport report;
  final _CalculationDialogType type;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String status;
    final List<Widget> body;
    final IconData icon;

    switch (type) {
      case _CalculationDialogType.business:
        title = 'Not Halal Business Activity Percentage';
        status = report.revenueBreakdownStatus;
        body = _businessBody();
        icon = Icons.pie_chart_outline_rounded;
        break;
      case _CalculationDialogType.securities:
        title = 'Interest-bearing Securities and Assets Percentage';
        status = report.securitiesStatus;
        body = _securitiesBody();
        icon = Icons.account_balance_wallet_outlined;
        break;
      case _CalculationDialogType.debt:
        title = 'Interest-bearing Debt Percentage';
        status = report.debtStatus;
        body = _debtBody();
        icon = Icons.credit_score_outlined;
        break;
    }

    final Color accent = ComplianceFormatters.statusColor(status);

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
                          borderRadius:
                              BorderRadius.circular(HomeUi.radiusMd),
                        ),
                        child: Icon(icon, size: 20, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
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
                      children: body,
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

  bool _isPassStatus(String status) {
    final String normalized = status.toUpperCase();
    if (normalized.contains('NON') ||
        normalized.contains('FAIL') ||
        normalized.contains('NOT')) {
      return false;
    }
    return normalized.contains('COMPLIANT') || normalized.contains('PASS');
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

  Widget _formulaPanel({
    required String formulaLabel,
    required String numerator,
    required String denominator,
    required String result,
    required String threshold,
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
            child: _formulaFraction(
              numerator: numerator,
              denominator: denominator,
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
            child: Text(
              result,
              style: HomeUi.tableCellEmphasis(isDark).copyWith(
                fontSize: 14,
                height: 1.35,
              ),
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

  List<Widget> _businessBody() {
    final num numerator = report.notHalalRevenue + report.questionableRevenue;
    return <Widget>[
      _sectionCard(
        title: 'Breakdown',
        children: <Widget>[
          _breakdownRow('Halal Sales & Income',
              ComplianceFormatters.percent(report.halalPercent)),
          _breakdownRow('Doubtful Sales & Income',
              ComplianceFormatters.percent(report.questionablePercent)),
          _breakdownRow('Non Halal Sales & Income',
              ComplianceFormatters.percent(report.notHalalPercent)),
          _breakdownRow(
            'Total Revenue',
            '100%',
            emphasized: true,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _formulaPanel(
        formulaLabel: 'Not Halal Business Activity Percentage =',
        numerator: '( Not Halal Sales & Income + Doubtful Sales & Income )',
        denominator: '( Total Revenue )',
        result:
            '${ComplianceFormatters.compactMoney(numerator, fromOnes: true)} / ${ComplianceFormatters.compactMoney(report.totalRevenue, fromOnes: true)} = ${ComplianceFormatters.percent(report.businessActivityFailPercent)}',
        threshold: 'Threshold: 5.00%',
      ),
    ];
  }

  List<Widget> _securitiesBody() {
    return <Widget>[
      _sectionCard(
        title: 'Breakdown',
        children: <Widget>[
          if (report.securitiesShortTerm != null)
            _breakdownRow('Short-term',
                ComplianceFormatters.percent(report.securitiesShortTerm!.ratio)),
          if (report.securitiesLongTerm != null)
            _breakdownRow('Long-term',
                ComplianceFormatters.percent(report.securitiesLongTerm!.ratio)),
          _breakdownRow(
            'Interest-bearing securities and assets',
            ComplianceFormatters.percent(report.securitiesRatio),
            emphasized: true,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _formulaPanel(
        formulaLabel: 'Interest-bearing securities and assets percentage =',
        numerator: '( Interest-bearing securities and assets )',
        denominator: '( Trailing 36-month average market capitalization )',
        result:
            '${ComplianceFormatters.millions(report.securitiesTotalAmount)} / ${ComplianceFormatters.compactMoney(report.trailing36MonAvgCap, fromOnes: true)} = ${ComplianceFormatters.percent(report.securitiesRatio)}',
        threshold: 'Threshold: 30.00%',
      ),
    ];
  }

  List<Widget> _debtBody() {
    return <Widget>[
      _sectionCard(
        title: 'Breakdown',
        children: <Widget>[
          if (report.debtShortTerm != null)
            _breakdownRow('Short-term',
                ComplianceFormatters.percent(report.debtShortTerm!.ratio)),
          if (report.debtLongTerm != null)
            _breakdownRow('Long-term',
                ComplianceFormatters.percent(report.debtLongTerm!.ratio)),
          _breakdownRow(
            'Total Interest-bearing debt',
            ComplianceFormatters.percent(report.debtRatio),
            emphasized: true,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _formulaPanel(
        formulaLabel: 'Interest-bearing debt percentage =',
        numerator: '( Total interest-bearing debt )',
        denominator: '( Trailing 36-month average market capitalization )',
        result:
            '${ComplianceFormatters.millions(report.debtTotalAmount)} / ${ComplianceFormatters.compactMoney(report.trailing36MonAvgCap, fromOnes: true)} = ${ComplianceFormatters.percent(report.debtRatio)}',
        threshold: 'Threshold: 30.00%',
      ),
    ];
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

  Widget _formulaFraction({
    required String numerator,
    required String denominator,
  }) {
    return Column(
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
    );
  }
}
