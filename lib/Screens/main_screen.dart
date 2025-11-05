import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/market_summary.dart';
import 'package:musaffa_terminal/Components/market_indices.dart';
import 'package:musaffa_terminal/Components/mini_widgets_row.dart';
import 'package:musaffa_terminal/Components/stock_heatmap.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isWatchlistOpen = false;

  @override
  void initState() {
    super.initState();
    Get.put(WatchlistController());
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
      
      // When opening the watchlist, reset to default watchlist
      if (_isWatchlistOpen) {
        final watchlistController = Get.find<WatchlistController>();
        watchlistController.resetToDefaultWatchlist();
      }
    });
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
              Column(
                children: [
                  HomeTabBar(
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
                    child: _buildResponsiveMainContent(constraints),
                  ),
                ],
              ),
              if (_isWatchlistOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleWatchlist,
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: _buildWatchlistSidebar(constraints),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            const SizedBox(height: 16),            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: MarketSummaryDynamicTable(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DynamicHeightTradingView(),
                ),
              ],
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
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: _calculateMarketSummaryFlex(screenWidth),
                  child: MarketSummaryDynamicTable(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: _calculateMarketIndicesFlex(screenWidth),
                  child: DynamicHeightTradingView(),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    // Always returns 3 for consistent market indices width
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
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        maxLines: 2,
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
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subTextColor),
              ],
            ),
          ),
        ),
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
              subtitle: 'Explore live market breadth across sectors and market caps with interactive zoom and tooltips for each company.',
              onTap: () => _open(const StockHeatmapFullScreenPage()),
              accentColor: unifiedAccent,
            ),
            const SizedBox(width: 12),
            buildTile(
              icon: CupertinoIcons.chart_pie_fill,
              title: 'ETF Market Heatmap',
              subtitle: 'View top ETFs grouped by asset class and theme. Quickly spot flows and performance leaders across US-listed funds.',
              onTap: () => _open(const EtfHeatmapFullScreenPage()),
              accentColor: unifiedAccent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            buildTile(
              icon: CupertinoIcons.bitcoin_circle_fill,
              title: 'Crypto Market Map',
              subtitle: 'Monitor the digital assets universe by market cap and weekly performance. Drill into leaders and emerging movers.',
              onTap: () => _open(const CryptoHeatmapFullScreenPage()),
              accentColor: unifiedAccent,
            ),
            const SizedBox(width: 12),
            buildTile(
              icon: CupertinoIcons.arrow_2_circlepath,
              title: 'Forex Cross‑Rates Heatmap',
              subtitle: 'Compare strength across major FX pairs and crosses at a glance with a theme-aware, full‑width heatmap.',
              onTap: () => _open(const ForexCrossRatesFullScreenPage()),
              accentColor: unifiedAccent,
            ),
          ],
        ),
      ],
    );
  }

  double _calculateResponsiveSidebarWidth(double screenWidth) {
    if (screenWidth < 800) return screenWidth * 0.7;    // 70% of screen
    if (screenWidth < 1200) return screenWidth * 0.8;   // 80% of screen  
    return screenWidth * 0.55;                         // 55% of screen
  }

  Widget _buildWatchlistSidebar(BoxConstraints constraints) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = constraints.maxWidth;
    final sidebarWidth = _calculateResponsiveSidebarWidth(screenWidth);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth.clamp(320.0, 1200.0),
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
    );
  }

}
