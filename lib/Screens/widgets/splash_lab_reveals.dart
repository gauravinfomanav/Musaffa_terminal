part of 'splash_lab_animations.dart';

/// Unique stage-open transitions for every splash style.
enum SplashRevealKind {
  circle,
  horizontal,
  vertical,
  diamond,
  diagonalTl,
  diagonalTr,
  softRadial,
  cross,
  barsHorizontal,
  barsVertical,
  roundedRect,
  diamondSoft,
  wipeLeft,
  wipeRight,
  wipeUp,
  wipeDown,
  ovalWide,
  ovalTall,
  cornerFan,
  hexOpen,
}

SplashRevealKind splashRevealFor(SplashLabStyle style) {
  switch (style) {
    case SplashLabStyle.tudum:
      return SplashRevealKind.horizontal;
    case SplashLabStyle.noir:
      return SplashRevealKind.circle;
    case SplashLabStyle.mercury:
      return SplashRevealKind.diagonalTl;
    case SplashLabStyle.editorial:
      return SplashRevealKind.horizontal;
    case SplashLabStyle.atelier:
      return SplashRevealKind.roundedRect;
    case SplashLabStyle.zenith:
      return SplashRevealKind.vertical;
    case SplashLabStyle.porcelain:
      return SplashRevealKind.softRadial;
    case SplashLabStyle.signature:
      return SplashRevealKind.wipeUp;
    case SplashLabStyle.ethereal:
      return SplashRevealKind.softRadial;
    case SplashLabStyle.obsidian:
      return SplashRevealKind.diagonalTr;
    case SplashLabStyle.sovereign:
      return SplashRevealKind.hexOpen;
    case SplashLabStyle.velvet:
      return SplashRevealKind.wipeLeft;
    case SplashLabStyle.quantum:
      return SplashRevealKind.cross;
    case SplashLabStyle.lumina:
      return SplashRevealKind.ovalWide;
    case SplashLabStyle.beacon:
      return SplashRevealKind.wipeDown;
    case SplashLabStyle.ledger:
      return SplashRevealKind.barsHorizontal;
    case SplashLabStyle.nova:
      return SplashRevealKind.circle;
    case SplashLabStyle.parallax:
      return SplashRevealKind.diamond;
    case SplashLabStyle.signal:
      return SplashRevealKind.barsVertical;
    case SplashLabStyle.vault:
      return SplashRevealKind.roundedRect;
    case SplashLabStyle.sable:
      return SplashRevealKind.wipeRight;
    case SplashLabStyle.circleReveal:
      return SplashRevealKind.circle;
    case SplashLabStyle.orbit:
      return SplashRevealKind.ovalTall;
    case SplashLabStyle.prism:
      return SplashRevealKind.diagonalTl;
    case SplashLabStyle.aurora:
      return SplashRevealKind.horizontal;
    case SplashLabStyle.liquidMetal:
      return SplashRevealKind.softRadial;
    case SplashLabStyle.constellation:
      return SplashRevealKind.cross;
    case SplashLabStyle.ripple:
      return SplashRevealKind.circle;
    case SplashLabStyle.neonTrace:
      return SplashRevealKind.wipeLeft;
    case SplashLabStyle.particleBloom:
      return SplashRevealKind.cornerFan;
    case SplashLabStyle.horizon:
      return SplashRevealKind.wipeUp;
    case SplashLabStyle.silkWipe:
      return SplashRevealKind.horizontal;
    case SplashLabStyle.helix:
      return SplashRevealKind.ovalTall;
    case SplashLabStyle.mirrorDrop:
      return SplashRevealKind.vertical;
    case SplashLabStyle.whisper:
      return SplashRevealKind.softRadial;
    case SplashLabStyle.aperture:
      return SplashRevealKind.hexOpen;
    case SplashLabStyle.meshGlow:
      return SplashRevealKind.diamondSoft;
    case SplashLabStyle.monogram:
      return SplashRevealKind.roundedRect;
    case SplashLabStyle.springInertia:
      return SplashRevealKind.circle;
    case SplashLabStyle.cinema:
      return SplashRevealKind.barsHorizontal;
    case SplashLabStyle.magnetic:
      return SplashRevealKind.cross;
    case SplashLabStyle.frostClear:
      return SplashRevealKind.wipeDown;
    case SplashLabStyle.cascade:
      return SplashRevealKind.barsVertical;
  }
}

/// Wraps splash content with a unique expanding stage reveal.
class _SplashRevealGate extends StatelessWidget {
  const _SplashRevealGate({
    required this.progress,
    required this.kind,
    required this.child,
  });

  final double progress;
  final SplashRevealKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    if (p >= 0.999) return child;
    if (p <= 0.001) {
      return const ColoredBox(color: Color(0xFF08090B));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF08090B)),
        ClipPath(
          clipper: _SplashRevealClipper(kind: kind, progress: p),
          child: child,
        ),
      ],
    );
  }
}

class _SplashRevealClipper extends CustomClipper<Path> {
  _SplashRevealClipper({required this.kind, required this.progress});

  final SplashRevealKind kind;
  final double progress;

  @override
  Path getClip(Size size) {
    final p = progress.clamp(0.0, 1.0);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.sqrt(
          size.width * size.width + size.height * size.height,
        ) /
        2;

    switch (kind) {
      case SplashRevealKind.circle:
        return Path()
          ..addOval(
            Rect.fromCircle(center: Offset(cx, cy), radius: maxR * p),
          );

      case SplashRevealKind.softRadial:
        // Slightly soft oval that grows faster on X.
        return Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: size.width * 1.25 * p,
              height: size.height * 1.15 * p,
            ),
          );

      case SplashRevealKind.ovalWide:
        return Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: size.width * 1.4 * p,
              height: size.height * 0.85 * p,
            ),
          );

      case SplashRevealKind.ovalTall:
        return Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: size.width * 0.85 * p,
              height: size.height * 1.4 * p,
            ),
          );

      case SplashRevealKind.horizontal:
        final w = size.width * p;
        return Path()
          ..addRect(Rect.fromLTWH((size.width - w) / 2, 0, w, size.height));

      case SplashRevealKind.vertical:
        final h = size.height * p;
        return Path()
          ..addRect(Rect.fromLTWH(0, (size.height - h) / 2, size.width, h));

      case SplashRevealKind.wipeLeft:
        return Path()..addRect(Rect.fromLTWH(0, 0, size.width * p, size.height));

      case SplashRevealKind.wipeRight:
        final w = size.width * p;
        return Path()
          ..addRect(Rect.fromLTWH(size.width - w, 0, w, size.height));

      case SplashRevealKind.wipeUp:
        final h = size.height * p;
        return Path()
          ..addRect(Rect.fromLTWH(0, size.height - h, size.width, h));

      case SplashRevealKind.wipeDown:
        return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height * p));

      case SplashRevealKind.diamond:
      case SplashRevealKind.diamondSoft:
        final s = maxR * p * (kind == SplashRevealKind.diamondSoft ? 1.15 : 1);
        return Path()
          ..moveTo(cx, cy - s)
          ..lineTo(cx + s, cy)
          ..lineTo(cx, cy + s)
          ..lineTo(cx - s, cy)
          ..close();

      case SplashRevealKind.diagonalTl:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(size.width * p * 2, 0)
          ..lineTo(0, size.height * p * 2)
          ..close();

      case SplashRevealKind.diagonalTr:
        return Path()
          ..moveTo(size.width, 0)
          ..lineTo(size.width - size.width * p * 2, 0)
          ..lineTo(size.width, size.height * p * 2)
          ..close();

      case SplashRevealKind.cross:
        final tw = size.width * 0.18 + size.width * 0.82 * p;
        final th = size.height * 0.18 + size.height * 0.82 * p;
        final path = Path()
          ..addRect(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: tw,
              height: size.height * 0.22 + size.height * 0.1 * p,
            ),
          )
          ..addRect(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: size.width * 0.22 + size.width * 0.1 * p,
              height: th,
            ),
          );
        return path;

      case SplashRevealKind.barsHorizontal:
        final path = Path();
        const bars = 7;
        final barH = size.height / bars;
        for (var i = 0; i < bars; i++) {
          final local = ((p - i / bars * 0.35) / 0.65).clamp(0.0, 1.0);
          final w = size.width * local;
          path.addRect(
            Rect.fromLTWH((size.width - w) / 2, i * barH, w, barH + 1),
          );
        }
        return path;

      case SplashRevealKind.barsVertical:
        final path = Path();
        const bars = 9;
        final barW = size.width / bars;
        for (var i = 0; i < bars; i++) {
          final local = ((p - i / bars * 0.35) / 0.65).clamp(0.0, 1.0);
          final h = size.height * local;
          path.addRect(
            Rect.fromLTWH(i * barW, (size.height - h) / 2, barW + 1, h),
          );
        }
        return path;

      case SplashRevealKind.roundedRect:
        final w = size.width * p;
        final h = size.height * p;
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: w,
          height: h,
        );
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(24 * (1 - p * 0.5))),
          );

      case SplashRevealKind.cornerFan:
        final path = Path()..moveTo(cx, cy);
        final reach = maxR * p;
        path.lineTo(cx - reach, cy - reach);
        path.lineTo(cx + reach, cy - reach);
        path.lineTo(cx + reach, cy + reach);
        path.lineTo(cx - reach, cy + reach);
        path.close();
        return path;

      case SplashRevealKind.hexOpen:
        final r = maxR * p;
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = -math.pi / 2 + i * math.pi / 3;
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        return path;
    }
  }

  @override
  bool shouldReclip(covariant _SplashRevealClipper old) =>
      old.kind != kind || old.progress != progress;
}
