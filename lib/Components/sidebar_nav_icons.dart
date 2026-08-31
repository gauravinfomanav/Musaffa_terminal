import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Sidebar navigation glyphs — stroke-based, terminal-grade icon set.
enum SidebarGlyph {
  dashboard,
  screener,
  ideas,
  portfolio,
  watchlist,
  earnings,
  economic,
  logout,
}

class SidebarNavIcon extends StatelessWidget {
  const SidebarNavIcon({
    super.key,
    required this.glyph,
    required this.selected,
    this.size = 16,
    this.gradient,
  });

  final SidebarGlyph glyph;
  final bool selected;
  final double size;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final fill = gradient ??
        (selected ? HomeUi.brandGradient : HomeUi.softBrandIconGradient);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SidebarGlyphPainter(
          glyph: glyph,
          gradient: fill,
        ),
      ),
    );
  }
}

class _SidebarGlyphPainter extends CustomPainter {
  _SidebarGlyphPainter({
    required this.glyph,
    required this.gradient,
  });

  final SidebarGlyph glyph;
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.width / 24;
    canvas.scale(scale);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, 24, 24));

    switch (glyph) {
      case SidebarGlyph.dashboard:
        _dashboard(canvas, paint);
      case SidebarGlyph.screener:
        _screener(canvas, paint);
      case SidebarGlyph.ideas:
        _ideas(canvas, paint);
      case SidebarGlyph.portfolio:
        _portfolio(canvas, paint);
      case SidebarGlyph.watchlist:
        _watchlist(canvas, paint);
      case SidebarGlyph.earnings:
        _earnings(canvas, paint);
      case SidebarGlyph.economic:
        _economic(canvas, paint);
      case SidebarGlyph.logout:
        _logout(canvas, paint);
    }

    canvas.restore();
  }

  void _dashboard(Canvas canvas, Paint paint) {
    const r = 2.2;
    for (final rect in [
      const Rect.fromLTWH(3.5, 3.5, 7, 7),
      const Rect.fromLTWH(13.5, 3.5, 7, 7),
      const Rect.fromLTWH(3.5, 13.5, 7, 7),
      const Rect.fromLTWH(13.5, 13.5, 7, 7),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(r)), paint);
    }
  }

  void _screener(Canvas canvas, Paint paint) {
    final funnel = Path()
      ..moveTo(5, 5.5)
      ..lineTo(19, 5.5)
      ..lineTo(15.5, 11.5)
      ..lineTo(15.5, 17.5)
      ..lineTo(8.5, 17.5)
      ..lineTo(8.5, 11.5)
      ..close();
    canvas.drawPath(funnel, paint);
    canvas.drawLine(const Offset(10, 17.5), const Offset(14, 20.5), paint);
    canvas.drawLine(const Offset(14, 17.5), const Offset(10, 20.5), paint);
  }

  void _ideas(Canvas canvas, Paint paint) {
    final trend = Path()
      ..moveTo(4, 17)
      ..lineTo(8.5, 13)
      ..lineTo(12, 14.5)
      ..lineTo(16.5, 8)
      ..lineTo(20, 9.5);
    canvas.drawPath(trend, paint);
    canvas.drawLine(const Offset(16.5, 8), const Offset(16.5, 5.5), paint);
    canvas.drawLine(const Offset(16.5, 8), const Offset(19, 8), paint);
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 24, 24));
    canvas.drawCircle(const Offset(4, 17), 1.15, dot);
    canvas.drawCircle(const Offset(20, 9.5), 1.15, dot);
  }

  void _portfolio(Canvas canvas, Paint paint) {
    const center = Offset(12, 12);
    canvas.drawCircle(center, 8.2, paint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 4.6),
      -math.pi / 2,
      math.pi * 1.35,
      false,
      paint,
    );
    canvas.drawLine(center, center + const Offset(0, -4.6), paint);
    canvas.drawLine(center, center + const Offset(3.2, 2.4), paint);
  }

  void _watchlist(Canvas canvas, Paint paint) {
    final ribbon = Path()
      ..moveTo(8, 4.5)
      ..lineTo(8, 18)
      ..lineTo(12, 15.5)
      ..lineTo(16, 18)
      ..lineTo(16, 4.5)
      ..close();
    canvas.drawPath(ribbon, paint);
    canvas.drawLine(const Offset(10, 9), const Offset(14, 9), paint);
    canvas.drawLine(const Offset(10, 12), const Offset(14, 12), paint);
  }

  void _earnings(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.5, 5, 15, 15),
        const Radius.circular(2.4),
      ),
      paint,
    );
    canvas.drawLine(const Offset(4.5, 9.5), const Offset(19.5, 9.5), paint);
    canvas.drawLine(const Offset(8.5, 3.5), const Offset(8.5, 6.5), paint);
    canvas.drawLine(const Offset(15.5, 3.5), const Offset(15.5, 6.5), paint);
    canvas.drawLine(const Offset(8, 14.5), const Offset(8, 17.5), paint);
    canvas.drawLine(const Offset(12, 13), const Offset(12, 17.5), paint);
    canvas.drawLine(const Offset(16, 15), const Offset(16, 17.5), paint);
  }

  void _economic(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 11), 7.2, paint);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(12, 11), width: 4.2, height: 14.4),
      paint,
    );
    canvas.drawLine(const Offset(4.8, 11), const Offset(19.2, 11), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14.5, 14.5, 6.5, 6.5),
        const Radius.circular(1.6),
      ),
      paint,
    );
    canvas.drawLine(const Offset(16.2, 17.2), const Offset(19.2, 17.2), paint);
  }

  void _logout(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 5, 9, 14),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawLine(const Offset(13.5, 12), const Offset(19.5, 12), paint);
    final arrow = Path()
      ..moveTo(16.5, 9)
      ..lineTo(19.5, 12)
      ..lineTo(16.5, 15);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant _SidebarGlyphPainter old) =>
      old.glyph != glyph || old.gradient != gradient;
}

/// Header menu trigger — refined three-line mark / close.
class SidebarMenuGlyph extends StatelessWidget {
  const SidebarMenuGlyph({
    super.key,
    required this.open,
    required this.active,
    this.size = 18,
    this.mutedColor = const Color(0xFF6B7280),
  });

  final bool open;
  final bool active;
  final double size;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MenuGlyphPainter(
          open: open,
          color: active ? Colors.white : mutedColor,
        ),
      ),
    );
  }
}

class _MenuGlyphPainter extends CustomPainter {
  _MenuGlyphPainter({required this.open, required this.color});

  final bool open;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    if (open) {
      canvas.drawLine(
        Offset(cx - 5.5, cy - 5.5),
        Offset(cx + 5.5, cy + 5.5),
        paint,
      );
      canvas.drawLine(
        Offset(cx + 5.5, cy - 5.5),
        Offset(cx - 5.5, cy + 5.5),
        paint,
      );
      return;
    }

    canvas.drawLine(Offset(cx - 6.5, cy - 4.5), Offset(cx + 4.5, cy - 4.5), paint);
    canvas.drawLine(Offset(cx - 5.5, cy), Offset(cx + 6.5, cy), paint);
    canvas.drawLine(Offset(cx - 4.5, cy + 4.5), Offset(cx + 5.5, cy + 4.5), paint);
  }

  @override
  bool shouldRepaint(covariant _MenuGlyphPainter old) =>
      old.open != open || old.color != color;
}
