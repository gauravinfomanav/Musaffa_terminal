import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Controllers/fund_ownership_detail_controller.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/Screens/etf_details_screen.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/models/fund_ownership_model.dart';
import 'package:musaffa_terminal/models/institutional_investor_model.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class FundOwnershipDetailScreen extends StatefulWidget {
  const FundOwnershipDetailScreen({
    super.key,
    required this.fund,
    required this.holdingSymbol,
    required this.holdingName,
    this.currentPrice,
  });

  final FundOwnershipModel fund;
  final String holdingSymbol;
  final String holdingName;
  final double? currentPrice;

  @override
  State<FundOwnershipDetailScreen> createState() =>
      _FundOwnershipDetailScreenState();
}

class _FundOwnershipDetailScreenState extends State<FundOwnershipDetailScreen> {
  late final FundOwnershipDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FundOwnershipDetailController(
      fund: widget.fund,
      holdingSymbol: widget.holdingSymbol,
      holdingName: widget.holdingName,
      currentPrice: widget.currentPrice,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: HomeUi.pageBg(isDark),
      body: Column(
        children: <Widget>[
          HomeTabBar(
            showBackButton: true,
            onThemeToggle: () {
              final Brightness current = Theme.of(context).brightness;
              Get.changeThemeMode(
                current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (BuildContext context, Widget? child) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildHeader(isDark),
                      const SizedBox(height: 16),
                      _buildPositionCard(isDark),
                      const SizedBox(height: 16),
                      if (_controller.isLoading) ...<Widget>[
                        _shimmerCard(isDark),
                        const SizedBox(height: 16),
                        _shimmerCard(isDark, height: 220),
                      ] else ...<Widget>[
                        if (_controller.profile != null) ...<Widget>[
                          _buildProfileCard(isDark, _controller.profile!),
                          const SizedBox(height: 16),
                        ],
                        if (_controller.holdings.isNotEmpty) ...<Widget>[
                          _buildHoldingsTable(isDark),
                          const SizedBox(height: 16),
                        ],
                        if (_controller.relatedTickers.isNotEmpty)
                          _buildRelatedTickers(isDark)
                        else if (!_controller.isLoading &&
                            _controller.holdings.isEmpty)
                          _buildEmpty(isDark),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: HomeUi.cardDecoration(isDark),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: HomeUi.softBrandWellGradient,
            ),
            child: HomeUi.brandIcon(
              icon: Icons.account_balance_outlined,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.fund.name,
                  style: HomeUi.sectionTitle(isDark).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Institutional holder of ${widget.holdingSymbol}',
                  style: HomeUi.subtitle(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(bool isDark) {
    final FundOwnershipModel fund = widget.fund;
    final num prevShare = fund.share - fund.change;
    final num? positionValue =
        widget.currentPrice == null ? null : fund.share * widget.currentPrice!;
    final Color? changeColor = fund.change > 0
        ? HomeUi.positive(isDark)
        : fund.change < 0
            ? HomeUi.negative(isDark)
            : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.pie_chart_outline,
            title: 'Position in ${widget.holdingSymbol}',
            subtitleText: widget.holdingName,
          ),
          const SizedBox(height: 16),
          HomeUi.detailSummaryMetricsRow(
            dark: isDark,
            items: <({String label, String value, Color? valueColor})>[
              (
                label: 'Shares',
                value: getShortenedT(fund.share),
                valueColor: null,
              ),
              (
                label: 'Change',
                value: _signedCompact(fund.change),
                valueColor: changeColor,
              ),
              (
                label: 'Portfolio %',
                value: '${fund.portfolioPercent.toStringAsFixed(2)}%',
                valueColor: null,
              ),
              (
                label: 'Position value',
                value: positionValue == null
                    ? '--'
                    : valueWithCurrency(
                        price: positionValue,
                        currency: 'USD',
                        showCurrencySymbol: true,
                        shorten: true,
                      ),
                valueColor: null,
              ),
              (
                label: 'Filing date',
                value: FinnhubDisplayFormatters.formatDate(fund.filingDate),
                valueColor: null,
              ),
              (
                label: 'Prev. shares',
                value: prevShare > 0 ? getShortenedT(prevShare) : '--',
                valueColor: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, InstitutionalInvestorProfile profile) {
    final String philosophy = (profile.philosophy ?? '').trim();
    final String bio = (profile.profile ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.badge_outlined,
            title: profile.manager,
            subtitleText: [
              if ((profile.firmType ?? '').trim().isNotEmpty) profile.firmType,
              if (profile.cik.isNotEmpty) 'CIK ${profile.cik}',
            ].join('  ·  '),
          ),
          if (philosophy.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(philosophy, style: HomeUi.bodyText(isDark)),
          ],
          if (bio.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              bio,
              style: HomeUi.subtitle(isDark).copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHoldingsTable(bool isDark) {
    final List<InstitutionalHolding> holdings = _controller.holdings;
    final DateTime? reportDate = _controller.portfolio?.reportDate;

    return DynamicTable(
      title: 'Fund holdings',
      subtitle: reportDate == null
          ? 'Reported 13F positions'
          : 'Reported ${FinnhubDisplayFormatters.formatDate(reportDate)}',
      toolbarLeadingIcon: Icons.list_alt_outlined,
      showOuterShadow: true,
      considerPadding: false,
      showFixedColumn: true,
      tickerHeaderLabel: 'TICKER',
      enableLivePrices: false,
      zebraStripes: true,
      columns: const <SimpleColumn>[
        SimpleColumn(label: 'NAME', fieldName: 'name', width: 220),
        SimpleColumn(
          label: 'SHARES',
          fieldName: 'share',
          isNumeric: true,
          width: 110,
        ),
        SimpleColumn(
          label: 'CHANGE',
          fieldName: 'change',
          isNumeric: true,
          width: 100,
        ),
        SimpleColumn(
          label: 'PORTFOLIO %',
          fieldName: 'percentage',
          isNumeric: true,
          width: 110,
        ),
        SimpleColumn(
          label: 'VALUE',
          fieldName: 'value',
          isNumeric: true,
          width: 120,
        ),
      ],
      rows: holdings.map((InstitutionalHolding item) {
        return SimpleRowModel(
          symbol: item.symbol,
          name: item.name,
          fields: <String, dynamic>{
            'name': item.name,
            'share': getShortenedT(item.share),
            'change': _signedCompact(item.change),
            'percentage': '${item.percentage.toStringAsFixed(2)}%',
            'value': valueWithCurrency(
              price: item.value,
              currency: 'USD',
              showCurrencySymbol: true,
              shorten: true,
            ),
            'isStock': true,
          },
          changeColor: item.change > 0
              ? HomeUi.positive(isDark)
              : item.change < 0
                  ? HomeUi.negative(isDark)
                  : null,
        );
      }).toList(),
      onTickerTap: (row) {
        final String symbol = row.data['_ticker_symbol']?.toString() ?? '';
        final String name = row.data['_company_name']?.toString() ?? symbol;
        _openTicker(symbol, name);
      },
    );
  }

  Widget _buildRelatedTickers(bool isDark) {
    return DynamicTable(
      title: 'Related tickers',
      subtitle: 'Stocks and ETFs matching this fund name',
      toolbarLeadingIcon: Icons.search_outlined,
      showOuterShadow: true,
      considerPadding: false,
      showFixedColumn: true,
      tickerHeaderLabel: 'TICKER',
      enableLivePrices: false,
      zebraStripes: true,
      columns: const <SimpleColumn>[
        SimpleColumn(label: 'NAME', fieldName: 'name', width: 260),
        SimpleColumn(label: 'TYPE', fieldName: 'type', width: 90),
        SimpleColumn(
          label: 'PRICE',
          fieldName: 'price',
          isNumeric: true,
          width: 110,
        ),
      ],
      rows: _controller.relatedTickers.map((TickerModel ticker) {
        final String symbol =
            (ticker.symbol ?? ticker.ticker ?? '').trim().toUpperCase();
        final String name =
            ticker.companyName ?? ticker.name ?? ticker.stockName ?? symbol;
        return SimpleRowModel(
          symbol: symbol,
          name: name,
          logo: ticker.logo,
          price: ticker.currentPrice,
          fields: <String, dynamic>{
            'name': name,
            'type': ticker.isStock ? 'Stock' : 'ETF',
            'price': ticker.currentPrice == null
                ? '--'
                : valueWithCurrency(
                    price: ticker.currentPrice,
                    currency: ticker.currency ?? 'USD',
                    showCurrencySymbol: true,
                  ),
            'isStock': ticker.isStock,
          },
        );
      }).toList(),
      onTickerTap: (row) {
        final String symbol = row.data['_ticker_symbol']?.toString() ?? '';
        final bool isStock = row.data['_is_stock'] != false;
        final String name = row.data['_company_name']?.toString() ?? symbol;
        _openKnownTicker(
          TickerModel(
            symbol: symbol,
            ticker: symbol,
            name: name,
            companyName: name,
            isStock: isStock,
          ),
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: HomeUi.cardDecoration(isDark),
      child: Text(
        _controller.error ??
            'No related tickers or fund holdings were found for this holder.',
        style: HomeUi.subtitle(isDark),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _shimmerCard(bool isDark, {double height = 120}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: HomeUi.cardDecoration(isDark),
      child: ShimmerWidgets.box(
        width: double.infinity,
        height: height - 32,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  String _signedCompact(num value) {
    if (value == 0) return '0';
    final String sign = value > 0 ? '+' : '-';
    return '$sign${getShortenedT(value.abs())}';
  }

  Future<void> _openTicker(String symbol, String name) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;

    final List<TickerModel> results =
        await SearchService.searchStocks(normalized);
    TickerModel? match;
    for (final TickerModel ticker in results) {
      final String candidate =
          (ticker.symbol ?? ticker.ticker ?? '').trim().toUpperCase();
      if (candidate == normalized) {
        match = ticker;
        break;
      }
    }
    match ??= results.isNotEmpty
        ? results.first
        : TickerModel(
            symbol: normalized,
            ticker: normalized,
            name: name,
            companyName: name,
            isStock: true,
          );
    if (!mounted) return;
    _openKnownTicker(match);
  }

  void _openKnownTicker(TickerModel ticker) {
    FeatureNavigation.pushIfAllowed(
      context,
      ticker.isStock ? FeatureKeys.tickerDetails : FeatureKeys.etfDetails,
      ticker.isStock
          ? TickerDetailScreen(ticker: ticker)
          : EtfDetailsScreen(ticker: ticker),
    );
  }
}
