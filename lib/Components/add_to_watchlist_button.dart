import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_model.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

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
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 220,
                      maxWidth: 280,
                      maxHeight: 300,
                    ),
                    decoration: HomeUi.cardDecoration(widget.isDarkMode),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Add to Watchlist',
                                  style: HomeUi.sectionTitle(widget.isDarkMode)
                                      .copyWith(fontSize: 13),
                                ),
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _removeOverlay,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: HomeUi.muted(widget.isDarkMode),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: HomeUi.borderLight(widget.isDarkMode)),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          _removeOverlay();
          await _addToSpecificWatchlist(watchlist);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: HomeUi.borderLight(widget.isDarkMode).withValues(alpha: 0.7)),
            ),
          ),
          child: Row(
            children: [
              if (isDefault)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: HomeUi.brandIcon(
                    icon: Icons.star_rounded,
                    size: 12,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      watchlist.name,
                      style: HomeUi.tableCellEmphasis(widget.isDarkMode).copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${watchlist.stockCount} stocks',
                      style: HomeUi.subtitle(widget.isDarkMode).copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_rounded,
                size: 16,
                color: HomeUi.muted(widget.isDarkMode),
              ),
            ],
          ),
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
    if (!FeatureNavigation.isEnabled(FeatureKeys.watchlists)) {
      return const SizedBox.shrink();
    }

    if (widget.isInWatchlist) {
      // Show "In Watchlist" state
      return _buildInWatchlistButton();
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: HomeUi.controlHeight,
        decoration: HomeUi.primaryButton(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _isAdding ? null : _addToDefaultWatchlist,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAdding)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Watchlist', style: HomeUi.primaryActionLabel()),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 16,
              color: Colors.white.withValues(alpha: 0.28),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _isAdding ? null : _showWatchlistDropdown,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.expand_more_rounded, size: 16, color: Colors.white),
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
      height: HomeUi.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: HomeUi.iconWellGradient,
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: HomeUi.iconWellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeUi.brandIcon(
            icon: Icons.check_circle_rounded,
            size: 14,
            gradient: HomeUi.iconFillGradient,
          ),
          const SizedBox(width: 6),
          Text(
            'In Watchlist',
            style: HomeUi.control(widget.isDarkMode, active: true).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

