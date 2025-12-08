import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/floating_action_buttons_controller.dart';
import 'package:musaffa_terminal/Components/floating_action_button_widget.dart';

class GlobalFABOverlay extends StatelessWidget {
  const GlobalFABOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<FloatingActionButtonsController>();
    
    return Obx(() => Stack(
      children: [
        // All floating action buttons
        ...controller.fabs.map((fab) => FloatingActionButtonWidget(
          item: fab,
          isDarkMode: isDarkMode,
        )).toList(),
      ],
    ));
  }
}

