import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/app_sidebar.dart';

enum SidebarNavItem {
  dashboard,
  screener,
  ideas,
  portfolio,
  earnings,
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

    try {
      await Get.generalDialog<void>(
        barrierLabel: 'Navigation sidebar',
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.4),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: AppSidebarPanel(),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
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
