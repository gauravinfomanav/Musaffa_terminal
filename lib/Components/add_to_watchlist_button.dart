import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_model.dart';

class AddToWatchlistButton extends StatefulWidget {
  final String ticker;
  final double currentPrice;
  final bool isDarkMode;
  final bool isInWatchlist;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const AddToWatchlistButton({
    Key? key,
    required this.ticker,
    required this.currentPrice,
    required this.isDarkMode,
    this.isInWatchlist = false,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<AddToWatchlistButton> createState() => _AddToWatchlistButtonState();
}

class _AddToWatchlistButtonState extends State<AddToWatchlistButton> {
  bool _isAdding = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _addToDefaultWatchlist() async {
    if (_isAdding || widget.isInWatchlist) return;

    setState(() => _isAdding = true);

    try {
      final watchlistController = Get.find<WatchlistController>();

      // Check if we have a default watchlist
      if (watchlistController.defaultWatchlistId == null) {
        // If no default, show the dropdown instead
        _showWatchlistDropdown();
        return;
      }

      // Prepare stock data
      final stockToAdd = {
        'ticker': widget.ticker,
        'current_price': widget.currentPrice,
        'addedAt': DateTime.now().toIso8601String(),
      };

      // Add to default/selected watchlist
      final success = await watchlistController.addStocksToWatchlist([stockToAdd]);

      if (success) {
        widget.onSuccess?.call();
      } else {
        widget.onError?.call();
      }
    } catch (e) {
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _showWatchlistDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final watchlistController = Get.find<WatchlistController>();

    if (watchlistController.watchlists.isEmpty) {
      // Show error if no watchlists
      if (widget.onError != null) {
        widget.onError!();
      }
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              child: CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 220,
                      maxWidth: 280,
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'ADD TO WATCHLIST',
                                style: DashboardTextStyles.columnHeader.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _removeOverlay,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Watchlist items
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: watchlistController.watchlists.length,
                            itemBuilder: (context, index) {
                              final watchlist = watchlistController.watchlists[index];
                              final isDefault = watchlistController.isDefaultWatchlist(watchlist.id);
                              
                              return _buildWatchlistItem(watchlist, isDefault, watchlistController);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildWatchlistItem(WatchlistModel watchlist, bool isDefault, WatchlistController controller) {
    return GestureDetector(
      onTap: () async {
        _removeOverlay();
        await _addToSpecificWatchlist(watchlist);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF404040).withOpacity(0.3) : const Color(0xFFE5E7EB).withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (isDefault)
              Container(
                margin: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.star,
                  size: 12,
                  color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    watchlist.name,
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${watchlist.stockCount} stocks',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              size: 14,
              color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToSpecificWatchlist(WatchlistModel watchlist) async {
    if (_isAdding || widget.isInWatchlist) return;

    setState(() => _isAdding = true);

    try {
      final watchlistController = Get.find<WatchlistController>();

      // Temporarily set this watchlist as selected
      final previousWatchlist = watchlistController.selectedWatchlist.value;
      watchlistController.selectedWatchlist.value = watchlist;

      // Prepare stock data
      final stockToAdd = {
        'ticker': widget.ticker,
        'current_price': widget.currentPrice,
        'addedAt': DateTime.now().toIso8601String(),
      };

      // Add stock
      final success = await watchlistController.addStocksToWatchlist([stockToAdd]);

      // Restore previous selection
      watchlistController.selectedWatchlist.value = previousWatchlist;

      if (success) {
        widget.onSuccess?.call();
      } else {
        widget.onError?.call();
      }
    } catch (e) {
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInWatchlist) {
      // Show "In Watchlist" state
      return _buildInWatchlistButton();
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main button - Add to default
            GestureDetector(
              onTap: _isAdding ? null : _addToDefaultWatchlist,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAdding)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.add,
                        size: 14,
                        color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'ADD TO WATCHLIST',
                      style: DashboardTextStyles.columnHeader.copyWith(
                        color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Divider
            Container(
              width: 1,
              height: 24,
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
            
            // Dropdown button
            GestureDetector(
              onTap: _isAdding ? null : _showWatchlistDropdown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInWatchlistButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode 
            ? const Color(0xFF1A1A1A).withOpacity(0.5)
            : const Color(0xFFF9FAFB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isDarkMode 
              ? const Color(0xFF81AACE).withOpacity(0.5)
              : const Color(0xFF3B82F6).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 6),
          Text(
            'IN WATCHLIST',
            style: DashboardTextStyles.columnHeader.copyWith(
              color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

