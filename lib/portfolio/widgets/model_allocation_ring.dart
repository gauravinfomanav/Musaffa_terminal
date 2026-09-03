import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
import 'package:musaffa_terminal/portfolio/utils/portfolio_allocation_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Standard donut-style allocation ring (hollow center, stroke arcs only).
class ModelAllocationRing extends StatelessWidget {
  const ModelAllocationRing({
    super.key,
    required this.isDark,
    required this.allocatedPercent,
    required this.holdings,
    this.size = 200,
    this.groupByAssetType = false,
    this.strokeFactor,
  });

  final bool isDark;
  final double allocatedPercent;
  final List<ModelPortfolioHolding> holdings;
  final double size;
  final bool groupByAssetType;
  /// Ring thickness as a fraction of diameter. Defaults adapt to [size].
  final double? strokeFactor;

  double get _strokeFactor {
    if (strokeFactor != null) return strokeFactor!;
    if (size <= 90) return 0.085;
    if (size <= 130) return 0.095;
    return 0.11;
  }

  double get _valueFontSize {
    final inner = size * (1 - 2 * _strokeFactor);
    return (inner * 0.38).clamp(14.0, 32.0);
  }

  @override
  Widget build(BuildContext context) {
    final clamped = allocatedPercent.clamp(0.0, 100.0);
    final isComplete = isAllocationBalanced(allocatedPercent) && holdings.isNotEmpty;
    final isOver = isAllocationOver(allocatedPercent);

    final segments = _buildSegments();
    final centerLabel = isComplete ? 'Allocated' : 'Allocation';
    final centerValue = isOver
        ? formatAllocationPercent(allocatedPercent)
        : formatAllocationPercent(clamped);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, animationFactor, _) {
          return CustomPaint(
            painter: _ModelAllocationRingPainter(
              isDark: isDark,
              animationFactor: animationFactor,
              segments: segments,
              isOver: isOver,
              strokeFactor: _strokeFactor,
            ),
            child: _DonutCenterLabel(
              isDark: isDark,
              value: centerValue,
              label: centerLabel,
              ringSize: size,
              strokeFactor: _strokeFactor,
              valueColor: isOver
                  ? const Color(0xFFDC2626)
                  : isComplete
                      ? const Color(0xFF059669)
                      : null,
              valueSize: _valueFontSize,
            ),
          );
        },
      ),
    );
  }

  List<_RingSegment> _buildSegments() {
    if (groupByAssetType) {
      return _buildAssetTypeSegments();
    }

    final active =
        holdings.where((h) => h.targetPercent > 0).toList(growable: false);
    if (active.isEmpty) return const [];

    final holdingColors = PortfolioAllocationPalette.donutHoldingColors(isDark);
    final segments = <_RingSegment>[];
    for (var i = 0; i < active.length; i++) {
      final h = active[i];
      segments.add(
        _RingSegment(
          label: h.company ?? h.ticker,
          percent: h.targetPercent,
          color: holdingColors[i % holdingColors.length],
        ),
      );
    }

    final remaining = 100.0 - allocatedPercent;
    if (remaining > 0.05 && allocatedPercent <= 100) {
      segments.add(
        _RingSegment(
          label: 'Unallocated',
          percent: remaining,
          color: isDark ? const Color(0xFF3A3F47) : const Color(0xFFD1D5DB),
          isRemaining: true,
        ),
      );
    }

    return segments;
  }

  List<_RingSegment> _buildAssetTypeSegments() {
    final map = <String, double>{};
    for (final h in holdings) {
      if (h.targetPercent <= 0) continue;
      final label = _assetCategoryLabel(h.assetType);
      map[label] = (map[label] ?? 0) + h.targetPercent;
    }

    final segments = map.entries
        .map(
          (e) => _RingSegment(
            label: e.key,
            percent: e.value,
            color: PortfolioAllocationPalette.assetType(e.key, isDark),
          ),
        )
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));

    final remaining = 100.0 - allocatedPercent;
    if (remaining > 0.05 && allocatedPercent <= 100) {
      segments.add(
        _RingSegment(
          label: 'Unallocated',
          percent: remaining,
          color: isDark ? const Color(0xFF3A3F47) : const Color(0xFFD1D5DB),
          isRemaining: true,
        ),
      );
    }

    return segments;
  }

  String _assetCategoryLabel(ModelAssetType type) {
    switch (type) {
      case ModelAssetType.stock:
      case ModelAssetType.etf:
        return 'Equity';
      case ModelAssetType.gold:
        return 'Gold';
      case ModelAssetType.bond:
        return 'Bonds';
      case ModelAssetType.reit:
        return 'Real Estate';
      case ModelAssetType.cash:
        return 'Cash';
      case ModelAssetType.commodity:
        return 'Commodity';
      case ModelAssetType.other:
        return 'Other';
    }
  }
}

/// Breakdown donut for analytics (asset type, sector mix, etc.).
class ModelBreakdownDonut extends StatelessWidget {
  const ModelBreakdownDonut({
    super.key,
    required this.isDark,
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
    this.size = 160,
    this.colors,
    this.strokeFactor = 0.135,
  });

  final bool isDark;
  final List<({String label, double percent})> slices;
  final String centerValue;
  final String centerLabel;
  final double size;
  /// Optional per-slice colors (falls back to palette).
  final List<Color>? colors;
  final double strokeFactor;

  @override
  Widget build(BuildContext context) {
    final holdingColors = PortfolioAllocationPalette.donutHoldingColors(isDark);
    final segments = <_RingSegment>[];
    for (var i = 0; i < slices.length; i++) {
      final s = slices[i];
      if (s.percent <= 0) continue;
      final color = (colors != null && i < colors!.length)
          ? colors![i]
          : holdingColors[i % holdingColors.length];
      segments.add(
        _RingSegment(
          label: s.label,
          percent: s.percent,
          color: color,
        ),
      );
    }

    final total = segments.fold<double>(0, (sum, s) => sum + s.percent);
    final remaining = 100.0 - total;
    if (remaining > 0.05 && segments.isNotEmpty) {
      segments.add(
        _RingSegment(
          label: 'Unallocated',
          percent: remaining,
          color: isDark ? const Color(0xFF3A3F47) : const Color(0xFFD1D5DB),
          isRemaining: true,
        ),
      );
    }

    final valueSize = (size * 0.16).clamp(20.0, 30.0);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 780),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return CustomPaint(
            painter: _ModelBreakdownDonutPainter(
              isDark: isDark,
              segments: segments,
              progress: t,
              strokeFactor: strokeFactor,
            ),
            child: child,
          );
        },
        child: _DonutCenterLabel(
          isDark: isDark,
          value: centerValue,
          label: centerLabel,
          ringSize: size,
          strokeFactor: strokeFactor,
          valueSize: valueSize,
        ),
      ),
    );
  }
}

class _DonutCenterLabel extends StatelessWidget {
  const _DonutCenterLabel({
    required this.isDark,
    required this.value,
    required this.label,
    required this.ringSize,
    required this.strokeFactor,
    this.valueColor,
    this.valueSize = 24,
  });

  final bool isDark;
  final String value;
  final String label;
  final double ringSize;
  final double strokeFactor;
  final Color? valueColor;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final innerDiameter = ringSize * (1 - 2 * strokeFactor) - 6;
    final labelSize = (valueSize * 0.42).clamp(7.0, 10.0);

    return Center(
      child: SizedBox(
        width: innerDiameter,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: valueSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1,
                  color: valueColor ?? HomeUi.title(isDark),
                ),
              ),
              SizedBox(height: ringSize <= 100 ? 2 : 4),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  height: 1.1,
                  color: HomeUi.muted(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingSegment {
  const _RingSegment({
    required this.label,
    required this.percent,
    required this.color,
    this.isRemaining = false,
  });

  final String label;
  final double percent;
  final Color color;
  final bool isRemaining;
}

class _DonutStrokePainter {
  _DonutStrokePainter._();

  static const double defaultStrokeFactor = 0.11;

  static void draw(
    Canvas canvas,
    Size size, {
    required bool isDark,
    required List<_RingSegment> segments,
    double strokeFactor = defaultStrokeFactor,
    double progress = 1.0,
    bool isOver = false,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.shortestSide * strokeFactor;
    final radius = size.shortestSide / 2 - strokeWidth / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackColor =
        isDark ? const Color(0xFF2A2D33) : const Color(0xFFE5E7EB);

    _drawStrokeArc(
      canvas,
      rect,
      startAngle: -math.pi / 2,
      sweepAngle: 2 * math.pi,
      color: trackColor,
      strokeWidth: strokeWidth,
      cap: StrokeCap.butt,
    );

    if (segments.isEmpty) return;

    final total = segments.fold<double>(0, (s, seg) => s + seg.percent);
    if (total <= 0) return;

    if (isOver) {
      _drawStrokeArc(
        canvas,
        rect,
        startAngle: -math.pi / 2,
        sweepAngle: 2 * math.pi,
        color: const Color(0xFFDC2626),
        strokeWidth: strokeWidth,
        cap: StrokeCap.butt,
      );
      return;
    }

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      final baseSweep = (seg.percent / 100) * 2 * math.pi;
      final sweep = seg.isRemaining
          ? baseSweep
          : baseSweep * progress.clamp(0.0, 1.0);
      if (sweep <= 0.001) continue;

      _drawStrokeArc(
        canvas,
        rect,
        startAngle: startAngle,
        sweepAngle: sweep,
        color: seg.color,
        strokeWidth: strokeWidth,
        cap: seg.isRemaining ? StrokeCap.butt : StrokeCap.round,
      );

      startAngle += sweep;
    }
  }

  static void _drawStrokeArc(
    Canvas canvas,
    Rect rect, {
    required double startAngle,
    required double sweepAngle,
    required Color color,
    required double strokeWidth,
    required StrokeCap cap,
  }) {
    if (sweepAngle >= 2 * math.pi - 0.001) {
      _drawStrokeArc(
        canvas,
        rect,
        startAngle: startAngle,
        sweepAngle: math.pi,
        color: color,
        strokeWidth: strokeWidth,
        cap: StrokeCap.butt,
      );
      _drawStrokeArc(
        canvas,
        rect,
        startAngle: startAngle + math.pi,
        sweepAngle: math.pi,
        color: color,
        strokeWidth: strokeWidth,
        cap: StrokeCap.butt,
      );
      return;
    }

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = cap
        ..isAntiAlias = true,
    );
  }
}

class _ModelBreakdownDonutPainter extends CustomPainter {
  _ModelBreakdownDonutPainter({
    required this.isDark,
    required this.segments,
    required this.progress,
    this.strokeFactor = 0.135,
  });

  final bool isDark;
  final List<_RingSegment> segments;
  final double progress;
  final double strokeFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.shortestSide * strokeFactor;
    final radius = size.shortestSide / 2 - strokeWidth / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackColor =
        isDark ? const Color(0xFF2A2D36) : const Color(0xFFE8EAED);

    // Soft outer halo
    canvas.drawCircle(
      center,
      radius + strokeWidth * 0.55,
      Paint()
        ..color = (isDark ? Colors.white : const Color(0xFF0F172A))
            .withValues(alpha: isDark ? 0.04 : 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.9
        ..isAntiAlias = true,
    );

    // Track
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true,
    );

    // Soft inner well
    final innerR = radius - strokeWidth * 0.55;
    if (innerR > 0) {
      canvas.drawCircle(
        center,
        innerR,
        Paint()
          ..shader = RadialGradient(
            colors: isDark
                ? [
                    const Color(0xFF1A1D28).withValues(alpha: 0.9),
                    const Color(0xFF12151F).withValues(alpha: 0.2),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC).withValues(alpha: 0.35),
                  ],
          ).createShader(Rect.fromCircle(center: center, radius: innerR)),
      );
    }

    if (segments.isEmpty) return;

    final total = segments.fold<double>(0, (s, seg) => s + seg.percent);
    if (total <= 0) return;

    final activeCount = segments.where((s) => !s.isRemaining).length;
    final gap = activeCount > 1 ? 0.045 : 0.0;
    var startAngle = -math.pi / 2;

    for (final seg in segments) {
      final rawSweep = (seg.percent / total) * 2 * math.pi;
      final sweep = (rawSweep - gap).clamp(0.0, rawSweep) * progress;
      if (sweep <= 0.004) {
        startAngle += rawSweep;
        continue;
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..color = seg.color;

      // Soft glow under segment
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 3
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = seg.color.withValues(alpha: isDark ? 0.22 : 0.16),
      );

      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep,
        false,
        paint,
      );

      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ModelBreakdownDonutPainter oldDelegate) {
    return oldDelegate.segments.length != segments.length ||
        oldDelegate.isDark != isDark ||
        oldDelegate.progress != progress ||
        oldDelegate.strokeFactor != strokeFactor;
  }
}

class _ModelAllocationRingPainter extends CustomPainter {
  _ModelAllocationRingPainter({
    required this.isDark,
    required this.animationFactor,
    required this.segments,
    required this.isOver,
    this.strokeFactor = _DonutStrokePainter.defaultStrokeFactor,
  });

  final bool isDark;
  final double animationFactor;
  final List<_RingSegment> segments;
  final bool isOver;
  final double strokeFactor;

  @override
  void paint(Canvas canvas, Size size) {
    _DonutStrokePainter.draw(
      canvas,
      size,
      isDark: isDark,
      segments: segments,
      strokeFactor: strokeFactor,
      progress: animationFactor.clamp(0.0, 1.0),
      isOver: isOver,
    );
  }

  @override
  bool shouldRepaint(covariant _ModelAllocationRingPainter oldDelegate) {
    return oldDelegate.animationFactor != animationFactor ||
        oldDelegate.segments.length != segments.length ||
        oldDelegate.isOver != isOver ||
        oldDelegate.isDark != isDark ||
        oldDelegate.strokeFactor != strokeFactor;
  }
}
