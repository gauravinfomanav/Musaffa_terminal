import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';
import 'package:musaffa_terminal/services/sector_mapping_service.dart';
import 'package:musaffa_terminal/Controllers/sector_stocks_controller.dart';
import 'package:musaffa_terminal/Controllers/market_summary_controller.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';

class SectorDetailsScreen extends StatefulWidget {
  final String sectorName;

  const SectorDetailsScreen({Key? key, required this.sectorName}) : super(key: key);

  @override
  State<SectorDetailsScreen> createState() => _SectorDetailsScreenState();
}

class _SectorDetailsScreenState extends State<SectorDetailsScreen> {
  late WatchlistController watchlistController;
  late SectorStocksController sectorStocksController;
  bool _isWatchlistOpen = false;
  List<String>? _mappedSectors;

  @override
  void initState() {
    super.initState();
    watchlistController = Get.put(WatchlistController());
    sectorStocksController = Get.put(SectorStocksController());
    _initializeSectorMapping();
  }

  void _initializeSectorMapping() async {
    // Initialize the sector mapping service
    await SectorMappingService.initialize();
    
    // Get the mapped sectors for the clicked sector
    _mappedSectors = SectorMappingService.getMappedSectors(widget.sectorName);
    
    // Fetch stocks for the mapped sectors
    if (_mappedSectors != null && _mappedSectors!.isNotEmpty) {
      await sectorStocksController.fetchStocksForMappedSectors(
        sectorNames: _mappedSectors!,
        limitPerSector: 200, // Fetch all stocks
      );
    } else {
      // If no mapped sectors, try to fetch stocks for the original sector name
      await sectorStocksController.fetchStocksBySector(
        sectorName: widget.sectorName,
        limit: 1000, // Fetch all stocks
      );
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
    });
  }

  Widget _buildCombinedMetricsContainer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
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
              'Sector Overview',
              style: DashboardTextStyles.columnHeader.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTopPerformer(isDarkMode),
          _buildWorstPerformer(isDarkMode),
          _buildLargestMarketCapStock(isDarkMode),
          _buildMostActiveStock(isDarkMode),
          _buildSectorMetric('Total Stocks', '${sectorStocksController.totalStocks}'),
          _buildSectorMetric('Avg Market Cap', _getAverageMarketCap()),
          _buildSectorMetric('Total Volume', _getTotalVolume()),
        ],
      ),
    );
  }

  Widget _buildTopPerformer(bool isDarkMode) {
    final stocks = sectorStocksController.allSectorStocks;
    if (stocks.isEmpty) return const SizedBox.shrink();
    
    // Find best performing stock (highest positive change) from ALL stocks
    final topPerformer = stocks
        .where((stock) => (stock.priceChange1DPercent ?? 0) > 0)
        .fold<StocksData?>(null, (best, current) {
      if (best == null) return current;
      return (current.priceChange1DPercent ?? 0) > (best.priceChange1DPercent ?? 0) 
          ? current : best;
    });
    
    if (topPerformer == null) {
      return _buildPerformanceRow('Top Gainer', 'No positive performers', '--', isDarkMode);
    }
    
    return _buildPerformanceRow(
      'Top Gainer',
      topPerformer.companySymbol ?? topPerformer.ticker ?? '--',
      '${(topPerformer.priceChange1DPercent ?? 0).toStringAsFixed(2)}%',
      isDarkMode,
    );
  }

  Widget _buildWorstPerformer(bool isDarkMode) {
    final stocks = sectorStocksController.allSectorStocks;
    if (stocks.isEmpty) return const SizedBox.shrink();
    
    // Find worst performing stock (lowest negative change) from ALL stocks
    final worstPerformer = stocks
        .where((stock) => (stock.priceChange1DPercent ?? 0) < 0)
        .fold<StocksData?>(null, (worst, current) {
      if (worst == null) return current;
      return (current.priceChange1DPercent ?? 0) < (worst.priceChange1DPercent ?? 0) 
          ? current : worst;
    });
    
    if (worstPerformer == null) {
      return _buildPerformanceRow('Top Loser', 'No negative performers', '--', isDarkMode);
    }
    
    return _buildPerformanceRow(
      'Top Loser',
      worstPerformer.companySymbol ?? worstPerformer.ticker ?? '--',
      '${(worstPerformer.priceChange1DPercent ?? 0).toStringAsFixed(2)}%',
      isDarkMode,
    );
  }

  Widget _buildLargestMarketCapStock(bool isDarkMode) {
    final stocks = sectorStocksController.allSectorStocks;
    if (stocks.isEmpty) return const SizedBox.shrink();
    
    // Find stock with largest market cap from ALL stocks
    final largestMarketCap = stocks.fold<StocksData?>(null, (largest, current) {
      if (largest == null) return current;
      
      final currentMarketCap = current.usdMarketCap ?? 0;
      final largestMarketCapValue = largest.usdMarketCap ?? 0;
      
      return currentMarketCap > largestMarketCapValue ? current : largest;
    });
    
    if (largestMarketCap == null || (largestMarketCap.usdMarketCap ?? 0) == 0) {
      return _buildPerformanceRow('Largest Market Cap', 'No data available', '--', isDarkMode);
    }
    
    final marketCap = largestMarketCap.usdMarketCap! * 1000000; // Convert to actual value
    final marketCapStr = getShortenedT(marketCap);
    
    return _buildPerformanceRow(
      'Largest Market Cap',
      largestMarketCap.companySymbol ?? largestMarketCap.ticker ?? '--',
      marketCapStr,
      isDarkMode,
    );
  }

  Widget _buildMostActiveStock(bool isDarkMode) {
    final stocks = sectorStocksController.allSectorStocks;
    if (stocks.isEmpty) return const SizedBox.shrink();
    
    // Calculate average volume for the sector
    final totalVolume = stocks
        .where((stock) => stock.volume != null && stock.volume! > 0)
        .fold<double>(0, (sum, stock) => sum + stock.volume!);
    final averageVolume = totalVolume / stocks.length;
    
    // Find stock with highest volume relative to average
    final mostActive = stocks.fold<StocksData?>(null, (most, current) {
      if (most == null) return current;
      
      final currentVolume = current.volume ?? 0;
      final mostVolume = most.volume ?? 0;
      
      // Calculate relative activity (volume / average)
      final currentActivity = averageVolume > 0 ? currentVolume / averageVolume : 0;
      final mostActivity = averageVolume > 0 ? mostVolume / averageVolume : 0;
      
      return currentActivity > mostActivity ? current : most;
    });
    
    if (mostActive == null || (mostActive.volume ?? 0) == 0) {
      return _buildPerformanceRow('Most Active', 'No data available', '--', isDarkMode);
    }
    
    final volume = mostActive.volume!;
    final relativeActivity = averageVolume > 0 ? volume / averageVolume : 0;
    final activityStr = '${relativeActivity.toStringAsFixed(1)}x avg';
    
    return _buildPerformanceRow(
      'Most Active',
      mostActive.companySymbol ?? mostActive.ticker ?? '--',
      activityStr,
      isDarkMode,
    );
  }

  Widget _buildPerformanceRow(String label, String ticker, String change, bool isDarkMode) {
    // Determine color based on positive/negative change
    Color changeColor;
    if (change == '--') {
      changeColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    } else if (change.startsWith('+') || (double.tryParse(change.replaceAll('%', '')) ?? 0) > 0) {
      changeColor = const Color(0xFF10B981); // Green for positive
    } else {
      changeColor = const Color(0xFFEF4444); // Red for negative
    }
    
    return Container(
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
            label,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 11,
            ),
          ),
          Row(
            children: [
              Text(
                ticker,
                style: DashboardTextStyles.dataCell.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                change,
                style: DashboardTextStyles.dataCell.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSectorMetric(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
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
            label,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: DashboardTextStyles.dataCell.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChangesContainer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
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
              'Sector Performance',
              style: DashboardTextStyles.columnHeader.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPerformanceChangeRow('1D', _getSectorChange('1D')),
          _buildPerformanceChangeRow('5D', _getSectorChange('5D')),
          _buildPerformanceChangeRow('1M', _getSectorChange('1M')),
          _buildPerformanceChangeRow('3M', _getSectorChange('3M')),
          _buildPerformanceChangeRow('6M', _getSectorChange('6M')),
          _buildPerformanceChangeRow('1Y', _getSectorChange('1Y')),
        ],
      ),
    );
  }

  Widget _buildPerformanceChangeRow(String period, double change) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Color changeColor;
    if (change == 0) {
      changeColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    } else if (change > 0) {
      changeColor = const Color(0xFF10B981); // Green for positive
    } else {
      changeColor = const Color(0xFFEF4444); // Red for negative
    }
    
    return Container(
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
            period,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 11,
            ),
          ),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: DashboardTextStyles.dataCell.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }

  double _getSectorChange(String period) {
    // Get the market summary controller to access sector performance data
    final marketSummaryController = Get.find<MarketSummaryController>();
    final hits = marketSummaryController.data['hits'] as List?;
    
    if (hits == null) return 0.0;
    
    // Find the current sector in market summary data
    for (var hit in hits) {
      var document = hit['document'] as Map<String, dynamic>?;
      if (document == null) continue;
      
      var sector = document['Sector']?.toString() ?? '';
      
      // Check if this is our current sector or a mapped sector
      if (sector == widget.sectorName || _isMappedSector(sector)) {
        String? fieldName;
        switch (period) {
          case '1D':
            fieldName = '1 Day';
            break;
          case '5D':
            fieldName = '1 Week'; // Use 1W as closest to 5D
            break;
          case '1M':
            fieldName = '1 Month';
            break;
          case '3M':
            fieldName = '3 Months';
            break;
          case '6M':
            fieldName = '6 Months';
            break;
          case '1Y':
            fieldName = '1 Year';
            break;
        }
        
        if (fieldName != null) {
          final value = document[fieldName];
          if (value != null) {
            if (value is num) {
              return value.toDouble();
            } else if (value is String) {
              return double.tryParse(value) ?? 0.0;
            }
          }
        }
        break;
      }
    }
    
    return 0.0;
  }

  bool _isMappedSector(String sector) {
    // Check if this sector is mapped to our current sector
    if (SectorMappingService.hasSectorMapping(widget.sectorName)) {
      final mappedSectors = SectorMappingService.getMappedSectors(widget.sectorName);
      return mappedSectors?.contains(sector) ?? false;
    }
    return false;
  }

  String _getAverageMarketCap() {
    final stocks = sectorStocksController.allSectorStocks;
    if (stocks.isEmpty) return '--';
    
    final totalMarketCap = stocks
        .where((stock) => stock.usdMarketCap != null)
        .fold<double>(0, (sum, stock) => sum + (stock.usdMarketCap! * 1000000));
    
    final average = totalMarketCap / stocks.length;
    return getShortenedT(average);
  }

  String _getTotalVolume() {
    final stocks = sectorStocksController.allSectorStocks;
    if (stocks.isEmpty) return '--';
    
    final totalVolume = stocks
        .where((stock) => stock.volume != null)
        .fold<double>(0, (sum, stock) => sum + stock.volume!);
    
    return getShortenedT(totalVolume);
  }

  Widget _buildPaginationControls() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Obx(() {
      if (sectorStocksController.totalPages <= 1) return const SizedBox.shrink();
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info in the center-left
          Text(
            'Page ${sectorStocksController.currentPage + 1} of ${sectorStocksController.totalPages} (${sectorStocksController.totalStocks} stocks)',
            style: DashboardTextStyles.dataCell.copyWith(
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          
          // Navigation buttons on the right
          Padding(
            padding: const EdgeInsets.only(right: 30),
            child: Row(
              children: [
                // Previous button - only show if not on first page
                if (sectorStocksController.hasPreviousPage) ...[
                  GestureDetector(
                    onTap: () => sectorStocksController.previousPage(),
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
                        style: DashboardTextStyles.dataCell.copyWith(
                          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Next button - only show if there are more pages
                if (sectorStocksController.hasNextPage)
                  GestureDetector(
                    onTap: () => sectorStocksController.nextPage(),
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
                        style: DashboardTextStyles.dataCell.copyWith(
                          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStocksTable() {
    // Convert StocksData to SimpleRowModel for the table
    List<SimpleRowModel> rows = sectorStocksController.sectorStocks.map((stock) {
      final isPositive = (stock.priceChange1DPercent ?? 0) >= 0;
      final changeColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
      
      return SimpleRowModel(
        symbol: stock.ticker ?? '',
        name: stock.companySymbol ?? stock.ticker ?? '',
        logo: sectorStocksController.logoMap[stock.ticker],
        price: stock.currentPrice,
        changePercent: stock.priceChange1DPercent,
        fields: {
          'ticker': stock.ticker ?? '--',
          'price': stock.currentPrice != null ? '\$${stock.currentPrice!.toStringAsFixed(2)}' : '--',
          'change': stock.priceChange1DPercent != null ? '${stock.priceChange1DPercent!.toStringAsFixed(2)}%' : '--',
          'marketCap': stock.usdMarketCap != null ? getShortenedT(stock.usdMarketCap! * 1000000) : '--',
          'sector': stock.sector ?? '--',
          'industry': stock.industry ?? '--',
          'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
        },
        changeColor: changeColor,
        isPositive: isPositive,
      );
    }).toList();

    return DynamicTable(
      columns: const [
        SimpleColumn(label: 'PRICE', fieldName: 'price', isNumeric: true),
        SimpleColumn(label: 'CHANGE', fieldName: 'change', isNumeric: true),
        SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
        SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
      ],
      rows: rows,
      showFixedColumn: true,
      considerPadding: false,
      enableDragging: true,
      onDragStarted: () {
        print('Drag started on sector stock');
      },
      onDragEnd: () {
        print('Drag ended on sector stock');
      },
    );
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
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Sector Header - Following app design pattern
                      Text(
                        widget.sectorName,
                        style: DashboardTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 16),
                      // Stocks Table
                      Obx(() {
                        if (sectorStocksController.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        if (sectorStocksController.errorMessage.value.isNotEmpty) {
                          return Center(
                            child: Text(
                              sectorStocksController.errorMessage.value,
                              style: DashboardTextStyles.errorMessage,
                            ),
                          );
                        }
                        
                        if (sectorStocksController.sectorStocks.isEmpty) {
                          return Center(
                            child: Text(
                              'No stocks found for this sector',
                              style: DashboardTextStyles.noData,
                            ),
                          );
                        }
                        
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Main table - takes most of the space
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        _buildStocksTable(),
                                        const SizedBox(height: 16),
                                        _buildPaginationControls(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
            // Performance widgets - fixed width
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  _buildCombinedMetricsContainer(),
                  const SizedBox(height: 16),
                  _buildPerformanceChangesContainer(),
                ],
              ),
            ),
                                ],
                              );
                      }),
                    ],
                  ),
                ),
              ),
                ),
            ],
          ),
          // Watchlist Sidebar
          if (_isWatchlistOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 400,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
                  border: Border(
                    left: BorderSide(
                      color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: WatchlistDropdown(isDarkMode: isDarkMode),
              ),
            ),
        ],
      ),
    );
  }
}
