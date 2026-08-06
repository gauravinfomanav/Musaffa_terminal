import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/controllers/finhub_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/Screens/etf_details_screen.dart';
import 'package:musaffa_terminal/Screens/screener_screen.dart';
import 'package:musaffa_terminal/Screens/trading_ideas_screen.dart';
import 'package:musaffa_terminal/Screens/portfolio_idea_screen.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Controllers/floating_action_buttons_controller.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_search_service.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/Components/app_sidebar.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';


class HomeTabBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSearchSubmit;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onWatchlistToggle;
  final bool showBackButton;
  final bool isWatchlistOpen;

  const HomeTabBar({
    super.key, 
    this.onSearch, 
    this.onSearchSubmit,
    this.onThemeToggle,
    this.onWatchlistToggle,
    this.showBackButton = false,
    this.isWatchlistOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinhubController());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fabController = Get.find<FloatingActionButtonsController>();

    return DragTarget<FABType>(
      onWillAccept: (data) => data != null,
      onAccept: (type) {
        // When FAB is dropped on tabbar, remove it (icon will reappear)
        try {
          final fab = fabController.fabs.firstWhere((fab) => fab.type == type);
          fabController.removeFAB(fab.id);
        } catch (e) {
          // FAB not found, ignore
        }
      },
      builder: (context, candidateData, rejectedData) {
        final barBg = candidateData.isNotEmpty
            ? (isDarkMode
                ? const Color(0xFF2D4A6B).withOpacity(0.8)
                : const Color(0xFFDBEAFE).withOpacity(0.8))
            : (isDarkMode ? const Color(0xFF1A1A1A) : Colors.white);
        final borderColor =
            isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
        final screenWidth = MediaQuery.sizeOf(context).width;
        // Responsive centered search: ~45% of screen, clamped.
        final searchWidth = (screenWidth * 0.45).clamp(300.0, 680.0);

        return Container(
          decoration: BoxDecoration(
            color: barBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.06),
                blurRadius: isDarkMode ? 8 : 12,
                offset: const Offset(0, 2),
              ),
            ],
            border: candidateData.isNotEmpty
                ? Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4A9EFF)
                        : const Color(0xFF2563EB),
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SidebarMenuButton(isDarkMode: isDarkMode),
                          const SizedBox(width: 16),
                          if (showBackButton) ...[
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Icon(
                                CupertinoIcons.back,
                                size: 20,
                                color: isDarkMode
                                    ? const Color(0xFFE0E0E0)
                                    : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          SvgPicture.asset(
                            'resources/Small Logo.svg',
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: searchWidth,
                      child: _SearchField(
                        onChanged: onSearch,
                        onSubmitted: (_) => onSearchSubmit?.call(),
                        isDarkMode: isDarkMode,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _NavToolsCluster(isDarkMode: isDarkMode),
                          const SizedBox(width: 8),
                          _WatchlistToggleButton(
                            isOpen: isWatchlistOpen,
                            onToggle: onWatchlistToggle,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 32,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF141414)
                      : const Color(0xFFF8F9FA),
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: _MarketIndicesStrip(
                  controller: controller,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isDarkMode;

  const _SearchField({
    this.onChanged, 
    this.onSubmitted,
    required this.isDarkMode,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchController = TextEditingController();
  List<TickerModel> _searchResults = [];
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchFieldKey = GlobalKey();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Register the focus node with global service
    if (Get.isRegistered<GlobalSearchService>()) {
      Get.find<GlobalSearchService>().registerSearchFocusNode(_focusNode);
    }
  }

  @override
  void dispose() {
    // Unregister the focus node
    if (Get.isRegistered<GlobalSearchService>()) {
      Get.find<GlobalSearchService>().unregisterSearchFocusNode();
    }
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }





  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    
    // Only show overlay if there are search results AND the text field is not empty
    if (_searchResults.isEmpty || _searchController.text.isEmpty) {
      return;
    }
    
    final RenderBox? renderBox = _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height + 4,
        left: position.dx,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final ticker = _searchResults[index];
                return Container(
                  color: Colors.transparent,
                  child: _buildSearchResultItem(ticker),
                );
              },
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      _removeOverlay();
      return;
    }


    try {
      final results = await SearchService.searchStocks(query.trim());
      setState(() {
        _searchResults = results;
      });
      
      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
      _removeOverlay();
    }
  }

  void _onTickerSelected(TickerModel ticker) {
    // Remove overlay and reset state first
    _removeOverlay();
    _searchController.clear();
    _focusNode.unfocus();
    
    // Navigate to appropriate screen based on isStock flag
    if (ticker.isStock) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TickerDetailScreen(ticker: ticker),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EtfDetailsScreen(ticker: ticker),
        ),
      );
    }
  }





  Widget _buildSearchResultItem(TickerModel ticker) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // This ensures the entire area is tappable
      onTap: () {
        _onTickerSelected(ticker);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent, // Make sure background is transparent
          border: Border(
            bottom: BorderSide(
              color: (widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Logo or Icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: showLogo(
                ticker.symbol ?? '',
                ticker.logo ?? '',
                sideWidth: 20,
                name: ticker.symbol ?? '',
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Ticker and Company Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.symbol ?? ticker.ticker ?? '',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFFE0E0E0) : DashboardTextStyles.stockName.color,
                    ),
                  ),
                  Text(
                    ticker.companyName ?? ticker.name ?? '',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF6B7280) : DashboardTextStyles.tickerSymbol.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price with change indicator
            if (ticker.currentPrice != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ticker.percentChange != null && ticker.percentChange! >= 0 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                        size: 12,
                        color: ticker.percentChange != null && ticker.percentChange! >= 0 
                            ? Colors.green.shade600 
                            : Colors.red.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '\$${ticker.currentPrice!.toStringAsFixed(2)}',
                        style: DashboardTextStyles.dataCell.copyWith(
                          color: ticker.percentChange != null && ticker.percentChange! >= 0 
                              ? Colors.green.shade600 
                              : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fieldHeight = 30.0;

    return SizedBox(
      key: _searchFieldKey,
      height: fieldHeight,
      child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          cursorColor: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
          onChanged: (value) {
          if (value.length >= 2) {
            _performSearch(value);
          } else if (value.isEmpty) {
            setState(() {
              _searchResults = [];
            });
            _removeOverlay();
          } else {
            // Clear results when text is less than 2 characters but not empty
            setState(() {
              _searchResults = [];
            });
            _removeOverlay();
          }
        },
        textInputAction: TextInputAction.search,
        style: DashboardTextStyles.stockName.copyWith(
          color: widget.isDarkMode ? const Color(0xFFE0E0E0) : DashboardTextStyles.stockName.color,
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 12.5,
          height: 1.15,
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(
            CupertinoIcons.search,
            size: 15,
            color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 30,
          ),
          hintText: 'Search symbols, ETFs, or stocks...',
          hintStyle: DashboardTextStyles.tickerSymbol.copyWith(
            color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: 12,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          filled: true,
          fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Color(0xFFDC2626),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Color(0xFFDC2626),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketIndicesStrip extends StatefulWidget {
  final FinhubController controller;
  final bool isDarkMode;

  const _MarketIndicesStrip({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<_MarketIndicesStrip> createState() => _MarketIndicesStripState();
}

class _MarketIndicesStripState extends State<_MarketIndicesStrip> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _isHovered = false;
  double _scrollPosition = 0.0;
  double _contentWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isHovered && mounted && _scrollController.hasClients) {
        setState(() {
          _scrollPosition += 1.5; // Slow scroll increment
          // For infinite scroll: when we reach the end of one set, jump back to the start of the next set
          // Since we have 4 duplicates, we can loop seamlessly
          if (_contentWidth > 0 && _scrollPosition >= _contentWidth) {
            // Jump back to the start of the second set (which looks identical to the first)
            _scrollPosition = _scrollPosition - _contentWidth;
          }
        });
        _scrollController.jumpTo(_scrollPosition);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildIndexItems(List<MarketIndex> indices) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: indices
          .map(
            (index) => Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _IndexItem(
                  index: index,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoading.value &&
          widget.controller.indices.isEmpty) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              8,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 12),
                  child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ShimmerWidgets.box(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(6),
                    baseColor: widget.isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                    highlightColor: widget.isDarkMode
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (widget.controller.indices.isEmpty) {
        return const SizedBox.shrink();
      }

      final indices = widget.controller.indices.take(20).toList();
      // Create multiple duplicates for seamless infinite scrolling
      final duplicatedIndices = [...indices, ...indices, ...indices, ...indices];

      return MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), 
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients && _contentWidth == 0.0) {
                  final maxScroll = _scrollController.position.maxScrollExtent;
                  if (maxScroll > 0) {
                    setState(() {
                      // Calculate width of one set of indices (we have 4 duplicates)
                      _contentWidth = maxScroll / 4; 
                    });
                  }
                }
              });

              return _buildIndexItems(duplicatedIndices);
            },
          ),
        ),
      );
    });
  }
}

class _IndexItem extends StatelessWidget {
  final MarketIndex index;
  final bool isDarkMode;

  const _IndexItem({
    required this.index,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final color = index.isPositive 
        ? const Color(0xFF10B981) 
        : const Color(0xFFEF4444);
    final icon = index.isPositive 
        ? Icons.arrow_upward 
        : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MusaffaAutoSizeText.labelMedium(
          index.displayName,
          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
          group: MusaffaAutoSizeText.groups.labelMediumGroup,
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        MusaffaAutoSizeText.labelMedium(
          index.formattedChangePercent,
          color: color,
          group: MusaffaAutoSizeText.groups.labelMediumGroup,
        ),
        
      ],
    );
  }
}

class _NavToolsCluster extends StatelessWidget {
  final bool isDarkMode;

  const _NavToolsCluster({required this.isDarkMode});

  void _goScreener(BuildContext context) {
    bool isOnScreener = false;
    context.visitAncestorElements((element) {
      if (element.widget is ScreenerScreen) {
        isOnScreener = true;
        return false;
      }
      return true;
    });
    if (isOnScreener) return;

    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.screener);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScreenerScreen()),
    );
  }

  void _goIdeas(BuildContext context) {
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.ideas);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TradingIdeasScreen()),
    );
  }

  void _goPortfolio(BuildContext context) {
    bool isOnPortfolio = false;
    context.visitAncestorElements((element) {
      if (element.widget is PortfolioIdeaScreen) {
        isOnPortfolio = true;
        return false;
      }
      return true;
    });
    if (isOnPortfolio) return;

    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.portfolio);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PortfolioIdeaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final border =
        isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final divider =
        isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);

    return Obx(() {
      final fab = Get.find<FloatingActionButtonsController>();
      final tools = <_ToolSpec>[
        if (!fab.shouldHideInTabbar(FABType.screener))
          _ToolSpec(
            label: 'Screener',
            icon: CupertinoIcons.slider_horizontal_3,
            fabType: FABType.screener,
            onTap: () => _goScreener(context),
          ),
        if (!fab.shouldHideInTabbar(FABType.ideas))
          _ToolSpec(
            label: 'Ideas',
            icon: CupertinoIcons.lightbulb,
            fabType: FABType.ideas,
            onTap: () => _goIdeas(context),
          ),
        if (!fab.shouldHideInTabbar(FABType.portfolio))
          _ToolSpec(
            label: 'Portfolios',
            icon: CupertinoIcons.chart_pie,
            fabType: FABType.portfolio,
            onTap: () => _goPortfolio(context),
          ),
      ];

      if (tools.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
          color: isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tools.length; i++) ...[
              if (i > 0)
                Container(width: 1, height: 18, color: divider),
              _ToolSegment(
                spec: tools[i],
                isDarkMode: isDarkMode,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ToolSpec {
  final String label;
  final IconData icon;
  final FABType fabType;
  final VoidCallback onTap;

  const _ToolSpec({
    required this.label,
    required this.icon,
    required this.fabType,
    required this.onTap,
  });
}

class _ToolSegment extends StatefulWidget {
  final _ToolSpec spec;
  final bool isDarkMode;

  const _ToolSegment({
    required this.spec,
    required this.isDarkMode,
  });

  @override
  State<_ToolSegment> createState() => _ToolSegmentState();
}

class _ToolSegmentState extends State<_ToolSegment> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final idle =
        widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final active =
        widget.isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final hoverBg = widget.isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final fabController = Get.find<FloatingActionButtonsController>();
    final color = _hovering ? active : idle;

    final chip = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.spec.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: _hovering ? hoverBg : Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.spec.icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                widget.spec.label,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Tooltip(
      message: 'Drag out to pin as floating button',
      waitDuration: const Duration(milliseconds: 600),
      child: Draggable<FABType>(
        data: widget.spec.fabType,
        onDragEnd: (_) => fabController.addFAB(widget.spec.fabType),
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(6),
          color: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.spec.icon, size: 14, color: active),
                const SizedBox(width: 6),
                Text(
                  widget.spec.label,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: chip),
        child: chip,
      ),
    );
  }
}

class _WatchlistToggleButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback? onToggle;
  final bool isDarkMode;

  const _WatchlistToggleButton({
    required this.isOpen,
    this.onToggle,
    required this.isDarkMode,
  });

  @override
  State<_WatchlistToggleButton> createState() => _WatchlistToggleButtonState();
}

class _WatchlistToggleButtonState extends State<_WatchlistToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onToggle?.call();
  }

  Future<void> _handleStockDrop(SimpleRowModel stockData) async {
    try {
      final watchlistController = Get.find<WatchlistController>();
      
      // Check if we have a default watchlist
      if (watchlistController.defaultWatchlistId == null) {
        // If no default watchlist, use the first available watchlist
        if (watchlistController.watchlists.isNotEmpty) {
          watchlistController.selectedWatchlist.value = watchlistController.watchlists.first;
        } else {
          // Show error if no watchlists exist
          _showErrorSnackBar('No watchlists available. Please create a watchlist first.');
          return;
        }
      }

      // Extract current price from multiple sources
      double currentPrice = 0.0;
      
      // First try to get price from the price field
      if (stockData.price != null) {
        currentPrice = stockData.price!.toDouble();
      } else {
        // Try to extract price from the fields map (formatted string)
        final priceField = stockData.fields['price'];
        if (priceField is String && priceField != '-') {
          // Remove $ and parse the number
          final cleanPrice = priceField.replaceAll('\$', '').replaceAll(',', '');
          currentPrice = double.tryParse(cleanPrice) ?? 0.0;
        }
      }

      // If still no price, try to fetch it from the API
      if (currentPrice == 0.0) {
        try {
          // Try to fetch current price from the stock details API
          final stockDetails = await _fetchStockPrice(stockData.symbol);
          if (stockDetails != null) {
            currentPrice = stockDetails;
          }
        } catch (e) {
          print('Failed to fetch price for ${stockData.symbol}: $e');
        }
      }

      // Prepare stock data for API
      final stockToAdd = {
        'ticker': stockData.symbol,
        'current_price': currentPrice,  // Backend expects underscore, not camelCase
        'addedAt': DateTime.now().toIso8601String(),
      };

      // Add stock to the default/selected watchlist
      final success = await watchlistController.addStocksToWatchlist([stockToAdd]);
      
      if (success) {
        _showSuccessSnackBar('${stockData.symbol} added to watchlist');
      } else {
        _showErrorSnackBar('Failed to add ${stockData.symbol} to watchlist');
      }
    } catch (e) {
      print('Error adding stock to watchlist: $e');
      _showErrorSnackBar('Error adding stock to watchlist');
    }
  }

  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  Future<double?> _fetchStockPrice(String symbol) async {
    try {
      // Use the same API endpoint that the stock details controller uses
      final response = await WebService.getTypesense([
        'collections',
        'stocks_data',
        'documents',
        'search'
      ], {
        'q': symbol,
        'query_by': 'id',
        'per_page': 1,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hits = (data['hits'] as List?) ?? [];
        
        if (hits.isNotEmpty) {
          final doc = (hits.first['document'] as Map?)?.cast<String, dynamic>() ?? {};
          Map<String, dynamic>? sd;
          final v = doc['\$stocks_data'] ?? doc['stocks_data'];
          if (v is Map) sd = v.cast<String, dynamic>();
          if (v is List && v.isNotEmpty) sd = (v.first as Map).cast<String, dynamic>();
          
          if (sd != null && sd['currentPrice'] != null) {
            return double.tryParse(sd['currentPrice'].toString());
          }
        }
      }
    } catch (e) {
      print('Error fetching stock price for $symbol: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<SimpleRowModel>(
      onWillAccept: (data) {
        setState(() {
          _isDragOver = true;
        });
        return true;
      },
      onAccept: (stockData) {
        setState(() {
          _isDragOver = false;
        });
        _handleStockDrop(stockData);
      },
      onLeave: (data) {
        setState(() {
          _isDragOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        // Watchlist button is NOT draggable - it stays in tabbar
        return _buildButtonContent();
      },
    );
  }

  Widget _buildButtonContent() {
    final border =
        widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final idle =
        widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final active =
        widget.isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final accent = const Color(0xFF81AACE);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _isDragOver
                      ? accent.withOpacity(widget.isDarkMode ? 0.2 : 0.12)
                      : widget.isOpen
                          ? (widget.isDarkMode
                              ? const Color(0xFF1C2430)
                              : const Color(0xFFEFF6FF))
                          : (_isHovered
                              ? (widget.isDarkMode
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFF3F4F6))
                              : (widget.isDarkMode
                                  ? const Color(0xFF161616)
                                  : const Color(0xFFFAFAFA))),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isDragOver || widget.isOpen ? accent : border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isDragOver
                        ? Icon(CupertinoIcons.plus_circle, size: 14, color: accent)
                        : SvgPicture.asset(
                            'resources/bookmark.svg',
                            width: 13,
                            height: 13,
                            colorFilter: ColorFilter.mode(
                              widget.isOpen ? accent : idle,
                              BlendMode.srcIn,
                            ),
                          ),
                    const SizedBox(width: 6),
                    Text(
                      _isDragOver ? 'Add' : 'Watchlist',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        color: widget.isOpen || _isDragOver ? active : idle,
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
  }
}
