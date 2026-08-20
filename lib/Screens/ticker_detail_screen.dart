import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/trading_view_widget.dart';
import 'package:musaffa_terminal/Components/simple_news_widget.dart';
import 'package:musaffa_terminal/Components/super_investors_section.dart';
import 'package:musaffa_terminal/Components/recommendation_widget.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/add_to_watchlist_button.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/Controllers/financial_fundamentals_controller.dart';
import 'package:musaffa_terminal/Controllers/trading_view_controller.dart';
import 'package:musaffa_terminal/Components/research_notes_panel_content.dart';
import 'package:musaffa_terminal/Controllers/research_notes_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_earnings_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_dividend_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_peer_comparison_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_insider_trading_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_news_sentiment_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_fund_ownership_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_price_target_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_youtube_videos_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_profile_controller.dart';
import 'package:musaffa_terminal/Components/ticker_about_company_tab.dart';
import 'package:musaffa_terminal/Components/ticker_upcoming_earnings_card.dart';
import 'package:musaffa_terminal/Components/ticker_earnings_history_section.dart';
import 'package:musaffa_terminal/Components/ticker_dividend_history_section.dart';
import 'package:musaffa_terminal/Components/ticker_peer_comparison_section.dart';
import 'package:musaffa_terminal/Components/ticker_insider_trading_section.dart';
import 'package:musaffa_terminal/Components/ticker_news_sentiment_section.dart';
import 'package:musaffa_terminal/Components/ticker_fund_ownership_section.dart';
import 'package:musaffa_terminal/Components/ticker_price_target_section.dart';
import 'package:musaffa_terminal/charts/widgets/ticker_charts_tab_content.dart';
import 'package:musaffa_terminal/charts/widgets/ticker_custom_charts_tab_content.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_financials_screen.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/live_price_service.dart';
import 'package:musaffa_terminal/services/websocket_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/models/live_price_model.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'dart:async';

class TickerDetailScreen extends StatefulWidget {
  final TickerModel ticker;

  const TickerDetailScreen({Key? key, required this.ticker}) : super(key: key);

  @override
  State<TickerDetailScreen> createState() => _TickerDetailScreenState();
}

class _TickerDetailScreenState extends State<TickerDetailScreen> {
  late StockDetailsController controller;
  late RecommendationController recommendationController;
  late FinancialFundamentalsController financialFundamentalsController;
  late TradingViewController tradingViewController;
  late WatchlistController watchlistController;
  late ResearchNotesController researchNotesController;
  late TickerEarningsController tickerEarningsController;
  late TickerDividendController tickerDividendController;
  late TickerPeerComparisonController tickerPeerComparisonController;
  late TickerInsiderTradingController tickerInsiderTradingController;
  late TickerNewsSentimentController tickerNewsSentimentController;
  late TickerFundOwnershipController tickerFundOwnershipController;
  late TickerPriceTargetController tickerPriceTargetController;
  late StockYouTubeVideosController stockYouTubeVideosController;
  late StockProfileController stockProfileController;

  late LivePriceService _livePriceService;
  late WebSocketService _webSocketService;
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();
  int _selectedTabIndex =
      0; // 0 Overview, 1 Financial, 2 Charts, 3 Custom Charts, 4 About Company
  bool _isInWatchlist = false;

  bool _isResearchNotesOpen = false;

  // Live price state
  double? _livePrice;
  double? _previousPrice;
  StreamSubscription<Map<String, LivePriceData>>? _priceStreamSubscription;
  StreamSubscription? _stockDataSubscription;
  StreamSubscription? _watchlistStocksSubscription;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(StockDetailsController());
    recommendationController = RecommendationController();
    financialFundamentalsController = FinancialFundamentalsController();
    tradingViewController = TradingViewController();
    watchlistController = Get.put(WatchlistController());
    researchNotesController = Get.put(ResearchNotesController());
    tickerEarningsController = TickerEarningsController();
    tickerDividendController = TickerDividendController();
    tickerPeerComparisonController = TickerPeerComparisonController();
    tickerInsiderTradingController = TickerInsiderTradingController();
    tickerNewsSentimentController = TickerNewsSentimentController();
    tickerFundOwnershipController = TickerFundOwnershipController();
    tickerPriceTargetController = TickerPriceTargetController();
    stockYouTubeVideosController = StockYouTubeVideosController();
    stockProfileController = StockProfileController();

    _livePriceService = Get.find<LivePriceService>();
    _webSocketService = Get.find<WebSocketService>();

    // Listen to watchlist changes to update button state
    _watchlistStocksSubscription =
        watchlistController.watchlistStocks.listen((_) {
      _checkIfStockInWatchlist();
    });

    // Check if stock is already in watchlist
    _checkIfStockInWatchlist();

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticker = widget.ticker.symbol ?? widget.ticker.ticker ?? '';
      controller.fetchStockDetails(ticker);
      researchNotesController.fetchNotes(ticker);
      recommendationController.fetchRecommendation(ticker);
      tickerEarningsController.load(ticker);
      tickerDividendController.load(ticker);
      tickerPeerComparisonController.load(ticker);
      tickerInsiderTradingController.load(ticker);
      tickerNewsSentimentController.load(ticker);
      tickerFundOwnershipController.load(ticker);
      tickerPriceTargetController.load(ticker);

      _setupLivePrices(ticker);
    });
  }

  void _setupLivePrices(String ticker) {
    // Store initial price from Typesense
    _stockDataSubscription?.cancel();
    _stockDataSubscription = controller.stockData.listen((stockData) {
      if (stockData != null && stockData.currentPrice != null) {
        if (!mounted || _isDisposing) return;
        if (mounted) {
          setState(() {
            _previousPrice = stockData.currentPrice!.toDouble();
            _livePrice = stockData.currentPrice!.toDouble();
            _webSocketService.setTypesensePrices({ticker: _livePrice!});
          });
        }
      }
    });

    // Add ticker to visible list for live updates
    _livePriceService.addVisibleTickers([ticker]);

    // Listen to live price updates
    _priceStreamSubscription?.cancel();
    _priceStreamSubscription = _webSocketService.priceStream.listen(
      (livePrices) {
        if (!mounted || _isDisposing) return;
        if (mounted) {
          final livePriceData = livePrices[ticker];
          if (livePriceData != null) {
            setState(() {
              _previousPrice = _livePrice;
              _livePrice = livePriceData.price;
            });
          }
        }
      },
      onError: (error) {
        // Handle error silently
      },
    );
  }

  @override
  void dispose() {
    _isDisposing = true;
    _priceStreamSubscription?.cancel();
    _stockDataSubscription?.cancel();
    _watchlistStocksSubscription?.cancel();
    final ticker = widget.ticker.symbol ?? widget.ticker.ticker ?? '';
    if (ticker.isNotEmpty) {
      _livePriceService.removeVisibleTickers([ticker]);
    }
    recommendationController.dispose();
    tickerEarningsController.dispose();
    tickerDividendController.dispose();
    tickerPeerComparisonController.dispose();
    tickerInsiderTradingController.dispose();
    tickerNewsSentimentController.dispose();
    tickerFundOwnershipController.dispose();
    tickerPriceTargetController.dispose();
    stockYouTubeVideosController.dispose();
    stockProfileController.dispose();
    financialFundamentalsController.dispose();
    tradingViewController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() {
    // When opening the watchlist, reset to default watchlist
    if (!_watchlistService.isWatchlistOpen.value) {
      watchlistController.resetToDefaultWatchlist();
    }
    _watchlistService.toggleWatchlist();
  }

  void _checkIfStockInWatchlist() {
    final currentTicker = widget.ticker.symbol ?? widget.ticker.ticker ?? '';

    // Check if stock is in the current watchlist's stocks
    final isInCurrentWatchlist = watchlistController.watchlistStocks
        .any((stock) => stock.ticker == currentTicker);

    // Also check if it's in any of the user's watchlists
    bool isInAnyWatchlist = false;
    for (final watchlist in watchlistController.watchlists) {
      // This is a simplified check - in a real implementation, you might want to
      // check each watchlist's stocks individually
      if (watchlist.stockCount > 0) {
        // For now, we'll rely on the current watchlist check
        // In a more robust implementation, you'd check each watchlist
        isInAnyWatchlist = isInCurrentWatchlist;
        break;
      }
    }

    if (!mounted || _isDisposing) return;
    if (mounted) {
      setState(() {
        _isInWatchlist = isInCurrentWatchlist || isInAnyWatchlist;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  Future<void> _openResearchNotesPanel() async {
    final ticker = widget.ticker.symbol ?? widget.ticker.ticker ?? '';
    if (ticker.isNotEmpty) {
      await researchNotesController.fetchNotes(ticker);
    }
    if (!mounted) return;
    setState(() => _isResearchNotesOpen = true);
  }

  void _closeResearchNotesPanel() {
    if (!_isResearchNotesOpen || !mounted) return;
    setState(() => _isResearchNotesOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FeatureGuard(
      featureKey: FeatureKeys.tickerDetails,
      child: Scaffold(
        backgroundColor: HomeUi.pageBg(isDarkMode),
        body: Stack(
          children: [
            Column(
              children: [
                Obx(() => HomeTabBar(
                      showBackButton: true,
                      isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
                      onWatchlistToggle: _toggleWatchlist,
                      onThemeToggle: () {
                        final currentTheme = Theme.of(context).brightness;
                        Get.changeThemeMode(
                          currentTheme == Brightness.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        );
                      },
                    )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildSectionTabs(isDarkMode),
                          const Spacer(),
                          _buildResearchNotesButton(isDarkMode),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (_selectedTabIndex) {
                    0 => _buildOverviewTab(isDarkMode),
                    1 => _buildFinancialTab(isDarkMode),
                    2 => _buildChartsTab(isDarkMode),
                    3 => _buildCustomChartsTab(isDarkMode),
                    _ => _buildAboutCompanyTab(isDarkMode),
                  },
                ),
              ],
            ),

            // Watchlist sidebar overlay - positioned relative to entire screen
            Obx(() {
              if (!_watchlistService.isWatchlistOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleWatchlist, // Close when tapping outside
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              Container(), // Empty space that closes sidebar when tapped
                        ),
                        GestureDetector(
                          onTap:
                              () {}, // Prevent closing when tapping on sidebar itself
                          child: WatchlistSidebar(
                            isDarkMode: isDarkMode,
                            onClose: _toggleWatchlist,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_isResearchNotesOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeResearchNotesPanel,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.24),
                  ),
                ),
              ),
            if (_isResearchNotesOpen)
              Positioned(
                top: 112,
                right: 20,
                child: _ResearchNotesOverlayCard(
                  isDarkMode: isDarkMode,
                  title: 'Research Notes',
                  subtitle: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                  onClose: _closeResearchNotesPanel,
                  child: ResearchNotesPanelContent(
                    ticker: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                    controller: researchNotesController,
                    onAddNote: () => _showAddNoteDialog(isDarkMode),
                  ),
                ),
              ),
            // Global FAB Overlay
            const GlobalFABOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTabs(bool isDarkMode) {
    const tabs = [
      'Overview',
      'Financial',
      'Charts',
      'Custom Charts',
      'About Company',
    ];
    return SizedBox(
      width: 620,
      child: HomeUi.segmentedControl(
        dark: isDarkMode,
        options: tabs,
        selectedIndex: _selectedTabIndex,
        onChanged: (index) => setState(() => _selectedTabIndex = index),
      ),
    );
  }

  Widget _buildResearchNotesButton(bool isDarkMode) {
    return Obx(() {
      final hasNotes = researchNotesController.hasNotes;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          HomeUi.ghostAction(
            label: 'Research Notes',
            dark: isDarkMode,
            icon: Icons.sticky_note_2_outlined,
            onTap: _openResearchNotesPanel,
          ),
          if (hasNotes)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: HomeUi.accent(isDarkMode),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HomeUi.pageBg(isDarkMode),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _premiumLoader(bool isDarkMode) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(HomeUi.accent(isDarkMode)),
        ),
      ),
    );
  }

  String _fmtPct(num? value, {int digits = 2}) {
    if (value == null) return '--';
    final n = value.toDouble();
    final sign = n > 0 ? '+' : '';
    return '$sign${n.toStringAsFixed(digits)}%';
  }

  String _fmtNum(num? value, {int digits = 2}) {
    if (value == null) return '--';
    return value.toStringAsFixed(digits);
  }

  String _fmtVolume(num? value) {
    if (value == null || value <= 0) return '--';
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  String _fmtShares(num? millions) {
    if (millions == null || millions <= 0) return '--';
    return Constants.getShortenedMarketCapV2(millions * 1000000)
        .replaceAll('\$', '');
  }

  Widget _buildKeyMetricsCard(StocksData stockData, bool isDarkMode) {
    final groups = [
      [
        _MetricGroup(
          'Price & Market',
          [
            (
              'Market Cap',
              Constants.getShortenedMarketCapV2(stockData.usdMarketCap)
            ),
            (
              '52W High',
              stockData.d52WeekHigh == null
                  ? '--'
                  : '\$${_fmtNum(stockData.d52WeekHigh)}'
            ),
            (
              '52W Low',
              stockData.d52WeekLow == null
                  ? '--'
                  : '\$${_fmtNum(stockData.d52WeekLow)}'
            ),
            ('Volume', _fmtVolume(stockData.volume)),
            ('Beta', _fmtNum(stockData.beta)),
            ('P/E Ratio', _fmtNum(stockData.peTTM)),
          ],
        ),
        _MetricGroup(
          'Valuation',
          [
            ('P/B Ratio', _fmtNum(stockData.pbAnnual)),
            ('P/S Ratio', _fmtNum(stockData.psTTM)),
            ('P/CF Ratio', _fmtNum(stockData.pcfShareTTM)),
            ('EV/EBIT', _fmtNum(stockData.evEbit)),
            ('EV/FCF', _fmtNum(stockData.evFcf)),
            ('EV/Revenue', _fmtNum(stockData.evRevenue)),
          ],
        ),
        _MetricGroup(
          'Financial Ratios',
          [
            ('ROE', _fmtPct(stockData.rOE)),
            ('ROA', _fmtPct(stockData.roaTTM)),
            ('Current Ratio', _fmtNum(stockData.currentRatioAnnual)),
            ('Quick Ratio', _fmtNum(stockData.quickRatioAnnual)),
            ('Debt/Equity', _fmtNum(stockData.totalDebtTotalEquityAnnual)),
            ('Interest Coverage', _fmtNum(stockData.netInterestCoverageAnnual)),
          ],
        ),
      ],
      [
        _MetricGroup(
          'Growth',
          [
            ('Revenue (1Y)', _fmtPct(stockData.revenueGrowth1Y)),
            ('Revenue (3Y)', _fmtPct(stockData.revenueGrowth3Y)),
            ('EPS (1Y)', _fmtPct(stockData.epsGrowth1y)),
            ('EPS (3Y)', _fmtPct(stockData.epsGrowth3Y)),
            ('Market Cap (3Y)', _fmtPct(stockData.marketCapChange3y)),
            (
              'EBITDA',
              Constants.getShortenedMarketCapV2(stockData.ebitdaEstimateAnnual)
            ),
          ],
        ),
        _MetricGroup(
          'Risk & Efficiency',
          [
            ('Gross Margin', _fmtPct(stockData.grossMarginAnnual)),
            ('Operating Margin', _fmtPct(stockData.operatingMarginAnnual)),
            ('Net Margin', _fmtPct(stockData.netProfitMarginAnnual)),
            ('Asset Turnover', _fmtNum(stockData.assetTurnoverAnnual)),
            ('Inventory Turnover', _fmtNum(stockData.inventoryTurnoverAnnual)),
            ('Receivables Turnover', _fmtNum(stockData.receivablesTurnoverTTM)),
          ],
        ),
        _MetricGroup(
          'Market & Trading',
          [
            ('Avg Volume (10D)', _fmtVolume(stockData.avgVolume10days)),
            ('Avg Volume (30D)', _fmtVolume(stockData.avgVolume30days)),
            ('Shares Outstanding', _fmtShares(stockData.sharesOutStanding)),
            (
              'Float',
              _fmtShares(
                stockData.sharesOutStanding == null
                    ? null
                    : stockData.sharesOutStanding! * 0.8,
              ),
            ),
            (
              'Insider Ownership',
              stockData.businessCompliantRatio == null
                  ? '--'
                  : '${stockData.businessCompliantRatio!.toStringAsFixed(1)}%'
            ),
            (
              'Institutional Hold',
              stockData.businessQuestionableRatio == null
                  ? '--'
                  : '${stockData.businessQuestionableRatio!.toStringAsFixed(1)}%'
            ),
          ],
        ),
      ],
    ];

    return Container(
      width: double.infinity,
      decoration: HomeUi.cardDecoration(isDarkMode),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: HomeUi.tableToolbarHeader(
              isDarkMode,
              icon: Icons.analytics_outlined,
              title: 'Key Metrics',
              subtitleText: 'Price, valuation, growth, and trading snapshot',
            ),
          ),
          Divider(height: 1, color: HomeUi.borderLight(isDarkMode)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: _KeyMetricsQuoteStrip(
              isDark: isDarkMode,
              marketCap: Constants.getShortenedMarketCapV2(
                stockData.usdMarketCap,
              ),
              peRatio: _fmtNum(stockData.peTTM),
              roe: _fmtPct(stockData.rOE),
              roeValue: stockData.rOE?.toDouble(),
              weekLow: stockData.d52WeekLow?.toDouble(),
              weekHigh: stockData.d52WeekHigh?.toDouble(),
              currentPrice: _livePrice ?? stockData.currentPrice?.toDouble(),
            ),
          ),
          for (var rowIndex = 0; rowIndex < groups.length; rowIndex++) ...[
            Divider(height: 1, color: HomeUi.borderLight(isDarkMode)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var colIndex = 0;
                    colIndex < groups[rowIndex].length;
                    colIndex++) ...[
                  if (colIndex > 0)
                    Container(
                      width: 1,
                      color: HomeUi.borderLight(isDarkMode),
                    ),
                  Expanded(
                    child: _KeyMetricColumn(
                      isDark: isDarkMode,
                      group: groups[rowIndex][colIndex],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockHeader(StocksData stockData, bool isDarkMode) {
    final ticker = widget.ticker.symbol ?? widget.ticker.ticker ?? 'TICKER';
    final companyName =
        widget.ticker.companyName ?? widget.ticker.name ?? 'Company Name';
    final price = _livePrice ?? stockData.currentPrice?.toDouble() ?? 0.0;
    final change = stockData.change1DPercent;
    final isUp = change != null && change >= 0;
    final priceColor = _getPriceColor(isDarkMode, _livePrice);

    return Container(
      decoration: HomeUi.cardDecoration(isDarkMode),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: HomeUi.elevatedBg(isDarkMode),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: HomeUi.borderLight(isDarkMode)),
                          ),
                          child: showLogo(
                            ticker,
                            widget.ticker.logo ?? '',
                            sideWidth: 28,
                            name: ticker,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: HomeUi.sectionTitle(isDarkMode)
                                    .copyWith(fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ticker,
                                style: HomeUi.overline(isDarkMode).copyWith(
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AddToWatchlistButton(
                          ticker: ticker,
                          currentPrice: price,
                          isDarkMode: isDarkMode,
                          isInWatchlist: _isInWatchlist,
                          onSuccess: () {
                            _showSuccessSnackBar('$ticker added to watchlist');
                            _checkIfStockInWatchlist();
                          },
                          onError: () {
                            _showErrorSnackBar(
                                'Failed to add $ticker to watchlist');
                          },
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
                                style: HomeUi.overline(isDarkMode).copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: HomeUi.display(isDarkMode).copyWith(
                                  fontSize: 24,
                                  height: 1.1,
                                  color: priceColor,
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
                              isDarkMode,
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
                      isDarkMode,
                      'Market Cap',
                      Constants.getShortenedMarketCapV2(stockData.usdMarketCap),
                    ),
                    _headerKv(
                      isDarkMode,
                      'Volume',
                      '${((stockData.volume ?? 0) / 1000000).toStringAsFixed(1)}M',
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: HomeUi.borderLight(isDarkMode),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeUi.tableToolbarHeader(
                      isDarkMode,
                      icon: Icons.public_outlined,
                      title: 'Market Overview',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDarkMode,
                      'Sector',
                      widget.ticker.sectorname ?? '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Industry',
                      stockData.industry ?? '--',
                      maxLines: 2,
                    ),
                    _headerKv(
                      isDarkMode,
                      'Shares Out',
                      stockData.sharesOutStanding != null
                          ? Constants.getShortenedMarketCapV2(
                              stockData.sharesOutStanding! * 1000000,
                            ).replaceAll('\$', '')
                          : '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'IPO Date',
                      stockData.ipoDate ?? '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Beta',
                      stockData.beta != null
                          ? stockData.beta!.toStringAsFixed(2)
                          : '--',
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: HomeUi.borderLight(isDarkMode),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeUi.tableToolbarHeader(
                      isDarkMode,
                      icon: Icons.auto_graph_outlined,
                      title: 'Key Highlights',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDarkMode,
                      'Book Value',
                      stockData.bookValuePerShareAnnual != null
                          ? '\$${stockData.bookValuePerShareAnnual!.toStringAsFixed(2)}'
                          : '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Cash / Share',
                      stockData.cashPerSharePerShareAnnual != null
                          ? '\$${stockData.cashPerSharePerShareAnnual!.toStringAsFixed(2)}'
                          : '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Dividend Yield',
                      stockData.currentDividendYieldTTM != null
                          ? '${stockData.currentDividendYieldTTM!.toStringAsFixed(2)}%'
                          : '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Enterprise Value',
                      stockData.enterpriseValue != null
                          ? Constants.getShortenedMarketCapV2(
                              stockData.enterpriseValue,
                            )
                          : '--',
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

  Widget _headerKv(
    bool isDarkMode,
    String label,
    String value, {
    int maxLines = 1,
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
              style:
                  HomeUi.tableCellSecondary(isDarkMode).copyWith(fontSize: 12),
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
              style:
                  HomeUi.tableCellEmphasis(isDarkMode).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriceColor(bool isDarkMode, double? livePrice) {
    if (livePrice == null || _previousPrice == null) {
      return HomeUi.title(isDarkMode);
    }
    if (livePrice > _previousPrice!) {
      return HomeUi.positive(isDarkMode);
    }
    if (livePrice < _previousPrice!) {
      return HomeUi.negative(isDarkMode);
    }
    return HomeUi.title(isDarkMode);
  }

  Widget _buildPerformanceHeatmap(StocksData stockData, bool isDarkMode) {
    final performanceData = {
      '1D': stockData.change1DPercent ?? 0,
      '1W': stockData.priceChange1WPercent ?? 0,
      '1M': stockData.priceChange1MPercent ?? 0,
      '3M': stockData.priceChange3MPercent ?? 0,
      '6M': stockData.priceChange6MPercent ?? 0,
      '1Y': stockData.priceChange1YPercent ?? 0,
      '3Y': stockData.priceChange3YPercent ?? 0,
      '5Y': stockData.priceChange5YPercent ?? 0,
      'YTD': stockData.priceChangeYTDPercent ?? 0,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDarkMode,
            icon: Icons.grid_view_rounded,
            title: 'Performance',
            subtitleText: 'Returns across timeframes',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 2.15,
            ),
            itemCount: performanceData.length,
            itemBuilder: (context, index) {
              final period = performanceData.keys.elementAt(index);
              final value = performanceData[period] ?? 0;
              return _buildHeatmapCell(period, value.toDouble(), isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCell(String period, double value, bool isDarkMode) {
    final isPositive = value >= 0;
    final absValue = value.abs();
    final intensity = (absValue / 20).clamp(0.18, 1.0);
    final tone =
        isPositive ? HomeUi.positive(isDarkMode) : HomeUi.negative(isDarkMode);
    final fill = absValue == 0
        ? HomeUi.elevatedBg(isDarkMode)
        : Color.lerp(
            tone.withValues(alpha: isDarkMode ? 0.12 : 0.08),
            tone.withValues(alpha: isDarkMode ? 0.38 : 0.22),
            intensity,
          )!;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(
          color: absValue == 0
              ? HomeUi.borderLight(isDarkMode)
              : tone.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            period,
            style: HomeUi.overline(isDarkMode).copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              color: absValue == 0 ? HomeUi.muted(isDarkMode) : tone,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: HomeUi.tableNumeric(
              isDarkMode,
              positiveValue: absValue == 0 ? null : isPositive,
            ).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDarkMode) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _premiumLoader(isDarkMode);
      }

      if (controller.errorMessage.isNotEmpty) {
        return Center(
          child: Text(
            controller.errorMessage.value,
            style: HomeUi.bodyText(isDarkMode).copyWith(
              color: HomeUi.negative(isDarkMode),
            ),
          ),
        );
      }

      if (controller.stockData.value == null) {
        return Center(
          child: Text(
            'No data available',
            style: HomeUi.subtitle(isDarkMode),
          ),
        );
      }

      final stockData = controller.stockData.value!;
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStockHeader(stockData, isDarkMode),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = (constraints.maxWidth - 16) / 2;
                final cellWidth = (availableWidth - 32 - 12) / 3;
                final cellHeight = cellWidth / 2.15;
                final gridHeight = (cellHeight * 3) + 12;
                final heatmapHeight = 30 + 48 + gridHeight;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TradingViewWidget(
                        symbol:
                            widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                        controller: tradingViewController,
                        height: heatmapHeight,
                        country: stockData.country,
                        exchange: stockData.exchange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Half screen width for analytics in column
                    Expanded(
                      child: Column(
                        children: [
                          // RecommendationWidget(
                          //   symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                          //   controller: recommendationController,
                          // ),
                          // const SizedBox(height: 8),
                          _buildPerformanceHeatmap(stockData, isDarkMode),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            _buildKeyMetricsCard(stockData, isDarkMode),
            const SizedBox(height: 16),
            TickerUpcomingEarningsCard(
              controller: tickerEarningsController,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            TickerEarningsHistorySection(
              controller: tickerEarningsController,
              isDarkMode: isDarkMode,
            ),
            // const SizedBox(height: 16),
            // TickerRevenueGeographySection(
            //   controller: tickerRevenueGeographyController,
            //   isDarkMode: isDarkMode,
            //   onRetry: () => tickerRevenueGeographyController.load(
            //     widget.ticker.symbol ?? widget.ticker.ticker ?? '',
            //     forceRefresh: true,
            //   ),
            // ),
            const SizedBox(height: 16),
            TickerDividendHistorySection(
              controller: tickerDividendController,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            TickerPeerComparisonSection(
              controller: tickerPeerComparisonController,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            TickerPriceTargetSection(
              controller: tickerPriceTargetController,
              isDarkMode: isDarkMode,
              onRetry: () => tickerPriceTargetController.load(
                widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                forceRefresh: true,
              ),
            ),
            const SizedBox(height: 16),
            // Forecast/Recommendation Widget
            ListenableBuilder(
              listenable: recommendationController,
              builder: (context, child) {
                // Hide container only if not loading AND (error OR no recommendation)
                if (!recommendationController.isLoading &&
                    (recommendationController.error != null ||
                        recommendationController.recommendation == null)) {
                  return const SizedBox.shrink();
                }

                return Container(
                  decoration: HomeUi.cardDecoration(isDarkMode),
                  child: RecommendationWidget(
                    symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                    controller: recommendationController,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Super Investors Section
            SuperInvestorsSection(
              symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
            ),
            const SizedBox(height: 16),
            TickerFundOwnershipSection(
              controller: tickerFundOwnershipController,
              isDarkMode: isDarkMode,
              currentPrice: _livePrice ?? stockData.currentPrice?.toDouble(),
              onRetry: () => tickerFundOwnershipController.load(
                widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                forceRefresh: true,
              ),
            ),
            const SizedBox(height: 16),
            TickerInsiderTradingSection(
              controller: tickerInsiderTradingController,
              isDarkMode: isDarkMode,
              ticker: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
              currentPrice: _livePrice ?? stockData.currentPrice?.toDouble(),
              companyLogoUrl: widget.ticker.logo ?? '',
              onRetry: () => tickerInsiderTradingController.load(
                widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                forceRefresh: true,
              ),
            ),
            const SizedBox(height: 16),
            TickerNewsSentimentSection(
              controller: tickerNewsSentimentController,
              isDarkMode: isDarkMode,
              onRetry: () => tickerNewsSentimentController.load(
                widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                forceRefresh: true,
              ),
            ),
            const SizedBox(height: 16),
            // News Section
            SimpleNewsWidget(
              symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFinancialTab(bool isDarkMode) {
    return TerminalFinancialsScreen(
      symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
      currency: widget.ticker.currency ?? 'USD',
    );
  }

  Widget _buildChartsTab(bool isDarkMode) {
    return TickerChartsTabContent(
      symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
    );
  }

  Widget _buildCustomChartsTab(bool isDarkMode) {
    return const TickerCustomChartsTabContent();
  }

  Widget _buildAboutCompanyTab(bool isDarkMode) {
    return TickerAboutCompanyTab(
      ticker: widget.ticker,
      profileController: stockProfileController,
      youtubeController: stockYouTubeVideosController,
      isDarkMode: isDarkMode,
    );
  }

  void _showAddNoteDialog(bool isDarkMode) {
    _AddResearchNoteDialog.show(
      context: context,
      ticker: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
      notesController: researchNotesController,
      onSaved: () {
        _showSuccessSnackBar('Note added successfully');
        setState(() => _isResearchNotesOpen = true);
      },
    );
  }
}

class _MetricGroup {
  const _MetricGroup(this.title, this.rows);

  final String title;
  final List<(String, String)> rows;
}

const _signedMetricLabels = {
  'Revenue (1Y)',
  'Revenue (3Y)',
  'EPS (1Y)',
  'EPS (3Y)',
  'Market Cap (3Y)',
  'ROE',
  'ROA',
  'Gross Margin',
  'Operating Margin',
  'Net Margin',
};

bool? _metricSignedTone(String label, String value) {
  if (!_signedMetricLabels.contains(label)) return null;
  final parsed = double.tryParse(
    value.replaceAll(RegExp(r'[^0-9.\-]'), ''),
  );
  if (parsed == null || parsed == 0) return null;
  return parsed > 0;
}

class _KeyMetricsQuoteStrip extends StatelessWidget {
  const _KeyMetricsQuoteStrip({
    required this.isDark,
    required this.marketCap,
    required this.peRatio,
    required this.roe,
    required this.roeValue,
    required this.weekLow,
    required this.weekHigh,
    required this.currentPrice,
  });

  final bool isDark;
  final String marketCap;
  final String peRatio;
  final String roe;
  final double? roeValue;
  final double? weekLow;
  final double? weekHigh;
  final double? currentPrice;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: _PremiumStatCard(
                  isDark: isDark, label: 'Market Cap', value: marketCap)),
          const SizedBox(width: 12),
          Expanded(
              child: _PremiumStatCard(
                  isDark: isDark, label: 'P/E Ratio', value: peRatio)),
          const SizedBox(width: 12),
          Expanded(
              child: _PremiumStatCard(
                  isDark: isDark,
                  label: 'ROE',
                  value: roe,
                  signedValue: roeValue)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _PremiumWeekRangeCard(
              isDark: isDark,
              weekLow: weekLow,
              weekHigh: weekHigh,
              currentPrice: currentPrice,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  const _PremiumStatCard({
    required this.isDark,
    required this.label,
    required this.value,
    this.signedValue,
  });

  final bool isDark;
  final String label;
  final String value;
  final double? signedValue;

  @override
  Widget build(BuildContext context) {
    final signed =
        signedValue == null || signedValue == 0 ? null : signedValue! > 0;
    final valueColor = signed == null
        ? HomeUi.title(isDark)
        : (signed ? HomeUi.positive(isDark) : HomeUi.negative(isDark));

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1D2E), const Color(0xFF151822)]
              : [const Color(0xFFF9FAFB), const Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2D3E).withValues(alpha: 0.8)
              : const Color(0xFFE5E7EB).withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF6366F1).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFF8B8FA3) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
              height: 1.05,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumWeekRangeCard extends StatelessWidget {
  const _PremiumWeekRangeCard({
    required this.isDark,
    required this.weekLow,
    required this.weekHigh,
    required this.currentPrice,
  });

  final bool isDark;
  final double? weekLow;
  final double? weekHigh;
  final double? currentPrice;

  @override
  Widget build(BuildContext context) {
    final low = weekLow;
    final high = weekHigh;
    final price = currentPrice;
    final hasRange = low != null && high != null && high > low;
    final t = hasRange && price != null
        ? ((price - low) / (high - low)).clamp(0.0, 1.0)
        : 0.5;

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1D2E), const Color(0xFF151822)]
              : [const Color(0xFFF9FAFB), const Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2D3E).withValues(alpha: 0.8)
              : const Color(0xFFE5E7EB).withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF6366F1).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '52-WEEK RANGE',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              height: 1.1,
              color: isDark ? const Color(0xFF8B8FA3) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                hasRange ? '\$${low.toStringAsFixed(2)}' : '--',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: isDark
                      ? const Color(0xFF8B8FA3)
                      : const Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              if (price != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: HomeUi.iconFillGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                hasRange ? '\$${high.toStringAsFixed(2)}' : '--',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: isDark
                      ? const Color(0xFF8B8FA3)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final thumb = (t * constraints.maxWidth)
                    .clamp(6.0, constraints.maxWidth - 6);
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 10,
                    width: constraints.maxWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 5,
                          margin: const EdgeInsets.only(top: 2.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2D3E)
                                : const Color(0xFFE5E7EB),
                            borderRadius:
                                BorderRadius.circular(HomeUi.radiusPill),
                          ),
                        ),
                        if (hasRange)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: (t * constraints.maxWidth)
                                  .clamp(4.0, constraints.maxWidth),
                              height: 5,
                              margin: const EdgeInsets.only(top: 2.5),
                              decoration: BoxDecoration(
                                gradient: HomeUi.iconFillGradient,
                                borderRadius:
                                    BorderRadius.circular(HomeUi.radiusPill),
                              ),
                            ),
                          ),
                        if (hasRange)
                          Positioned(
                            left: thumb - 6,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE4621E),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE4621E)
                                        .withValues(alpha: 0.28),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyMetricColumn extends StatelessWidget {
  const _KeyMetricColumn({
    required this.isDark,
    required this.group,
  });

  final bool isDark;
  final _MetricGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeUi.sectionTitle(isDark).copyWith(
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 20,
            height: 2,
            decoration: BoxDecoration(
              gradient: HomeUi.iconFillGradient,
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < group.rows.length; i++)
            _MetricKvRow(
              isDark: isDark,
              label: group.rows[i].$1,
              value: group.rows[i].$2,
              striped: i.isOdd,
            ),
        ],
      ),
    );
  }
}

class _MetricKvRow extends StatelessWidget {
  const _MetricKvRow({
    required this.isDark,
    required this.label,
    required this.value,
    required this.striped,
  });

  final bool isDark;
  final String label;
  final String value;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final signed = _metricSignedTone(label, value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: striped ? HomeUi.tableRowOdd(isDark) : Colors.transparent,
        borderRadius: BorderRadius.circular(HomeUi.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (signed == null
                      ? HomeUi.tableCellEmphasis(isDark)
                      : HomeUi.tableNumeric(isDark, positiveValue: signed))
                  .copyWith(fontSize: 13, letterSpacing: -0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResearchNotesOverlayCard extends StatelessWidget {
  const _ResearchNotesOverlayCard({
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.child,
  });

  final bool isDarkMode;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        height: 560,
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDarkMode),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDarkMode)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.38 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDarkMode,
                      icon: Icons.sticky_note_2_outlined,
                      title: title,
                      subtitleText: subtitle.isNotEmpty ? subtitle : null,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDarkMode),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: HomeUi.borderLight(isDarkMode)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: HomeUi.muted(isDarkMode),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDarkMode)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _AddResearchNoteDialog extends StatefulWidget {
  const _AddResearchNoteDialog({
    required this.ticker,
    required this.notesController,
    required this.onSaved,
  });

  final String ticker;
  final ResearchNotesController notesController;
  final VoidCallback onSaved;

  static Future<void> show({
    required BuildContext context,
    required String ticker,
    required ResearchNotesController notesController,
    required VoidCallback onSaved,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Research Note',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _AddResearchNoteDialog(
              ticker: ticker,
              notesController: notesController,
              onSaved: onSaved,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<_AddResearchNoteDialog> createState() => _AddResearchNoteDialogState();
}

class _AddResearchNoteDialogState extends State<_AddResearchNoteDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please enter a note');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final success = await widget.notesController.addNote(widget.ticker, text);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onSaved();
    } else {
      setState(() {
        _saving = false;
        _error = widget.notesController.errorMessage.value.isNotEmpty
            ? widget.notesController.errorMessage.value
            : 'Failed to add note';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.note_add_outlined,
                      title: 'Add Research Note',
                      subtitleText: widget.ticker,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _saving ? null : () => Navigator.of(context).pop(),
                      child: Container(
                        width: HomeUi.controlHeight,
                        height: HomeUi.controlHeight,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDark),
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeUi.borderLight(isDark)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: HomeUi.muted(isDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: FilterTextField(
                dark: isDark,
                label: 'Note',
                controller: _noteController,
                hintText: 'Thesis, catalysts, risks, follow-ups…',
                errorText: _error,
                minLines: 4,
                maxLines: 6,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: _saving ? 0.5 : 1,
                      child: HomeUi.ghostAction(
                        label: 'Cancel',
                        dark: isDark,
                        onTap:
                            _saving ? () {} : () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Opacity(
                      opacity: _saving ? 0.7 : 1,
                      child: HomeUi.primaryAction(
                        label: _saving ? 'Saving…' : 'Save',
                        onTap: _saving ? () {} : _save,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
