import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/floating_action_buttons_controller.dart';
import 'package:musaffa_terminal/Components/floating_action_button_widget.dart';
import 'package:musaffa_terminal/Components/notes_fab.dart';
import 'package:musaffa_terminal/Components/notes_panel.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class GlobalFABOverlay extends StatelessWidget {
  const GlobalFABOverlay({Key? key}) : super(key: key);

  bool _fabAllowed(FABType type) {
    switch (type) {
      case FABType.screener:
        return FeatureNavigation.isEnabled(FeatureKeys.screener);
      case FABType.ideas:
        return FeatureNavigation.isEnabled(FeatureKeys.tradingIdeas);
      case FABType.portfolio:
        return FeatureNavigation.isEnabled(FeatureKeys.portfolios);
      case FABType.watchlist:
        return FeatureNavigation.isEnabled(FeatureKeys.watchlists);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<FloatingActionButtonsController>();
    
    return Stack(
      children: [
        // All floating action buttons
        Obx(() => Stack(
          children: controller.fabs
              .where((fab) => _fabAllowed(fab.type))
              .map((fab) => FloatingActionButtonWidget(
                    item: fab,
                    isDarkMode: isDarkMode,
                  ))
              .toList(),
        )),
        // Notes FAB (always visible, left bottom)
        const NotesFAB(),
        // Notes Panel
        const NotesPanel(),
      ],
    );
  }
}

