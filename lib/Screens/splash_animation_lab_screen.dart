import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Screens/widgets/splash_lab_animations.dart';
import 'package:musaffa_terminal/Screens/widgets/splash_lab_flagship_mini_previews.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Sidebar-linked page to preview premium Terminal splash animations.
class SplashAnimationLabScreen extends StatefulWidget {
  const SplashAnimationLabScreen({super.key});

  @override
  State<SplashAnimationLabScreen> createState() =>
      _SplashAnimationLabScreenState();
}

class _SplashAnimationLabScreenState extends State<SplashAnimationLabScreen> {
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();

  SplashLabStyle? _playing;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.splashLab);
    }
  }

  void _toggleWatchlist() {
    _watchlistService.toggleWatchlist();
  }

  void _play(SplashLabStyle style) {
    setState(() => _playing = style);
  }

  void _onFinished() {
    if (!mounted) return;
    setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = HomeUi.pageBg(isDark);

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Obx(
                  () => HomeTabBar(
                    showBackButton: true,
                    isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
                    onWatchlistToggle: _toggleWatchlist,
                    onThemeToggle: () {
                      final current = Theme.of(context).brightness;
                      Get.changeThemeMode(
                        current == Brightness.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final pad = HomeUi.pagePadding(constraints.maxWidth);
                      return ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          scrollbars: false,
                        ),
                        child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          pad.left,
                          20,
                          pad.right,
                          pad.bottom + 24,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Splash Animations',
                                style: TextStyle(
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: HomeUi.title(isDark),
                                ),
                              ),
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, c) {
                                  final cols = c.maxWidth >= 960
                                      ? 3
                                      : c.maxWidth >= 560
                                          ? 2
                                          : 1;
                                  final cards = [
                                    // Flagship premium set first
                                    _StyleCard(
                                      title: 'Tudum',
                                      subtitle:
                                          'Netflix-grade cinematic logo punch',
                                      accent: const Color(0xFFE50914),
                                      darkAccent: const Color(0xFF000000),
                                      isDark: isDark,
                                      preview: const MiniTudum(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.tudum),
                                    ),
                                    _StyleCard(
                                      title: 'Noir',
                                      subtitle:
                                          'Dark-grey BG iris-opens 0 → full screen',
                                      accent: const Color(0xFFE5E5E5),
                                      darkAccent: const Color(0xFF060608),
                                      isDark: isDark,
                                      preview: const MiniNoir(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.noir),
                                    ),
                                    _StyleCard(
                                      title: 'Mercury',
                                      subtitle:
                                          'Liquid metal bloom with dual sheen',
                                      accent: const Color(0xFFD4D4D8),
                                      darkAccent: const Color(0xFF09090B),
                                      isDark: isDark,
                                      preview: const MiniMercury(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.mercury),
                                    ),
                                    _StyleCard(
                                      title: 'Editorial',
                                      subtitle:
                                          'Magazine masthead assemble',
                                      accent: const Color(0xFFFAFAFA),
                                      darkAccent: const Color(0xFF0A0A0A),
                                      isDark: isDark,
                                      preview: const MiniEditorial(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.editorial),
                                    ),
                                    _StyleCard(
                                      title: 'Atelier',
                                      subtitle:
                                          'Luxury seal press — mark stamps into place',
                                      accent: const Color(0xFFF5F5F4),
                                      darkAccent: const Color(0xFF08070A),
                                      isDark: isDark,
                                      preview: const MiniAtelier(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.atelier),
                                    ),
                                    _StyleCard(
                                      title: 'Zenith',
                                      subtitle:
                                          'Swiss ultra-minimal institutional quiet',
                                      accent: const Color(0xFFFAFAFA),
                                      darkAccent: const Color(0xFF050505),
                                      isDark: isDark,
                                      preview: const MiniZenith(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.zenith),
                                    ),
                                    _StyleCard(
                                      title: 'Porcelain',
                                      subtitle:
                                          'Soft top-light product pedestal reveal',
                                      accent: const Color(0xFFE7E5E4),
                                      darkAccent: const Color(0xFF0A0A0C),
                                      isDark: isDark,
                                      preview: const MiniPorcelain(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.porcelain),
                                    ),
                                    _StyleCard(
                                      title: 'Signature',
                                      subtitle:
                                          'Cinematic 3s fintech logo opening',
                                      accent: const Color(0xFFFAFAFA),
                                      darkAccent: const Color(0xFF07070A),
                                      isDark: isDark,
                                      preview: const MiniSignature(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.signature),
                                    ),
                                    _StyleCard(
                                      title: 'Lumina',
                                      subtitle:
                                          'Apple-grade lens flare bloom reveal',
                                      accent: const Color(0xFFFAFAFA),
                                      darkAccent: const Color(0xFF060608),
                                      isDark: isDark,
                                      preview: const MiniLumina(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.lumina),
                                    ),
                                    _StyleCard(
                                      title: 'Ethereal',
                                      subtitle:
                                          'Mist clears, brand emerges in light',
                                      accent: const Color(0xFFE9D5FF),
                                      darkAccent: const Color(0xFF0A0A0E),
                                      isDark: isDark,
                                      preview: const MiniEthereal(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.ethereal),
                                    ),
                                    _StyleCard(
                                      title: 'Sovereign',
                                      subtitle:
                                          'Radial brand rays bloom from core',
                                      accent: const Color(0xFFE4621E),
                                      darkAccent: const Color(0xFF08060A),
                                      isDark: isDark,
                                      preview: const MiniSovereign(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.sovereign),
                                    ),
                                    _StyleCard(
                                      title: 'Velvet',
                                      subtitle:
                                          'Luxury curtains part to reveal',
                                      accent: const Color(0xFFD2364C),
                                      darkAccent: const Color(0xFF120A10),
                                      isDark: isDark,
                                      preview: const MiniVelvet(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.velvet),
                                    ),
                                    _StyleCard(
                                      title: 'Obsidian',
                                      subtitle:
                                          'Glossy dark plane + specular sweep',
                                      accent: const Color(0xFFA1A1AA),
                                      darkAccent: const Color(0xFF050506),
                                      isDark: isDark,
                                      preview: const MiniObsidian(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.obsidian),
                                    ),
                                    _StyleCard(
                                      title: 'Quantum',
                                      subtitle:
                                          'Particle field converges to core',
                                      accent: const Color(0xFF6366F1),
                                      darkAccent: const Color(0xFF050508),
                                      isDark: isDark,
                                      preview: const MiniQuantum(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.quantum),
                                    ),
                                    // Premium set
                                    _StyleCard(
                                      title: 'Beacon',
                                      subtitle:
                                          'Searchlight sweep locks onto brand',
                                      accent: const Color(0xFFE4621E),
                                      darkAccent: const Color(0xFF06060A),
                                      isDark: isDark,
                                      preview: const _MiniBeacon(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.beacon),
                                    ),
                                    _StyleCard(
                                      title: 'Ledger',
                                      subtitle:
                                          'Precision fintech rules draw in',
                                      accent: const Color(0xFFA1A1AA),
                                      darkAccent: const Color(0xFF08090C),
                                      isDark: isDark,
                                      preview: const _MiniLedger(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.ledger),
                                    ),
                                    _StyleCard(
                                      title: 'Nova',
                                      subtitle:
                                          'Soft brand wash rings bloom open',
                                      accent: const Color(0xFFD2364C),
                                      darkAccent: const Color(0xFF050508),
                                      isDark: isDark,
                                      preview: const _MiniNova(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.nova),
                                    ),
                                    _StyleCard(
                                      title: 'Parallax',
                                      subtitle:
                                          'Multi-layer depth drift settle',
                                      accent: const Color(0xFFA72669),
                                      darkAccent: const Color(0xFF07070B),
                                      isDark: isDark,
                                      preview: const _MiniParallax(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.parallax),
                                    ),
                                    _StyleCard(
                                      title: 'Signal',
                                      subtitle:
                                          'Acquisition scan locks brand core',
                                      accent: const Color(0xFF22C55E),
                                      darkAccent: const Color(0xFF05070A),
                                      isDark: isDark,
                                      preview: const _MiniSignal(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.signal),
                                    ),
                                    _StyleCard(
                                      title: 'Vault',
                                      subtitle:
                                          'Concentric frames dilate open',
                                      accent: const Color(0xFFF4F4F5),
                                      darkAccent: const Color(0xFF09090B),
                                      isDark: isDark,
                                      preview: const _MiniVault(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.vault),
                                    ),
                                    // Best / US-level first
                                    _StyleCard(
                                      title: 'Whisper',
                                      subtitle:
                                          'Ultra-soft blur dissolve + letter fade',
                                      accent: const Color(0xFFFAFAFA),
                                      darkAccent: const Color(0xFF09090B),
                                      isDark: isDark,
                                      preview: const _MiniWhisper(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.whisper),
                                    ),
                                    _StyleCard(
                                      title: 'Spring',
                                      subtitle:
                                          'iOS spring zoom with overshoot settle',
                                      accent: const Color(0xFFE4621E),
                                      darkAccent: const Color(0xFF08080A),
                                      isDark: isDark,
                                      preview: const _MiniSpring(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.springInertia),
                                    ),
                                    _StyleCard(
                                      title: 'Cinema',
                                      subtitle:
                                          'Letterbox bars + trailer-grade reveal',
                                      accent: const Color(0xFFE8E8E8),
                                      darkAccent: const Color(0xFF030303),
                                      isDark: isDark,
                                      preview: const _MiniCinema(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.cinema),
                                    ),
                                    _StyleCard(
                                      title: 'Magnetic',
                                      subtitle:
                                          'Floating orbs pull into brand core',
                                      accent: const Color(0xFFA5B4FC),
                                      darkAccent: const Color(0xFF07060C),
                                      isDark: isDark,
                                      preview: const _MiniMagnetic(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.magnetic),
                                    ),
                                    _StyleCard(
                                      title: 'Frost Clear',
                                      subtitle:
                                          'Frosted glass thaws into crisp mark',
                                      accent: const Color(0xFF93C5FD),
                                      darkAccent: const Color(0xFF0E1218),
                                      isDark: isDark,
                                      preview: const _MiniFrost(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.frostClear),
                                    ),
                                    _StyleCard(
                                      title: 'Cascade',
                                      subtitle:
                                          'Soft staggered blinds lift reveal',
                                      accent: const Color(0xFFA1A1AA),
                                      darkAccent: const Color(0xFF0A0A0E),
                                      isDark: isDark,
                                      preview: const _MiniCascade(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.cascade),
                                    ),
                                    _StyleCard(
                                      title: 'Mesh Glow',
                                      subtitle:
                                          'Stripe/Linear soft mesh morph',
                                      accent: const Color(0xFF6366F1),
                                      darkAccent: const Color(0xFF09090B),
                                      isDark: isDark,
                                      preview: const _MiniMesh(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.meshGlow),
                                    ),
                                    _StyleCard(
                                      title: 'Aperture',
                                      subtitle:
                                          'Camera iris open — Apple Camera grade',
                                      accent: const Color(0xFFA1A1AA),
                                      darkAccent: const Color(0xFF050505),
                                      isDark: isDark,
                                      preview: const _MiniAperture(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.aperture),
                                    ),
                                    _StyleCard(
                                      title: 'Monogram',
                                      subtitle:
                                          'T mark expands into TERMINAL',
                                      accent: const Color(0xFFF4F4F5),
                                      darkAccent: const Color(0xFF0A0A0C),
                                      isDark: isDark,
                                      preview: const _MiniMonogram(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.monogram),
                                    ),
                                    _StyleCard(
                                      title: 'Silk Wipe',
                                      subtitle:
                                          'Soft dual curtains + elegant settle',
                                      accent: const Color(0xFFD4A5C0),
                                      darkAccent: const Color(0xFF1A1424),
                                      isDark: isDark,
                                      preview: const _MiniSilk(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.silkWipe),
                                    ),
                                    _StyleCard(
                                      title: 'Mirror Drop',
                                      subtitle:
                                          'Soft bounce drop + floor reflection',
                                      accent: const Color(0xFFE4E4E7),
                                      darkAccent: const Color(0xFF07070A),
                                      isDark: isDark,
                                      preview: const _MiniMirror(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.mirrorDrop),
                                    ),
                                    _StyleCard(
                                      title: 'Prism',
                                      subtitle:
                                          'Chromatic refraction + spectral beams',
                                      accent: const Color(0xFFE4621E),
                                      darkAccent: const Color(0xFF12101C),
                                      isDark: isDark,
                                      preview: const _MiniPrism(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.prism),
                                    ),
                                    _StyleCard(
                                      title: 'Liquid Metal',
                                      subtitle:
                                          'Chrome morph blob → precision settle',
                                      accent: const Color(0xFFD4D4D8),
                                      darkAccent: const Color(0xFF0A0A0C),
                                      isDark: isDark,
                                      preview: const _MiniLiquid(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.liquidMetal),
                                    ),
                                    _StyleCard(
                                      title: 'Helix',
                                      subtitle:
                                          'Dual spiral ribbons coil into mark',
                                      accent: const Color(0xFFC4B5FD),
                                      darkAccent: const Color(0xFF12101C),
                                      isDark: isDark,
                                      preview: const _MiniHelix(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.helix),
                                    ),
                                    _StyleCard(
                                      title: 'Horizon',
                                      subtitle:
                                          'Dawn rise, sun bloom + shimmer line',
                                      accent: const Color(0xFFFFB36B),
                                      darkAccent: const Color(0xFF0A0814),
                                      isDark: isDark,
                                      preview: const _MiniHorizon(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.horizon),
                                    ),
                                    _StyleCard(
                                      title: 'Aurora',
                                      subtitle:
                                          'Northern-light ribbons over deep night',
                                      accent: const Color(0xFF2DD4BF),
                                      darkAccent: const Color(0xFF061018),
                                      isDark: isDark,
                                      preview: const _MiniAurora(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.aurora),
                                    ),
                                    _StyleCard(
                                      title: 'Constellation',
                                      subtitle:
                                          'Star network links into the brand',
                                      accent: const Color(0xFF818CF8),
                                      darkAccent: const Color(0xFF0F1224),
                                      isDark: isDark,
                                      preview: const _MiniConstellation(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.constellation),
                                    ),
                                    _StyleCard(
                                      title: 'Neon Trace',
                                      subtitle:
                                          'Glowing outline draw + cyber fill',
                                      accent: const Color(0xFF00F0FF),
                                      darkAccent: const Color(0xFF050508),
                                      isDark: isDark,
                                      preview: const _MiniNeon(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.neonTrace),
                                    ),
                                    _StyleCard(
                                      title: 'Particle Bloom',
                                      subtitle:
                                          'Burst particles coalesce into mark',
                                      accent: const Color(0xFFD2364C),
                                      darkAccent: const Color(0xFF1A0F18),
                                      isDark: isDark,
                                      preview: const _MiniBloom(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.particleBloom),
                                    ),
                                    _StyleCard(
                                      title: 'Ripple',
                                      subtitle:
                                          'Concentric sonic rings from the core',
                                      accent: const Color(0xFFE4621E),
                                      darkAccent: const Color(0xFF06060A),
                                      isDark: isDark,
                                      preview: const _MiniRipple(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.ripple),
                                    ),
                                    _StyleCard(
                                      title: 'Orbit',
                                      subtitle:
                                          'Path draw with traveling lead dot',
                                      accent: const Color(0xFF2F6B55),
                                      darkAccent: const Color(0xFF0E1F18),
                                      isDark: isDark,
                                      preview: const _MiniOrbit(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.orbit),
                                    ),
                                    _StyleCard(
                                      title: 'Circle Reveal',
                                      subtitle:
                                          'White flash → expanding void → mark',
                                      accent: const Color(0xFFE4621E),
                                      darkAccent: const Color(0xFF050505),
                                      isDark: isDark,
                                      preview: const _MiniCircle(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.circleReveal),
                                    ),
                                    _StyleCard(
                                      title: 'Sable',
                                      subtitle:
                                          'Letter reveal + black ↔ white invert',
                                      accent: const Color(0xFFE8E8E8),
                                      darkAccent: const Color(0xFF111111),
                                      isDark: isDark,
                                      preview: const _MiniSable(),
                                      onPlay: () =>
                                          _play(SplashLabStyle.sable),
                                    ),
                                  ];
                                  return Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    children: [
                                      for (final card in cards)
                                        SizedBox(
                                          width: cols == 1
                                              ? c.maxWidth
                                              : (c.maxWidth -
                                                      14 * (cols - 1)) /
                                                  cols,
                                          child: card,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_playing != null)
            Positioned.fill(
              child: SplashLabPlayer(
                key: ValueKey(_playing),
                style: _playing!,
                onFinished: _onFinished,
              ),
            ),
        ],
      ),
    );
  }
}

class _StyleCard extends StatefulWidget {
  const _StyleCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.darkAccent,
    required this.isDark,
    required this.preview,
    required this.onPlay,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Color darkAccent;
  final bool isDark;
  final Widget preview;
  final VoidCallback onPlay;

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: const Cubic(0.16, 1, 0.3, 1),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(
            color: _hover
                ? HomeUi.borderStrong(isDark)
                : HomeUi.borderLight(isDark),
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPlay,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.darkAccent,
                            Color.lerp(
                                  widget.darkAccent,
                                  widget.accent,
                                  0.35,
                                ) ??
                                widget.darkAccent,
                          ],
                        ),
                      ),
                      child: Center(child: widget.preview),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HomeUi.title(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12,
                      height: 1.4,
                      color: HomeUi.muted(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: _hover ? HomeUi.brandGradient : null,
                      color: _hover ? null : HomeUi.elevatedBg(isDark),
                      border: _hover
                          ? null
                          : Border.all(color: HomeUi.borderLight(isDark)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color:
                              _hover ? Colors.white : HomeUi.title(isDark),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Play animation',
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _hover ? Colors.white : HomeUi.title(isDark),
                          ),
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
    );
  }
}

class _MiniSable extends StatelessWidget {
  const _MiniSable();

  @override
  Widget build(BuildContext context) {
    return Text(
      'TERMINAL',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
    );
  }
}

class _MiniCircle extends StatelessWidget {
  const _MiniCircle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'resources/Small Logo.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Text(
          'Terminal',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
      ],
    );
  }
}

class _MiniOrbit extends StatelessWidget {
  const _MiniOrbit();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _MiniOrbitPainter(),
        child: Center(
          child: Image.asset(
            'resources/Small Logo.png',
            width: 28,
            height: 28,
          ),
        ),
      ),
    );
  }
}

class _MiniOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    const start = -1.2;
    const sweep = 4.8;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    final angle = start + sweep;
    canvas.drawCircle(
      Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle)),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniPrism extends StatelessWidget {
  const _MiniPrism();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFE4621E),
          Color(0xFFD2364C),
          Color(0xFFA72669),
          Color(0xFF6A2C72),
          Color(0xFF232C64),
        ],
      ).createShader(bounds),
      child: Text(
        'TERMINAL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
          fontFamily: Constants.FONT_DEFAULT_NEW,
        ),
      ),
    );
  }
}

class _MiniAurora extends StatelessWidget {
  const _MiniAurora();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2DD4BF),
                Color(0xFF6366F1),
                Color(0xFFA855F7),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'TERMINAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 5,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
      ],
    );
  }
}

class _MiniLiquid extends StatelessWidget {
  const _MiniLiquid();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [
            Color(0xFFF4F4F5),
            Color(0xFFA1A1AA),
            Color(0xFF3F3F46),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'resources/Small Logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _MiniConstellation extends StatelessWidget {
  const _MiniConstellation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 56,
      child: CustomPaint(
        painter: _MiniConstellationPainter(),
      ),
    );
  }
}

class _MiniConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      Offset(size.width * 0.15, size.height * 0.35),
      Offset(size.width * 0.4, size.height * 0.15),
      Offset(size.width * 0.7, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.55),
      Offset(size.width * 0.55, size.height * 0.75),
      Offset(size.width * 0.28, size.height * 0.7),
    ];
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(
        pts[i],
        pts[i + 1],
        Paint()
          ..color = const Color(0xFF818CF8).withValues(alpha: 0.7)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawLine(
      pts.first,
      pts.last,
      Paint()
        ..color = const Color(0xFFE4621E).withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniRipple extends StatelessWidget {
  const _MiniRipple();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(painter: _MiniRipplePainter()),
    );
  }
}

class _MiniRipplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        c,
        i * 10.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFE4621E).withValues(alpha: 1 - i * 0.22),
      );
    }
    canvas.drawCircle(c, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniNeon extends StatelessWidget {
  const _MiniNeon();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00F0FF), Color(0xFFFF2D95)],
      ).createShader(bounds),
      child: Text(
        'TERMINAL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          fontFamily: Constants.FONT_DEFAULT_NEW,
        ),
      ),
    );
  }
}

class _MiniBloom extends StatelessWidget {
  const _MiniBloom();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: CustomPaint(painter: _MiniBloomPainter()),
    );
  }
}

class _MiniBloomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const colors = [
      Color(0xFFE4621E),
      Color(0xFFD2364C),
      Color(0xFFA72669),
      Color(0xFF6A2C72),
    ];
    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2;
      final p = Offset(c.dx + math.cos(a) * 22, c.dy + math.sin(a) * 22);
      canvas.drawCircle(
        p,
        2.2,
        Paint()..color = colors[i % colors.length],
      );
    }
    canvas.drawCircle(c, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniHorizon extends StatelessWidget {
  const _MiniHorizon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TERMINAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 88,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFFE4621E),
                Color(0xFFFFB36B),
                Color(0xFFA72669),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniSilk extends StatelessWidget {
  const _MiniSilk();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF2A1E38), Color(0xFF1A1424)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'TERMINAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 18,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF2A1E38), Color(0xFF1A1424)],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniHelix extends StatelessWidget {
  const _MiniHelix();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 64,
      child: CustomPaint(painter: _MiniHelixPainter()),
    );
  }
}

class _MiniHelixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (final phase in [0.0, math.pi]) {
      final path = Path();
      for (var i = 0; i <= 40; i++) {
        final u = i / 40;
        final a = u * math.pi * 4 + phase;
        final y = c.dy - 28 + u * 56;
        final x = c.dx + math.sin(a) * 14;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = phase == 0
              ? const Color(0xFFE4621E)
              : const Color(0xFFC4B5FD)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniMirror extends StatelessWidget {
  const _MiniMirror();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'resources/Small Logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
        Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()..scaleByDouble(1.0, -1.0, 1.0, 1.0),
          child: Opacity(
            opacity: 0.28,
            child: Image.asset(
              'resources/Small Logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniWhisper extends StatelessWidget {
  const _MiniWhisper();

  @override
  Widget build(BuildContext context) {
    return Text(
      'TERMINAL',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.72),
        fontSize: 16,
        fontWeight: FontWeight.w300,
        letterSpacing: 6,
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
    );
  }
}

class _MiniAperture extends StatelessWidget {
  const _MiniAperture();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(painter: _MiniAperturePainter()),
    );
  }
}

class _MiniAperturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final hole = size.width * 0.22;
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: c, radius: size.width * 0.48))
      ..addOval(Rect.fromCircle(center: c, radius: hole));
    canvas.drawPath(mask, Paint()..color = const Color(0xFF2A2A32));
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * hole, c.dy + math.sin(a) * hole),
        Offset(c.dx + math.cos(a) * size.width * 0.42, c.dy + math.sin(a) * size.width * 0.42),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniMesh extends StatelessWidget {
  const _MiniMesh();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE4621E),
            Color(0xFFA72669),
            Color(0xFF6366F1),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'TERMINAL',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          fontFamily: Constants.FONT_DEFAULT_NEW,
        ),
      ),
    );
  }
}

class _MiniMonogram extends StatelessWidget {
  const _MiniMonogram();

  @override
  Widget build(BuildContext context) {
    return Text(
      'T',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.92),
        fontSize: 42,
        fontWeight: FontWeight.w200,
        height: 1,
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
    );
  }
}

class _MiniSpring extends StatelessWidget {
  const _MiniSpring();

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.15,
      child: Image.asset(
        'resources/Small Logo.png',
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _MiniCinema extends StatelessWidget {
  const _MiniCinema();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 8, width: 90, color: Colors.black),
        const SizedBox(height: 8),
        Text(
          'TERMINAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 8, width: 90, color: Colors.black),
      ],
    );
  }
}

class _MiniMagnetic extends StatelessWidget {
  const _MiniMagnetic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 56,
      child: CustomPaint(painter: _MiniMagneticPainter()),
    );
  }
}

class _MiniMagneticPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final pts = [
      Offset(8, 10),
      Offset(size.width - 8, 12),
      Offset(10, size.height - 10),
      Offset(size.width - 12, size.height - 8),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.45),
    ];
    for (final p in pts) {
      canvas.drawLine(
        p,
        c,
        Paint()
          ..color = const Color(0xFF6366F1).withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFFA5B4FC));
    }
    canvas.drawCircle(c, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniFrost extends StatelessWidget {
  const _MiniFrost();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        'TERMINAL',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w300,
          letterSpacing: 3,
          fontFamily: Constants.FONT_DEFAULT_NEW,
        ),
      ),
    );
  }
}

class _MiniCascade extends StatelessWidget {
  const _MiniCascade();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Container(
          width: 80,
          height: 6,
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: i.isEven ? const Color(0xFF2A2A32) : const Color(0xFF1C1C24),
        );
      }),
    );
  }
}

class _MiniBeacon extends StatelessWidget {
  const _MiniBeacon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(88, 48),
      painter: _MiniBeaconPainter(),
    );
  }
}

class _MiniBeaconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.55, 0)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.9, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x88E4621E), Color(0x00E4621E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.55),
      5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniLedger extends StatelessWidget {
  const _MiniLedger();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Container(
          width: 70.0 - i * 4,
          height: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 3),
          color: i == 2
              ? const Color(0xFFE4621E).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.25),
        );
      }),
    );
  }
}

class _MiniNova extends StatelessWidget {
  const _MiniNova();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(56, 56),
      painter: _MiniNovaPainter(),
    );
  }
}

class _MiniNovaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        c,
        8.0 * i,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Color.lerp(
            const Color(0xFFE4621E),
            const Color(0xFF232C64),
            i / 3,
          )!
              .withValues(alpha: 0.55),
      );
    }
    canvas.drawCircle(c, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniParallax extends StatelessWidget {
  const _MiniParallax();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: _orb(const Color(0xFFE4621E), 22),
          ),
          Positioned(
            right: 2,
            top: 10,
            child: _orb(const Color(0xFFA72669), 18),
          ),
          Positioned(
            left: 18,
            bottom: 2,
            child: _orb(const Color(0xFF232C64), 26),
          ),
          const Center(
            child: Icon(Icons.circle, size: 8, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _orb(Color c, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: 0.35),
        ),
      );
}

class _MiniSignal extends StatelessWidget {
  const _MiniSignal();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 48),
      painter: _MiniSignalPainter(),
    );
  }
}

class _MiniSignalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.55;
    canvas.drawLine(
      Offset(6, y),
      Offset(size.width - 6, y),
      Paint()
        ..color = const Color(0xFFE4621E)
        ..strokeWidth = 1.4,
    );
    final c = Offset(size.width / 2, size.height * 0.45);
    final p = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(c + const Offset(-12, -10), c + const Offset(-5, -10), p);
    canvas.drawLine(c + const Offset(-12, -10), c + const Offset(-12, -3), p);
    canvas.drawLine(c + const Offset(12, -10), c + const Offset(5, -10), p);
    canvas.drawLine(c + const Offset(12, -10), c + const Offset(12, -3), p);
    canvas.drawCircle(c, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniVault extends StatelessWidget {
  const _MiniVault();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 48),
      painter: _MiniVaultPainter(),
    );
  }
}

class _MiniVaultPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i <= 3; i++) {
      final rect = Rect.fromCenter(
        center: c,
        width: 18.0 * i,
        height: 12.0 * i,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(4.0 + i)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: 0.35 + i * 0.1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
