import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
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
  bool _closeHover = false;

  double _calculateResponsiveSidebarWidth(double screenWidth) {
    if (screenWidth < 800) return screenWidth * 0.7;
    if (screenWidth < 1200) return screenWidth * 0.8;
    return screenWidth * 0.55;
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultWidth = _calculateResponsiveSidebarWidth(screenWidth);
    final minWidth = defaultWidth;
    final maxWidth = screenWidth * 0.9;

    if (_watchlistWidth == 0.0) {
      _watchlistWidth = defaultWidth;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: _isDraggingResize
              ? Duration.zero
              : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: _watchlistWidth.clamp(minWidth, maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: HomeUi.pageBg(dark),
              border: Border(
                left: BorderSide(color: HomeUi.borderLight(dark)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.45 : 0.12),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(-8, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(dark),
                Expanded(
                  child: WatchlistDropdown(isDarkMode: dark),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onHorizontalDragStart: (_) =>
                setState(() => _isDraggingResize = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                _watchlistWidth =
                    (_watchlistWidth - details.delta.dx).clamp(minWidth, maxWidth);
              });
            },
            onHorizontalDragEnd: (_) =>
                setState(() => _isDraggingResize = false),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              onEnter: (_) => setState(() => _isHoveringResizeHandle = true),
              onExit: (_) => setState(() => _isHoveringResizeHandle = false),
              child: SizedBox(
                width: 8,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width:
                        _isHoveringResizeHandle || _isDraggingResize ? 3.0 : 1.0,
                    height: _isHoveringResizeHandle || _isDraggingResize
                        ? 48.0
                        : 24.0,
                    decoration: BoxDecoration(
                      gradient: _isHoveringResizeHandle || _isDraggingResize
                          ? HomeUi.iconFillGradient
                          : null,
                      color: _isHoveringResizeHandle || _isDraggingResize
                          ? null
                          : HomeUi.border(dark).withValues(alpha: 0.55),
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

  Widget _buildHeader(bool dark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: HomeUi.headerBg(dark),
        border: Border(bottom: BorderSide(color: HomeUi.borderLight(dark))),
      ),
      child: Row(
        children: [
          HomeUi.tableToolbarHeader(
            dark,
            icon: Icons.monitor_heart_outlined,
            title: 'Monitor',
            subtitleText: 'Watchlists & live positions',
          ),
          const Spacer(),
          MouseRegion(
            onEnter: (_) => setState(() => _closeHover = true),
            onExit: (_) => setState(() => _closeHover = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onClose,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _closeHover ? HomeUi.elevatedBg(dark) : Colors.transparent,
                  borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                  border: Border.all(
                    color: _closeHover
                        ? HomeUi.borderStrong(dark)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: HomeUi.muted(dark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
