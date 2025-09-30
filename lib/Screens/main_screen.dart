import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/market_summary.dart';
import 'package:musaffa_terminal/Components/market_indices.dart';
// import 'package:musaffa_terminal/Components/top_movers_widget.dart';
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
    final padding = _calculateResponsivePadding(screenWidth);
    
    if (screenWidth < 1000) {
      return _buildVerticalLayout(padding);
    } else {
      return _buildHorizontalLayout(padding, screenWidth);
    }
  }

  Widget _buildVerticalLayout(EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: MarketSummaryDynamicTable(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: DynamicHeightTradingView(
              initialHeight: 500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(EdgeInsets padding, double screenWidth) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _calculateMarketSummaryFlex(screenWidth),
            child: SingleChildScrollView(
              child: MarketSummaryDynamicTable(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: _calculateMarketIndicesFlex(screenWidth),
            child: DynamicHeightTradingView(
              initialHeight: 600,
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _calculateResponsivePadding(double screenWidth) {
    final padding = (screenWidth * 0.01).clamp(8.0, 24.0);
    return EdgeInsets.all(padding);
  }

  int _calculateMarketSummaryFlex(double screenWidth) {
    if (screenWidth < 1200) return 2;
    if (screenWidth < 1600) return 3;
    if (screenWidth < 2000) return 4;
    return 5;
  }

  int _calculateTopMoversFlex(double screenWidth) {
    if (screenWidth < 1200) return 3;
    if (screenWidth < 1600) return 2;
    if (screenWidth < 2000) return 1;
    return 1;
  }

  int _calculateMarketIndicesFlex(double screenWidth) {
    if (screenWidth < 1200) return 3;
    if (screenWidth < 1600) return 3;
    if (screenWidth < 2000) return 3;
    return 3;
  }

  double _calculateResponsiveSidebarWidth(double screenWidth) {
    if (screenWidth < 800) return screenWidth * 0.5;
    if (screenWidth < 1200) return screenWidth * 0.4;
    return screenWidth * 0.35;
  }

  Widget _buildWatchlistSidebar(BoxConstraints constraints) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = constraints.maxWidth;
    final sidebarWidth = _calculateResponsiveSidebarWidth(screenWidth);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth.clamp(320.0, 600.0),
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
