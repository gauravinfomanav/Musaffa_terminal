import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/Controllers/filter_controller.dart';
import 'package:musaffa_terminal/Controllers/screener_strategy_controller.dart';
import 'package:musaffa_terminal/models/filter_config.dart';
import 'package:musaffa_terminal/models/results_tab_config.dart';
import 'package:musaffa_terminal/models/screener_strategy.dart';
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
  late ScreenerStrategyController strategyController;
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
    
    // Initialize Controllers
    filterController = Get.put(FilterController());
    strategyController = Get.put(ScreenerStrategyController());
    
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
    // FilterController expects Map<String, dynamic> where arrays are List<String>
    Map<String, dynamic> filters = {};
    
    _filterValues.forEach((key, value) {
      if (value != null && value != "any" && value.isNotEmpty) {
        // If value contains comma, it's a comma-separated list - convert to array
        if (value.contains(',')) {
          filters[key] = value.split(',').map((e) => e.trim()).toList();
        } else {
        filters[key] = value;
        }
      }
    });
    
    // Always fetch stocks - FilterController handles default filters when none are applied
    filterController.fetchStocks(filters: filters);
    
    setState(() {
      // This will trigger a rebuild and show updated results
    });
  }

  int _getTotalAppliedFiltersCount() {
    return _filterValues.values.where((v) => v != null && v != "any").length;
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

  /// Apply a saved strategy by loading its filters
  Future<void> applyStrategy(ScreenerStrategy strategy) async {
    setState(() {
      // Clear current filters
      _filterValues.clear();
      
      // Map API filters to _filterValues
      // API returns filters as Map<String, dynamic>
      // _filterValues stores Map<String, String?>
      strategy.filters.forEach((filterId, filterValue) {
        if (filterValue != null) {
          if (filterValue is List) {
            // For array filters (e.g., exchange: ["NYSE", "NASDAQ"]), join with comma
            _filterValues[filterId] = filterValue.map((e) => e.toString()).join(',');
          } else {
            // For string/number filters, convert to string
            _filterValues[filterId] = filterValue.toString();
          }
        }
      });
      
      // Apply the filters
      _applyFilters();
    });
  }

  /// Save current filters as a strategy
  Future<void> _saveCurrentFiltersAsStrategy() async {
    // Get current filters and convert to API format
    // _filterValues stores String? values (some may be comma-separated arrays)
    // API expects Map<String, dynamic> where arrays are List<String>
    final currentFilters = <String, dynamic>{};
    _filterValues.forEach((key, value) {
      if (value != null && value != "any" && value.isNotEmpty) {
        // If value contains comma, it's a comma-separated list - convert to array
        if (value.contains(',')) {
          currentFilters[key] = value.split(',').map((e) => e.trim()).toList();
        } else {
          currentFilters[key] = value;
        }
      }
    });

    // Show dialog to enter strategy name
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _SaveStrategyDialog(),
    );

    if (result != null && result['name'] != null && result['name']!.isNotEmpty) {
      final strategy = await strategyController.saveStrategy(
        name: result['name']!,
        description: result['description'],
        filters: currentFilters,
        sortBy: null, // You can add sortBy tracking if needed
        isDefault: false,
      );

      if (strategy != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Strategy "${strategy.name}" saved successfully',
              style: DashboardTextStyles.tickerSymbol.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF374151)
                : const Color(0xFF6B7280),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strategyController.errorMessage.value.isNotEmpty
                  ? strategyController.errorMessage.value
                  : 'Failed to save strategy',
              style: DashboardTextStyles.tickerSymbol.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Load and show strategies list
  void _showStrategiesList() async {
    // Refresh strategies
    await strategyController.fetchStrategies();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF8F9FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => _StrategiesListSheet(
        onStrategySelected: (strategy) {
          Navigator.pop(context);
          applyStrategy(strategy);
        },
        onStrategyDelete: (strategy) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFF8F9FA),
              title: Text(
                'Delete Strategy',
                style: DashboardTextStyles.headerTitle.copyWith(
                  fontSize: 16,
                ),
              ),
              content: Text(
                'Are you sure you want to delete "${strategy.name}"?',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: DashboardTextStyles.tickerSymbol,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Delete',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await strategyController.deleteStrategy(strategy.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Strategy deleted',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF374151)
                      : const Color(0xFF6B7280),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTap: () {
              if (_isWatchlistOpen) {
                setState(() {
                  _isWatchlistOpen = false;
                });
              }
            },
            child: Stack(
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
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping on sidebar itself
                      child: WatchlistSidebar(
                        isDarkMode: isDarkMode,
                        onClose: () => setState(() => _isWatchlistOpen = false),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Text(
          'STOCK SCREENER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          )
    );
  }

  Widget _buildFilterTabs(bool isDarkMode) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(90),
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
                      ? Colors.blue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(90),
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
                        ? Colors.white
                        : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                     ),
                     if (_getAppliedFiltersCount(category) > 0) ...[
                       const SizedBox(width: 4),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                         decoration: BoxDecoration(
                           color: isSelected 
                               ? Colors.white
                               : Colors.blue,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                         child: Text(
                           '${_getAppliedFiltersCount(category)}',
                           style: TextStyle(
                             color: isSelected ? Colors.blue : Colors.white,
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
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
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
              const SizedBox(width: 8),
            
              GestureDetector(
                onTap: _showStrategiesList,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(90),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Strategies',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_getTotalAppliedFiltersCount() > 0) ...[
                const SizedBox(width: 8),
                // Save Strategy button (Secondary - outlined)
                GestureDetector(
                  onTap: _saveCurrentFiltersAsStrategy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(90),
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.save_outlined,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Save',
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reset All button (Tertiary - minimal with hover)
                _ResetAllButton(isDarkMode: isDarkMode, onTap: _resetAllFilters),
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
                        // Only apply filters if the value actually changed
                        final currentValue = _filterValues[filterConfig.id];
                        if (currentValue != value) {
                        setState(() {
                          _filterValues[filterConfig.id] = value;
                        });
                        _applyFilters();
                        }
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
          borderRadius: BorderRadius.circular(90),
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
                      ? Colors.blue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(90),
                ),
                child: Text(
                  tab.label,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? Colors.white
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
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
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
              
              
              if (_getTotalAppliedFiltersCount() > 0) ...[
                Text(
                  '${_getTotalAppliedFiltersCount()} ${_getTotalAppliedFiltersCount() == 1 ? 'filter' : 'filters'}',
                  style: DashboardTextStyles.dataCell.copyWith(
                    fontSize: 12,
                    color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
              ] else ...[
                const Spacer(),
              ],
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
              // Previous button (Secondary - outlined)
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(90),
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: DashboardTextStyles.dataCell.copyWith(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Next button (Primary)
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
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(90),
                    ),
                    child: Text(
                      'Next',
                      style: DashboardTextStyles.dataCell.copyWith(
                        fontSize: 12,
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
      'sharesOutstanding': stock.sharesOutStanding != null ? getShortenedT(stock.sharesOutStanding! * 1000000) : '--',
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
      'epsAnnual': stock.epsAnnual != null ? stock.epsAnnual!.toStringAsFixed(2) : '--',
      'dividendPerShare': stock.dividendPerShareAnnual != null ? '\$${stock.dividendPerShareAnnual!.toStringAsFixed(2)}' : '--',
      'cashFlowPerShare': stock.cashFlowPerShareAnnual != null ? '\$${stock.cashFlowPerShareAnnual!.toStringAsFixed(2)}' : '--',
      
      // Technical fields
      'high52W': stock.d52WeekHigh != null ? '\$${stock.d52WeekHigh!.toStringAsFixed(2)}' : '--',
      'low52W': stock.d52WeekLow != null ? '\$${stock.d52WeekLow!.toStringAsFixed(2)}' : '--',
      'avgVolume10D': stock.avgVolume10days != null ? getShortenedT(stock.avgVolume10days!) : '--',
      'avgVolume30D': stock.avgVolume30days != null ? getShortenedT(stock.avgVolume30days!) : '--',
      'priceTangibleBookValue': stock.priceTangiblebookValueAnnual != null ? stock.priceTangiblebookValueAnnual!.toStringAsFixed(2) : '--',
      'marketCapChange3Y': stock.marketCapChange3y != null ? '${stock.marketCapChange3y! >= 0 ? '+' : ''}${stock.marketCapChange3y!.toStringAsFixed(2)}%' : '--',
      'previousClose': stock.previousClose != null ? '\$${stock.previousClose!.toStringAsFixed(2)}' : '--',
      'open': stock.open != null ? '\$${stock.open!.toStringAsFixed(2)}' : '--',
      'high': stock.high != null ? '\$${stock.high!.toStringAsFixed(2)}' : '--',
      'low': stock.low != null ? '\$${stock.low!.toStringAsFixed(2)}' : '--',
      'close': stock.close != null ? '\$${stock.close!.toStringAsFixed(2)}' : '--',
      
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
      'revenueGrowth1Y': stock.revenueGrowth1Y != null ? '${stock.revenueGrowth1Y! >= 0 ? '+' : ''}${stock.revenueGrowth1Y!.toStringAsFixed(2)}%' : '--',
      'revenuePerShare': stock.revenuePerShareAnnual != null ? '\$${stock.revenuePerShareAnnual!.toStringAsFixed(2)}' : '--',
    };
  }
  
  Widget _buildAddToWatchlistButton(bool isDarkMode) {
    return Obx(() {
      final stocks = filterController.stocks;
      final hasStocks = stocks.isNotEmpty;
      
      return ElevatedButton.icon(
          onPressed: hasStocks ? _showAddToWatchlistDialog : null,
          icon: Icon(
            Icons.add,
            size: 16,
            color: hasStocks 
                ? (isDarkMode ? Colors.white : Colors.black87)
                : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
          ),
          label: Text(
            'Add to Watchlist',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: hasStocks 
                  ? (isDarkMode ? Colors.white : Colors.black87)
                  : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasStocks 
                ? (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5))
                : (isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0)),
            foregroundColor: hasStocks 
                ? (isDarkMode ? Colors.white : Colors.black87)
                : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: hasStocks 
                    ? (isDarkMode ? const Color(0xFF404040) : const Color(0xFFD0D0D0))
                    : (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
          ),
      );
    });
  }
  
  void _showAddToWatchlistDialog() {
    final stocks = filterController.stocks;
    
    if (stocks.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String watchlistName = '';
        
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1A1A1A) 
              : const Color(0xFFF8F9FA),
          title: Text(
            'Add to Watchlist',
            style: DashboardTextStyles.headerTitle.copyWith(
              fontSize: 18,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add all filtered stocks to a new watchlist',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[300] 
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => watchlistName = value,
                decoration: InputDecoration(
                  labelText: 'Watchlist Name',
                  labelStyle: DashboardTextStyles.tickerSymbol.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF404040) 
                          : const Color(0xFFD0D0D0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF404040) 
                          : const Color(0xFFD0D0D0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.blue[400]! 
                          : Colors.blue[600]!,
                    ),
                  ),
                ),
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (watchlistName.trim().isNotEmpty) {
                  _addStocksToNewWatchlist(watchlistName.trim(), stocks);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF2A2A2A) 
                    : const Color(0xFFE5E5E5),
                foregroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Add',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
        );
      },
    );
  }
  
  Future<void> _addStocksToNewWatchlist(String watchlistName, List<dynamic> stocks) async {
    final watchlistController = Get.find<WatchlistController>();
    
    try {
      // Get ALL filtered stocks, not just the current page
      final allFilteredStocks = await _getAllFilteredStocks();
      
      // If no stocks found from all pages, use current page stocks as fallback
      final stocksToUse = allFilteredStocks.isNotEmpty ? allFilteredStocks : stocks;
      
      // Convert stocks to the format expected by the watchlist API
      final stockTickers = stocksToUse.map((stock) => stock.ticker).where((ticker) => ticker != null).cast<String>().toList();
      
      // Create watchlist and add stocks
      final success = await watchlistController.addStocksToNewWatchlist(watchlistName, stockTickers);
      
      if (success) {
        // Show success message using proper snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${stockTickers.length} stocks to "$watchlistName"',
              style: DashboardTextStyles.tickerSymbol.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF374151) 
                : const Color(0xFF6B7280),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      } else {
        // Show error message using proper snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create watchlist or add stocks',
              style: DashboardTextStyles.tickerSymbol.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }
    } catch (e) {
      // Show error message using proper snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: $e',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }
  }
  
  /// Get all filtered stocks across all pages, not just the current page
  Future<List<dynamic>> _getAllFilteredStocks() async {
    try {
      // Build the same filter query that's currently being used
      final filters = <String, dynamic>{};
      
      // Get all applied filters from the UI
      for (String filterId in _filterValues.keys) {
        final value = _filterValues[filterId];
        if (value != null && value != "any") {
          filters[filterId] = value;
        }
      }
      
      // Use the filter controller to fetch all stocks with the same filters
      // but with a large per_page to get all results
      final allStocks = await filterController.fetchAllFilteredStocks(filters);
      return allStocks;
    } catch (e) {
      // Fallback to current page stocks if error occurs
      return filterController.stocks;
    }
  }
  
  // Removed _scrollToResults() - no longer needed
}

// Reset All button with hover effect
class _ResetAllButton extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ResetAllButton({
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_ResetAllButton> createState() => _ResetAllButtonState();
}

class _ResetAllButtonState extends State<_ResetAllButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovering
                ? (widget.isDarkMode 
                    ? const Color(0xFF2A2A2A).withOpacity(0.5)
                    : const Color(0xFFF3F4F6).withOpacity(0.7))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(90),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 14,
                color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                'Reset All',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog for saving strategy
class _SaveStrategyDialog extends StatefulWidget {
  @override
  State<_SaveStrategyDialog> createState() => _SaveStrategyDialogState();
}

class _SaveStrategyDialogState extends State<_SaveStrategyDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      title: Row(
        children: [
          Text(
            'Save Strategy',
            style: DashboardTextStyles.headerTitle.copyWith(
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Strategy Name *',
                labelStyle: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF81AACE),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              ),
              style: DashboardTextStyles.tickerSymbol.copyWith(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF81AACE),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              ),
              style: DashboardTextStyles.tickerSymbol.copyWith(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 12,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF81AACE),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Save',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// Bottom sheet for strategies list
class _StrategiesListSheet extends StatelessWidget {
  final Function(ScreenerStrategy) onStrategySelected;
  final Function(ScreenerStrategy) onStrategyDelete;

  const _StrategiesListSheet({
    required this.onStrategySelected,
    required this.onStrategyDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final strategyController = Get.find<ScreenerStrategyController>();

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'STRATEGIES',
                  style: DashboardTextStyles.headerTitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Obx(() {
            if (strategyController.isLoading.value) {
              return Container(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF81AACE),
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            if (strategyController.strategies.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 32,
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFD0D0D0),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No saved strategies',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Save current filters to create a strategy',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 11,
                          color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: strategyController.strategies.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final strategy = strategyController.strategies[index];
                    final filterCount = strategy.filters.length;

                    return GestureDetector(
                      onTap: () => onStrategySelected(strategy),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Strategy icon/indicator
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: strategy.isDefault 
                                    ? const Color(0xFF81AACE) 
                                    : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          strategy.name,
                                          style: DashboardTextStyles.tickerSymbol.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (strategy.isDefault)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF81AACE),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Text(
                                            'DEFAULT',
                                            style: DashboardTextStyles.tickerSymbol.copyWith(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (strategy.description != null && strategy.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      strategy.description!,
                                      style: DashboardTextStyles.tickerSymbol.copyWith(
                                        fontSize: 11,
                                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Filters count
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '$filterCount',
                                style: DashboardTextStyles.tickerSymbol.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            
                            // Delete button
                            GestureDetector(
                              onTap: () => onStrategyDelete(strategy),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

