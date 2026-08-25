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
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class SectorDetailsScreen extends StatefulWidget {
  final String sectorName;

  const SectorDetailsScreen({Key? key, required this.sectorName})
      : super(key: key);

  @override
  State<SectorDetailsScreen> createState() => _SectorDetailsScreenState();
}

class _SectorDetailsScreenState extends State<SectorDetailsScreen> {
  late WatchlistController watchlistController;
  late SectorStocksController sectorStocksController;
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();
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

    return _buildSectionCard(
      title: 'Sector Overview',
      subtitle: 'Live leaders and breadth snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopPerformer(isDarkMode),
          _buildWorstPerformer(isDarkMode),
          _buildLargestMarketCapStock(isDarkMode),
          _buildMostActiveStock(isDarkMode),
          _buildSectorMetric(
              'Total Stocks', '${sectorStocksController.totalStocks}'),
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
      return (current.priceChange1DPercent ?? 0) >
              (best.priceChange1DPercent ?? 0)
          ? current
          : best;
    });

    if (topPerformer == null) {
      return _buildPerformanceRow(
          'Top Gainer', 'No positive performers', '--', isDarkMode);
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
      return (current.priceChange1DPercent ?? 0) <
              (worst.priceChange1DPercent ?? 0)
          ? current
          : worst;
    });

    if (worstPerformer == null) {
      return _buildPerformanceRow(
          'Top Loser', 'No negative performers', '--', isDarkMode);
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
      return _buildPerformanceRow(
          'Largest Market Cap', 'No data available', '--', isDarkMode);
    }

    final marketCapStr = Constants.formatMarketCapFromMillions(
      largestMarketCap.usdMarketCap,
    );

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
      final currentActivity =
          averageVolume > 0 ? currentVolume / averageVolume : 0;
      final mostActivity = averageVolume > 0 ? mostVolume / averageVolume : 0;

      return currentActivity > mostActivity ? current : most;
    });

    if (mostActive == null || (mostActive.volume ?? 0) == 0) {
      return _buildPerformanceRow(
          'Most Active', 'No data available', '--', isDarkMode);
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

  Widget _buildPerformanceRow(
      String label, String ticker, String change, bool isDarkMode) {
    // Determine color based on positive/negative change
    Color changeColor;
    if (change == '--' || change == '-') {
      changeColor =
          isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    } else if (change.startsWith('+') ||
        (double.tryParse(change.replaceAll('%', '')) ?? 0) > 0) {
      changeColor = const Color(0xFF10B981); // Green for positive
    } else {
      changeColor = const Color(0xFFEF4444); // Red for negative
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HomeUi.borderLight(isDarkMode).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
          ),
          Row(
            children: [
              Text(
                ticker,
                style: HomeUi.sectionTitle(isDarkMode).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                change,
                style: HomeUi.control(isDarkMode, active: true).copyWith(
                  fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HomeUi.borderLight(isDarkMode).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
          ),
          Text(
            value,
            style: HomeUi.sectionTitle(isDarkMode).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDarkMode) {
    final baseColor =
        isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final highlightColor =
        isDarkMode ? const Color(0xFF373E45) : const Color(0xFFF3F4F6);

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
            color:
                isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerBox(width: 220, height: 22),
            const SizedBox(height: 20),
            ...List.generate(
                rows,
                (_) => Padding(
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
            color:
                isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerBox(width: 200, height: 22),
            const SizedBox(height: 20),
            ...List.generate(
                7,
                (_) => Padding(
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
                      color:
                          isDarkMode ? const Color(0xFF151718) : Colors.white,
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

    return _buildSectionCard(
      title: 'Sector Performance',
      subtitle: 'Relative returns across common periods',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      changeColor =
          isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    } else if (change > 0) {
      changeColor = const Color(0xFF10B981); // Green for positive
    } else {
      changeColor = const Color(0xFFEF4444); // Red for negative
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HomeUi.borderLight(isDarkMode).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period,
            style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
          ),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: HomeUi.control(isDarkMode, active: true).copyWith(
              fontSize: 12,
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
      final mappedSectors =
          SectorMappingService.getMappedSectors(widget.sectorName);
      return mappedSectors?.contains(sector) ?? false;
    }
    return false;
  }

  String _getAverageMarketCap() {
    final stocks = sectorStocksController.allSectorStocks;
    if (stocks.isEmpty) return '--';

    final withCap = stocks.where((stock) => stock.usdMarketCap != null).toList();
    if (withCap.isEmpty) return '--';

    final averageMillions = withCap.fold<double>(
          0,
          (sum, stock) => sum + stock.usdMarketCap!.toDouble(),
        ) /
        withCap.length;
    return Constants.formatMarketCapFromMillions(averageMillions);
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
      final total = sectorStocksController.totalStocks;
      final pages = sectorStocksController.totalPages;
      if (total <= 0 || pages <= 1) return const SizedBox.shrink();

      final current = sectorStocksController.currentPage + 1;
      final items = _sectorPageItems(current, pages);

      return Column(
        children: [
          Divider(
            height: 1,
            thickness: 0.5,
            color: HomeUi.borderLight(isDarkMode),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style:
                          HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12.5),
                      children: [
                        const TextSpan(text: 'Page '),
                        TextSpan(
                          text: '$current',
                          style:
                              HomeUi.control(isDarkMode, active: true).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        const TextSpan(text: ' of '),
                        TextSpan(
                          text: _commaNumber(pages),
                          style:
                              HomeUi.control(isDarkMode, active: true).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ${_commaNumber(total)} stocks',
                        ),
                      ],
                    ),
                  ),
                ),
                if (pages > 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SectorPaginationIconButton(
                        icon: Icons.chevron_left_rounded,
                        enabled: sectorStocksController.hasPreviousPage,
                        isDarkMode: isDarkMode,
                        onTap: () => sectorStocksController.goToPage(
                          sectorStocksController.currentPage - 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...items.map((item) {
                        if (item == null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '…',
                              style: HomeUi.subtitle(isDarkMode).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _SectorPaginationPageButton(
                            page: item,
                            selected: item == current,
                            isDarkMode: isDarkMode,
                            onTap: () =>
                                sectorStocksController.goToPage(item - 1),
                          ),
                        );
                      }),
                      const SizedBox(width: 6),
                      _SectorPaginationIconButton(
                        icon: Icons.chevron_right_rounded,
                        enabled: sectorStocksController.hasNextPage,
                        isDarkMode: isDarkMode,
                        onTap: () => sectorStocksController.goToPage(
                          sectorStocksController.currentPage + 1,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  List<int?> _sectorPageItems(int current, int total) {
    if (total <= 7) {
      return [for (var i = 1; i <= total; i++) i];
    }
    final set = <int>{1, total, current};
    if (current - 1 > 1) set.add(current - 1);
    if (current + 1 < total) set.add(current + 1);
    if (current <= 3) set.addAll({2, 3, 4});
    if (current >= total - 2) {
      set.addAll({total - 3, total - 2, total - 1});
    }
    final sorted = set.toList()..sort();
    final out = <int?>[];
    int? prev;
    for (final page in sorted) {
      if (page < 1 || page > total) continue;
      if (prev != null && page - prev > 1) out.add(null);
      out.add(page);
      prev = page;
    }
    return out;
  }

  String _commaNumber(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _buildStocksTable() {
    final rows = sectorStocksController.sectorStocks.map((stock) {
      final symbol = stock.ticker ?? '--';
      final companyName =
          sectorStocksController.companyNamesMap[stock.ticker] ??
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
              ? Constants.formatMarketCapFromMillions(stock.usdMarketCap)
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
      decoration: HomeUi.cardDecoration(isDarkMode),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          DynamicTableFromWeb(
            title: 'Sector Stocks',
            subtitle: 'Sortable and searchable sector stock list',
            showTickerCell: true,
            tickerKey: 'ticker',
            companyKey: 'company',
            logoKey: 'logo',
            tickerHeaderLabel: 'Ticker',
            columns: const [
              DynamicTableColumn(
                  key: 'price',
                  label: 'Price',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'change',
                  label: 'Change %',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'changeAmount',
                  label: 'Change \$',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'marketCap',
                  label: 'MKT CAP',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'volume',
                  label: 'Volume',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'sector', label: 'Sector', sortable: true),
              DynamicTableColumn(
                  key: 'beta',
                  label: 'Beta',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'week52High',
                  label: '52W High',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'week52Low',
                  label: '52W Low',
                  sortable: true,
                  align: TextAlign.right),
              DynamicTableColumn(
                  key: 'avgVol10d',
                  label: 'Avg Vol 10D',
                  sortable: true,
                  align: TextAlign.right),
            ],
            rows: rows,
            searchable: true,
            paginated: false,
            enableColumnVisibilityToggle: true,
            enableColumnFilters: false,
            stickyHeader: true,
            maxHeight: 560,
            useOuterContainer: false,
            onTickerTap: (row) {
              final ticker = row.data['ticker']?.toString() ?? '';
              if (ticker.isEmpty || ticker == '--') return;

              final companyName = row.data['company']?.toString() ?? ticker;
              final logo = row.data['logo']?.toString();
              final stock =
                  sectorStocksController.allSectorStocks.firstWhereOrNull(
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

              FeatureNavigation.pushIfAllowed(
                context,
                FeatureKeys.tickerDetails,
                TickerDetailScreen(ticker: tickerModel),
              );
            },
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildTopGainersLosersTables(bool compact) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get top 5 gainers and losers from all sector stocks
    final allStocks = sectorStocksController.allSectorStocks;
    final topGainers = allStocks
        .where((stock) => stock.priceChange1DPercent != null)
        .toList()
      ..sort((a, b) =>
          (b.priceChange1DPercent ?? 0).compareTo(a.priceChange1DPercent ?? 0));

    final topLosers = allStocks
        .where((stock) => stock.priceChange1DPercent != null)
        .toList()
      ..sort((a, b) =>
          (a.priceChange1DPercent ?? 0).compareTo(b.priceChange1DPercent ?? 0));

    final children = <Widget>[
      Expanded(
        child: _buildGainersLosersTable(
          title: 'Top 5 Gainers',
          stocks: topGainers.take(5).toList(),
          isDarkMode: isDarkMode,
        ),
      ),
      SizedBox(width: compact ? 0 : 16, height: compact ? 16 : 0),
      Expanded(
        child: _buildGainersLosersTable(
          title: 'Top 5 Losers',
          stocks: topLosers.take(5).toList(),
          isDarkMode: isDarkMode,
        ),
      ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildGainersLosersTable({
    required String title,
    required List<StocksData> stocks,
    required bool isDarkMode,
  }) {
    final subtitle = title.contains('Gainers')
        ? 'Best daily performers in this sector'
        : 'Weakest daily performers in this sector';

    // Convert to SimpleRowModel
    List<SimpleRowModel> rows = stocks.map((stock) {
      final isPositive = (stock.priceChange1DPercent ?? 0) >= 0;
      final changeColor =
          isPositive ? Colors.green.shade600 : Colors.red.shade600;

      return SimpleRowModel(
        symbol: stock.ticker ?? '',
        name: sectorStocksController.companyNamesMap[stock.ticker] ??
            stock.companySymbol ??
            stock.ticker ??
            '',
        logo: sectorStocksController.logoMap[stock.ticker],
        price: stock.currentPrice,
        changePercent: stock.priceChange1DPercent,
        currency: stock.currency ?? 'USD',
        fields: {
          'price': stock.currentPrice != null
              ? '\$${stock.currentPrice!.toStringAsFixed(2)}'
              : '--',
          'change': stock.priceChange1DPercent != null
              ? '${stock.priceChange1DPercent! >= 0 ? '+' : ''}${stock.priceChange1DPercent!.toStringAsFixed(2)}%'
              : '--',
          'changeAmount': stock.change1D != null
              ? '\$${stock.change1D!.toStringAsFixed(2)}'
              : '--',
          'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
          'marketCap': stock.usdMarketCap != null
              ? Constants.formatMarketCapFromMillions(stock.usdMarketCap)
              : '--',
          'avgVol10d': stock.avgVolume10days != null
              ? getShortenedT(stock.avgVolume10days!)
              : '--',
          'beta': stock.beta != null ? stock.beta!.toStringAsFixed(2) : '--',
        },
        changeColor: changeColor,
        isPositive: isPositive,
      );
    }).toList();

    return DynamicTable(
      title: title,
      subtitle: subtitle,
      tableId:
          'sector_details_${title.toLowerCase().replaceAll(' ', '_')}_table',
      enableColumnCustomization: true,
      showOuterShadow: false,
      columns: const [
        SimpleColumn(label: 'PRICE', fieldName: 'price', isNumeric: true),
        SimpleColumn(label: 'CHANGE %', fieldName: 'change', isNumeric: true),
        SimpleColumn(
            label: 'CHANGE \$', fieldName: 'changeAmount', isNumeric: true),
        SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
        SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
      ],
      rows: rows,
      showFixedColumn: true,
      considerPadding: false,
      columnSpacing: 40,
      horizontalMargin: 12,
      fixedColumnWidth: 220,
      enableDragging: false,
      enableLivePrices: true,
      headerHeight: 44,
      rowHeight: 50,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: HomeUi.cardPadding,
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDarkMode,
            title: title,
            subtitleText: subtitle,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPageHeader(bool isDarkMode) {
    final mappedSectorsText =
        (_mappedSectors != null && _mappedSectors!.isNotEmpty)
            ? _mappedSectors!.join(', ')
            : widget.sectorName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sector Details',
            style: HomeUi.overline(isDarkMode).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            widget.sectorName,
            style: HomeUi.heading(isDarkMode).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? HomeUi.cardBg(true) : Colors.white,
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              border: Border.all(color: HomeUi.borderLight(isDarkMode)),
            ),
            child: Text(
              'Coverage: $mappedSectorsText',
              style: HomeUi.subtitle(isDarkMode).copyWith(
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarColumn() {
    return Column(
      children: [
        _buildCombinedMetricsContainer(),
        const SizedBox(height: 16),
        _buildPerformanceChangesContainer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FeatureGuard(
      featureKey: FeatureKeys.sectorDetails,
      child: Scaffold(
        backgroundColor: HomeUi.pageBg(isDarkMode),
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
                        isWatchlistOpen:
                            _watchlistService.isWatchlistOpen.value,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 1180;
                        final pagePadding =
                            HomeUi.pagePadding(constraints.maxWidth);
                        const sectionGap = 16.0;

                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: pagePadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPageHeader(isDarkMode),
                              SizedBox(height: sectionGap),
                              Obx(() {
                                if (sectorStocksController.isLoading.value) {
                                  return _buildLoadingShimmer(isDarkMode);
                                }

                                if (sectorStocksController
                                    .errorMessage.value.isNotEmpty) {
                                  return Center(
                                    child: Text(
                                      sectorStocksController.errorMessage.value,
                                      style: DashboardTextStyles.errorMessage
                                          .copyWith(
                                        fontFamily: Constants.FONT_DEFAULT_NEW,
                                      ),
                                    ),
                                  );
                                }

                                if (sectorStocksController
                                    .sectorStocks.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No stocks found for this sector',
                                      style:
                                          DashboardTextStyles.noData.copyWith(
                                        fontFamily: Constants.FONT_DEFAULT_NEW,
                                      ),
                                    ),
                                  );
                                }

                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildStocksTable(),
                                      const SizedBox(height: 16),
                                      _buildSidebarColumn(),
                                      SizedBox(height: sectionGap),
                                      _buildTopGainersLosersTables(true),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildStocksTable()),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 320,
                                          child: _buildSidebarColumn(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: sectionGap),
                                    _buildTopGainersLosersTables(false),
                                  ],
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Obx(() {
                if (!_watchlistService.isWatchlistOpen.value) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleWatchlist,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.24),
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
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
                );
              }),
              const GlobalFABOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectorPaginationIconButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _SectorPaginationIconButton({
    required this.icon,
    required this.enabled,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_SectorPaginationIconButton> createState() =>
      _SectorPaginationIconButtonState();
}

class _SectorPaginationIconButtonState
    extends State<_SectorPaginationIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final enabled = widget.enabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: enabled ? 1 : 0.38,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: HomeUi.controlHeight,
            height: HomeUi.controlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled && _hover
                  ? HomeUi.iconFillGradient
                  : HomeUi.iconWellGradient,
              border: Border.all(
                color: enabled && _hover
                    ? HomeUi.buttonBorder
                    : HomeUi.iconWellBorder,
                width: 0.856,
              ),
            ),
            child: enabled && _hover
                ? Icon(widget.icon, size: 18, color: Colors.white)
                : HomeUi.brandIcon(icon: widget.icon, size: 18),
          ),
        ),
      ),
    );
  }
}

class _SectorPaginationPageButton extends StatefulWidget {
  final int page;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _SectorPaginationPageButton({
    required this.page,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_SectorPaginationPageButton> createState() =>
      _SectorPaginationPageButtonState();
}

class _SectorPaginationPageButtonState
    extends State<_SectorPaginationPageButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: selected ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: selected ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            minWidth: HomeUi.controlHeight,
            minHeight: HomeUi.controlHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? HomeUi.iconFillGradient : null,
            color: selected
                ? null
                : (_hover ? HomeUi.elevatedBg(dark) : Colors.transparent),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: selected
                  ? HomeUi.buttonBorder
                  : (_hover ? HomeUi.borderStrong(dark) : Colors.transparent),
              width: 0.856,
            ),
          ),
          child: Text(
            '${widget.page}',
            style: HomeUi.control(dark, active: true).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : HomeUi.title(dark),
            ),
          ),
        ),
      ),
    );
  }
}
