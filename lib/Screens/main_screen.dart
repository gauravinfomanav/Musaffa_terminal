import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:musaffa_terminal/Components/market_indices.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/market_summary.dart';
import 'package:musaffa_terminal/Components/mini_widgets_row.dart';
import 'package:musaffa_terminal/Components/latest_market_news_widget.dart';
import 'package:musaffa_terminal/Components/stock_heatmap.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Controllers/market_summary_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
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
  
  // Resizable table and chart - using width for smooth resizing
  double? _tableWidth; // null means use 50% default
  bool _isHoveringTableChartDivider = false;
  bool _isDraggingTableChartDivider = false;

  @override
  void initState() {
    super.initState();
    Get.put(WatchlistController());
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.dashboard);
    }
    _hideSplash();
    
    // Initialize watchlist slide animation
    _watchlistAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 280),
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
    if (!FeatureNavigation.isEnabled(FeatureKeys.watchlists)) return;

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
    // Keep Dashboard selected whenever home is the top route again.
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true &&
        Get.isRegistered<GlobalSidebarService>()) {
      final sidebar = Get.find<GlobalSidebarService>();
      if (sidebar.activeItem.value != SidebarNavItem.dashboard &&
          sidebar.activeItem.value != SidebarNavItem.profile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (ModalRoute.of(context)?.isCurrent == true) {
            sidebar.setActive(SidebarNavItem.dashboard);
          }
        });
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: HomeUi.pageBg(isDark),
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
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleWatchlist,
                      child: AnimatedBuilder(
                        animation: _watchlistAnimationController,
                        builder: (context, child) {
                          return Container(
                            color: Colors.black.withValues(
                              alpha: 0.28 * _watchlistAnimationController.value,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Container()),
                                SlideTransition(
                                  position: _watchlistSlideAnimation,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: WatchlistSidebar(
                                      isDarkMode: isDark,
                                      onClose: _toggleWatchlist,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
        padding: LayoutConstants.dashboardBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MiniWidgetsRow(),
            const SizedBox(height: LayoutConstants.SECTION_GAP),
            Builder(
              builder: (context) =>
                  _buildTableAndChartRow(MediaQuery.of(context).size.width),
            ),
            const SizedBox(height: LayoutConstants.SECTION_GAP),
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
        padding: LayoutConstants.dashboardBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            MiniWidgetsRow(),
            const SizedBox(height: LayoutConstants.SECTION_GAP),
            _buildTableAndChartRow(screenWidth),
            const SizedBox(height: LayoutConstants.SECTION_GAP),
            _buildHeatmapHub(context),
          ],
        ),
      ),
    );
  }



  static const double _chartNewsGap = 12.0;
  static const int _chartPanelFlex = 68;
  static const int _newsPanelFlex = 32;

  double _tableWidgetHeight(double screenWidth) {
    final summary = Get.isRegistered<MarketSummaryController>()
        ? Get.find<MarketSummaryController>()
        : Get.put(MarketSummaryController());
    return summary.estimatedTableWidgetHeight(screenWidth);
  }

  Widget _buildTableAndChartRow(double screenWidth) {
    final availableWidth = screenWidth -
        (2 * LayoutConstants.SCREEN_PADDING) -
        LayoutConstants.SCREEN_COMPONENTS_PADDING;
    final widgetWidth = availableWidth / 2;

    return Obx(() {
      final summary = Get.isRegistered<MarketSummaryController>()
          ? Get.find<MarketSummaryController>()
          : Get.put(MarketSummaryController());
      // ignore: unused_local_variable
      final _ = summary.dataRows.length;
      final tableHeight = _tableWidgetHeight(screenWidth);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: widgetWidth,
            child: const MarketSummaryDynamicTable(),
          ),
          SizedBox(width: LayoutConstants.SCREEN_COMPONENTS_PADDING),
          SizedBox(
            height: tableHeight,
            width: widgetWidth,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const indicesShrink = 40.0;
                const newsShrink = 15.0;
                final available =
                    (constraints.maxHeight - _chartNewsGap).clamp(1.0, constraints.maxHeight);
                final chartShare = _chartPanelFlex /
                    (_chartPanelFlex + _newsPanelFlex);
                var chartH = available * chartShare - indicesShrink;
                var newsH = available - chartH - newsShrink;
                if (chartH < 80) {
                  chartH = 80;
                  newsH = available - chartH - newsShrink;
                }
                if (newsH < 80) {
                  newsH = 80;
                  chartH = available - newsH - newsShrink;
                }
                final chartBodyHeight = (chartH -
                        DynamicHeightTradingViewConstants.chromeHeight)
                    .clamp(1.0, chartH);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: chartH,
                      child: DynamicHeightTradingView(
                        height: chartBodyHeight,
                        minHeight: chartBodyHeight,
                        maxHeight: chartBodyHeight,
                        useResponsiveHeight: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: _chartNewsGap),
                    SizedBox(
                      height: newsH,
                      child: LatestMarketNewsWidget(height: newsH),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    });
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
    }) {
      return Expanded(
        child: _HeatmapHubTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: onTap,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final canHeatmaps =
              FeatureNavigation.isEnabled(FeatureKeys.heatmaps);
          if (!canHeatmaps) {
            return const SizedBox.shrink();
          }
          return Row(
            children: [
              buildTile(
                icon: CupertinoIcons.chart_bar_alt_fill,
                title: 'Stock Market Heatmap',
                subtitle:
                    'Explore live market breadth across sectors and market caps with interactive zoom and tooltips for each company.',
                onTap: () => FeatureNavigation.toIfAllowed(
                  FeatureKeys.heatmaps,
                  () => const StockHeatmapFullScreenPage(),
                ),
              ),
              const SizedBox(width: LayoutConstants.SCREEN_COMPONENTS_PADDING),
              buildTile(
                icon: CupertinoIcons.chart_pie_fill,
                title: 'ETF Market Heatmap',
                subtitle:
                    'View top ETFs grouped by asset class and theme. Quickly spot flows and performance leaders across US-listed funds.',
                onTap: () => FeatureNavigation.toIfAllowed(
                  FeatureKeys.heatmaps,
                  () => const EtfHeatmapFullScreenPage(),
                ),
              ),
              const SizedBox(width: LayoutConstants.SCREEN_COMPONENTS_PADDING),
              buildTile(
                icon: CupertinoIcons.bitcoin_circle_fill,
                title: 'Crypto Market Map',
                subtitle:
                    'Monitor the digital assets universe by market cap and weekly performance. Drill into leaders and emerging movers.',
                onTap: () => FeatureNavigation.toIfAllowed(
                  FeatureKeys.heatmaps,
                  () => const CryptoHeatmapFullScreenPage(),
                ),
              ),
              const SizedBox(width: LayoutConstants.SCREEN_COMPONENTS_PADDING),
              buildTile(
                icon: CupertinoIcons.arrow_2_circlepath,
                title: 'Forex Cross‑Rates Heatmap',
                subtitle:
                    'Compare strength across major FX pairs and crosses at a glance with a theme-aware, full-width heatmap.',
                onTap: () => FeatureNavigation.toIfAllowed(
                  FeatureKeys.heatmaps,
                  () => const ForexCrossRatesFullScreenPage(),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  EdgeInsets _calculateResponsivePadding(double screenWidth) {
    final padding = (screenWidth * 0.01).clamp(8.0, 24.0);
    return EdgeInsets.all(padding);
  }

}

class _HeatmapHubTile extends StatefulWidget {
  const _HeatmapHubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_HeatmapHubTile> createState() => _HeatmapHubTileState();
}

class _HeatmapHubTileState extends State<_HeatmapHubTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          decoration: HomeUi.cardDecoration(isDark, hover: _hover),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HomeUi.iconWellBorder,
                    width: 1,
                  ),
                  gradient: HomeUi.iconWellGradient,
                ),
                child: Center(
                  child: HomeUi.brandIcon(
                    icon: widget.icon,
                    size: HomeUi.iconXl,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title, style: HomeUi.sectionTitle(isDark)),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HomeUi.subtitle(isDark).copyWith(
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _hover ? HomeUi.elevatedBg(isDark) : Colors.transparent,
                  borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                ),
                child: _hover
                    ? HomeUi.brandIcon(
                        icon: Icons.arrow_forward_ios_rounded,
                        size: HomeUi.iconXs,
                      )
                    : HomeUi.vectorIcon(
                        icon: Icons.arrow_forward_ios_rounded,
                        size: HomeUi.iconXs,
                        color: HomeUi.muted(isDark),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

