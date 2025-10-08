import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/trading_view_widget.dart';
import 'package:musaffa_terminal/Controllers/etf_details_controller.dart';
import 'package:musaffa_terminal/Controllers/trading_view_controller.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/models/etfs_data.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';

class EtfDetailsScreen extends StatefulWidget {
  final TickerModel ticker;

  const EtfDetailsScreen({
    Key? key,
    required this.ticker,
  }) : super(key: key);

  @override
  State<EtfDetailsScreen> createState() => _EtfDetailsScreenState();
}

class _EtfDetailsScreenState extends State<EtfDetailsScreen> {
  late WatchlistController watchlistController;
  late EtfDetailsController controller;
  late TradingViewController tradingViewController;
  bool _isWatchlistOpen = false;

  @override
  void initState() {
    super.initState();
    watchlistController = Get.put(WatchlistController());
    controller = Get.put(EtfDetailsController());
    tradingViewController = TradingViewController();
    
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchEtfDetails(widget.ticker.symbol ?? '');
    });
  }

  @override
  void dispose() {
    tradingViewController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
    });
  }

  String _formatSymbolForTradingView(EtfsData etfData) {
    final symbol = widget.ticker.symbol ?? etfData.symbol ?? '';
    final exchange = etfData.exchange ?? widget.ticker.exchange ?? '';
    
    // Check if symbol already has exchange prefix (e.g., "NYSE:SPY")
    if (symbol.contains(':')) {
      print('📊 TradingView Symbol (already prefixed): $symbol');
      return symbol;
    }
    
    // TradingView requires exchange prefix for ETFs
    if (exchange.isNotEmpty && symbol.isNotEmpty) {
      String tvExchange = exchange.toUpperCase();
      
      // TradingView uses specific exchange formats for ETFs
      // Most NYSE-listed ETFs are actually on NYSE Arca, which TradingView calls "AMEX"
      if (tvExchange.contains('NYSE') || tvExchange.contains('ARCA')) {
        tvExchange = 'AMEX'; // TradingView format for NYSE Arca ETFs
      } else if (tvExchange.contains('NASDAQ')) {
        tvExchange = 'NASDAQ';
      }
      
      final formattedSymbol = '$tvExchange:$symbol';
      print('📊 TradingView Symbol: $formattedSymbol (Original Exchange: $exchange → TradingView: $tvExchange, Symbol: $symbol)');
      return formattedSymbol;
    }
    
    // Fallback: Try AMEX (most common for ETFs)
    if (symbol.isNotEmpty) {
      print('⚠️ No exchange found, trying AMEX:$symbol as fallback');
      return 'AMEX:$symbol';
    }
    
    return symbol;
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
              
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (controller.errorMessage.isNotEmpty) {
                    return Center(
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    );
                  }
                  
                  if (controller.etfData.value == null) {
                    return const Center(child: Text('No data available'));
                  }
                  
                  final etfData = controller.etfData.value!;
                  return _buildEtfContent(etfData, isDarkMode);
                }),
              ),
            ],
          ),
          
          // Watchlist sidebar overlay
          if (_isWatchlistOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleWatchlist,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: WatchlistSidebar(
                          isDarkMode: isDarkMode,
                          onClose: _toggleWatchlist,
                        ),
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

  Widget _buildEtfContent(EtfsData etfData, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildEtfHeader(etfData, isDarkMode),
          const SizedBox(height: 16),

          // TradingView Chart and Performance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Half screen width for chart
              Expanded(
                child: TradingViewWidget(
                  symbol: _formatSymbolForTradingView(etfData),
                  controller: tradingViewController,
                  height: 400,
                ),
              ),
              const SizedBox(width: 8),
              // Half screen width for performance
              Expanded(
                child: _buildPerformanceHeatmap(etfData, isDarkMode),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ETF Metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPriceMetrics(etfData, isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildFundamentals(etfData, isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildExposureMetrics(etfData, isDarkMode)),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description Section
          if (etfData.etfProfile?.description != null)
            _buildDescriptionSection(etfData, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildEtfHeader(EtfsData etfData, bool isDarkMode) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ETF Logo
              showLogo(
                widget.ticker.symbol ?? '',
                widget.ticker.logo ?? '',
                sideWidth: 32,
                name: widget.ticker.symbol ?? '',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etfData.etfProfile?.name ?? widget.ticker.name ?? widget.ticker.companyName ?? 'ETF Name',
                      style: DashboardTextStyles.headerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      etfData.symbol ?? widget.ticker.symbol ?? 'TICKER',
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
                'Current Price: \$${etfData.currentPrice?.toStringAsFixed(2) ?? '--'}',
                style: DashboardTextStyles.headerPrice,
              ),
              Text(
                'Change: ${etfData.change1DPercent?.toStringAsFixed(2) ?? '--'}%',
                style: DashboardTextStyles.headerChange.copyWith(
                  color: etfData.change1DPercent != null
                      ? (etfData.change1DPercent! >= 0 ? Colors.green : Colors.red)
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
                'AUM: ${Constants.getShortenedMarketCapV2(etfData.aum)}',
                style: DashboardTextStyles.headerMetric,
              ),
              Text(
                'Volume: ${((etfData.volume ?? 0) / 1000000).toStringAsFixed(1)}M',
                style: DashboardTextStyles.headerMetric,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceMetrics(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['AUM', Constants.getShortenedMarketCapV2(etfData.aum)],
      ['52W High', '\$${etfData.d52WeekHigh?.toStringAsFixed(2) ?? '--'}'],
      ['52W Low', '\$${etfData.d52WeekLow?.toStringAsFixed(2) ?? '--'}'],
      ['Volume', '${((etfData.volume ?? 0) / 1000000).toStringAsFixed(1)}M'],
      ['NAV', '\$${etfData.nav?.toStringAsFixed(2) ?? '--'}'],
      ['Expense Ratio', '${etfData.expenseRatio?.toStringAsFixed(2) ?? '--'}%'],
    ];
    
    return _buildCompactTable('Price & Market', data, isDarkMode);
  }

  Widget _buildFundamentals(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['Holdings', '${etfData.numberOfHoldings ?? '--'}'],
      ['Inception', etfData.inceptionDate ?? '--'],
      ['Asset Class', etfData.assetClass ?? '--'],
      ['Segment', etfData.investmentSegment ?? '--'],
      ['P/E Ratio', etfData.priceToEarnings?.toStringAsFixed(2) ?? '--'],
      ['P/B Ratio', etfData.priceToBook?.toStringAsFixed(2) ?? '--'],
    ];
    
    return _buildCompactTable('Fundamentals', data, isDarkMode);
  }

  Widget _buildExposureMetrics(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['Mega Cap', '${etfData.megacapExposure?.toStringAsFixed(1) ?? '--'}%'],
      ['Large Cap', '${etfData.largecapExposure?.toStringAsFixed(1) ?? '--'}%'],
      ['Mid Cap', '${etfData.midcapExposure?.toStringAsFixed(1) ?? '--'}%'],
      ['Small Cap', '${etfData.smallcapExposure?.toStringAsFixed(1) ?? '--'}%'],
      ['Compliant', '${etfData.businessCompliantRatio?.toStringAsFixed(1) ?? '--'}%'],
      ['Non-Compliant', '${etfData.businessNonCompliantRatio?.toStringAsFixed(1) ?? '--'}%'],
    ];
    
    return _buildCompactTable('Exposure', data, isDarkMode);
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

  Widget _buildPerformanceHeatmap(EtfsData etfData, bool isDarkMode) {
    final performanceData = {
      '1D': etfData.change1DPercent ?? 0,
      '1W': etfData.priceChange1WPercent ?? 0,
      '1M': etfData.priceChange1MPercent ?? 0,
      '3M': etfData.priceChange3MPercent ?? 0,
      '6M': etfData.priceChange6MPercent ?? 0,
      '1Y': etfData.priceChange1YPercent ?? 0,
      '3Y': etfData.priceChange3YPercent ?? 0,
      '5Y': etfData.priceChange5YPercent ?? 0,
      'YTD': etfData.priceChangeYTDPercent ?? 0,
    };

    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 2,
              ),
              itemCount: performanceData.length,
              itemBuilder: (context, index) {
                final period = performanceData.keys.elementAt(index);
                final value = performanceData[period] ?? 0;
                return _buildHeatmapCell(period, value.toDouble(), isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCell(String period, double value, bool isDarkMode) {
    final isPositive = value >= 0;
    final absValue = value.abs();
    
    Color cellColor;
    Color textColor;
    
    if (absValue == 0) {
      cellColor = isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
      textColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    } else if (absValue <= 1) {
      cellColor = isPositive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
      textColor = isPositive ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    } else if (absValue <= 5) {
      cellColor = isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
      textColor = isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    } else if (absValue <= 15) {
      cellColor = isPositive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);
      textColor = isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    } else {
      cellColor = isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171);
      textColor = isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    }

    return Container(
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
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
          const SizedBox(height: 2),
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

  Widget _buildDescriptionSection(EtfsData etfData, bool isDarkMode) {
    return Container(
      width: double.infinity,
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
            'About',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            etfData.etfProfile!.description!,
            style: TextStyle(
              fontSize: 12,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
