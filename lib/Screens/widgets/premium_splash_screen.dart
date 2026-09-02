import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/flower_logo_cache.dart';

/// Full-screen premium splash overlay — port of React SplashScreen component.
class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({
    super.key,
    required this.active,
    required this.onComplete,
    this.isWaiting = false,
  });

  final bool active;
  final VoidCallback onComplete;
  final bool isWaiting;

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

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

class _PremiumLaunchSplashState extends State<PremiumLaunchSplash> {
  @override
  Widget build(BuildContext context) {
    return PremiumSplashScreen(
      active: true,
      isWaiting: widget.isWaiting,
      onComplete: widget.onFinished,
    );
  }
}

enum _SplashPhase { idle, reveal, enter, hold, exit }

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  static const _revealMs = 1100;
  static const _enterMs = 2200;
  static const _holdMs = 1600;
  static const _exitMs = 700;
  static const _chartLineMs = _revealMs + _enterMs + _holdMs;
  static const _chartBottomFraction = 0.2;
  static const _chartHeight = 220.0;
  static const _chartPeakRatio = 0.45;
  static const _contentGapAbovePeak = 16.0;
  static const _contentLiftOffset = 40.0;

  static double _contentBottomOffset(double height) =>
      height * _chartBottomFraction +
      _chartHeight * (1 - _chartPeakRatio) +
      _contentGapAbovePeak +
      _contentLiftOffset;

  static const _brandColors = [
    Color(0xFFE4621E),
    Color(0xFFD2364C),
    Color(0xFFA72669),
    Color(0xFF6A2C72),
    Color(0xFF232C64),
  ];

  static const _tickers = [
    ('EUR/USD', '+0.42%'),
    ('BTC/USD', '+1.28%'),
    ('AAPL', '+0.85%'),
    ('SPX', '+0.31%'),
    ('GOLD', '+0.12%'),
    ('ETH/USD', '+2.14%'),
  ];

  _SplashPhase _phase = _SplashPhase.idle;
  late final AnimationController _master;
  late final AnimationController _ambient;
  late final AnimationController _ticker;
  late final AnimationController _orbit;
  late final AnimationController _halo;
  late final AnimationController _shimmer;
  late final AnimationController _statusPulse;
  late final AnimationController _chartLine;
  late final Animation<double> _chartLineProgress;

  bool _pendingComplete = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(vsync: this);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _statusPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _chartLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _chartLineMs),
    );
    _chartLineProgress = CurvedAnimation(
      parent: _chartLine,
      curve: Curves.easeInOutCubic,
    );

    if (widget.active) _startSequence();
  }

  @override
  void didUpdateWidget(covariant PremiumSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _startSequence();
    } else if (oldWidget.active && !widget.active) {
      _reset();
    } else if (oldWidget.isWaiting && !widget.isWaiting && _pendingComplete) {
      _beginExit();
    }
  }

  void _reset() {
    _master.stop();
    _ambient.stop();
    _ticker.stop();
    _orbit.stop();
    _halo.stop();
    _shimmer.stop();
    _statusPulse.stop();
    _chartLine.stop();
    _chartLine.reset();
    _pendingComplete = false;
    _completed = false;
    setState(() => _phase = _SplashPhase.idle);
  }

  Future<void> _startSequence() async {
    _reset();
    setState(() => _phase = _SplashPhase.reveal);

    _ambient.repeat();
    _ticker.repeat();
    _orbit.repeat();
    _halo.repeat();
    _shimmer.repeat();
    _statusPulse.repeat(reverse: true);
    _chartLine.forward(from: 0);

    await Future<void>.delayed(const Duration(milliseconds: _revealMs));
    if (!mounted || !widget.active) return;
    setState(() => _phase = _SplashPhase.enter);

    await Future<void>.delayed(const Duration(milliseconds: _enterMs));
    if (!mounted || !widget.active) return;
    setState(() => _phase = _SplashPhase.hold);

    await Future<void>.delayed(const Duration(milliseconds: _holdMs));
    if (!mounted || !widget.active) return;
    _tryComplete();
  }

  void _tryComplete() {
    if (_completed) return;
    if (widget.isWaiting) {
      _pendingComplete = true;
      return;
    }
    _beginExit();
  }

  Future<void> _beginExit() async {
    if (_completed || !mounted) return;
    _pendingComplete = false;
    setState(() => _phase = _SplashPhase.exit);

    await Future<void>.delayed(const Duration(milliseconds: _exitMs));
    if (!mounted) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _master.dispose();
    _ambient.dispose();
    _ticker.dispose();
    _orbit.dispose();
    _halo.dispose();
    _shimmer.dispose();
    _statusPulse.dispose();
    _chartLine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && _phase == _SplashPhase.idle) {
      return const SizedBox.shrink();
    }

    final displayPhase =
        widget.active && _phase == _SplashPhase.idle ? _SplashPhase.reveal : _phase;
    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.width * 0.18).clamp(76.0, 100.0);

    return SizedBox.expand(
      child: Material(
        type: MaterialType.transparency,
        child: _OverlayEntrance(
          phase: displayPhase,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.4, -1),
                    end: Alignment(0.4, 1),
                    colors: [Color(0xFF08060F), Color(0xFF0D0A18), Color(0xFF0A0816)],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              if (displayPhase == _SplashPhase.reveal) ...[
                _IntroBurst(phase: displayPhase),
                _IntroSweep(phase: displayPhase),
                _IntroFlash(phase: displayPhase),
              ],
              _Vignette(),
              _BackgroundLayer(
                phase: displayPhase,
                ambient: _ambient,
                orbit: _orbit,
                chartLine: _chartLineProgress,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: _contentBottomOffset(size.height),
                child: _ContentLayer(
                  phase: displayPhase,
                  logoSize: logoSize,
                  halo: _halo,
                  orbit: _orbit,
                  shimmer: _shimmer,
                  statusPulse: _statusPulse,
                ),
              ),
              _TickerStrip(phase: displayPhase, ticker: _ticker),
              _BottomProgressBar(phase: displayPhase),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashKeyframes {
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double entranceScale(double t) {
    if (t <= 0.35) return _lerp(0, 0.56, t / 0.35);
    if (t <= 0.65) return _lerp(0.56, 1.04, (t - 0.35) / 0.30);
    if (t <= 0.82) return _lerp(1.04, 0.985, (t - 0.65) / 0.17);
    return _lerp(0.985, 1.0, (t - 0.82) / 0.18);
  }

  static double entranceOpacity(double t) {
    if (t <= 0.35) return _lerp(0, 0.85, t / 0.35);
    return _lerp(0.85, 1.0, (t - 0.35) / 0.65);
  }

  static double entranceBlur(double t) {
    if (t <= 0.35) return _lerp(20, 10, t / 0.35);
    if (t <= 0.65) return _lerp(10, 3, (t - 0.35) / 0.30);
    if (t <= 0.82) return _lerp(3, 0, (t - 0.65) / 0.17);
    return 0;
  }

  static double entranceRadiusPercent(double t) {
    if (t <= 0.35) return _lerp(50, 22, t / 0.35);
    if (t <= 0.65) return _lerp(22, 6, (t - 0.35) / 0.30);
    if (t <= 0.82) return _lerp(6, 0, (t - 0.65) / 0.17);
    return 0;
  }

  static double exitScale(double t) {
    if (t <= 0.3) return _lerp(1.0, 1.02, t / 0.3);
    return _lerp(1.02, 0, (t - 0.3) / 0.7);
  }

  static double exitBlur(double t) {
    if (t <= 0.3) return _lerp(0, 2, t / 0.3);
    return _lerp(2, 18, (t - 0.3) / 0.7);
  }

  static double exitRadiusPercent(double t) {
    if (t <= 0.3) return _lerp(0, 8, t / 0.3);
    return _lerp(8, 50, (t - 0.3) / 0.7);
  }
}

class _OverlayEntrance extends StatelessWidget {
  const _OverlayEntrance({required this.phase, required this.child});

  final _SplashPhase phase;
  final Widget child;

  static const _easePremium = Cubic(0.16, 1, 0.3, 1);

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide;

    if (phase == _SplashPhase.reveal) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: _easePremium,
        builder: (context, t, child) {
          final scale = _SplashKeyframes.entranceScale(t);
          final blur = _SplashKeyframes.entranceBlur(t);
          final radius = side * _SplashKeyframes.entranceRadiusPercent(t) / 100;
          return Opacity(
            opacity: _SplashKeyframes.entranceOpacity(t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.04),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: child,
      );
    }

    if (phase == _SplashPhase.exit) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOut,
        builder: (context, t, child) {
          final scale = _SplashKeyframes.exitScale(t);
          final blur = _SplashKeyframes.exitBlur(t);
          final radius = side * _SplashKeyframes.exitRadiusPercent(t) / 100;
          return Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: child,
      );
    }

    return child;
  }
}

class _DelayedReveal extends StatefulWidget {
  const _DelayedReveal({
    required this.delay,
    required this.duration,
    required this.builder,
  });

  final Duration delay;
  final Duration duration;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<_DelayedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const _curve = Cubic(0.16, 1, 0.3, 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _controller, curve: _curve),
      builder: (context, _) => widget.builder(context, _controller.value),
    );
  }
}

class _IntroBurst extends StatelessWidget {
  const _IntroBurst({required this.phase});
  final _SplashPhase phase;

  @override
  Widget build(BuildContext context) {
    return _DelayedReveal(
      delay: const Duration(milliseconds: 150),
      duration: const Duration(milliseconds: 1100),
      builder: (context, t) {
        if (t <= 0.01) return const SizedBox.shrink();
        final opacity = t < 0.7 ? 0.9 - t * 0.55 : (1 - t) * 0.35;
        return IgnorePointer(
          child: Center(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: t,
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 2.4,
                  height: MediaQuery.sizeOf(context).width * 2.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 2, color: const Color(0xFFE4621E).withValues(alpha: 0.5)),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF08060F),
                        const Color(0xFF08060F).withValues(alpha: 0.95),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IntroSweep extends StatelessWidget {
  const _IntroSweep({required this.phase});
  final _SplashPhase phase;

  @override
  Widget build(BuildContext context) {
    return _DelayedReveal(
      delay: const Duration(milliseconds: 450),
      duration: const Duration(milliseconds: 850),
      builder: (context, t) {
        final x = -1.2 + t * 2.4;
        return IgnorePointer(
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(0, 3, x * MediaQuery.sizeOf(context).width)
              ..rotateZ(-0.21),
            child: Container(
              width: MediaQuery.sizeOf(context).width * 1.4,
              height: MediaQuery.sizeOf(context).height * 1.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE4621E).withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.14),
                    const Color(0xFFA72669).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.42, 0.47, 0.5, 0.53, 0.58],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IntroFlash extends StatelessWidget {
  const _IntroFlash({required this.phase});
  final _SplashPhase phase;

  @override
  Widget build(BuildContext context) {
    return _DelayedReveal(
      delay: const Duration(milliseconds: 250),
      duration: const Duration(milliseconds: 1000),
      builder: (context, t) {
        final opacity = t < 0.3 ? t / 0.3 : 1 - (t - 0.3) / 0.7;
        final scale = 0.6 + t * 0.6;
        return IgnorePointer(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      const Color(0xFFE4621E).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.65],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Vignette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.16),
            radius: 0.95,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
            stops: const [0.25, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({
    required this.phase,
    required this.ambient,
    required this.orbit,
    required this.chartLine,
  });

  final _SplashPhase phase;
  final AnimationController ambient;
  final AnimationController orbit;
  final Animation<double> chartLine;

  @override
  Widget build(BuildContext context) {
    final bgVisible = phase != _SplashPhase.idle;
    final detailsVisible = phase == _SplashPhase.enter ||
        phase == _SplashPhase.hold ||
        phase == _SplashPhase.exit;

    return _DelayedReveal(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 1000),
      builder: (context, revealT) {
        final opacity = bgVisible ? revealT.clamp(0.0, 1.0) : 0.0;
        final scale = bgVisible ? 0.6 + revealT * 0.4 : 0.6;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: ambient,
                  builder: (context, _) {
                    final t = ambient.value;
                    return Stack(
                      children: [
                        _BlurOrb(
                          top: 0.2 + 0.02 * math.sin(t * math.pi * 2),
                          left: 0.25,
                          size: 320,
                          color: const Color(0xFFE4621E).withValues(alpha: detailsVisible ? 0.35 : 0),
                        ),
                        _BlurOrb(
                          top: 0.35 + 0.02 * math.cos(t * math.pi * 2),
                          right: 0.2,
                          size: 280,
                          color: const Color(0xFFA72669).withValues(alpha: detailsVisible ? 0.3 : 0),
                        ),
                        _BlurOrb(
                          bottom: 0.15,
                          left: 0.4,
                          size: 360,
                          color: const Color(0xFF232C64).withValues(alpha: detailsVisible ? 0.35 : 0),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.sizeOf(context).height *
                      _PremiumSplashScreenState._chartBottomFraction,
                  height: _PremiumSplashScreenState._chartHeight,
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([chartLine, ambient]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ChartScenePainter(
                            progress: chartLine.value.clamp(0.0, 1.0),
                            flow: ambient.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.sizeOf(context).height * 0.16,
                  left: 0,
                  right: 0,
                  child: _DataStreamBars(active: detailsVisible),
                ),
                if (detailsVisible) _ParticlesLayer(active: detailsVisible),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top != null ? MediaQuery.sizeOf(context).height * top! : null,
      bottom: bottom != null ? MediaQuery.sizeOf(context).height * bottom! : null,
      left: left != null ? MediaQuery.sizeOf(context).width * left! : null,
      right: right != null ? MediaQuery.sizeOf(context).width * right! : null,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
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
      ),
    );
  }
}

class _ChartScenePainter extends CustomPainter {
  _ChartScenePainter({required this.progress, required this.flow});

  final double progress;
  final double flow;

  static const int _totalPoints = 100;

  List<double> _generatePrices({required int seed, double baseline = 180}) {
    final rng = math.Random(seed);
    final prices = <double>[];
    var p = baseline;
    for (var i = 0; i < _totalPoints; i++) {
      final trend = math.sin(i * 0.06) * 12;
      final noise = (rng.nextDouble() - 0.48) * 5;
      p += trend * 0.04 + noise;
      p = p.clamp(baseline - 40, baseline + 40);
      prices.add(p);
    }
    return prices;
  }

  Path _smoothPath(List<Offset> pts) {
    if (pts.length < 2) return Path();
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final mx = (pts[i - 1].dx + pts[i].dx) / 2;
      path.cubicTo(mx, pts[i - 1].dy, mx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    return path;
  }

  void _drawSeries(
    Canvas canvas,
    Size size, {
    required List<double> prices,
    required double seriesProgress,
    required double chartTop,
    required double priceAreaH,
    required double chartLeft,
    required double chartW,
    required double lineWidth,
    required List<Color> colors,
    double opacity = 1,
    bool withGlow = false,
  }) {
    if (seriesProgress <= 0) return;

    final minP = prices.reduce(math.min);
    final maxP = prices.reduce(math.max);
    final range = maxP - minP;
    if (range <= 0) return;

    double xOf(int i) => chartLeft + (i / (_totalPoints - 1)) * chartW;
    double yOf(double p) => chartTop + (1 - (p - minP) / range) * priceAreaH;

    final drawCount =
        (seriesProgress * _totalPoints).round().clamp(2, _totalPoints);
    final points = <Offset>[
      for (var i = 0; i < drawCount; i++) Offset(xOf(i), yOf(prices[i])),
    ];
    final linePath = _smoothPath(points);
    final lineGrad = ui.Gradient.linear(
      Offset(chartLeft, 0),
      Offset(chartLeft + chartW, 0),
      [
        for (final color in colors)
          color.withValues(alpha: opacity * progress.clamp(0.0, 1.0)),
      ],
      List<double>.generate(colors.length, (i) => i / (colors.length - 1)),
    );

    if (withGlow) {
      final areaPath = Path()..addPath(linePath, Offset.zero)
        ..lineTo(points.last.dx, chartTop + priceAreaH)
        ..lineTo(points.first.dx, chartTop + priceAreaH)
        ..close();

      canvas.drawPath(
        areaPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, chartTop),
            Offset(0, chartTop + priceAreaH),
            [
              const Color(0xFFE4621E).withValues(alpha: 0.18 * progress),
              const Color(0xFFA72669).withValues(alpha: 0.10 * progress),
              Colors.transparent,
            ],
            const [0.0, 0.55, 1.0],
          ),
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..shader = lineGrad
          ..style = PaintingStyle.stroke
          ..strokeWidth = lineWidth + 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..shader = lineGrad
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final chartLeft = size.width * 0.02;
    final chartRight = size.width * 0.98;
    final chartTop = size.height * 0.06;
    final chartW = chartRight - chartLeft;
    final priceAreaH = size.height * 0.82;

    final primary = _generatePrices(seed: 77);
    final secondary = _generatePrices(seed: 41, baseline: 172);

    _drawSeries(
      canvas,
      size,
      prices: secondary,
      seriesProgress: (progress - 0.12).clamp(0.0, 1.0),
      chartTop: chartTop + priceAreaH * 0.08,
      priceAreaH: priceAreaH * 0.72,
      chartLeft: chartLeft,
      chartW: chartW,
      lineWidth: 1.2,
      colors: const [Color(0xFF6A2C72), Color(0xFF232C64)],
      opacity: 0.7,
    );

    _drawSeries(
      canvas,
      size,
      prices: primary,
      seriesProgress: progress,
      chartTop: chartTop,
      priceAreaH: priceAreaH,
      chartLeft: chartLeft,
      chartW: chartW,
      lineWidth: 2.2,
      colors: const [
        Color(0xFFE4621E),
        Color(0xFFD2364C),
        Color(0xFFA72669),
        Color(0xFF6A2C72),
      ],
      withGlow: true,
    );

    final minP = primary.reduce(math.min);
    final maxP = primary.reduce(math.max);
    final range = maxP - minP;
    if (range <= 0) return;

    final drawCount =
        (progress * _totalPoints).round().clamp(2, _totalPoints);
    if (drawCount <= 2) return;

    double xOf(int i) => chartLeft + (i / (_totalPoints - 1)) * chartW;
    double yOf(double p) => chartTop + (1 - (p - minP) / range) * priceAreaH;

    final cursorX = xOf(drawCount - 1);
    final cursorY = yOf(primary[drawCount - 1]);
    const cursorColor = Color(0xFFE4621E);

    canvas.drawLine(
      Offset(chartLeft, cursorY),
      Offset(chartRight, cursorY),
      Paint()
        ..color = cursorColor.withValues(alpha: 0.08 * progress)
        ..strokeWidth = 0.6,
    );
    canvas.drawLine(
      Offset(cursorX, chartTop),
      Offset(cursorX, chartTop + priceAreaH),
      Paint()
        ..color = cursorColor.withValues(alpha: 0.08 * progress)
        ..strokeWidth = 0.6,
    );

    final pulseR = 3.5 + math.sin(flow * math.pi * 6) * 1.2;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      pulseR + 6,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.12 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      pulseR,
      Paint()..color = cursorColor.withValues(alpha: 0.92 * progress),
    );
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      pulseR + 2.5,
      Paint()
        ..color = const Color(0xFFA72669).withValues(alpha: 0.45 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartScenePainter old) =>
      old.progress != progress || old.flow != flow;
}

class _ParticlesLayer extends StatelessWidget {
  const _ParticlesLayer({required this.active});

  final bool active;

  static const _particles = [
    (0.18, 0.22, Color(0xFFE4621E)),
    (0.78, 0.30, Color(0xFFD2364C)),
    (0.12, 0.55, Color(0xFFA72669)),
    (0.85, 0.48, Color(0xFF6A2C72)),
    (0.28, 0.65, Color(0xFF232C64)),
    (0.70, 0.60, Color(0xFFE4621E)),
    (0.45, 0.38, Color(0xFFA72669)),
    (0.58, 0.72, Color(0xFFD2364C)),
  ];

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        for (var i = 0; i < _particles.length; i++)
          _ParticleDot(
            left: _particles[i].$1 * size.width,
            top: _particles[i].$2 * size.height,
            color: _particles[i].$3,
            index: i,
          ),
      ],
    );
  }
}

class _ParticleDot extends StatefulWidget {
  const _ParticleDot({
    required this.left,
    required this.top,
    required this.color,
    required this.index,
  });

  final double left;
  final double top;
  final Color color;
  final int index;

  @override
  State<_ParticleDot> createState() => _ParticleDotState();
}

class _ParticleDotState extends State<_ParticleDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final phase = (_drift.value + widget.index * 0.125) % 1.0;
        final opacity = phase < 0.2
            ? phase / 0.2 * 0.7
            : phase < 0.5
                ? 0.5
                : phase < 0.8
                    ? 0.3
                    : 0.0;
        final yOffset = -20 * math.sin(phase * math.pi);
        final scale = 0.5 + 0.5 * math.sin(phase * math.pi);
        return Positioned(
          left: widget.left,
          top: widget.top + yOffset,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DataStreamBars extends StatefulWidget {
  const _DataStreamBars({required this.active});
  final bool active;

  @override
  State<_DataStreamBars> createState() => _DataStreamBarsState();
}

class _DataStreamBarsState extends State<_DataStreamBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const _colors = _PremiumSplashScreenState._brandColors;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.active) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _DataStreamBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.active) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.active ? 1 : 0,
      duration: const Duration(milliseconds: 1200),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(14, (i) {
          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final wave = 0.2 + 0.8 * (0.5 + 0.5 * math.sin((_pulse.value + i * 0.07) * math.pi * 2));
              return Container(
                width: 4,
                height: 8 + 48 * wave,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _colors[i % _colors.length],
                      _colors[i % _colors.length].withValues(alpha: 0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _colors[i % _colors.length].withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _ContentLayer extends StatelessWidget {
  const _ContentLayer({
    required this.phase,
    required this.logoSize,
    required this.halo,
    required this.orbit,
    required this.shimmer,
    required this.statusPulse,
  });

  final _SplashPhase phase;
  final double logoSize;
  final AnimationController halo;
  final AnimationController orbit;
  final AnimationController shimmer;
  final AnimationController statusPulse;

  @override
  Widget build(BuildContext context) {
    final showContent = phase == _SplashPhase.enter ||
        phase == _SplashPhase.hold ||
        phase == _SplashPhase.exit;

    return Align(
      alignment: Alignment.bottomCenter,
      child: _AnimatedContentShell(
        phase: phase,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LogoStage(
              logoSize: logoSize,
              halo: halo,
              orbit: orbit,
              shimmer: shimmer,
              visible: showContent,
              showDetails: showContent,
            ),
            const SizedBox(height: 30),
            AnimatedOpacity(
              opacity: showContent ? 1 : 0,
              duration: const Duration(milliseconds: 1000),
              curve: const Cubic(0.34, 1.45, 0.64, 1),
              child: AnimatedSlide(
                offset: showContent ? Offset.zero : const Offset(0, 0.08),
                duration: const Duration(milliseconds: 1000),
                curve: const Cubic(0.34, 1.45, 0.64, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BrandBlock(visible: showContent),
                    const SizedBox(height: 18),
                    _StatusRow(pulse: statusPulse, visible: showContent),
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

class _AnimatedContentShell extends StatefulWidget {
  const _AnimatedContentShell({required this.phase, required this.child});

  final _SplashPhase phase;
  final Widget child;

  @override
  State<_AnimatedContentShell> createState() => _AnimatedContentShellState();
}

class _AnimatedContentShellState extends State<_AnimatedContentShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.phase == _SplashPhase.enter || widget.phase == _SplashPhase.hold) {
      _enter.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedContentShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase == _SplashPhase.reveal &&
        (widget.phase == _SplashPhase.enter || widget.phase == _SplashPhase.hold)) {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;

    if (widget.phase == _SplashPhase.exit) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (context, t, child) {
          return Opacity(
            opacity: 1 - t,
            child: Transform.scale(
              scale: 1 - t * 0.15,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: t * 8, sigmaY: t * 8),
                child: child,
              ),
            ),
          );
        },
        child: child,
      );
    }

    if (widget.phase == _SplashPhase.reveal) {
      return Opacity(opacity: 0, child: child);
    }

    if (widget.phase == _SplashPhase.enter || widget.phase == _SplashPhase.hold) {
      return AnimatedBuilder(
        animation: CurvedAnimation(parent: _enter, curve: const Cubic(0.34, 1.45, 0.64, 1)),
        builder: (context, _) {
          final t = _enter.value;
          final scale = t < 0.75
              ? 0.7 + t / 0.75 * 0.33
              : 1.03 - (t - 0.75) / 0.25 * 0.03;
          final y = (1 - t) * 22;
          final blur = t < 0.55
              ? (1 - t / 0.55) * 12
              : t < 0.75
                  ? 3 * (1 - (t - 0.55) / 0.2)
                  : 0.0;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, y),
              child: Transform.scale(
                scale: scale.clamp(0.7, 1.03),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
    }

    return child;
  }
}

class _LogoStage extends StatefulWidget {
  const _LogoStage({
    required this.logoSize,
    required this.halo,
    required this.orbit,
    required this.shimmer,
    required this.visible,
    this.showDetails = false,
  });

  final double logoSize;
  final AnimationController halo;
  final AnimationController orbit;
  final AnimationController shimmer;
  final bool visible;
  final bool showDetails;

  @override
  State<_LogoStage> createState() => _LogoStageState();
}

class _LogoStageState extends State<_LogoStage> {
  ui.Image? _flowerImage;
  double? _loadedHi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hi = FlowerLogoImageCache.hiSizeFor(context, widget.logoSize * 1.1);
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
    final stage = widget.logoSize * 1.45;
    return AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: const Duration(milliseconds: 900),
      curve: const Cubic(0.16, 1, 0.3, 1),
      child: AnimatedSlide(
        offset: widget.visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 1200),
        curve: const Cubic(0.16, 1, 0.3, 1),
        child: SizedBox(
          width: stage,
          height: stage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showDetails)
                for (var i = 0; i < 3; i++)
                  _ExpandingRing(
                    key: ValueKey('ring-$i'),
                    index: i,
                    stage: stage,
                  ),
              AnimatedBuilder(
                animation: widget.halo,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: widget.halo.value * math.pi * 2,
                    child: AnimatedOpacity(
                      opacity: widget.visible ? 0.45 : 0,
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        width: stage * 0.9,
                        height: stage * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              ..._PremiumSplashScreenState._brandColors,
                              _PremiumSplashScreenState._brandColors.first,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: widget.orbit,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: widget.orbit.value * math.pi * 2,
                    child: Opacity(
                      opacity: widget.visible ? 0.85 : 0,
                      child: CustomPaint(
                        size: Size(stage, stage),
                        painter: _OrbitRingPainter(),
                      ),
                    ),
                  );
                },
              ),
              if (widget.showDetails)
                TweenAnimationBuilder<double>(
                  key: const ValueKey('progress-ring'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 2200),
                  curve: const Cubic(0.16, 1, 0.3, 1),
                  builder: (context, progress, _) {
                    return CustomPaint(
                      size: Size(stage, stage),
                      painter: _ProgressRingPainter(progress: progress),
                    );
                  },
                ),
              AnimatedBuilder(
                animation: Listenable.merge([widget.halo, widget.shimmer]),
                builder: (context, child) {
                  final breathe = 1 + 0.035 * math.sin(widget.halo.value * math.pi * 2);
                  return Transform.scale(
                    scale: widget.visible ? breathe : 0,
                    child: child,
                  );
                },
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(widget.visible),
                  tween: Tween(end: widget.visible ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: const Cubic(0.16, 1, 0.3, 1),
                  builder: (context, t, child) {
                    final scale = t < 0.55
                        ? t / 0.55 * 1.08
                        : 1.08 - (t - 0.55) / 0.45 * 0.08;
                    return Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: widget.logoSize,
                        height: widget.logoSize * 1.01,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE4621E).withValues(alpha: 0.35),
                              blurRadius: 24,
                            ),
                            BoxShadow(
                              color: const Color(0xFFA72669).withValues(alpha: 0.25),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: _flowerImage != null && _loadedHi != null
                            ? FlowerLogoImageCache.smoothImage(
                                image: _flowerImage!,
                                displaySize: widget.logoSize,
                                hi: _loadedHi!,
                              )
                            : Image.asset(
                                'resources/Small Logo.png',
                                fit: BoxFit.contain,
                              ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: widget.shimmer,
                            builder: (context, _) {
                              final shimmerT = widget.shimmer.value;
                              return ClipOval(
                                child: ShaderMask(
                                  blendMode: BlendMode.srcATop,
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment(-1.2 + shimmerT * 2.4, -0.3),
                                      end: Alignment(-0.2 + shimmerT * 2.4, 0.3),
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.42),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.35, 0.5, 0.65],
                                    ).createShader(bounds);
                                  },
                                  child: Container(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              );
                            },
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
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xCCE4621E),
            Color(0x80A72669),
            Color(0x4D232C64),
            Color(0xCCE4621E),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.47;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final sweep = (1 - progress * 0.83) * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFE4621E),
            Color(0xFFD2364C),
            Color(0xFFA72669),
            Color(0xFF6A2C72),
            Color(0xFF232C64),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}

class _ExpandingRing extends StatefulWidget {
  const _ExpandingRing({super.key, required this.index, required this.stage});

  final int index;
  final double stage;

  static const _ringColors = [
    Color(0x59E4621E),
    Color(0x4DA72669),
    Color(0x66232C64),
  ];

  @override
  State<_ExpandingRing> createState() => _ExpandingRingState();
}

class _ExpandingRingState extends State<_ExpandingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    Future<void>.delayed(Duration(milliseconds: 250 + widget.index * 220), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _controller, curve: const Cubic(0.16, 1, 0.3, 1)),
      builder: (context, _) {
        final t = _controller.value;
        final scale = 0.35 + t * 1.05;
        final opacity = t < 0.25 ? t / 0.25 * 0.8 : (1 - t) * 0.8;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: widget.stage,
              height: widget.stage,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ExpandingRing._ringColors[widget.index % 3],
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ExpandingRing._ringColors[widget.index % 3].withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.visible});

  final bool visible;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _PremiumSplashScreenState._brandColors,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 1000),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => _gradient.createShader(bounds),
            child: Text(
              'TERMINAL',
              style: TextStyle(
                fontSize: (MediaQuery.sizeOf(context).width * 0.055).clamp(28.0, 38.0),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.14 * 38,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 900),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE4621E), Color(0xFFA72669), Color(0xFF6A2C72)],
            ).createShader(bounds),
            child: Text(
              'ENTERPRISE TRADING PLATFORM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.22 * 11,
                height: 1.4,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.pulse, required this.visible});

  final AnimationController pulse;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFA72669).withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                return Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE4621E), Color(0xFFA72669)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(
                          const Color(0xFFE4621E),
                          const Color(0xFFA72669),
                          pulse.value,
                        )!.withValues(alpha: 0.7),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Text(
              'Initializing secure session',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.06 * 11,
                color: const Color(0xFFC8C3D7).withValues(alpha: 0.6),
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TickerStrip extends StatelessWidget {
  const _TickerStrip({required this.phase, required this.ticker});

  final _SplashPhase phase;
  final AnimationController ticker;

  @override
  Widget build(BuildContext context) {
    final visible = phase != _SplashPhase.idle;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 56,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 800),
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.05),
          duration: const Duration(milliseconds: 800),
          curve: const Cubic(0.16, 1, 0.3, 1),
          child: ClipRect(
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: 14,
              child: AnimatedBuilder(
                animation: ticker,
                builder: (context, _) {
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  final offset = ticker.value * screenWidth * 0.5;
                  return OverflowBox(
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(-offset, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var pass = 0; pass < 2; pass++)
                            for (var i = 0;
                                i < _PremiumSplashScreenState._tickers.length;
                                i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _PremiumSplashScreenState._tickers[i].$1,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.12 * 10,
                                        color: _PremiumSplashScreenState
                                            ._brandColors[i % 5]
                                            .withValues(alpha: 0.7),
                                        fontFamily: Constants.FONT_DEFAULT_NEW,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _PremiumSplashScreenState._tickers[i].$2,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.85),
                                        fontFamily: Constants.FONT_DEFAULT_NEW,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomProgressBar extends StatefulWidget {
  const _BottomProgressBar({required this.phase});
  final _SplashPhase phase;

  @override
  State<_BottomProgressBar> createState() => _BottomProgressBarState();
}

class _BottomProgressBarState extends State<_BottomProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    if (widget.phase == _SplashPhase.enter || widget.phase == _SplashPhase.hold) {
      _progress.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _BottomProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.phase == _SplashPhase.enter || widget.phase == _SplashPhase.hold) &&
        !_progress.isAnimating &&
        _progress.value == 0) {
      Future<void>.delayed(const Duration(seconds: 1), () {
        if (mounted) _progress.forward();
      });
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.phase != _SplashPhase.idle;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 700),
        curve: const Cubic(0.16, 1, 0.3, 1),
        child: Container(
          height: 3,
          color: Colors.white.withValues(alpha: 0.05),
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _progress.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: _PremiumSplashScreenState._brandColors,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
