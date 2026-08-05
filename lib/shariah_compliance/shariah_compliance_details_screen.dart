import 'package:flutter/cupertino.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final Future<void> stockFuture =
        _stockController.fetchStockDetails(widget.tickerSymbol);
    final results = await Future.wait<dynamic>([
      _apiService.fetchCompliance(widget.tickerSymbol),
      _historyService.fetchHistory(widget.tickerSymbol),
      _historyDetailsService.fetchPeriods(widget.tickerSymbol),
      stockFuture,
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
      _stockData = _stockController.stockData.value;
      _isLoading = false;
    });
  }

  ComplianceReport? get _activeReport => _viewingHistorical
      ? _selectedHistoricalPeriod?.report
      : _currentReport;

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
    final Color bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final Color primary =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A);
    final Color secondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _exitScreening,
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentReport == null
                  ? _buildError(primary, secondary)
                  : Column(
                      children: [
                        _buildTopBar(primary, secondary, isDark),
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStockHeaderRow(primary, secondary, isDark),
                                  if (_historicalPeriods.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 16),
                                    ComplianceReportPeriodSelector(
                                      periods: _historicalPeriods,
                                      viewingHistorical: _viewingHistorical,
                                      selectedYear: _selectedHistoricalYear,
                                      selectedPeriodId:
                                          _selectedHistoricalPeriodId,
                                      onSelectCurrent: _selectCurrentReport,
                                      onSelectYear: _selectHistoricalYear,
                                      onSelectPeriod: _selectHistoricalPeriod,
                                      isDark: isDark,
                                      secondary: secondary,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  _buildMethodologySection(
                                    _activeReport!,
                                    isDark,
                                    showMsciPanel: _showMsciPanel,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildScreeningSection(_activeReport!, isDark),
                                  const SizedBox(height: 16),
                                  _buildRevenueSection(
                                    _activeReport!,
                                    primary,
                                    secondary,
                                    isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  // _buildMsciSection(_activeReport!, isDark),
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
        color: const Color.fromARGB(255, 0, 0, 0),
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _topBarCompliancePill(String status, {double fontSize = 13}) {
    final bool compliant = _isCompliantStatus(status);
    final Color bg =
        compliant ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ComplianceFormatters.statusLabel(status),
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
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

  String _fmtPrice(num? value) =>
      value != null ? '\$${value.toStringAsFixed(2)}' : '--';

  String _fmtPercent(num? value) =>
      value != null ? '${value.toStringAsFixed(2)}%' : '--';

  String _fmtNum(num? value, {int digits = 2}) =>
      value != null ? value.toStringAsFixed(digits) : '--';

  Widget _buildTopBar(Color primary, Color secondary, bool isDark) {
    final Color backColor =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 10),
      child: Row(
        children: [
          ComplianceOutlinedActionButton(
            onPressed: _goBack,
            label: 'Back',
            leadingIcon: Icons.arrow_back_rounded,
            color: backColor,
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
          ComplianceOutlinedActionButton(
            onPressed: _exitScreening,
            label: 'Exit',
            trailingIcon: Icons.close_rounded,
            color: secondary,
          ),
        ],
      ),
    );
  }

  Widget _stockInfoCard(bool isDark, Widget child) {
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
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                    (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockHeaderRow(Color primary, Color secondary, bool isDark) {
    final String name = _activeReport?.companyName ??
        widget.companyName ??
        widget.ticker?.companyName ??
        widget.ticker?.name ??
        '';
    final String status = _activeReport?.status ?? '';
    final String logo = widget.ticker?.logo ?? '';
    final StocksData? stock = _stockData;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _stockInfoCard(
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
                              name.isNotEmpty
                                  ? name
                                  : widget.tickerSymbol.toUpperCase(),
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
                                if (status.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  _inlineComplianceBadge(status),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openTickerDetail,
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
                              horizontal: 8, vertical: 4),
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
                            _fmtPrice(stock?.currentPrice),
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
                            stock?.change1DPercent != null
                                ? '${stock!.change1DPercent! >= 0 ? '+' : ''}${stock.change1DPercent!.toStringAsFixed(2)}%'
                                : '--',
                            style: DashboardTextStyles.stockName.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: stock?.change1DPercent != null
                                  ? (stock!.change1DPercent! >= 0
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
                        'Market Cap: ${stock?.usdMarketCap != null ? Constants.getShortenedMarketCapV2(stock!.usdMarketCap) : '--'}',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primary,
                        ),
                      ),
                      Text(
                        'Volume: ${stock?.volume != null ? '${((stock!.volume!) / 1000000).toStringAsFixed(1)}M' : '--'}',
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
            child: _stockInfoCard(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Overview',
                    style: DashboardTextStyles.stockName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                
                  _overviewRow(
                    'Industry:',
                    stock?.industry ?? '--',
                    isDark,
                  ),
                  _overviewRow(
                    'Shares Outstanding:',
                    stock?.sharesOutStanding != null
                        ? Constants.getShortenedMarketCapV2(
                                stock!.sharesOutStanding! * 1000000)
                            .replaceAll('\$', '')
                        : '--',
                    isDark,
                  ),
                  _overviewRow(
                    'IPO Date:',
                    stock?.ipoDate ?? '--',
                    isDark,
                  ),
                  _overviewRow('Beta:', _fmtNum(stock?.beta), isDark),
                  _overviewRow(
                    '52W High:',
                    _fmtPrice(stock?.d52WeekHigh),
                    isDark,
                  ),
                  // _overviewRow(
                  //   '52W Low:',
                  //   _fmtPrice(stock?.d52WeekLow),
                  //   isDark,
                  // ),
                  // _overviewRow(
                  //   'P/E Ratio:',
                  //   _fmtNum(stock?.peTTM),
                  //   isDark,
                  // ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _stockInfoCard(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Highlights',
                    style: DashboardTextStyles.stockName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _overviewRow(
                    'Book Value:',
                    stock?.bookValuePerShareAnnual != null
                        ? _fmtPrice(stock!.bookValuePerShareAnnual)
                        : '--',
                    isDark,
                  ),
                  _overviewRow(
                    'Cash/Share:',
                    stock?.cashPerSharePerShareAnnual != null
                        ? _fmtPrice(stock!.cashPerSharePerShareAnnual)
                        : '--',
                    isDark,
                  ),
                  _overviewRow(
                    'Dividend Yield:',
                    _fmtPercent(stock?.currentDividendYieldTTM),
                    isDark,
                  ),
                  _overviewRow(
                    'Enterprise Value:',
                    stock?.enterpriseValue != null
                        ? Constants.getShortenedMarketCapV2(stock!.enterpriseValue)
                        : '--',
                    isDark,
                  ),
                  _overviewRow(
                    'P/B Ratio:',
                    _fmtNum(stock?.pbAnnual),
                    isDark,
                  ),
                  // _overviewRow(
                  //   'ROE:',
                  //   stock?.rOE != null ? _fmtPercent(stock!.rOE) : '--',
                  //   isDark,
                  // ),
                  // _overviewRow(
                  //   'Gross Margin:',
                  //   stock?.grossMarginAnnual != null
                  //       ? _fmtPercent(stock!.grossMarginAnnual)
                  //       : '--',
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

  Widget _buildPercentCurrencyToggle(
      Color secondary, bool isDark, String sectionKey,
      {double fontSize = 13}) {
    final bool showPercent = _sectionShowPercent(sectionKey);
    return CupertinoSlidingSegmentedControl<bool>(
      padding: const EdgeInsets.all(2),
      groupValue: showPercent,
      thumbColor: isDark ? const Color(0xFF4B5563) : CupertinoColors.white,
      backgroundColor: isDark
          ? const Color(0xFF1F2937)
          : const Color(0xFFE5E7EB),
      children: <bool, Widget>{
        true: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            '%',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: fontSize,
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
              fontSize: fontSize,
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
        Expanded(
            child: _sectionLabel(title, isDark, fontSize: labelFontSize)),
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
      color: isDark
          ? const Color(0xFF6B7280).withOpacity(0.35)
          : const Color(0xFF6B7280).withOpacity(0.4),
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
                    color: const Color(0xFF3B82F6),
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
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_outward,
                          size: 12,
                          color: Color(0xFF3B82F6),
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
                    color: const Color(0xFF3B82F6),
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
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: isDark ? 11 : 10,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: isDark ? 13 : 12,
            fontWeight: FontWeight.w600,
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
          _sectionLabel('Screening Overview', isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _methodologyPanel(
                  title: 'Our Analysis',
                  status: report.status,
                  isDark: isDark,
                  accent: const Color(0xFF16A34A),
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
                            valueColor: const Color(0xFF16A34A),
                          ),
                          _PanelLine(
                            label: 'Not Halal',
                            value: ComplianceFormatters.percent(
                                report.notHalalPercent),
                            valueColor: const Color(0xFFDC2626),
                          ),
                        ],
                ),
              ),
              if (showMsciPanel) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: _methodologyPanel(
                    title: 'MSCI',
                    status: report.msciStatus,
                    isDark: isDark,
                    accent: const Color(0xFFDC2626),
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
                                      ? const Color(0xFFDC2626)
                                      : null,
                            ),
                            _PanelLine(
                              label: 'IB Debt',
                              value: ComplianceFormatters.percent(
                                  report.msciDebtRatio),
                              valueColor: _isFailStatus(report.msciDebtStatus)
                                  ? const Color(0xFFDC2626)
                                  : null,
                            ),
                          ],
                  ),
                ),
              ],
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
    List<String>? lines,
    List<_PanelLine>? structuredLines,
  }) {
    if (isDark) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.25)),
          color: accent.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                ComplianceStatusBadge(
                  label: status,
                  compact: true,
                  fontSize: 13,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lines!.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line,
                    style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
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
          ...structuredLines!.map(_panelDataLine),
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

  Widget _buildScreeningSection(ComplianceReport report, bool isDark) {
    final Color secondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

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
                  secondary: secondary,
                  onViewCalculation: () => _showCalculationDialog(
                    report,
                    _CalculationDialogType.business,
                    isDark,
                  ),
                  child: _buildBusinessScreeningContent(report, isDark),
                ),
                const SizedBox(width: 10),
                _screeningColumn(
                  title: 'IB Securities',
                  status: report.securitiesStatus,
                  isDark: isDark,
                  secondary: secondary,
                  toggleSectionKey: 'securities',
                  onViewCalculation: () => _showCalculationDialog(
                    report,
                    _CalculationDialogType.securities,
                    isDark,
                  ),
                  child: _buildSecuritiesScreeningContent(report, isDark),
                ),
                const SizedBox(width: 10),
                _screeningColumn(
                  title: 'IB Debt',
                  status: report.debtStatus,
                  isDark: isDark,
                  secondary: secondary,
                  toggleSectionKey: 'debt',
                  onViewCalculation: () => _showCalculationDialog(
                    report,
                    _CalculationDialogType.debt,
                    isDark,
                  ),
                  child: _buildDebtScreeningContent(report, isDark),
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
    required Color secondary,
    required Widget child,
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
                if (toggleSectionKey != null)
                  _buildPercentCurrencyToggle(
                      secondary, isDark, toggleSectionKey,
                      fontSize: 14),
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

  Widget _buildBusinessScreeningContent(ComplianceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ComplianceDonutChart(
            halal: report.halalPercent.toDouble(),
            doubtful: report.questionablePercent.toDouble(),
            notHalal: report.notHalalPercent.toDouble(),
            halalColor: const Color(0xFF16A34A),
            doubtfulColor: const Color(0xFFF59E0B),
            notHalalColor: const Color(0xFFDC2626),
            size: isDark ? 180 : 190,
            bottomSpacing: 20,
          ),
        ),
        const SizedBox(height: 4),
        _legendRow('Halal Sales & Income', report.halalPercent,
            const Color(0xFF16A34A), isDark),
        _legendRow('Doubtful Sales & Income', report.questionablePercent,
            const Color(0xFFF59E0B), isDark),
        _legendRow('Non Halal Sales & Income', report.notHalalPercent,
            const Color(0xFFDC2626), isDark),
        const Spacer(),
        Text(
          'Not Halal Business Activity Percentage must not exceed 5% of Total Revenue.',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 14,
            color: const Color(0xFF6B7280),
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
            passColor: const Color(0xFF16A34A),
            failColor: const Color(0xFFDC2626),
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
        const SizedBox(height: 8),
        if (report.securitiesLongTerm != null) ...[
          const SizedBox(height: 8),
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
            passColor: const Color(0xFF16A34A),
            failColor: const Color(0xFFDC2626),
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
        const SizedBox(height: 8),
        if (report.debtLongTerm != null) ...[
          const SizedBox(height: 8),
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
    final Color statusColor =
        pass ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final double clampedValue = value.clamp(0.0, 100.0);
    final double thresholdFactor = (threshold / 100).clamp(0.0, 1.0);
    final double fillFactor = (clampedValue / 100).clamp(0.0, 1.0);
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
                height: 8,
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
                '$numeratorLabel ÷ Trailing 36M Avg Market Cap',
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

  Widget _legendRow(String label, num value, Color color, bool isDark) {
    if (!isDark) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(width: 8, height: 8, color: color),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
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
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 14)),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
              ],
            ),
          ),
          ...term.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
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
        ],
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpanded(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
        if (expanded)
          ...term.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
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
      ],
    );
  }

  Widget _buildRevenueSection(
      ComplianceReport report, Color primary, Color secondary, bool isDark) {
    final bool showPercent = _sectionShowPercent('revenue');
    return ComplianceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithToggle(
            'Revenue Breakdown',
            isDark,
            secondary,
            sectionKey: 'revenue',
            labelFontSize: isDark ? 18 : 16,
            toggleFontSize: 15,
          ),
          SizedBox(height: isDark ? 12 : 8),
          _revenueGroupHeader(
              'Halal Revenue',
              report.halalPercent,
              const Color(0xFFDCFCE7),
              const Color(0xFF166534),
              const Color(0xFF16A34A),
              isDark),
          ...report.revenueItems
              .where((e) => e.selector.toUpperCase().contains('COMPLIANT'))
              .map((item) =>
                  _revenueRow(item, primary, secondary, isDark, showPercent)),
          SizedBox(height: isDark ? 8 : 4),
          _revenueGroupHeader(
              'Not Halal Revenue',
              report.notHalalPercent,
              const Color(0xFFFEE2E2),
              const Color(0xFF991B1B),
              const Color(0xFFDC2626),
              isDark),
          ...report.revenueItems
              .where((e) => !e.selector.toUpperCase().contains('COMPLIANT'))
              .map((item) =>
                  _revenueRow(item, primary, secondary, isDark, showPercent)),
          if (report.interestIncomeItems.isNotEmpty) ...[
            SizedBox(height: isDark ? 8 : 4),
            _revenueGroupHeader(
                'Other Income',
                report.notHalalPercent,
                const Color(0xFFFEE2E2),
                const Color(0xFF991B1B),
                const Color(0xFFDC2626),
                isDark),
            ...report.interestIncomeItems.map((item) =>
                _revenueRow(item, primary, secondary, isDark, showPercent)),
          ],
        ],
      ),
    );
  }

  Widget _revenueGroupHeader(String title, num percent, Color bg, Color fg,
      Color borderAccent, bool isDark) {
    if (isDark) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(title,
                style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fg)),
            const Spacer(),
            Text(ComplianceFormatters.percent(percent),
                style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fg)),
          ],
        ),
      );
    }

    return Container(
      height: isDark ? null : 30,
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isDark ? 6 : 2),
      padding: EdgeInsets.fromLTRB(12, 0, 12, isDark ? 0 : 0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: borderAccent, width: 3),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            ComplianceFormatters.percent(percent),
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTextBadge(String selector) {
    final String normalized = selector.toUpperCase();
    Color color;
    if (normalized.contains('COMPLIANT') && !normalized.contains('NON')) {
      color = const Color(0xFF16A34A);
    } else {
      color = const Color(0xFFDC2626);
    }
    return Text(
      ComplianceFormatters.statusLabel(selector),
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  bool _revenueRowCanExpand(ComplianceLineItem item) {
    return (item.comment?.isNotEmpty ?? false) || item.items.isNotEmpty;
  }

  Widget _revenueRow(ComplianceLineItem item, Color primary, Color secondary,
      bool isDark, bool showPercent) {
    final String key = '${item.id}-${item.name}';
    final bool expanded = _expandedRows.contains(key);
    final bool canExpand = _revenueRowCanExpand(item);
    return Column(
      children: [
        InkWell(
          onTap: canExpand ? () => _toggleExpanded(key) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isDark ? 10 : 0,
              horizontal: isDark ? 4 : 0,
            ),
            child: SizedBox(
              height: isDark ? null : 34,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 15,
                        color: primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: isDark ? 2 : 1,
                    child: Text(
                      showPercent
                          ? ComplianceFormatters.percent(item.percentage)
                          : formatLineAmount(item, showPercent: false),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 15,
                        fontWeight: isDark ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  isDark
                      ? ComplianceStatusBadge(
                          label: item.selector,
                          compact: true,
                          fontSize: 13,
                        )
                      : _statusTextBadge(item.selector),
                  if (canExpand)
                    Icon(
                      isDark
                          ? (expanded ? Icons.expand_less : Icons.expand_more)
                          : Icons.chevron_right,
                      size: isDark ? 18 : 16,
                      color: secondary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (expanded && canExpand) ...[
          if (item.comment?.isNotEmpty ?? false)
            isDark
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.comment!,
                      style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 14,
                          color: secondary),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 0, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.comment!,
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
          ...item.items.map(
            (nested) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 0, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nested.name,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 14,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Divider(
          height: 1,
          color: isDark ? null : const Color(0xFFF3F4F6),
        ),
      ],
    );
  }

  Widget _statusTextOnly(String status) {
    final bool pass = !_isFailStatus(status);
    return Text(
      ComplianceFormatters.statusLabel(status),
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: pass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
                  border: isDark
                      ? null
                      : Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Text(
                  'External methodology',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF3B82F6),
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

    return ComplianceSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _sectionLabel('Historical Reports', isDark),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return _buildHistoryTable(
                  isDark: isDark,
                  secondary: secondary,
                  tableWidth: constraints.maxWidth,
                );
              },
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
        flex: 12,
        value: ComplianceHistoryFormatters.reportDate,
      ),
      _HistoryTableColumn(
        label: 'Fiscal Quarter',
        flex: 14,
        value: ComplianceHistoryFormatters.fiscalQuarter,
      ),
      _HistoryTableColumn(
        label: 'Report Period',
        flex: 11,
        value: ComplianceHistoryFormatters.reportPeriod,
      ),
      _HistoryTableColumn(
        label: 'Coverage From',
        flex: 12,
        value: ComplianceHistoryFormatters.coverageFrom,
      ),
      _HistoryTableColumn(
        label: 'Coverage To',
        flex: 12,
        value: ComplianceHistoryFormatters.coverageTo,
      ),
      _HistoryTableColumn(
        label: 'Ticker',
        flex: 8,
        value: ComplianceHistoryFormatters.ticker,
      ),
      _HistoryTableColumn(
        label: 'Not Halal',
        flex: 11,
        value: ComplianceHistoryFormatters.notHalalAmount,
        valueColor: (ComplianceHistoryItem item) =>
            item.notHalalAmount > 0 ? const Color(0xFFDC2626) : null,
      ),
      _HistoryTableColumn(
        label: 'Doubtful',
        flex: 11,
        value: ComplianceHistoryFormatters.doubtfulAmount,
        valueColor: (ComplianceHistoryItem item) =>
            item.doubtfulAmount > 0 ? const Color(0xFFF59E0B) : null,
      ),
      _HistoryTableColumn(
        label: 'Shares O/S',
        flex: 11,
        value: ComplianceHistoryFormatters.sharesOutstanding,
      ),
      _HistoryTableColumn(
        label: 'Currency',
        flex: 8,
        value: ComplianceHistoryFormatters.currency,
      ),
      _HistoryTableColumn(
        label: 'Created',
        flex: 12,
        value: ComplianceHistoryFormatters.createdAt,
      ),
      _HistoryTableColumn(
        label: 'Status',
        flex: 12,
        isStatus: true,
      ),
    ];
  }

  Widget _buildHistoryTable({
    required bool isDark,
    required Color secondary,
    required double tableWidth,
  }) {
    final List<_HistoryTableColumn> columns = _historyTableColumns();
    final TextStyle headerStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: isDark ? 13 : 12,
      color: isDark ? secondary : const Color(0xFF9CA3AF),
      letterSpacing: 0.5,
      fontWeight: FontWeight.w600,
    );
    final TextStyle dataStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 14,
      color: isDark ? const Color(0xFFE5E7EB) : null,
    );
    final Color borderColor =
        isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final Color stripeA =
        isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB);
    final Color stripeB = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return SizedBox(
      width: tableWidth,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: columns
                  .map(
                    (_HistoryTableColumn column) => Expanded(
                      flex: column.flex,
                      child: _historyHeaderCell(
                        column.label,
                        headerStyle,
                        isDark: isDark,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ..._history.asMap().entries.map((MapEntry<int, ComplianceHistoryItem> e) {
            final int index = e.key;
            final ComplianceHistoryItem item = e.value;

            return Container(
              height: 48,
              color: index.isEven ? stripeA : stripeB,
              child: Row(
                children: columns.map((_HistoryTableColumn column) {
                  if (column.isStatus) {
                    return Expanded(
                      flex: column.flex,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: isDark
                              ? ComplianceStatusBadge(
                                  label: item.complianceStatus,
                                  compact: true,
                                  fontSize: 15,
                                )
                              : _topBarCompliancePill(
                                  item.complianceStatus,
                                  fontSize: 15,
                                ),
                        ),
                      ),
                    );
                  }

                  final Color? color = column.valueColor?.call(item);
                  return Expanded(
                    flex: column.flex,
                    child: _historyDataCell(
                      column.value!(item),
                      dataStyle: dataStyle.copyWith(color: color),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _historyHeaderCell(
    String label,
    TextStyle style, {
    required bool isDark,
  }) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isDark ? label : label.toUpperCase(),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _historyDataCell(
    String value, {
    required TextStyle dataStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: dataStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _HistoryTableColumn {
  const _HistoryTableColumn({
    required this.label,
    required this.flex,
    this.value,
    this.valueColor,
    this.isStatus = false,
  });

  final String label;
  final int flex;
  final String Function(ComplianceHistoryItem item)? value;
  final Color? Function(ComplianceHistoryItem item)? valueColor;
  final bool isStatus;
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
    final Color bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final Color border =
        isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final String title;
    final String status;
    final List<Widget> body;

    switch (type) {
      case _CalculationDialogType.business:
        title = 'Not Halal Business Activity Percentage';
        status = report.revenueBreakdownStatus;
        body = _businessBody();
        break;
      case _CalculationDialogType.securities:
        title = 'Interest-bearing Securities and Assets Percentage';
        status = report.securitiesStatus;
        body = _securitiesBody();
        break;
      case _CalculationDialogType.debt:
        title = 'Interest-bearing Debt Percentage';
        status = report.debtStatus;
        body = _debtBody();
        break;
    }

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ComplianceStatusBadge(
                          label: status,
                          compact: true,
                          fontSize: 13,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _businessBody() {
    final num numerator =
        report.notHalalRevenue + report.questionableRevenue;
    return <Widget>[
      _breakdownRow(
          'Halal Sales & Income', ComplianceFormatters.percent(report.halalPercent)),
      _breakdownRow('Doubtful Sales & Income',
          ComplianceFormatters.percent(report.questionablePercent)),
      _breakdownRow('Non Halal Sales & Income',
          ComplianceFormatters.percent(report.notHalalPercent)),
      _breakdownRow('Total Revenue', '100%'),
      const SizedBox(height: 16),
      _formulaTitle('Not Halal Business Activity Percentage ='),
      const SizedBox(height: 8),
      _formulaFraction(
        numerator:
            '( Not Halal Sales & Income + Doubtful Sales & Income )',
        denominator: '( Total Revenue )',
      ),
      const SizedBox(height: 12),
      _resultLine(
        '${ComplianceFormatters.compactMoney(numerator, fromOnes: true)} / ${ComplianceFormatters.compactMoney(report.totalRevenue, fromOnes: true)} = ${ComplianceFormatters.percent(report.businessActivityFailPercent)}',
      ),
      const SizedBox(height: 8),
      _thresholdLine('Threshold: 5.00%'),
    ];
  }

  List<Widget> _securitiesBody() {
    return <Widget>[
      if (report.securitiesShortTerm != null)
        _breakdownRow('Short-term',
            ComplianceFormatters.percent(report.securitiesShortTerm!.ratio)),
      if (report.securitiesLongTerm != null)
        _breakdownRow('Long-term',
            ComplianceFormatters.percent(report.securitiesLongTerm!.ratio)),
      _breakdownRow(
        'Interest-bearing securities and assets',
        ComplianceFormatters.percent(report.securitiesRatio),
      ),
      const SizedBox(height: 16),
      _formulaTitle('Interest-bearing securities and assets percentage ='),
      const SizedBox(height: 8),
      _formulaFraction(
        numerator: '( Interest-bearing securities and assets )',
        denominator:
            '( Trailing 36-month average market capitalization )',
      ),
      const SizedBox(height: 12),
      _resultLine(
        '${ComplianceFormatters.millions(report.securitiesTotalAmount)} / ${ComplianceFormatters.compactMoney(report.trailing36MonAvgCap, fromOnes: true)} = ${ComplianceFormatters.percent(report.securitiesRatio)}',
      ),
      const SizedBox(height: 8),
      _thresholdLine('Threshold: 30.00%'),
    ];
  }

  List<Widget> _debtBody() {
    return <Widget>[
      if (report.debtShortTerm != null)
        _breakdownRow('Short-term',
            ComplianceFormatters.percent(report.debtShortTerm!.ratio)),
      if (report.debtLongTerm != null)
        _breakdownRow(
            'Long-term', ComplianceFormatters.percent(report.debtLongTerm!.ratio)),
      _breakdownRow(
        'Total Interest-bearing debt',
        ComplianceFormatters.percent(report.debtRatio),
      ),
      const SizedBox(height: 16),
      _formulaTitle('Interest-bearing debt percentage ='),
      const SizedBox(height: 8),
      _formulaFraction(
        numerator: '( Total interest-bearing debt )',
        denominator:
            '( Trailing 36-month average market capitalization )',
      ),
      const SizedBox(height: 12),
      _resultLine(
        '${ComplianceFormatters.millions(report.debtTotalAmount)} / ${ComplianceFormatters.compactMoney(report.trailing36MonAvgCap, fromOnes: true)} = ${ComplianceFormatters.percent(report.debtRatio)}',
      ),
      const SizedBox(height: 8),
      _thresholdLine('Threshold: 30.00%'),
    ];
  }

  Widget _breakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 13,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
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
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          ),
        ),
        Text(
          denominator,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _resultLine(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _thresholdLine(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      ),
    );
  }
}
