import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// World-class institutional financial-market loading experience.
class PremiumMarketLoader extends StatefulWidget {
  const PremiumMarketLoader({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<PremiumMarketLoader> createState() => _PremiumMarketLoaderState();
}

class _PremiumMarketLoaderState extends State<PremiumMarketLoader>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _pulse;
  late final AnimationController _dataFlow;
  late final AnimationController _orbitalSpin;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _curveDraw;
  late final Animation<double> _candleBuild;
  late final Animation<double> _dotsFade;
  late final Animation<double> _glowPulse;
  late final Animation<double> _textFade;
  late final Animation<double> _gridFade;
  late final Animation<double> _ringProgress;
  late final Animation<double> _tickerFade;
  late final Animation<double> _accelPhase;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed) _startExit();
      });

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _dataFlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _orbitalSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOutBack),
      ),
    );
    _gridFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.12, curve: Curves.easeOut),
    );
    _curveDraw = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.10, 0.50, curve: Curves.easeInOutCubic),
    );
    _candleBuild = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.25, 0.62, curve: Curves.easeOutCubic),
    );
    _dotsFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.14, 0.45, curve: Curves.easeIn),
    );
    _glowPulse = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.40, 0.72, curve: Curves.easeInOut),
    );
    _textFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.16, 0.32, curve: Curves.easeIn),
    );
    _ringProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.08, 0.55, curve: Curves.easeInOutCubic),
    );
    _tickerFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.30, 0.50, curve: Curves.easeIn),
    );
    _accelPhase = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.65, 0.90, curve: Curves.easeIn),
    );

    _master.forward();
  }

  void _startExit() {
    if (_exiting) return;
    _exiting = true;
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _pulse.dispose();
    _dataFlow.dispose();
    _orbitalSpin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedOpacity(
      opacity: _exiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: _exiting ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.15),
              radius: 1.1,
              colors: dark
                  ? const <Color>[
                      Color(0xFF0E1420),
                      Color(0xFF080B0F),
                      Color(0xFF050709),
                    ]
                  : const <Color>[
                      Color(0xFFF6F8FC),
                      Color(0xFFEEF1F7),
                      Color(0xFFE4E9F0),
                    ],
              stops: const <double>[0.0, 0.6, 1.0],
            ),
          ),
          child: reduceMotion
              ? _buildStatic(dark)
              : AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _master,
                    _pulse,
                    _dataFlow,
                    _orbitalSpin,
                  ]),
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      painter: _MarketLoaderPainter(
                        dark: dark,
                        gridFade: _gridFade.value,
                        curveDraw: _curveDraw.value,
                        candleBuild: _candleBuild.value,
                        dotsFade: _dotsFade.value,
                        glowPulse: _glowPulse.value,
                        pulse: _pulse.value,
                        dataFlow: _dataFlow.value,
                        orbitalSpin: _orbitalSpin.value,
                        ringProgress: _ringProgress.value,
                        tickerFade: _tickerFade.value,
                        accelPhase: _accelPhase.value,
                      ),
                      child: child,
                    );
                  },
                  child: _buildOverlay(dark),
                ),
        ),
      ),
    );
  }

  Widget _buildStatic(bool dark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _brandMark(dark),
          const SizedBox(height: 18),
          _statusText(dark),
        ],
      ),
    );
  }

  Widget _buildOverlay(bool dark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext context, Widget? child) {
                  final double glow =
                      _glowPulse.value * (0.4 + _pulse.value * 0.6);
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: glow > 0.01
                          ? <BoxShadow>[
                              BoxShadow(
                                color: UsPremiumPalette.electricBlue
                                    .withValues(alpha: 0.10 * glow),
                                blurRadius: 32 * glow,
                                spreadRadius: 6 * glow,
                              ),
                              BoxShadow(
                                color: UsPremiumPalette.tealAccent
                                    .withValues(alpha: 0.04 * glow),
                                blurRadius: 56 * glow,
                                spreadRadius: 12 * glow,
                              ),
                            ]
                          : null,
                    ),
                    child: child,
                  );
                },
                child: _brandMark(dark),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FadeTransition(
            opacity: _textFade,
            child: _statusText(dark),
          ),
          const SizedBox(height: 10),
          FadeTransition(
            opacity: _textFade,
            child: _progressBar(dark),
          ),
        ],
      ),
    );
  }

  Widget _brandMark(bool dark) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? <Color>[
                  const Color(0xFF151C28),
                  const Color(0xFF101620),
                ]
              : <Color>[
                  Colors.white,
                  const Color(0xFFF0F3F8),
                ],
        ),
        border: Border.all(
          color: UsPremiumPalette.electricBlue.withValues(alpha: dark ? 0.18 : 0.12),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            'resources/Small Logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.candlestick_chart_rounded,
              color: UsPremiumPalette.electricBlue,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusText(bool dark) {
    return Text(
      'Initializing Markets\u2026',
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
        color: (dark ? UsPremiumPalette.darkMuted : UsPremiumPalette.lightMuted)
            .withValues(alpha: 0.55),
      ),
    );
  }

  Widget _progressBar(bool dark) {
    return AnimatedBuilder(
      animation: _ringProgress,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: 120,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _ringProgress.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: <Color>[
                    UsPremiumPalette.electricBlue.withValues(alpha: 0.5),
                    UsPremiumPalette.tealAccent.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Canvas painter ─────────────────────────────────────────────────────────

class _MarketLoaderPainter extends CustomPainter {
  _MarketLoaderPainter({
    required this.dark,
    required this.gridFade,
    required this.curveDraw,
    required this.candleBuild,
    required this.dotsFade,
    required this.glowPulse,
    required this.pulse,
    required this.dataFlow,
    required this.orbitalSpin,
    required this.ringProgress,
    required this.tickerFade,
    required this.accelPhase,
  });

  final bool dark;
  final double gridFade;
  final double curveDraw;
  final double candleBuild;
  final double dotsFade;
  final double glowPulse;
  final double pulse;
  final double dataFlow;
  final double orbitalSpin;
  final double ringProgress;
  final double tickerFade;
  final double accelPhase;

  static const int _curvePoints = 64;
  static const int _candleCount = 16;
  static const int _dotCount = 24;
  static const int _gridLines = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    _drawGrid(canvas, size, cx, cy);
    _drawOrbitalRing(canvas, cx, cy, size);

    final double chartW = size.width * 0.52;
    final double chartH = size.height * 0.15;
    final double chartLeft = cx - chartW / 2;
    final double chartTop = cy + 60;

    _drawPriceCurve(canvas, chartLeft, chartTop, chartW, chartH);
    _drawVolumeBars(canvas, chartLeft, chartTop + chartH + 4, chartW, chartH * 0.35);
    _drawCandlesticks(canvas, chartLeft, chartTop - 6, chartW, chartH);
    _drawDataDots(canvas, cx, cy, size);
    _drawScanLines(canvas, cx, cy, size);
    _drawFlowingTicker(canvas, size);
    _drawMiniSparklines(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size, double cx, double cy) {
    if (gridFade <= 0) return;
    final double alpha = gridFade * (dark ? 0.04 : 0.03);
    final Paint gridPaint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: alpha)
      ..strokeWidth = 0.5;

    final double span = math.max(size.width, size.height);
    final double step = span / _gridLines;

    for (int i = 0; i <= _gridLines; i++) {
      final double y = cy - span / 2 + step * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i <= _gridLines; i++) {
      final double x = cx - span / 2 + step * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawOrbitalRing(Canvas canvas, double cx, double cy, Size size) {
    if (ringProgress <= 0) return;

    final double radius = math.min(size.width, size.height) * 0.18;
    final double sweep = ringProgress * math.pi * 2;
    final double start = orbitalSpin * math.pi * 2 - math.pi / 2;

    // Track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.025)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Active arc with gradient
    final Paint arcPaint = Paint()
      ..shader = ui.Gradient.sweep(
        Offset(cx, cy),
        <Color>[
          UsPremiumPalette.electricBlue.withValues(alpha: 0.0),
          UsPremiumPalette.electricBlue.withValues(alpha: 0.22 * ringProgress),
          UsPremiumPalette.tealAccent.withValues(alpha: 0.12 * ringProgress),
          UsPremiumPalette.electricBlue.withValues(alpha: 0.0),
        ],
        <double>[0.0, 0.3, 0.7, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      start,
      sweep.clamp(0, math.pi * 1.5),
      false,
      arcPaint,
    );

    // Orbital dot at the leading edge
    if (ringProgress > 0.1) {
      final double dotAngle = start + sweep.clamp(0, math.pi * 1.5);
      final Offset dotPos = Offset(
        cx + math.cos(dotAngle) * radius,
        cy + math.sin(dotAngle) * radius,
      );
      canvas.drawCircle(
        dotPos,
        2.5,
        Paint()
          ..color = UsPremiumPalette.electricBlue
              .withValues(alpha: 0.45 * ringProgress),
      );
      canvas.drawCircle(
        dotPos,
        5,
        Paint()
          ..color = UsPremiumPalette.electricBlue
              .withValues(alpha: 0.08 * ringProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  void _drawPriceCurve(
      Canvas canvas, double left, double top, double w, double h) {
    if (curveDraw <= 0) return;

    final math.Random rng = math.Random(42);
    final List<Offset> points = <Offset>[];
    for (int i = 0; i <= _curvePoints; i++) {
      final double t = i / _curvePoints;
      final double x = left + w * t;
      final double noise = rng.nextDouble() * 0.5 + 0.25;
      final double trend =
          0.45 - 0.28 * math.sin(t * math.pi * 2.6 + 0.3) +
          0.08 * math.cos(t * math.pi * 5.2);
      final double y = top + h * (trend * 0.7 + noise * 0.3);
      points.add(Offset(x, y));
    }

    final int visibleCount =
        (points.length * curveDraw).ceil().clamp(2, points.length);
    final List<Offset> visible = points.sublist(0, visibleCount);

    final Path path = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
      final Offset prev = visible[i - 1];
      final Offset curr = visible[i];
      final double mx = (prev.dx + curr.dx) / 2;
      path.cubicTo(mx, prev.dy, mx, curr.dy, curr.dx, curr.dy);
    }

    // Line with gradient shader
    final Paint linePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(left, 0),
        Offset(left + w, 0),
        <Color>[
          UsPremiumPalette.electricBlue.withValues(alpha: 0.15),
          UsPremiumPalette.electricBlueSoft.withValues(alpha: dark ? 0.40 : 0.30),
          UsPremiumPalette.tealAccent.withValues(alpha: 0.25),
        ],
        <double>[0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Glow line
    canvas.drawPath(
      path,
      Paint()
        ..shader = linePaint.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Area fill
    final Path areaPath = Path()..addPath(path, Offset.zero);
    areaPath
      ..lineTo(visible.last.dx, top + h + 4)
      ..lineTo(visible.first.dx, top + h + 4)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, top + h + 4),
          <Color>[
            UsPremiumPalette.electricBlue.withValues(alpha: dark ? 0.08 : 0.05),
            UsPremiumPalette.electricBlue.withValues(alpha: 0.0),
          ],
        ),
    );

    // Leading dot
    if (visible.length > 2) {
      final Offset last = visible.last;
      canvas.drawCircle(
        last,
        3,
        Paint()
          ..color = UsPremiumPalette.electricBlueSoft
              .withValues(alpha: 0.35 * curveDraw),
      );
      canvas.drawCircle(
        last,
        6,
        Paint()
          ..color = UsPremiumPalette.electricBlueSoft
              .withValues(alpha: 0.08 * curveDraw)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawVolumeBars(
      Canvas canvas, double left, double top, double w, double h) {
    if (candleBuild < 0.15) return;

    final math.Random rng = math.Random(55);
    final double barW = w / (_candleCount * 2);
    final double gap = w / _candleCount;
    final double progress =
        ((candleBuild - 0.15) / 0.85).clamp(0.0, 1.0);
    final int visible = (progress * _candleCount).ceil().clamp(0, _candleCount);

    for (int i = 0; i < visible; i++) {
      final double x = left + gap * i + gap * 0.25;
      final double barH = h * (0.2 + rng.nextDouble() * 0.8);
      final double entry =
          ((progress * _candleCount - i) * 2.0).clamp(0.0, 1.0);
      final bool bull = rng.nextBool();

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top + h - barH * entry, barW, barH * entry),
          const Radius.circular(0.5),
        ),
        Paint()
          ..color = (bull ? UsPremiumPalette.gain : UsPremiumPalette.loss)
              .withValues(alpha: 0.10 * entry),
      );
    }
  }

  void _drawCandlesticks(
      Canvas canvas, double left, double top, double w, double h) {
    if (candleBuild <= 0) return;

    final math.Random rng = math.Random(77);
    final double gap = w / (_candleCount + 1);
    final int visible =
        (candleBuild * _candleCount).ceil().clamp(0, _candleCount);

    for (int i = 0; i < visible; i++) {
      final double x = left + gap * (i + 1);
      final double open = top + h * (0.25 + rng.nextDouble() * 0.45);
      final double close = top + h * (0.25 + rng.nextDouble() * 0.45);
      final double high = math.min(open, close) - rng.nextDouble() * h * 0.10;
      final double low = math.max(open, close) + rng.nextDouble() * h * 0.10;
      final bool bull = close < open;

      final double entry =
          ((candleBuild * _candleCount - i) * 1.8).clamp(0.0, 1.0);
      final double alpha = (dark ? 0.35 : 0.28) * entry;

      final Color color = bull
          ? UsPremiumPalette.gain.withValues(alpha: alpha)
          : UsPremiumPalette.loss.withValues(alpha: alpha * 0.85);

      // Wick
      canvas.drawLine(
        Offset(x, high),
        Offset(x, low),
        Paint()
          ..color = color.withValues(alpha: alpha * 0.5)
          ..strokeWidth = 0.7,
      );

      // Body
      final double bodyTop = math.min(open, close);
      final double bodyBot = math.max(open, close);
      final double bodyH = (bodyBot - bodyTop).clamp(2.0, 18.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2.2, bodyTop, 4.4, bodyH * entry),
          const Radius.circular(0.8),
        ),
        Paint()..color = color,
      );
    }
  }

  void _drawDataDots(Canvas canvas, double cx, double cy, Size size) {
    if (dotsFade <= 0) return;

    final math.Random rng = math.Random(99);
    final double radius = math.min(size.width, size.height) * 0.28;

    for (int i = 0; i < _dotCount; i++) {
      final double baseAngle = (i / _dotCount) * math.pi * 2;
      final double angle = baseAngle + dataFlow * math.pi * 2;
      final double r = radius * (0.45 + rng.nextDouble() * 0.55);
      final double x = cx + math.cos(angle) * r;
      final double y = cy + math.sin(angle) * r * 0.50;

      final double alphaPulse =
          (math.sin(dataFlow * math.pi * 4 + i * 0.9) * 0.5 + 0.5);
      final double accel = 1.0 + accelPhase * 0.6;
      final double alpha = dotsFade * alphaPulse * 0.22 * accel;

      final double dotR = 1.2 + rng.nextDouble() * 1.2;

      canvas.drawCircle(
        Offset(x, y),
        dotR,
        Paint()
          ..color = (i % 3 == 0
                  ? UsPremiumPalette.tealAccent
                  : UsPremiumPalette.electricBlueSoft)
              .withValues(alpha: alpha.clamp(0.0, 0.35)),
      );

      // Tiny connecting lines between nearby dots
      if (i > 0 && i % 4 == 0) {
        final double prevAngle =
            ((i - 1) / _dotCount) * math.pi * 2 + dataFlow * math.pi * 2;
        final double pr = radius * (0.45 + math.Random(99 + i - 1).nextDouble() * 0.55);
        canvas.drawLine(
          Offset(x, y),
          Offset(
            cx + math.cos(prevAngle) * pr,
            cy + math.sin(prevAngle) * pr * 0.50,
          ),
          Paint()
            ..color = UsPremiumPalette.electricBlueSoft
                .withValues(alpha: alpha * 0.25)
            ..strokeWidth = 0.4,
        );
      }
    }
  }

  void _drawScanLines(Canvas canvas, double cx, double cy, Size size) {
    if (curveDraw < 0.2) return;

    final double alpha =
        ((curveDraw - 0.2) / 0.3).clamp(0.0, 1.0) * 0.03;

    for (int i = 0; i < 3; i++) {
      final double yOffset =
          (dataFlow * size.height * 0.5 + i * size.height * 0.33) %
              size.height;
      canvas.drawLine(
        Offset(0, yOffset),
        Offset(size.width, yOffset),
        Paint()
          ..color = UsPremiumPalette.electricBlue.withValues(alpha: alpha)
          ..strokeWidth = 0.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawFlowingTicker(Canvas canvas, Size size) {
    if (tickerFade <= 0) return;

    final double alpha = tickerFade * 0.22;
    final double y = size.height * 0.84;
    final double speed = 1.0 + accelPhase * 0.8;
    final double flowOffset = dataFlow * size.width * 0.5 * speed;

    final List<_TickerItem> tickers = <_TickerItem>[
      _TickerItem('AAPL', 178.42, true, 1.24),
      _TickerItem('MSFT', 412.87, false, 0.87),
      _TickerItem('GOOGL', 142.15, true, 2.13),
      _TickerItem('AMZN', 185.60, true, 0.95),
      _TickerItem('TSLA', 245.30, false, 1.67),
      _TickerItem('META', 502.44, true, 0.43),
      _TickerItem('NVDA', 875.21, true, 3.12),
      _TickerItem('JPM', 198.55, false, 0.52),
      _TickerItem('V', 278.90, true, 0.31),
      _TickerItem('BRK.B', 412.60, true, 0.18),
    ];

    for (int i = 0; i < tickers.length; i++) {
      final _TickerItem t = tickers[i];
      final double x =
          (i * 110.0 + flowOffset) % (size.width + 300) - 150;

      final String text =
          '${t.symbol}  \$${t.price.toStringAsFixed(2)}  '
          '${t.up ? "▲" : "▼"} ${t.change.toStringAsFixed(2)}%';

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: (t.up ? UsPremiumPalette.gain : UsPremiumPalette.loss)
                .withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x, y));

      // Separator dot
      if (i < tickers.length - 1) {
        final double sepX = x + tp.width + 12;
        canvas.drawCircle(
          Offset(sepX, y + tp.height / 2),
          1,
          Paint()
            ..color = (dark ? Colors.white : Colors.black)
                .withValues(alpha: alpha * 0.3),
        );
      }
    }
  }

  void _drawMiniSparklines(Canvas canvas, Size size) {
    if (curveDraw < 0.3) return;

    final double alpha =
        ((curveDraw - 0.3) / 0.3).clamp(0.0, 1.0) * (dark ? 0.12 : 0.08);
    final math.Random rng = math.Random(200);

    // 4 mini sparklines in corners
    final List<Offset> origins = <Offset>[
      Offset(size.width * 0.06, size.height * 0.12),
      Offset(size.width * 0.78, size.height * 0.10),
      Offset(size.width * 0.04, size.height * 0.72),
      Offset(size.width * 0.80, size.height * 0.74),
    ];

    for (int s = 0; s < origins.length; s++) {
      final Offset o = origins[s];
      final double sparkW = size.width * 0.14;
      final double sparkH = 16.0;

      final Path p = Path();
      for (int i = 0; i <= 12; i++) {
        final double t = i / 12;
        final double x = o.dx + sparkW * t;
        final double y = o.dy + sparkH * (0.5 + 0.4 * math.sin(t * math.pi * 3 + s * 1.5 + dataFlow * math.pi * 2));
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }

      final Color sparkColor = s % 2 == 0
          ? UsPremiumPalette.electricBlueSoft
          : UsPremiumPalette.tealAccent;

      canvas.drawPath(
        p,
        Paint()
          ..color = sparkColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
      );

      // Label
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: <String>['S&P 500', 'NASDAQ', 'DOW', 'VIX'][s],
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 7.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: (dark ? UsPremiumPalette.darkMuted : UsPremiumPalette.lightMuted)
                .withValues(alpha: alpha * 2),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      label.paint(canvas, Offset(o.dx, o.dy - 10));
    }
  }

  @override
  bool shouldRepaint(covariant _MarketLoaderPainter old) => true;
}

class _TickerItem {
  const _TickerItem(this.symbol, this.price, this.up, this.change);
  final String symbol;
  final double price;
  final bool up;
  final double change;
}
