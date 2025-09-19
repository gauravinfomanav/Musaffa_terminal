import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/market_summary.dart';
import 'package:musaffa_terminal/Components/top_movers_widget.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isWatchlistOpen = false;

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
      body: Stack(
        children: [
          Column(
            children: [
              // Tabbar at the top
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IntrinsicWidth(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8.0),
                        child: MarketSummaryDynamicTable(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TopMoversWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Watchlist sidebar overlay - positioned relative to entire screen
          if (_isWatchlistOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleWatchlist, // Close when tapping outside
                child: Container(
                  color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(), // Empty space that closes sidebar when tapped
                      ),
                      GestureDetector(
                        onTap: () {}, // Prevent closing when tapping on sidebar itself
                        child: _buildWatchlistSidebar(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWatchlistSidebar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 1200 
        ? screenWidth * 0.35  // 35% of screen width on larger screens
        : screenWidth > 800 
            ? screenWidth * 0.4  // 40% on medium screens
            : screenWidth * 0.5; // 50% on smaller screens
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth.clamp(320.0, 600.0), // Min 320px, max 600px
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
          
          // Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monitor,
                    size: 32,
                    color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MONITOR PANEL',
                    style: DashboardTextStyles.columnHeader.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track your positions',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
