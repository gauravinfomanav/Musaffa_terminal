import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_model.dart';
import 'package:musaffa_terminal/watchlist/widgets/create_watchlist_dialog.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_stocks_table.dart';
import 'package:musaffa_terminal/watchlist/widgets/add_stocks_modal.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_news_widget.dart';

class WatchlistDropdown extends StatelessWidget {
  final bool isDarkMode;

  const WatchlistDropdown({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WatchlistController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.errorMessage.isNotEmpty) {
        return _buildErrorState(controller);
      }

      if (controller.isEmpty) {
        return _buildEmptyState();
      }

      return _buildDropdownState(controller);
    });
  }

  Widget _buildLoadingState() {
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

  Widget _buildErrorState(WatchlistController controller) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 48,
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'NO WATCHLISTS',
            style: DashboardTextStyles.columnHeader.copyWith(
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first watchlist to\ntrack stocks and monitor positions',
            textAlign: TextAlign.center,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildCreateButton(isInactive: false),
        ],
      ),
    );
  }

  Widget _buildDropdownState(WatchlistController controller) {
    return Column(
      children: [
        // Dropdown container
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WatchlistModel>(
                    value: controller.selectedWatchlist.value,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    dropdownColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                    style: DashboardTextStyles.stockName.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 12,
                    ),
                    items: controller.watchlists.map((watchlist) {
                      final isDefault = controller.isDefaultWatchlist(watchlist.id);
                      return DropdownMenuItem<WatchlistModel>(
                        value: watchlist,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    watchlist.name,
                                    style: DashboardTextStyles.stockName.copyWith(
                                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${watchlist.stockCount} stocks',
                              style: DashboardTextStyles.tickerSymbol.copyWith(
                                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (WatchlistModel? newValue) {
                      if (newValue != null) {
                        controller.selectWatchlist(newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSetDefaultButton(controller),
              const SizedBox(width: 4),
              _buildCreateButton(isInactive: false),
            ],
          ),
        ),
        
        // Stocks list
        Expanded(
          child: _buildStocksList(controller),
        ),
      ],
    );
  }

  Widget _buildSetDefaultButton(WatchlistController controller) {
    final selectedWatchlist = controller.selectedWatchlist.value;
    final isDefault = selectedWatchlist != null && controller.isDefaultWatchlist(selectedWatchlist.id);
    
    return GestureDetector(
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDefault 
              ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB))
              : (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDefault 
                ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDefault ? Icons.star : Icons.star_border,
              size: 10,
              color: isDefault 
                  ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                  : (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 2),
            Text(
              isDefault ? 'DEFAULT' : 'SET DEFAULT',
              style: DashboardTextStyles.columnHeader.copyWith(
                color: isDefault 
                    ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                    : (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton({required bool isInactive}) {
    return GestureDetector(
      onTap: isInactive ? null : () {
        _showCreateWatchlistDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isInactive 
              ? (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB))
              : (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 12,
              color: isInactive 
                  ? (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                  : (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151)),
            ),
            const SizedBox(width: 4),
            Text(
              'CREATE',
              style: DashboardTextStyles.columnHeader.copyWith(
                color: isInactive 
                    ? (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                    : (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151)),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStocksList(WatchlistController controller) {
    return Obx(() {
      if (controller.isLoadingStocks.value) {
        return _buildStocksLoadingState();
      }

      if (controller.stocksErrorMessage.isNotEmpty) {
        return _buildStocksErrorState(controller);
      }

      if (controller.isStocksEmpty) {
        return _buildEmptyStocksState(controller);
      }

      return _buildStocksListState(controller);
    });
  }

  Widget _buildStocksLoadingState() {
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

  Widget _buildStocksErrorState(WatchlistController controller) {
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

  Widget _buildEmptyStocksState(WatchlistController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_chart_outlined,
            size: 32,
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            'WATCHLIST IS EMPTY',
            style: DashboardTextStyles.columnHeader.copyWith(
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add stocks to start tracking\nyour investments',
            textAlign: TextAlign.center,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              final selectedWatchlist = controller.selectedWatchlist.value!;
              showDialog(
                context: Get.context!,
                barrierDismissible: true,
                builder: (context) => AddStocksModal(
                  watchlistName: selectedWatchlist.name,
                  watchlistId: selectedWatchlist.id,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 12,
                    color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ADD STOCKS',
                    style: DashboardTextStyles.columnHeader.copyWith(
                      color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksListState(WatchlistController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
          // Header with count and add button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STOCKS (${controller.stocksCount})',
                  style: DashboardTextStyles.columnHeader.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final selectedWatchlist = controller.selectedWatchlist.value!;
                    showDialog(
                      context: Get.context!,
                      barrierDismissible: true,
                      builder: (context) => AddStocksModal(
                        watchlistName: selectedWatchlist.name,
                        watchlistId: selectedWatchlist.id,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 10,
                          color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ADD',
                          style: DashboardTextStyles.columnHeader.copyWith(
                            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Dynamic table for stocks
          WatchlistStocksTable(
            stocks: controller.watchlistStocks,
            isLoading: false, // Already handled by parent
            errorMessage: null, // Already handled by parent
            isDarkMode: isDarkMode,
          ),
          
          // News section
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
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


  void _showCreateWatchlistDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CreateWatchlistDialog(isDarkMode: isDarkMode);
      },
    );
  }
}
