import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';

class WatchlistSidebar extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onClose;

  const WatchlistSidebar({
    Key? key,
    required this.isDarkMode,
    required this.onClose,
  }) : super(key: key);

  double _calculateResponsiveSidebarWidth(double screenWidth) {
    if (screenWidth < 800) return screenWidth * 0.7;    // 70% of screen
    if (screenWidth < 1200) return screenWidth * 0.8;  // 80% of screen  
    return screenWidth * 0.55;                          // 55% of screen
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = _calculateResponsiveSidebarWidth(screenWidth);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth.clamp(320.0, 1200.0), // Min 320px, max 1200px
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
                  onTap: onClose,
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

