import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/models/filter_config.dart';
import 'package:musaffa_terminal/services/filter_loader.dart';
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

  int _getResultsCount() {
    int appliedFilters = _filterValues.values.where((v) => v != null).length;
    
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isDarkMode),
                          const SizedBox(height: 24),
                          
                          Expanded(
                            child: _isLoadingFilters
                                ? const Center(child: CircularProgressIndicator())
                                : _buildFilterContent(isDarkMode),
                          ),
                          
                          const SizedBox(height: 24),
                          _buildResultsSection(isDarkMode),
                        ],
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
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
          ),
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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
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
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected 
                      ? Border.all(
                          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  category,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTabs(isDarkMode),
          const SizedBox(height: 16),
          
          Text(
            '$_selectedCategory Filters',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          
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
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 12 : 0),
          child: Row(
            children: List.generate(crossAxisCount, (colIndex) {
              if (colIndex < rowFilters.length) {
                final filterConfig = rowFilters[colIndex];
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: colIndex < crossAxisCount - 1 ? 16 : 0),
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

  Widget _buildResultsSection(bool isDarkMode) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                _getResultsCount() == 0 
                    ? 'No filters applied yet. Use the filters above to screen stocks.'
                    : 'Showing ${_getResultsCount()} stocks matching your criteria',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

