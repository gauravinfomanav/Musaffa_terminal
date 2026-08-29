import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/earnings_calendar_screen.dart';
import 'package:musaffa_terminal/Screens/economic_calendar_screen.dart';
import 'package:musaffa_terminal/Screens/portfolio_idea_screen.dart';
import 'package:musaffa_terminal/Screens/screener_screen.dart';
import 'package:musaffa_terminal/Screens/trading_ideas_screen.dart';
import 'package:musaffa_terminal/Screens/watchlist_screen.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class AppSidebarPanel extends StatefulWidget {
  const AppSidebarPanel({super.key});

  @override
  State<AppSidebarPanel> createState() => _AppSidebarPanelState();
}

class _AppSidebarPanelState extends State<AppSidebarPanel>
    with SingleTickerProviderStateMixin {
  static const double _width = 300;

  late final AnimationController _contentAnim;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _contentFade = CurvedAnimation(
      parent: _contentAnim,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(-0.04, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnim,
        curve: const Interval(0.12, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _contentAnim.forward();
  }

  @override
  void dispose() {
    _contentAnim.dispose();
    super.dispose();
  }

  Future<void> _confirmAndLogout(bool isDark) async {
    final sidebar = Get.find<GlobalSidebarService>();
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sign out',
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.55 : 0.32),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: _SignOutConfirmDialog(
            isDark: isDark,
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          ),
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

  void _goWatchlist() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.watchlist) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.watchlist);
    sidebar.close();
    FeatureNavigation.toIfAllowed(
      FeatureKeys.watchlists,
      () => const WatchlistScreen(),
    );
  }

  void _goEarnings() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.earnings) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.earnings);
    sidebar.close();
    Get.to(() => const EarningsCalendarScreen());
  }

  void _goEconomicCalendar() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.economicCalendar) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.economicCalendar);
    sidebar.close();
    Get.to(() => const EconomicCalendarScreen());
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
      Get.generalDialog<void>(
        barrierLabel: 'Profile',
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.55 : 0.32),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Center(
            child: _ProfileCard(
              isDark: isDark,
              name: name,
              email: email,
              status: status,
              initials: initials,
              onClose: () {
                Get.back();
                if (Get.isRegistered<GlobalSidebarService>()) {
                  Get.find<GlobalSidebarService>()
                      .setActive(SidebarNavItem.dashboard);
                }
              },
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    });
  }

  String _initials(String name, String email) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
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

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: _width,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xF2161A21),
                        Color(0xF01C2129),
                      ]
                    : const [
                        Color(0xFFF8FAFC),
                        Color(0xFFFFFFFF),
                      ],
              ),
              border: Border(
                right: BorderSide(color: HomeUi.borderLight(isDark)),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(
                    alpha: isDark ? 0.55 : 0.14,
                  ),
                  blurRadius: 36,
                  offset: const Offset(12, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 12, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Obx(() {
                                final user = auth.user.value;
                                final name =
                                    (user?.name.trim().isNotEmpty == true)
                                        ? user!.name.trim()
                                        : 'User';
                                final email = user?.email ?? '';
                                final profileSelected =
                                    sidebar.activeItem.value ==
                                        SidebarNavItem.profile;
                                final initials = _initials(name, email);

                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _showProfileSheet(isDark),
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const MusaffaLogo(height: 22),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            _Avatar(
                                              initials: initials,
                                              size: 36,
                                              isDark: isDark,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: HomeUi.sectionTitle(
                                                      isDark,
                                                    ).copyWith(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: profileSelected
                                                          ? const Color(
                                                              0xFFE4621E)
                                                          : HomeUi.title(
                                                              isDark),
                                                    ),
                                                  ),
                                                  if (email.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      email,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: HomeUi.subtitle(
                                                        isDark,
                                                      ).copyWith(fontSize: 11),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                            _IconHit(
                              isDark: isDark,
                              onTap: sidebar.close,
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: HomeUi.muted(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                        child: Divider(
                          height: 1,
                          color: HomeUi.borderLight(isDark),
                        ),
                      ),
                      Expanded(
                        child: Obx(() {
                          final active = sidebar.activeItem.value;
                          final canScreener = FeatureNavigation.isEnabled(
                            FeatureKeys.screener,
                          );
                          final canIdeas = FeatureNavigation.isEnabled(
                            FeatureKeys.tradingIdeas,
                          );
                          final canPortfolios = FeatureNavigation.isEnabled(
                            FeatureKeys.portfolios,
                          );
                          final canWatchlists = FeatureNavigation.isEnabled(
                            FeatureKeys.watchlists,
                          );
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                            children: [
                              _NavTile(
                                icon: CupertinoIcons.square_grid_2x2,
                                label: 'Dashboard',
                                selected:
                                    active == SidebarNavItem.dashboard,
                                isDark: isDark,
                                onTap: _goDashboard,
                              ),
                              if (canScreener)
                                _NavTile(
                                  icon: CupertinoIcons.slider_horizontal_3,
                                  label: 'Stock Screener',
                                  selected:
                                      active == SidebarNavItem.screener,
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
                                  selected:
                                      active == SidebarNavItem.portfolio,
                                  isDark: isDark,
                                  onTap: _goPortfolio,
                                ),
                              if (canWatchlists)
                                _NavTile(
                                  icon: CupertinoIcons.bookmark,
                                  label: 'Watchlist',
                                  selected:
                                      active == SidebarNavItem.watchlist,
                                  isDark: isDark,
                                  onTap: _goWatchlist,
                                ),
                              _NavTile(
                                icon: CupertinoIcons.calendar,
                                label: 'Earnings Calendar',
                                selected:
                                    active == SidebarNavItem.earnings,
                                isDark: isDark,
                                onTap: _goEarnings,
                              ),
                              _NavTile(
                                icon: CupertinoIcons.globe,
                                label: 'Economic Calendar',
                                selected: active ==
                                    SidebarNavItem.economicCalendar,
                                isDark: isDark,
                                onTap: _goEconomicCalendar,
                              ),
                            ],
                          );
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                        child: Column(
                          children: [
                            Divider(
                              height: 1,
                              color: HomeUi.borderLight(isDark),
                            ),
                            const SizedBox(height: 10),
                            _LogoutTile(
                              isDark: isDark,
                              onTap: () => _confirmAndLogout(isDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOutConfirmDialog extends StatelessWidget {
  const _SignOutConfirmDialog({
    required this.isDark,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: HomeUi.cardBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(color: HomeUi.borderLight(isDark)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(
                  alpha: isDark ? 0.48 : 0.14,
                ),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE4621E).withValues(alpha: 0.14),
                          const Color(0xFF88123E).withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: HomeUi.buttonBorder.withValues(alpha: 0.55),
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Color(0xFFE4621E),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign out',
                          style: HomeUi.sectionTitle(isDark).copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Are you sure you want to sign out of ${Constants.appName}?',
                          style: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: HomeUi.ghostAction(
                      label: 'Cancel',
                      dark: isDark,
                      onTap: onCancel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DestructiveAction(
                      label: 'Sign out',
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestructiveAction extends StatefulWidget {
  const _DestructiveAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_DestructiveAction> createState() => _DestructiveActionState();
}

class _DestructiveActionState extends State<_DestructiveAction> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : (_hover ? 1.02 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: HomeUi.controlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: HomeUi.iconFillGradient,
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              border: Border.all(color: HomeUi.buttonBorder, width: 0.856),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE4621E).withValues(
                    alpha: _hover ? 0.34 : 0.18,
                  ),
                  blurRadius: _hover ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: HomeUi.primaryActionLabel(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.isDark,
    required this.name,
    required this.email,
    required this.status,
    required this.initials,
    required this.onClose,
  });

  final bool isDark;
  final String name;
  final String email;
  final String status;
  final String initials;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(24, 18, 16, 20),
          decoration: BoxDecoration(
            color: HomeUi.cardBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(color: HomeUi.borderLight(isDark)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(
                  alpha: isDark ? 0.48 : 0.14,
                ),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _IconHit(
                  isDark: isDark,
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: HomeUi.muted(isDark),
                  ),
                ),
              ),
              _Avatar(initials: initials, size: 64, isDark: isDark),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 13),
              ),
              if (status.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: HomeUi.positiveSoft(isDark),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: HomeUi.positive(isDark),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: HomeUi.ghostAction(
                  label: 'Close',
                  dark: isDark,
                  onTap: onClose,
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
        gradient: HomeUi.iconWellGradient,
        border: Border.all(color: HomeUi.iconWellBorder),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: HomeUi.title(isDark),
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
    final selected = widget.selected;
    final showHover = _hovering && !selected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: BoxDecoration(
              color: selected
                  ? HomeUi.elevatedBg(widget.isDark)
                  : (showHover
                      ? HomeUi.elevatedBg(widget.isDark).withValues(
                          alpha: widget.isDark ? 0.55 : 0.7,
                        )
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? HomeUi.borderStrong(widget.isDark)
                    : (showHover
                        ? HomeUi.borderLight(widget.isDark)
                        : Colors.transparent),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(
                          alpha: widget.isDark ? 0.22 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: selected ? HomeUi.iconFillGradient : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: HomeUi.iconWellGradient,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HomeUi.iconWellBorder),
                  ),
                  child: HomeUi.brandIcon(
                    icon: widget.icon,
                    size: 14,
                    gradient: selected
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFE4621E),
                              Color(0xFFD2364C),
                            ],
                          )
                        : HomeUi.quietIconGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: HomeUi.control(
                      widget.isDark,
                      active: selected || showHover,
                    ).copyWith(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? HomeUi.title(widget.isDark)
                          : HomeUi.muted(widget.isDark),
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
    final danger = HomeUi.negative(widget.isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _hovering ? HomeUi.negativeSoft(widget.isDark) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hovering
                  ? danger.withValues(alpha: 0.28)
                  : HomeUi.borderLight(widget.isDark),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeUi.negativeSoft(widget.isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: danger.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(Icons.logout_rounded, size: 15, color: danger),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign out',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering
                ? HomeUi.elevatedBg(widget.isDark)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovering
                  ? HomeUi.borderStrong(widget.isDark)
                  : Colors.transparent,
            ),
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
      final idle = widget.isDarkMode
          ? const Color(0xFFE0E0E0)
          : const Color(0xFF374151);

      return ScaleTransition(
        scale: _pulse,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: isOpen ? 'Close menu' : 'Open menu',
            child: GestureDetector(
              onTap: _onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: HomeUi.controlHeight,
                height: HomeUi.controlHeight,
                decoration: BoxDecoration(
                  gradient: isOpen || _hovering
                      ? HomeUi.iconFillGradient
                      : HomeUi.iconWellGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOpen
                        ? HomeUi.buttonBorder
                        : (_hovering
                            ? HomeUi.borderStrong(widget.isDarkMode)
                            : HomeUi.iconWellBorder),
                    width: 0.9,
                  ),
                  boxShadow: isOpen || _hovering
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: widget.isDarkMode ? 0.22 : 0.08,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : const [],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    isOpen
                        ? CupertinoIcons.xmark
                        : CupertinoIcons.line_horizontal_3,
                    key: ValueKey(isOpen),
                    size: 17,
                    color: isOpen || _hovering ? Colors.white : idle,
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
