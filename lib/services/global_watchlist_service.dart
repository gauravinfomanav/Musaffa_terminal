import 'package:get/get.dart';
import 'package:musaffa_terminal/Screens/watchlist_screen.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';

/// Opens the full-page Watchlist screen (replaces the old slide-over panel).
class GlobalWatchlistService extends GetxController {
  /// Legacy flag kept so existing callers compile; overlays should stay closed.
  final RxBool isWatchlistOpen = false.obs;

  void toggleWatchlist() {
    if (_isOnWatchlistPage()) {
      return;
    }
    openWatchlist();
  }

  void openWatchlist() {
    isWatchlistOpen.value = false;

    if (Get.isRegistered<WatchlistController>()) {
      Get.find<WatchlistController>().resetToDefaultWatchlist();
    }

    if (Get.isRegistered<GlobalSidebarService>()) {
      final GlobalSidebarService sidebar = Get.find<GlobalSidebarService>();
      if (sidebar.activeItem.value == SidebarNavItem.watchlist) {
        sidebar.close();
        return;
      }
      sidebar.setActive(SidebarNavItem.watchlist);
      sidebar.close();
    }

    FeatureNavigation.toIfAllowed(
      FeatureKeys.watchlists,
      () => const WatchlistScreen(),
    );
  }

  void closeWatchlist() {
    isWatchlistOpen.value = false;
  }

  bool _isOnWatchlistPage() {
    if (!Get.isRegistered<GlobalSidebarService>()) return false;
    return Get.find<GlobalSidebarService>().activeItem.value ==
        SidebarNavItem.watchlist;
  }
}
