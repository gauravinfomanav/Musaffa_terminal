part of 'splash_lab_animations.dart';

// --- 30. Ethereal - mist clears, brand emerges through soft light ------------

class _EtherealSplash extends StatelessWidget {
  const _EtherealSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final clear = _easeInOutQuint(_seg(t, 0.0, 0.58));
    final logoIn = _easeOutExpo(_seg(t, 0.30, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final mist = (1 - clear).clamp(0.0, 1.0);

    return ColoredBox(
      color: const Color(0xFF0A0A0E),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 1.1,
                  colors: [
                    Color.lerp(
                      const Color(0xFF1A1520),
                      const Color(0xFF2A1828),
                      clear,
                    )!,
                    const Color(0xFF0A0A0E),
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _EtherealMistPainter(clear: clear, flow: t),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.86 + logoIn * 0.14,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: mist * 10,
                          sigmaY: mist * 10,
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.62, 0.84)),
                    child: Text(
                      'THROUGH THE MIST',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: Opacity(
                opacity: mist * 0.85,
                child: CustomPaint(
                  painter: _EtherealVeilPainter(density: mist),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtherealMistPainter extends CustomPainter {
  _EtherealMistPainter({required this.clear, required this.flow});

  final double clear;
  final double flow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    for (var i = 0; i < 4; i++) {
      final drift = math.sin(flow * math.pi * 2 + i) * 12 * (1 - clear);
      final r = size.shortestSide * (0.28 + i * 0.12);
      canvas.drawCircle(
        c + Offset(drift, i * 8.0),
        r,
        Paint()
          ..color = _brandSpectrum[i % _brandSpectrum.length]
              .withValues(alpha: 0.06 * (1 - clear * 0.7))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EtherealMistPainter old) =>
      old.clear != clear || old.flow != flow;
}

class _EtherealVeilPainter extends CustomPainter {
  _EtherealVeilPainter({required this.density});
  final double density;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.height),
          [
            Colors.white.withValues(alpha: 0.14 * density),
            Colors.white.withValues(alpha: 0.04 * density),
            Colors.transparent,
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _EtherealVeilPainter old) =>
      old.density != density;
}

// --- 31. Obsidian - glossy dark plane with specular sweep ---------------------

class _ObsidianSplash extends StatelessWidget {
  const _ObsidianSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sweep = _easeInOutQuint(_seg(t, 0.0, 0.52));
    final logoIn = _easeOutExpo(_seg(t, 0.34, 0.60));
    final wordIn = _easeOutCubic(_seg(t, 0.52, 0.76));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141418), Color(0xFF050506), Color(0xFF0C0C10)],
        ),
      ),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ObsidianSheenPainter(sweep: sweep),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.82 + logoIn * 0.18,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white
                                  .withValues(alpha: 0.08 * logoIn),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.96),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.64, 0.84)),
                    child: Text(
                      'POLISHED PRECISION',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.32),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObsidianSheenPainter extends CustomPainter {
  _ObsidianSheenPainter({required this.sweep});
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.35 + sweep * size.width * 1.7;
    final path = Path()
      ..moveTo(x, -size.height * 0.1)
      ..lineTo(x + size.width * 0.22, -size.height * 0.1)
      ..lineTo(x + size.width * 0.08, size.height * 1.1)
      ..lineTo(x - size.width * 0.14, size.height * 1.1)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, 0),
          Offset(x + size.width * 0.22, 0),
          [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          const [0.0, 0.45, 0.55, 1.0],
        ),
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.72),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _ObsidianSheenPainter old) =>
      old.sweep != sweep;
}

// --- 32. Sovereign - radial brand rays bloom from core ----------------------

class _SovereignSplash extends StatelessWidget {
  const _SovereignSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rays = _easeOutQuint(_seg(t, 0.0, 0.55));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF08060A),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _SovereignRaysPainter(rays: rays, spin: t),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.7 + logoIn * 0.3,
                    child: Opacity(
                      opacity: logoIn,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE4621E)
                                  .withValues(alpha: 0.4 * logoIn),
                              blurRadius: 56,
                            ),
                            BoxShadow(
                              color: const Color(0xFF232C64)
                                  .withValues(alpha: 0.25 * logoIn),
                              blurRadius: 72,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.62, 0.84)),
                    child: Text(
                      'COMMAND THE MARKET',
                      style: TextStyle(
                        color: const Color(0xFFE4621E).withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SovereignRaysPainter extends CustomPainter {
  _SovereignRaysPainter({required this.rays, required this.spin});

  final double rays;
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    const count = 14;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + spin * math.pi * 0.15;
      final len = size.shortestSide * (0.35 + rays * 0.55);
      final color = _brandSpectrum[i % _brandSpectrum.length];
      final end = c + Offset(math.cos(angle), math.sin(angle)) * len;
      canvas.drawLine(
        c,
        end,
        Paint()
          ..color = color.withValues(alpha: 0.14 * rays)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawCircle(
      c,
      size.shortestSide * 0.18 * rays,
      Paint()
        ..color = const Color(0xFFE4621E).withValues(alpha: 0.08 * rays)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );
  }

  @override
  bool shouldRepaint(covariant _SovereignRaysPainter old) =>
      old.rays != rays || old.spin != spin;
}

// --- 33. Velvet - luxury curtains part to reveal brand ------------------------

class _VelvetSplash extends StatelessWidget {
  const _VelvetSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Curtains slide fully off-screen so content BG becomes full width.
    final part = _easeInOutQuint(_seg(t, 0.0, 0.58));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.60));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final half = size.width / 2;
    // Content opening grows 0 → full width; curtains translate completely off.
    final openW = half * part;
    final curtainShift = half * part;
    final showCurtains = part < 0.998;

    return ColoredBox(
      color: const Color(0xFF120A10),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Content stage — expands to full width as curtains part.
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: (openW * 2).clamp(0.0, size.width),
                height: size.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85 + part * 0.25,
                      colors: [
                        Color.lerp(
                          const Color(0xFF2A1420),
                          const Color(0xFF3A1A28),
                          part,
                        )!
                            .withValues(alpha: 0.95),
                        const Color(0xFF120A10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.88 + logoIn * 0.12,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.60, 0.82)),
                    child: Text(
                      'THE MAIN STAGE',
                      style: TextStyle(
                        color: const Color(0xFFD2364C).withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showCurtains) ...[
              // Left curtain — slides fully off to the left.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: half,
                child: Transform.translate(
                  offset: Offset(-curtainShift, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF1A0E14), Color(0xFF2A1420)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45 * (1 - part)),
                          blurRadius: 24,
                          offset: const Offset(8, 0),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: List.generate(5, (i) {
                        final fold = (i + 1) / 6;
                        return Positioned(
                          left: half * fold * 0.9,
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: Opacity(
                            opacity: (1 - part) * 0.22,
                            child: const ColoredBox(color: Color(0x33FFFFFF)),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              // Right curtain — slides fully off to the right.
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: half,
                child: Transform.translate(
                  offset: Offset(curtainShift, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Color(0xFF1A0E14), Color(0xFF2A1420)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45 * (1 - part)),
                          blurRadius: 24,
                          offset: const Offset(-8, 0),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: List.generate(5, (i) {
                        final fold = (i + 1) / 6;
                        return Positioned(
                          right: half * fold * 0.9,
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: Opacity(
                            opacity: (1 - part) * 0.22,
                            child: const ColoredBox(color: Color(0x33FFFFFF)),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- 34. Quantum - particle field converges with shimmer ----------------------

class _QuantumSplash extends StatelessWidget {
  const _QuantumSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final converge = _easeInOutQuint(_seg(t, 0.0, 0.58));
    final logoIn = _easeOutExpo(_seg(t, 0.38, 0.64));
    final wordIn = _easeOutCubic(_seg(t, 0.54, 0.78));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);

    return ColoredBox(
      color: const Color(0xFF050508),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _QuantumFieldPainter(converge: converge, flow: t),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.6 + logoIn * 0.4,
                    child: Opacity(
                      opacity: logoIn,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.64, 0.84)),
                    child: Text(
                      'FIELD CONVERGED',
                      style: TextStyle(
                        color: const Color(0xFFA5B4FC).withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantumFieldPainter extends CustomPainter {
  _QuantumFieldPainter({required this.converge, required this.flow});

  final double converge;
  final double flow;

  static const _seeds = [
    Offset(0.08, 0.18),
    Offset(0.92, 0.14),
    Offset(0.15, 0.82),
    Offset(0.88, 0.78),
    Offset(0.05, 0.48),
    Offset(0.95, 0.52),
    Offset(0.28, 0.10),
    Offset(0.72, 0.90),
    Offset(0.40, 0.88),
    Offset(0.60, 0.12),
    Offset(0.22, 0.62),
    Offset(0.78, 0.38),
    Offset(0.50, 0.06),
    Offset(0.50, 0.94),
    Offset(0.35, 0.35),
    Offset(0.65, 0.65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final target = Offset(size.width / 2, size.height * 0.42);
    for (var i = 0; i < _seeds.length; i++) {
      final s = Offset(
        _seeds[i].dx * size.width,
        _seeds[i].dy * size.height,
      );
      final wobble = math.sin(flow * math.pi * 4 + i) * 6 * (1 - converge);
      final p = Offset.lerp(s, target, converge)! + Offset(wobble, -wobble * 0.5);
      final color = _brandSpectrum[i % _brandSpectrum.length];
      final alpha = (1 - converge * 0.75).clamp(0.0, 1.0);
      canvas.drawCircle(
        p,
        2.2 + (i % 3),
        Paint()
          ..color = color.withValues(alpha: 0.75 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      if (converge > 0.1 && converge < 0.92) {
        canvas.drawLine(
          s,
          p,
          Paint()
            ..color = color.withValues(alpha: 0.08 * alpha)
            ..strokeWidth = 0.8,
        );
      }
    }
    final pulse = 1 + 0.06 * math.sin(flow * math.pi * 6);
    canvas.drawCircle(
      target,
      36 * converge * pulse,
      Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: 0.12 * converge)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  @override
  bool shouldRepaint(covariant _QuantumFieldPainter old) =>
      old.converge != converge || old.flow != flow;
}

// --- 35. Lumina - elegant lens flare bloom (Apple-grade) ----------------------

class _LuminaSplash extends StatelessWidget {
  const _LuminaSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final flare = _easeOutQuint(_seg(t, 0.0, 0.48));
    final settle = _easeInOutCubic(_seg(t, 0.38, 0.62));
    final logoIn = _easeOutExpo(_seg(t, 0.32, 0.58));
    final wordIn = _easeOutCubic(_seg(t, 0.50, 0.74));
    final exit = _exitOf(t);
    final logoSize = (size.shortestSide * 0.14).clamp(72.0, 110.0);
    final flareFade = (1 - settle).clamp(0.0, 1.0);

    return ColoredBox(
      color: const Color(0xFF060608),
      child: _SplashExit(
        exit: exit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _LuminaFlarePainter(
                intensity: flare * flareFade,
                flow: t,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: logoIn,
                    child: Transform.scale(
                      scale: 0.84 + logoIn * 0.16,
                      child: _MusaffaLogoMark(size: logoSize),
                    ),
                  ),
                  SizedBox(height: logoSize * 0.28),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: (size.width * 0.038).clamp(24.0, 36.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 9,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: _easeOutCubic(_seg(t, 0.62, 0.84)),
                    child: Text(
                      'CLARITY IN LIGHT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuminaFlarePainter extends CustomPainter {
  _LuminaFlarePainter({required this.intensity, required this.flow});

  final double intensity;
  final double flow;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.01) return;
    final c = Offset(size.width / 2, size.height * 0.40);
    final streakW = size.width * 0.85;

    // Horizontal anamorphic streak
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c,
          width: streakW * intensity,
          height: 8 * intensity,
        ),
        const Radius.circular(4),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx - streakW / 2, c.dy),
          Offset(c.dx + streakW / 2, c.dy),
          [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.55 * intensity),
            Colors.white.withValues(alpha: 0.85 * intensity),
            Colors.white.withValues(alpha: 0.55 * intensity),
            Colors.transparent,
          ],
          const [0.0, 0.35, 0.5, 0.65, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Core bloom
    canvas.drawCircle(
      c,
      48 * intensity,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Spectral orbs along axis
    for (var i = -2; i <= 2; i++) {
      if (i == 0) continue;
      final dx = i * size.width * 0.14;
      final orbR = (12 - i.abs() * 3) * intensity;
      canvas.drawCircle(
        c + Offset(dx, 0),
        orbR,
        Paint()
          ..color = _brandSpectrum[(i + 2) % _brandSpectrum.length]
              .withValues(alpha: 0.35 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Subtle vertical shaft
    canvas.drawRect(
      Rect.fromCenter(
        center: c + Offset(0, math.sin(flow * math.pi * 2) * 4),
        width: 2 * intensity,
        height: size.height * 0.55 * intensity,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _LuminaFlarePainter old) =>
      old.intensity != intensity || old.flow != flow;
}

// --- 36. Signature - cinematic fintech logo opening (2.8-3.2s) -----------------
// Art-directed: anticipation hairline -> geometric reveal of existing mark ->
// subtle overshoot settle -> hold -> continuous exit into the app.

class _SignatureSplash extends StatelessWidget {
  const _SignatureSplash({required this.t});
  final double t;

  /// Soft spring overshoot (subtle — not bounce).
  static double _overshoot(double x) {
    x = x.clamp(0.0, 1.0);
    // Critically-damped-ish: rises past 1 then settles.
    return 1 - math.exp(-6.2 * x) * math.cos(3.4 * x);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    // Timing map (normalized to ~3.2s master):
    // 0.00-0.10 anticipation
    // 0.10-0.46 logo reveal / formation
    // 0.40-0.58 word settle
    // 0.46-0.60 micro settle
    // 0.60-0.72 hold
    // 0.72-1.00 seamless exit
    final anticipate = _easeOutCubic(_seg(tt, 0.0, 0.10));
    final reveal = _easeOutQuint(_seg(tt, 0.10, 0.46));
    final form = _overshoot(_seg(tt, 0.12, 0.52));
    final wordIn = _easeOutCubic(_seg(tt, 0.40, 0.62));
    final tagIn = _easeOutCubic(_seg(tt, 0.52, 0.70));
    final hold = _seg(tt, 0.58, 0.72);
    final exit = _easeInOutQuint(_seg(tt, 0.72, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);
    final letters = 'TERMINAL'.split('');

    // Hairline anticipation width
    final lineW = size.width * 0.12 * anticipate + size.width * 0.18 * reveal;
    // Geometric reveal: clip opens from center vertically
    final clipOpen = reveal;
    // Micro motion while forming
    final breath = math.sin(tt * math.pi * 1.2) * 0.6 * (1 - exit);
    final yRise = (1 - reveal) * 14.0;
    // Scale: start slightly small, overshoot softly, settle to 1
    final scale = (0.94 + form * 0.07).clamp(0.94, 1.03);
    // Exit continuity: drift up + soft scale-down (one continuous shot)
    final exitY = -exit * 18.0;
    final exitScale = 1.0 - exit * 0.04;
    final exitOpacity = (1.0 - exit).clamp(0.0, 1.0);

    // Very light early blur only during first half of reveal (not cheap glow)
    final earlyBlur = ((1 - reveal) * 4.5).clamp(0.01, 4.5);

    Widget logo = _MusaffaLogoMark(size: logoSize);
    if (reveal < 0.98) {
      logo = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: earlyBlur,
          sigmaY: earlyBlur,
        ),
        child: logo,
      );
    }

    return ColoredBox(
      color: const Color(0xFF07070A),
      child: Opacity(
        opacity: exitOpacity,
        child: Transform.translate(
          offset: Offset(0, exitY + breath),
          child: Transform.scale(
            scale: exitScale,
            filterQuality: FilterQuality.high,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Quiet vignette — not a decorative gradient wash
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.08),
                      radius: 1.15,
                      colors: [Color(0xFF0C0C10), Color(0xFF07070A)],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Anticipation hairline
                      SizedBox(
                        height: 1,
                        width: lineW.clamp(0.0, size.width * 0.36),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color.lerp(
                                  const Color(0xFFE4621E),
                                  Colors.white,
                                  0.35,
                                )!
                                    .withValues(alpha: 0.55 * anticipate),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: logoSize * 0.22),
                      // Geometric vertical reveal of existing logo mark
                      Transform.translate(
                        offset: Offset(0, yRise),
                        child: Transform.scale(
                          scale: scale,
                          filterQuality: FilterQuality.high,
                          child: Opacity(
                            opacity: (0.15 + reveal * 0.85).clamp(0.0, 1.0),
                            child: ClipRect(
                              clipper: _SignatureRevealClipper(open: clipOpen),
                              child: SizedBox(
                                width: logoSize,
                                height: logoSize,
                                child: logo,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: logoSize * 0.26),
                      // Wordmark — staggered, not a hard fade
                      Opacity(
                        opacity: wordIn,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < letters.length; i++)
                              _SignatureLetter(
                                letter: letters[i],
                                progress: _easeOutCubic(
                                  _seg(
                                    wordIn,
                                    i / letters.length * 0.45,
                                    1.0,
                                  ),
                                ),
                                fontSize:
                                    (size.width * 0.036).clamp(22.0, 34.0),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: tagIn * (0.7 + hold * 0.3),
                        child: Text(
                          'ENTERPRISE TRADING',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.34),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4.8,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignatureRevealClipper extends CustomClipper<Rect> {
  _SignatureRevealClipper({required this.open});
  final double open;

  @override
  Rect getClip(Size size) {
    // Opens from vertical center — respects mark geometry without distorting it.
    final h = size.height * open.clamp(0.0, 1.0);
    final top = (size.height - h) / 2;
    return Rect.fromLTWH(0, top, size.width, h);
  }

  @override
  bool shouldReclip(covariant _SignatureRevealClipper old) =>
      old.open != open;
}

class _SignatureLetter extends StatelessWidget {
  const _SignatureLetter({
    required this.letter,
    required this.progress,
    required this.fontSize,
  });

  final String letter;
  final double progress;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final y = (1 - progress) * 10;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.015),
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, y),
          child: Text(
            letter,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              height: 1,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
      ),
    );
  }
}

// --- 37. Atelier - luxury seal press of the existing mark --------------------

class _AtelierSplash extends StatelessWidget {
  const _AtelierSplash({required this.t});
  final double t;

  static double _press(double x) {
    x = x.clamp(0.0, 1.0);
    // Soft press past target then settle — like a stamp.
    return 1 - math.exp(-5.5 * x) * math.cos(2.8 * x);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    final wait = _easeOutCubic(_seg(tt, 0.0, 0.12));
    final press = _press(_seg(tt, 0.10, 0.48));
    final frame = _easeInOutQuint(_seg(tt, 0.28, 0.58));
    final wordIn = _easeOutCubic(_seg(tt, 0.48, 0.68));
    final exit = _easeInOutQuint(_seg(tt, 0.74, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);

    // Start large + soft, press into crisp place
    final scale = 1.22 - press * 0.22;
    final blur = ((1 - press) * 8).clamp(0.01, 8.0);
    final opacity = (wait * 0.25 + press * 0.75).clamp(0.0, 1.0);
    final framePad = logoSize * 0.22;
    final frameSide = logoSize + framePad * 2;

    return ColoredBox(
      color: const Color(0xFF08070A),
      child: Opacity(
        opacity: (1 - exit).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -exit * 14),
          child: Transform.scale(
            scale: 1 - exit * 0.035,
            filterQuality: FilterQuality.high,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: frameSide,
                    height: frameSide,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.square(frameSide),
                          painter: _AtelierFramePainter(progress: frame),
                        ),
                        Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            filterQuality: FilterQuality.high,
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: blur,
                                sigmaY: blur,
                              ),
                              child: _MusaffaLogoMark(size: logoSize),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: logoSize * 0.2),
                  Opacity(
                    opacity: wordIn,
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: (size.width * 0.034).clamp(20.0, 32.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 10,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _easeOutCubic(_seg(tt, 0.58, 0.76)),
                    child: Text(
                      'CRAFTED FOR MARKETS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.32),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.6,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AtelierFramePainter extends CustomPainter {
  _AtelierFramePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.01) return;
    final inset = size.width * 0.04;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final extract = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      extract,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = Colors.white.withValues(alpha: 0.28 * progress)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AtelierFramePainter old) =>
      old.progress != progress;
}

// --- 38. Zenith - Swiss / ultra-minimal institutional quiet -------------------

class _ZenithSplash extends StatelessWidget {
  const _ZenithSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    final rise = _easeOutExpo(_seg(tt, 0.08, 0.42));
    final line = _easeInOutQuint(_seg(tt, 0.36, 0.58));
    final wordIn = _easeOutCubic(_seg(tt, 0.50, 0.70));
    final exit = _easeInOutQuint(_seg(tt, 0.76, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.13).clamp(70.0, 104.0);
    final y = (1 - rise) * 18;

    return ColoredBox(
      color: const Color(0xFF050505),
      child: Opacity(
        opacity: (1 - exit).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -exit * 10),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, y),
                  child: Opacity(
                    opacity: rise,
                    child: _MusaffaLogoMark(size: logoSize),
                  ),
                ),
                SizedBox(height: logoSize * 0.32),
                SizedBox(
                  width: logoSize * 0.55 * line,
                  height: 1,
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.35 * line),
                  ),
                ),
                SizedBox(height: logoSize * 0.22),
                Opacity(
                  opacity: wordIn,
                  child: Text(
                    'TERMINAL',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: (size.width * 0.032).clamp(18.0, 28.0),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 12,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 39. Porcelain - soft top-light product pedestal reveal -------------------

class _PorcelainSplash extends StatelessWidget {
  const _PorcelainSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    final light = _easeInOutQuint(_seg(tt, 0.0, 0.42));
    final settle = _easeOutQuint(_seg(tt, 0.28, 0.55));
    final wordIn = _easeOutCubic(_seg(tt, 0.48, 0.70));
    final exit = _easeInOutQuint(_seg(tt, 0.74, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);
    final scale = 0.96 + settle * 0.04;
    final lift = (1 - settle) * 10;

    return ColoredBox(
      color: const Color(0xFF0A0A0C),
      child: Opacity(
        opacity: (1 - exit).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -exit * 16),
          child: Transform.scale(
            scale: 1 - exit * 0.03,
            filterQuality: FilterQuality.high,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(
                          const Color(0xFF0A0A0C),
                          const Color(0xFF1A1816),
                          light,
                        )!,
                        const Color(0xFF0A0A0C),
                      ],
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, lift),
                        child: Transform.scale(
                          scale: scale,
                          filterQuality: FilterQuality.high,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(
                                    alpha: light.clamp(0.0, 1.0),
                                  ),
                                ],
                                stops: [0.0, 0.15 + light * 0.85],
                              ).createShader(bounds);
                            },
                            child: Opacity(
                              opacity: (0.2 + light * 0.8).clamp(0.0, 1.0),
                              child: _MusaffaLogoMark(size: logoSize),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: logoSize * 0.08),
                      Opacity(
                        opacity: settle * 0.55,
                        child: Container(
                          width: logoSize * 0.72,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: logoSize * 0.18),
                      Opacity(
                        opacity: wordIn,
                        child: Text(
                          'TERMINAL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: (size.width * 0.034).clamp(20.0, 32.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 9,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: _easeOutCubic(_seg(tt, 0.58, 0.78)),
                        child: Text(
                          'QUIET CONFIDENCE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4.6,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 40. Noir - cinematic iris reveal of existing mark -----------------------

class _NoirSplash extends StatelessWidget {
  const _NoirSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    // Dark stage content — stage-open iris handled by [_SplashRevealGate].
    final markIn = _easeOutExpo(_seg(tt, 0.28, 0.56));
    final wordIn = _easeOutCubic(_seg(tt, 0.50, 0.72));
    final exit = _easeInOutQuint(_seg(tt, 0.74, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.15).clamp(78.0, 118.0);

    // Always dark cinematic stage — premium app dark surfaces.
    // Stage-open iris is handled globally by [_SplashRevealGate] (circle).
    const stageInner = Color(0xFF1A1D22); // HomeUi.elevatedBg (dark)
    const stageOuter = Color(0xFF121417); // HomeUi.headerBg (dark)
    final titleColor = HomeUi.title(true);
    final tagColor = HomeUi.muted(true).withValues(alpha: 0.55);
    final shadowColor = Colors.black.withValues(alpha: 0.55 * markIn);

    final stage = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.12),
          radius: 1.05,
          colors: [stageInner, stageOuter],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset((1 - markIn) * -10, 0),
              child: Opacity(
                opacity: markIn,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 28,
                        offset: const Offset(14, 10),
                      ),
                    ],
                  ),
                  child: _MusaffaLogoMark(size: logoSize),
                ),
              ),
            ),
            SizedBox(height: logoSize * 0.28),
            Opacity(
              opacity: wordIn,
              child: Text(
                'TERMINAL',
                style: TextStyle(
                  color: titleColor.withValues(alpha: 0.94),
                  fontSize: (size.width * 0.034).clamp(20.0, 32.0),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 10,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _easeOutCubic(_seg(tt, 0.58, 0.78)),
              child: Text(
                'IN THE LIGHT',
                style: TextStyle(
                  color: tagColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 4.6,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: (1 - exit).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -exit * 12),
        child: stage,
      ),
    );
  }
}

// --- 41. Mercury - liquid metal bloom, dual sheen, quiet settle --------------

class _MercurySplash extends StatelessWidget {
  const _MercurySplash({required this.t});
  final double t;

  static double _liquidSettle(double x) {
    x = x.clamp(0.0, 1.0);
    // Soft mercury settle — brief overshoot then still.
    return 1 - math.exp(-6.8 * x) * math.cos(2.1 * x);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    // Cinematic mercury timing (~4.0s):
    // 0.00-0.18  atmosphere wakes
    // 0.08-0.46  mark blooms from soft liquid blur → crisp
    // 0.30-0.78  dual sheen sweeps across the mark
    // 0.42-0.68  word + tag settle
    // 0.78-1.00  quiet fade exit
    final atmosphere = _easeOutCubic(_seg(tt, 0.0, 0.28));
    final form = _liquidSettle(_seg(tt, 0.08, 0.48));
    final sheenA = _easeInOutQuint(_seg(tt, 0.30, 0.68));
    final sheenB = _easeInOutQuint(_seg(tt, 0.42, 0.82));
    final ripple = _easeOutQuint(_seg(tt, 0.18, 0.62));
    final wordIn = _easeOutCubic(_seg(tt, 0.50, 0.72));
    final tagIn = _easeOutCubic(_seg(tt, 0.60, 0.80));
    final exit = _easeInOutQuint(_seg(tt, 0.78, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.16).clamp(82.0, 124.0);

    final scale = 1.12 - form * 0.12;
    final blur = ((1 - form) * 10).clamp(0.01, 10.0);
    final markOpacity = (atmosphere * 0.2 + form * 0.8).clamp(0.0, 1.0);
    final rise = (1 - form) * 14;
    final exitOpacity = (1 - exit).clamp(0.0, 1.0);
    final exitScale = 1 - exit * 0.04;

    return ColoredBox(
      color: const Color(0xFF07070A),
      child: Opacity(
        opacity: exitOpacity,
        child: Transform.scale(
          scale: exitScale,
          filterQuality: FilterQuality.high,
          child: Transform.translate(
            offset: Offset(0, -exit * 16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cool graphite atmosphere
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.12),
                      radius: 1.05,
                      colors: [
                        Color.lerp(
                          const Color(0xFF07070A),
                          const Color(0xFF1A1C22),
                          atmosphere * 0.9,
                        )!,
                        const Color(0xFF07070A),
                      ],
                    ),
                  ),
                ),
                // Soft mercury field + expanding ripples
                CustomPaint(
                  painter: _MercuryFieldPainter(
                    atmosphere: atmosphere,
                    ripple: ripple,
                    sheen: sheenA,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, rise),
                        child: Opacity(
                          opacity: markOpacity,
                          child: Transform.scale(
                            scale: scale,
                            filterQuality: FilterQuality.high,
                            child: SizedBox(
                              width: logoSize * 1.55,
                              height: logoSize * 1.55,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ambient liquid glow behind mark
                                  IgnorePointer(
                                    child: Container(
                                      width: logoSize * 1.35,
                                      height: logoSize * 1.35,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(0xFFC8D0DC)
                                                .withValues(
                                              alpha: 0.16 * form,
                                            ),
                                            const Color(0xFF8FA0B8)
                                                .withValues(
                                              alpha: 0.05 * form,
                                            ),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(
                                      sigmaX: blur,
                                      sigmaY: blur,
                                    ),
                                    child: _MusaffaLogoMark(size: logoSize),
                                  ),
                                  // Primary liquid sheen
                                  IgnorePointer(
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: logoSize,
                                        height: logoSize,
                                        child: Opacity(
                                          opacity: 0.55 * form,
                                          child: Transform.translate(
                                            offset: Offset(
                                              -logoSize +
                                                  sheenA * logoSize * 2.35,
                                              0,
                                            ),
                                            child: Transform.rotate(
                                              angle: -0.42,
                                              child: Container(
                                                width: logoSize * 0.42,
                                                height: logoSize * 1.7,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      const Color(0xFFB8C4D4)
                                                          .withValues(
                                                        alpha: 0.25,
                                                      ),
                                                      Colors.white.withValues(
                                                        alpha: 0.72,
                                                      ),
                                                      const Color(0xFF9EB0C4)
                                                          .withValues(
                                                        alpha: 0.2,
                                                      ),
                                                      Colors.transparent,
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.28,
                                                      0.5,
                                                      0.72,
                                                      1.0,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Secondary cooler sheen (offset angle)
                                  IgnorePointer(
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: logoSize,
                                        height: logoSize,
                                        child: Opacity(
                                          opacity: 0.28 * form,
                                          child: Transform.translate(
                                            offset: Offset(
                                              -logoSize +
                                                  sheenB * logoSize * 2.5,
                                              logoSize * 0.08,
                                            ),
                                            child: Transform.rotate(
                                              angle: -0.55,
                                              child: Container(
                                                width: logoSize * 0.22,
                                                height: logoSize * 1.5,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      const Color(0xFFA8C0D8)
                                                          .withValues(
                                                        alpha: 0.45,
                                                      ),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: logoSize * 0.08),
                      // Mirror pool under the mark
                      Opacity(
                        opacity: form * 0.9,
                        child: CustomPaint(
                          size: Size(logoSize * 1.15, logoSize * 0.22),
                          painter: _MercuryMirrorPainter(progress: form),
                        ),
                      ),
                      SizedBox(height: logoSize * 0.18),
                      Opacity(
                        opacity: wordIn,
                        child: Transform.translate(
                          offset: Offset(0, (1 - wordIn) * 8),
                          child: Text(
                            'TERMINAL',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize:
                                  (size.width * 0.034).clamp(20.0, 32.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 10,
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: tagIn,
                        child: Text(
                          'LIQUID PRECISION',
                          style: TextStyle(
                            color: const Color(0xFFB0B8C4)
                                .withValues(alpha: 0.42),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4.8,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft mercury atmosphere — cool bloom + expanding liquid ripples.
class _MercuryFieldPainter extends CustomPainter {
  _MercuryFieldPainter({
    required this.atmosphere,
    required this.ripple,
    required this.sheen,
  });

  final double atmosphere;
  final double ripple;
  final double sheen;

  static const _silver = Color(0xFFC4CCD8);
  static const _cool = Color(0xFF8FA3BC);

  @override
  void paint(Canvas canvas, Size size) {
    if (atmosphere < 0.01) return;
    final c = Offset(size.width / 2, size.height * 0.42);
    final a = atmosphere.clamp(0.0, 1.0);

    // Core cool bloom
    canvas.drawCircle(
      c,
      size.shortestSide * 0.34,
      Paint()
        ..color = _cool.withValues(alpha: 0.07 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );

    // Expanding liquid ripples
    if (ripple > 0.02) {
      for (var i = 0; i < 3; i++) {
        final local = ((ripple - i * 0.12) / (1 - i * 0.12)).clamp(0.0, 1.0);
        if (local <= 0) continue;
        final r = size.shortestSide * (0.12 + local * 0.38);
        final fade = (1 - local) * a * 0.35;
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = _silver.withValues(alpha: fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }

    // Horizontal light skim across field
    if (sheen > 0.01) {
      final y = size.height * (0.28 + sheen * 0.28);
      final rect = Rect.fromLTWH(0, y - 18, size.width, 36);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, y),
            Offset(size.width, y),
            [
              Colors.transparent,
              _silver.withValues(alpha: 0.05 * a),
              Colors.transparent,
            ],
            const [0.15, 0.5, 0.85],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MercuryFieldPainter old) =>
      old.atmosphere != atmosphere ||
      old.ripple != ripple ||
      old.sheen != sheen;
}

/// Thin reflective pool under the mark — liquid mirror line.
class _MercuryMirrorPainter extends CustomPainter {
  _MercuryMirrorPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.01) return;
    final p = progress.clamp(0.0, 1.0);
    final w = size.width * (0.35 + p * 0.65);
    final left = (size.width - w) / 2;
    final cy = size.height * 0.35;

    final rect = Rect.fromLTWH(left, cy - 6, w, 12);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, cy),
          w * 0.55,
          [
            Colors.white.withValues(alpha: 0.18 * p),
            const Color(0xFF9AABBE).withValues(alpha: 0.06 * p),
            Colors.transparent,
          ],
          const [0.0, 0.45, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawLine(
      Offset(left + w * 0.08, cy),
      Offset(left + w * 0.92, cy),
      Paint()
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.22 * p),
    );
  }

  @override
  bool shouldRepaint(covariant _MercuryMirrorPainter old) =>
      old.progress != progress;
}

// --- 42. Editorial - magazine masthead assemble ------------------------------

class _EditorialSplash extends StatelessWidget {
  const _EditorialSplash({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    final markIn = _easeOutExpo(_seg(tt, 0.06, 0.40));
    final rule = _easeInOutQuint(_seg(tt, 0.28, 0.55));
    final wordIn = _easeOutCubic(_seg(tt, 0.42, 0.66));
    final exit = _easeInOutQuint(_seg(tt, 0.74, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.11).clamp(56.0, 88.0);
    final gap = 18.0 + rule * 8;

    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: Opacity(
        opacity: (1 - exit).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -exit * 10),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: markIn,
                      child: Transform.translate(
                        offset: Offset((1 - markIn) * -16, 0),
                        child: _MusaffaLogoMark(size: logoSize),
                      ),
                    ),
                    SizedBox(width: gap),
                    // Vertical masthead rule
                    SizedBox(
                      width: 1,
                      height: logoSize * 0.72 * rule,
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.35 * rule),
                      ),
                    ),
                    SizedBox(width: gap),
                    Opacity(
                      opacity: wordIn,
                      child: Transform.translate(
                        offset: Offset((1 - wordIn) * 16, 0),
                        child: Text(
                          'TERMINAL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: (size.width * 0.038).clamp(22.0, 36.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 8,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: logoSize * 0.4),
                Opacity(
                  opacity: _easeOutCubic(_seg(tt, 0.58, 0.78)),
                  child: Text(
                    'MARKETS · CLARITY · CRAFT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.8,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Tudum - authentic Netflix-style ribbon draw → logo impact --------------

class _TudumSplash extends StatelessWidget {
  const _TudumSplash({required this.t});
  final double t;

  static double _impact(double x) {
    x = x.clamp(0.0, 1.0);
    // Tight cinematic settle (Netflix punch, not spring bounce).
    return 1 - math.exp(-9.5 * x) * math.cos(1.6 * x);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tt = reduce ? 1.0 : t;

    // Netflix bumper timing (~3.6s):
    // 0.00-0.52  red ribbons draw (N-language curves)
    // 0.42-0.62  ribbons bloom + logo impact punch
    // 0.62-0.78  solid hold
    // 0.78-1.00  smooth zoom handoff into app
    final draw = _easeInOutCubic(_seg(tt, 0.0, 0.52));
    final climax = _easeOutQuint(_seg(tt, 0.40, 0.58));
    final punch = _impact(_seg(tt, 0.44, 0.64));
    final hold = _seg(tt, 0.62, 0.78);
    final exit = _easeInOutQuint(_seg(tt, 0.78, 1.0));

    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.18).clamp(92.0, 140.0);

    // Ribbons fade as logo takes the stage
    final ribbonFade = (1.0 - climax * 0.92).clamp(0.0, 1.0);
    // Logo: invisible → sudden Netflix-scale punch (1.55 → 1.0)
    final logoScale = 1.55 - punch * 0.55;
    final logoOpacity = punch.clamp(0.0, 1.0);
    // Exit continues the camera push
    final exitScale = 1.0 + exit * 0.72;
    final exitOpacity = (1.0 - _easeInOutCubic(exit)).clamp(0.0, 1.0);

    // Single-frame impact flash at the "tudum" moment
    final tudumFlash = punch > 0.92 && punch < 1.0
        ? (1 - (punch - 0.92) / 0.08) * 0.22
        : (hold > 0 && hold < 0.15 ? 0.05 : 0.0);

    return ColoredBox(
      color: const Color(0xFF000000),
      child: Opacity(
        opacity: exitOpacity,
        child: Transform.scale(
          scale: exitScale,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _TudumRibbonsPainter(
                  draw: draw,
                  fade: ribbonFade,
                ),
              ),
              // Impact bloom — the "tudum" hit
              if (tudumFlash > 0.001)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE50914).withValues(alpha: tudumFlash),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),
                ),
              Center(
                child: Opacity(
                  opacity: logoOpacity,
                  child: Transform.scale(
                    scale: logoScale.clamp(0.98, 1.6),
                    filterQuality: FilterQuality.high,
                    child: _MusaffaLogoMark(size: logoSize),
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

/// Thick Netflix-style red ribbons — progressive stroke draw with edge lighting.
class _TudumRibbonsPainter extends CustomPainter {
  _TudumRibbonsPainter({required this.draw, required this.fade});

  final double draw;
  final double fade;

  static const _red = Color(0xFFE50914);
  static const _redHi = Color(0xFFFF2A2A);
  static const _redLo = Color(0xFF8B0008);

  Path _leftStem(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.34, h * -0.08)
      ..cubicTo(
        w * 0.30,
        h * 0.22,
        w * 0.31,
        h * 0.55,
        w * 0.36,
        h * 1.08,
      );
  }

  Path _diagonal(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.72, h * -0.05)
      ..cubicTo(
        w * 0.58,
        h * 0.28,
        w * 0.42,
        h * 0.62,
        w * 0.28,
        h * 1.05,
      );
  }

  Path _rightStem(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.66, h * -0.08)
      ..cubicTo(
        w * 0.70,
        h * 0.25,
        w * 0.69,
        h * 0.58,
        w * 0.64,
        h * 1.08,
      );
  }

  void _strokeRibbon(
    Canvas canvas,
    Path full, {
    required double localDraw,
    required double width,
    required double alpha,
  }) {
    if (localDraw <= 0.001 || alpha <= 0.001) return;
    final metrics = full.computeMetrics();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final len = metric.length * localDraw.clamp(0.0, 1.0);
    final drawn = metric.extractPath(0, len);

    // Soft outer glow
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 1.55
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _red.withValues(alpha: 0.22 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Deep shadow edge
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 1.08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _redLo.withValues(alpha: 0.85 * alpha),
    );

    // Core ribbon body
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _red.withValues(alpha: alpha),
    );

    // Specular highlight edge (Netflix metallic sheen)
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.28
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _redHi.withValues(alpha: 0.55 * alpha),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (draw < 0.01 && fade < 0.01) return;
    final a = fade.clamp(0.0, 1.0);
    final ribbonW = size.shortestSide * 0.085;

    // Staggered Netflix N-language strokes
    _strokeRibbon(
      canvas,
      _leftStem(size),
      localDraw: _easeInOutCubic((draw / 0.55).clamp(0.0, 1.0)),
      width: ribbonW,
      alpha: a,
    );
    _strokeRibbon(
      canvas,
      _diagonal(size),
      localDraw: _easeInOutCubic(((draw - 0.12) / 0.55).clamp(0.0, 1.0)),
      width: ribbonW * 0.95,
      alpha: a,
    );
    _strokeRibbon(
      canvas,
      _rightStem(size),
      localDraw: _easeInOutCubic(((draw - 0.22) / 0.55).clamp(0.0, 1.0)),
      width: ribbonW,
      alpha: a,
    );

    // Center convergence bloom as ribbons complete
    if (draw > 0.45) {
      final bloom = ((draw - 0.45) / 0.35).clamp(0.0, 1.0) * a;
      final c = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(
        c,
        size.shortestSide * 0.28 * bloom,
        Paint()
          ..color = _red.withValues(alpha: 0.20 * bloom)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TudumRibbonsPainter old) =>
      old.draw != draw || old.fade != fade;
}
