import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/services/sector_mapping_service.dart';
import 'package:musaffa_terminal/Controllers/sector_stocks_controller.dart';
import 'package:musaffa_terminal/Controllers/market_summary_controller.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';

class SectorDetailsScreen extends StatefulWidget {
  final String sectorName;

  const SectorDetailsScreen({Key? key, required this.sectorName}) : super(key: key);

  @override
  State<SectorDetailsScreen> createState() => _SectorDetailsScreenState();
}

class _SectorDetailsScreenState extends State<SectorDetailsScreen> {
  late WatchlistController watchlistController;
  late SectorStocksController sectorStocksController;
  final GlobalWatchlistService _watchlistService = Get.find<GlobalWatchlistService>();
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
    if (!_watchlistService.isWatchlistOpen.value) {
      watchlistController.resetToDefaultWatchlist();
    }
    _watchlistService.toggleWatchlist();
  }

  Widget _buildCombinedMetricsContainer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
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
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              'Sector Overview',
              style: DashboardTextStyles.columnHeader.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                fontFamily: Constants.FONT_DEFAULT_NEW,
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
      '${(topPerformer.priceChange1DPercent ?? 0) >= 0 ? '+' : ''}${(topPerformer.priceChange1DPercent ?? 0).toStringAsFixed(2)}%',
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
      '${(worstPerformer.priceChange1DPercent ?? 0) >= 0 ? '+' : ''}${(worstPerformer.priceChange1DPercent ?? 0).toStringAsFixed(2)}%',
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
    if (change == '--' || change == '-') {
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
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
          Row(
            children: [
              Text(
                ticker,
                style: DashboardTextStyles.dataCell.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                change,
                style: DashboardTextStyles.dataCell.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
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
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
          Text(
            value,
            style: DashboardTextStyles.dataCell.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final highlightColor = isDarkMode ? const Color(0xFF373E45) : const Color(0xFFF3F4F6);

    Widget shimmerBox({double width = double.infinity, double height = 18}) {
      return ShimmerWidgets.box(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(6),
        baseColor: baseColor,
        highlightColor: highlightColor,
      );
    }

    Widget buildTableRowSkeleton() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            shimmerBox(width: 110, height: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: List.generate(6, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index == 5 ? 0 : 20),
                    child: shimmerBox(width: 90, height: 18),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildCardSkeleton({int rows = 6}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF151718) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerBox(width: 220, height: 22),
            const SizedBox(height: 20),
            ...List.generate(rows, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      shimmerBox(width: 150, height: 18),
                      shimmerBox(width: 110, height: 18),
                    ],
                  ),
                )),
          ],
        ),
      );
    }

    Widget buildGainersLosersSkeleton() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF151718) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerBox(width: 200, height: 22),
            const SizedBox(height: 20),
            ...List.generate(7, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      shimmerBox(width: 60, height: 18),
                      const SizedBox(width: 16),
                      shimmerBox(width: 110, height: 18),
                      const SizedBox(width: 16),
                      shimmerBox(width: 90, height: 18),
                      const Spacer(),
                      shimmerBox(width: 100, height: 18),
                    ],
                  ),
                )),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerBox(width: 280, height: 28),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF151718) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF2A2F33)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerBox(width: 240, height: 24),
                        const SizedBox(height: 24),
                        ...List.generate(10, (_) => buildTableRowSkeleton()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      shimmerBox(width: 280, height: 20),
                      Row(
                        children: [
                          shimmerBox(width: 140, height: 20),
                          const SizedBox(width: 16),
                          shimmerBox(width: 140, height: 20),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  buildCardSkeleton(rows: 7),
                  const SizedBox(height: 20),
                  buildCardSkeleton(rows: 7),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: buildGainersLosersSkeleton()),
            const SizedBox(width: 20),
            Expanded(child: buildGainersLosersSkeleton()),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceChangesContainer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
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
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              'Sector Performance',
              style: DashboardTextStyles.columnHeader.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                fontFamily: Constants.FONT_DEFAULT_NEW,
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
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: DashboardTextStyles.dataCell.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
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
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          
          // Navigation buttons on the right
          Row(
              children: [
                // Previous button - only show if not on first page (Secondary)
                if (sectorStocksController.hasPreviousPage) ...[
                  GestureDetector(
                    onTap: () => sectorStocksController.previousPage(),
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
                        'Previous',
                        style: DashboardTextStyles.dataCell.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Next button - only show if there are more pages (Primary)
                if (sectorStocksController.hasNextPage)
                  GestureDetector(
                    onTap: () => sectorStocksController.nextPage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: Text(
                        'Next',
                        style: DashboardTextStyles.dataCell.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          color: Colors.white,
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

  Widget _buildStocksTable() {
    final rows = sectorStocksController.sectorStocks.map((stock) {
      final symbol = stock.ticker ?? '--';
      final companyName = sectorStocksController.companyNamesMap[stock.ticker] ??
          stock.companySymbol ??
          stock.ticker ??
          '--';

      return DynamicTableRow(
        id: symbol,
        data: {
          'ticker': symbol,
          'company': companyName,
          'logo': sectorStocksController.logoMap[stock.ticker],
          'price': stock.currentPrice != null
              ? '\$${stock.currentPrice!.toStringAsFixed(2)}'
              : '--',
          'change': stock.priceChange1DPercent != null
              ? '${stock.priceChange1DPercent! >= 0 ? '+' : ''}${stock.priceChange1DPercent!.toStringAsFixed(2)}%'
              : '--',
          'changeAmount': stock.change1D != null
              ? '\$${stock.change1D!.toStringAsFixed(2)}'
              : '--',
          'marketCap': stock.usdMarketCap != null
              ? getShortenedT(stock.usdMarketCap! * 1000000)
              : '--',
          'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
          'sector': stock.sector ?? '--',
          'beta': stock.beta != null ? stock.beta!.toStringAsFixed(2) : '--',
          'week52High': stock.d52WeekHigh != null
              ? '\$${stock.d52WeekHigh!.toStringAsFixed(2)}'
              : '--',
          'week52Low': stock.d52WeekLow != null
              ? '\$${stock.d52WeekLow!.toStringAsFixed(2)}'
              : '--',
          'avgVol10d': stock.avgVolume10days != null
              ? getShortenedT(stock.avgVolume10days!)
              : '--',
        },
      );
    }).toList();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Table
          Padding(
            padding: const EdgeInsets.all(12),
            child: DynamicTableFromWeb(
              title: 'Sector Stocks',
              subtitle: 'Sortable and searchable sector stock list',
              showTickerCell: true,
              tickerKey: 'ticker',
              companyKey: 'company',
              logoKey: 'logo',
              tickerHeaderLabel: 'Ticker',
              columns: const [
                DynamicTableColumn(key: 'price', label: 'Price', sortable: true),
                DynamicTableColumn(key: 'change', label: 'Change %', sortable: true),
                DynamicTableColumn(key: 'changeAmount', label: 'Change \$', sortable: true),
                DynamicTableColumn(key: 'marketCap', label: 'MKT CAP', sortable: true),
                DynamicTableColumn(key: 'volume', label: 'Volume', sortable: true),
                DynamicTableColumn(key: 'sector', label: 'Sector', sortable: true),
                DynamicTableColumn(key: 'beta', label: 'Beta', sortable: true),
                DynamicTableColumn(key: 'week52High', label: '52W High', sortable: true),
                DynamicTableColumn(key: 'week52Low', label: '52W Low', sortable: true),
                DynamicTableColumn(key: 'avgVol10d', label: 'Avg Vol 10D', sortable: true),
              ],
              rows: rows,
              searchable: true,
              paginated: false,
              enableColumnVisibilityToggle: true,
              enableColumnFilters: false,
              stickyHeader: true,
              maxHeight: 560,
              onTickerTap: (row) {
                final ticker = row.data['ticker']?.toString() ?? '';
                if (ticker.isEmpty || ticker == '--') return;

                final companyName = row.data['company']?.toString() ?? ticker;
                final logo = row.data['logo']?.toString();
                final stock = sectorStocksController.allSectorStocks.firstWhereOrNull(
                  (s) => (s.ticker ?? '').toUpperCase() == ticker.toUpperCase(),
                );

                final tickerModel = TickerModel(
                  symbol: ticker,
                  ticker: ticker,
                  mainTicker: ticker,
                  name: companyName,
                  companyName: companyName,
                  logo: (logo != null && logo.isNotEmpty) ? logo : null,
                  currentPrice: stock?.currentPrice,
                  percentChange: stock?.priceChange1DPercent,
                  currency: stock?.currency ?? 'USD',
                  isStock: true,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TickerDetailScreen(ticker: tickerModel),
                  ),
                );
              },
            ),
          ),
          // Pagination controls at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildPaginationControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGainersLosersTables() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get top 5 gainers and losers from all sector stocks
    final allStocks = sectorStocksController.allSectorStocks;
    final topGainers = allStocks
        .where((stock) => stock.priceChange1DPercent != null)
        .toList()
        ..sort((a, b) => (b.priceChange1DPercent ?? 0).compareTo(a.priceChange1DPercent ?? 0));
    
    final topLosers = allStocks
        .where((stock) => stock.priceChange1DPercent != null)
        .toList()
        ..sort((a, b) => (a.priceChange1DPercent ?? 0).compareTo(b.priceChange1DPercent ?? 0));

    return Row(
      children: [
        // Top 5 Gainers Table
        Expanded(
          child: _buildGainersLosersTable(
            title: 'Top 5 Gainers',
            stocks: topGainers.take(5).toList(),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        // Top 5 Losers Table
        Expanded(
          child: _buildGainersLosersTable(
            title: 'Top 5 Losers',
            stocks: topLosers.take(5).toList(),
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildGainersLosersTable({
    required String title,
    required List<StocksData> stocks,
    required bool isDarkMode,
  }) {
    // Convert to SimpleRowModel
    List<SimpleRowModel> rows = stocks.map((stock) {
      final isPositive = (stock.priceChange1DPercent ?? 0) >= 0;
      final changeColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
      
      return SimpleRowModel(
        symbol: stock.ticker ?? '',
        name: sectorStocksController.companyNamesMap[stock.ticker] ?? stock.companySymbol ?? stock.ticker ?? '',
        logo: sectorStocksController.logoMap[stock.ticker],
        price: stock.currentPrice,
        changePercent: stock.priceChange1DPercent,
        currency: stock.currency ?? 'USD',
        fields: {
          'price': stock.currentPrice != null ? '\$${stock.currentPrice!.toStringAsFixed(2)}' : '--',
          'change': stock.priceChange1DPercent != null ? '${stock.priceChange1DPercent! >= 0 ? '+' : ''}${stock.priceChange1DPercent!.toStringAsFixed(2)}%' : '--',
          'changeAmount': stock.change1D != null ? '\$${stock.change1D!.toStringAsFixed(2)}' : '--',
          'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
          'marketCap': stock.usdMarketCap != null ? getShortenedT(stock.usdMarketCap! * 1000000) : '--',
          'avgVol10d': stock.avgVolume10days != null ? getShortenedT(stock.avgVolume10days!) : '--',
          'beta': stock.beta != null ? stock.beta!.toStringAsFixed(2) : '--',
        },
        changeColor: changeColor,
        isPositive: isPositive,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: DashboardTextStyles.columnHeader.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Table
          DynamicTable(
            tableId: 'sector_details_${title.toLowerCase().replaceAll(' ', '_')}_table',
            enableColumnCustomization: true,
            columns: const [
              SimpleColumn(label: 'PRICE', fieldName: 'price', isNumeric: true),
              SimpleColumn(label: 'CHANGE %', fieldName: 'change', isNumeric: true),
              SimpleColumn(label: 'CHANGE \$', fieldName: 'changeAmount', isNumeric: true),
              SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
              SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
              SimpleColumn(label: '10D AVG', fieldName: 'avgVol10d', isNumeric: true),
              SimpleColumn(label: 'BETA', fieldName: 'beta', isNumeric: true),
            ],
            rows: rows,
            showFixedColumn: true,
            considerPadding: false,
            columnSpacing: 20,
            fixedColumnWidth: 300,
            enableDragging: false,
            enableLivePrices: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: GestureDetector(
        onTap: () {
          if (_watchlistService.isWatchlistOpen.value) {
            _watchlistService.closeWatchlist();
          }
        },
        child: Stack(
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Sector Header - Following app design pattern
                      Text(
                        widget.sectorName,
                        style: DashboardTextStyles.titleSmall.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stocks Table
                      Obx(() {
                        if (sectorStocksController.isLoading.value) {
                          return _buildLoadingShimmer(isDarkMode);
                        }
                        
                        if (sectorStocksController.errorMessage.value.isNotEmpty) {
                          return Center(
                            child: Text(
                              sectorStocksController.errorMessage.value,
                              style: DashboardTextStyles.errorMessage.copyWith(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                              ),
                            ),
                          );
                        }
                        
                        if (sectorStocksController.sectorStocks.isEmpty) {
                          return Center(
                            child: Text(
                              'No stocks found for this sector',
                              style: DashboardTextStyles.noData.copyWith(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                              ),
                            ),
                          );
                        }
                        
                              return Column(
                                children: [
                                  // Main content row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Dynamic table with pagination - takes remaining space
                                      Expanded(
                                        child: _buildStocksTable(),
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
                                  ),
                                  const SizedBox(height: 24),
                                  // Top 5 Gainers and Losers - full width
                                  _buildTopGainersLosersTables(),
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
            Obx(() {
              if (!_watchlistService.isWatchlistOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping on sidebar itself
                  child: WatchlistSidebar(
                    isDarkMode: isDarkMode,
                    onClose: () => _watchlistService.closeWatchlist(),
                  ),
                ),
              );
            }),
              // Global FAB Overlay
              const GlobalFABOverlay(),
          ],
        ),
      ),
    );
  }
}
