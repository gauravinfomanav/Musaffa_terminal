// Mini preview widgets for flagship splash styles (used by splash_animation_lab_screen.dart)

import 'dart:math' as math;

import 'package:flutter/material.dart';

class MiniNoir extends StatelessWidget {
  const MiniNoir({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white.withValues(alpha: 0.85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(4, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniMercury extends StatelessWidget {
  const MiniMercury({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          Transform.rotate(
            angle: -0.4,
            child: Container(
              width: 8,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniEditorial extends StatelessWidget {
  const MiniEditorial({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 16,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 8),
        Text(
          'TERMINAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class MiniAtelier extends StatelessWidget {
  const MiniAtelier({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 0.9,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniZenith extends StatelessWidget {
  const MiniZenith({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 28,
          height: 1,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 8),
        Text(
          'TERMINAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.8,
          ),
        ),
      ],
    );
  }
}

class MiniPorcelain extends StatelessWidget {
  const MiniPorcelain({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.25),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

class MiniSignature extends StatelessWidget {
  const MiniSignature({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'TERMINAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

class MiniLumina extends StatelessWidget {
  const MiniLumina({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 40),
      painter: _MiniLuminaPainter(),
    );
  }
}

class _MiniLuminaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 72, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      c,
      6,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      c + const Offset(-18, 0),
      3,
      Paint()..color = const Color(0xFFE4621E).withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      c + const Offset(18, 0),
      3,
      Paint()..color = const Color(0xFF232C64).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniEthereal extends StatelessWidget {
  const MiniEthereal({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        const Icon(Icons.circle, size: 8, color: Colors.white),
      ],
    );
  }
}

class MiniSovereign extends StatelessWidget {
  const MiniSovereign({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(56, 56),
      painter: _MiniSovereignPainter(),
    );
  }
}

class _MiniSovereignPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const colors = [
      Color(0xFFE4621E),
      Color(0xFFD2364C),
      Color(0xFFA72669),
      Color(0xFF6A2C72),
      Color(0xFF232C64),
    ];
    for (var i = 0; i < 8; i++) {
      final angle = i / 8 * math.pi * 2;
      final end = c + Offset(math.cos(angle), math.sin(angle)) * 22;
      canvas.drawLine(
        c,
        end,
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 0.55)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(c, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniVelvet extends StatelessWidget {
  const MiniVelvet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A1420), Color(0xFF1A0E14)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0E14), Color(0xFF2A1420)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniObsidian extends StatelessWidget {
  const MiniObsidian({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 48),
      painter: _MiniObsidianPainter(),
    );
  }
}

class _MiniObsidianPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.55, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.25, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.55),
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniQuantum extends StatelessWidget {
  const MiniQuantum({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 48),
      painter: _MiniQuantumPainter(),
    );
  }
}

class _MiniQuantumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const pts = [
      Offset(8, 8),
      Offset(64, 10),
      Offset(10, 40),
      Offset(62, 38),
      Offset(36, 6),
      Offset(36, 42),
    ];
    for (final p in pts) {
      canvas.drawLine(
        p,
        c,
        Paint()
          ..color = const Color(0xFF6366F1).withValues(alpha: 0.35)
          ..strokeWidth = 0.8,
      );
      canvas.drawCircle(p, 2.2, Paint()..color = const Color(0xFFA5B4FC));
    }
    canvas.drawCircle(c, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
