import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/app_sidebar.dart';

enum SidebarNavItem {
  dashboard,
  screener,
  ideas,
  portfolio,
  watchlist,
  earnings,
  economicCalendar,
  profile,
}

class GlobalSidebarService extends GetxController {
  final RxBool isOpen = false.obs;
  final Rx<SidebarNavItem> activeItem = SidebarNavItem.dashboard.obs;

  bool _opening = false;

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
    if (isOpen.value || _opening) return;
    _opening = true;
    isOpen.value = true;

    final isDark = Get.context != null &&
        Theme.of(Get.context!).brightness == Brightness.dark;

    try {
      await Get.generalDialog<void>(
        barrierLabel: 'Navigation sidebar',
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.52 : 0.28),
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: AppSidebarPanel(),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final slide = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final fade = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
            reverseCurve: const Interval(0.45, 1.0, curve: Curves.easeIn),
          );
          final scale = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.04, 0),
                end: Offset.zero,
              ).animate(slide),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(scale),
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
          );
        },
      );
    } finally {
      isOpen.value = false;
      _opening = false;
    }
  }

  void close() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    isOpen.value = false;
  }
}
