import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/controllers/finhub_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';


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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.06),
            blurRadius: isDarkMode ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
              child: Row(
          children: [
            // Back button or Theme toggle button
            if (showBackButton)
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 24,
                  color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                ),
              ),
            if (showBackButton) const SizedBox(width: 12),
            // Theme toggle button
            // GestureDetector(
            //   onTap: onThemeToggle,
            //   child: Container(
            //     width: 44,
            //     height: 44,
            //     decoration: BoxDecoration(
            //       color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7),
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(
            //         color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            //         width: 1,
            //       ),
            //     ),
            //     child: Icon(
            //       isDarkMode ? Icons.light_mode : Icons.dark_mode,
            //       size: 20,
            //       color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            //     ),
            //   ),
            // ),
            // const SizedBox(width: 12),
          // Search field
          Expanded(
            flex: 1,
            child: _SearchField(
              onChanged: onSearch,
              onSubmitted: (_) => onSearchSubmit?.call(),
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 16),
          // Market indices
          Expanded(
            flex: 3,
            child: _MarketIndicesStrip(
              controller: controller,
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 16),
          // Watchlist toggle button
          _WatchlistToggleButton(
            isOpen: isWatchlistOpen,
            onToggle: onWatchlistToggle,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
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
  }

  @override
  void dispose() {
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
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(8),
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
    
    // Navigate to ticker detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TickerDetailScreen(ticker: ticker),
      ),
    );
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
    final screenHeight = MediaQuery.of(context).size.height;
    final fieldHeight = (screenHeight * 0.055).clamp(40.0, 48.0);
    
    return SizedBox(
      key: _searchFieldKey,
      height: fieldHeight,
      child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
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
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          hintText: 'Search symbols, ETFs, or stocks...',
          hintStyle: DashboardTextStyles.tickerSymbol.copyWith(
            color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF4F46E5),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFFDC2626),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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

class _MarketIndicesStrip extends StatelessWidget {
  final FinhubController controller;
  final bool isDarkMode;

  const _MarketIndicesStrip({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.indices.isEmpty) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              8,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: ShimmerWidgets.box(
                    width: 120,
                    height: 18,
                    borderRadius: BorderRadius.circular(6),
                    baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (controller.indices.isEmpty) {
        return const SizedBox.shrink();
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: controller.indices
              .take(20)
              .map(
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: _IndexItem(
                      index: index,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ),
              )
              .toList(),
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  maxWidth: 48,
                  minHeight: 40,
                  maxHeight: 48,
                ),
                decoration: BoxDecoration(
                  color: widget.isOpen 
                      ? (widget.isDarkMode 
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF9FAFB))
                      : (_isHovered 
                          ? (widget.isDarkMode 
                              ? const Color(0xFF2D2D2D).withOpacity(0.5)
                              : const Color(0xFFF9FAFB).withOpacity(0.8))
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Active indicator line
                    if (widget.isOpen)
                      Positioned(
                        left: 2,
                        child: Container(
                          width: 2,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.isDarkMode 
                                ? const Color(0xFF81AACE)
                                : const Color(0xFF81AACE),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    
                    // Icon
                    Icon(
                      widget.isOpen 
                          ? Icons.format_list_bulleted 
                          : Icons.format_list_bulleted_outlined,
                      size: 18,
                      color: widget.isOpen
                          ? (widget.isDarkMode 
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF374151))
                          : (widget.isDarkMode 
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
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

