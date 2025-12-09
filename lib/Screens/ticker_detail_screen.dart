import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/trading_view_widget.dart';
import 'package:musaffa_terminal/Components/simple_news_widget.dart';
import 'package:musaffa_terminal/Components/recommendation_widget.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/add_to_watchlist_button.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/Controllers/financial_fundamentals_controller.dart';
import 'package:musaffa_terminal/Controllers/trading_view_controller.dart';
import 'package:musaffa_terminal/Controllers/research_notes_controller.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_financials_screen.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/live_price_service.dart';
import 'package:musaffa_terminal/services/websocket_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/models/live_price_model.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
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
  late LivePriceService _livePriceService;
  late WebSocketService _webSocketService;
  final GlobalWatchlistService _watchlistService = Get.find<GlobalWatchlistService>();
  int _selectedTabIndex = 0; // 0 for Overview, 1 for Financial
  bool _isInWatchlist = false;
  bool _isNotesPanelOpen = false;
  
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
    financialFundamentalsController.dispose();
    tradingViewController.dispose();
    super.dispose();
  }

  void _toggleNotesPanel() {
    setState(() {
      _isNotesPanelOpen = !_isNotesPanelOpen;
      // Refresh notes when opening panel
      if (_isNotesPanelOpen) {
        final ticker = widget.ticker.symbol ?? widget.ticker.ticker ?? '';
        researchNotesController.fetchNotes(ticker);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
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
              
              // Action Buttons
              Container(
                margin: const EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 2),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Tab selector matching screener style
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(90),
                              border: Border.all(
                                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                            setState(() {
                              _selectedTabIndex = 0;
                            });
                          },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 
                                          ? Colors.blue
                                : Colors.transparent,
                                      borderRadius: BorderRadius.circular(90),
                          ),
                          child: Text(
                            'Overview',
                                      style: DashboardTextStyles.tickerSymbol.copyWith(
                                        fontSize: 11,
                                        fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w400,
                              color: _selectedTabIndex == 0 
                                            ? Colors.white
                                  : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                            ),
                          ),
                        ),
                                ),
                                GestureDetector(
                                  onTap: () {
                            setState(() {
                              _selectedTabIndex = 1;
                            });
                          },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 
                                          ? Colors.blue
                                : Colors.transparent,
                                      borderRadius: BorderRadius.circular(90),
                          ),
                          child: Text(
                            'Financial',
                                      style: DashboardTextStyles.tickerSymbol.copyWith(
                                        fontSize: 11,
                                        fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w400,
                              color: _selectedTabIndex == 1 
                                            ? Colors.white
                                            : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Obx(() {
                          final hasNotes = researchNotesController.hasNotes;
                          return GestureDetector(
                            onTap: () {
                              if (!hasNotes) {
                                // If no notes, open dialog directly
                                _showAddNoteDialog(isDarkMode);
                              } else {
                                // If notes exist, toggle panel
                                _toggleNotesPanel();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(90),
                                border: Border.all(
                                  color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                                  width: 1,
                              ),
                            ),
                            child: Text(
                              hasNotes ? 'View Notes' : 'Add Note',
                              style: TextStyle(
                                fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                  color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    // Notes Panel
                    if (_isNotesPanelOpen) ...[
                      const SizedBox(height: 8),
                      _buildNotesPanel(isDarkMode),
                    ],
                  ],
                ),
              ),
              
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildOverviewTab(isDarkMode)
                    : _buildFinancialTab(isDarkMode),
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
                  color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(), // Empty space that closes sidebar when tapped
                      ),
                      GestureDetector(
                        onTap: () {}, // Prevent closing when tapping on sidebar itself
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
          // Global FAB Overlay
          const GlobalFABOverlay(),
        ],
      ),
    );
  }

  Widget _buildPriceMetrics(StocksData stockData, bool isDarkMode) {
    final data = [
      ['Market Cap', Constants.getShortenedMarketCapV2(stockData.usdMarketCap)],
      ['52W High', '\$${stockData.d52WeekHigh?.toStringAsFixed(2) ?? '--'}'],
      ['52W Low', '\$${stockData.d52WeekLow?.toStringAsFixed(2) ?? '--'}'],
      ['Volume', '${((stockData.volume ?? 0) / 1000000).toStringAsFixed(1)}M'],
      ['Beta', stockData.beta?.toStringAsFixed(2) ?? '--'],
      ['P/E Ratio', stockData.peTTM?.toStringAsFixed(2) ?? '--'],
    ];
    
    return _buildCompactTable('Price & Market', data, isDarkMode, 
      titleFontSize: 13, 
      titleFontWeight: FontWeight.w400,
      childFontSize: 12,
      childFontWeight: FontWeight.w400,
    );
  }

  Widget _buildValuationMetrics(StocksData stockData, bool isDarkMode) {
    final data = [
      ['P/B Ratio', stockData.pbAnnual?.toStringAsFixed(2) ?? '--'],
      ['P/S Ratio', stockData.psTTM?.toStringAsFixed(2) ?? '--'],
      ['P/CF Ratio', stockData.pcfShareTTM?.toStringAsFixed(2) ?? '--'],
      ['EV/EBIT', stockData.evEbit?.toStringAsFixed(2) ?? '--'],
      ['EV/FCF', stockData.evFcf?.toStringAsFixed(2) ?? '--'],
      ['EV/Revenue', stockData.evRevenue?.toStringAsFixed(2) ?? '--'],
    ];
    
    return _buildCompactTable('Valuation', data, isDarkMode,
      titleFontSize: 13,
      titleFontWeight: FontWeight.w400,
      childFontSize: 12,
      childFontWeight: FontWeight.w400,
    );
  }

  Widget _buildFinancialRatios(StocksData stockData, bool isDarkMode) {
    final data = [
      ['ROE', '${stockData.rOE?.toStringAsFixed(2) ?? '--'}%'],
      ['ROA', '${stockData.roaTTM?.toStringAsFixed(2) ?? '--'}%'],
      ['Current Ratio', stockData.currentRatioAnnual?.toStringAsFixed(2) ?? '--'],
      ['Quick Ratio', stockData.quickRatioAnnual?.toStringAsFixed(2) ?? '--'],
      ['Debt/Equity', stockData.totalDebtTotalEquityAnnual?.toStringAsFixed(2) ?? '--'],
      ['Interest Coverage', stockData.netInterestCoverageAnnual?.toStringAsFixed(2) ?? '--'],
    ];
    
    return _buildCompactTable('Financial Ratios', data, isDarkMode,
      titleFontSize: 13,
      titleFontWeight: FontWeight.w400,
      childFontSize: 12,
      childFontWeight: FontWeight.w400,
    );
  }


  Widget _buildGrowthMetrics(StocksData stockData, bool isDarkMode) {
    final data = [
      ['Revenue (1Y)', '${stockData.revenueGrowth1Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Revenue (3Y)', '${stockData.revenueGrowth3Y?.toStringAsFixed(2) ?? '--'}%'],
      ['EPS (1Y)', '${stockData.epsGrowth1y?.toStringAsFixed(2) ?? '--'}%'],
      ['EPS (3Y)', '${stockData.epsGrowth3Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Market Cap (3Y)', '${stockData.marketCapChange3y?.toStringAsFixed(2) ?? '--'}%'],
      ['EBITDA', Constants.getShortenedMarketCapV2(stockData.ebitdaEstimateAnnual)],
    ];
    
    return _buildCompactTable('Growth', data, isDarkMode,
      titleFontSize: 13,
      titleFontWeight: FontWeight.w400,
      childFontSize: 12,
      childFontWeight: FontWeight.w400,
    );
  }

  Widget _buildRiskMetrics(StocksData stockData, bool isDarkMode) {
    final data = [
      ['Gross Margin', '${stockData.grossMarginAnnual?.toStringAsFixed(2) ?? '--'}%'],
      ['Operating Margin', '${stockData.operatingMarginAnnual?.toStringAsFixed(2) ?? '--'}%'],
      ['Net Margin', '${stockData.netProfitMarginAnnual?.toStringAsFixed(2) ?? '--'}%'],
      ['Asset Turnover', stockData.assetTurnoverAnnual?.toStringAsFixed(2) ?? '--'],
      ['Inventory Turnover', stockData.inventoryTurnoverAnnual?.toStringAsFixed(2) ?? '--'],
      ['Receivables Turnover', stockData.receivablesTurnoverTTM?.toStringAsFixed(2) ?? '--'],
    ];
    
    return _buildCompactTable('Risk & Efficiency', data, isDarkMode,
      titleFontSize: 13,
      titleFontWeight: FontWeight.w400,
      childFontSize: 12,
      childFontWeight: FontWeight.w400,
    );
  }

  Widget _buildMarketTradingMetrics(StocksData stockData, bool isDarkMode) {
    // Format shares outstanding - same approach as Market Overview
    String sharesOutstandingFormatted = '--';
    if (stockData.sharesOutStanding != null && stockData.sharesOutStanding! > 0) {
      // sharesOutStanding is stored in millions, so multiply by 1M to get raw number
      final rawShares = stockData.sharesOutStanding! * 1000000;
      sharesOutstandingFormatted = Constants.getShortenedMarketCapV2(rawShares).replaceAll('\$', '');
    }
    
    String floatFormatted = '--';
    if (stockData.sharesOutStanding != null && stockData.sharesOutStanding! > 0) {
      // Calculate float as 80% of shares outstanding
      final rawFloat = stockData.sharesOutStanding! * 0.8 * 1000000;
      floatFormatted = Constants.getShortenedMarketCapV2(rawFloat).replaceAll('\$', '');
    }
    
    final data = [
      ['Avg Volume (10D)', '${((stockData.avgVolume10days ?? 0) / 1000000).toStringAsFixed(1)}M'],
      ['Avg Volume (30D)', '${((stockData.avgVolume30days ?? 0) / 1000000).toStringAsFixed(1)}M'],
      ['Shares Outstanding', sharesOutstandingFormatted],
      ['Float', floatFormatted],
      ['Insider Ownership', '${(stockData.businessCompliantRatio ?? 0).toStringAsFixed(1)}%'],
      ['Institutional Hold', '${(stockData.businessQuestionableRatio ?? 0).toStringAsFixed(1)}%'],
    ];
    
    return _buildCompactTable('Market & Trading', data, isDarkMode,
      titleFontSize: 13,
      titleFontWeight: FontWeight.w400,
      childFontSize: 12,
      childFontWeight: FontWeight.w400,
    );
  }

  Widget _buildCompactTable(
    String title, 
    List<List<String>> data, 
    bool isDarkMode, {
    double? titleFontSize,
    FontWeight? titleFontWeight,
    double? childFontSize,
    FontWeight? childFontWeight,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: titleFontSize ?? 11,
                fontWeight: titleFontWeight ?? FontWeight.w600,
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
              ),
            ),
          ),
          ...data.map((row) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row[0],
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: childFontSize ?? 11,
                    fontWeight: childFontWeight ?? FontWeight.w400,
                  ),
                ),
                Text(
                  row[1],
                  style: DashboardTextStyles.dataCell.copyWith(
                    fontSize: childFontSize ?? 11,
                    fontWeight: childFontWeight ?? FontWeight.w400,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }


  Widget _buildStockHeader(StocksData stockData, bool isDarkMode) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Container 1: Company Identity & Current Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Company Logo using showLogo function
                      showLogo(
                        widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                        widget.ticker.logo ?? '',
                        sideWidth: 32,
                        name: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ticker.companyName ?? widget.ticker.name ?? 'Company Name',
                              style: DashboardTextStyles.stockName.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.ticker.symbol ?? widget.ticker.ticker ?? 'TICKER',
                              style: DashboardTextStyles.tickerSymbol.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add to Watchlist Button
                      AddToWatchlistButton(
                        ticker: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                        currentPrice: _livePrice ?? (stockData.currentPrice ?? 0.0).toDouble(),
                        isDarkMode: isDarkMode,
                        isInWatchlist: _isInWatchlist,
                        onSuccess: () {
                          _showSuccessSnackBar('${widget.ticker.symbol ?? widget.ticker.ticker} added to watchlist');
                          _checkIfStockInWatchlist();
                        },
                        onError: () {
                          _showErrorSnackBar('Failed to add ${widget.ticker.symbol ?? widget.ticker.ticker} to watchlist');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Live Current Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                            'Current Price',
                            style: DashboardTextStyles.tickerSymbol.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                      ),
                          const SizedBox(height: 4),
                      Text(
                            '\$${(_livePrice ?? stockData.currentPrice?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                            style: DashboardTextStyles.stockName.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _getPriceColor(_livePrice, stockData.currentPrice?.toDouble()),
                            ),
                          ),
                        ],
                      ),
                      // Change %
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Change',
                            style: DashboardTextStyles.tickerSymbol.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stockData.change1DPercent != null ? (stockData.change1DPercent! >= 0 ? '+' : '') : ''}${stockData.change1DPercent?.toStringAsFixed(2) ?? '--'}%',
                            style: DashboardTextStyles.stockName.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                          color: stockData.change1DPercent != null
                                  ? (stockData.change1DPercent! >= 0 ? Colors.green.shade600 : Colors.red.shade600)
                                  : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
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
                        'Market Cap: ${Constants.getShortenedMarketCapV2(stockData.usdMarketCap)}',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Volume: ${((stockData.volume ?? 0) / 1000000).toStringAsFixed(1)}M',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Container 2: Market Overview
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Overview',
                    style: DashboardTextStyles.stockName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.ticker.sectorname != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sector:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.ticker.sectorname!,
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.industry != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Industry:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          stockData.industry!,
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.sharesOutStanding != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shares Outstanding:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          Constants.getShortenedMarketCapV2(stockData.sharesOutStanding! * 1000000).replaceAll('\$', ''),
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.ipoDate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'IPO Date:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          stockData.ipoDate!,
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.beta != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Beta:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          stockData.beta!.toStringAsFixed(2),
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Add spacer to push content to top and maintain consistent height
                  const Spacer(),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Container 3: Key Financial Highlights
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Highlights',
                    style: DashboardTextStyles.stockName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (stockData.bookValuePerShareAnnual != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Book Value:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '\$${stockData.bookValuePerShareAnnual!.toStringAsFixed(2)}',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.cashPerSharePerShareAnnual != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cash/Share:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '\$${stockData.cashPerSharePerShareAnnual!.toStringAsFixed(2)}',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.currentDividendYieldTTM != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dividend Yield:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${stockData.currentDividendYieldTTM!.toStringAsFixed(2)}%',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.enterpriseValue != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enterprise Value:',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          Constants.getShortenedMarketCapV2(stockData.enterpriseValue),
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Add spacer to push content to top and maintain consistent height
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriceColor(double? livePrice, double? typesensePrice) {
    if (livePrice == null || typesensePrice == null || _previousPrice == null) {
      return Colors.grey;
    }
    
    if (livePrice > _previousPrice!) {
      return Colors.green.shade600;
    } else if (livePrice < _previousPrice!) {
      return Colors.red.shade600;
    } else {
      return Colors.grey;
    }
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
      padding: const EdgeInsets.all(10), // Reduced padding for terminal look
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(4), // Smaller radius for terminal look
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Heatmap',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing for terminal look
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4, // Reduced spacing for terminal look
              mainAxisSpacing: 4, // Reduced spacing for terminal look
              childAspectRatio: 2, // Adjusted for larger text and better readability
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
    
    // Terminal-appropriate colors - solid colors, no opacity
    Color cellColor;
    Color textColor;
    
    if (absValue == 0) {
      // Neutral/zero performance
      cellColor = isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
      textColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    } else if (absValue <= 1) {
      // Very small change
      cellColor = isPositive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
      textColor = isPositive ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    } else if (absValue <= 5) {
      // Small change
      cellColor = isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
      textColor = isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    } else if (absValue <= 15) {
      // Medium change
      cellColor = isPositive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);
      textColor = isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    } else {
      // Large change
      cellColor = isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171);
      textColor = isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    }

    return Container(
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2), // Smaller radius for terminal look
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            period,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2), // Increased spacing for better readability
          Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDarkMode) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.errorMessage.isNotEmpty) {
        return Center(
          child: Text(
            controller.errorMessage.value,
            style: DashboardTextStyles.errorMessage,
          ),
        );
      }
      
      if (controller.stockData.value == null) {
        return const Center(child: Text('No data available'));
      }
      
      final stockData = controller.stockData.value!;
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildStockHeader(stockData, isDarkMode),
            const SizedBox(height: 16),

            // TradingView Chart and Analytics Row
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate heatmap height based on available width
                // Heatmap structure:
                // - Padding: 10px top + 10px bottom = 20px
                // - Header: ~20px (text) + 6px spacing = 26px
                // - Grid: 3 rows × cell height
                //   Cell height = (available width / 3 - spacing) / aspectRatio(2)
                //   With 4px spacing between cells
                final availableWidth = (constraints.maxWidth - 16) / 2; // Half width minus spacing
                final cellWidth = (availableWidth - 20 - 8) / 3; // Container width - padding - spacing
                final cellHeight = cellWidth / 2; // aspectRatio is 2
                final gridHeight = (cellHeight * 3) + (4 * 2); // 3 rows + 2 spacings
                final heatmapHeight = 20 + 26 + gridHeight; // padding + header + grid
                
                return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Half screen width for chart
                Expanded(
                  child: TradingViewWidget(
                    symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
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

            // Row 1: Price & Market, Valuation, Financial Ratios
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPriceMetrics(stockData, isDarkMode),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildValuationMetrics(stockData, isDarkMode),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialRatios(stockData, isDarkMode),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Growth, Risk & Efficiency (Performance removed - shown in heatmap)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildGrowthMetrics(stockData, isDarkMode),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRiskMetrics(stockData, isDarkMode),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMarketTradingMetrics(stockData, isDarkMode),
                ),
              ],
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: RecommendationWidget(
                symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                controller: recommendationController,
              ),
                );
              },
            ),
            const SizedBox(height: 16),
            // News Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: SimpleNewsWidget(
                symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
              ),
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

  Widget _buildNotesPanel(bool isDarkMode) {
    return Obx(() {
      if (researchNotesController.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: researchNotesController.hasNotes
            ? _buildNotesList(isDarkMode)
            : _buildAddNoteForm(isDarkMode),
      );
    });
  }

  Widget _buildNotesList(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Research Notes',
              style: DashboardTextStyles.headerTitle.copyWith(fontSize: 14),
            ),
            TextButton(
              onPressed: () => _showAddNoteDialog(isDarkMode),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'Add Note',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: const Color(0xFF81AACE),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (researchNotesController.notes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No notes found',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 11,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: researchNotesController.notes.map((note) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF505050) : const Color(0xFFD1D5DB),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.text,
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        fontSize: 11,
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(note.createdAt),
                    style: DashboardTextStyles.columnHeader.copyWith(
                      fontSize: 10,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildAddNoteForm(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No Research Notes',
          style: DashboardTextStyles.headerTitle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          'Click "Add Note" to create your first research note for this ticker.',
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 11,
            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _showAddNoteDialog(isDarkMode),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            side: const BorderSide(
              color: Color(0xFF81AACE),
            ),
            backgroundColor: const Color(0xFF81AACE).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Add Note',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: const Color(0xFF81AACE),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddNoteDialog(bool isDarkMode) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Research Note',
                      style: DashboardTextStyles.headerTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 6,
                minLines: 4,
                style: DashboardTextStyles.tickerSymbol.copyWith(fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  hintText: 'Enter your research note...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDarkMode ? const Color(0xFF505050) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDarkMode ? const Color(0xFF505050) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFF81AACE),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Secondary CTA - Cancel button (transparent with border)
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(90),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Primary CTA - Save button (filled blue)
                  ElevatedButton(
                    onPressed: () async {
                      final noteText = noteController.text.trim();
                      if (noteText.isEmpty) {
                        _showErrorSnackBar('Please enter a note');
                        return;
                      }
                      final ticker = widget.ticker.symbol ?? widget.ticker.ticker ?? '';
                      final success = await researchNotesController.addNote(ticker, noteText);
                      if (success) {
                        Navigator.pop(context);
                        _showSuccessSnackBar('Note added successfully');
                        // Open panel if it was closed
                        if (!_isNotesPanelOpen) {
                          setState(() {
                            _isNotesPanelOpen = true;
                          });
                        }
                      } else {
                        _showErrorSnackBar(researchNotesController.errorMessage.value);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      backgroundColor: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(90),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
}