import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';

const List<Color> _premiumDonutColors = <Color>[
  Color(0xFF1B3A5C),
  Color(0xFF2D6A8F),
  Color(0xFF3D8B7A),
  Color(0xFF5B7FA6),
  Color(0xFF8BACC4),
  Color(0xFFB0C4D8),
  Color(0xFF4A6E5D),
  Color(0xFF7A94AB),
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
    with TickerProviderStateMixin {
  int? _hoveredIndex;
  Offset? _mousePosition;

  late AnimationController _entryController;
  late Animation<double> _sweepAnim;
  late Animation<double> _fadeAnim;

  late AnimationController _hoverController;
  late Animation<double> _hoverAnim;
  int? _animatingHoverIndex;

  static const double _outerFactor = 0.88;
  static const double _innerFactor = 0.74;
  static const double _hoverExpand = 5.0;
  static const double _gapWidth = 2.0;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sweepAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
    _entryController.forward();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _hoverAnim = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    );
    _hoverController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(int? index) {
    if (index == _hoveredIndex) return;
    _animatingHoverIndex = index ?? _hoveredIndex;
    _hoveredIndex = index;

    if (index != null) {
      _hoverController.forward(from: 0);
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onHover: (event) {
            final idx = _hitTest(event.localPosition, size);
            if (idx != _hoveredIndex || _mousePosition != event.localPosition) {
              setState(() => _mousePosition = event.localPosition);
              _onHover(idx);
            }
          },
          onExit: (_) {
            setState(() => _mousePosition = null);
            _onHover(null);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _entryController,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: _DonutPainter(
                      slices: widget.slices,
                      palette: _premiumDonutColors,
                      hoveredIndex: _hoveredIndex,
                      hoverT: _hoverAnim.value,
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
                    transitionBuilder: (child, anim) {
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
      key: const ValueKey('default'),
      mainAxisSize: MainAxisSize.min,
      children: [
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
    final slice = widget.slices[index];
    final color = _premiumDonutColors[index % _premiumDonutColors.length];
    return Column(
      key: ValueKey('hover_$index'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${slice.percent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
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
    final slice = widget.slices[index];
    final pos = _mousePosition!;
    final color = _premiumDonutColors[index % _premiumDonutColors.length];
    return Positioned(
      left: (pos.dx + 16).clamp(0.0, 220.0),
      top: (pos.dy - 58).clamp(0.0, 200.0),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 150),
          builder: (context, val, child) {
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
              color: widget.dark ? const Color(0xFF1A2332) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.dark ? 0.50 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
    final center = Offset(size.width / 2, size.height / 2);
    final outer = math.min(size.width, size.height) / 2 * _outerFactor;
    final inner = outer * _innerFactor;

    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < (inner - _hoverExpand) || distance > (outer + _hoverExpand)) {
      return null;
    }

    double angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);

    final total = widget.slices.fold(0.0, (a, s) => a + s.percent);
    if (total <= 0) return null;

    double cursor = 0;
    for (int i = 0; i < widget.slices.length; i++) {
      final sweep = (widget.slices[i].percent / total) * 2 * math.pi;
      if (angle >= cursor && angle < cursor + sweep) return i;
      cursor += sweep;
    }
    return null;
  }
}

// ── Painter ─────────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.palette,
    required this.hoveredIndex,
    required this.hoverT,
    required this.dark,
    required this.sweepProgress,
  });

  final List<StaticAllocationSlice> slices;
  final List<Color> palette;
  final int? hoveredIndex;
  final double hoverT;
  final bool dark;
  final double sweepProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerBase = math.min(size.width, size.height) / 2 *
        _PremiumAllocationDonutState._outerFactor;
    final innerBase = outerBase * _PremiumAllocationDonutState._innerFactor;
    final total = slices.fold(0.0, (a, s) => a + s.percent);
    if (total <= 0) return;

    // Soft shadow beneath donut
    if (sweepProgress > 0.1) {
      canvas.drawCircle(
        center.translate(0, 2),
        outerBase,
        Paint()
          ..color = Colors.black.withValues(alpha: dark ? 0.15 : 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    final totalSweep = 2 * math.pi * sweepProgress;
    final halfGap = _PremiumAllocationDonutState._gapWidth / 2;
    final gapAngle = halfGap / outerBase;
    double startAngle = -math.pi / 2;
    double usedSweep = 0;

    // Draw all slices
    for (int i = 0; i < slices.length; i++) {
      final fullSweep = (slices[i].percent / total) * 2 * math.pi;

      var sweep = fullSweep;
      if (usedSweep + sweep > totalSweep) {
        sweep = totalSweep - usedSweep;
        if (sweep <= 0) break;
      }
      usedSweep += sweep;

      final hovered = hoveredIndex == i;
      final expand = _PremiumAllocationDonutState._hoverExpand;
      final t = hovered ? hoverT : 0.0;

      final innerR = innerBase - expand * t;
      final outerR = outerBase + expand * t;

      final baseColor = palette[i % palette.length];

      // Inset sweep by gap angle on both sides for clean separation
      final drawStart = startAngle + (slices.length > 1 ? gapAngle : 0);
      final drawSweep = sweep - (slices.length > 1 ? gapAngle * 2 : 0);
      if (drawSweep <= 0) {
        startAngle += sweep;
        continue;
      }

      // Build arc path with rounded ends
      final path = _buildSlicePath(center, innerR, outerR, drawStart, drawSweep);

      // Gradient fill
      final startColor = Color.lerp(baseColor, Colors.white, 0.06)!;
      final endColor = Color.lerp(baseColor, Colors.black, 0.04)!;

      canvas.drawPath(
        path,
        Paint()
          ..shader = SweepGradient(
            startAngle: drawStart,
            endAngle: drawStart + drawSweep,
            colors: [startColor, endColor],
            tileMode: TileMode.clamp,
          ).createShader(Rect.fromCircle(center: center, radius: outerR))
          ..style = PaintingStyle.fill,
      );

      // Hover glow
      if (t > 0.01) {
        canvas.drawPath(
          path,
          Paint()
            ..color = baseColor.withValues(alpha: 0.12 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
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
          ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }
  }

  Path _buildSlicePath(
      Offset center, double innerR, double outerR, double start, double sweep) {
    final path = Path();

    // Outer arc (clockwise)
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerR),
      start,
      sweep,
      true,
    );

    // Line to inner arc end
    path.lineTo(
      center.dx + math.cos(start + sweep) * innerR,
      center.dy + math.sin(start + sweep) * innerR,
    );

    // Inner arc (counter-clockwise)
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerR),
      start + sweep,
      -sweep,
      false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    return old.hoveredIndex != hoveredIndex ||
        old.hoverT != hoverT ||
        old.dark != dark ||
        old.sweepProgress != sweepProgress;
  }
}
