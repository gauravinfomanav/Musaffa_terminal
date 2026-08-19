import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/floating_action_buttons_controller.dart';
import 'package:musaffa_terminal/Screens/screener_screen.dart';
import 'package:musaffa_terminal/Screens/trading_ideas_screen.dart';
import 'package:musaffa_terminal/Screens/portfolio_idea_screen.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class FloatingActionButtonWidget extends StatelessWidget {
  final FloatingActionButtonItem item;
  final bool isDarkMode;

  const FloatingActionButtonWidget({
    Key? key,
    required this.item,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FloatingActionButtonsController>();
    
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: Draggable<FABType>(
        data: item.type,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(28),
          child: _buildFABContent(isDragging: true),
        ),
        onDragEnd: (details) {
          // Only allow dropping on tabbar - if not dropped there, do nothing
          // Position stays the same (bottom-right)
        },
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildFABContent(),
        ),
        child: GestureDetector(
          onLongPress: () {
            _showRemoveDialog(context, controller);
          },
          child: _buildFABContent(),
        ),
      ),
    );
  }

  Widget _buildFABContent({bool isDragging = false}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _handleTap(),
          child: Center(
            child: _buildIcon(),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconColor = isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF1E40AF);

    switch (item.type) {
      case FABType.screener:
        return HomeUi.vectorIcon(
          icon: Icons.tune_rounded,
          size: HomeUi.iconXl,
          color: iconColor,
        );
      case FABType.ideas:
        return HomeUi.vectorIcon(
          icon: Icons.lightbulb,
          size: HomeUi.iconXl,
          color: isDarkMode ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
        );
      case FABType.portfolio:
        return HomeUi.vectorIcon(
          icon: Icons.pie_chart,
          size: HomeUi.iconXl,
          color: iconColor,
        );
      case FABType.watchlist:
        return HomeUi.vectorIcon(
          icon: Icons.bookmark,
          size: HomeUi.iconXl,
          color: iconColor,
        );
    }
  }

  void _handleTap() {
    switch (item.type) {
      case FABType.screener:
        FeatureNavigation.toIfAllowed(
          FeatureKeys.screener,
          () => const ScreenerScreen(),
        );
        break;
      case FABType.ideas:
        FeatureNavigation.toIfAllowed(
          FeatureKeys.tradingIdeas,
          () => const TradingIdeasScreen(),
        );
        break;
      case FABType.portfolio:
        FeatureNavigation.toIfAllowed(
          FeatureKeys.portfolios,
          () => const PortfolioIdeaScreen(),
        );
        break;
      case FABType.watchlist:
        if (!FeatureNavigation.isEnabled(FeatureKeys.watchlists)) return;
        // Toggle watchlist using global service
        final watchlistService = Get.find<GlobalWatchlistService>();
        final watchlistController = Get.find<WatchlistController>();
        watchlistController.resetToDefaultWatchlist();
        watchlistService.toggleWatchlist();
        break;
    }
  }

  void _showRemoveDialog(BuildContext context, FloatingActionButtonsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'Remove Shortcut?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        content: Text(
          'This will remove the floating action button from your screen.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.removeFAB(item.id);
              Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

