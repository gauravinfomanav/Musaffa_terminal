import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:musaffa_terminal/Components/market_indices.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/market_summary.dart';
import 'package:musaffa_terminal/Components/mini_widgets_row.dart';
import 'package:musaffa_terminal/Components/stock_heatmap.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final GlobalWatchlistService _watchlistService = Get.find<GlobalWatchlistService>();
  bool _showSplash = true;
  late AnimationController _watchlistAnimationController;
  late Animation<Offset> _watchlistSlideAnimation;
  double _watchlistWidth = 0.0; 
  bool _isHoveringResizeHandle = false;
  bool _isDraggingResize = false;
  
  // Resizable table and chart - using width for smooth resizing
  double? _tableWidth; // null means use 50% default
  bool _isHoveringTableChartDivider = false;
  bool _isDraggingTableChartDivider = false;

  @override
  void initState() {
    super.initState();
    Get.put(WatchlistController());
    _hideSplash();
    
    // Initialize watchlist slide animation
    _watchlistAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
    );
    
    _watchlistSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _watchlistAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    
    // Listen to global watchlist service changes
    _watchlistService.isWatchlistOpen.listen((isOpen) {
      if (!mounted) return;
      
      if (isOpen) {
        // Ensure animation starts from beginning
        if (_watchlistAnimationController.isCompleted) {
          _watchlistAnimationController.reset();
        } else if (!_watchlistAnimationController.isAnimating && _watchlistAnimationController.value != 0.0) {
          _watchlistAnimationController.reset();
        }
        // Wait for widget to be in tree, then animate in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _watchlistService.isWatchlistOpen.value) {
            _watchlistAnimationController.forward();
          }
        });
      } else {
        // Reverse animation when closing
        if (_watchlistAnimationController.value > 0.0 && !_watchlistAnimationController.isAnimating) {
          _watchlistAnimationController.reverse();
        }
      }
    });
  }

  void _hideSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  void dispose() {
    _watchlistAnimationController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() {
    final watchlistController = Get.find<WatchlistController>();
    
    if (_watchlistService.isWatchlistOpen.value) {
      // Closing: animate out first, then close
      _watchlistAnimationController.reverse().then((_) {
        if (mounted) {
          _watchlistService.closeWatchlist();
        }
      });
    } else {
      // Opening: reset to default watchlist first
      watchlistController.resetToDefaultWatchlist();
      // Then open (animation will sync via listener)
      _watchlistService.openWatchlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
                // Main content
                Column(
                  children: [
                    Obx(() => HomeTabBar(
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
                      child: _buildResponsiveMainContent(constraints),
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
                        color: Colors.black.withOpacity(0.3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(),
                            ),
                            SlideTransition(
                              position: _watchlistSlideAnimation,
                              child: GestureDetector(
                                onTap: () {},
                                child: _buildWatchlistSidebar(constraints),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              // Splash overlay
              if (_showSplash)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                      child: Container(
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.black)
                            .withOpacity(0.4),
                        child: Center(
                          child: Lottie.asset(
                            'resources/Sandy Loading.json',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Global FAB Overlay
              const GlobalFABOverlay(),
            ],
          );
        },
      ),
    );
  }

 Widget _buildResponsiveMainContent(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    
    if (screenWidth < 1000) {
      return _buildVerticalLayout();
    } else {
      return _buildHorizontalLayout(screenWidth);
    }
  }



Widget _buildVerticalLayout() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: LayoutConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MiniWidgetsRow(),
            const SizedBox(height: 12),            
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Calculate available width after padding and spacing
                // Available width = screenWidth - (left padding + right padding + spacing between widgets)
                final availableWidth = screenWidth - (2 * LayoutConstants.SCREEN_PADDING) - LayoutConstants.SCREEN_COMPONENTS_PADDING;
                final widgetWidth = availableWidth / 2;
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table always takes exactly half of available width
                    SizedBox(
                      width: widgetWidth,
                      child: MarketSummaryDynamicTable(),
                    ),
                    SizedBox(width: LayoutConstants.SCREEN_COMPONENTS_PADDING),
                    // TradingView widget also takes exactly half of available width
                    SizedBox(
                      width: widgetWidth,
                      child: DynamicHeightTradingView(
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),            
            _buildHeatmapHub(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(double screenWidth) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: LayoutConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            MiniWidgetsRow(),
            const SizedBox(height: 16),
            
            Builder(
              builder: (context) {
                // Calculate available width after padding and spacing
                // Available width = screenWidth - (left padding + right padding + spacing between widgets)
                final availableWidth = screenWidth - (2 * LayoutConstants.SCREEN_PADDING) - LayoutConstants.SCREEN_COMPONENTS_PADDING;
                final widgetWidth = availableWidth / 2;
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table always takes exactly half of available width
                    SizedBox(
                      width: widgetWidth,
                      child: MarketSummaryDynamicTable(),
                    ),
                    SizedBox(width: LayoutConstants.SCREEN_COMPONENTS_PADDING),
                    // TradingView widget also takes exactly half of available width
                    SizedBox(
                      width: widgetWidth,
                      child: DynamicHeightTradingView(
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            // Bottom Section: Heatmap/Cross Rates hub
            _buildHeatmapHub(context),
          ],
        ),
      ),
    );
  }



  int _calculateMarketSummaryFlex(double screenWidth) {
    if (screenWidth < 1200) return 2;
    if (screenWidth < 1600) return 3;
    if (screenWidth < 2000) return 4;
    return 5;
  }

  int _calculateMarketIndicesFlex(double screenWidth) {
    if (screenWidth < 1200) return 3;
    if (screenWidth < 1600) return 3;
    if (screenWidth < 2000) return 3;
    return 3;
  }

  Widget _buildHeatmapHub(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF151718) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final unifiedAccent = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    

    void _open(Widget page) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 140),
          opaque: false,
          barrierColor: Colors.transparent,
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            final slide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(animation);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
          maintainState: true,
        ),
      );
    }

    Widget buildTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      required Color accentColor,
    }) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isHovering = false;
          bool isChevronHovering = false;

          void setHover(bool value) {
            if (isHovering != value) {
              setState(() => isHovering = value);
            }
          }

          void setChevronHover(bool value) {
            if (isChevronHovering != value) {
              setState(() => isChevronHovering = value);
            }
          }

          final bool shouldHighlight = isHovering || isChevronHovering;
          final Color highlightColor = accentColor.withOpacity(0.2);
          final Color arrowColor = shouldHighlight ? accentColor : subTextColor;
          final Color iconBackgroundColor = shouldHighlight
              ? accentColor.withOpacity(0.22)
              : accentColor.withOpacity(0.12);
          final Color borderHighlight = shouldHighlight
              ? accentColor.withOpacity(0.45)
              : borderColor;

          return Expanded(
            child: MouseRegion(
              onEnter: (_) => setHover(true),
              onExit: (_) => setHover(false),
              cursor: SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: borderHighlight,
                      width: 1,
                    ),
                    boxShadow: shouldHighlight
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.14),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 18, color: arrowColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                letterSpacing: 0.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      MouseRegion(
                        onEnter: (_) => setChevronHover(true),
                        onExit: (_) => setChevronHover(false),
                        cursor: SystemMouseCursors.basic,
                        child: Container(
                          width: 36,
                          height: 36,
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            color: shouldHighlight ? highlightColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: arrowColor,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            buildTile(
              icon: CupertinoIcons.chart_bar_alt_fill,
              title: 'Stock Market Heatmap',
              subtitle:
                  'Explore live market breadth across sectors and market caps with interactive zoom and tooltips for each company.',
              onTap: () => _open(const StockHeatmapFullScreenPage()),
              accentColor: unifiedAccent,
            ),
            const SizedBox(width: 20),
            buildTile(
              icon: CupertinoIcons.chart_pie_fill,
              title: 'ETF Market Heatmap',
              subtitle:
                  'View top ETFs grouped by asset class and theme. Quickly spot flows and performance leaders across US-listed funds.',
              onTap: () => _open(const EtfHeatmapFullScreenPage()),
              accentColor: unifiedAccent,
            ),
            const SizedBox(width: 20),
            buildTile(
              icon: CupertinoIcons.bitcoin_circle_fill,
              title: 'Crypto Market Map',
              subtitle:
                  'Monitor the digital assets universe by market cap and weekly performance. Drill into leaders and emerging movers.',
              onTap: () => _open(const CryptoHeatmapFullScreenPage()),
              accentColor: unifiedAccent,
            ),
            const SizedBox(width: 20),
            buildTile(
              icon: CupertinoIcons.arrow_2_circlepath,
              title: 'Forex Cross‑Rates Heatmap',
              subtitle:
                  'Compare strength across major FX pairs and crosses at a glance with a theme-aware, full-width heatmap.',
              onTap: () => _open(const ForexCrossRatesFullScreenPage()),
              accentColor: unifiedAccent,
            ),
          ],
        ),
      ],
    );
  }

  EdgeInsets _calculateResponsivePadding(double screenWidth) {
    final padding = (screenWidth * 0.01).clamp(8.0, 24.0);
    return EdgeInsets.all(padding);
  }

  double _calculateResponsiveSidebarWidth(double screenWidth) {
    if (screenWidth < 800) return screenWidth * 0.7;    // 70% of screen
    if (screenWidth < 1200) return screenWidth * 0.8;   // 80% of screen  
    return screenWidth * 0.55;                         // 55% of screen
  }

  Widget _buildWatchlistSidebar(BoxConstraints constraints) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = constraints.maxWidth;
    final defaultWidth = _calculateResponsiveSidebarWidth(screenWidth);
    final minWidth = defaultWidth; 
    final maxWidth = screenWidth * 0.9; 
    
    // Initialize width on first build or if not set
    if (_watchlistWidth == 0.0) {
      _watchlistWidth = defaultWidth;
    }
    
    return Stack(
      children: [
        // Main sidebar content
        AnimatedContainer(
          duration: _isDraggingResize 
              ? Duration.zero  // No animation during drag
              : const Duration(milliseconds: 200),
          width: _watchlistWidth.clamp(minWidth, maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border(
                left: BorderSide(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.monitor,
                        size: 16,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MONITOR',
                          style: DashboardTextStyles.columnHeader.copyWith(
                            color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleWatchlist,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content - Watchlist Dropdown
                Expanded(
                  child: WatchlistDropdown(isDarkMode: isDarkMode),
                ),
              ],
            ),
          ),
        ),
        
        // Resize handle on left edge
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onHorizontalDragStart: (_) => setState(() => _isDraggingResize = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                // Dragging left (negative delta) increases width, right decreases it
                _watchlistWidth = (_watchlistWidth - details.delta.dx).clamp(minWidth, maxWidth);
              });
            },
            onHorizontalDragEnd: (_) => setState(() => _isDraggingResize = false),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              onEnter: (_) => setState(() => _isHoveringResizeHandle = true),
              onExit: (_) => setState(() => _isHoveringResizeHandle = false),
              child: Container(
                width: 6.0,
                color: Colors.transparent,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isHoveringResizeHandle || _isDraggingResize ? 3.0 : 1.0,
                    height: _isHoveringResizeHandle || _isDraggingResize ? 40.0 : 20.0,
                    decoration: BoxDecoration(
                      color: _isHoveringResizeHandle || _isDraggingResize
                          ? (isDarkMode 
                              ? const Color(0xFF4A9EFF) 
                              : const Color(0xFF2563EB))
                          : (isDarkMode 
                              ? const Color(0xFF404040).withOpacity(0.3)
                              : const Color(0xFFE5E7EB).withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
