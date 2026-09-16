import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/flower_logo_cache.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

part 'splash_lab_flagship_animations.dart';
part 'splash_lab_reveals.dart';

enum SplashLabStyle {
  // Flagship premium set
  tudum,
  noir,
  mercury,
  editorial,
  atelier,
  zenith,
  porcelain,
  signature,
  ethereal,
  obsidian,
  sovereign,
  velvet,
  quantum,
  lumina,
  // Premium set
  beacon,
  ledger,
  nova,
  parallax,
  signal,
  vault,
  // Existing catalog
  sable,
  circleReveal,
  orbit,
  prism,
  aurora,
  liquidMetal,
  constellation,
  ripple,
  neonTrace,
  particleBloom,
  horizon,
  silkWipe,
  helix,
  mirrorDrop,
  whisper,
  aperture,
  meshGlow,
  monogram,
  springInertia,
  cinema,
  magnetic,
  frostClear,
  cascade,
}

/// Full-screen premium splash preview - Terminal logo, forty-two motion styles.
class SplashLabPlayer extends StatefulWidget {
  const SplashLabPlayer({
    super.key,
    required this.style,
    required this.onFinished,
  });

  final SplashLabStyle style;
  final VoidCallback onFinished;

  @override
  State<SplashLabPlayer> createState() => _SplashLabPlayerState();
}

class _SplashLabPlayerState extends State<SplashLabPlayer>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  bool _done = false;

  Duration get _duration {
    switch (widget.style) {
      case SplashLabStyle.tudum:
        return const Duration(milliseconds: 3800);
      case SplashLabStyle.noir:
        return const Duration(milliseconds: 3400);
      case SplashLabStyle.mercury:
        return const Duration(milliseconds: 4000);
      case SplashLabStyle.editorial:
        return const Duration(milliseconds: 3300);
      case SplashLabStyle.atelier:
        return const Duration(milliseconds: 3400);
      case SplashLabStyle.zenith:
        return const Duration(milliseconds: 3000);
      case SplashLabStyle.porcelain:
        return const Duration(milliseconds: 3600);
      case SplashLabStyle.signature:
        return const Duration(milliseconds: 3200);
      case SplashLabStyle.ethereal:
        return const Duration(milliseconds: 5600);
      case SplashLabStyle.obsidian:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.sovereign:
        return const Duration(milliseconds: 5800);
      case SplashLabStyle.velvet:
        return const Duration(milliseconds: 5600);
      case SplashLabStyle.quantum:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.lumina:
        return const Duration(milliseconds: 5600);
      case SplashLabStyle.beacon:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.ledger:
        return const Duration(milliseconds: 5200);
      case SplashLabStyle.nova:
        return const Duration(milliseconds: 5600);
      case SplashLabStyle.parallax:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.signal:
        return const Duration(milliseconds: 5200);
      case SplashLabStyle.vault:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.sable:
        return const Duration(milliseconds: 4400);
      case SplashLabStyle.circleReveal:
        return const Duration(milliseconds: 4200);
      case SplashLabStyle.orbit:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.prism:
        return const Duration(milliseconds: 5000);
      case SplashLabStyle.aurora:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.liquidMetal:
        return const Duration(milliseconds: 5000);
      case SplashLabStyle.constellation:
        return const Duration(milliseconds: 5800);
      case SplashLabStyle.ripple:
        return const Duration(milliseconds: 5000);
      case SplashLabStyle.neonTrace:
        return const Duration(milliseconds: 5200);
      case SplashLabStyle.particleBloom:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.horizon:
        return const Duration(milliseconds: 5600);
      case SplashLabStyle.silkWipe:
        return const Duration(milliseconds: 5200);
      case SplashLabStyle.helix:
        return const Duration(milliseconds: 5600);
      case SplashLabStyle.mirrorDrop:
        return const Duration(milliseconds: 5000);
      case SplashLabStyle.whisper:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.aperture:
        return const Duration(milliseconds: 5000);
      case SplashLabStyle.meshGlow:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.monogram:
        return const Duration(milliseconds: 5200);
      case SplashLabStyle.springInertia:
        return const Duration(milliseconds: 4800);
      case SplashLabStyle.cinema:
        return const Duration(milliseconds: 5200);
      case SplashLabStyle.magnetic:
        return const Duration(milliseconds: 5400);
      case SplashLabStyle.frostClear:
        return const Duration(milliseconds: 5000);
      case SplashLabStyle.cascade:
        return const Duration(milliseconds: 5000);
    }
  }

  @override
  void initState() {
    super.initState();
    _master = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
    FlowerLogoImageCache.warmUp(256);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _master,
              builder: (context, _) {
                final t = _master.value;
                final Widget splash;
                switch (widget.style) {
                  case SplashLabStyle.tudum:
                    splash = _TudumSplash(t: t);
                  case SplashLabStyle.noir:
                    splash = _NoirSplash(t: t);
                  case SplashLabStyle.mercury:
                    splash = _MercurySplash(t: t);
                  case SplashLabStyle.editorial:
                    splash = _EditorialSplash(t: t);
                  case SplashLabStyle.atelier:
                    splash = _AtelierSplash(t: t);
                  case SplashLabStyle.zenith:
                    splash = _ZenithSplash(t: t);
                  case SplashLabStyle.porcelain:
                    splash = _PorcelainSplash(t: t);
                  case SplashLabStyle.signature:
                    splash = _SignatureSplash(t: t);
                  case SplashLabStyle.ethereal:
                    splash = _EtherealSplash(t: t);
                  case SplashLabStyle.obsidian:
                    splash = _ObsidianSplash(t: t);
                  case SplashLabStyle.sovereign:
                    splash = _SovereignSplash(t: t);
                  case SplashLabStyle.velvet:
                    splash = _VelvetSplash(t: t);
                  case SplashLabStyle.quantum:
                    splash = _QuantumSplash(t: t);
                  case SplashLabStyle.lumina:
                    splash = _LuminaSplash(t: t);
                  case SplashLabStyle.beacon:
                    splash = _BeaconSplash(t: t);
                  case SplashLabStyle.ledger:
                    splash = _LedgerSplash(t: t);
                  case SplashLabStyle.nova:
                    splash = _NovaSplash(t: t);
                  case SplashLabStyle.parallax:
                    splash = _ParallaxSplash(t: t);
                  case SplashLabStyle.signal:
                    splash = _SignalSplash(t: t);
                  case SplashLabStyle.vault:
                    splash = _VaultSplash(t: t);
                  case SplashLabStyle.sable:
                    splash = _SableSplash(t: t);
                  case SplashLabStyle.circleReveal:
                    splash = _CircleRevealSplash(t: t);
                  case SplashLabStyle.orbit:
                    splash = _OrbitSplash(t: t);
                  case SplashLabStyle.prism:
                    splash = _PrismSplash(t: t);
                  case SplashLabStyle.aurora:
                    splash = _AuroraSplash(t: t);
                  case SplashLabStyle.liquidMetal:
                    splash = _LiquidMetalSplash(t: t);
                  case SplashLabStyle.constellation:
                    splash = _ConstellationSplash(t: t);
                  case SplashLabStyle.ripple:
                    splash = _RippleSplash(t: t);
                  case SplashLabStyle.neonTrace:
                    splash = _NeonTraceSplash(t: t);
                  case SplashLabStyle.particleBloom:
                    splash = _ParticleBloomSplash(t: t);
                  case SplashLabStyle.horizon:
                    splash = _HorizonSplash(t: t);
                  case SplashLabStyle.silkWipe:
                    splash = _SilkWipeSplash(t: t);
                  case SplashLabStyle.helix:
                    splash = _HelixSplash(t: t);
                  case SplashLabStyle.mirrorDrop:
                    splash = _MirrorDropSplash(t: t);
                  case SplashLabStyle.whisper:
                    splash = _WhisperSplash(t: t);
                  case SplashLabStyle.aperture:
                    splash = _ApertureSplash(t: t);
                  case SplashLabStyle.meshGlow:
                    splash = _MeshGlowSplash(t: t);
                  case SplashLabStyle.monogram:
                    splash = _MonogramSplash(t: t);
                  case SplashLabStyle.springInertia:
                    splash = _SpringInertiaSplash(t: t);
                  case SplashLabStyle.cinema:
                    splash = _CinemaSplash(t: t);
                  case SplashLabStyle.magnetic:
                    splash = _MagneticSplash(t: t);
                  case SplashLabStyle.frostClear:
                    splash = _FrostClearSplash(t: t);
                  case SplashLabStyle.cascade:
                    splash = _CascadeSplash(t: t);
                }

                // Unique stage-open transition per style (0 → full).
                final reveal = _easeInOutQuint(_seg(t, 0.0, 0.36));
                return _SplashRevealGate(
                  progress: reveal,
                  kind: splashRevealFor(widget.style),
                  child: splash,
                );
              },
            ),
          ),
          // Soft premium vignette over every style
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.05),
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    Color(0x40000000),
                  ],
                  stops: [0.52, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: 16,
            child: _SkipChip(onTap: _finish),
          ),
        ],
      ),
    );
  }
}

class _SkipChip extends StatelessWidget {
  const _SkipChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: const Cubic(0.22, 1, 0.36, 1),
      builder: (context, v, child) => Opacity(
        opacity: v * 0.9,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * -6),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Shared logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MusaffaLogoMark extends StatefulWidget {
  const _MusaffaLogoMark({
    required this.size,
  });

  final double size;

  @override
  State<_MusaffaLogoMark> createState() => _MusaffaLogoMarkState();
}

class _MusaffaLogoMarkState extends State<_MusaffaLogoMark> {
  ui.Image? _image;
  double? _hi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hi = FlowerLogoImageCache.hiSizeFor(context, widget.size);
    if (_hi == hi && _image != null) return;
    _hi = hi;
    _image = FlowerLogoImageCache.imageFor(hi);
    FlowerLogoImageCache.warmUp(hi).then((img) {
      if (!mounted || img == null || _hi != hi) return;
      setState(() => _image = img);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null && _hi != null) {
      return FlowerLogoImageCache.smoothImage(
        image: _image!,
        displaySize: widget.size,
        hi: _hi!,
      );
    }
    return Image.asset(
      'resources/Small Logo.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }
}

double _seg(double t, double a, double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return ((t - a) / (b - a)).clamp(0.0, 1.0);
}

double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
double _easeInOutCubic(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
double _easeOutQuint(double t) => 1 - math.pow(1 - t, 5).toDouble();
double _easeInOutQuint(double t) {
  t = t.clamp(0.0, 1.0);
  return t < 0.5
      ? 16 * math.pow(t, 5).toDouble()
      : 1 - math.pow(-2 * t + 2, 5).toDouble() / 2;
}

double _easeOutExpo(double t) {
  t = t.clamp(0.0, 1.0);
  return t >= 1 ? 1 : 1 - math.pow(2, -10 * t).toDouble();
}

/// Unified soft exit window â€” longer, smoother fade for every style.
double _exitOf(double t) => _easeInOutQuint(_seg(t, 0.86, 1.0));

/// Premium exit: opacity + micro scale + soft blur dissolve.
class _SplashExit extends StatelessWidget {
  const _SplashExit({required this.exit, required this.child});

  final double exit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (exit <= 0.001) return child;
    final keep = (1.0 - exit).clamp(0.0, 1.0);
    final blur = (exit * 14).clamp(0.01, 14.0);
    return Opacity(
      opacity: _easeOutCubic(keep),
      child: Transform.scale(
        scale: 1.0 - exit * 0.05,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: child,
        ),
      ),
    );
  }
}

// â”€â”€â”€ 1. Sable â€” typographic invert reveal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SableSplash extends StatelessWidget {
  const _SableSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    // Phase map: 0â€“0.22 black hold + letters form
    // 0.22â€“0.48 logo + wordmark settle on black
    // 0.48â€“0.62 color invert wipe
    // 0.62â€“0.88 hold on white
    // 0.88â€“1.0 soft exit
    final invert = _easeInOutCubic(_seg(t, 0.48, 0.62));
    final bg = Color.lerp(const Color(0xFF050505), Colors.white, invert)!;
    final fg = Color.lerp(Colors.white, const Color(0xFF0A0A0A), invert)!;

    final logoIn = _easeOutExpo(_seg(t, 0.08, 0.32));
    final wordIn = _easeOutCubic(_seg(t, 0.18, 0.42));
    final exit = _exitOf(t);
    final blur = (1 - logoIn) * 14 + exit * 10;

    final letters = 'TERMINAL'.split('');
    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: bg,
      child: _SplashExit(
        exit: exit,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.72 + logoIn * 0.28,
                child: Opacity(
                  opacity: logoIn,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: blur.clamp(0.01, 20),
                      sigmaY: blur.clamp(0.01, 20),
                    ),
                    child: _MusaffaLogoMark(size: logoSize),
                  ),
                ),
              ),
              SizedBox(height: logoSize * 0.28),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < letters.length; i++)
                    _SableLetter(
                      letter: letters[i],
                      progress: _easeOutCubic(
                        _seg(wordIn, i / letters.length * 0.55, 1.0),
                      ),
                      color: fg,
                      fontSize:
                          (size.width * 0.042).clamp(26.0, 42.0),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: _easeOutCubic(_seg(t, 0.34, 0.52)) * (1 - exit),
                child: Text(
                  'ENTERPRISE TRADING PLATFORM',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.2,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SableLetter extends StatelessWidget {
  const _SableLetter({
    required this.letter,
    required this.progress,
    required this.color,
    required this.fontSize,
  });

  final String letter;
  final double progress;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final y = (1 - progress) * 18;
    final blur = (1 - progress) * 8;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.02),
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, y),
          child: Transform.scale(
            scale: 0.85 + progress * 0.15,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur.clamp(0.01, 10),
                sigmaY: blur.clamp(0.01, 10),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: fontSize * 0.08,
                  height: 1,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ 2. Circle reveal â€” white â†’ expanding black â†’ logo + wordmark â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CircleRevealSplash extends StatelessWidget {
  const _CircleRevealSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final expand = _easeInOutCubic(_seg(t, 0.05, 0.38));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.55));
    final textIn = _easeOutCubic(_seg(t, 0.48, 0.70));
    final exit = _exitOf(t);

    final maxR = math.sqrt(
          size.width * size.width + size.height * size.height,
        ) /
        2;
    final radius = expand * maxR * 1.15;
    final logoSize = (size.shortestSide * 0.12).clamp(64.0, 96.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        CustomPaint(
          painter: _ExpandingCirclePainter(
            radius: radius,
            color: const Color(0xFF050505),
          ),
        ),
        _SplashExit(
          exit: exit,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.55 + logoIn * 0.45,
                  child: Opacity(
                    opacity: logoIn,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE4621E)
                                .withValues(alpha: 0.28 * logoIn),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: textIn.clamp(0.0, 1.0),
                    child: Opacity(
                      opacity: textIn,
                      child: Padding(
                        padding: EdgeInsets.only(left: logoSize * 0.22),
                        child: Transform.translate(
                          offset: Offset((1 - textIn) * 28, 0),
                          child: Text(
                            'Terminal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  (size.width * 0.038).clamp(24.0, 36.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandingCirclePainter extends CustomPainter {
  _ExpandingCirclePainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpandingCirclePainter old) =>
      old.radius != radius || old.color != color;
}

// â”€â”€â”€ 3. Orbit / ONE â€” path draw + traveling dot + logo settle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OrbitSplash extends StatelessWidget {
  const _OrbitSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final draw = _easeInOutCubic(_seg(t, 0.0, 0.45));
    final logoIn = _easeOutExpo(_seg(t, 0.42, 0.68));
    final wordIn = _easeOutCubic(_seg(t, 0.55, 0.78));
    final exit = _exitOf(t);
    final ringSize = (size.shortestSide * 0.38).clamp(180.0, 280.0);
    final logoSize = ringSize * 0.36;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.1,
          colors: [
            Color(0xFF1A3A2E),
            Color(0xFF0E1F18),
            Color(0xFF070E0B),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: _SplashExit(
        exit: exit,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(ringSize, ringSize),
                      painter: _OrbitRingPainter(
                        progress: draw,
                        strokeWidth: 1.6,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.6 + logoIn * 0.4,
                      child: Opacity(
                        opacity: logoIn,
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Opacity(
                opacity: wordIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - wordIn) * 16),
                  child: Text(
                    'TERMINAL',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: (size.width * 0.036).clamp(22.0, 32.0),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 10,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: _easeOutCubic(_seg(t, 0.62, 0.82)),
                child: Text(
                  'ONE PLATFORM',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4.5,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Soft guide ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (progress <= 0) return;

    final sweep = progress * math.pi * 2 * 0.92;
    final start = -math.pi / 2;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Traveling lead dot
    final angle = start + sweep;
    final dot = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(
      dot,
      5.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(dot, 3.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

const _brandSpectrum = [
  Color(0xFFE4621E),
  Color(0xFFD2364C),
  Color(0xFFA72669),
  Color(0xFF6A2C72),
  Color(0xFF232C64),
];

// â”€â”€â”€ 4. Prism â€” chromatic light refraction + spectral sweep â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PrismSplash extends StatelessWidget {
  const _PrismSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final flash = _easeOutCubic(_seg(t, 0.0, 0.12));
    final beam = _easeInOutCubic(_seg(t, 0.08, 0.42));
    final logoIn = _easeOutExpo(_seg(t, 0.28, 0.52));
    final wordIn = _easeOutCubic(_seg(t, 0.48, 0.72));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [Color(0xFF12101C), Color(0xFF08060F), Color(0xFF05040A)],
        ),
      ),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _PrismBeamsPainter(progress: beam, flash: flash),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.55 + logoIn * 0.45,
                    child: Opacity(
                      opacity: logoIn,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Chromatic ghost layers
                          for (final entry in [
                            (const Offset(-3.5, 0), const Color(0xFFE4621E)),
                            (const Offset(3.5, 0), const Color(0xFF232C64)),
                            (const Offset(0, -2.5), const Color(0xFFA72669)),
                          ])
                            Transform.translate(
                              offset: entry.$1 * (1 - logoIn),
                              child: Opacity(
                                opacity: 0.45 * logoIn * (1 - wordIn * 0.7),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    entry.$2.withValues(alpha: 0.7),
                                    BlendMode.srcATop,
                                  ),
                                  child: _MusaffaLogoMark(size: logoSize),
                                ),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE4621E)
                                      .withValues(alpha: 0.35 * logoIn),
                                  blurRadius: 36,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF6A2C72)
                                      .withValues(alpha: 0.28 * logoIn),
                                  blurRadius: 56,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: _MusaffaLogoMark(size: logoSize),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.18),
                  Opacity(
                    opacity: wordIn,
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: _brandSpectrum,
                      ).createShader(bounds),
                      child: Text(
                        'TERMINAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (size.width * 0.04).clamp(26.0, 40.0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.58, 0.78)),
                    child: Text(
                      'REFRACTED CLARITY',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4.2,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrismBeamsPainter extends CustomPainter {
  _PrismBeamsPainter({required this.progress, required this.flash});

  final double progress;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    // Keep rays inside the visible circular field (vignette / card circle)
    final clipR = size.shortestSide * 0.46;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: c, radius: clipR)),
    );

    if (flash > 0) {
      canvas.drawCircle(
        c,
        clipR * 0.85 * flash,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.22 * (1 - flash * 0.5)),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: c, radius: clipR)),
      );
    }
    if (progress <= 0) {
      canvas.restore();
      return;
    }

    final rays = [
      (-0.55, _brandSpectrum[0]),
      (-0.28, _brandSpectrum[1]),
      (0.0, _brandSpectrum[2]),
      (0.28, _brandSpectrum[3]),
      (0.55, _brandSpectrum[4]),
    ];
    for (var i = 0; i < rays.length; i++) {
      final delay = i * 0.06;
      final p = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final angle = rays[i].$1;
      // Cap length so beams never leave the clipped circle
      final len = clipR * (0.42 + 0.48 * p);
      final end = Offset(
        c.dx + math.sin(angle) * len,
        c.dy + math.cos(angle) * len * 0.72,
      );
      canvas.drawLine(
        c,
        end,
        Paint()
          ..shader = LinearGradient(
            colors: [
              rays[i].$2.withValues(alpha: 0.55 * p),
              rays[i].$2.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromPoints(c, end))
          ..strokeWidth = 2.0 + 2.5 * (1 - p)
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PrismBeamsPainter old) =>
      old.progress != progress || old.flash != flash;
}

// â”€â”€â”€ 5. Aurora â€” flowing northern-light ribbons + soft brand settle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AuroraSplash extends StatelessWidget {
  const _AuroraSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final curtain = _easeInOutCubic(_seg(t, 0.0, 0.45));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF061018), Color(0xFF0A1624), Color(0xFF05080E)],
        ),
      ),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _AuroraRibbonsPainter(progress: curtain, flow: t),
            ),
            // Soft horizon glow
            Align(
              alignment: const Alignment(0, 0.55),
              child: Opacity(
                opacity: curtain * 0.7,
                child: Container(
                  width: size.width * 0.7,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2DD4BF).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(0, (1 - logoIn) * 28),
                    child: Transform.scale(
                      scale: 0.7 + logoIn * 0.3,
                      child: Opacity(
                        opacity: logoIn,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2DD4BF)
                                    .withValues(alpha: 0.35 * logoIn),
                                blurRadius: 40,
                              ),
                              BoxShadow(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.25 * logoIn),
                                blurRadius: 60,
                              ),
                            ],
                          ),
                          child: _MusaffaLogoMark(size: logoSize),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.3),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 12,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.60, 0.80)),
                    child: Text(
                      'MARKETS IN MOTION',
                      style: TextStyle(
                        color: const Color(0xFF99F6E4).withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.8,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuroraRibbonsPainter extends CustomPainter {
  _AuroraRibbonsPainter({required this.progress, required this.flow});

  final double progress;
  final double flow;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final ribbons = [
      (0.22, const Color(0xFF2DD4BF), 0.0),
      (0.38, const Color(0xFF6366F1), 0.8),
      (0.52, const Color(0xFFA855F7), 1.6),
      (0.30, const Color(0xFFE4621E), 2.4),
    ];

    for (final r in ribbons) {
      final path = Path();
      final yBase = size.height * r.$1;
      final amp = size.height * 0.06 * progress;
      path.moveTo(-20, yBase);
      for (var x = 0.0; x <= size.width + 40; x += 8) {
        final nx = x / size.width;
        final y = yBase +
            math.sin(nx * math.pi * 2.2 + flow * math.pi * 2 + r.$3) * amp +
            math.sin(nx * math.pi * 5 + flow * 3) * amp * 0.35;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18 + 10 * progress
          ..color = r.$2.withValues(alpha: 0.22 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = r.$2.withValues(alpha: 0.55 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraRibbonsPainter old) =>
      old.progress != progress || old.flow != flow;
}

// â”€â”€â”€ 6. Liquid Metal â€” morphing chrome blob â†’ logo settle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LiquidMetalSplash extends StatelessWidget {
  const _LiquidMetalSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final morph = _easeInOutCubic(_seg(t, 0.0, 0.48));
    final settle = _easeOutQuint(_seg(t, 0.38, 0.62));
    final wordIn = _easeOutCubic(_seg(t, 0.55, 0.78));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);
    final blobSize = logoSize * (2.4 - settle * 1.15);

    return ColoredBox(
      color: const Color(0xFF0A0A0C),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Specular floor reflection
            Align(
              alignment: const Alignment(0, 0.72),
              child: Opacity(
                opacity: settle * 0.35,
                  child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(1.15)
                    ..scaleByDouble(1.0, 0.35, 1.0, 1.0),
                  child: Container(
                    width: logoSize * 1.6,
                    height: logoSize,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: blobSize,
                    height: blobSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(blobSize, blobSize),
                          painter: _LiquidBlobPainter(
                            progress: morph,
                            settle: settle,
                          ),
                        ),
                        Opacity(
                          opacity: settle,
                          child: Transform.scale(
                            scale: 0.75 + settle * 0.25,
                            child: _MusaffaLogoMark(size: logoSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: wordIn,
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF5F5F7),
                          Color(0xFFA1A1AA),
                          Color(0xFFE4E4E7),
                          Color(0xFF71717A),
                        ],
                        stops: [0.0, 0.35, 0.65, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        'TERMINAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 9,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.64, 0.82)),
                    child: Text(
                      'PRECISION FORGED',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidBlobPainter extends CustomPainter {
  _LiquidBlobPainter({required this.progress, required this.settle});

  final double progress;
  final double settle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final baseR = size.width * 0.38;
    final path = Path();
    const n = 64;
    for (var i = 0; i <= n; i++) {
      final a = (i / n) * math.pi * 2;
      final wobble = math.sin(a * 3 + progress * math.pi * 4) * 0.14 *
              (1 - settle) +
          math.sin(a * 5 - progress * math.pi * 3) * 0.08 * (1 - settle);
      final r = baseR * (0.55 + 0.45 * progress) * (1 + wobble);
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    final opacity = (1 - settle * 0.85).clamp(0.0, 1.0);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [
            Colors.white.withValues(alpha: 0.92 * opacity),
            const Color(0xFFD4D4D8).withValues(alpha: 0.75 * opacity),
            const Color(0xFF52525B).withValues(alpha: 0.55 * opacity),
            const Color(0xFF27272A).withValues(alpha: 0.4 * opacity),
          ],
          stops: const [0.0, 0.28, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: baseR * 1.2))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 8 * (1 - settle)),
    );

    // Specular highlight
    canvas.drawCircle(
      Offset(c.dx - baseR * 0.28, c.dy - baseR * 0.32),
      baseR * 0.18,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidBlobPainter old) =>
      old.progress != progress || old.settle != settle;
}

// â”€â”€â”€ 7. Constellation â€” star network forms brand mark â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ConstellationSplash extends StatelessWidget {
  const _ConstellationSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final stars = _easeOutCubic(_seg(t, 0.0, 0.28));
    final links = _easeInOutCubic(_seg(t, 0.18, 0.52));
    final logoIn = _easeOutExpo(_seg(t, 0.42, 0.68));
    final wordIn = _easeOutCubic(_seg(t, 0.58, 0.80));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.13).clamp(68.0, 104.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.15,
          colors: [Color(0xFF0F1224), Color(0xFF070810), Color(0xFF030308)],
        ),
      ),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ConstellationPainter(
                stars: stars,
                links: links,
                pulse: t,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.4 + logoIn * 0.6,
                    child: Opacity(
                      opacity: logoIn,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF818CF8)
                                  .withValues(alpha: 0.4 * logoIn),
                              blurRadius: 48,
                            ),
                            BoxShadow(
                              color: const Color(0xFFE4621E)
                                  .withValues(alpha: 0.22 * logoIn),
                              blurRadius: 32,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.34),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.036).clamp(22.0, 34.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 11,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.68, 0.86)),
                    child: Text(
                      'CONNECTED INTELLIGENCE',
                      style: TextStyle(
                        color: const Color(0xFFA5B4FC).withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3.8,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.stars,
    required this.links,
    required this.pulse,
  });

  final double stars;
  final double links;
  final double pulse;

  static const _nodes = [
    Offset(0.18, 0.22),
    Offset(0.42, 0.14),
    Offset(0.68, 0.20),
    Offset(0.82, 0.38),
    Offset(0.72, 0.62),
    Offset(0.48, 0.72),
    Offset(0.22, 0.58),
    Offset(0.12, 0.40),
    Offset(0.50, 0.38),
    Offset(0.36, 0.48),
    Offset(0.58, 0.48),
    Offset(0.34, 0.28),
  ];

  static const _edges = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 5),
    (5, 6),
    (6, 7),
    (7, 0),
    (1, 11),
    (11, 9),
    (9, 5),
    (2, 10),
    (10, 4),
    (8, 9),
    (8, 10),
    (8, 11),
    (0, 11),
    (7, 9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      for (final n in _nodes) Offset(n.dx * size.width, n.dy * size.height),
    ];

    // Soft ambient stars
    final rng = math.Random(42);
    for (var i = 0; i < 48; i++) {
      final o = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(pulse * math.pi * 4 + i));
      canvas.drawCircle(
        o,
        0.8 + rng.nextDouble() * 1.2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18 * stars * twinkle),
      );
    }

    // Network edges
    for (var i = 0; i < _edges.length; i++) {
      final e = _edges[i];
      final edgeT = ((links * _edges.length) - i).clamp(0.0, 1.0);
      if (edgeT <= 0) continue;
      final a = pts[e.$1];
      final b = pts[e.$2];
      final mid = Offset.lerp(a, b, edgeT)!;
      canvas.drawLine(
        a,
        mid,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF6366F1),
            const Color(0xFFE4621E),
            i / _edges.length,
          )!
              .withValues(alpha: 0.55 * edgeT)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Nodes
    for (var i = 0; i < pts.length; i++) {
      final appear = ((stars * _nodes.length) - i * 0.55).clamp(0.0, 1.0);
      if (appear <= 0) continue;
      final p = pts[i];
      final glow = 1 + 0.35 * math.sin(pulse * math.pi * 3 + i);
      canvas.drawCircle(
        p,
        6 * glow,
        Paint()
          ..color = const Color(0xFF818CF8).withValues(alpha: 0.2 * appear)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        p,
        2.4,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * appear),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.stars != stars || old.links != links || old.pulse != pulse;
}

// â”€â”€â”€ 8. Ripple â€” concentric sonic rings from logo core â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RippleSplash extends StatelessWidget {
  const _RippleSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pulse = _easeOutCubic(_seg(t, 0.0, 0.55));
    final logoIn = _easeOutExpo(_seg(t, 0.18, 0.45));
    final wordIn = _easeOutCubic(_seg(t, 0.42, 0.68));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF06060A),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _RippleRingsPainter(progress: pulse, flow: t),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.5 + logoIn * 0.5,
                    child: Opacity(
                      opacity: logoIn,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE4621E)
                                  .withValues(alpha: 0.4 * logoIn),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.3),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.55, 0.75)),
                    child: Text(
                      'SIGNAL LOCKED',
                      style: TextStyle(
                        color: const Color(0xFFE4621E).withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RippleRingsPainter extends CustomPainter {
  _RippleRingsPainter({required this.progress, required this.flow});

  final double progress;
  final double flow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final maxR = size.shortestSide * 0.7;
    for (var i = 0; i < 6; i++) {
      final phase = ((progress * 1.15) - i * 0.12).clamp(0.0, 1.0);
      if (phase <= 0) continue;
      final r = maxR * phase;
      final alpha = (1 - phase) * 0.55;
      final color = Color.lerp(
        const Color(0xFFE4621E),
        const Color(0xFF6A2C72),
        i / 5,
      )!;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 + (1 - phase) * 2
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    // Soft core glow
    canvas.drawCircle(
      c,
      40 + 20 * math.sin(flow * math.pi * 2),
      Paint()
        ..color = const Color(0xFFE4621E).withValues(alpha: 0.12 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
  }

  @override
  bool shouldRepaint(covariant _RippleRingsPainter old) =>
      old.progress != progress || old.flow != flow;
}

// â”€â”€â”€ 9. Neon Trace â€” glowing outline draws then fills brand â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NeonTraceSplash extends StatelessWidget {
  const _NeonTraceSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final trace = _easeInOutCubic(_seg(t, 0.0, 0.42));
    final fill = _easeOutQuint(_seg(t, 0.35, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.52, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);
    final frame = logoSize * 1.55;

    return ColoredBox(
      color: const Color(0xFF050508),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Scanline ambience
            CustomPaint(painter: _ScanlinesPainter(opacity: 0.04 + 0.03 * fill)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: frame,
                    height: frame,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(frame, frame),
                          painter: _NeonFramePainter(progress: trace),
                        ),
                        Opacity(
                          opacity: fill,
                          child: Transform.scale(
                            scale: 0.8 + fill * 0.2,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF2D95)
                                        .withValues(alpha: 0.45 * fill),
                                    blurRadius: 32,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF00F0FF)
                                        .withValues(alpha: 0.3 * fill),
                                    blurRadius: 48,
                                  ),
                                ],
                              ),
                              child: _MusaffaLogoMark(size: logoSize),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: wordIn,
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFFFF2D95)],
                      ).createShader(bounds),
                      child: Text(
                        'TERMINAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 9,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.62, 0.82)),
                    child: Text(
                      'LIVE EDGE',
                      style: TextStyle(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  _ScanlinesPainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter old) => old.opacity != opacity;
}

class _NeonFramePainter extends CustomPainter {
  _NeonFramePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = progress * math.pi * 2;

    // Outer glow arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: const [
            Color(0xFF00F0FF),
            Color(0xFFFF2D95),
            Color(0xFFE4621E),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: const [
            Color(0xFF00F0FF),
            Color(0xFFFF2D95),
            Color(0xFFE4621E),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Lead tip
    final angle = -math.pi / 2 + sweep;
    final tip = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
    canvas.drawCircle(
      tip,
      5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _NeonFramePainter old) => old.progress != progress;
}

// â”€â”€â”€ 10. Particle Bloom â€” burst then coalesce into logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ParticleBloomSplash extends StatelessWidget {
  const _ParticleBloomSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final burst = _easeOutCubic(_seg(t, 0.0, 0.35));
    final coalesce = _easeInOutCubic(_seg(t, 0.28, 0.62));
    final logoIn = _easeOutExpo(_seg(t, 0.48, 0.70));
    final wordIn = _easeOutCubic(_seg(t, 0.60, 0.80));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1A0F18), Color(0xFF08060C), Color(0xFF040308)],
        ),
      ),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ParticleBloomPainter(
                burst: burst,
                coalesce: coalesce,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.3 + logoIn * 0.7,
                    child: Opacity(
                      opacity: logoIn,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD2364C)
                                  .withValues(alpha: 0.4 * logoIn),
                              blurRadius: 44,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.3),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.68, 0.86)),
                    child: Text(
                      'ASSEMBLED',
                      style: TextStyle(
                        color: const Color(0xFFD2364C).withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticleBloomPainter extends CustomPainter {
  _ParticleBloomPainter({required this.burst, required this.coalesce});

  final double burst;
  final double coalesce;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final rng = math.Random(7);
    const count = 56;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + rng.nextDouble() * 0.4;
      final maxDist = size.shortestSide * (0.18 + rng.nextDouble() * 0.32);
      final out = burst * maxDist;
      final back = coalesce * out;
      final dist = (out - back).clamp(0.0, maxDist);
      final p = Offset(
        c.dx + math.cos(angle) * dist,
        c.dy + math.sin(angle) * dist,
      );
      final alpha = (burst * (1 - coalesce * 0.85)).clamp(0.0, 1.0);
      final color = _brandSpectrum[i % _brandSpectrum.length];
      canvas.drawCircle(
        p,
        1.5 + rng.nextDouble() * 2.2,
        Paint()
          ..color = color.withValues(alpha: 0.75 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBloomPainter old) =>
      old.burst != burst || old.coalesce != coalesce;
}

// â”€â”€â”€ 11. Horizon â€” premium dawn rise + atmospheric brand settle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HorizonSplash extends StatelessWidget {
  const _HorizonSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rise = _easeInOutQuint(_seg(t, 0.0, 0.52));
    final atmosphere = _easeOutCubic(_seg(t, 0.12, 0.55));
    final glow = _easeOutCubic(_seg(t, 0.22, 0.58));
    final logoIn = _easeOutExpo(_seg(t, 0.38, 0.64));
    final wordIn = _easeOutCubic(_seg(t, 0.52, 0.76));
    final tagIn = _easeOutCubic(_seg(t, 0.62, 0.84));
    final shimmer = _easeInOutCubic(_seg(t, 0.35, 0.85));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    // Horizon climbs from near-bottom to mid-lower third
    final lineY = size.height * (0.82 - rise * 0.34);
    final sunY = lineY - 8;
    final sunSize = size.shortestSide * (0.22 + glow * 0.08);

    return ColoredBox(
      color: const Color(0xFF040308),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Deep night â†’ warm dawn sky
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFF05060C),
                      const Color(0xFF2A1538),
                      atmosphere * 0.85,
                    )!,
                    Color.lerp(
                      const Color(0xFF0A0814),
                      const Color(0xFF1A0F24),
                      glow * 0.7,
                    )!,
                    const Color(0xFF040308),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Soft stars that fade as dawn arrives
            CustomPaint(
              painter: _HorizonStarsPainter(
                opacity: (1 - atmosphere * 0.92).clamp(0.0, 1.0),
                twinkle: t,
              ),
            ),

            // Atmospheric haze bands
            Positioned(
              left: 0,
              right: 0,
              top: lineY - size.height * 0.28,
              height: size.height * 0.32,
              child: Opacity(
                opacity: atmosphere * 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFFA72669).withValues(alpha: 0.08),
                        const Color(0xFFE4621E).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Rising sun disk (soft bloom behind horizon)
            Positioned(
              left: (size.width - sunSize) / 2,
              top: sunY - sunSize * 0.55,
              width: sunSize,
              height: sunSize,
              child: Opacity(
                opacity: glow,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFB36B).withValues(alpha: 0.85),
                          const Color(0xFFE4621E).withValues(alpha: 0.45),
                          const Color(0xFFA72669).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Primary dawn glow dome
            Positioned(
              left: 0,
              right: 0,
              top: lineY - 160,
              height: 220,
              child: Opacity(
                opacity: glow,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter,
                      radius: 1.15,
                      colors: [
                        const Color(0xFFFFB36B).withValues(alpha: 0.42),
                        const Color(0xFFE4621E).withValues(alpha: 0.28),
                        const Color(0xFFA72669).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.28, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Ground below horizon (subtle)
            Positioned(
              left: 0,
              right: 0,
              top: lineY,
              bottom: 0,
              child: Opacity(
                opacity: rise * 0.9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0C0812).withValues(alpha: 0.55),
                        const Color(0xFF040308),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Multi-layer horizon line + shimmer
            Positioned(
              left: size.width * 0.06,
              right: size.width * 0.06,
              top: lineY - 1,
              child: Opacity(
                opacity: rise.clamp(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Soft bloom under the line
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFE4621E).withValues(alpha: 0.22),
                            const Color(0xFFFFB36B).withValues(alpha: 0.28),
                            const Color(0xFFA72669).withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: SizedBox(
                        height: 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFFE4621E)
                                        .withValues(alpha: 0.85),
                                    const Color(0xFFFFD6A5)
                                        .withValues(alpha: 0.95),
                                    const Color(0xFFE4621E)
                                        .withValues(alpha: 0.9),
                                    const Color(0xFFA72669)
                                        .withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.18, 0.45, 0.62, 0.82, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE4621E)
                                        .withValues(alpha: 0.55),
                                    blurRadius: 22,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFB36B)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 36,
                                  ),
                                ],
                              ),
                            ),
                            // Traveling shimmer highlight
                            FractionallySizedBox(
                              alignment: Alignment(-1.2 + shimmer * 2.4, 0),
                              widthFactor: 0.18,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.65),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Brand content â€” sits just above the horizon glow
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: size.height - lineY + 28,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, (1 - logoIn) * 18),
                        child: Opacity(
                          opacity: logoIn,
                          child: Transform.scale(
                            scale: 0.82 + logoIn * 0.18,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE4621E)
                                        .withValues(alpha: 0.35 * logoIn),
                                    blurRadius: 40,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFB36B)
                                        .withValues(alpha: 0.18 * logoIn),
                                    blurRadius: 64,
                                  ),
                                ],
                              ),
                              child: _MusaffaLogoMark(size: logoSize),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: logoSize * 0.2),
                      Opacity(
                        opacity: wordIn,
                        child: Transform.translate(
                          offset: Offset(0, (1 - wordIn) * 10),
                          child: Text(
                            'TERMINAL',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.96),
                              fontSize:
                                  (size.width * 0.038).clamp(24.0, 36.0),
                              fontWeight: FontWeight.w300,
                              letterSpacing: 6 + wordIn * 6,
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: tagIn,
                        child: Text(
                          'OPENING BELL',
                          style: TextStyle(
                            color: const Color(0xFFFFB36B)
                                .withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4.8,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizonStarsPainter extends CustomPainter {
  _HorizonStarsPainter({required this.opacity, required this.twinkle});

  final double opacity;
  final double twinkle;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final rng = math.Random(91);
    for (var i = 0; i < 42; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.55;
      final pulse =
          0.45 + 0.55 * (0.5 + 0.5 * math.sin(twinkle * math.pi * 3 + i));
      canvas.drawCircle(
        Offset(x, y),
        0.7 + rng.nextDouble() * 1.1,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22 * opacity * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonStarsPainter old) =>
      old.opacity != opacity || old.twinkle != twinkle;
}

// â”€â”€â”€ 12. Silk Wipe â€” soft dual curtains + elegant brand settle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SilkWipeSplash extends StatelessWidget {
  const _SilkWipeSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wipe = _easeInOutQuint(_seg(t, 0.0, 0.48));
    final logoIn = _easeOutExpo(_seg(t, 0.28, 0.55));
    final wordIn = _easeOutCubic(_seg(t, 0.48, 0.72));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final open = wipe * size.width * 0.55;

    return ColoredBox(
      color: const Color(0xFF0C0A10),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft ambient wash behind curtains
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Color.lerp(
                      const Color(0xFF0C0A10),
                      const Color(0xFF2A1830),
                      logoIn * 0.6,
                    )!,
                    const Color(0xFF0C0A10),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.82 + logoIn * 0.18,
                    child: Opacity(
                      opacity: logoIn,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: (1 - logoIn) * 12 + 0.01,
                          sigmaY: (1 - logoIn) * 12 + 0.01,
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Transform.translate(
                      offset: Offset(0, (1 - wordIn) * 14),
                      child: Text(
                        'TERMINAL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4 + wordIn * 8,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.58, 0.78)),
                    child: Text(
                      'CRAFTED FOR MARKETS',
                      style: TextStyle(
                        color: const Color(0xFFD4A5C0).withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Left silk curtain
            Positioned(
              left: -open,
              top: 0,
              bottom: 0,
              width: size.width * 0.52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF1A1424),
                      const Color(0xFF2A1E38),
                      const Color(0xFF1A1424).withValues(alpha: 0.92),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 0.88, 1.0],
                  ),
                ),
              ),
            ),
            // Right silk curtain
            Positioned(
              right: -open,
              top: 0,
              bottom: 0,
              width: size.width * 0.52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      const Color(0xFF1A1424),
                      const Color(0xFF2A1E38),
                      const Color(0xFF1A1424).withValues(alpha: 0.92),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 0.88, 1.0],
                  ),
                ),
              ),
            ),
            // Soft edge sheen on curtains
            if (wipe < 0.98) ...[
              Positioned(
                left: size.width * 0.52 - open - 1,
                top: 0,
                bottom: 0,
                width: 2,
                child: Opacity(
                  opacity: (1 - wipe) * 0.5,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
              Positioned(
                right: size.width * 0.52 - open - 1,
                top: 0,
                bottom: 0,
                width: 2,
                child: Opacity(
                  opacity: (1 - wipe) * 0.5,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 13. Helix â€” dual spiral ribbons coil into the brand â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HelixSplash extends StatelessWidget {
  const _HelixSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final coil = _easeInOutCubic(_seg(t, 0.0, 0.55));
    final logoIn = _easeOutExpo(_seg(t, 0.38, 0.62));
    final wordIn = _easeOutCubic(_seg(t, 0.55, 0.78));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.05),
          radius: 1.1,
          colors: [Color(0xFF12101C), Color(0xFF080610), Color(0xFF040308)],
        ),
      ),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _HelixPainter(progress: coil, flow: t),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.55 + logoIn * 0.45,
                    child: Opacity(
                      opacity: logoIn,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA72669)
                                  .withValues(alpha: 0.35 * logoIn),
                              blurRadius: 40,
                            ),
                            BoxShadow(
                              color: const Color(0xFF232C64)
                                  .withValues(alpha: 0.3 * logoIn),
                              blurRadius: 56,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.3),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.036).clamp(22.0, 34.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 11,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.64, 0.84)),
                    child: Text(
                      'SPIRALING INSIGHT',
                      style: TextStyle(
                        color: const Color(0xFFC4B5FD).withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelixPainter extends CustomPainter {
  _HelixPainter({required this.progress, required this.flow});

  final double progress;
  final double flow;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = Offset(size.width / 2, size.height * 0.42);
    final turns = 3.2 * progress;
    final amp = size.shortestSide * 0.16 * (1.15 - progress * 0.35);
    final height = size.shortestSide * 0.55;

    void drawStrand(double phase, Color color) {
      final path = Path();
      const steps = 80;
      for (var i = 0; i <= steps; i++) {
        final u = i / steps;
        if (u > progress) break;
        final angle = u * turns * math.pi * 2 + phase + flow * 0.4;
        final y = c.dy - height / 2 + u * height;
        final x = c.dx + math.sin(angle) * amp;
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
          ..strokeWidth = 3.2
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color.withValues(alpha: 0.75)
          ..strokeCap = StrokeCap.round,
      );
    }

    drawStrand(0, const Color(0xFFE4621E));
    drawStrand(math.pi, const Color(0xFF6A2C72));
  }

  @override
  bool shouldRepaint(covariant _HelixPainter old) =>
      old.progress != progress || old.flow != flow;
}

// â”€â”€â”€ 14. Mirror Drop â€” logo drops with soft bounce + floor reflection â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MirrorDropSplash extends StatelessWidget {
  const _MirrorDropSplash({required this.t});
  final double t;

  double _bounce(double x) {
    // Soft overshoot settle
    if (x < 0.65) return _easeOutCubic(x / 0.65);
    if (x < 0.82) {
      final u = (x - 0.65) / 0.17;
      return 1 + 0.06 * math.sin(u * math.pi);
    }
    final u = (x - 0.82) / 0.18;
    return 1 + 0.02 * (1 - u) * math.sin(u * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final drop = _bounce(_seg(t, 0.08, 0.55));
    final floorIn = _easeOutCubic(_seg(t, 0.35, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.52, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final dropY = (1 - drop) * -size.height * 0.28;

    return ColoredBox(
      color: const Color(0xFF07070A),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Floor plane
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.42,
              child: Opacity(
                opacity: floorIn,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.03),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(0, dropY),
                    child: Opacity(
                      opacity: drop.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MusaffaLogoMark(size: logoSize),
                          // Short reflection â€” keeps logoâ†”text gap tight
                          SizedBox(
                            height: logoSize * 0.36,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: 0.4,
                                child: Transform(
                                  alignment: Alignment.topCenter,
                                  transform: Matrix4.identity()
                                    ..scaleByDouble(1.0, -1.0, 1.0, 1.0),
                                  child: Opacity(
                                    opacity:
                                        0.22 * floorIn * drop.clamp(0.0, 1.0),
                                    child: ImageFiltered(
                                      imageFilter: ui.ImageFilter.blur(
                                        sigmaX: 1.2,
                                        sigmaY: 4,
                                      ),
                                      child: ShaderMask(
                                        blendMode: BlendMode.dstIn,
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.5),
                                            Colors.transparent,
                                          ],
                                        ).createShader(bounds),
                                        child: _MusaffaLogoMark(size: logoSize),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.62, 0.82)),
                    child: Text(
                      'GROUND TRUTH',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 15. Whisper â€” ultra-soft blur dissolve (Apple-keynote calm) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WhisperSplash extends StatelessWidget {
  const _WhisperSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final clear = _easeOutQuint(_seg(t, 0.05, 0.48));
    final wordIn = _easeOutCubic(_seg(t, 0.35, 0.62));
    final tagIn = _easeOutCubic(_seg(t, 0.52, 0.75));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);
    final blur = (1 - clear) * 28 + 0.01;
    final letters = 'TERMINAL'.split('');

    return ColoredBox(
      color: const Color(0xFF09090B),
      child: _SplashExit(
        exit: exit,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: clear,
                child: Transform.scale(
                  scale: 0.92 + clear * 0.08,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: blur,
                      sigmaY: blur,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.08 * clear),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                ),
              ),
              SizedBox(height: logoSize * 0.32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < letters.length; i++)
                    Opacity(
                      opacity: _easeOutCubic(
                        _seg(wordIn, i / letters.length * 0.45, 1.0),
                      ),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          (1 -
                                  _easeOutCubic(
                                    _seg(wordIn, i / letters.length * 0.45, 1.0),
                                  )) *
                              10,
                        ),
                        child: Text(
                          letters[i],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: (size.width * 0.036).clamp(22.0, 34.0),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 6,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Opacity(
                opacity: tagIn,
                child: Text(
                  'QUIETLY POWERFUL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.32),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 5,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ 16. Aperture â€” camera iris blades open (Apple Camera grade) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ApertureSplash extends StatelessWidget {
  const _ApertureSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final open = _easeInOutQuint(_seg(t, 0.04, 0.50));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.72));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF050505),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Brand content sits under the iris
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.7 + logoIn * 0.3,
                    child: Opacity(
                      opacity: logoIn,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.036).clamp(22.0, 34.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.60, 0.80)),
                    child: Text(
                      'IN FOCUS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Iris opens to reveal content beneath
            IgnorePointer(
              child: Opacity(
                opacity: (1 - open * 0.92).clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: _AperturePainter(open: open),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AperturePainter extends CustomPainter {
  _AperturePainter({required this.open});
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);
    final hole = size.shortestSide * (0.06 + open * 0.55);
    const blades = 8;

    // Full-screen dark with circular hole (even-odd)
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: c, radius: hole));
    canvas.drawPath(mask, Paint()..color = const Color(0xFF050505));

    // Blade edges around the hole for iris feel
    for (var i = 0; i < blades; i++) {
      final a0 = (i / blades) * math.pi * 2;
      final a1 = ((i + 0.92) / blades) * math.pi * 2;
      final outer = hole + size.shortestSide * 0.22 * (1 - open * 0.35);
      final path = Path()
        ..moveTo(
          c.dx + math.cos(a0) * hole,
          c.dy + math.sin(a0) * hole,
        )
        ..lineTo(
          c.dx + math.cos(a0 + 0.08) * outer,
          c.dy + math.sin(a0 + 0.08) * outer,
        )
        ..lineTo(
          c.dx + math.cos(a1) * outer,
          c.dy + math.sin(a1) * outer,
        )
        ..lineTo(
          c.dx + math.cos(a1 - 0.08) * hole * 1.02,
          c.dy + math.sin(a1 - 0.08) * hole * 1.02,
        )
        ..close();

      final alpha = (1 - open * 0.7).clamp(0.15, 0.85);
      canvas.drawPath(
        path,
        Paint()..color = Color.lerp(
          const Color(0xFF1C1C22),
          const Color(0xFF2A2A32),
          i.isEven ? 0.0 : 1.0,
        )!.withValues(alpha: alpha),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = Colors.white.withValues(alpha: 0.08 * alpha),
      );
    }

    // Soft rim light
    canvas.drawCircle(
      c,
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.12 * (1 - open * 0.5)),
    );

    // Keep analyzer happy â€” maxR used as safety for huge screens
    if (maxR < 0) return;
  }

  @override
  bool shouldRepaint(covariant _AperturePainter old) => old.open != open;
}

// â”€â”€â”€ 17. Mesh Glow â€” Stripe/Linear soft mesh gradient morph â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MeshGlowSplash extends StatelessWidget {
  const _MeshGlowSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final morph = _easeInOutQuint(_seg(t, 0.0, 0.58));
    final logoIn = _easeOutExpo(_seg(t, 0.30, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    final c1 = Alignment(-0.8 + morph * 0.5, -0.7 + morph * 0.2);
    final c2 = Alignment(0.7 - morph * 0.3, 0.6 - morph * 0.4);
    final c3 = Alignment(-0.2 + morph * 0.4, 0.8 - morph * 0.5);

    return _SplashExit(
      exit: exit,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF09090B)),
          // Soft mesh blobs
          Opacity(
            opacity: 0.55 + morph * 0.35,
            child: Stack(
              children: [
                Align(
                  alignment: c1,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE4621E).withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: c2,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(
                      width: size.width * 0.65,
                      height: size.width * 0.65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: c3,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: Container(
                      width: size.width * 0.55,
                      height: size.width * 0.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFA72669).withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Subtle noise veil
          Opacity(
            opacity: 0.04,
            child: CustomPaint(painter: _SoftNoisePainter(seed: 11)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.85 + logoIn * 0.15,
                  child: Opacity(
                    opacity: logoIn,
                    child: _MusaffaLogoMark(size: logoSize),
                  ),
                ),
                SizedBox(height: logoSize * 0.3),
                Opacity(
                  opacity: wordIn,
                  child: Text(
                    'TERMINAL',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 9,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: _easeOutCubic(_seg(t, 0.60, 0.82)),
                  child: Text(
                    'BUILT FOR SCALE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4.5,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftNoisePainter extends CustomPainter {
  _SoftNoisePainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    for (var i = 0; i < 120; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.6,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoftNoisePainter old) => old.seed != seed;
}

// â”€â”€â”€ 18. Monogram â€” T mark expands into TERMINAL wordmark â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MonogramSplash extends StatelessWidget {
  const _MonogramSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final markIn = _easeOutQuint(_seg(t, 0.05, 0.32));
    final expand = _easeInOutCubic(_seg(t, 0.32, 0.62));
    final logoIn = _easeOutExpo(_seg(t, 0.48, 0.70));
    final tagIn = _easeOutCubic(_seg(t, 0.62, 0.82));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.12).clamp(64.0, 96.0);

    final monoSize = (size.width * 0.22).clamp(72.0, 120.0) * (1 - expand * 0.55);
    final wordOpacity = expand;
    final monoOpacity = (1 - expand * 0.85).clamp(0.0, 1.0);

    return ColoredBox(
      color: const Color(0xFF0A0A0C),
      child: _SplashExit(
        exit: exit,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: logoIn,
                child: Transform.scale(
                  scale: 0.8 + logoIn * 0.2,
                  child: _MusaffaLogoMark(size: logoSize),
                ),
              ),
              SizedBox(height: logoSize * 0.28),
              SizedBox(
                height: monoSize * 1.1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: markIn * monoOpacity,
                      child: Text(
                        'T',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: monoSize,
                          fontWeight: FontWeight.w200,
                          height: 1,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: wordOpacity,
                      child: Transform.scale(
                        scale: 0.85 + expand * 0.15,
                        child: Text(
                          'TERMINAL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: (size.width * 0.04).clamp(26.0, 40.0),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2 + expand * 8,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: tagIn,
                child: Text(
                  'SIMPLY CLEAR',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.32),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 5,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ 19. Spring Inertia â€” iOS-spring zoom settle with overshoot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SpringInertiaSplash extends StatelessWidget {
  const _SpringInertiaSplash({required this.t});
  final double t;

  /// Approximate spring with overshoot then settle.
  double _spring(double x) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    // Underdamped-ish: overshoots past 1 then settles
    final decay = math.exp(-6.5 * x);
    return 1 - decay * math.cos(x * math.pi * 3.2);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final springT = _spring(_seg(t, 0.0, 0.55));
    final wordIn = _easeOutCubic(_seg(t, 0.42, 0.68));
    final tagIn = _easeOutCubic(_seg(t, 0.55, 0.78));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);

    // Map spring: start large+blurry far, settle to 1.0
    final scale = 1.55 - springT.clamp(0.0, 1.12) * 0.55;
    final opacity = springT.clamp(0.0, 1.0);
    final blur = ((1.12 - springT.clamp(0.0, 1.12)) * 18).clamp(0.01, 20.0);

    return ColoredBox(
      color: const Color(0xFF08080A),
      child: _SplashExit(
        exit: exit,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale.clamp(0.85, 1.55),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: blur,
                      sigmaY: blur,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE4621E)
                                .withValues(alpha: 0.25 * opacity),
                            blurRadius: 48,
                          ),
                        ],
                      ),
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                ),
              ),
              SizedBox(height: logoSize * 0.3),
              Opacity(
                opacity: wordIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - wordIn) * 16),
                  child: Text(
                    'TERMINAL',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 9,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: tagIn,
                child: Text(
                  'INSTANT RESPONSE',
                  style: TextStyle(
                    color: const Color(0xFFE4621E).withValues(alpha: 0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ 20. Cinema â€” letterbox bars + soft brand reveal (trailer grade) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CinemaSplash extends StatelessWidget {
  const _CinemaSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bars = _easeInOutQuint(_seg(t, 0.0, 0.38));
    final logoIn = _easeOutExpo(_seg(t, 0.28, 0.55));
    final wordIn = _easeOutCubic(_seg(t, 0.48, 0.72));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final barH = size.height * 0.14 * bars;

    return ColoredBox(
      color: const Color(0xFF030303),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft vignette stage
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1A1210).withValues(alpha: 0.5 * logoIn),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.88 + logoIn * 0.12,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: (1 - logoIn) * 8 + 0.01,
                          sigmaY: (1 - logoIn) * 8 + 0.01,
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 12,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.58, 0.80)),
                    child: Text(
                      'A NEW MARKET PICTURE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Letterbox bars
            Align(
              alignment: Alignment.topCenter,
              child: Container(height: barH, color: Colors.black),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(height: barH, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 21. Magnetic â€” floating orbs pull into the brand core â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MagneticSplash extends StatelessWidget {
  const _MagneticSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pull = _easeInOutQuint(_seg(t, 0.0, 0.60));
    final logoIn = _easeOutExpo(_seg(t, 0.40, 0.65));
    final wordIn = _easeOutCubic(_seg(t, 0.55, 0.78));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF07060C),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MagneticOrbsPainter(pull: pull, flow: t),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.55 + logoIn * 0.45,
                    child: Opacity(
                      opacity: logoIn,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.35 * logoIn),
                              blurRadius: 44,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.3),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.036).clamp(22.0, 34.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.64, 0.84)),
                    child: Text(
                      'FORCES ALIGNED',
                      style: TextStyle(
                        color: const Color(0xFFA5B4FC).withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MagneticOrbsPainter extends CustomPainter {
  _MagneticOrbsPainter({required this.pull, required this.flow});

  final double pull;
  final double flow;

  static const _starts = [
    Offset(0.12, 0.22),
    Offset(0.88, 0.18),
    Offset(0.08, 0.68),
    Offset(0.92, 0.72),
    Offset(0.20, 0.48),
    Offset(0.78, 0.42),
    Offset(0.48, 0.12),
    Offset(0.55, 0.85),
    Offset(0.32, 0.78),
    Offset(0.70, 0.28),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final target = Offset(size.width / 2, size.height * 0.42);
    for (var i = 0; i < _starts.length; i++) {
      final s = Offset(_starts[i].dx * size.width, _starts[i].dy * size.height);
      final p = Offset.lerp(s, target, pull)!;
      final fade = (1 - pull * 0.85).clamp(0.0, 1.0);
      final color = _brandSpectrum[i % _brandSpectrum.length];
      final r = 3.5 + (i % 3) * 1.2;
      canvas.drawCircle(
        p,
        r + 6,
        Paint()
          ..color = color.withValues(alpha: 0.18 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()..color = color.withValues(alpha: 0.85 * fade),
      );
      // Soft trail
      if (pull > 0.05 && pull < 0.95) {
        canvas.drawLine(
          s,
          p,
          Paint()
            ..color = color.withValues(alpha: 0.12 * fade)
            ..strokeWidth = 1
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
    // Core attractor pulse
    final pulse = 1 + 0.08 * math.sin(flow * math.pi * 4);
    canvas.drawCircle(
      target,
      28 * pulse * pull,
      Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: 0.12 * pull)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  @override
  bool shouldRepaint(covariant _MagneticOrbsPainter old) =>
      old.pull != pull || old.flow != flow;
}

// â”€â”€â”€ 22. Frost Clear â€” frosted glass thaws into crisp brand â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FrostClearSplash extends StatelessWidget {
  const _FrostClearSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final thaw = _easeInOutQuint(_seg(t, 0.06, 0.58));
    final logoIn = _easeOutExpo(_seg(t, 0.25, 0.55));
    final wordIn = _easeOutCubic(_seg(t, 0.48, 0.72));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final frostBlur = (1 - thaw) * 22 + 0.01;

    return ColoredBox(
      color: const Color(0xFF0E1218),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cool ambient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  colors: [
                    const Color(0xFF1E3A5F).withValues(alpha: 0.35 * thaw),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: frostBlur,
                      sigmaY: frostBlur,
                    ),
                    child: Opacity(
                      opacity: logoIn,
                      child: Transform.scale(
                        scale: 0.9 + logoIn * 0.1,
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.58, 0.80)),
                    child: Text(
                      'CRYSTAL CLEAR',
                      style: TextStyle(
                        color: const Color(0xFF93C5FD).withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Frost overlay fading out
            IgnorePointer(
              child: Opacity(
                opacity: (1 - thaw).clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: _FrostNoisePainter(density: 1 - thaw),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostNoisePainter extends CustomPainter {
  _FrostNoisePainter({required this.density});
  final double density;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(21);
    final count = (180 * density).round();
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.8 + rng.nextDouble() * 2.2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08 + rng.nextDouble() * 0.12),
      );
    }
    // Soft frost veil
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.06 * density),
    );
  }

  @override
  bool shouldRepaint(covariant _FrostNoisePainter old) => old.density != density;
}

// â”€â”€â”€ 23. Cascade â€” soft staggered blinds lift to reveal brand â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CascadeSplash extends StatelessWidget {
  const _CascadeSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final lift = _easeInOutQuint(_seg(t, 0.0, 0.55));
    final logoIn = _easeOutExpo(_seg(t, 0.28, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.48, 0.72));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    const strips = 14;

    return ColoredBox(
      color: const Color(0xFF0A0A0E),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.85 + logoIn * 0.15,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.58, 0.80)),
                    child: Text(
                      'LAYER BY LAYER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cascading blinds
            ...List.generate(strips, (i) {
              final delay = i / strips * 0.42;
              final raw = ((lift - delay) / (1 - delay)).clamp(0.0, 1.0);
              final local = _easeOutCubic(raw);
              final stripH = size.height / strips;
              final y = i * stripH - local * (stripH + 24);
              final shade = i.isEven
                  ? const Color(0xFF18181F)
                  : const Color(0xFF121218);
              return Positioned(
                left: 0,
                right: 0,
                top: y,
                height: stripH + 1.5,
                child: Opacity(
                  opacity: (1 - local).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: shade,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- 24. Beacon — soft searchlight locks onto brand ---------------------------

class _BeaconSplash extends StatelessWidget {
  const _BeaconSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sweep = _easeInOutQuint(_seg(t, 0.0, 0.48));
    final lock = _easeOutExpo(_seg(t, 0.38, 0.62));
    final wordIn = _easeOutCubic(_seg(t, 0.52, 0.76));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final beamX = -0.9 + sweep * 1.8;

    return ColoredBox(
      color: const Color(0xFF06060A),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _BeaconBeamPainter(beamX: beamX, intensity: lock),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.72 + lock * 0.28,
                    child: Opacity(
                      opacity: lock,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE4621E)
                                  .withValues(alpha: 0.32 * lock),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.62, 0.84)),
                    child: Text(
                      'GUIDED BY LIGHT',
                      style: TextStyle(
                        color: const Color(0xFFE4621E).withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeaconBeamPainter extends CustomPainter {
  _BeaconBeamPainter({required this.beamX, required this.intensity});

  final double beamX;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * (0.5 + beamX * 0.42);
    final top = Offset(cx, -size.height * 0.05);
    final path = Path()
      ..moveTo(top.dx - size.width * 0.04, top.dy)
      ..lineTo(cx - size.width * 0.22, size.height * 1.05)
      ..lineTo(cx + size.width * 0.22, size.height * 1.05)
      ..close();
    final glow = Paint()
      ..shader = ui.Gradient.linear(
        top,
        Offset(cx, size.height),
        [
          const Color(0x66E4621E),
          const Color(0x22D2364C),
          const Color(0x00A72669),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawPath(path, glow);
    // Soft core wash after lock
    if (intensity > 0.01) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.42),
        size.shortestSide * 0.28 * intensity,
        Paint()
          ..color = const Color(0xFFE4621E).withValues(alpha: 0.10 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeaconBeamPainter old) =>
      old.beamX != beamX || old.intensity != intensity;
}

// --- 25. Ledger — fintech rule lines draw, brand settles ----------------------

class _LedgerSplash extends StatelessWidget {
  const _LedgerSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final draw = _easeInOutCubic(_seg(t, 0.0, 0.48));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF08090C),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _LedgerLinesPainter(progress: draw)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.82 + logoIn * 0.18,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.60, 0.82)),
                    child: Text(
                      'PRECISION LEDGER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerLinesPainter extends CustomPainter {
  _LedgerLinesPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 9;
    for (var i = 0; i < rows; i++) {
      final delay = i / rows * 0.35;
      final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      final y = size.height * (0.18 + i / (rows - 1) * 0.64);
      final w = size.width * 0.72 * _easeOutCubic(local);
      final x0 = (size.width - w) / 2;
      final alpha = 0.06 + 0.10 * local;
      canvas.drawLine(
        Offset(x0, y),
        Offset(x0 + w, y),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = i == 4 ? 1.4 : 0.85
          ..strokeCap = StrokeCap.round,
      );
      if (i == 4 && local > 0.4) {
        canvas.drawLine(
          Offset(x0, y),
          Offset(x0 + w, y),
          Paint()
            ..color = const Color(0xFFE4621E).withValues(alpha: 0.35 * local)
            ..strokeWidth = 1.2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LedgerLinesPainter old) =>
      old.progress != progress;
}

// --- 26. Nova — soft brand wash rings bloom into mark -------------------------

class _NovaSplash extends StatelessWidget {
  const _NovaSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bloom = _easeOutQuint(_seg(t, 0.0, 0.55));
    final logoIn = _easeOutExpo(_seg(t, 0.28, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF050508),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _NovaRingsPainter(bloom: bloom, flow: t),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.55 + logoIn * 0.45,
                    child: Opacity(
                      opacity: logoIn,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.60, 0.82)),
                    child: Text(
                      'IGNITION',
                      style: TextStyle(
                        color: const Color(0xFFD2364C).withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovaRingsPainter extends CustomPainter {
  _NovaRingsPainter({required this.bloom, required this.flow});

  final double bloom;
  final double flow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final maxR = size.shortestSide * 0.55;
    for (var i = 0; i < 5; i++) {
      final delay = i * 0.08;
      final local = ((bloom - delay) / (1 - delay)).clamp(0.0, 1.0);
      final r = maxR * (0.25 + i * 0.18) * local;
      final color = _brandSpectrum[i % _brandSpectrum.length];
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: 0.35 * (1 - local * 0.55)),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = color.withValues(alpha: 0.08 * (1 - local * 0.4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    final pulse = 1 + 0.04 * math.sin(flow * math.pi * 5);
    canvas.drawCircle(
      c,
      maxR * 0.22 * bloom * pulse,
      Paint()
        ..color = const Color(0xFFE4621E).withValues(alpha: 0.14 * bloom)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  @override
  bool shouldRepaint(covariant _NovaRingsPainter old) =>
      old.bloom != bloom || old.flow != flow;
}

// --- 27. Parallax — multi-layer depth drift settle ----------------------------

class _ParallaxSplash extends StatelessWidget {
  const _ParallaxSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final settle = _easeOutQuint(_seg(t, 0.0, 0.58));
    final logoIn = _easeOutExpo(_seg(t, 0.28, 0.55));
    final wordIn = _easeOutCubic(_seg(t, 0.48, 0.72));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    Widget layer({
      required Alignment align,
      required double depth,
      required Color color,
      required double radius,
    }) {
      final drift = (1 - settle) * 48 * depth;
      return Align(
        alignment: align,
        child: Transform.translate(
          offset: Offset(drift * align.x, drift * 0.55),
          child: Opacity(
            opacity: 0.55 + settle * 0.45,
            child: Container(
              width: radius,
              height: radius,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 60,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF07070B),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            layer(
              align: const Alignment(-0.75, -0.55),
              depth: 1.2,
              color: const Color(0xFFE4621E),
              radius: size.shortestSide * 0.42,
            ),
            layer(
              align: const Alignment(0.8, 0.2),
              depth: 0.85,
              color: const Color(0xFFA72669),
              radius: size.shortestSide * 0.36,
            ),
            layer(
              align: const Alignment(-0.35, 0.75),
              depth: 0.55,
              color: const Color(0xFF232C64),
              radius: size.shortestSide * 0.48,
            ),
            Center(
              child: Transform.translate(
                offset: Offset(0, (1 - settle) * 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: logoIn,
                      child: Transform.scale(
                        scale: 0.88 + logoIn * 0.12,
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                    SizedBox(height: logoSize * 0.28),
                    Opacity(
                      opacity: wordIn,
                      child: Text(
                        'TERMINAL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 9,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: _easeOutCubic(_seg(t, 0.58, 0.80)),
                      child: Text(
                        'DEPTH IN MOTION',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 4.5,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 28. Signal — acquisition scan locks onto brand ---------------------------

class _SignalSplash extends StatelessWidget {
  const _SignalSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scan = _easeInOutCubic(_seg(t, 0.0, 0.52));
    final lock = _easeOutExpo(_seg(t, 0.40, 0.65));
    final wordIn = _easeOutCubic(_seg(t, 0.55, 0.78));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF05070A),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _SignalScanPainter(scan: scan, lock: lock),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: lock,
                    child: Transform.scale(
                      scale: 0.78 + lock * 0.22,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.64, 0.84)),
                    child: Text(
                      'SIGNAL ACQUIRED',
                      style: TextStyle(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.55),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalScanPainter extends CustomPainter {
  _SignalScanPainter({required this.scan, required this.lock});

  final double scan;
  final double lock;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft grid
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.7;
    for (var i = 1; i < 12; i++) {
      final x = size.width * i / 12;
      final y = size.height * i / 12;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final y = size.height * (0.12 + scan * 0.76);
    final scanPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y - 18),
        Offset(0, y + 18),
        [
          Colors.transparent,
          const Color(0x88E4621E),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, y - 18, size.width, 36), scanPaint);
    canvas.drawLine(
      Offset(size.width * 0.08, y),
      Offset(size.width * 0.92, y),
      Paint()
        ..color = const Color(0xFFE4621E).withValues(alpha: 0.75)
        ..strokeWidth = 1.2,
    );

    // Lock brackets
    if (lock > 0.01) {
      final c = Offset(size.width / 2, size.height * 0.42);
      final arm = 28.0 * lock;
      final gap = 52.0;
      final p = Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.7 * lock)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      // TL
      canvas.drawLine(c + Offset(-gap, -gap), c + Offset(-gap + arm, -gap), p);
      canvas.drawLine(c + Offset(-gap, -gap), c + Offset(-gap, -gap + arm), p);
      // TR
      canvas.drawLine(c + Offset(gap, -gap), c + Offset(gap - arm, -gap), p);
      canvas.drawLine(c + Offset(gap, -gap), c + Offset(gap, -gap + arm), p);
      // BL
      canvas.drawLine(c + Offset(-gap, gap), c + Offset(-gap + arm, gap), p);
      canvas.drawLine(c + Offset(-gap, gap), c + Offset(-gap, gap - arm), p);
      // BR
      canvas.drawLine(c + Offset(gap, gap), c + Offset(gap - arm, gap), p);
      canvas.drawLine(c + Offset(gap, gap), c + Offset(gap, gap - arm), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalScanPainter old) =>
      old.scan != scan || old.lock != lock;
}

// --- 29. Vault — concentric frames dilate open to brand -----------------------

class _VaultSplash extends StatelessWidget {
  const _VaultSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final open = _easeInOutQuint(_seg(t, 0.0, 0.55));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.60));
    final wordIn = _easeOutCubic(_seg(t, 0.52, 0.76));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF09090B),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _VaultFramesPainter(open: open)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.8 + logoIn * 0.2,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.62, 0.84)),
                    child: Text(
                      'SECURE ACCESS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultFramesPainter extends CustomPainter {
  _VaultFramesPainter({required this.open});
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 6; i++) {
      final delay = i * 0.06;
      final local = ((open - delay) / (1 - delay)).clamp(0.0, 1.0);
      final base = size.shortestSide * (0.12 + i * 0.09);
      final expand = base + local * size.shortestSide * 0.55;
      final rect = Rect.fromCenter(
        center: c,
        width: expand * 1.15,
        height: expand * 0.78,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(18 + i * 4.0),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: 0.12 * (1 - local * 0.7)),
      );
      if (i == 2) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFE4621E)
                .withValues(alpha: 0.22 * (1 - local * 0.5))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VaultFramesPainter old) => old.open != open;
}
