import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/app_sidebar.dart';

enum SidebarNavItem {
  dashboard,
  screener,
  ideas,
  modelPortfolio,
  portfolio,
  watchlist,
  earnings,
  economicCalendar,
  splashLab,
  profile,
}

class GlobalSidebarService extends GetxController {
  final RxBool isOpen = false.obs;
  final Rx<SidebarNavItem> activeItem = SidebarNavItem.dashboard.obs;

  bool _busy = false;

  /// Same soft settle curve for open and close so both feel identical.
  static const _motion = Cubic(0.16, 1, 0.3, 1);
  static const _duration = Duration(milliseconds: 450);

  void setActive(SidebarNavItem item) {
    activeItem.value = item;
  }

  void toggle() {
    if (isOpen.value) {
      close();
    } else {
      open();
    }
  }

  Future<void> open() async {
    if (isOpen.value || _busy) return;
    _busy = true;
    isOpen.value = true;

    final isDark = Get.context != null &&
        Theme.of(Get.context!).brightness == Brightness.dark;

    try {
      await Get.generalDialog<void>(
        barrierLabel: 'Navigation sidebar',
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: _duration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: AppSidebarPanel(),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          // Identical curve forward + reverse → open and close match.
          final motion = CurvedAnimation(
            parent: animation,
            curve: _motion,
            reverseCurve: _motion,
          );

          return AnimatedBuilder(
            animation: motion,
            builder: (context, _) {
              final t = motion.value.clamp(0.0, 1.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: close,
                    behavior: HitTestBehavior.opaque,
                    child: Opacity(
                      opacity: t,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 4 * t,
                          sigmaY: 4 * t,
                        ),
                        child: ColoredBox(
                          color: Colors.black.withValues(
                            alpha: (isDark ? 0.38 : 0.14) * t,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0),
                      end: Offset.zero,
                    ).animate(motion),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Only clear after reverse transition fully finishes.
      isOpen.value = false;
      _busy = false;
    }
  }

  void close() {
    if (!isOpen.value && !_busy) return;
    // Keep isOpen true while closing so UI stays in sync during slide-out.
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
