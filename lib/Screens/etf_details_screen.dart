import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/trading_view_widget.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
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
    
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchEtfDetails(widget.ticker.symbol ?? '');
      controller.fetchEtfHoldings(widget.ticker.symbol ?? '');
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
    
    
    if (symbol.contains(':')) {
      return symbol;
    }
    
    
    if (exchange.isNotEmpty && symbol.isNotEmpty) {
      String tvExchange = exchange.toUpperCase();
      
    
      if (tvExchange.contains('NYSE') || tvExchange.contains('ARCA')) {
        tvExchange = 'AMEX'; // TradingView format for NYSE Arca ETFs
      } else if (tvExchange.contains('NASDAQ')) {
        tvExchange = 'NASDAQ';
      }
      
      return '$tvExchange:$symbol';
    }
    
    
    if (symbol.isNotEmpty) {
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

        
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        
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

          // ETF Key Metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTradingData(etfData, isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildKeyMetrics(etfData, isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildReturnsData(etfData, isDarkMode)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Charts Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCapExposureChart(etfData, isDarkMode)),
              const SizedBox(width: 16),
              Expanded(child: _buildSectorExposureChart(etfData, isDarkMode)),
            ],
          ),
          const SizedBox(height: 16),
          
        // Holdings Table
        _buildHoldingsTable(isDarkMode),
        const SizedBox(height: 16),
        _buildHoldingsPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildEtfHeader(EtfsData etfData, bool isDarkMode) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Container 1: ETF Identity & Current Status
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
                        'Change: ${etfData.priceChange1D?.toStringAsFixed(2) ?? '--'}',
                        style: DashboardTextStyles.headerChange.copyWith(
                          color: etfData.change1DPercent != null
                              ? (etfData.priceChange1D! >= 0 ? Colors.green : Colors.red)
                              : DashboardTextStyles.headerChange.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Volume:', style: DashboardTextStyles.headerMetric),
                      Text(
                        '${((etfData.volume ?? 0) / 1000000).toStringAsFixed(1)}M',
                        style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('52W High:', style: DashboardTextStyles.headerMetric),
                      Text(
                        '\$${etfData.d52WeekHigh?.toStringAsFixed(2) ?? '--'}',
                        style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('52W Low:', style: DashboardTextStyles.headerMetric),
                      Text(
                        '\$${etfData.d52WeekLow?.toStringAsFixed(2) ?? '--'}',
                        style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Container 2: Fund Information
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
                    'Fund Information',
                    style: DashboardTextStyles.headerTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (etfData.exchange != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exchange:', style: DashboardTextStyles.headerMetric),
                        Text(
                          etfData.exchange!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (etfData.domicile != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Domicile:', style: DashboardTextStyles.headerMetric),
                        Text(
                          etfData.domicile!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (etfData.assetClass != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Asset Class:', style: DashboardTextStyles.headerMetric),
                        Text(
                          etfData.assetClass!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (etfData.investmentSegment != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Segment:', style: DashboardTextStyles.headerMetric),
                        Text(
                          etfData.investmentSegment!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (etfData.inceptionDate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Inception:', style: DashboardTextStyles.headerMetric),
                        Text(
                          etfData.inceptionDate!,
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Container 3: Key Metrics
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
                    'Key Metrics',
                    style: DashboardTextStyles.headerTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (etfData.numberOfHoldings != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Holdings:', style: DashboardTextStyles.headerMetric),
                        Text(
                          '${etfData.numberOfHoldings}',
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (etfData.expenseRatio != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Expense Ratio:', style: DashboardTextStyles.headerMetric),
                        Text(
                          '${etfData.expenseRatio!.toStringAsFixed(2)}%',
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (etfData.nav != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NAV:', style: DashboardTextStyles.headerMetric),
                        Text(
                          '\$${etfData.nav!.toStringAsFixed(2)}',
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AUM:', style: DashboardTextStyles.headerMetric),
                      Text(
                        Constants.getShortenedMarketCapV2(etfData.aum),
                        style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (etfData.dividentAmount != null && etfData.dividentAmount! > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dividend:', style: DashboardTextStyles.headerMetric),
                        Text(
                          '\$${etfData.dividentAmount!.toStringAsFixed(2)}',
                          style: DashboardTextStyles.headerMetric.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingData(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['Open', '\$${etfData.open?.toStringAsFixed(2) ?? '--'}'],
      ['High', '\$${etfData.high?.toStringAsFixed(2) ?? '--'}'],
      ['Low', '\$${etfData.low?.toStringAsFixed(2) ?? '--'}'],
      ['Close', '\$${etfData.close?.toStringAsFixed(2) ?? '--'}'],
      ['Prev Close', '\$${etfData.previousClose?.toStringAsFixed(2) ?? '--'}'],
      ['Volume', '${((etfData.volume ?? 0) / 1000000).toStringAsFixed(1)}M'],
    ];
    
    return _buildCompactTable('Trading Data', data, isDarkMode);
  }

  Widget _buildKeyMetrics(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['P/E Ratio', etfData.priceToEarnings?.toStringAsFixed(2) ?? '--'],
      ['P/B Ratio', etfData.priceToBook?.toStringAsFixed(2) ?? '--'],
      ['Compliant', '${etfData.businessCompliantRatio?.toStringAsFixed(1) ?? '--'}%'],
      ['Non-Compliant', '${etfData.businessNonCompliantRatio?.toStringAsFixed(1) ?? '--'}%'],
      ['Interest Assets', '${etfData.interestBearingAssetsRatio?.toStringAsFixed(1) ?? '--'}%'],
      ['Interest Debt', '${etfData.interestBearingDebtRatio?.toStringAsFixed(1) ?? '--'}%'],
    ];
    
    return _buildCompactTable('Key Metrics', data, isDarkMode);
  }

  Widget _buildReturnsData(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['Return 1M', '${etfData.totalReturn1M?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 1Y', '${etfData.totalReturn1Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 3Y', '${etfData.totalReturn3Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 5Y', '${etfData.totalReturn5Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 6M', '${etfData.totalReturn6M?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 1W', '${etfData.totalReturn1W?.toStringAsFixed(2) ?? '--'}%'],
    ];
    
    return _buildCompactTable('Total Returns', data, isDarkMode);
  }

  Widget _buildCapExposureChart(EtfsData etfData, bool isDarkMode) {
    final capData = {
      'Mega Cap': etfData.megacapExposure ?? 0,
      'Large Cap': etfData.largecapExposure ?? 0,
      'Mid Cap': etfData.midcapExposure ?? 0,
      'Small Cap': etfData.smallcapExposure ?? 0,
      'Micro Cap': etfData.microcapExposure ?? 0,
      'Nano Cap': etfData.nanocapExposure ?? 0,
    };

    // Filter out zero values
    final filteredData = Map.fromEntries(
      capData.entries.where((entry) => entry.value > 0),
    );

    return _buildPieChartContainer(
      title: 'Market Cap Exposure',
      data: filteredData,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildSectorExposureChart(EtfsData etfData, bool isDarkMode) {
    if (etfData.sectorExposure == null || etfData.sectorExposure!.isEmpty) {
      return _buildPieChartContainer(
        title: 'Sector Exposure',
        data: {},
        isDarkMode: isDarkMode,
      );
    }

    // Convert sector exposure to Map<String, num> and sort by value (descending)
    final sectorData = <String, num>{};
    etfData.sectorExposure!.forEach((key, value) {
      if (value is num && value > 0) {
        sectorData[key] = value;
      }
    });

    // Sort by value in descending order (highest first)
    final sortedEntries = sectorData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedSectorData = <String, num>{};
    for (final entry in sortedEntries) {
      sortedSectorData[entry.key] = entry.value;
    }

    return _buildPieChartContainer(
      title: 'Sector Exposure',
      data: sortedSectorData,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildPieChartContainer({
    required String title,
    required Map<String, num> data,
    required bool isDarkMode,
  }) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No data available',
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildInteractivePieChart(data, isDarkMode),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Legend
                Expanded(
                  flex: 3,
                  child: _buildChartLegend(data, isDarkMode),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Map<String, num> data, bool isDarkMode) {
    final colors = _getChartColors();
    final entries = data.entries.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        entries.length,
        (index) {
          final entry = entries[index];
          final color = colors[index % colors.length];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 6,right: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${entry.value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractivePieChart(Map<String, num> data, bool isDarkMode) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final center = Offset(box.size.width / 2, box.size.height / 2);
            final radius = box.size.width / 2 * 0.8;
            
            // Calculate which segment was tapped
            final dx = localPosition.dx - center.dx;
            final dy = localPosition.dy - center.dy;
            final distance = math.sqrt(dx * dx + dy * dy);
            
            if (distance <= radius && distance >= radius * 0.5) {
              final angle = math.atan2(dy, dx);
              final normalizedAngle = (angle + math.pi / 2) % (2 * math.pi);
              
              final total = data.values.fold<num>(0, (sum, value) => sum + value);
              double currentAngle = 0;
              
              for (final entry in data.entries) {
                final sweepAngle = (entry.value / total) * 2 * math.pi;
                if (normalizedAngle >= currentAngle && normalizedAngle <= currentAngle + sweepAngle) {
                  _showTooltip(context, entry.key, entry.value, details.globalPosition);
                  break;
                }
                currentAngle += sweepAngle;
              }
            }
          },
          child: CustomPaint(
            painter: PieChartPainter(
              data: data,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
    );
  }

  void _showTooltip(BuildContext context, String label, num value, Offset position) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 50,
        top: position.dy - 40,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Remove tooltip after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _buildHoldingsTable(bool isDarkMode) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Holdings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                      ),
                    ),
                    Obx(() {
                      final totalHoldings = controller.holdingsData.value?.holdings.length ?? 0;
                      return Text(
                        '$totalHoldings Holdings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
          
          Obx(() {
            if (controller.isLoadingHoldings.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (controller.holdingsErrorMessage.value.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    'Error: ${controller.holdingsErrorMessage.value}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              );
            }
            
            final enrichedHoldings = controller.enrichedHoldings;
            if (enrichedHoldings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    'No holdings data available',
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              );
            }
            
            // Convert to SimpleRowModel for DynamicTable (already sorted by controller)
            final tableRows = enrichedHoldings.map((enrichedHolding) {
              final holding = enrichedHolding.holding;
              final stockData = enrichedHolding.stockData;
              final companyProfile = enrichedHolding.companyProfile;
              
              return SimpleRowModel(
                symbol: holding.symbol,
                name: companyProfile?.name ?? holding.name,
                logo: companyProfile?.logo,
                price: stockData?.currentPrice,
                changePercent: stockData?.priceChange1DPercent,
                currency: 'USD',
                fields: {
                  'weight': '${holding.percent.toStringAsFixed(2)}%',
                  'value': Constants.getShortenedMarketCapV2(holding.value),
                  'currentPrice': stockData?.currentPrice != null ? '\$${stockData!.currentPrice!.toStringAsFixed(2)}' : '--',
                  'change': stockData?.priceChange1D != null ? '${stockData!.priceChange1D!.toStringAsFixed(2)}' : '--',
                  'changePercent': stockData?.priceChange1DPercent != null ? '${stockData!.priceChange1DPercent!.toStringAsFixed(2)}%' : '--',
                  'volume': stockData?.volume != null ? '${((stockData!.volume! / 1000000).toStringAsFixed(1))}M' : '--',
                  'marketCap': stockData?.usdMarketCap != null ? Constants.getShortenedMarketCapV2(stockData!.usdMarketCap!) : '--',
                  'pe': stockData?.peTTM != null ? '${stockData!.peTTM!.toStringAsFixed(1)}' : '--',
                  'pb': stockData?.pbAnnual != null ? '${stockData!.pbAnnual!.toStringAsFixed(2)}' : '--',
                  'ps': stockData?.psTTM != null ? '${stockData!.psTTM!.toStringAsFixed(1)}' : '--',
                  'eps': stockData?.epsTTM != null ? '\$${stockData!.epsTTM!.toStringAsFixed(2)}' : '--',
                  'dividend': stockData?.currentDividendYieldTTM != null ? '${stockData!.currentDividendYieldTTM!.toStringAsFixed(2)}%' : '--',
                  'beta': stockData?.beta != null ? '${stockData!.beta!.toStringAsFixed(2)}' : '--',
                  'roe': stockData?.rOE != null ? '${stockData!.rOE!.toStringAsFixed(1)}%' : '--',
                  'margin': stockData?.netProfitMarginTTM != null ? '${stockData!.netProfitMarginTTM!.toStringAsFixed(1)}%' : '--',
                  'debt': stockData?.longTermDebtEquityAnnual != null ? '${stockData!.longTermDebtEquityAnnual!.toStringAsFixed(1)}%' : '--',
                  '52wHigh': stockData?.d52WeekHigh != null ? '\$${stockData!.d52WeekHigh!.toStringAsFixed(2)}' : '--',
                  '52wLow': stockData?.d52WeekLow != null ? '\$${stockData!.d52WeekLow!.toStringAsFixed(2)}' : '--',
                  'return1Y': stockData?.priceChange1YPercent != null ? '${stockData!.priceChange1YPercent!.toStringAsFixed(1)}%' : '--',
                  'return3Y': stockData?.priceChange3YPercent != null ? '${stockData!.priceChange3YPercent!.toStringAsFixed(1)}%' : '--',
                },
                changeColor: stockData?.priceChange1D != null 
                    ? (stockData!.priceChange1D! >= 0 ? Colors.green : Colors.red)
                    : null,
              );
            }).toList();
            
            return DynamicTable(
              columns: const [
                SimpleColumn(label: 'WEIGHT', fieldName: 'weight', isNumeric: true),
                SimpleColumn(label: 'VALUE', fieldName: 'value', isNumeric: true),
                SimpleColumn(label: 'PRICE', fieldName: 'currentPrice', isNumeric: true),
                SimpleColumn(label: 'CHANGE', fieldName: 'change', isNumeric: true),
                SimpleColumn(label: 'CHANGE %', fieldName: 'changePercent', isNumeric: true),
                SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
                SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
                SimpleColumn(label: 'P/E', fieldName: 'pe', isNumeric: true),
                SimpleColumn(label: 'P/B', fieldName: 'pb', isNumeric: true),
                SimpleColumn(label: 'P/S', fieldName: 'ps', isNumeric: true),
                SimpleColumn(label: 'EPS', fieldName: 'eps', isNumeric: true),
                SimpleColumn(label: 'DIV YIELD', fieldName: 'dividend', isNumeric: true),
                SimpleColumn(label: 'BETA', fieldName: 'beta', isNumeric: true),
                SimpleColumn(label: 'ROE', fieldName: 'roe', isNumeric: true),
                SimpleColumn(label: 'MARGIN', fieldName: 'margin', isNumeric: true),
                SimpleColumn(label: 'DEBT/EQUITY', fieldName: 'debt', isNumeric: true),
                SimpleColumn(label: '52W HIGH', fieldName: '52wHigh', isNumeric: true),
                SimpleColumn(label: '52W LOW', fieldName: '52wLow', isNumeric: true),
                SimpleColumn(label: '1Y RETURN', fieldName: 'return1Y', isNumeric: true),
                SimpleColumn(label: '3Y RETURN', fieldName: 'return3Y', isNumeric: true),
              ],
              rows: tableRows,
              showFixedColumn: true,
              considerPadding: false,
              columnSpacing: 16,
              fixedColumnWidth: 0,
              enableDragging: true,
              enableLivePrices: true,
              onDragStarted: () {
                // Drag started
              },
              onDragEnd: () {
                // Drag ended
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHoldingsPaginationControls() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Obx(() {
      if (controller.totalHoldingsPages.value <= 1) return const SizedBox.shrink();
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info in the center-left
          Text(
            'Page ${controller.currentHoldingsPage.value + 1} of ${controller.totalHoldingsPages.value} (${controller.holdingsData.value?.holdings.length ?? 0} holdings)',
            style: TextStyle(
              fontSize: 12,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          
          // Navigation buttons on the right
          Row(
            children: [
              // Previous button - only show if not on first page
              if (controller.hasPreviousHoldingsPage) ...[
                GestureDetector(
                  onTap: () => controller.previousHoldingsPage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Next button - only show if there are more pages
              if (controller.hasNextHoldingsPage)
                GestureDetector(
                  onTap: () => controller.nextHoldingsPage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }



  List<Color> _getChartColors() {
    return [
      const Color(0xFF60A5FA), // Blue
      const Color(0xFF34D399), // Green
      const Color(0xFFFBBF24), // Yellow
      const Color(0xFFF87171), // Red
      const Color(0xFFA78BFA), // Purple
      const Color(0xFFFB923C), // Orange
      const Color(0xFF2DD4BF), // Teal
      const Color(0xFFFB7185), // Pink
      const Color(0xFF4ADE80), // Light Green
      const Color(0xFF818CF8), // Indigo
      const Color(0xFFFCD34D), // Light Yellow
      const Color(0xFF9CA3AF), // Gray
    ];
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

}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final Map<String, num> data;
  final bool isDarkMode;

  PieChartPainter({
    required this.data,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8; // 80% of half width
    
    // Calculate total
    final total = data.values.fold<num>(0, (sum, value) => sum + value);
    if (total == 0) return;

    // Chart colors
    final colors = [
      const Color(0xFF60A5FA), // Blue
      const Color(0xFF34D399), // Green
      const Color(0xFFFBBF24), // Yellow
      const Color(0xFFF87171), // Red
      const Color(0xFFA78BFA), // Purple
      const Color(0xFFFB923C), // Orange
      const Color(0xFF2DD4BF), // Teal
      const Color(0xFFFB7185), // Pink
      const Color(0xFF4ADE80), // Light Green
      const Color(0xFF818CF8), // Indigo
      const Color(0xFFFCD34D), // Light Yellow
      const Color(0xFF9CA3AF), // Gray
    ];

    double startAngle = -math.pi / 2; // Start from top (-90 degrees)
    
    final entries = data.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border between slices
      final borderPaint = Paint()
        ..color = isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
