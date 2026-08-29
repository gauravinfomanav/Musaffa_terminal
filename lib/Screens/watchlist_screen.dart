import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';

/// Full-page Watchlist — hosts the existing watchlist UI as a dedicated screen
/// (replacing the slide-over sidebar panel). Redesign builds on top of this.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<WatchlistController>()) {
      Get.put(WatchlistController());
    }
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.watchlist);
    }
  }

  void _toggleWatchlist() => _watchlistService.toggleWatchlist();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = HomeUi.pageBg(isDark);

    return FeatureGuard(
      featureKey: FeatureKeys.watchlists,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeTabBar(
              showBackButton: true,
              onWatchlistToggle: _toggleWatchlist,
              isWatchlistOpen: true,
              onThemeToggle: () {
                final Brightness current = Theme.of(context).brightness;
                Get.changeThemeMode(
                  current == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
              },
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final EdgeInsets pagePad =
                      HomeUi.pagePadding(constraints.maxWidth);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      pagePad.left,
                      12,
                      pagePad.right,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Watchlist', style: HomeUi.heading(isDark)),
                        const SizedBox(height: 4),
                        Text(
                          'Track your lists, targets, and market moves in one place.',
                          style: HomeUi.subtitle(isDark),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: WatchlistDropdown(isDarkMode: isDark),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
