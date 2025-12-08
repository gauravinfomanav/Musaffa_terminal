import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';

class WatchlistSidebar extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onClose;

  const WatchlistSidebar({
    Key? key,
    required this.isDarkMode,
    required this.onClose,
  }) : super(key: key);

  @override
  State<WatchlistSidebar> createState() => _WatchlistSidebarState();
}

class _WatchlistSidebarState extends State<WatchlistSidebar> {
  double _watchlistWidth = 0.0;
  bool _isHoveringResizeHandle = false;
  bool _isDraggingResize = false;

  double _calculateResponsiveSidebarWidth(double screenWidth) {
    if (screenWidth < 800) return screenWidth * 0.7;    // 70% of screen
    if (screenWidth < 1200) return screenWidth * 0.8;  // 80% of screen  
    return screenWidth * 0.55;                          // 55% of screen
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
              color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border(
                left: BorderSide(
                  color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
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
                    color: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(
                        color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.monitor,
                        size: 16,
                        color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MONITOR',
                          style: TextStyle(
                            color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content - Watchlist Dropdown
                Expanded(
                  child: WatchlistDropdown(isDarkMode: widget.isDarkMode),
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
                          ? (widget.isDarkMode 
                              ? const Color(0xFF4A9EFF) 
                              : const Color(0xFF2563EB))
                          : (widget.isDarkMode 
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

