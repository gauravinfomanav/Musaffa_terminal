import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';
import 'package:musaffa_terminal/services/sector_mapping_service.dart';
import 'package:musaffa_terminal/Controllers/sector_stocks_controller.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/utils.dart';

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
          Row(
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
                        
                        return Column(
                          children: [
                            _buildStocksTable(),
                            const SizedBox(height: 16),
                            _buildPaginationControls(),
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
