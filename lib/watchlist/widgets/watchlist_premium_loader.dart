import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/premium_finance_loader.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';

/// Full-screen entry loader for the Watchlist page.
class WatchlistPremiumLoader extends StatelessWidget {
  const WatchlistPremiumLoader({
    super.key,
    this.onExitStart,
    this.onFinished,
  });

  final VoidCallback? onExitStart;
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    final controller = WatchlistController.ensureRegistered();

    return Obx(() {
      final loading = controller.isLoading.value ||
          controller.isLoadingStocks.value ||
          controller.isLoadingPreferences.value;

      return PremiumFinanceLoader(
        fullScreen: true,
        waitForData: true,
        isLoading: loading,
        duration: const Duration(milliseconds: 2400),
        statusLabel: 'Preparing your experience',
        onExitStart: onExitStart,
        onFinished: onFinished,
      );
    });
  }
}
