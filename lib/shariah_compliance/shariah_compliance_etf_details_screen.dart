import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/Screens/etf_details_screen.dart';
import 'package:musaffa_terminal/models/etfs_data.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/models/etf_compliance_report.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_api_service.dart';
import 'package:musaffa_terminal/shariah_compliance/shariah_compliance_details_screen.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_detail_search.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/etf_compliance_details_content.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/web_service.dart';

class ShariahComplianceEtfDetailsScreen extends StatefulWidget {
  const ShariahComplianceEtfDetailsScreen({
    super.key,
    required this.tickerSymbol,
    this.companyName,
    this.ticker,
  });

  final String tickerSymbol;
  final String? companyName;
  final TickerModel? ticker;

  @override
  State<ShariahComplianceEtfDetailsScreen> createState() =>
      _ShariahComplianceEtfDetailsScreenState();
}

class _ShariahComplianceEtfDetailsScreenState
    extends State<ShariahComplianceEtfDetailsScreen> {
  final ShariahComplianceApiService _apiService = ShariahComplianceApiService();

  EtfComplianceReport? _report;
  EtfsData? _etfData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait<dynamic>([
      _apiService.fetchEtfCompliance(widget.tickerSymbol),
      _fetchEtfProfile(widget.tickerSymbol),
    ]);

    if (!mounted) return;

    final ShariahComplianceResult apiResult =
        results[0] as ShariahComplianceResult;
    setState(() {
      if (apiResult.isSuccess) {
        _report = EtfComplianceReport.fromJson(apiResult.data!);
      } else {
        _errorMessage = apiResult.errorMessage;
      }
      _etfData = results[1] as EtfsData?;
      _isLoading = false;
    });
  }

  Future<EtfsData?> _fetchEtfProfile(String symbol) async {
    try {
      final response = await WebService.getTypesense(
        <String>['collections', 'etfs_data', 'documents', 'search'],
        <String, String>{
          'q': '*',
          'per_page': '1',
          'include_fields':
              '\$etf_profile_collection_4(name,navCurrency,symbol,description)',
          'filter_by':
              '\$etf_profile_collection_4(id:*)&&id:=[`$symbol`]',
        },
      );

      if (response.statusCode != 200) return null;

      final dynamic data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final List<dynamic>? hits = data['hits'] as List<dynamic>?;
      if (hits == null || hits.isEmpty) return null;

      final Map<String, dynamic>? document =
          hits[0]['document'] as Map<String, dynamic>?;
      if (document == null) return null;

      return EtfsData.fromJson(document);
    } catch (_) {
      return null;
    }
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

  void _openEtfDetail() {
    final TickerModel ticker = widget.ticker ??
        TickerModel(
          symbol: widget.tickerSymbol,
          companyName: _report?.name ?? widget.companyName,
          name: _report?.name ?? widget.companyName,
          logo: widget.ticker?.logo,
          currentPrice: _etfData?.currentPrice,
          percentChange: _etfData?.change1DPercent,
          isStock: false,
        );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EtfDetailsScreen(ticker: ticker),
      ),
    );
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
              : _report == null
                  ? _buildError(primary, secondary)
                  : LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final EdgeInsets pagePadding =
                            HomeUi.pagePadding(constraints.maxWidth);
                        return Column(
                          children: [
                            _buildTopBar(isDark, secondary, pagePadding),
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
                                      EtfComplianceDetailsContent(
                                        report: _report!,
                                        tickerSymbol: widget.tickerSymbol,
                                        etfData: _etfData,
                                        ticker: widget.ticker,
                                        onOpenEtfDetail: _openEtfDetail,
                                      ),
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
            _errorMessage ??
                'Unable to load compliance data for ${widget.tickerSymbol}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: primary,
            ),
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

  Widget _buildTopBar(
    bool isDark,
    Color secondary,
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
}
