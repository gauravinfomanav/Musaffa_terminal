import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/trading_view_widget.dart';
import 'package:musaffa_terminal/Components/simple_news_widget.dart';
import 'package:musaffa_terminal/Components/recommendation_widget.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/Controllers/financial_fundamentals_controller.dart';
import 'package:musaffa_terminal/Controllers/trading_view_controller.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_financials_screen.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

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
  int _selectedTabIndex = 0; // 0 for Overview, 1 for Financial
  bool _isWatchlistOpen = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(StockDetailsController());
    recommendationController = RecommendationController();
    financialFundamentalsController = FinancialFundamentalsController();
    tradingViewController = TradingViewController();
    
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchStockDetails(widget.ticker.symbol ?? widget.ticker.ticker ?? '');
    });
  }

  @override
  void dispose() {
    recommendationController.dispose();
    financialFundamentalsController.dispose();
    tradingViewController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
    });
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
              HomeTabBar(
                showBackButton: true,
                isWatchlistOpen: _isWatchlistOpen,
                onWatchlistToggle: _toggleWatchlist,
                onThemeToggle: () {
                  final currentTheme = Theme.of(context).brightness;
                  Get.changeThemeMode(
                    currentTheme == Brightness.dark 
                        ? ThemeMode.light 
                        : ThemeMode.dark,
                  );
                },
              ),
              
              // Action Buttons
              Container(
                margin: const EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 2),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        side: BorderSide(
                          color: _selectedTabIndex == 0 
                              ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE))
                              : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
                          width: _selectedTabIndex == 0 ? 2 : 1,
                        ),
                        backgroundColor: _selectedTabIndex == 0 
                            ? (isDarkMode ? const Color(0xFF81AACE).withOpacity(0.1) : const Color(0xFF81AACE).withOpacity(0.1))
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          color: _selectedTabIndex == 0 
                              ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE))
                              : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        side: BorderSide(
                          color: _selectedTabIndex == 1 
                              ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE))
                              : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
                          width: _selectedTabIndex == 1 ? 2 : 1,
                        ),
                        backgroundColor: _selectedTabIndex == 1 
                            ? (isDarkMode ? const Color(0xFF81AACE).withOpacity(0.1) : const Color(0xFF81AACE).withOpacity(0.1))
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Financial',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          color: _selectedTabIndex == 1 
                              ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE))
                              : (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE)),
                        ),
                      ),
                    ),
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
          if (_isWatchlistOpen)
            Positioned.fill(
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
                        child: _buildWatchlistSidebar(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWatchlistSidebar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 1200 
        ? screenWidth * 0.35  // 35% of screen width on larger screens
        : screenWidth > 800 
            ? screenWidth * 0.4  // 40% on medium screens
            : screenWidth * 0.5; // 50% on smaller screens
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth.clamp(320.0, 600.0), // Min 320px, max 600px
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monitor,
                  size: 16,
                  color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MONITOR',
                    style: DashboardTextStyles.columnHeader.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleWatchlist,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 48,
                    color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO WATCHLISTS',
                    style: DashboardTextStyles.columnHeader.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first watchlist to\ntrack stocks and monitor positions',
                    textAlign: TextAlign.center,
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement create watchlist functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Create watchlist functionality coming soon...'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: isDarkMode ? const Color(0xFF374151) : const Color(0xFF6B7280),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CREATE WATCHLIST',
                            style: DashboardTextStyles.columnHeader.copyWith(
                              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    
    return _buildCompactTable('Price & Market', data, isDarkMode);
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
    
    return _buildCompactTable('Valuation', data, isDarkMode);
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
    
    return _buildCompactTable('Financial Ratios', data, isDarkMode);
  }

  Widget _buildPerformanceMetrics(StocksData stockData, bool isDarkMode) {
    final data = [
      ['1 Week', '${stockData.priceChange1WPercent?.toStringAsFixed(2) ?? '--'}%'],
      ['1 Month', '${stockData.priceChange1MPercent?.toStringAsFixed(2) ?? '--'}%'],
      ['3 Months', '${stockData.priceChange3MPercent?.toStringAsFixed(2) ?? '--'}%'],
      ['6 Months', '${stockData.priceChange6MPercent?.toStringAsFixed(2) ?? '--'}%'],
      ['1 Year', '${stockData.priceChange1YPercent?.toStringAsFixed(2) ?? '--'}%'],
      ['YTD', '${stockData.priceChangeYTDPercent?.toStringAsFixed(2) ?? '--'}%'],
    ];
    
    return _buildCompactTable('Performance', data, isDarkMode);
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
    
    return _buildCompactTable('Growth', data, isDarkMode);
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
    
    return _buildCompactTable('Risk & Efficiency', data, isDarkMode);
  }

  Widget _buildMarketTradingMetrics(StocksData stockData, bool isDarkMode) {
    final data = [
      ['Avg Volume (10D)', '${((stockData.avgVolume10days ?? 0) / 1000000).toStringAsFixed(1)}M'],
      ['Avg Volume (30D)', '${((stockData.avgVolume30days ?? 0) / 1000000).toStringAsFixed(1)}M'],
      ['Shares Outstanding', '${((stockData.sharesOutStanding ?? 0) / 1000000).toStringAsFixed(1)}M'],
      ['Float', '${((stockData.sharesOutStanding ?? 0) * 0.8 / 1000000).toStringAsFixed(1)}M'],
      ['Insider Ownership', '${(stockData.businessCompliantRatio ?? 0).toStringAsFixed(1)}%'],
      ['Institutional Hold', '${(stockData.businessQuestionableRatio ?? 0).toStringAsFixed(1)}%'],
    ];
    
    return _buildCompactTable('Market & Trading', data, isDarkMode);
  }

  Widget _buildCompactTable(String title, List<List<String>> data, bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
              style: DashboardTextStyles.columnHeader.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
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
                    fontSize: 11,
                  ),
                ),
                Text(
                  row[1],
                  style: DashboardTextStyles.dataCell.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
                              style: DashboardTextStyles.headerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.ticker.symbol ?? widget.ticker.ticker ?? 'TICKER',
                              style: DashboardTextStyles.headerTicker,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Price: \$${stockData.currentPrice?.toStringAsFixed(2) ?? '--'}',
                        style: DashboardTextStyles.headerPrice,
                      ),
                      Text(
                        'Change: ${stockData.change1DPercent?.toStringAsFixed(2) ?? '--'}%',
                        style: DashboardTextStyles.headerChange.copyWith(
                          color: stockData.change1DPercent != null
                              ? (stockData.change1DPercent! >= 0 ? Colors.green : Colors.red)
                              : DashboardTextStyles.headerChange.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Market Cap: ${Constants.getShortenedMarketCapV2(stockData.usdMarketCap)}',
                        style: DashboardTextStyles.headerMetric,
                      ),
                      Text(
                        'Volume: ${((stockData.volume ?? 0) / 1000000).toStringAsFixed(1)}M',
                        style: DashboardTextStyles.headerMetric,
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
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
                    style: DashboardTextStyles.headerTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (widget.ticker.sectorname != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sector:', style: DashboardTextStyles.headerMetric),
                        Text(
                          widget.ticker.sectorname!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (widget.ticker.countryName != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Country:', style: DashboardTextStyles.headerMetric),
                        Text(
                          widget.ticker.countryName!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (widget.ticker.exchange != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exchange:', style: DashboardTextStyles.headerMetric),
                        Text(
                          widget.ticker.exchange!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (widget.ticker.currency != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Currency:', style: DashboardTextStyles.headerMetric),
                        Text(
                          widget.ticker.currency!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  if (controller.companyProfile.value?.weburl != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Website:', style: DashboardTextStyles.headerMetric),
                        GestureDetector(
                          onTap: () {
                            // Open website in browser
                            final url = controller.companyProfile.value!.weburl!;
                            if (url.isNotEmpty) {
                              // You can use url_launcher package here
                              // For now, just show a snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening: $url'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Visit Site',
                            style: DashboardTextStyles.headerMetric.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
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
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
                    style: DashboardTextStyles.headerTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (stockData.bookValuePerShareAnnual != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Book Value:', style: DashboardTextStyles.headerMetric),
                        Text(
                          '\$${stockData.bookValuePerShareAnnual!.toStringAsFixed(2)}',
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.cashPerSharePerShareAnnual != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cash/Share:', style: DashboardTextStyles.headerMetric),
                        Text(
                          '\$${stockData.cashPerSharePerShareAnnual!.toStringAsFixed(2)}',
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.currentDividendYieldTTM != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dividend Yield:', style: DashboardTextStyles.headerMetric),
                        Text(
                          '${stockData.currentDividendYieldTTM!.toStringAsFixed(2)}%',
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (stockData.enterpriseValue != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Enterprise Value:', style: DashboardTextStyles.headerMetric),
                        Text(
                          Constants.getShortenedMarketCapV2(stockData.enterpriseValue),
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
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
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2), // Increased spacing for better readability
          Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
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
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildStockHeader(stockData, isDarkMode),
            const SizedBox(height: 16),

            // TradingView Chart and Analytics Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Half screen width for chart
                Expanded(
                  child: TradingViewWidget(
                    symbol: widget.ticker.symbol ?? widget.ticker.ticker ?? '',
                    controller: tradingViewController,
                    height: 400,
                  ),
                ),
                const SizedBox(width: 8),
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
            ),
            const SizedBox(height: 16),

            // Row 1: Price & Market, Valuation, Financial Ratios
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPriceMetrics(stockData, isDarkMode),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildValuationMetrics(stockData, isDarkMode),
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRiskMetrics(stockData, isDarkMode),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMarketTradingMetrics(stockData, isDarkMode),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Forecast/Recommendation Widget
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
            ),
            const SizedBox(height: 16),
            // News Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
  
}
