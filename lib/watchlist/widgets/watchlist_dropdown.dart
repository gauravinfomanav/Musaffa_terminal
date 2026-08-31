import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/sliding_pill_tabs.dart';
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
        SizedBox(
          height: 360,
          child: WatchlistShimmer.loadingState(isDarkMode: isDarkMode),
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
    return _WatchlistZeroState(
      isDark: isDarkMode,
      title: 'No watchlists yet',
      subtitle:
          'Create your first list to track tickers, set target prices, and follow market news in one place.',
      actionLabel: 'Create Watchlist',
      actionIcon: Icons.add_rounded,
      onAction: () => _showCreateWatchlistDialog(isDarkMode),
      highlights: const <String>[
        'Organize tickers',
        'Set price alerts',
        'Track performance',
      ],
    );
  }

  Widget _buildDropdownState(WatchlistController controller, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWatchlistTabBar(controller, isDarkMode),
        const SizedBox(height: 14),
        _buildStocksList(controller, isDarkMode),
      ],
    );
  }

  Widget _buildWatchlistActionButtons(
    WatchlistController controller,
    bool isDarkMode,
    WatchlistModel selected,
  ) {
    final bool isDefault = controller.isDefaultWatchlist(selected.id);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDefault)
          Container(
            height: HomeUi.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDarkMode),
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
        else
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
        const SizedBox(width: 10),
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
    );
  }

  Widget _buildWatchlistTabBar(
    WatchlistController controller,
    bool isDarkMode,
  ) {
    final List<WatchlistModel> lists = controller.watchlists.toList();
    if (lists.isEmpty) return const SizedBox.shrink();

    final String? selectedId = controller.selectedWatchlist.value?.id;
    int selectedIndex = lists.indexWhere((WatchlistModel w) => w.id == selectedId);
    if (selectedIndex < 0) selectedIndex = 0;

    final WatchlistModel? selected = controller.selectedWatchlist.value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SlidingPillTabs(
                  itemCount: lists.length,
                  selectedIndex: selectedIndex,
                  isDarkMode: isDarkMode,
                  onSelect: (int index) {
                    controller.selectWatchlist(lists[index]);
                    _clearTableData();
                  },
                  itemBuilder:
                      (BuildContext context, int index, bool isSelected) {
                    final WatchlistModel watchlist = lists[index];
                    return SizedBox(
                      height: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            watchlist.name,
                            style: HomeUi.control(isDarkMode, active: isSelected)
                                .copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1,
                              color: isSelected
                                  ? Colors.white
                                  : HomeUi.muted(isDarkMode),
                            ),
                            strutStyle: const StrutStyle(
                              fontSize: 12,
                              height: 1,
                              leading: 0,
                              forceStrutHeight: true,
                            ),
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
                            ),
                          ),
                          if (watchlist.stockCount > 0) ...[
                            const SizedBox(width: 6),
                            _WatchlistTabBadge(
                              count: watchlist.stockCount,
                              isSelected: isSelected,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(width: 12),
          _buildWatchlistActionButtons(controller, isDarkMode, selected),
        ],
      ],
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
    final WatchlistModel selected = controller.selectedWatchlist.value!;
    final String watchlistName = selected.name;

    return _WatchlistZeroState(
      isDark: isDarkMode,
      title: 'No stocks in $watchlistName',
      subtitle:
          'Add tickers to this watchlist to monitor live prices, targets, and headlines.',
      actionLabel: 'Add Stocks',
      actionIcon: Icons.add_rounded,
      onAction: () {
        AddStocksModal.show(
          context: Get.context!,
          watchlistName: selected.name,
          watchlistId: selected.id,
        );
      },
      highlights: const <String>[
        'Live quotes',
        'Target alerts',
        'Watchlist news',
      ],
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
              padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
              decoration: HomeUi.cardDecoration(isDarkMode),
              child: WatchlistNewsWidget(
                stocks: controller.watchlistStocks,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        );

        if (!showDetail) {
          return mainColumn;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: mainColumn),
            const SizedBox(width: LayoutConstants.SCREEN_COMPONENTS_PADDING),
            SizedBox(
              width: 360,
              child: WatchlistStockDetailPanel(
                stock: _selectedStock,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
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

class _WatchlistZeroState extends StatelessWidget {
  const _WatchlistZeroState({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.highlights,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 360),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: highlights
                    .map(
                      (String label) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDark),
                          borderRadius:
                              BorderRadius.circular(HomeUi.radiusPill),
                          border:
                              Border.all(color: HomeUi.borderLight(isDark)),
                        ),
                        child: Text(
                          label,
                          style: HomeUi.control(isDark).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              HomeUi.primaryAction(
                label: actionLabel,
                icon: actionIcon,
                onTap: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistTabBadge extends StatelessWidget {
  const _WatchlistTabBadge({
    required this.count,
    required this.isSelected,
  });

  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final String label = count > 99 ? '99+' : '$count';
    final bool compact = label.length <= 2;

    return Container(
      height: 16,
      width: compact ? 16 : null,
      constraints: compact ? null : const BoxConstraints(minWidth: 16),
      padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.95) : null,
        gradient: isSelected ? null : HomeUi.iconFillGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFFE4621E) : Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          height: 1,
        ),
        textAlign: TextAlign.center,
        strutStyle: const StrutStyle(
          fontSize: 9.5,
          height: 1,
          leading: 0,
          forceStrutHeight: true,
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }
}
