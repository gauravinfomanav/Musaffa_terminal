import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/sliding_pill_tabs.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/Controllers/filter_controller.dart';
import 'package:musaffa_terminal/Controllers/screener_strategy_controller.dart';
import 'package:musaffa_terminal/models/filter_config.dart';
import 'package:musaffa_terminal/models/results_tab_config.dart';
import 'package:musaffa_terminal/models/screener_strategy.dart';
import 'package:musaffa_terminal/services/filter_loader.dart';
import 'package:musaffa_terminal/services/results_tabs_loader.dart';
import 'package:musaffa_terminal/widgets/filter_widget_builder.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({Key? key}) : super(key: key);

  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();
  late TabController _tabController;
  String _selectedCategory = "Descriptive";
  late FilterController filterController;
  late ScreenerStrategyController strategyController;
  late ScrollController _scrollController;
  SortState? _resultsSortState;

  // GlobalKey to maintain scroll position
  final GlobalKey _resultsSectionKey = GlobalKey();

  // Keep scroll position
  double _scrollOffset = 0.0;

  ScreenerFiltersConfig? _filtersConfig;
  bool _isLoadingFilters = true;

  // Results tabs
  ResultsTabsConfig? _resultsTabsConfig;
  TabController? _resultsTabController;
  final GlobalKey _resultsTabsKey = GlobalKey();
  String _selectedResultsTab = 'overview';

  // Store all filter values in a map: filterId -> selectedValue
  final Map<String, String?> _filterValues = {};
  bool _isFilterExpanded = false;

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
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.screener);
    }

    // Initialize Controllers
    filterController = Get.put(FilterController());
    strategyController = Get.put(ScreenerStrategyController());

    // Initialize ScrollController with listener to track position
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      _scrollOffset = _scrollController.offset;
    });

    _tabController =
        TabController(length: _filterCategories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _filterCategories[_tabController.index];
          _isFilterExpanded = false;
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
      _syncResultsTabController(config);
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading results tabs: $e');
    }
  }

  void _syncResultsTabController(ResultsTabsConfig config) {
    final i = config.tabs.indexWhere((t) => t.id == _selectedResultsTab);
    final index = i < 0 ? 0 : i;
    if (_resultsTabController != null &&
        _resultsTabController!.length == config.tabs.length) {
      if (_resultsTabController!.index != index) {
        _resultsTabController!.index = index;
      }
      return;
    }
    _resultsTabController?.removeListener(_onResultsTabTick);
    _resultsTabController?.dispose();
    _resultsTabController = TabController(
      length: config.tabs.length,
      vsync: this,
      initialIndex: index,
    );
    _resultsTabController!.addListener(_onResultsTabTick);
  }

  void _onResultsTabTick() {
    final controller = _resultsTabController;
    final config = _resultsTabsConfig;
    if (controller == null || config == null) return;
    final id = config.tabs[controller.index].id;
    if (id != _selectedResultsTab) {
      setState(() {
        _selectedResultsTab = id;
      });
    }
  }

  @override
  void dispose() {
    _resultsTabController?.removeListener(_onResultsTabTick);
    _resultsTabController?.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _toggleWatchlist() {
    if (!_watchlistService.isWatchlistOpen.value) {
      final watchlistController = Get.find<WatchlistController>();
      watchlistController.resetToDefaultWatchlist();
    }
    _watchlistService.toggleWatchlist();
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
            _filterValues[filterId] =
                filterValue.map((e) => e.toString()).join(',');
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

    if (result != null &&
        result['name'] != null &&
        result['name']!.isNotEmpty) {
      final strategy = await strategyController.saveStrategy(
        name: result['name']!,
        description: result['description'],
        filters: currentFilters,
        sortBy: null, // You can add sortBy tracking if needed
        isDefault: false,
      );

      if (strategy != null) {
        SnackBarUtils.showSuccess(
          context,
          'Strategy "${strategy.name}" saved successfully',
        );
      } else {
        SnackBarUtils.showError(
          context,
          strategyController.errorMessage.value.isNotEmpty
              ? strategyController.errorMessage.value
              : 'Failed to save strategy',
        );
      }
    }
  }

  /// Load and show strategies list
  void _showStrategiesList() async {
    await strategyController.fetchStrategies();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Strategies',
      barrierColor: Colors.black.withOpacity(0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _StrategiesListDialog(
          onStrategySelected: (strategy) {
            Navigator.pop(context);
            applyStrategy(strategy);
          },
          onStrategyDelete: (strategy) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: HomeUi.cardBg(
                  Theme.of(context).brightness == Brightness.dark,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Delete strategy',
                  style: HomeUi.sectionTitle(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                content: Text(
                  'Delete "${strategy.name}"? This cannot be undone.',
                  style: HomeUi.subtitle(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: HomeUi.control(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                  HomeUi.primaryAction(
                    label: 'Delete',
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await strategyController.deleteStrategy(strategy.id);
              if (mounted) {
                SnackBarUtils.showSuccess(context, 'Strategy deleted');
              }
            }
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.018),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return FeatureGuard(
      featureKey: FeatureKeys.screener,
      child: _buildScreenerBody(context),
    );
  }

  Widget _buildScreenerBody(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: HomeUi.pageBg(isDarkMode),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
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
                          onWatchlistToggle: _toggleWatchlist,
                          isWatchlistOpen:
                              _watchlistService.isWatchlistOpen.value,
                        )),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: LayoutConstants.dashboardBodyPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(isDarkMode),
                              const SizedBox(
                                  height: LayoutConstants.SECTION_GAP),
                              _isLoadingFilters
                                  ? const SizedBox(
                                      height: 300,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    )
                                  : _buildFilterContent(isDarkMode),
                              const SizedBox(
                                  height: LayoutConstants.SECTION_GAP),
                              _buildResultsSection(isDarkMode,
                                  key: _resultsSectionKey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Obx(() {
                  if (!_watchlistService.isWatchlistOpen.value) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap:
                          () {}, // Prevent closing when tapping on sidebar itself
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stock Screener', style: HomeUi.heading(isDarkMode)),
        const SizedBox(height: 4),
        Text(
          'Filter the universe, then save a strategy.',
          style: HomeUi.subtitle(isDarkMode),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(bool isDarkMode) {
    return SlidingPillTabs(
      itemCount: _filterCategories.length,
      selectedIndex: _tabController.index,
      controller: _tabController,
      isDarkMode: isDarkMode,
      onSelect: (index) => _tabController.animateTo(index),
      itemBuilder: (context, index, isSelected) {
        final category = _filterCategories[index];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: HomeUi.control(isDarkMode, active: isSelected).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : HomeUi.muted(isDarkMode),
              ),
            ),
            if (_getAppliedFiltersCount(category) > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.95)
                      : null,
                  gradient: isSelected ? null : HomeUi.iconFillGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '${_getAppliedFiltersCount(category)}',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFE4621E) : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterContent(bool isDarkMode) {
    if (_filtersConfig == null) {
      return const SizedBox();
    }

    final totalApplied = _getTotalAppliedFiltersCount();
    final filters = _filtersConfig!.getFiltersForCategory(_selectedCategory);
    final visibleCount = _isFilterExpanded ? filters.length : filters.length.clamp(0, 6);
    final hasMore = filters.length > 6;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF13161C), const Color(0xFF0F1218)]
              : [Colors.white, const Color(0xFFFAFBFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF1E2230).withValues(alpha: 0.9)
              : const Color(0xFFE5E7EB).withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar: Tabs + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildFilterTabs(isDarkMode),
              const Spacer(),
              if (totalApplied > 0) ...[
                _buildCompactActionChip(
                  isDarkMode,
                  icon: Icons.save_outlined,
                  label: 'Save',
                  onTap: _saveCurrentFiltersAsStrategy,
                ),
                const SizedBox(width: 6),
              ],
              _buildCompactActionChip(
                isDarkMode,
                icon: Icons.bookmark_outline,
                label: 'Strategies',
                onTap: _showStrategiesList,
                isPrimary: true,
              ),
              if (totalApplied > 0) ...[
                const SizedBox(width: 6),
                _buildCompactActionChip(
                  isDarkMode,
                  icon: Icons.refresh_rounded,
                  label: 'Reset',
                  onTap: _resetAllFilters,
                  isDestructive: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Compact filter row — inline chips style
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: KeyedSubtree(
              key: ValueKey('${_selectedCategory}_$_isFilterExpanded'),
              child: _buildCompactFilterGrid(filters, visibleCount, isDarkMode),
            ),
          ),

          // Applied chips + expand toggle
          if (hasMore || totalApplied > 0) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalApplied > 0)
                  Expanded(child: _buildAppliedFilterChips(isDarkMode))
                else
                  const Spacer(),
                if (hasMore) ...[
                  const SizedBox(width: 8),
                  _buildExpandToggle(isDarkMode, filters.length - 6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactFilterGrid(List<FilterConfig> filters, int visibleCount, bool isDarkMode) {
    const cols = 6;
    const gap = 12.0;
    final visibleFilters = filters.take(visibleCount).toList();
    final rows = (visibleFilters.length / cols).ceil();

    return Column(
      children: List.generate(rows, (rowIdx) {
        final start = rowIdx * cols;
        final end = (start + cols).clamp(0, visibleFilters.length);
        final rowCount = end - start;

        return Padding(
          padding: EdgeInsets.only(bottom: rowIdx < rows - 1 ? gap : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(cols, (colIdx) {
              final idx = start + colIdx;
              if (idx < end) {
                final f = visibleFilters[idx];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: colIdx < rowCount - 1 ? gap : 0,
                    ),
                    child: FilterWidgetBuilder.buildFilter(
                      config: f,
                      selectedValue: _filterValues[f.id],
                      onChanged: (value) {
                        if (_filterValues[f.id] != value) {
                          setState(() => _filterValues[f.id] = value);
                          _applyFilters();
                        }
                      },
                      isDarkMode: isDarkMode,
                      isApplied: _isFilterApplied(f.id),
                      onReset: () => _resetFilter(f.id),
                    ),
                  ),
                );
              }
              return const Expanded(child: SizedBox());
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCompactActionChip(
    bool isDarkMode, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    if (isPrimary) {
      return HomeUi.primaryAction(
        label: label,
        icon: icon,
        onTap: onTap,
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: HomeUi.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1A1E2A)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: isDestructive
                  ? (isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
                  : (isDarkMode ? const Color(0xFF2A2E3A) : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isDestructive
                    ? (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                    : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                      : (isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandToggle(bool isDarkMode, int moreCount) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: HomeUi.iconWellGradient,
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(color: HomeUi.iconWellBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HomeUi.brandIcon(
                icon: _isFilterExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.tune_rounded,
                size: 14,
                gradient: HomeUi.iconFillGradient,
              ),
              const SizedBox(width: 6),
              Text(
                _isFilterExpanded ? 'Less' : '+$moreCount more filters',
                style: HomeUi.control(isDarkMode, active: true).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppliedFilterChips(bool isDarkMode) {
    final applied = <({String id, String label, String value})>[];
    if (_filtersConfig != null) {
      for (final category in ['Descriptive', 'Fundamental', 'Technical', 'Growth']) {
        for (final f in _filtersConfig!.getFiltersForCategory(category)) {
          final val = _filterValues[f.id];
          if (val != null && val.isNotEmpty && val != 'any') {
            String displayLabel = val;
            for (final o in f.options) {
              if (o.value == val) {
                displayLabel = o.label;
                break;
              }
            }
            applied.add((id: f.id, label: f.label, value: displayLabel));
          }
        }
      }
    }
    if (applied.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: applied.map((entry) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF1A1E2A), const Color(0xFF151822)]
                    : [const Color(0xFFF0F1F4), const Color(0xFFEBECF0)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF2A2E3A)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.label}: ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? const Color(0xFF8B8FA3) : const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _resetFilter(entry.id),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2A2E3A)
                          : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 11,
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
            color:
                isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 22 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(crossAxisCount, (colIndex) {
              if (colIndex < rowFilters.length) {
                final filterConfig = rowFilters[colIndex];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: colIndex < crossAxisCount - 1 ? 20 : 0),
                    child: FilterWidgetBuilder.buildFilter(
                      config: filterConfig,
                      selectedValue: _filterValues[filterConfig.id],
                      onChanged: (value) {
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

    final tabs = _resultsTabsConfig!.tabs;
    final selectedIndex = tabs.indexWhere((t) => t.id == _selectedResultsTab);
    return SlidingPillTabs(
      itemCount: tabs.length,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      controller: _resultsTabController,
      isDarkMode: isDarkMode,
      onSelect: (index) {
        _resultsTabController?.animateTo(index);
        setState(() {
          _selectedResultsTab = tabs[index].id;
        });
      },
      itemBuilder: (context, index, isSelected) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tabs[index].label,
              style: HomeUi.control(isDarkMode, active: isSelected).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : HomeUi.muted(isDarkMode),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultsSection(bool isDarkMode, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      decoration: HomeUi.cardDecoration(isDarkMode),
      clipBehavior: Clip.antiAlias,
      child: _buildResultsTable(isDarkMode),
    );
  }

  Widget _buildResultsTable(bool isDarkMode) {
    return Obx(() {
      // Show loading indicator
      if (filterController.isLoading.value) {
        return _buildDynamicTableShimmer(isDarkMode);
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
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      // Convert StocksData to SimpleRowModel for DynamicTable
      List<SimpleRowModel> rows = filterController.stocks.map((stock) {
        final isPositive = (stock.priceChange1DPercent ?? 0) >= 0;
        final changeColor =
            isPositive ? Colors.green.shade600 : Colors.red.shade600;

        return SimpleRowModel(
          symbol: stock.ticker ?? '',
          name: filterController.companyNamesMap[stock.ticker] ??
              stock.companySymbol ??
              stock.ticker ??
              '',
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
            toolbar: _buildResultsTabs(isDarkMode),
            showFixedColumn: true,
            considerPadding: false,
            showOuterShadow: false,
            fixedColumnWidth: 220,
            enableDragging: false,
            enableLivePrices: true,
            zebraStripes: true,
            enableColumnCustomization: true,
            showColumnActionMenu: true,
            showColumnResizeHandle: true,
            headerHeight: 44,
            rowHeight: 56,
            columnSpacing: 24,
            tableId: 'screener_results_table_${_selectedResultsTab}',
            sortState: _resultsSortState,
            onSortChange: (key, direction) {
              setState(() {
                _resultsSortState = SortState(key: key, direction: direction);
              });
            },
          ),

          const SizedBox(height: 4),
          _buildPaginationControls(isDarkMode),
        ],
      );
    });
  }

  Future<void> _goToResultsPage(int page0) async {
    if (page0 == filterController.currentPage) return;
    _scrollOffset = _scrollController.offset;
    await filterController.goToPage(
      page0,
      filters: _convertFiltersForController(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset);
      }
    });
  }

  Widget _buildPaginationControls(bool isDarkMode) {
    return Obx(() {
      final total = filterController.totalFound;
      if (total <= 0) return const SizedBox.shrink();

      final current = filterController.currentPage + 1;
      final pages = filterController.totalPages;
      final items = _screenerPageItems(current, pages);

      return Column(
        children: [
          Divider(
            height: 1,
            thickness: 0.5,
            color: HomeUi.borderLight(isDarkMode),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                          style: HomeUi.tableCell(isDarkMode).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        const TextSpan(text: ' of '),
                        TextSpan(
                          text: _commaNumber(pages),
                          style: HomeUi.tableCell(isDarkMode).copyWith(
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
                      _PaginationIconButton(
                        icon: Icons.chevron_left_rounded,
                        enabled: filterController.hasPreviousPage,
                        isDarkMode: isDarkMode,
                        onTap: () => _goToResultsPage(
                          filterController.currentPage - 1,
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
                          child: _PaginationPageButton(
                            page: item,
                            selected: item == current,
                            isDarkMode: isDarkMode,
                            onTap: () => _goToResultsPage(item - 1),
                          ),
                        );
                      }),
                      const SizedBox(width: 6),
                      _PaginationIconButton(
                        icon: Icons.chevron_right_rounded,
                        enabled: filterController.hasNextPage,
                        isDarkMode: isDarkMode,
                        onTap: () => _goToResultsPage(
                          filterController.currentPage + 1,
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

  List<int?> _screenerPageItems(int current, int total) {
    if (total <= 7) {
      return [for (var i = 1; i <= total; i++) i];
    }
    final set = <int>{1, total, current};
    if (current - 1 > 1) set.add(current - 1);
    if (current + 1 < total) set.add(current + 1);
    if (current <= 3) set.addAll({2, 3, 4});
    if (current >= total - 2) set.addAll({total - 3, total - 2, total - 1});
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
        isNumeric: column.type == 'number' ||
            column.type == 'currency' ||
            column.type == 'percentage',
        width: (column.width ?? _screenerColumnWidth(column.id, column.type))
            .toDouble(),
      );
    }).toList();
  }

  double _screenerColumnWidth(String id, String type) {
    if (id == 'sector') return 176;
    if (id == 'recommendation') return 152;
    if (type == 'percentage') return 136;
    if (type == 'currency' || type == 'number') return 128;
    return 148;
  }

  List<SimpleColumn> _getDefaultColumns() {
    return const [
      SimpleColumn(
          label: 'TICKER', fieldName: 'ticker', isNumeric: false, width: 148),
      SimpleColumn(
          label: 'PRICE', fieldName: 'price', isNumeric: true, width: 128),
      SimpleColumn(
          label: 'CHANGE %',
          fieldName: 'change1D',
          isNumeric: true,
          width: 136),
      SimpleColumn(
          label: 'MKT CAP',
          fieldName: 'marketCap',
          isNumeric: true,
          width: 128),
      SimpleColumn(
          label: 'VOLUME', fieldName: 'volume', isNumeric: true, width: 128),
      SimpleColumn(
          label: 'SECTOR', fieldName: 'sector', isNumeric: false, width: 176),
    ];
  }

  Map<String, String> _getFieldsForStock(dynamic stock) {
    return {
      // Basic fields (removed ticker as requested)
      'price': stock.currentPrice != null
          ? '\$${stock.currentPrice!.toStringAsFixed(2)}'
          : '--',
      'marketCap': stock.usdMarketCap != null
          ? Constants.formatMarketCapFromMillions(stock.usdMarketCap)
          : '--',
      'volume': stock.volume != null ? getShortenedT(stock.volume!) : '--',
      'sector': stock.sector ?? '--',

      // Overview fields
      'change1D': stock.priceChange1DPercent != null
          ? '${stock.priceChange1DPercent! >= 0 ? '+' : ''}${stock.priceChange1DPercent!.toStringAsFixed(2)}%'
          : '--',
      'beta': stock.beta != null ? stock.beta!.toStringAsFixed(2) : '--',
      'peTTM': stock.peTTM != null ? stock.peTTM!.toStringAsFixed(2) : '--',
      'dividendYield': stock.currentDividendYieldTTM != null
          ? '${stock.currentDividendYieldTTM!.toStringAsFixed(2)}%'
          : '--',
      'sharesOutstanding': stock.sharesOutStanding != null
          ? getShortenedT(stock.sharesOutStanding! * 1000000)
          : '--',
      'enterpriseValue': stock.enterpriseValue != null
          ? getShortenedT(stock.enterpriseValue!)
          : '--',
      'recommendation': stock.analystRecommendationWeightedAvg ?? '--',
      'epsTTM': stock.epsTTM != null ? stock.epsTTM!.toStringAsFixed(2) : '--',
      'revenueAnnual': stock.revenueAnnual != null
          ? getShortenedT(stock.revenueAnnual!)
          : '--',
      'netIncome': stock.netIncomeAnnual != null
          ? getShortenedT(stock.netIncomeAnnual!)
          : '--',

      // Valuation fields
      'peAnnual':
          stock.peAnnual != null ? stock.peAnnual!.toStringAsFixed(2) : '--',
      'pbAnnual':
          stock.pbAnnual != null ? stock.pbAnnual!.toStringAsFixed(2) : '--',
      'psTTM': stock.psTTM != null ? stock.psTTM!.toStringAsFixed(2) : '--',
      'psAnnual':
          stock.psAnnual != null ? stock.psAnnual!.toStringAsFixed(2) : '--',
      'evEbit': stock.evEbit != null ? stock.evEbit!.toStringAsFixed(2) : '--',
      'evFcf': stock.evFcf != null ? stock.evFcf!.toStringAsFixed(2) : '--',
      'bookValuePerShare': stock.bookValuePerShareAnnual != null
          ? '\$${stock.bookValuePerShareAnnual!.toStringAsFixed(2)}'
          : '--',
      'pfcfShareTTM': stock.pfcfShareTTM != null
          ? stock.pfcfShareTTM!.toStringAsFixed(2)
          : '--',
      'pcfShareTTM': stock.pcfShareTTM != null
          ? stock.pcfShareTTM!.toStringAsFixed(2)
          : '--',
      'ptbvAnnual': stock.ptbvAnnual != null
          ? stock.ptbvAnnual!.toStringAsFixed(2)
          : '--',

      // Financial fields
      'grossMargin': stock.grossMarginAnnual != null
          ? '${stock.grossMarginAnnual!.toStringAsFixed(2)}%'
          : '--',
      'operatingMargin': stock.operatingMarginAnnual != null
          ? '${stock.operatingMarginAnnual!.toStringAsFixed(2)}%'
          : '--',
      'netProfitMargin': stock.netProfitMarginAnnual != null
          ? '${stock.netProfitMarginAnnual!.toStringAsFixed(2)}%'
          : '--',
      'roe': stock.rOE != null ? '${stock.rOE!.toStringAsFixed(2)}%' : '--',
      'roa':
          stock.roaTTM != null ? '${stock.roaTTM!.toStringAsFixed(2)}%' : '--',
      'debtEquity': stock.totalDebtTotalEquityAnnual != null
          ? stock.totalDebtTotalEquityAnnual!.toStringAsFixed(2)
          : '--',
      'currentRatio': stock.currentRatioAnnual != null
          ? stock.currentRatioAnnual!.toStringAsFixed(2)
          : '--',
      'quickRatio': stock.quickRatioAnnual != null
          ? stock.quickRatioAnnual!.toStringAsFixed(2)
          : '--',
      'assetTurnover': stock.assetTurnoverAnnual != null
          ? stock.assetTurnoverAnnual!.toStringAsFixed(2)
          : '--',
      'inventoryTurnover': stock.inventoryTurnoverAnnual != null
          ? stock.inventoryTurnoverAnnual!.toStringAsFixed(2)
          : '--',
      'receivablesTurnover': stock.receivablesTurnoverTTM != null
          ? stock.receivablesTurnoverTTM!.toStringAsFixed(2)
          : '--',
      'payoutRatio': stock.payoutRatioTTM != null
          ? '${stock.payoutRatioTTM!.toStringAsFixed(2)}%'
          : '--',

      // Performance fields
      'change1W': stock.priceChange1WPercent != null
          ? '${stock.priceChange1WPercent! >= 0 ? '+' : ''}${stock.priceChange1WPercent!.toStringAsFixed(2)}%'
          : '--',
      'change1M': stock.priceChange1MPercent != null
          ? '${stock.priceChange1MPercent! >= 0 ? '+' : ''}${stock.priceChange1MPercent!.toStringAsFixed(2)}%'
          : '--',
      'change3M': stock.priceChange3MPercent != null
          ? '${stock.priceChange3MPercent! >= 0 ? '+' : ''}${stock.priceChange3MPercent!.toStringAsFixed(2)}%'
          : '--',
      'change6M': stock.priceChange6MPercent != null
          ? '${stock.priceChange6MPercent! >= 0 ? '+' : ''}${stock.priceChange6MPercent!.toStringAsFixed(2)}%'
          : '--',
      'change1Y': stock.priceChange1YPercent != null
          ? '${stock.priceChange1YPercent! >= 0 ? '+' : ''}${stock.priceChange1YPercent!.toStringAsFixed(2)}%'
          : '--',
      'change3Y': stock.priceChange3YPercent != null
          ? '${stock.priceChange3YPercent! >= 0 ? '+' : ''}${stock.priceChange3YPercent!.toStringAsFixed(2)}%'
          : '--',
      'change5Y': stock.priceChange5YPercent != null
          ? '${stock.priceChange5YPercent! >= 0 ? '+' : ''}${stock.priceChange5YPercent!.toStringAsFixed(2)}%'
          : '--',
      'priceChangeYTD': stock.priceChangeYTDPercent != null
          ? '${stock.priceChangeYTDPercent! >= 0 ? '+' : ''}${stock.priceChangeYTDPercent!.toStringAsFixed(2)}%'
          : '--',
      'epsAnnual':
          stock.epsAnnual != null ? stock.epsAnnual!.toStringAsFixed(2) : '--',
      'dividendPerShare': stock.dividendPerShareAnnual != null
          ? '\$${stock.dividendPerShareAnnual!.toStringAsFixed(2)}'
          : '--',
      'cashFlowPerShare': stock.cashFlowPerShareAnnual != null
          ? '\$${stock.cashFlowPerShareAnnual!.toStringAsFixed(2)}'
          : '--',

      // Technical fields
      'high52W': stock.d52WeekHigh != null
          ? '\$${stock.d52WeekHigh!.toStringAsFixed(2)}'
          : '--',
      'low52W': stock.d52WeekLow != null
          ? '\$${stock.d52WeekLow!.toStringAsFixed(2)}'
          : '--',
      'avgVolume10D': stock.avgVolume10days != null
          ? getShortenedT(stock.avgVolume10days!)
          : '--',
      'avgVolume30D': stock.avgVolume30days != null
          ? getShortenedT(stock.avgVolume30days!)
          : '--',
      'priceTangibleBookValue': stock.priceTangiblebookValueAnnual != null
          ? stock.priceTangiblebookValueAnnual!.toStringAsFixed(2)
          : '--',
      'marketCapChange3Y': stock.marketCapChange3y != null
          ? '${stock.marketCapChange3y! >= 0 ? '+' : ''}${stock.marketCapChange3y!.toStringAsFixed(2)}%'
          : '--',
      'previousClose': stock.previousClose != null
          ? '\$${stock.previousClose!.toStringAsFixed(2)}'
          : '--',
      'open': stock.open != null ? '\$${stock.open!.toStringAsFixed(2)}' : '--',
      'high': stock.high != null ? '\$${stock.high!.toStringAsFixed(2)}' : '--',
      'low': stock.low != null ? '\$${stock.low!.toStringAsFixed(2)}' : '--',
      'close':
          stock.close != null ? '\$${stock.close!.toStringAsFixed(2)}' : '--',

      // Growth fields
      'revenueGrowth3Y': stock.revenueGrowth3Y != null
          ? '${stock.revenueGrowth3Y! >= 0 ? '+' : ''}${stock.revenueGrowth3Y!.toStringAsFixed(2)}%'
          : '--',
      'revenueGrowth5Y': stock.revenueGrowth5Y != null
          ? '${stock.revenueGrowth5Y! >= 0 ? '+' : ''}${stock.revenueGrowth5Y!.toStringAsFixed(2)}%'
          : '--',
      'epsGrowth3Y': stock.epsGrowth3Y != null
          ? '${stock.epsGrowth3Y! >= 0 ? '+' : ''}${stock.epsGrowth3Y!.toStringAsFixed(2)}%'
          : '--',
      'epsGrowth5Y': stock.epsGrowth5Y != null
          ? '${stock.epsGrowth5Y! >= 0 ? '+' : ''}${stock.epsGrowth5Y!.toStringAsFixed(2)}%'
          : '--',
      'revenueGrowthQuarterlyYoY': stock.revenueGrowthQuarterlyYoy != null
          ? '${stock.revenueGrowthQuarterlyYoy! >= 0 ? '+' : ''}${stock.revenueGrowthQuarterlyYoy!.toStringAsFixed(2)}%'
          : '--',
      'revenueGrowthTTMYoY': stock.revenueGrowthTTMYoy != null
          ? '${stock.revenueGrowthTTMYoy! >= 0 ? '+' : ''}${stock.revenueGrowthTTMYoy!.toStringAsFixed(2)}%'
          : '--',
      'epsGrowthQuarterlyYoY': stock.epsGrowthQuarterlyYoy != null
          ? '${stock.epsGrowthQuarterlyYoy! >= 0 ? '+' : ''}${stock.epsGrowthQuarterlyYoy!.toStringAsFixed(2)}%'
          : '--',
      'epsGrowthTTMYoY': stock.epsGrowthTTMYoy != null
          ? '${stock.epsGrowthTTMYoy! >= 0 ? '+' : ''}${stock.epsGrowthTTMYoy!.toStringAsFixed(2)}%'
          : '--',
      'revenueShareGrowth5Y': stock.revenueShareGrowth5Y != null
          ? '${stock.revenueShareGrowth5Y! >= 0 ? '+' : ''}${stock.revenueShareGrowth5Y!.toStringAsFixed(2)}%'
          : '--',
      'roe5Y':
          stock.roe5Y != null ? '${stock.roe5Y!.toStringAsFixed(2)}%' : '--',
      'roa5Y':
          stock.roa5Y != null ? '${stock.roa5Y!.toStringAsFixed(2)}%' : '--',
      'revenueGrowth1Y': stock.revenueGrowth1Y != null
          ? '${stock.revenueGrowth1Y! >= 0 ? '+' : ''}${stock.revenueGrowth1Y!.toStringAsFixed(2)}%'
          : '--',
      'revenuePerShare': stock.revenuePerShareAnnual != null
          ? '\$${stock.revenuePerShareAnnual!.toStringAsFixed(2)}'
          : '--',
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
              : (isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFF0F0F0)),
          foregroundColor: hasStocks
              ? (isDarkMode ? Colors.white : Colors.black87)
              : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: hasStocks
                  ? (isDarkMode
                      ? const Color(0xFF404040)
                      : const Color(0xFFD0D0D0))
                  : (isDarkMode
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE0E0E0)),
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
                    borderSide: const BorderSide(
                      color: Color(0xFFC42329),
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

  Future<void> _addStocksToNewWatchlist(
      String watchlistName, List<dynamic> stocks) async {
    final watchlistController = Get.find<WatchlistController>();

    try {
      // Get ALL filtered stocks, not just the current page
      final allFilteredStocks = await _getAllFilteredStocks();

      // If no stocks found from all pages, use current page stocks as fallback
      final stocksToUse =
          allFilteredStocks.isNotEmpty ? allFilteredStocks : stocks;

      // Convert stocks to the format expected by the watchlist API
      final stockTickers = stocksToUse
          .map((stock) => stock.ticker)
          .where((ticker) => ticker != null)
          .cast<String>()
          .toList();

      // Create watchlist and add stocks
      final success = await watchlistController.addStocksToNewWatchlist(
          watchlistName, stockTickers);

      if (success) {
        SnackBarUtils.showSuccess(
          context,
          'Added ${stockTickers.length} stocks to "$watchlistName"',
        );
      } else {
        SnackBarUtils.showError(
          context,
          'Failed to create watchlist or add stocks',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        'An error occurred: $e',
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

  Widget _buildDynamicTableShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many shimmer boxes we need to fill the width
        // Fixed column: ~200px, each scrollable column: ~75px (smaller), spacing: 8px
        final fixedColumnWidth = 200.0;
        final columnWidth = 75.0;
        final spacing = 8.0;
        final availableWidth =
            constraints.maxWidth - fixedColumnWidth - spacing;
        final numColumns =
            (availableWidth / (columnWidth + spacing)).floor().clamp(4, 20);

        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: List.generate(
              10,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    ShimmerWidgets.box(
                      height: 36,
                      width: fixedColumnWidth,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Row(
                        children: List.generate(
                          numColumns,
                          (colIndex) => Padding(
                            padding: EdgeInsets.only(right: spacing),
                            child: ShimmerWidgets.box(
                              height: 36,
                              width: columnWidth,
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: _isHovering
                ? HomeUi.elevatedBg(widget.isDarkMode)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          ),
          alignment: Alignment.center,
          height: HomeUi.controlHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 14,
                color: HomeUi.muted(widget.isDarkMode),
              ),
              const SizedBox(width: 6),
              Text(
                'Reset All',
                style: HomeUi.control(widget.isDarkMode).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
      backgroundColor: HomeUi.cardBg(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
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
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
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
                  color: isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFC42329),
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
                  color: isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFC42329),
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
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'name': _nameController.text.trim(),
                  'description': _descriptionController.text.trim(),
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: HomeUi.primaryButton(),
              child: Text(
                'Save',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Dialog for strategies list
class _StrategiesListDialog extends StatelessWidget {
  final Function(ScreenerStrategy) onStrategySelected;
  final Function(ScreenerStrategy) onStrategyDelete;

  const _StrategiesListDialog({
    required this.onStrategySelected,
    required this.onStrategyDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final strategyController = Get.find<ScreenerStrategyController>();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HomeUi.borderLight(isDarkMode)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.42 : 0.10),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: HomeUi.iconWellGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HomeUi.iconWellBorder),
                        ),
                        child: const Icon(
                          Icons.bookmark_outline,
                          size: 18,
                          color: Color(0xFFC42329),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Obx(() {
                          final count = strategyController.strategies.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Strategies',
                                style: HomeUi.heading(isDarkMode).copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                count == 0
                                    ? 'Saved filter sets'
                                    : '$count saved ${count == 1 ? 'strategy' : 'strategies'}',
                                style: HomeUi.subtitle(isDarkMode),
                              ),
                            ],
                          );
                        }),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: HomeUi.controlHeight,
                            height: HomeUi.controlHeight,
                            decoration: BoxDecoration(
                              color: HomeUi.elevatedBg(isDarkMode),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: HomeUi.muted(isDarkMode),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Obx(() {
                    if (strategyController.isLoading.value) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDarkMode),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    if (strategyController.strategies.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 44,
                        ),
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDarkMode),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_border_rounded,
                              size: 32,
                              color: HomeUi.muted(isDarkMode),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No saved strategies',
                              style: HomeUi.sectionTitle(isDarkMode),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Save current filters to create a strategy.',
                              textAlign: TextAlign.center,
                              style: HomeUi.subtitle(isDarkMode),
                            ),
                          ],
                        ),
                      );
                    }

                    final strategies = strategyController.strategies;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.56,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                        itemCount: strategies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final strategy = strategies[index];
                          return _StrategyRow(
                            strategy: strategy,
                            isDarkMode: isDarkMode,
                            onTap: () => onStrategySelected(strategy),
                            onDelete: () => onStrategyDelete(strategy),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StrategyRow extends StatefulWidget {
  final ScreenerStrategy strategy;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StrategyRow({
    required this.strategy,
    required this.isDarkMode,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_StrategyRow> createState() => _StrategyRowState();
}

class _StrategyRowState extends State<_StrategyRow> {
  bool _hover = false;
  bool _deleteHover = false;

  String get _initial {
    final name = widget.strategy.name.trim();
    return name.isEmpty ? 'S' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final strategy = widget.strategy;
    final filterCount = strategy.filters.length;
    final desc = strategy.description;
    const radius = 12.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: _hover ? HomeUi.iconFillGradient : null,
            color: _hover ? null : HomeUi.borderLight(dark),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  dark ? (_hover ? 0.32 : 0.22) : (_hover ? 0.10 : 0.06),
                ),
                blurRadius: _hover ? 16 : 10,
                offset: Offset(0, _hover ? 6 : 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(_hover ? 1.5 : 1),
          child: Container(
            decoration: BoxDecoration(
              color: HomeUi.cardBg(dark),
              borderRadius: BorderRadius.circular(radius - 1),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: HomeUi.iconWellGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HomeUi.iconWellBorder),
                  ),
                  child: Text(
                    _initial,
                    style: HomeUi.sectionTitle(dark).copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              strategy.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HomeUi.sectionTitle(dark).copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (strategy.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: HomeUi.iconFillGradient,
                                borderRadius: BorderRadius.circular(
                                  HomeUi.radiusPill,
                                ),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: HomeUi.overline(false).copyWith(
                                  fontSize: 9,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeUi.subtitle(dark).copyWith(fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$filterCount ${filterCount == 1 ? 'filter' : 'filters'}',
                  style: HomeUi.control(dark).copyWith(fontSize: 12),
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  onEnter: (_) => setState(() => _deleteHover = true),
                  onExit: (_) => setState(() => _deleteHover = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: HomeUi.controlHeight,
                      height: HomeUi.controlHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _deleteHover
                            ? HomeUi.iconFillGradient
                            : HomeUi.iconWellGradient,
                        border: Border.all(
                          color: _deleteHover
                              ? HomeUi.buttonBorder
                              : HomeUi.iconWellBorder,
                          width: 0.856,
                        ),
                      ),
                      child: _deleteHover
                          ? const Icon(
                              CupertinoIcons.trash,
                              size: 14,
                              color: Colors.white,
                            )
                          : HomeUi.brandIcon(
                              icon: CupertinoIcons.trash,
                              size: 14,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationIconButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _PaginationIconButton({
    required this.icon,
    required this.enabled,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_PaginationIconButton> createState() => _PaginationIconButtonState();
}

class _PaginationIconButtonState extends State<_PaginationIconButton> {
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

class _PaginationPageButton extends StatefulWidget {
  final int page;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _PaginationPageButton({
    required this.page,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_PaginationPageButton> createState() => _PaginationPageButtonState();
}

class _PaginationPageButtonState extends State<_PaginationPageButton> {
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
