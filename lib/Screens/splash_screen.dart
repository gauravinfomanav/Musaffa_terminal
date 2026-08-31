import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/flower_logo_cache.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

/// Full-screen premium launch splash — market ambient motion, brand mark,
/// refined loader. Waits for [isWaiting] then exits with fade/scale.
class PremiumLaunchSplash extends StatefulWidget {
  const PremiumLaunchSplash({
    super.key,
    required this.isWaiting,
    required this.onFinished,
    this.minimumDuration = const Duration(milliseconds: 2600),
    this.exitDuration = const Duration(milliseconds: 720),
  });

  final bool isWaiting;
  final VoidCallback onFinished;
  final Duration minimumDuration;
  final Duration exitDuration;

  @override
  State<PremiumLaunchSplash> createState() => _PremiumLaunchSplashState();
}

class _PremiumLaunchSplashState extends State<PremiumLaunchSplash>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _ambient;
  late final AnimationController _candles;
  late final AnimationController _loader;
  late final AnimationController _exit;

  late final Animation<double> _screenFade;
  late final Animation<double> _irisReveal;
  late final Animation<double> _blurReveal;
  late final Animation<double> _sweepReveal;
  late final Animation<double> _bgReveal;
  late final Animation<double> _chartReveal;
  late final Animation<double> _glowReveal;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlide;
  late final Animation<double> _logoRotate;
  late final Animation<double> _logoGlow;
  late final Animation<double> _pulseRing;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _wordmarkSlide;
  late final Animation<double> _wordmarkReveal;
  late final Animation<double> _loaderFade;
  late final Animation<double> _loaderScale;
  late final Animation<double> _footerFade;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitBlur;

  bool _minElapsed = false;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _candles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _exit = AnimationController(
      vsync: this,
      duration: widget.exitDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished();
        }
      });

    _screenFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );
    _irisReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.04, 0.52, curve: Curves.easeOutCubic),
    );
    _blurReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.08, 0.58, curve: Curves.easeOutCubic),
    );
    _sweepReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.22, 0.48, curve: Curves.easeInOutCubic),
    );
    _bgReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.06, 0.46, curve: Curves.easeOutCubic),
    );
    _chartReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.10, 0.68, curve: Curves.easeOutCubic),
    );
    _glowReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.14, 0.62, curve: Curves.easeOutCubic),
    );
    _logoFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.28, 0.62, curve: Curves.easeOut),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.38, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.24, 0.74, curve: Curves.linear),
      ),
    );
    _logoSlide = Tween<double>(begin: 36, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.26, 0.68, curve: Curves.easeOutCubic),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.14, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.24, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _logoGlow = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.30, 0.78, curve: Curves.easeOut),
    );
    _pulseRing = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.26, 0.82, curve: Curves.easeOutCubic),
    );
    _wordmarkFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.38, 0.74, curve: Curves.easeOut),
    );
    _wordmarkSlide = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.36, 0.76, curve: Curves.easeOutCubic),
      ),
    );
    _wordmarkReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.38, 0.72, curve: Curves.easeOutCubic),
    );
    _loaderFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.52, 0.86, curve: Curves.easeOut),
    );
    _loaderScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.50, 0.88, curve: Curves.linear),
      ),
    );
    _footerFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.62, 0.94, curve: Curves.easeOut),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exit, curve: Curves.easeInOutCubic),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
    );
    _exitBlur = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
    );

    _enter.forward();
    Future.delayed(widget.minimumDuration, () {
      if (!mounted) return;
      _minElapsed = true;
      _tryExit();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hi = FlowerLogoImageCache.hiSizeFor(context, 72 * 1.1);
    FlowerLogoImageCache.warmUp(hi);
  }

  @override
  void didUpdateWidget(covariant PremiumLaunchSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWaiting && !widget.isWaiting) {
      _tryExit();
    }
  }

  void _tryExit() {
    if (_exiting || !_minElapsed || widget.isWaiting) return;
    _exiting = true;
    setState(() {});
    _exit.forward(from: 0);
  }

  @override
  void dispose() {
    _enter.dispose();
    _ambient.dispose();
    _candles.dispose();
    _loader.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AuthSplashPalette.of(isDark);

    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final blur = _exiting ? _exitBlur.value : 0.0;
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Opacity(
            opacity: _exiting ? _exitOpacity.value : 1.0,
            child: Transform.scale(
              scale: _exiting ? _exitScale.value : 1.0,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _enter,
        builder: (context, child) {
          return Opacity(
            opacity: _exiting ? 1.0 : _screenFade.value,
            child: child,
          );
        },
        child: Material(
          color: palette.bgBase,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: isDark ? const Color(0xFF050608) : const Color(0xFF0F172A),
              ),
              AnimatedBuilder(
                animation: _enter,
                builder: (context, child) {
                  final blurSigma = (1 - _blurReveal.value) * 14;
                  return ClipPath(
                    clipper: _IrisClipper(progress: _irisReveal.value),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: blurSigma,
                        sigmaY: blurSigma,
                      ),
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FadeTransition(
                      opacity: _bgReveal,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [palette.bgTop, palette.bgMid, palette.bgBottom],
                            stops: const [0.0, 0.52, 1.0],
                          ),
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _bgReveal,
                      child: AnimatedBuilder(
                        animation: _ambient,
                        builder: (context, _) {
                          final t = _ambient.value;
                          return Stack(
                            children: [
                              Positioned(
                                top: -80 + 18 * math.sin(t * math.pi),
                                right: -60,
                                child: _SplashOrb(
                                  size: 280,
                                  color: palette.accentGlow
                                      .withValues(alpha: isDark ? 0.22 : 0.14),
                                ),
                              ),
                              Positioned(
                                bottom: -100 + 14 * math.cos(t * math.pi),
                                left: -50,
                                child: _SplashOrb(
                                  size: 320,
                                  color: palette.navyGlow
                                      .withValues(alpha: isDark ? 0.28 : 0.10),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    FadeTransition(
                      opacity: _chartReveal,
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_ambient, _candles, _enter]),
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _MarketAmbientPainter(
                                phase: _ambient.value,
                                candlePhase: _candles.value,
                                isDark: isDark,
                                palette: palette,
                                reveal: _chartReveal.value,
                              ),
                              size: Size.infinite,
                            );
                          },
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _glowReveal,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.68 + _glowReveal.value * 0.32,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: _glowReveal.value,
                            child: child,
                          ),
                        );
                      },
                      child: Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.42,
                                colors: [
                                  const Color(0xFFE7DFE0)
                                      .withValues(alpha: isDark ? 0.10 : 0.16),
                                  const Color(0xFFE7DFE0)
                                      .withValues(alpha: isDark ? 0.05 : 0.08),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.46, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _bgReveal,
                      child: Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.95,
                                colors: [
                                  Colors.transparent,
                                  (isDark ? Colors.black : const Color(0xFF0F172A))
                                      .withValues(alpha: isDark ? 0.42 : 0.06),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _sweepReveal,
                builder: (context, _) {
                  if (_sweepReveal.value <= 0.01) {
                    return const SizedBox.shrink();
                  }
                  return IgnorePointer(
                    child: CustomPaint(
                      painter: _LightSweepPainter(
                        progress: _sweepReveal.value,
                        isDark: isDark,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _logoFade,
                        child: AnimatedBuilder(
                          animation: _enter,
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(0, _logoSlide.value),
                              child: Transform.rotate(
                                angle: _logoRotate.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_pulseRing.value > 0.02)
                                          CustomPaint(
                                            size: const Size(120, 120),
                                            painter: _SplashPulseRingsPainter(
                                              strength: _pulseRing.value,
                                              isDark: isDark,
                                            ),
                                          ),
                                        _BrandMark(
                                          isDark: isDark,
                                          glowStrength: _logoGlow.value,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      FadeTransition(
                        opacity: _wordmarkFade,
                        child: AnimatedBuilder(
                          animation: _enter,
                          builder: (context, _) {
                            final reveal = _wordmarkReveal.value.clamp(0.0, 1.0);
                            return Transform.translate(
                              offset: Offset(
                                _wordmarkSlide.value * 0.12,
                                _wordmarkSlide.value,
                              ),
                              child: ShaderMask(
                                blendMode: BlendMode.dstIn,
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: const [
                                      Colors.white,
                                      Colors.white,
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, reveal, reveal + 0.001],
                                  ).createShader(bounds);
                                },
                                child: Transform.translate(
                                  offset: const Offset(3, 0),
                                  child: MusaffaLogo(
                                    height: MediaQuery.sizeOf(context).width < 480
                                        ? 28
                                        : 34,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 36),
                      FadeTransition(
                        opacity: _loaderFade,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_loader, _enter]),
                          builder: (context, _) {
                            return Transform.scale(
                              scale: _loaderScale.value,
                              child: _PremiumLoaderRing(
                                progress: _loader.value,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: FadeTransition(
                  opacity: _footerFade,
                  child: Text(
                    Constants.appName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w600,
                      color: palette.muted.withValues(alpha: 0.55),
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
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

class AuthSplashPalette {
  const AuthSplashPalette({
    required this.bgBase,
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.grid,
    required this.line,
    required this.candleUp,
    required this.candleDown,
    required this.accentGlow,
    required this.navyGlow,
    required this.muted,
  });

  final Color bgBase;
  final Color bgTop;
  final Color bgMid;
  final Color bgBottom;
  final Color grid;
  final Color line;
  final Color candleUp;
  final Color candleDown;
  final Color accentGlow;
  final Color navyGlow;
  final Color muted;

  factory AuthSplashPalette.of(bool isDark) {
    return AuthSplashPalette(
      bgBase: isDark ? const Color(0xFF0A0C12) : const Color(0xFFF4F6FA),
      bgTop: isDark ? const Color(0xFF0A0C12) : const Color(0xFFF7F9FC),
      bgMid: isDark ? const Color(0xFF0E1118) : const Color(0xFFEEF2F7),
      bgBottom: isDark ? const Color(0xFF12151E) : const Color(0xFFE7ECF4),
      grid: isDark
          ? Colors.white.withValues(alpha: 0.035)
          : const Color(0xFF0F172A).withValues(alpha: 0.045),
      line: isDark
          ? const Color(0xFFE4621E).withValues(alpha: 0.55)
          : const Color(0xFFE4621E).withValues(alpha: 0.42),
      candleUp: isDark
          ? const Color(0xFF00C087)
          : const Color(0xFF059669),
      candleDown: isDark
          ? const Color(0xFFFF4757)
          : const Color(0xFFE53935),
      accentGlow: const Color(0xFFE4621E),
      navyGlow: const Color(0xFF1F2760),
      muted: HomeUi.muted(isDark),
    );
  }
}

class _BrandMark extends StatefulWidget {
  const _BrandMark({
    required this.isDark,
    this.glowStrength = 1.0,
  });

  final bool isDark;
  final double glowStrength;

  @override
  State<_BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<_BrandMark> {
  static const double _size = 72;

  ui.Image? _flowerImage;
  double? _loadedHi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hi = FlowerLogoImageCache.hiSizeFor(context, _size * 1.1);
    if (_loadedHi == hi && _flowerImage != null) return;
    _loadedHi = hi;
    _flowerImage = FlowerLogoImageCache.imageFor(hi);
    FlowerLogoImageCache.warmUp(hi).then((image) {
      if (!mounted || image == null || _loadedHi != hi) return;
      setState(() => _flowerImage = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    const size = _size;
    final glow = widget.glowStrength.clamp(0.0, 1.0);
    final image = _flowerImage;
    final hi = _loadedHi;

    return SizedBox(
      width: size + 24,
      height: size + 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: glow,
            child: Container(
              width: size + 16,
              height: size + 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE4621E)
                        .withValues(alpha: (widget.isDark ? 0.18 : 0.12) * glow),
                    blurRadius: 24 + glow * 16,
                    spreadRadius: glow * 3,
                  ),
                ],
              ),
            ),
          ),
          if (image != null && hi != null)
            FlowerLogoImageCache.smoothImage(
              image: image,
              displaySize: size,
              hi: hi,
            )
          else
            const SizedBox(width: size, height: size),
        ],
      ),
    );
  }
}

class _PremiumLoaderRing extends StatelessWidget {
  const _PremiumLoaderRing({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _LoaderRingPainter(
          progress: progress,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _LoaderRingPainter extends CustomPainter {
  _LoaderRingPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final ringRect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 2.2;
    const trackColor = Color(0xFFE7DFE0);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    final sweep = math.pi * 1.35;
    final start = -math.pi / 2 + progress * math.pi * 2;

    canvas.drawArc(
      ringRect,
      start,
      sweep,
      false,
      Paint()
        ..shader = HomeUi.brandGradient.createShader(ringRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LoaderRingPainter old) =>
      old.progress != progress || old.isDark != isDark;
}

class _MarketAmbientPainter extends CustomPainter {
  _MarketAmbientPainter({
    required this.phase,
    required this.candlePhase,
    required this.isDark,
    required this.palette,
    this.reveal = 1.0,
  });

  final double phase;
  final double candlePhase;
  final bool isDark;
  final AuthSplashPalette palette;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = reveal.clamp(0.0, 1.0);
    if (progress <= 0) return;

    canvas.save();
    final clipTop = size.height * (1 - progress);
    canvas.clipRect(Rect.fromLTWH(0, clipTop, size.width, size.height - clipTop));

    _paintGrid(canvas, size, progress);
    canvas.save();
    canvas.clipPath(_chartClipPath(size));
    _paintPriceLine(canvas, size, progress);
    _paintCandles(canvas, size, progress);
    canvas.restore();
    canvas.restore();
  }

  Path _chartClipPath(Size size) {
    final exclusion = _logoExclusionRect(size);
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          exclusion,
          Radius.elliptical(exclusion.width * 0.2, exclusion.height * 0.26),
        ),
      )
      ..fillType = PathFillType.evenOdd;
  }

  Rect _logoExclusionRect(Size size) {
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: math.min(size.width * 0.52, 300),
      height: math.min(size.height * 0.28, 220),
    );
  }

  void _paintGrid(Canvas canvas, Size size, double progress) {
    const spacing = 48.0;
    final paint = Paint()
      ..color = palette.grid.withValues(alpha: palette.grid.a * progress);

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintPriceLine(Canvas canvas, Size size, double progress) {
    final path = Path();
    const segments = 48;
    final baseY = size.height * 0.74;
    final amplitude = size.height * 0.048;
    final scroll = phase * size.width * 0.35;

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final x = t * size.width;
      final wave = math.sin((t * 4.2 - phase * 2) * math.pi) * 0.55 +
          math.sin((t * 7.1 + phase * 1.4) * math.pi) * 0.28;
      final y = baseY + wave * amplitude + scroll * 0.02 * math.sin(t * math.pi);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevT = (i - 1) / segments;
        final prevX = prevT * size.width;
        final prevWave = math.sin((prevT * 4.2 - phase * 2) * math.pi) * 0.55 +
            math.sin((prevT * 7.1 + phase * 1.4) * math.pi) * 0.28;
        final prevY = baseY + prevWave * amplitude + scroll * 0.02 * math.sin(prevT * math.pi);
        final cx = (prevX + x) / 2;
        path.quadraticBezierTo(cx, prevY, x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillRect = Rect.fromLTWH(
      0,
      baseY - amplitude,
      size.width,
      size.height - baseY + amplitude,
    );
    final lineShaderRect = Rect.fromLTWH(
      0,
      baseY - amplitude * 1.2,
      size.width,
      amplitude * 2.4,
    );

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HomeUi.brandGradient.colors.first
                .withValues(alpha: (isDark ? 0.14 : 0.10) * progress),
            HomeUi.brandGradient.colors[2]
                .withValues(alpha: (isDark ? 0.08 : 0.05) * progress),
            HomeUi.brandGradient.colors.last.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(fillRect),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = HomeUi.brandGradient.createShader(lineShaderRect)
        ..color = Color.fromRGBO(255, 255, 255, progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintCandles(Canvas canvas, Size size, double progress) {
    const candleW = 7.0;
    const gap = 11.0;
    const pitch = candleW + gap;
    final baseY = size.height * 0.84;

    // Continuous right drift — no discrete jumps.
    final scroll = candlePhase * pitch * 6;
    final offset = scroll % pitch;
    final firstIndex = ((-offset) / pitch).floor() - 1;
    final lastIndex = firstIndex + (size.width / pitch).ceil() + 3;

    final t = candlePhase * 2 * math.pi;

    for (int idx = firstIndex; idx <= lastIndex; idx++) {
      final x = idx * pitch + offset;
      if (x < -candleW * 2 || x > size.width + candleW * 2) continue;

      // Stable bull/bear per candle — color does not flicker while scrolling.
      final bullish = ((idx * 13 + 5) % 7) < 4;

      // Smooth breathing heights tied to time + index.
      final bodyWave = math.sin(idx * 0.72 + t * 0.55);
      final wickWave = math.sin(idx * 0.91 + t * 0.42 + 0.8);
      final bodyH = 9 + 14 * (0.5 + 0.5 * bodyWave);
      final wickH = 3 + 7 * (0.5 + 0.5 * wickWave);

      final bodyColor = bullish ? palette.candleUp : palette.candleDown;
      final wickColor = bodyColor.withValues(alpha: (isDark ? 0.72 : 0.68) * progress);
      final bodyFill = bodyColor.withValues(alpha: (isDark ? 0.92 : 0.88) * progress);

      final bodyTop = baseY - (bullish ? bodyH : 0);
      final bodyBottom = baseY + (bullish ? 0 : bodyH);

      canvas.drawLine(
        Offset(x + candleW / 2, bodyTop - wickH),
        Offset(x + candleW / 2, bodyBottom + wickH),
        Paint()
          ..color = wickColor
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          bodyTop,
          x + candleW,
          bodyBottom,
          const Radius.circular(1.4),
        ),
        Paint()..color = bodyFill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarketAmbientPainter old) =>
      old.phase != phase ||
      old.candlePhase != candlePhase ||
      old.isDark != isDark ||
      old.reveal != reveal;
}

class _SplashOrb extends StatelessWidget {
  const _SplashOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Expanding circular iris — cinematic scene reveal from center.
class _IrisClipper extends CustomClipper<Path> {
  const _IrisClipper({required this.progress});

  final double progress;

  @override
  Path getClip(Size size) {
    if (progress >= 1) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height) /
        2 *
        1.1;
    final radius = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0)) * maxR;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _IrisClipper old) => old.progress != progress;
}

/// One-shot diagonal light sweep across the splash on enter.
class _LightSweepPainter extends CustomPainter {
  _LightSweepPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.01) return;

    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final bandCenter = -diagonal * 0.35 + t * diagonal * 1.35;
    final fade = (1 - (t - 0.55).abs() * 2).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 5);
    canvas.translate(-size.width / 2, -size.height / 2);

    final rect = Rect.fromLTWH(
      bandCenter,
      -size.height * 0.15,
      diagonal * 0.28,
      size.height * 1.3,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            (isDark ? Colors.white : const Color(0xFFE7DFE0))
                .withValues(alpha: 0.0),
            (isDark ? Colors.white : const Color(0xFFE7DFE0))
                .withValues(alpha: (isDark ? 0.14 : 0.22) * fade),
            const Color(0xFFE4681F).withValues(alpha: 0.10 * fade),
            Colors.transparent,
          ],
          stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LightSweepPainter old) =>
      old.progress != progress || old.isDark != isDark;
}

/// Brand sonar rings — pulse outward when the logo lands.
class _SplashPulseRingsPainter extends CustomPainter {
  _SplashPulseRingsPainter({required this.strength, required this.isDark});

  final double strength;
  final bool isDark;

  static const int _ringCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final t = strength.clamp(0.0, 1.0);
    if (t <= 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.46;

    for (int i = 0; i < _ringCount; i++) {
      final ringT = ((t - i * 0.14) / 0.72).clamp(0.0, 1.0);
      if (ringT <= 0) continue;

      final eased = Curves.easeOutCubic.transform(ringT);
      final radius = 18 + eased * maxR;
      final fade = (1 - ringT);
      final alpha = fade * fade * 0.32;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFE4681F).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );

      final innerAlpha = alpha * 0.45;
      if (innerAlpha > 0.008) {
        canvas.drawCircle(
          center,
          radius - 1.2,
          Paint()
            ..color = const Color(0xFFE7DFE0).withValues(alpha: innerAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.65,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPulseRingsPainter old) =>
      old.strength != strength || old.isDark != isDark;
}

/// Legacy overlay — kept for optional in-app use.
class SplashOverlay extends StatefulWidget {
  final Widget child;
  final Duration displayDuration;
  final Duration fadeDuration;
  final double blurSigma;
  final double backgroundOpacity;
  final Widget? splashContent;

  const SplashOverlay({
    super.key,
    required this.child,
    this.displayDuration = const Duration(seconds: 3),
    this.fadeDuration = const Duration(milliseconds: 400),
    this.blurSigma = 4,
    this.backgroundOpacity = 0.35,
    this.splashContent,
  });

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _hideSplash();
  }

  Future<void> _hideSplash() async {
    await Future.delayed(widget.displayDuration);
    if (!mounted) return;
    await _fadeController.forward();
    if (!mounted) return;
    setState(() {
      _showSplash = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _defaultSplashContent() {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _LoaderRingPainter(
          progress: 0.25,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final splashTint = (Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white)
        .withValues(alpha: widget.backgroundOpacity);

    return Stack(
      children: [
        widget.child,
        if (_showSplash)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: widget.blurSigma,
                    sigmaY: widget.blurSigma,
                  ),
                  child: Container(
                    color: splashTint,
                    alignment: Alignment.center,
                    child: widget.splashContent ?? _defaultSplashContent(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
