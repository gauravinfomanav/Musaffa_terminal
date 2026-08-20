import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Modern institutional loader — clean + subtle finance ambiance.
class PremiumMarketLoader extends StatefulWidget {
  const PremiumMarketLoader({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<PremiumMarketLoader> createState() => _PremiumMarketLoaderState();
}

class _PremiumMarketLoaderState extends State<PremiumMarketLoader>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _orbit;
  late final AnimationController _shimmer;
  late final AnimationController _flow;

  late final Animation<double> _logoFade, _logoScale;
  late final Animation<double> _ringReveal;
  late final Animation<double> _textFade;
  late final Animation<double> _barProgress;
  late final Animation<double> _ambientFade;

  bool _exiting = false;

  static const _brand = <Color>[
    Color(0xFFE4681F),
    Color(0xFFDB3E20),
    Color(0xFFC42329),
    Color(0xFF7A213B),
    Color(0xFF232C64),
    Color(0xFFE4681F),
  ];

  @override
  void initState() {
    super.initState();

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _startExit();
      });

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.16, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.24, curve: Curves.easeOutCubic),
    ));
    _ringReveal = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOutCubic),
    );
    _textFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.16, 0.34, curve: Curves.easeOut),
    );
    _barProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.10, 0.90, curve: Curves.easeInOutCubic),
    );
    _ambientFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.08, 0.85, curve: Curves.easeOut),
    );

    _master.forward();
  }

  void _startExit() {
    if (_exiting) return;
    _exiting = true;
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _orbit.dispose();
    _shimmer.dispose();
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: _exiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: _exiting ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: dark ? const Color(0xFF0B0E13) : const Color(0xFFFAFAFB),
          child: AnimatedBuilder(
            animation: Listenable.merge([_master, _orbit, _shimmer, _flow]),
            builder: (context, _) => CustomPaint(
              painter: _AmbientFinancePainter(
                dark: dark,
                ambientFade: _ambientFade.value,
                flow: _flow.value,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogoRing(dark),
                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _textFade,
                      child: _buildProgressBar(dark),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _textFade,
                      child: _buildStatusRow(dark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoRing(bool dark) {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _GradientRingPainter(
              ringReveal: _ringReveal.value,
              orbitT: _orbit.value,
              dark: dark,
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? const Color(0xFF131720) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.30 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'resources/Small Logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => HomeUi.brandIcon(
                        icon: Icons.candlestick_chart_rounded,
                        size: 24,
                        gradient: HomeUi.iconFillGradient,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool dark) {
    return SizedBox(
      width: 200,
      height: 3,
      child: CustomPaint(
        painter: _ProgressBarPainter(
          dark: dark,
          progress: _barProgress.value,
          shimmerT: _shimmer.value,
        ),
      ),
    );
  }

  Widget _buildStatusRow(bool dark) {
    final pct = (_barProgress.value * 100).round();
    final mutedColor = dark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Loading charts',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.05,
            color: mutedColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 3, height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mutedColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        Text(
          '$pct%',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: dark ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── Live trading chart background ────────────────────────────────────────────

class _AmbientFinancePainter extends CustomPainter {
  _AmbientFinancePainter({
    required this.dark,
    required this.ambientFade,
    required this.flow,
  });

  final bool dark;
  final double ambientFade;
  final double flow;

  static const int _totalPoints = 120;

  @override
  void paint(Canvas canvas, Size size) {
    if (ambientFade <= 0) return;
    _drawTradingChart(canvas, size);
  }

  /// Generates a realistic price series (deterministic).
  List<double> _generatePrices() {
    final rng = math.Random(77);
    final prices = <double>[];
    double p = 180.0;
    for (int i = 0; i < _totalPoints; i++) {
      final trend = math.sin(i * 0.06) * 12;
      final noise = (rng.nextDouble() - 0.48) * 5;
      p += trend * 0.04 + noise;
      p = p.clamp(140.0, 220.0);
      prices.add(p);
    }
    return prices;
  }

  void _drawTradingChart(Canvas canvas, Size size) {
    final prices = _generatePrices();
    final minP = prices.reduce(math.min);
    final maxP = prices.reduce(math.max);
    final range = maxP - minP;
    if (range <= 0) return;

    // Chart area
    final chartLeft = size.width * 0.12;
    final chartRight = size.width * 0.88;
    final chartTop = size.height * 0.52;
    final chartBottom = size.height * 0.82;
    final chartW = chartRight - chartLeft;
    final chartH = chartBottom - chartTop;

    double xOf(int i) => chartLeft + (i / (_totalPoints - 1)) * chartW;
    double yOf(double p) => chartTop + (1 - (p - minP) / range) * chartH;

    // Points drawn — ambientFade drives full 0→120 sweep
    final drawCount = (ambientFade * _totalPoints).round().clamp(2, _totalPoints);

    final baseAlpha = dark ? 0.25 : 0.20;

    // ── Grid lines + price labels
    final gridAlpha = ambientFade * (dark ? 0.04 : 0.03);
    final gridPaint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: gridAlpha)
      ..strokeWidth = 0.4;

    for (int g = 0; g <= 4; g++) {
      final gy = chartTop + chartH * g / 4;
      canvas.drawLine(Offset(chartLeft, gy), Offset(chartRight, gy), gridPaint);

      // Price label on right
      final priceVal = maxP - (g / 4) * range;
      final tp = TextPainter(
        text: TextSpan(
          text: '\$${priceVal.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: (dark ? const Color(0xFF4B5563) : const Color(0xFFB0B8C4))
                .withValues(alpha: ambientFade),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartRight + 6, gy - tp.height / 2));
    }

    // Build smooth cubic path through all drawn points
    final points = <Offset>[
      for (int i = 0; i < drawCount; i++) Offset(xOf(i), yOf(prices[i])),
    ];

    Path _smoothPath(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        final mx = (pts[i - 1].dx + pts[i].dx) / 2;
        p.cubicTo(mx, pts[i - 1].dy, mx, pts[i].dy, pts[i].dx, pts[i].dy);
      }
      return p;
    }

    final linePath = _smoothPath(points);

    // ── Area fill beneath the line
    final areaPath = Path()..addPath(linePath, Offset.zero);
    areaPath.lineTo(points.last.dx, chartBottom);
    areaPath.lineTo(points.first.dx, chartBottom);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, chartTop),
          Offset(0, chartBottom),
          [
            const Color(0xFFE4681F).withValues(alpha: baseAlpha * 0.15 * ambientFade),
            const Color(0xFFC42329).withValues(alpha: baseAlpha * 0.05 * ambientFade),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    final lineAlpha = baseAlpha * ambientFade;
    final lineGrad = ui.Gradient.linear(
      Offset(chartLeft, 0),
      Offset(chartRight, 0),
      [
        const Color(0xFFE4681F).withValues(alpha: lineAlpha),
        const Color(0xFFDB3E20).withValues(alpha: lineAlpha),
        const Color(0xFFC42329).withValues(alpha: lineAlpha),
        const Color(0xFF232C64).withValues(alpha: lineAlpha * 0.7),
      ],
      [0.0, 0.3, 0.6, 1.0],
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..shader = lineGrad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Line glow
    canvas.drawPath(
      linePath,
      Paint()
        ..shader = lineGrad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Live cursor at the drawing edge
    if (drawCount > 2) {
      final cursorX = xOf(drawCount - 1);
      final cursorY = yOf(prices[drawCount - 1]);
      final cursorColor = const Color(0xFFE4681F);

      // Horizontal crosshair line
      canvas.drawLine(
        Offset(chartLeft, cursorY),
        Offset(chartRight, cursorY),
        Paint()
          ..color = cursorColor.withValues(alpha: 0.08 * ambientFade)
          ..strokeWidth = 0.6,
      );

      // Vertical crosshair line
      canvas.drawLine(
        Offset(cursorX, chartTop),
        Offset(cursorX, chartBottom),
        Paint()
          ..color = cursorColor.withValues(alpha: 0.08 * ambientFade)
          ..strokeWidth = 0.6,
      );

      // Pulsing dot
      final pulseR = 4.0 + math.sin(flow * math.pi * 6) * 1.5;
      canvas.drawCircle(
        Offset(cursorX, cursorY),
        pulseR,
        Paint()..color = cursorColor.withValues(alpha: 0.50 * ambientFade),
      );
      canvas.drawCircle(
        Offset(cursorX, cursorY),
        pulseR + 6,
        Paint()
          ..color = cursorColor.withValues(alpha: 0.10 * ambientFade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Price tag on the right edge
      final priceText = '\$${prices[drawCount - 1].toStringAsFixed(2)}';
      final tagTp = TextPainter(
        text: TextSpan(
          text: priceText,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9 * ambientFade),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final tagW = tagTp.width + 12;
      final tagH = tagTp.height + 6;
      final tagRect = RRect.fromLTRBR(
        chartRight + 3,
        cursorY - tagH / 2,
        chartRight + 3 + tagW,
        cursorY + tagH / 2,
        const Radius.circular(4),
      );

      canvas.drawRRect(
        tagRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFE4681F), Color(0xFFC42329)],
          ).createShader(tagRect.outerRect)
          ..color = cursorColor.withValues(alpha: 0.85 * ambientFade),
      );
      tagTp.paint(canvas, Offset(chartRight + 3 + 6, cursorY - tagTp.height / 2));
    }

    // ── Mini candlesticks at the bottom (volume-style)
    final candleAlpha = ambientFade * (dark ? 0.14 : 0.10);
    final candleH = chartH * 0.18;
    final candleTop = chartBottom + 6;
    final candleGap = chartW / _totalPoints;
    final candleW = candleGap * 0.5;

    final rng = math.Random(55);
    for (int i = 0; i < drawCount; i++) {
      final x = xOf(i);
      final bull = i > 0 ? prices[i] >= prices[i - 1] : true;
      final vol = 0.15 + rng.nextDouble() * 0.85;
      final entry = ((drawCount.toDouble() - i) * 0.15).clamp(0.0, 1.0);
      final h = candleH * vol * entry;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - candleW / 2, candleTop + candleH - h, candleW, h),
          const Radius.circular(0.5),
        ),
        Paint()
          ..color = (bull ? const Color(0xFF2B9E6E) : const Color(0xFFD94E4E))
              .withValues(alpha: candleAlpha * entry),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientFinancePainter old) => true;
}

// ── Gradient ring around logo ───────────────────────────────────────────────

class _GradientRingPainter extends CustomPainter {
  _GradientRingPainter({
    required this.ringReveal,
    required this.orbitT,
    required this.dark,
  });

  final double ringReveal;
  final double orbitT;
  final bool dark;

  static const _colors = <Color>[
    Color(0xFFE4681F),
    Color(0xFFDB3E20),
    Color(0xFFC42329),
    Color(0xFF7A213B),
    Color(0xFF232C64),
    Color(0xFFE4681F),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 2;

    // Track
    canvas.drawCircle(
      Offset(cx, cy), radius,
      Paint()
        ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    if (ringReveal <= 0) return;

    final sweep = ringReveal.clamp(0.0, 1.0) * math.pi * 2 * 0.75;
    final startAngle = orbitT * math.pi * 2 - math.pi / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Gradient arc
    canvas.drawArc(
      rect, startAngle, sweep, false,
      Paint()
        ..shader = SweepGradient(
          colors: _colors,
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Glow
    canvas.drawArc(
      rect, startAngle, sweep, false,
      Paint()
        ..shader = SweepGradient(
          colors: [for (final c in _colors) c.withValues(alpha: 0.15)],
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Leading dot
    final tipAngle = startAngle + sweep;
    final tip = Offset(cx + math.cos(tipAngle) * radius, cy + math.sin(tipAngle) * radius);
    canvas.drawCircle(tip, 4,
        Paint()..color = const Color(0xFFE4681F).withValues(alpha: 0.50 * ringReveal));
    canvas.drawCircle(
        tip, 9,
        Paint()
          ..color = const Color(0xFFE4681F).withValues(alpha: 0.12 * ringReveal)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter old) => true;
}

// ── Shimmer progress bar ────────────────────────────────────────────────────

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.dark,
    required this.progress,
    required this.shimmerT,
  });

  final bool dark;
  final double progress;
  final double shimmerT;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final rrect = RRect.fromLTRBR(0, 0, size.width, size.height, r);

    canvas.drawRRect(rrect,
        Paint()..color = dark ? const Color(0xFF1A1E28) : const Color(0xFFEEEFF2));

    if (progress <= 0) return;
    final fillW = size.width * progress;
    final fillRR = RRect.fromLTRBR(0, 0, fillW, size.height, r);

    canvas.save();
    canvas.clipRRect(fillRR);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, fillW, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFE4681F), Color(0xFFDB3E20), Color(0xFFC42329),
            Color(0xFF7A213B), Color(0xFF232C64),
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Shimmer
    final sx = shimmerT * (fillW + 80) - 40;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fillW, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(sx - 30, 0), Offset(sx + 30, 0),
          [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: dark ? 0.15 : 0.25),
            Colors.white.withValues(alpha: 0.0),
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter old) => true;
}
