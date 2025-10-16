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
  
  // Method to count applied filters for a specific category
  int _getAppliedFiltersCount(String category) {
    if (_filtersConfig == null) return 0;
    
    final filters = _filtersConfig!.getFiltersForCategory(category);
    int count = 0;
    
    for (final filter in filters) {
      final value = _filterValues[filter.id];
      if (value != null && value != "any" && value.isNotEmpty) {
        count++;
      }
    }
    
    return count;
  }

  final List<String> _filterCategories = [
    "Descriptive",
    "Fundamental", 
    "Technical",
    "Growth"
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

  int _getTotalAppliedFiltersCount() {
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
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                  category,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151))
                        : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                     ),
                     if (_getAppliedFiltersCount(category) > 0) ...[
                       const SizedBox(width: 4),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                         decoration: BoxDecoration(
                           color: const Color(0xFF81AACE),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                         child: Text(
                           '${_getAppliedFiltersCount(category)}',
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 9,
                             fontWeight: FontWeight.w600,
                           ),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     ],
                   ],
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
              if (_getTotalAppliedFiltersCount() > 0) ...[
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
                  if (_getTotalAppliedFiltersCount() > 0) ...[
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
                        '${_getTotalAppliedFiltersCount()} filters',
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
          fields: _getFieldsForStock(stock),
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
            columns: _getColumnsForSelectedTab(),
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
  
  List<SimpleColumn> _getColumnsForSelectedTab() {
    if (_resultsTabsConfig == null) {
      return _getDefaultColumns();
    }
    
    final selectedTab = _resultsTabsConfig!.tabs.firstWhere(
      (tab) => tab.id == _selectedResultsTab,
      orElse: () => _resultsTabsConfig!.tabs.first,
    );
    
    return selectedTab.columns.map((column) {
      return SimpleColumn(
        label: column.label.toUpperCase(),
        fieldName: column.id,
        isNumeric: column.type == 'number' || column.type == 'currency' || column.type == 'percentage',
      );
    }).toList();
  }
  
  List<SimpleColumn> _getDefaultColumns() {
    return const [
      SimpleColumn(label: 'TICKER', fieldName: 'ticker', isNumeric: false),
      SimpleColumn(label: 'PRICE', fieldName: 'price', isNumeric: true),
      SimpleColumn(label: 'CHANGE %', fieldName: 'change', isNumeric: true),
      SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
      SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
      SimpleColumn(label: 'SECTOR', fieldName: 'sector', isNumeric: false),
    ];
  }
  
  Map<String, String> _getFieldsForStock(dynamic stock) {
    return {
      // Basic fields (removed ticker as requested)
      'price': stock.currentPrice != null ? '\$${stock.currentPrice!.toStringAsFixed(2)}' : '--',
      'marketCap': stock.usdMarketCap != null ? getShortenedT(stock.usdMarketCap! * 1000000) : '--',
      'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
      'sector': stock.sector ?? '--',
      
      // Overview fields
      'change1D': stock.priceChange1DPercent != null ? '${stock.priceChange1DPercent! >= 0 ? '+' : ''}${stock.priceChange1DPercent!.toStringAsFixed(2)}%' : '--',
      'beta': stock.beta != null ? stock.beta!.toStringAsFixed(2) : '--',
      'peTTM': stock.peTTM != null ? stock.peTTM!.toStringAsFixed(2) : '--',
      'dividendYield': stock.currentDividendYieldTTM != null ? '${stock.currentDividendYieldTTM!.toStringAsFixed(2)}%' : '--',
      'sharesOutstanding': stock.sharesOutStanding != null ? getShortenedT(stock.sharesOutStanding!) : '--',
      'enterpriseValue': stock.enterpriseValue != null ? getShortenedT(stock.enterpriseValue!) : '--',
      'recommendation': stock.analystRecommendationWeightedAvg ?? '--',
      'epsTTM': stock.epsTTM != null ? stock.epsTTM!.toStringAsFixed(2) : '--',
      'revenueAnnual': stock.revenueAnnual != null ? getShortenedT(stock.revenueAnnual!) : '--',
      'netIncome': stock.netIncomeAnnual != null ? getShortenedT(stock.netIncomeAnnual!) : '--',
      
      // Valuation fields
      'peAnnual': stock.peAnnual != null ? stock.peAnnual!.toStringAsFixed(2) : '--',
      'pbAnnual': stock.pbAnnual != null ? stock.pbAnnual!.toStringAsFixed(2) : '--',
      'psTTM': stock.psTTM != null ? stock.psTTM!.toStringAsFixed(2) : '--',
      'psAnnual': stock.psAnnual != null ? stock.psAnnual!.toStringAsFixed(2) : '--',
      'evEbit': stock.evEbit != null ? stock.evEbit!.toStringAsFixed(2) : '--',
      'evFcf': stock.evFcf != null ? stock.evFcf!.toStringAsFixed(2) : '--',
      'bookValuePerShare': stock.bookValuePerShareAnnual != null ? '\$${stock.bookValuePerShareAnnual!.toStringAsFixed(2)}' : '--',
      'pfcfShareTTM': stock.pfcfShareTTM != null ? stock.pfcfShareTTM!.toStringAsFixed(2) : '--',
      'pcfShareTTM': stock.pcfShareTTM != null ? stock.pcfShareTTM!.toStringAsFixed(2) : '--',
      'ptbvAnnual': stock.ptbvAnnual != null ? stock.ptbvAnnual!.toStringAsFixed(2) : '--',
      
      // Financial fields
      'grossMargin': stock.grossMarginAnnual != null ? '${stock.grossMarginAnnual!.toStringAsFixed(2)}%' : '--',
      'operatingMargin': stock.operatingMarginAnnual != null ? '${stock.operatingMarginAnnual!.toStringAsFixed(2)}%' : '--',
      'netProfitMargin': stock.netProfitMarginAnnual != null ? '${stock.netProfitMarginAnnual!.toStringAsFixed(2)}%' : '--',
      'roe': stock.rOE != null ? '${stock.rOE!.toStringAsFixed(2)}%' : '--',
      'roa': stock.roaTTM != null ? '${stock.roaTTM!.toStringAsFixed(2)}%' : '--',
      'debtEquity': stock.totalDebtTotalEquityAnnual != null ? stock.totalDebtTotalEquityAnnual!.toStringAsFixed(2) : '--',
      'currentRatio': stock.currentRatioAnnual != null ? stock.currentRatioAnnual!.toStringAsFixed(2) : '--',
      'quickRatio': stock.quickRatioAnnual != null ? stock.quickRatioAnnual!.toStringAsFixed(2) : '--',
      'assetTurnover': stock.assetTurnoverAnnual != null ? stock.assetTurnoverAnnual!.toStringAsFixed(2) : '--',
      'inventoryTurnover': stock.inventoryTurnoverAnnual != null ? stock.inventoryTurnoverAnnual!.toStringAsFixed(2) : '--',
      'receivablesTurnover': stock.receivablesTurnoverTTM != null ? stock.receivablesTurnoverTTM!.toStringAsFixed(2) : '--',
      'payoutRatio': stock.payoutRatioTTM != null ? '${stock.payoutRatioTTM!.toStringAsFixed(2)}%' : '--',
      
      // Performance fields
      'change1W': stock.priceChange1WPercent != null ? '${stock.priceChange1WPercent! >= 0 ? '+' : ''}${stock.priceChange1WPercent!.toStringAsFixed(2)}%' : '--',
      'change1M': stock.priceChange1MPercent != null ? '${stock.priceChange1MPercent! >= 0 ? '+' : ''}${stock.priceChange1MPercent!.toStringAsFixed(2)}%' : '--',
      'change3M': stock.priceChange3MPercent != null ? '${stock.priceChange3MPercent! >= 0 ? '+' : ''}${stock.priceChange3MPercent!.toStringAsFixed(2)}%' : '--',
      'change6M': stock.priceChange6MPercent != null ? '${stock.priceChange6MPercent! >= 0 ? '+' : ''}${stock.priceChange6MPercent!.toStringAsFixed(2)}%' : '--',
      'change1Y': stock.priceChange1YPercent != null ? '${stock.priceChange1YPercent! >= 0 ? '+' : ''}${stock.priceChange1YPercent!.toStringAsFixed(2)}%' : '--',
      'change3Y': stock.priceChange3YPercent != null ? '${stock.priceChange3YPercent! >= 0 ? '+' : ''}${stock.priceChange3YPercent!.toStringAsFixed(2)}%' : '--',
      'change5Y': stock.priceChange5YPercent != null ? '${stock.priceChange5YPercent! >= 0 ? '+' : ''}${stock.priceChange5YPercent!.toStringAsFixed(2)}%' : '--',
      'priceChangeYTD': stock.priceChangeYTDPercent != null ? '${stock.priceChangeYTDPercent! >= 0 ? '+' : ''}${stock.priceChangeYTDPercent!.toStringAsFixed(2)}%' : '--',
      'totalReturn1Y': stock.totalReturn1Y != null ? '${stock.totalReturn1Y! >= 0 ? '+' : ''}${stock.totalReturn1Y!.toStringAsFixed(2)}%' : '--',
      'totalReturn3Y': stock.totalReturn3Y != null ? '${stock.totalReturn3Y! >= 0 ? '+' : ''}${stock.totalReturn3Y!.toStringAsFixed(2)}%' : '--',
      'totalReturn5Y': stock.totalReturn5Y != null ? '${stock.totalReturn5Y! >= 0 ? '+' : ''}${stock.totalReturn5Y!.toStringAsFixed(2)}%' : '--',
      
      // Technical fields
      'high52W': stock.d52WeekHigh != null ? '\$${stock.d52WeekHigh!.toStringAsFixed(2)}' : '--',
      'low52W': stock.d52WeekLow != null ? '\$${stock.d52WeekLow!.toStringAsFixed(2)}' : '--',
      'avgVolume10D': stock.avgVolume10days != null ? getShortenedT(stock.avgVolume10days!) : '--',
      'avgVolume30D': stock.avgVolume30days != null ? getShortenedT(stock.avgVolume30days!) : '--',
      'priceProximityToHigh': stock.priceProximityToHigh != null ? '${stock.priceProximityToHigh!.toStringAsFixed(2)}%' : '--',
      'marketCapChange3Y': stock.marketCapChange3y != null ? '${stock.marketCapChange3y! >= 0 ? '+' : ''}${stock.marketCapChange3y!.toStringAsFixed(2)}%' : '--',
      'previousClose': stock.previousClose != null ? '\$${stock.previousClose!.toStringAsFixed(2)}' : '--',
      'open': stock.open != null ? '\$${stock.open!.toStringAsFixed(2)}' : '--',
      'high': stock.high != null ? '\$${stock.high!.toStringAsFixed(2)}' : '--',
      'low': stock.low != null ? '\$${stock.low!.toStringAsFixed(2)}' : '--',
      'close': stock.close != null ? '\$${stock.close!.toStringAsFixed(2)}' : '--',
      'priceTangibleBookValue': stock.priceTangiblebookValueAnnual != null ? stock.priceTangiblebookValueAnnual!.toStringAsFixed(2) : '--',
      
      // Growth fields
      'revenueGrowth3Y': stock.revenueGrowth3Y != null ? '${stock.revenueGrowth3Y! >= 0 ? '+' : ''}${stock.revenueGrowth3Y!.toStringAsFixed(2)}%' : '--',
      'revenueGrowth5Y': stock.revenueGrowth5Y != null ? '${stock.revenueGrowth5Y! >= 0 ? '+' : ''}${stock.revenueGrowth5Y!.toStringAsFixed(2)}%' : '--',
      'epsGrowth3Y': stock.epsGrowth3Y != null ? '${stock.epsGrowth3Y! >= 0 ? '+' : ''}${stock.epsGrowth3Y!.toStringAsFixed(2)}%' : '--',
      'epsGrowth5Y': stock.epsGrowth5Y != null ? '${stock.epsGrowth5Y! >= 0 ? '+' : ''}${stock.epsGrowth5Y!.toStringAsFixed(2)}%' : '--',
      'revenueGrowthQuarterlyYoY': stock.revenueGrowthQuarterlyYoy != null ? '${stock.revenueGrowthQuarterlyYoy! >= 0 ? '+' : ''}${stock.revenueGrowthQuarterlyYoy!.toStringAsFixed(2)}%' : '--',
      'revenueGrowthTTMYoY': stock.revenueGrowthTTMYoy != null ? '${stock.revenueGrowthTTMYoy! >= 0 ? '+' : ''}${stock.revenueGrowthTTMYoy!.toStringAsFixed(2)}%' : '--',
      'epsGrowthQuarterlyYoY': stock.epsGrowthQuarterlyYoy != null ? '${stock.epsGrowthQuarterlyYoy! >= 0 ? '+' : ''}${stock.epsGrowthQuarterlyYoy!.toStringAsFixed(2)}%' : '--',
      'epsGrowthTTMYoY': stock.epsGrowthTTMYoy != null ? '${stock.epsGrowthTTMYoy! >= 0 ? '+' : ''}${stock.epsGrowthTTMYoy!.toStringAsFixed(2)}%' : '--',
      'revenueShareGrowth5Y': stock.revenueShareGrowth5Y != null ? '${stock.revenueShareGrowth5Y! >= 0 ? '+' : ''}${stock.revenueShareGrowth5Y!.toStringAsFixed(2)}%' : '--',
      'roe5Y': stock.roe5Y != null ? '${stock.roe5Y!.toStringAsFixed(2)}%' : '--',
      'roa5Y': stock.roa5Y != null ? '${stock.roa5Y!.toStringAsFixed(2)}%' : '--',
      'assetsGrowth1Y': stock.assetsGrowth1y != null ? '${stock.assetsGrowth1y! >= 0 ? '+' : ''}${stock.assetsGrowth1y!.toStringAsFixed(2)}%' : '--',
      'assetsGrowth3Y': stock.assetsGrowth3y != null ? '${stock.assetsGrowth3y! >= 0 ? '+' : ''}${stock.assetsGrowth3y!.toStringAsFixed(2)}%' : '--',
      'assetsGrowth5Y': stock.assetsGrowth5y != null ? '${stock.assetsGrowth5y! >= 0 ? '+' : ''}${stock.assetsGrowth5y!.toStringAsFixed(2)}%' : '--',
    };
  }
  
  // Removed _scrollToResults() - no longer needed
}

