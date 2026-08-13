import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/portfolio_idea_screen.dart';
import 'package:musaffa_terminal/Screens/screener_screen.dart';
import 'package:musaffa_terminal/Screens/trading_ideas_screen.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class AppSidebarPanel extends StatefulWidget {
  const AppSidebarPanel({super.key});

  @override
  State<AppSidebarPanel> createState() => _AppSidebarPanelState();
}

class _AppSidebarPanelState extends State<AppSidebarPanel> {
  static const double _width = 288;

  Future<void> _confirmAndLogout(bool isDark) async {
    final sidebar = Get.find<GlobalSidebarService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          title: Text(
            'Sign out',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of Musaffa Terminal?',
            style: TextStyle(
              fontSize: 13,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: isDark ? const Color(0xFF81AACE) : const Color(0xFF2563EB),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign out',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && Get.isRegistered<AuthController>()) {
      sidebar.close();
      await Get.find<AuthController>().logout();
    }
  }

  void _goDashboard() {
    final sidebar = Get.find<GlobalSidebarService>();
    sidebar.setActive(SidebarNavItem.dashboard);
    sidebar.close();
    // Pop back to root MainScreen without rebuilding (avoids splash).
    if (Get.key.currentState?.canPop() == true) {
      Get.until((route) => route.isFirst);
    }
  }

  void _goScreener() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.screener) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.screener);
    sidebar.close();
    FeatureNavigation.toIfAllowed(
      FeatureKeys.screener,
      () => const ScreenerScreen(),
    );
  }

  void _goIdeas() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.ideas) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.ideas);
    sidebar.close();
    FeatureNavigation.toIfAllowed(
      FeatureKeys.tradingIdeas,
      () => const TradingIdeasScreen(),
    );
  }

  void _goPortfolio() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.portfolio) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.portfolio);
    sidebar.close();
    FeatureNavigation.toIfAllowed(
      FeatureKeys.portfolios,
      () => const PortfolioIdeaScreen(),
    );
  }

  void _showProfileSheet(bool isDark) {
    final sidebar = Get.find<GlobalSidebarService>();
    sidebar.setActive(SidebarNavItem.profile);
    sidebar.close();

    final auth = Get.find<AuthController>();
    final user = auth.user.value;
    final name = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : 'User';
    final email = user?.email ?? '';
    final status = user?.status ?? '';
    final initials = _initials(name, email);

    Future.delayed(const Duration(milliseconds: 240), () {
      Get.dialog(
        Dialog(
          backgroundColor: isDark ? const Color(0xFF151718) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        Get.back();
                        if (Get.isRegistered<GlobalSidebarService>()) {
                          // Restore selection to last main destination if possible
                          Get.find<GlobalSidebarService>()
                              .setActive(SidebarNavItem.dashboard);
                        }
                      },
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  _Avatar(initials: initials, size: 64, isDark: isDark),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F3A2E)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: isDark
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Get.back();
                        if (Get.isRegistered<GlobalSidebarService>()) {
                          Get.find<GlobalSidebarService>()
                              .setActive(SidebarNavItem.dashboard);
                        }
                      },
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF81AACE)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierColor: Colors.black.withOpacity(0.45),
      );
    });
  }

  String _initials(String name, String email) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.trim().isNotEmpty) {
      return name.trim().substring(0, 1).toUpperCase();
    }
    if (email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebar = Get.find<GlobalSidebarService>();
    final auth = Get.find<AuthController>();

    final bg = isDark ? const Color(0xFF121414) : const Color(0xFFFCFCFC);
    final border = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final muted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final text = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final accent = isDark ? const Color(0xFF81AACE) : const Color(0xFF2563EB);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: _width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          border: Border(right: BorderSide(color: border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 10, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Obx(() {
                        final user = auth.user.value;
                        final name = (user?.name.trim().isNotEmpty == true)
                            ? user!.name.trim()
                            : 'User';
                        final email = user?.email ?? '';
                        final profileSelected =
                            sidebar.activeItem.value == SidebarNavItem.profile;

                        return MouseRegion(
                          cursor: SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: () => _showProfileSheet(isDark),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  'resources/Small Logo.svg',
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: Constants.FONT_DEFAULT_NEW,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: profileSelected ? accent : text,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: Constants.FONT_DEFAULT_NEW,
                                      fontSize: 11,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    _IconHit(
                      isDark: isDark,
                      onTap: sidebar.close,
                      child: Icon(Icons.close_rounded, size: 18, color: muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Divider(height: 1, color: border),
              ),
              Expanded(
                child: Obx(() {
                  final active = sidebar.activeItem.value;
                  final canScreener =
                      FeatureNavigation.isEnabled(FeatureKeys.screener);
                  final canIdeas =
                      FeatureNavigation.isEnabled(FeatureKeys.tradingIdeas);
                  final canPortfolios =
                      FeatureNavigation.isEnabled(FeatureKeys.portfolios);
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _NavTile(
                        icon: CupertinoIcons.square_grid_2x2,
                        label: 'Dashboard',
                        selected: active == SidebarNavItem.dashboard,
                        isDark: isDark,
                        onTap: _goDashboard,
                      ),
                      if (canScreener)
                        _NavTile(
                          icon: CupertinoIcons.slider_horizontal_3,
                          label: 'Stock Screener',
                          selected: active == SidebarNavItem.screener,
                          isDark: isDark,
                          onTap: _goScreener,
                        ),
                      if (canIdeas)
                        _NavTile(
                          icon: CupertinoIcons.lightbulb,
                          label: 'Trading Ideas',
                          selected: active == SidebarNavItem.ideas,
                          isDark: isDark,
                          onTap: _goIdeas,
                        ),
                      if (canPortfolios)
                        _NavTile(
                          icon: CupertinoIcons.chart_pie,
                          label: 'Portfolios',
                          selected: active == SidebarNavItem.portfolio,
                          isDark: isDark,
                          onTap: _goPortfolio,
                        ),
                    ],
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: _LogoutTile(
                  isDark: isDark,
                  onTap: () => _confirmAndLogout(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool isDark;

  const _Avatar({
    required this.initials,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF111827);
    final muted = widget.isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? (widget.isDark
                      ? const Color(0xFF1C1F20)
                      : const Color(0xFFF3F4F6))
                  : (_hovering
                      ? (widget.isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.03))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.selected ? text : muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 13,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w400,
                      color: widget.selected ? text : muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _LogoutTile({required this.isDark, required this.onTap});

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final danger = const Color(0xFFDC2626);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering
                ? danger.withOpacity(widget.isDark ? 0.12 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 16, color: danger),
              const SizedBox(width: 12),
              Text(
                'Sign out',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconHit extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  final Widget child;

  const _IconHit({
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  State<_IconHit> createState() => _IconHitState();
}

class _IconHitState extends State<_IconHit> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering
                ? (widget.isDark
                    ? const Color(0xFF2A2F33)
                    : const Color(0xFFF3F4F6))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Menu button used in [HomeTabBar].
class SidebarMenuButton extends StatefulWidget {
  final bool isDarkMode;

  const SidebarMenuButton({super.key, required this.isDarkMode});

  @override
  State<SidebarMenuButton> createState() => _SidebarMenuButtonState();
}

class _SidebarMenuButtonState extends State<SidebarMenuButton>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onTap() {
    _pulse.reverse().then((_) => _pulse.forward());
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = Get.isRegistered<GlobalSidebarService>()
        ? Get.find<GlobalSidebarService>().isOpen
        : false.obs;

    return Obx(() {
      final isOpen = open.value;
      final accent = widget.isDarkMode
          ? const Color(0xFF81AACE)
          : const Color(0xFF2563EB);
      final idle = widget.isDarkMode
          ? const Color(0xFFE0E0E0)
          : const Color(0xFF374151);

      return ScaleTransition(
        scale: _pulse,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.basic,
          child: Tooltip(
            message: isOpen ? 'Close menu' : 'Open menu',
            child: GestureDetector(
              onTap: _onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isOpen || _hovering
                      ? (widget.isDarkMode
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF3F4F6))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOpen
                        ? accent.withOpacity(0.55)
                        : (widget.isDarkMode
                            ? const Color(0xFF404040)
                            : const Color(0xFFE5E7EB)),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    isOpen
                        ? CupertinoIcons.xmark
                        : CupertinoIcons.line_horizontal_3,
                    key: ValueKey(isOpen),
                    size: 17,
                    color: isOpen ? accent : idle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
