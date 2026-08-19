import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Premium donut color ramp — sophisticated multi-hue palette.
const List<Color> _premiumDonutColors = <Color>[
  Color(0xFF1B3A5C), // deep navy
  Color(0xFF2D6A8F), // ocean blue
  Color(0xFF3D8B7A), // teal jade
  Color(0xFF5B7FA6), // slate periwinkle
  Color(0xFF8BACC4), // frost steel
  Color(0xFFB0C4D8), // cloud silver
  Color(0xFF4A6E5D), // sage
  Color(0xFF7A94AB), // dusty blue
];

class PremiumAllocationDonut extends StatefulWidget {
  const PremiumAllocationDonut({
    super.key,
    required this.dark,
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
  });

  final bool dark;
  final List<StaticAllocationSlice> slices;
  final String centerValue;
  final String centerLabel;

  @override
  State<PremiumAllocationDonut> createState() => _PremiumAllocationDonutState();
}

class _PremiumAllocationDonutState extends State<PremiumAllocationDonut>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  Offset? _mousePosition;
  late AnimationController _animController;
  late Animation<double> _sweepAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sweepAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const double _outerFactor = 0.88;
  static const double _innerFactor = 0.74;
  static const double _hoverThicken = 4.0; // extra px each side on hover

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return MouseRegion(
          onHover: (PointerHoverEvent event) {
            final int? index = _hitTest(
              event.localPosition,
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            if (index != _hoveredIndex ||
                _mousePosition != event.localPosition) {
              setState(() {
                _hoveredIndex = index;
                _mousePosition = event.localPosition;
              });
            }
          },
          onExit: (_) {
            if (_hoveredIndex != null || _mousePosition != null) {
              setState(() {
                _hoveredIndex = null;
                _mousePosition = null;
              });
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              AnimatedBuilder(
                animation: _animController,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _DonutPainter(
                      slices: widget.slices,
                      palette: _premiumDonutColors,
                      hoveredIndex: _hoveredIndex,
                      dark: widget.dark,
                      sweepProgress: _sweepAnim.value,
                    ),
                  );
                },
              ),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder:
                        (Widget child, Animation<double> anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: _hoveredIndex == null
                        ? _buildCenterDefault()
                        : _buildCenterHovered(_hoveredIndex!),
                  ),
                ),
              ),
              if (_hoveredIndex != null && _mousePosition != null)
                _buildFloatingTooltip(_hoveredIndex!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterDefault() {
    return Column(
      key: const ValueKey<String>('default'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.centerValue,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: UsPremiumPalette.text(widget.dark),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.centerLabel,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            color: UsPremiumPalette.muted(widget.dark).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterHovered(int index) {
    final StaticAllocationSlice slice = widget.slices[index];
    final Color sliceColor =
        _premiumDonutColors[index % _premiumDonutColors.length];
    return Column(
      key: ValueKey<String>('hover_$index'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${slice.percent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: sliceColor,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: sliceColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            slice.label,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: UsPremiumPalette.text(widget.dark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingTooltip(int index) {
    final StaticAllocationSlice slice = widget.slices[index];
    final Offset pos = _mousePosition!;
    final Color sliceColor =
        _premiumDonutColors[index % _premiumDonutColors.length];
    return Positioned(
      left: (pos.dx + 16).clamp(0, 220),
      top: (pos.dy - 58).clamp(0, 200),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 150),
          builder: (BuildContext context, double val, Widget? child) {
            return Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, 4 * (1 - val)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.dark
                  ? const Color(0xFF1A2332)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sliceColor.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: widget.dark ? 0.50 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: sliceColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sliceColor,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: sliceColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      slice.label,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: UsPremiumPalette.text(widget.dark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slice.percent.toStringAsFixed(1)}% allocation',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: UsPremiumPalette.muted(widget.dark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _hitTest(Offset position, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outer = math.min(size.width, size.height) / 2 * _outerFactor;
    final double inner = outer * _innerFactor;

    final double dx = position.dx - center.dx;
    final double dy = position.dy - center.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);

    if (distance < (inner - _hoverThicken) || distance > (outer + _hoverThicken)) {
      return null;
    }

    double angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);

    final double total = widget.slices
        .fold(0, (double a, StaticAllocationSlice s) => a + s.percent);
    if (total <= 0) return null;

    double cursor = 0;
    for (int i = 0; i < widget.slices.length; i++) {
      final double sweep = (widget.slices[i].percent / total) * 2 * math.pi;
      if (angle >= cursor && angle < cursor + sweep) return i;
      cursor += sweep;
    }
    return null;
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.palette,
    required this.hoveredIndex,
    required this.dark,
    required this.sweepProgress,
  });

  final List<StaticAllocationSlice> slices;
  final List<Color> palette;
  final int? hoveredIndex;
  final bool dark;
  final double sweepProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerBase =
        math.min(size.width, size.height) / 2 * _PremiumAllocationDonutState._outerFactor;
    final double innerBase = outerBase * _PremiumAllocationDonutState._innerFactor;
    final double total =
        slices.fold(0, (double a, StaticAllocationSlice s) => a + s.percent);
    if (total <= 0) return;

    // Outer shadow ring
    if (sweepProgress > 0.1) {
      canvas.drawCircle(
        center.translate(0, 2),
        outerBase,
        Paint()
          ..color = Colors.black.withValues(alpha: dark ? 0.15 : 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    final double totalSweep = 2 * math.pi * sweepProgress;
    double startAngle = -math.pi / 2;
    double usedSweep = 0;

    for (int i = 0; i < slices.length; i++) {
      final StaticAllocationSlice slice = slices[i];
      final double fullSweep = (slice.percent / total) * 2 * math.pi;

      double sweep = fullSweep;
      if (usedSweep + sweep > totalSweep) {
        sweep = totalSweep - usedSweep;
        if (sweep <= 0) break;
      }
      usedSweep += sweep;

      final bool hovered = hoveredIndex == i;
      final Color baseColor = palette[i % palette.length];
      final double ht = _PremiumAllocationDonutState._hoverThicken;

      // Hover: thicken symmetrically from ring center (no gap, no translate)
      final double innerR = hovered ? innerBase - ht : innerBase;
      final double outerR = hovered ? outerBase + ht : outerBase;

      final Color startColor = Color.lerp(baseColor, Colors.white, 0.06)!;
      final Color endColor = Color.lerp(baseColor, Colors.black, 0.04)!;

      final Paint fillPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweep,
          colors: <Color>[startColor, endColor],
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromCircle(center: center, radius: outerR))
        ..style = PaintingStyle.fill;

      final Path path = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerR),
          startAngle,
          sweep,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerR),
          startAngle + sweep,
          -sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, fillPaint);

      if (hovered) {
        canvas.drawPath(
          path,
          Paint()
            ..color = baseColor.withValues(alpha: 0.10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
        );
      }

      // Gap lines
      if (slices.length > 1) {
        final Color gapColor =
            dark ? const Color(0xFF0B0E11) : const Color(0xFFF8FAFC);
        final Paint gap = Paint()
          ..color = gapColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawLine(
          Offset(
            center.dx + math.cos(startAngle) * innerBase,
            center.dy + math.sin(startAngle) * innerBase,
          ),
          Offset(
            center.dx + math.cos(startAngle) * outerBase,
            center.dy + math.sin(startAngle) * outerBase,
          ),
          gap,
        );
      }

      startAngle += sweep;
    }

    // Inner ring hairline
    if (sweepProgress > 0.5) {
      canvas.drawCircle(
        center,
        innerBase,
        Paint()
          ..color =
              (dark ? Colors.white : Colors.black).withValues(alpha: 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.dark != dark ||
        oldDelegate.slices != slices ||
        oldDelegate.sweepProgress != sweepProgress;
  }
}
