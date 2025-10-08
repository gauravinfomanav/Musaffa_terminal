import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';

class EtfDetailsScreen extends StatefulWidget {
  final TickerModel ticker;

  const EtfDetailsScreen({
    Key? key,
    required this.ticker,
  }) : super(key: key);

  @override
  State<EtfDetailsScreen> createState() => _EtfDetailsScreenState();
}

class _EtfDetailsScreenState extends State<EtfDetailsScreen> {
  late WatchlistController watchlistController;
  bool _isWatchlistOpen = false;

  @override
  void initState() {
    super.initState();
    watchlistController = Get.put(WatchlistController());
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Column(
            children: [
              HomeTabBar(
                showBackButton: true,
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
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'This is ETF Details Screen',
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ETF Name: ${widget.ticker.name ?? widget.ticker.companyName ?? 'N/A'}',
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontSize: 18,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Symbol: ${widget.ticker.symbol ?? 'N/A'}',
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontSize: 18,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Exchange: ${widget.ticker.exchange ?? 'N/A'}',
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontSize: 18,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Domicile: ${widget.ticker.domicile ?? widget.ticker.countryName ?? 'N/A'}',
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontSize: 18,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        child: _buildWatchlistSidebar(isDarkMode),
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

  Widget _buildWatchlistSidebar(bool isDarkMode) {
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
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
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

