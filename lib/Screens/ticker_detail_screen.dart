import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';
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

  @override
  void initState() {
    super.initState();
    controller = Get.put(StockDetailsController());
    
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchStockDetails(widget.ticker.symbol ?? widget.ticker.ticker ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: Column(
        children: [
          HomeTabBar(
            showBackButton: true,
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
                    // Row 2: Performance, Growth, Risk & Efficiency
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildPerformanceMetrics(stockData, isDarkMode),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGrowthMetrics(stockData, isDarkMode),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRiskMetrics(stockData, isDarkMode),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

    

  Widget _buildPriceMetrics(StocksData stockData, bool isDarkMode) {
    final data = [
      ['Market Cap', '\$${((stockData.usdMarketCap ?? 0) / 1000).toStringAsFixed(1)}B'],
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
      ['EBITDA', '${stockData.ebitdaEstimateAnnual?.toStringAsFixed(2) ?? '--'}'],
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
                        'Market Cap: \$${((stockData.usdMarketCap ?? 0) / 1000).toStringAsFixed(1)}B',
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
                          '\$${((stockData.enterpriseValue! / 1000)).toStringAsFixed(1)}B',
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
}
