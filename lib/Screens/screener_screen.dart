import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
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

class _ScreenerScreenState extends State<ScreenerScreen> with TickerProviderStateMixin {
  bool _isWatchlistOpen = false;
  late TabController _tabController;
  String _selectedCategory = "Descriptive";
  
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
    super.dispose();
  }

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
    // TODO: Implement actual filtering logic
    setState(() {
      // This will trigger a rebuild and show updated results
    });
  }

  int _getAppliedFiltersCount() {
    return _filterValues.values.where((v) => v != null && v != "any").length;
  }

  int _getResultsCount() {
    int appliedFilters = _getAppliedFiltersCount();
    
    // Mock results based on applied filters
    if (appliedFilters == 0) return 0;
    if (appliedFilters <= 2) return 1250;
    if (appliedFilters <= 4) return 850;
    if (appliedFilters <= 6) return 420;
    if (appliedFilters <= 8) return 180;
    if (appliedFilters <= 10) return 75;
    if (appliedFilters <= 12) return 23;
    if (appliedFilters <= 15) return 8;
    if (appliedFilters <= 18) return 3;
    if (appliedFilters <= 20) return 1;
    
    return 0;
  }

  bool _isFilterApplied(String filterId) {
    final value = _filterValues[filterId];
    return value != null && value != "any";
  }

  @override
  Widget build(BuildContext context) {
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
                            _buildResultsSection(isDarkMode),
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
    
    // Calculate dynamic height: each row ~80px + spacing
    // Add extra space for tabs (60px) + title (40px) + padding
    final contentHeight = (rows * 80.0) + 140;
    
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
          _buildFilterTabs(isDarkMode),
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

  Widget _buildResultsSection(bool isDarkMode) {
    return Container(
      height: 350, // Reduced height
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
        children: [
          Row(
            children: [
              Row(
                children: [
                  Text(
                    'Results',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      fontSize: 14, // Reduced font size
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
          const SizedBox(height: 12), // Reduced spacing
          Expanded(
            child: _buildResultsTable(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(bool isDarkMode) {
    if (_resultsTabsConfig == null) {
      return Center(
        child: Text(
          'Loading results configuration...',
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 14,
            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    final selectedTab = _resultsTabsConfig!.getTabById(_selectedResultsTab);
    
    if (_getResultsCount() == 0) {
      return Center(
        child: Text(
          'No filters applied yet. Use the filters above to screen stocks.',
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 14,
            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // For now, show a placeholder table structure
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Reduced padding
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: selectedTab.columns.map((column) {
              return Expanded(
                flex: column.width ?? 1,
                child: Text(
                  column.label,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 11, // Reduced font size
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6), // Reduced spacing
        
        // Placeholder rows
        Expanded(
          child: ListView.builder(
            itemCount: 10, // Show 10 placeholder rows
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Reduced padding
                margin: const EdgeInsets.only(bottom: 2), // Reduced margin
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: selectedTab.columns.map((column) {
                    return Expanded(
                      flex: column.width ?? 1,
                      child: Text(
                        _getPlaceholderValue(column),
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          fontSize: 10, // Reduced font size
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getPlaceholderValue(ResultsTabColumn column) {
    switch (column.type) {
      case 'text':
        return column.id == 'ticker' ? 'AAPL' : 'Sample Data';
      case 'currency':
        return '\$123.45';
      case 'percentage':
        return '+2.34%';
      case 'number':
        return '1,234.56';
      case 'date':
        return '2024-01-15';
      default:
        return '--';
    }
  }
}

