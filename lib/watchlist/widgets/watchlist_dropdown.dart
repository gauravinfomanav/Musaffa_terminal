import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/create_watchlist_dialog.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_stocks_table.dart';
import 'package:musaffa_terminal/watchlist/widgets/add_stocks_modal.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_news_widget.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_performance_summary.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';

class WatchlistDropdown extends StatefulWidget {
  final bool isDarkMode;

  const WatchlistDropdown({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<WatchlistDropdown> createState() => _WatchlistDropdownState();
}

class _WatchlistDropdownState extends State<WatchlistDropdown> {
  final GlobalKey _dropdownButtonKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  double? _dropdownWidth;
  List<SimpleRowModel> _tableData = [];

  @override
  void didUpdateWidget(WatchlistDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Clear table data when watchlist changes (different dark mode doesn't matter)
    // This will be handled by the controller's watchlist selection
  }

  void _clearTableData() {
    setState(() {
      _tableData = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WatchlistController>();
    final isDarkMode = widget.isDarkMode;

    return Obx(() {
      final stateKey = controller.isLoading.value
          ? 'loading'
          : controller.errorMessage.isNotEmpty
              ? 'error'
              : controller.isEmpty
                  ? 'empty'
                  : 'content';

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(stateKey),
          child: controller.isLoading.value
              ? _buildLoadingState(isDarkMode)
              : controller.errorMessage.isNotEmpty
                  ? _buildErrorState(controller, isDarkMode)
                  : controller.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : _buildDropdownState(controller, isDarkMode),
        ),
      );
    });
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Column(
      children: [
        WatchlistShimmer.loadingState(isDarkMode: isDarkMode),
        WatchlistShimmer.dropdown(isDarkMode: isDarkMode),
        const SizedBox(height: 8),
        // Shimmer for placeholder content area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: WatchlistShimmer.loadingState(isDarkMode: isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(WatchlistController controller, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error loading watchlists',
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    color: Colors.red.shade400,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: controller.refresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: controller.isLoading.value 
                  ? WatchlistShimmer.retryButton(isDarkMode: isDarkMode)
                  : Text(
                      'RETRY',
                      style: DashboardTextStyles.columnHeader.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: HomeUi.iconWellGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HomeUi.iconWellBorder),
              ),
              child: HomeUi.brandIcon(
                icon: Icons.bookmark_add_outlined,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No watchlists yet',
              style: HomeUi.sectionTitle(isDarkMode),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first watchlist to track stocks\nand monitor positions in real time.',
              textAlign: TextAlign.center,
              style: HomeUi.subtitle(isDarkMode),
            ),
            const SizedBox(height: 24),
            HomeUi.primaryAction(
              label: 'Create Watchlist',
              icon: Icons.add_rounded,
              onTap: () => _showCreateWatchlistDialog(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownState(WatchlistController controller, bool isDarkMode) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: HomeUi.cardDecoration(isDarkMode),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: _WatchlistSelectorTile(
                      key: _dropdownButtonKey,
                      isDarkMode: isDarkMode,
                      isOpen: _isDropdownOpen,
                      name: controller.selectedWatchlist.value?.name ??
                          'Select Watchlist',
                      stockCount:
                          controller.selectedWatchlist.value?.stockCount,
                      isDefault: controller.selectedWatchlist.value != null &&
                          controller.isDefaultWatchlist(
                            controller.selectedWatchlist.value!.id,
                          ),
                      onTap: _toggleDropdown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UnconstrainedBox(
                          child: _buildAddStocksButton(controller, isDarkMode),
                        ),
                        const SizedBox(width: 8),
                        UnconstrainedBox(
                          child: HomeUi.ghostAction(
                            label: 'New Watchlist',
                            icon: Icons.add_rounded,
                            dark: isDarkMode,
                            onTap: () =>
                                _showCreateWatchlistDialog(isDarkMode),
                          ),
                        ),
                        const SizedBox(width: 8),
                        UnconstrainedBox(
                          child: _buildSetDefaultButton(controller, isDarkMode),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildStocksList(controller, isDarkMode),
            ),
          ],
        ),
        if (_isDropdownOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isDropdownOpen = false),
              child: Container(color: Colors.transparent),
            ),
          ),
        if (_isDropdownOpen)
          _buildCustomDropdown(controller, isDarkMode),
      ],
    );
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      setState(() => _isDropdownOpen = false);
      return;
    }

    final renderBox =
        _dropdownButtonKey.currentContext?.findRenderObject() as RenderBox?;
    setState(() {
      _dropdownWidth = renderBox?.size.width;
      _isDropdownOpen = true;
    });
  }

  Widget _buildCustomDropdown(WatchlistController controller, bool isDarkMode) {
    const double itemHeight = 60.0;
    const double padding = 8.0;
    const double maxHeight = 400.0;
    const double minHeight = 100.0;

    final itemCount = controller.watchlists.length;
    final calculatedHeight =
        (itemCount * itemHeight + padding).clamp(minHeight, maxHeight);

    final measuredWidth =
        _dropdownWidth ??
        (_dropdownButtonKey.currentContext?.findRenderObject() as RenderBox?)
            ?.size
            .width;

    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: GestureDetector(
          onTap: () {},
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * -4),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: SizedBox(
              width: measuredWidth,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: calculatedHeight,
                ),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(isDarkMode),
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  border: Border.all(color: HomeUi.borderLight(isDarkMode)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDarkMode ? 0.4 : 0.1,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: controller.watchlists.length,
                    itemBuilder: (context, index) {
                      final watchlist = controller.watchlists[index];
                      final isDefault =
                          controller.isDefaultWatchlist(watchlist.id);
                      final isSelected =
                          controller.selectedWatchlist.value?.id ==
                              watchlist.id;

                      return _WatchlistDropdownItem(
                        isDarkMode: isDarkMode,
                        watchlistName: watchlist.name,
                        stockCount: watchlist.stockCount,
                        isDefault: isDefault,
                        isSelected: isSelected,
                        onTap: () {
                          controller.selectWatchlist(watchlist);
                          setState(() => _isDropdownOpen = false);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildAddStocksButton(WatchlistController controller, bool isDarkMode) {
    final selectedWatchlist = controller.selectedWatchlist.value;

    if (selectedWatchlist == null) {
      return Opacity(
        opacity: 0.45,
        child: HomeUi.primaryAction(
          label: 'Add Stocks',
          icon: Icons.add_rounded,
          onTap: () {},
        ),
      );
    }

    return HomeUi.primaryAction(
      label: 'Add Stocks',
      icon: Icons.add_rounded,
      onTap: () {
        AddStocksModal.show(
          context: Get.context!,
          watchlistName: selectedWatchlist.name,
          watchlistId: selectedWatchlist.id,
        );
      },
    );
  }

  Widget _buildSetDefaultButton(WatchlistController controller, bool isDarkMode) {
    final selectedWatchlist = controller.selectedWatchlist.value;
    final isDefault = selectedWatchlist != null && controller.isDefaultWatchlist(selectedWatchlist.id);
    
    return _DefaultButton(
      isDarkMode: isDarkMode,
      isDefault: isDefault,
      onTap: selectedWatchlist != null && !isDefault ? () async {
        final success = await controller.setDefaultWatchlist(selectedWatchlist.id);
        if (success) {
          // Show success message
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text(
                'Set "${selectedWatchlist.name}" as default watchlist',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              backgroundColor: isDarkMode ? const Color(0xFF374151) : const Color(0xFF6B7280),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }
      } : null,
    );
  }

  Widget _buildStocksList(WatchlistController controller, bool isDarkMode) {
    return Obx(() {
      if (controller.isLoadingStocks.value) {
        return _buildStocksLoadingState(isDarkMode);
      }

      if (controller.stocksErrorMessage.isNotEmpty) {
        return _buildStocksErrorState(controller, isDarkMode);
      }

      if (controller.isStocksEmpty) {
        return _buildEmptyStocksState(controller, isDarkMode);
      }

      return _buildStocksListState(controller, isDarkMode);
    });
  }

  Widget _buildStocksLoadingState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          WatchlistShimmer.loadingState(isDarkMode: isDarkMode),
          const SizedBox(height: 8),
          WatchlistShimmer.listItem(isDarkMode: isDarkMode),
          const SizedBox(height: 4),
          WatchlistShimmer.listItem(isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStocksErrorState(WatchlistController controller, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 24,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading stocks',
            style: DashboardTextStyles.columnHeader.copyWith(
              color: Colors.red.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (controller.selectedWatchlist.value != null) {
                controller.fetchWatchlistStocks(controller.selectedWatchlist.value!.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Text(
                'RETRY',
                style: DashboardTextStyles.columnHeader.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStocksState(WatchlistController controller, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HomeUi.elevatedBg(isDarkMode),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HomeUi.borderLight(isDarkMode)),
              ),
              child: Icon(
                Icons.candlestick_chart_outlined,
                size: 26,
                color: HomeUi.muted(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Watchlist is empty',
              style: HomeUi.sectionTitle(isDarkMode),
            ),
            const SizedBox(height: 6),
            Text(
              'Add stocks to start tracking your investments.',
              textAlign: TextAlign.center,
              style: HomeUi.subtitle(isDarkMode),
            ),
            const SizedBox(height: 20),
            HomeUi.primaryAction(
              label: 'Add Stocks',
              icon: Icons.add_rounded,
              onTap: () {
                final selectedWatchlist = controller.selectedWatchlist.value!;
                AddStocksModal.show(
                  context: Get.context!,
                  watchlistName: selectedWatchlist.name,
                  watchlistId: selectedWatchlist.id,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStocksListState(WatchlistController controller, bool isDarkMode) {
    // Clear table data if current watchlist has no stocks
    if (controller.isStocksEmpty && _tableData.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearTableData();
      });
    }
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_tableData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: WatchlistPerformanceSummary(
                  tableData: _tableData,
                  isDarkMode: isDarkMode,
                ),
              ),
            Container(
              decoration: HomeUi.cardDecoration(isDarkMode),
              clipBehavior: Clip.antiAlias,
              child: WatchlistStocksTable(
                stocks: controller.watchlistStocks,
                isLoading: false,
                errorMessage: null,
                isDarkMode: isDarkMode,
                title: 'Stocks',
                subtitle:
                    '${controller.stocksCount} holdings in this watchlist',
                onDataReady: (data) {
                  setState(() => _tableData = data);
                },
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: HomeUi.cardDecoration(isDarkMode),
              child: WatchlistNewsWidget(
                stocks: controller.watchlistStocks,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showCreateWatchlistDialog(bool isDarkMode) {
    CreateWatchlistDialog.show(
      context: Get.context!,
      isDarkMode: isDarkMode,
    );
  }
}

class _DefaultButton extends StatefulWidget {
  final bool isDarkMode;
  final bool isDefault;
  final VoidCallback? onTap;

  const _DefaultButton({
    required this.isDarkMode,
    required this.isDefault,
    required this.onTap,
  });

  @override
  State<_DefaultButton> createState() => _DefaultButtonState();
}

class _DefaultButtonState extends State<_DefaultButton> {
  @override
  Widget build(BuildContext context) {
    final label = widget.isDefault ? 'Default' : 'Set Default';
    final icon = widget.isDefault ? Icons.star_rounded : Icons.star_outline_rounded;

    if (widget.onTap == null) {
      return Opacity(
        opacity: widget.isDefault ? 0.7 : 0.45,
        child: HomeUi.ghostAction(
          label: label,
          icon: icon,
          dark: widget.isDarkMode,
          onTap: () {},
        ),
      );
    }

    return HomeUi.ghostAction(
      label: label,
      icon: icon,
      dark: widget.isDarkMode,
      onTap: widget.onTap!,
    );
  }
}

class _WatchlistSelectorTile extends StatefulWidget {
  final bool isDarkMode;
  final bool isOpen;
  final String name;
  final int? stockCount;
  final bool isDefault;
  final VoidCallback onTap;

  const _WatchlistSelectorTile({
    super.key,
    required this.isDarkMode,
    required this.isOpen,
    required this.name,
    required this.stockCount,
    required this.isDefault,
    required this.onTap,
  });

  @override
  State<_WatchlistSelectorTile> createState() => _WatchlistSelectorTileState();
}

class _WatchlistSelectorTileState extends State<_WatchlistSelectorTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: HomeUi.filterFieldShell(
          dark: widget.isDarkMode,
          hover: _hover || widget.isOpen,
          accent: widget.isOpen,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: HomeUi.iconWellGradient,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HomeUi.iconWellBorder),
                ),
                child: HomeUi.brandIcon(
                  icon: Icons.bookmark_rounded,
                  size: HomeUi.iconSm,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.name,
                            style: HomeUi.tableCellEmphasis(widget.isDarkMode),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (widget.isDefault) ...[
                          const SizedBox(width: 6),
                          HomeUi.brandIcon(
                            icon: Icons.star_rounded,
                            size: HomeUi.iconXs,
                          ),
                        ],
                      ],
                    ),
                    if (widget.stockCount != null)
                      Text(
                        '${widget.stockCount} stocks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeUi.subtitle(widget.isDarkMode).copyWith(
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: widget.isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: HomeUi.filterChevron(widget.isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistDropdownItem extends StatefulWidget {
  final bool isDarkMode;
  final String watchlistName;
  final int stockCount;
  final bool isDefault;
  final bool isSelected;
  final VoidCallback onTap;

  const _WatchlistDropdownItem({
    required this.isDarkMode,
    required this.watchlistName,
    required this.stockCount,
    required this.isDefault,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_WatchlistDropdownItem> createState() => _WatchlistDropdownItemState();
}

class _WatchlistDropdownItemState extends State<_WatchlistDropdownItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? HomeUi.elevatedBg(widget.isDarkMode)
                : _hover
                    ? HomeUi.elevatedBg(widget.isDarkMode)
                        .withValues(alpha: 0.65)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(HomeUi.radiusSm),
            border: widget.isSelected
                ? Border.all(color: HomeUi.borderStrong(widget.isDarkMode))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.watchlistName,
                            style: HomeUi.tableCellEmphasis(widget.isDarkMode)
                                .copyWith(
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isDefault) ...[
                          const SizedBox(width: 6),
                          HomeUi.brandIcon(
                            icon: Icons.star_rounded,
                            size: HomeUi.iconXs,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.stockCount} stocks',
                      style: HomeUi.subtitle(widget.isDarkMode).copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                HomeUi.brandIcon(
                  icon: Icons.check_rounded,
                  size: HomeUi.iconSm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
