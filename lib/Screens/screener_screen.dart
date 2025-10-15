import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/Controllers/filter_controller.dart';
import 'package:musaffa_terminal/models/filter_config.dart';
import 'package:musaffa_terminal/models/results_tab_config.dart';
import 'package:musaffa_terminal/services/filter_loader.dart';
import 'package:musaffa_terminal/services/results_tabs_loader.dart';
import 'package:musaffa_terminal/widgets/filter_widget_builder.dart';

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({Key? key}) : super(key: key);

  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isWatchlistOpen = false;
  late TabController _tabController;
  String _selectedCategory = "Descriptive";
  late FilterController filterController;
  late ScrollController _scrollController;
  
  // GlobalKey to maintain scroll position
  final GlobalKey _resultsSectionKey = GlobalKey();
  
  // Keep scroll position
  double _scrollOffset = 0.0;
  
  ScreenerFiltersConfig? _filtersConfig;
  bool _isLoadingFilters = true;
  
  // Results tabs
  ResultsTabsConfig? _resultsTabsConfig;
  String _selectedResultsTab = 'overview';
  
  // Store all filter values in a map: filterId -> selectedValue
  final Map<String, String?> _filterValues = {};

  final List<String> _filterCategories = [
    "Descriptive",
    "Fundamental", 
    "Technical",
    "Growth",
    "ETF"
  ];

  @override
  void initState() {
    super.initState();
    print('🚀 [ScreenerScreen] initState called');
    
    // Initialize FilterController
    filterController = Get.put(FilterController());
    
    // Initialize ScrollController with listener to track position
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      _scrollOffset = _scrollController.offset;
    });
    
    _tabController = TabController(length: _filterCategories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _filterCategories[_tabController.index];
        });
      }
    });
    _loadFilters();
    _loadResultsTabs();
    
    // Load default stocks on screen load
    _loadDefaultStocks();
  }
  
  Future<void> _loadDefaultStocks() async {
    print('🔄 [ScreenerScreen] Loading default stocks...');
    await filterController.fetchStocks();
  }

  Future<void> _loadFilters() async {
    try {
      final config = await FilterLoader.loadFilters();
      setState(() {
        _filtersConfig = config;
        _isLoadingFilters = false;
      });
    } catch (e) {
      print('Error loading filters: $e');
      setState(() {
        _isLoadingFilters = false;
      });
    }
  }

  Future<void> _loadResultsTabs() async {
    try {
      final config = await ResultsTabsLoader.loadTabs();
      setState(() {
        _resultsTabsConfig = config;
        _selectedResultsTab = config.getDefaultTab().id;
      });
    } catch (e) {
      print('Error loading results tabs: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true;

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
      
      if (_isWatchlistOpen) {
        final watchlistController = Get.find<WatchlistController>();
        watchlistController.resetToDefaultWatchlist();
      }
    });
  }

  void _applyFilters() {
    // Convert _filterValues to the format expected by FilterController
    Map<String, dynamic> filters = {};
    
    _filterValues.forEach((key, value) {
      if (value != null && value != "any") {
        filters[key] = value;
      }
    });
    
    // Fetch stocks with filters
    filterController.fetchStocks(filters: filters);
    
    setState(() {
      // This will trigger a rebuild and show updated results
    });
  }

  int _getAppliedFiltersCount() {
    return _filterValues.values.where((v) => v != null && v != "any").length;
  }

  int _getResultsCount() {
    // Return actual results count from controller
    return filterController.totalFound;
  }

  bool _isFilterApplied(String filterId) {
    final value = _filterValues[filterId];
    return value != null && value != "any";
  }

  void _resetFilter(String filterId) {
    setState(() {
      _filterValues[filterId] = "any";
    });
    _applyFilters();
  }

  void _resetAllFilters() {
    setState(() {
      _filterValues.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Column(
                children: [
                  HomeTabBar(
                    showBackButton: true,
                    onWatchlistToggle: _toggleWatchlist,
                    isWatchlistOpen: _isWatchlistOpen,
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(12), // Reduced padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(isDarkMode),
                            const SizedBox(height: 16), // Reduced spacing
                            
                            _isLoadingFilters
                                ? const SizedBox(
                                    height: 300, // Reduced height
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : _buildFilterContent(isDarkMode),
                            
                            const SizedBox(height: 16), // Reduced spacing
                            _buildResultsSection(isDarkMode, key: _resultsSectionKey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_isWatchlistOpen)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: WatchlistSidebar(
                    isDarkMode: isDarkMode,
                    onClose: () => setState(() => _isWatchlistOpen = false),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Text(
          'STOCK SCREENER',
          style: DashboardTextStyles.headerTitle,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            '${_getResultsCount()} Results',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 12,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(bool isDarkMode) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _filterCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final isSelected = _tabController.index == index;
            
            return GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151))
                        : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterContent(bool isDarkMode) {
    if (_filtersConfig == null) {
      return const SizedBox();
    }

    // Get filter count for current category
    final filters = _filtersConfig!.getFiltersForCategory(_selectedCategory);
    final filterCount = filters.length;
    final crossAxisCount = 4;
    final rows = (filterCount / crossAxisCount).ceil();
    
    
    final contentHeight = (rows * 80.0) + 80;
    
    return Container(
      height: contentHeight.clamp(180, 500), // Reduced min/max height
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterTabs(isDarkMode)),
              if (_getAppliedFiltersCount() > 0) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _resetAllFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFD0D0D0),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reset All',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          
          Text(
            '$_selectedCategory Filters',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 14, // Reduced font size
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12), // Reduced spacing
          
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: _buildFilterGrid(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGrid(bool isDarkMode) {
    if (_filtersConfig == null) {
      return const SizedBox();
    }

    // Get filters for current category from JSON
    final filters = _filtersConfig!.getFiltersForCategory(_selectedCategory);
    
    if (filters.isEmpty) {
      return Center(
        child: Text(
          'No filters available',
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 14,
            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    final crossAxisCount = 4;
    final rows = (filters.length / crossAxisCount).ceil();
    
    return Column(
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * crossAxisCount;
        final endIndex = (startIndex + crossAxisCount).clamp(0, filters.length);
        final rowFilters = filters.sublist(startIndex, endIndex);
        
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 8 : 0), // Reduced spacing
          child: Row(
            children: List.generate(crossAxisCount, (colIndex) {
              if (colIndex < rowFilters.length) {
                final filterConfig = rowFilters[colIndex];
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: colIndex < crossAxisCount - 1 ? 12 : 0), // Reduced spacing
                    child: FilterWidgetBuilder.buildFilter(
                      config: filterConfig,
                      selectedValue: _filterValues[filterConfig.id],
                      onChanged: (value) {
                        setState(() {
                          _filterValues[filterConfig.id] = value;
                        });
                        _applyFilters();
                      },
                      isDarkMode: isDarkMode,
                      isApplied: _isFilterApplied(filterConfig.id),
                      onReset: () => _resetFilter(filterConfig.id),
                    ),
                  ),
                );
              } else {
                return const Expanded(child: SizedBox());
              }
            }),
          ),
        );
      }),
    );
  }

  Widget _buildResultsTabs(bool isDarkMode) {
    if (_resultsTabsConfig == null) {
      return const SizedBox();
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _resultsTabsConfig!.tabs.map((tab) {
            final isSelected = _selectedResultsTab == tab.id;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedResultsTab = tab.id;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tab.label,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151))
                        : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultsSection(bool isDarkMode, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Row(
                children: [
                  Text(
                    'Results',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                    ),
                  ),
                  if (_getAppliedFiltersCount() > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFD0D0D0),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '${_getAppliedFiltersCount()} filters',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              _buildResultsTabs(isDarkMode),
            ],
          ),
          const SizedBox(height: 12),
          _buildResultsTable(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildResultsTable(bool isDarkMode) {
    return Obx(() {
      // Show loading indicator
      if (filterController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      // Show error message
      if (filterController.errorMessage.value.isNotEmpty) {
        return Center(
          child: Text(
            filterController.errorMessage.value,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 14,
              color: Colors.red.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
      
      // Show empty state
      if (filterController.stocks.isEmpty) {
        return Center(
          child: Text(
            'No stocks found. Try adjusting your filters.',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 14,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
      
      // Convert StocksData to SimpleRowModel for DynamicTable
      List<SimpleRowModel> rows = filterController.stocks.map((stock) {
        final isPositive = (stock.priceChange1DPercent ?? 0) >= 0;
        final changeColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
        
        return SimpleRowModel(
          symbol: stock.ticker ?? '',
          name: filterController.companyNamesMap[stock.ticker] ?? stock.companySymbol ?? stock.ticker ?? '',
          logo: filterController.logoMap[stock.ticker],
          price: stock.currentPrice,
          changePercent: stock.priceChange1DPercent,
          currency: stock.currency ?? 'USD',
          fields: {
            'price': stock.currentPrice != null ? '\$${stock.currentPrice!.toStringAsFixed(2)}' : '--',
            'change': stock.priceChange1DPercent != null ? '${stock.priceChange1DPercent! >= 0 ? '+' : ''}${stock.priceChange1DPercent!.toStringAsFixed(2)}%' : '--',
            'changeAmount': stock.change1D != null ? '\$${stock.change1D!.toStringAsFixed(2)}' : '--',
            'marketCap': stock.usdMarketCap != null ? getShortenedT(stock.usdMarketCap! * 1000000) : '--',
            'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
            'sector': stock.sector ?? '--',
            'beta': stock.beta != null ? stock.beta!.toStringAsFixed(2) : '--',
            'peRatio': stock.peTTM != null ? stock.peTTM!.toStringAsFixed(2) : '--',
          },
          changeColor: changeColor,
          isPositive: isPositive,
        );
      }).toList();
      
      // Build table with pagination
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DynamicTable - no fixed height, takes natural height
          DynamicTable(
            columns: const [
              SimpleColumn(label: 'PRICE', fieldName: 'price', isNumeric: true),
              SimpleColumn(label: 'CHANGE %', fieldName: 'change', isNumeric: true),
              SimpleColumn(label: 'CHANGE \$', fieldName: 'changeAmount', isNumeric: true),
              SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
              SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
              SimpleColumn(label: 'SECTOR', fieldName: 'sector', isNumeric: false),
              SimpleColumn(label: 'BETA', fieldName: 'beta', isNumeric: true),
              SimpleColumn(label: 'P/E', fieldName: 'peRatio', isNumeric: true),
            ],
            rows: rows,
            showFixedColumn: true,
            considerPadding: false,
            columnSpacing: 16,
            fixedColumnWidth: 0,
            enableDragging: false,
            enableLivePrices: true,
          ),
          
          const SizedBox(height: 12),
          
          // Pagination controls
          _buildPaginationControls(isDarkMode),
        ],
      );
    });
  }
  
  Widget _buildPaginationControls(bool isDarkMode) {
    return Obx(() {
      if (filterController.totalPages <= 1) return const SizedBox.shrink();
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            'Page ${filterController.currentPage + 1} of ${filterController.totalPages} (${filterController.totalFound} stocks)',
            style: DashboardTextStyles.dataCell.copyWith(
              fontSize: 12,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          
          // Navigation buttons
          Row(
            children: [
              // Previous button
              if (filterController.hasPreviousPage) ...[
                GestureDetector(
                  onTap: () async {
                    // Save current scroll position
                    _scrollOffset = _scrollController.offset;
                    
                    await filterController.previousPage(
                      filters: _convertFiltersForController(),
                    );
                    
                    // Restore scroll position after rebuild
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollOffset);
                      }
                    });
                  },
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
                        fontSize: 12,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Next button
              if (filterController.hasNextPage)
                GestureDetector(
                  onTap: () async {
                    // Save current scroll position
                    _scrollOffset = _scrollController.offset;
                    
                    await filterController.nextPage(
                      filters: _convertFiltersForController(),
                    );
                    
                    // Restore scroll position after rebuild
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollOffset);
                      }
                    });
                  },
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
                        fontSize: 12,
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
  
  Map<String, dynamic> _convertFiltersForController() {
    Map<String, dynamic> filters = {};
    
    _filterValues.forEach((key, value) {
      if (value != null && value != "any") {
        filters[key] = value;
      }
    });
    
    return filters;
  }
  
  // Removed _scrollToResults() - no longer needed
}

