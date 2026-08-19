import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Hierarchical sunburst — Finance exposure map with premium US palette.
class PremiumSunburstChart extends StatefulWidget {
  const PremiumSunburstChart({
    super.key,
    required this.dark,
    required this.nodes,
    required this.rootLabel,
    required this.rootTotal,
  });

  final bool dark;
  final List<StaticSunburstNode> nodes;
  final String rootLabel;
  final double rootTotal;

  @override
  State<PremiumSunburstChart> createState() => _PremiumSunburstChartState();
}

class _PremiumSunburstChartState extends State<PremiumSunburstChart> {
  static const double _tooltipWidth = 164;
  static const double _tooltipHeight = 62;
  _SunburstSegment? _hovered;
  Offset? _mousePosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final List<_SunburstNode> tree = _buildTree(widget.nodes);
        final List<_SunburstSegment> segments = _layoutSegments(tree, size);

        return MouseRegion(
          onHover: (PointerHoverEvent event) {
            final _SunburstSegment? hit = _hitTest(event.localPosition, size, segments);
            if (hit != _hovered || _mousePosition != event.localPosition) {
              setState(() {
                _hovered = hit;
                _mousePosition = event.localPosition;
              });
            }
          },
          onExit: (_) {
            if (_hovered != null || _mousePosition != null) {
              setState(() {
                _hovered = null;
                _mousePosition = null;
              });
            }
          },
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              CustomPaint(
                size: size,
                painter: _SunburstPainter(
                  segments: segments,
                  hovered: _hovered,
                  dark: widget.dark,
                  centerLabel: widget.rootLabel,
                  centerTotal: widget.rootTotal,
                ),
              ),
              if (_hovered != null && _mousePosition != null)
                _buildTooltip(_hovered!, size),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(_SunburstSegment segment, Size size) {
    final Offset pos = _mousePosition!;
    final double left = (pos.dx + 12).clamp(
      8.0,
      math.max(8.0, size.width - _tooltipWidth - 8),
    );
    final double top = (pos.dy - _tooltipHeight - 8).clamp(
      8.0,
      math.max(8.0, size.height - _tooltipHeight - 8),
    );

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: _tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: UsPremiumPalette.surface(widget.dark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: UsPremiumPalette.border(widget.dark)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.dark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                segment.label,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: UsPremiumPalette.text(widget.dark),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _SunburstPainter.quadrantColor(segment.colorGroup),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${segment.value.toStringAsFixed(0)} items',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: UsPremiumPalette.muted(widget.dark),
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

  List<_SunburstNode> _buildTree(List<StaticSunburstNode> flat) {
    final Map<String, _SunburstNode> map = <String, _SunburstNode>{};
    for (final StaticSunburstNode node in flat) {
      map[node.id] = _SunburstNode(
        id: node.id,
        label: node.label,
        value: node.value,
        colorGroup: node.colorGroup,
      );
    }
    final List<_SunburstNode> roots = <_SunburstNode>[];
    for (final StaticSunburstNode node in flat) {
      final _SunburstNode current = map[node.id]!;
      if (node.parentId == null) {
        roots.add(current);
      } else {
        map[node.parentId!]?.children.add(current);
      }
    }
    return roots;
  }

  List<_SunburstSegment> _layoutSegments(List<_SunburstNode> roots, Size size) {
    final double side = math.min(size.width, size.height) * 0.78;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    const double startAngle = -math.pi / 2;

    final double hub = side * 0.14;
    final List<double> ringOuter = <double>[
      side * 0.32,
      side * 0.52,
      side * 0.72,
    ];

    final List<_SunburstSegment> segments = <_SunburstSegment>[];
    _layoutRing(
      nodes: roots,
      startAngle: startAngle,
      sweep: math.pi * 2,
      inner: hub,
      outer: ringOuter[0],
      depth: 1,
      cx: cx,
      cy: cy,
      ringOuter: ringOuter,
      segments: segments,
      colorGroup: null,
    );
    return segments;
  }

  void _layoutRing({
    required List<_SunburstNode> nodes,
    required double startAngle,
    required double sweep,
    required double inner,
    required double outer,
    required int depth,
    required double cx,
    required double cy,
    required List<double> ringOuter,
    required List<_SunburstSegment> segments,
    required int? colorGroup,
  }) {
    if (nodes.isEmpty) return;

    final double total = nodes.fold(0.0, (double s, _SunburstNode n) => s + n.value);
    double cursor = startAngle;

    for (final _SunburstNode node in nodes) {
      final double nodeSweep = sweep * (node.value / total);
      final int group = colorGroup ?? node.colorGroup;

      segments.add(
        _SunburstSegment(
          label: node.label,
          value: node.value,
          startAngle: cursor,
          sweepAngle: nodeSweep,
          innerRadius: inner,
          outerRadius: outer,
          colorGroup: group,
          depth: depth,
          cx: cx,
          cy: cy,
        ),
      );

      if (node.children.isNotEmpty && depth < ringOuter.length) {
        _layoutRing(
          nodes: node.children,
          startAngle: cursor,
          sweep: nodeSweep,
          inner: outer,
          outer: ringOuter[depth],
          depth: depth + 1,
          cx: cx,
          cy: cy,
          ringOuter: ringOuter,
          segments: segments,
          colorGroup: group,
        );
      }

      cursor += nodeSweep;
    }
  }

  _SunburstSegment? _hitTest(Offset pos, Size size, List<_SunburstSegment> segments) {
    final double dx = pos.dx - size.width / 2;
    final double dy = pos.dy - size.height / 2;
    final double r = math.sqrt(dx * dx + dy * dy);
    double angle = math.atan2(dy, dx);
    if (angle < -math.pi / 2) angle += math.pi * 2;

    for (final _SunburstSegment seg in segments.reversed) {
      if (r >= seg.innerRadius && r <= seg.outerRadius && _angleInArc(angle, seg.startAngle, seg.sweepAngle)) {
        return seg;
      }
    }
    return null;
  }

  bool _angleInArc(double angle, double start, double sweep) {
    double normalized = angle;
    double end = start + sweep;
    while (normalized < start) {
      normalized += math.pi * 2;
    }
    return normalized >= start && normalized <= end;
  }
}

class _SunburstNode {
  _SunburstNode({
    required this.id,
    required this.label,
    required this.value,
    required this.colorGroup,
  });

  final String id;
  final String label;
  final double value;
  final int colorGroup;
  final List<_SunburstNode> children = <_SunburstNode>[];
}

class _SunburstSegment {
  const _SunburstSegment({
    required this.label,
    required this.value,
    required this.startAngle,
    required this.sweepAngle,
    required this.innerRadius,
    required this.outerRadius,
    required this.colorGroup,
    required this.depth,
    required this.cx,
    required this.cy,
  });

  final String label;
  final double value;
  final double startAngle;
  final double sweepAngle;
  final double innerRadius;
  final double outerRadius;
  final int colorGroup;
  final int depth;
  final double cx;
  final double cy;
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter({
    required this.segments,
    required this.hovered,
    required this.dark,
    required this.centerLabel,
    required this.centerTotal,
  });

  final List<_SunburstSegment> segments;
  final _SunburstSegment? hovered;
  final bool dark;
  final String centerLabel;
  final double centerTotal;

  static const List<Color> _quadrants = UsPremiumChartColors.sunburstQuadrants;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final Paint divider = Paint()
      ..color = UsPremiumPalette.surface(dark)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (final _SunburstSegment seg in segments) {
      final bool isHovered = identical(seg, hovered);
      final Color base = quadrantColor(seg.colorGroup);
      final double alpha = seg.depth == 1
          ? (dark ? 0.92 : 0.88)
          : seg.depth == 2
              ? (dark ? 0.78 : 0.72)
              : (dark ? 0.65 : 0.58);
      final Color fill = isHovered ? base.withValues(alpha: 1) : base.withValues(alpha: alpha);

      final Path path = _arcPath(seg);
      canvas.drawPath(
        path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(path, divider);

      if (seg.sweepAngle > 0.34) {
        _drawLabel(canvas, seg);
      }
    }

    final double hubR = segments.isEmpty ? size.shortestSide * 0.14 : segments.first.innerRadius;
    canvas.drawCircle(
      Offset(cx, cy),
      hubR,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            UsPremiumPalette.surface(dark),
            UsPremiumPalette.surface(dark).withValues(alpha: 0.96),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: hubR)),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      hubR,
      Paint()
        ..color = UsPremiumPalette.border(dark)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final TextPainter title = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: hubR * 0.34,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: hubR * 1.6);
    title.paint(canvas, Offset(cx - title.width / 2, cy - title.height / 2 - 4));

    final TextPainter total = TextPainter(
      text: TextSpan(
        text: '(${centerTotal.toStringAsFixed(0)})',
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: hubR * 0.24,
          color: UsPremiumPalette.muted(dark),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: hubR * 1.6);
    total.paint(canvas, Offset(cx - total.width / 2, cy + 2));
  }

  static Color quadrantColor(int colorGroup) =>
      _quadrants[colorGroup % _quadrants.length];

  Path _arcPath(_SunburstSegment seg) {
    final Rect rect = Rect.fromCircle(
      center: Offset(seg.cx, seg.cy),
      radius: seg.outerRadius,
    );
    final Rect innerRect = Rect.fromCircle(
      center: Offset(seg.cx, seg.cy),
      radius: seg.innerRadius,
    );
    final Path path = Path()
      ..arcTo(rect, seg.startAngle, seg.sweepAngle, false)
      ..arcTo(innerRect, seg.startAngle + seg.sweepAngle, -seg.sweepAngle, false)
      ..close();
    return path;
  }

  void _drawLabel(Canvas canvas, _SunburstSegment seg) {
    final double midAngle = seg.startAngle + seg.sweepAngle / 2;
    final double labelR = (seg.innerRadius + seg.outerRadius) / 2;
    final Offset pos = Offset(
      seg.cx + math.cos(midAngle) * labelR,
      seg.cy + math.sin(midAngle) * labelR,
    );

    final String text = seg.value.toStringAsFixed(0);
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: seg.depth == 3 ? 7 : 8.5,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: dark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF0F172A),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: (seg.outerRadius - seg.innerRadius) * 1.20);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (midAngle > math.pi / 2 && midAngle < math.pi * 1.5) {
      canvas.rotate(midAngle + math.pi);
    } else {
      canvas.rotate(midAngle);
    }
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.hovered != hovered ||
      oldDelegate.dark != dark;
}
