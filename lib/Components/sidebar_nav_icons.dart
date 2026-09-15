import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Sidebar navigation glyphs — SVG assets from `resources/icon*.svg`.
enum SidebarGlyph {
  dashboard,
  screener,
  ideas,
  portfolio,
  assignments,
  watchlist,
  earnings,
  economic,
  splash,
  logout,
}

class SidebarNavIcon extends StatelessWidget {
  const SidebarNavIcon({
    super.key,
    required this.glyph,
    required this.selected,
    this.size = 17,
    this.gradient,
    this.color,
  });

  final SidebarGlyph glyph;
  final bool selected;
  final double size;

  /// When set with [selected], paints the glyph with this gradient via ShaderMask.
  final LinearGradient? gradient;

  /// Solid tint override (e.g. white on gradient pill, logout danger).
  final Color? color;

  static const Color idleColor = Color(0xFF7E7E7E);

  static Color idle(bool dark) => idleColor;

  static Color hover(bool dark) =>
      dark ? const Color(0xFFB0B0B0) : const Color(0xFF5A5A5A);

  /// Active brand wash —
  /// `linear-gradient(90deg, rgba(228,98,30,0.89) … #232C64)`.
  static const LinearGradient activeGradient = HomeUi.iconFillGradient;

  static String? assetFor(SidebarGlyph glyph) {
    switch (glyph) {
      case SidebarGlyph.dashboard:
        return 'resources/iconDashboard.svg';
      case SidebarGlyph.screener:
        return 'resources/iconStockScreener.svg';
      case SidebarGlyph.ideas:
        return 'resources/iconIdeas.svg';
      case SidebarGlyph.portfolio:
        return 'resources/iconPortfolio.svg';
      case SidebarGlyph.assignments:
        return 'resources/iconAssignments.svg';
      case SidebarGlyph.watchlist:
        return 'resources/iconWatchlist.svg';
      case SidebarGlyph.earnings:
        return 'resources/iconEarningsCalendar.svg';
      case SidebarGlyph.economic:
        return 'resources/iconEconomicCalendar.svg';
      case SidebarGlyph.logout:
        return 'resources/iconLogout.svg';
      case SidebarGlyph.splash:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(glyph);
    final useGradient = selected && color == null;

    Widget paintGlyph(Color tint) {
      if (asset != null) {
        return SvgPicture.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        );
      }
      return CustomPaint(
        size: Size.square(size),
        painter: _SplashGlyphPainter(color: tint),
      );
    }

    if (useGradient) {
      final fill = gradient ?? activeGradient;
      return SizedBox(
        width: size,
        height: size,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => fill.createShader(bounds),
          child: paintGlyph(Colors.white),
        ),
      );
    }

    final tint = color ?? idleColor;
    return SizedBox(
      width: size,
      height: size,
      child: paintGlyph(tint),
    );
  }
}

class _SplashGlyphPainter extends CustomPainter {
  _SplashGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(12, 12), 7.6, stroke);
    canvas.drawCircle(const Offset(12, 12), 3.2, stroke);
    canvas.drawLine(const Offset(12, 2.8), const Offset(12, 5.2), stroke);
    canvas.drawLine(const Offset(12, 18.8), const Offset(12, 21.2), stroke);
    canvas.drawLine(const Offset(2.8, 12), const Offset(5.2, 12), stroke);
    canvas.drawLine(const Offset(18.8, 12), const Offset(21.2, 12), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashGlyphPainter old) => old.color != color;
}

/// Header menu trigger — refined three-line mark / close.
class SidebarMenuGlyph extends StatelessWidget {
  const SidebarMenuGlyph({
    super.key,
    required this.open,
    required this.active,
    this.size = 18,
    this.mutedColor = const Color(0xFF7E7E7E),
    this.activeGradient,
  });

  final bool open;
  final bool active;
  final double size;
  final Color mutedColor;

  /// Brand stroke fill when [active] (hover / open). Defaults to [HomeUi.iconFillGradient].
  final LinearGradient? activeGradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MenuGlyphPainter(
          open: open,
          color: mutedColor,
          gradient: active
              ? (activeGradient ?? HomeUi.iconFillGradient)
              : null,
        ),
      ),
    );
  }
}

class _MenuGlyphPainter extends CustomPainter {
  _MenuGlyphPainter({
    required this.open,
    required this.color,
    this.gradient,
  });

  final bool open;
  final Color color;
  final LinearGradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    } else {
      paint.color = color;
    }

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

    canvas.drawLine(
      Offset(cx - 6.5, cy - 4.5),
      Offset(cx + 4.5, cy - 4.5),
      paint,
    );
    canvas.drawLine(
      Offset(cx - 5.5, cy),
      Offset(cx + 6.5, cy),
      paint,
    );
    canvas.drawLine(
      Offset(cx - 4.5, cy + 4.5),
      Offset(cx + 5.5, cy + 4.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MenuGlyphPainter old) =>
      old.open != open ||
      old.color != color ||
      old.gradient != gradient;
}
