import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Screens/earnings_calendar_screen.dart';
import 'package:musaffa_terminal/Screens/economic_calendar_screen.dart';
import 'package:musaffa_terminal/Screens/portfolio_idea_screen.dart';
import 'package:musaffa_terminal/Screens/splash_animation_lab_screen.dart';
import 'package:musaffa_terminal/portfolio/screens/model_portfolios_screen.dart';
import 'package:musaffa_terminal/Screens/screener_screen.dart';
import 'package:musaffa_terminal/Screens/trading_ideas_screen.dart';
import 'package:musaffa_terminal/Screens/watchlist_screen.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/Components/sidebar_nav_icons.dart';
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
  static const double _width = 304;

  late final AnimationController _contentAnim;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _contentFade = CurvedAnimation(
      parent: _contentAnim,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _contentAnim.forward();
    });
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

  void _goModelPortfolios() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.modelPortfolio) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.modelPortfolio);
    sidebar.close();
    FeatureNavigation.toIfAllowed(
      FeatureKeys.portfolios,
      () => const ModelPortfoliosScreen(),
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

  void _goSplashLab() {
    final sidebar = Get.find<GlobalSidebarService>();
    if (sidebar.activeItem.value == SidebarNavItem.splashLab) {
      sidebar.close();
      return;
    }
    sidebar.setActive(SidebarNavItem.splashLab);
    sidebar.close();
    Get.to(() => const SplashAnimationLabScreen());
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
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        child: Container(
          width: _width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121417) : Colors.white,
            border: Border(
              right: BorderSide(
                color: isDark
                    ? const Color(0xFF2A2E34)
                    : const Color(0xFFE8EAED),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(
                  alpha: isDark ? 0.45 : 0.06,
                ),
                blurRadius: 28,
                offset: const Offset(8, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _contentFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                    child: _Reveal(
                      animation: _contentAnim,
                      index: 0,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: MusaffaLogo(height: 20),
                            ),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 14, 0),
                    child: _Reveal(
                      animation: _contentAnim,
                      index: 1,
                      child: Obx(() {
                        final user = auth.user.value;
                        final name = (user?.name.trim().isNotEmpty == true)
                            ? user!.name.trim()
                            : 'User';
                        final email = user?.email ?? '';
                        final profileSelected = sidebar.activeItem.value ==
                            SidebarNavItem.profile;
                        return _ProfileChip(
                          isDark: isDark,
                          name: name,
                          email: email,
                          initials: _initials(name, email),
                          selected: profileSelected,
                          onTap: () => _showProfileSheet(isDark),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: HomeUi.borderLight(isDark).withValues(alpha: 0.9),
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

                      var i = 2;
                      final children = <Widget>[];

                      void section(String label, List<Widget> tiles) {
                        if (tiles.isEmpty) return;
                        children.add(
                          _Reveal(
                            animation: _contentAnim,
                            index: i++,
                            child: _SectionLabel(
                              label: label,
                              isDark: isDark,
                            ),
                          ),
                        );
                        for (final tile in tiles) {
                          children.add(
                            _Reveal(
                              animation: _contentAnim,
                              index: i++,
                              child: tile,
                            ),
                          );
                        }
                      }

                      section('Workspace', [
                        _NavTile(
                          glyph: SidebarGlyph.dashboard,
                          label: 'Dashboard',
                          selected: active == SidebarNavItem.dashboard,
                          isDark: isDark,
                          onTap: _goDashboard,
                        ),
                        if (canScreener)
                          _NavTile(
                            glyph: SidebarGlyph.screener,
                            label: 'Stock Screener',
                            selected: active == SidebarNavItem.screener,
                            isDark: isDark,
                            onTap: _goScreener,
                          ),
                        if (canIdeas)
                          _NavTile(
                            glyph: SidebarGlyph.ideas,
                            label: 'Trading Ideas',
                            selected: active == SidebarNavItem.ideas,
                            isDark: isDark,
                            onTap: _goIdeas,
                          ),
                      ]);
                      section('Portfolios', [
                        if (canPortfolios)
                          _NavTile(
                            glyph: SidebarGlyph.portfolio,
                            label: 'Model Portfolios',
                            selected:
                                active == SidebarNavItem.modelPortfolio,
                            isDark: isDark,
                            onTap: _goModelPortfolios,
                          ),
                        if (canPortfolios)
                          _NavTile(
                            glyph: SidebarGlyph.assignments,
                            label: 'Assignments',
                            selected: active == SidebarNavItem.portfolio,
                            isDark: isDark,
                            onTap: _goPortfolio,
                          ),
                        if (canWatchlists)
                          _NavTile(
                            glyph: SidebarGlyph.watchlist,
                            label: 'Watchlist',
                            selected: active == SidebarNavItem.watchlist,
                            isDark: isDark,
                            onTap: _goWatchlist,
                          ),
                      ]);
                      section('Markets', [
                        _NavTile(
                          glyph: SidebarGlyph.earnings,
                          label: 'Earnings Calendar',
                          selected: active == SidebarNavItem.earnings,
                          isDark: isDark,
                          onTap: _goEarnings,
                        ),
                        _NavTile(
                          glyph: SidebarGlyph.economic,
                          label: 'Economic Calendar',
                          selected:
                              active == SidebarNavItem.economicCalendar,
                          isDark: isDark,
                          onTap: _goEconomicCalendar,
                        ),
                        _NavTile(
                          glyph: SidebarGlyph.splash,
                          label: 'Splash Animations',
                          selected: active == SidebarNavItem.splashLab,
                          isDark: isDark,
                          onTap: _goSplashLab,
                        ),
                      ]);

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 2, 12, 8),
                        physics: const BouncingScrollPhysics(),
                        children: children,
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: _Reveal(
                      animation: _contentAnim,
                      index: 14,
                      child: Column(
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: HomeUi.borderLight(isDark)
                                .withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 12),
                          _LogoutTile(
                            isDark: isDark,
                            onTap: () => _confirmAndLogout(isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = math.min(0.04 + index * 0.032, 0.55);
    final end = math.min(start + 0.42, 1.0);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.035, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontFamilyFallback: Constants.FONT_FALLBACK,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.85,
          height: 1,
          color: HomeUi.muted(isDark).withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatefulWidget {
  const _ProfileChip({
    required this.isDark,
    required this.name,
    required this.email,
    required this.initials,
    required this.selected,
    required this.onTap,
  });

  final bool isDark;
  final String name;
  final String email;
  final String initials;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<_ProfileChip> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
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
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.isDark
                  ? const Color(0xFF1A1D22)
                  : const Color(0xFFF3F3F3),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    _Avatar(
                      initials: widget.initials,
                      size: 38,
                      isDark: widget.isDark,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark
                                ? const Color(0xFF1A1D22)
                                : const Color(0xFFF7F8FA),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontFamilyFallback: Constants.FONT_FALLBACK,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.07,
                          color: HomeUi.title(widget.isDark),
                        ),
                      ),
                      if (widget.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontFamilyFallback: Constants.FONT_FALLBACK,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: HomeUi.muted(widget.isDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  offset: _hovering ? const Offset(0.1, 0) : Offset.zero,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: HomeUi.muted(widget.isDark).withValues(
                      alpha: _hovering ? 0.95 : 0.55,
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
    final fontSize = size * 0.34;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF252A32) : Colors.white,
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => HomeUi.iconFillGradient.createShader(
          // Full avatar bounds so the brand wash reads clearly on a single glyph.
          Rect.fromLTWH(0, 0, size, size),
        ),
        child: Text(
          initials,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontFamilyFallback: Constants.FONT_FALLBACK,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.08,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final SidebarGlyph glyph;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTile({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  bool _pressed = false;
  late final AnimationController _selectPulse;

  @override
  void initState() {
    super.initState();
    _selectPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _NavTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    if (widget.selected) {
      _selectPulse.forward(from: 0);
    } else {
      _selectPulse.reverse();
    }
  }

  @override
  void dispose() {
    _selectPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final showHover = _hovering && !selected;
    const idle = SidebarNavIcon.idleColor;
    final ink = SidebarNavIcon.hover(widget.isDark);
    final labelColor = showHover ? ink : idle;

    final baseStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontFamilyFallback: Constants.FONT_FALLBACK,
      fontSize: 13.25,
      letterSpacing: 0.07,
      height: 1.15,
      fontWeight: FontWeight.w500,
    );

    // Measure once so the brand gradient spans the glyph run (not a fixed box).
    // Using TextStyle.foreground (not ShaderMask) keeps Windows AA crisp.
    TextStyle labelStyle;
    if (selected) {
      final painter = TextPainter(
        text: TextSpan(text: widget.label, style: baseStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        ellipsis: '…',
      )..layout(maxWidth: 220);
      labelStyle = baseStyle.copyWith(
        foreground: Paint()
          ..isAntiAlias = true
          ..shader = HomeUi.iconFillGradient.createShader(
            Rect.fromLTWH(0, 0, painter.width.clamp(1, 220), painter.height),
          ),
      );
    } else {
      labelStyle = baseStyle.copyWith(color: labelColor);
    }

    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: labelStyle,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() {
          _hovering = false;
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
            scale: _pressed ? 0.985 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 46,
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: selected ? HomeUi.sidebarActiveBgGradient : null,
                color: selected
                    ? null
                    : (showHover
                        ? (widget.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF4F5F7))
                        : Colors.transparent),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _selectPulse,
                    builder: (context, child) {
                      final scale =
                          selected ? (0.90 + 0.10 * _selectPulse.value) : 1.0;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: SidebarNavIcon(
                      glyph: widget.glyph,
                      selected: selected,
                      size: 17,
                      // Selected → brand gradient via ShaderMask (no solid tint).
                      // Idle / hover → solid grey.
                      color: selected ? null : labelColor,
                      gradient: selected ? HomeUi.iconFillGradient : null,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: label),
                ],
              ),
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final danger = HomeUi.negative(widget.isDark);
    const idle = SidebarNavIcon.idleColor;
    final color = _hovering ? danger : idle;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
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
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 46,
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _hovering
                  ? danger.withValues(alpha: widget.isDark ? 0.12 : 0.06)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                SidebarNavIcon(
                  glyph: SidebarGlyph.logout,
                  selected: false,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Sign out',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontFamilyFallback: Constants.FONT_FALLBACK,
                      fontSize: 13.25,
                      letterSpacing: 0.07,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _hovering ? 1 : 0.35,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: color,
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
                ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF4F5F7))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
                decoration: HomeUi.headerControlDecoration(
                  widget.isDarkMode,
                  hover: _hovering,
                  active: isOpen,
                ),
                child: SidebarMenuGlyph(
                  open: isOpen,
                  active: isOpen || _hovering,
                  size: 17,
                  mutedColor: widget.isDarkMode
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF374151),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
