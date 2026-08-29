import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_model.dart';
import 'package:musaffa_terminal/watchlist/widgets/create_watchlist_dialog.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_stocks_table.dart';
import 'package:musaffa_terminal/watchlist/widgets/add_stocks_modal.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_news_widget.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_overview_row.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_stock_detail_panel.dart';
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
  List<SimpleRowModel> _tableData = [];
  String? _selectedSymbol;

  void _clearTableData() {
    setState(() {
      _tableData = [];
      _selectedSymbol = null;
    });
  }

  SimpleRowModel? get _selectedStock {
    if (_tableData.isEmpty) return null;
    if (_selectedSymbol != null) {
      for (final SimpleRowModel row in _tableData) {
        if (row.symbol == _selectedSymbol) return row;
      }
    }
    return _tableData.first;
  }

  void _onTableDataReady(List<SimpleRowModel> data) {
    setState(() {
      _tableData = data;
      if (data.isEmpty) {
        _selectedSymbol = null;
      } else if (_selectedSymbol == null ||
          !data.any((SimpleRowModel r) => r.symbol == _selectedSymbol)) {
        _selectedSymbol = data.first.symbol;
      }
    });
  }

  void _onStockSelected(SimpleRowModel row) {
    setState(() => _selectedSymbol = row.symbol);
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
    // One page scroll: tabs, toolbar, table, and detail all move together.
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWatchlistTabBar(controller, isDarkMode),
          _buildActionsToolbar(controller, isDarkMode),
          _buildStocksList(controller, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildActionsToolbar(
    WatchlistController controller,
    bool isDarkMode,
  ) {
    final WatchlistModel? selected = controller.selectedWatchlist.value;
    final int count = selected?.stockCount ?? controller.watchlistStocks.length;
    final bool isDefault = selected != null &&
        controller.isDefaultWatchlist(selected.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
      child: Row(
        children: [
          if (selected != null)
            Text(
              count == 1 ? '1 stock' : '$count stocks',
              style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12.5),
            ),
          const Spacer(),
          if (isDefault)
            Container(
              height: HomeUi.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HomeUi.elevatedBg(isDarkMode),
                borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                border: Border.all(color: HomeUi.borderLight(isDarkMode)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: HomeUi.buttonBorder,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Default',
                    style: HomeUi.control(isDarkMode, active: true).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (selected != null) ...[
            HomeUi.ghostAction(
              label: 'Set as default',
              icon: Icons.star_outline_rounded,
              dark: isDarkMode,
              onTap: () async {
                final bool success =
                    await controller.setDefaultWatchlist(selected.id);
                if (!success || !mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Set "${selected.name}" as default watchlist',
                      style: HomeUi.control(isDarkMode, active: true).copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: HomeUi.title(isDarkMode),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          if (selected != null)
            HomeUi.primaryAction(
              label: 'Add stocks',
              icon: Icons.add_rounded,
              onTap: () {
                AddStocksModal.show(
                  context: context,
                  watchlistName: selected.name,
                  watchlistId: selected.id,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWatchlistTabBar(
    WatchlistController controller,
    bool isDarkMode,
  ) {
    final List<WatchlistModel> lists = controller.watchlists.toList();
    final String? selectedId = controller.selectedWatchlist.value?.id;
    final Color muted = HomeUi.muted(isDarkMode);
    final Color border = HomeUi.borderLight(isDarkMode);
    // Match Add Stocks (primary action) label / brand accent.
    final Color selectedColor = HomeUi.buttonBorder;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(lists.length, (int index) {
                  final WatchlistModel watchlist = lists[index];
                  final bool selected = watchlist.id == selectedId;
                  final Color color = selected ? selectedColor : muted;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        controller.selectWatchlist(watchlist);
                        _clearTableData();
                      },
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  selected ? selectedColor : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              watchlist.name,
                              style: HomeUi.control(
                                isDarkMode,
                                active: selected,
                              ).copyWith(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: color,
                              ),
                            ),
                            if (watchlist.stockCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${watchlist.stockCount}',
                                style: HomeUi.label(isDarkMode).copyWith(
                                  fontSize: 11,
                                  color: selected
                                      ? selectedColor.withValues(alpha: 0.75)
                                      : muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, right: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showCreateWatchlistDialog(isDarkMode),
                borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: muted),
                      const SizedBox(width: 4),
                      Text(
                        'New Watchlist',
                        style: HomeUi.control(isDarkMode).copyWith(
                          fontSize: 13,
                          color: muted,
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showDetail = constraints.maxWidth >= 1080;
        final Widget mainColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!controller.isStocksEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: WatchlistOverviewRow(
                  tableData: _tableData,
                  isDarkMode: isDarkMode,
                  isTableLoading: _tableData.isEmpty,
                ),
              ),
            Container(
              decoration: HomeUi.cardDecoration(isDarkMode),
              clipBehavior: Clip.none,
              child: WatchlistStocksTable(
                stocks: controller.watchlistStocks,
                isLoading: false,
                errorMessage: null,
                isDarkMode: isDarkMode,
                title: 'Stocks',
                subtitle:
                    '${controller.stocksCount} holdings in this watchlist',
                onDataReady: _onTableDataReady,
                selectedSymbol: _selectedSymbol,
                onStockSelected: _onStockSelected,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
              decoration: HomeUi.cardDecoration(isDarkMode),
              child: WatchlistNewsWidget(
                stocks: controller.watchlistStocks,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        );

        if (!showDetail) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: mainColumn,
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mainColumn),
              const SizedBox(width: 12),
              SizedBox(
                width: 360,
                child: WatchlistStockDetailPanel(
                  stock: _selectedStock,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _showCreateWatchlistDialog(bool isDarkMode) {
    CreateWatchlistDialog.show(
      context: Get.context!,
      isDarkMode: isDarkMode,
    );
  }
}
