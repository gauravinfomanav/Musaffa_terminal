import 'dart:math' as math;

import 'package:flutter/material.dart';

class ComplianceDonutChart extends StatelessWidget {
  const ComplianceDonutChart({
    super.key,
    required this.halal,
    required this.doubtful,
    required this.notHalal,
    required this.halalColor,
    required this.doubtfulColor,
    required     this.notHalalColor,
    this.size = 230,
    this.bottomSpacing = 0,
  });

  final double halal;
  final double doubtful;
  final double notHalal;
  final Color halalColor;
  final Color doubtfulColor;
  final Color notHalalColor;
  final double size;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(
              values: <double>[halal, doubtful, notHalal],
              colors: <Color>[halalColor, doubtfulColor, notHalalColor],
              size: size,
            ),
          ),
        ),
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.size,
  });

  final List<double> values;
  final List<Color> colors;
  final double size;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (a, b) => a + b);
    if (total <= 0) return;

    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final double radius = math.min(size.width, size.height) / 2;
    final double stroke = this.size * 24 / 180;
    double start = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final double sweep = (values[i] / total) * 2 * math.pi;
      final Paint paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class ComplianceGaugeChart extends StatelessWidget {
  const ComplianceGaugeChart({
    super.key,
    required this.value,
    required this.threshold,
    required this.passColor,
    required this.failColor,
    this.size = 220,
  });

  final double value;
  final double threshold;
  final Color passColor;
  final Color failColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size * 0.62),
            painter: _GaugePainter(
              value: value,
              threshold: threshold,
              passColor: passColor,
              failColor: failColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Text(
              '${value.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.threshold,
    required this.passColor,
    required this.failColor,
  });

  final double value;
  final double threshold;
  final Color passColor;
  final Color failColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height);
    final double radius = size.width * 0.42;
    const double stroke = 18;
    const double start = math.pi;
    const double sweep = math.pi;

    final double thresholdAngle = start + (threshold / 100).clamp(0, 1) * sweep;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint passPaint = Paint()
      ..color = passColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, start, thresholdAngle - start, false, passPaint);

    final Paint failPaint = Paint()
      ..color = failColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, thresholdAngle, start + sweep - thresholdAngle, false,
        failPaint);

    final double needleAngle = start + (value / 100).clamp(0, 1) * sweep;
    final Offset needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 8),
      center.dy + math.sin(needleAngle) * (radius - 8),
    );
    final Paint needlePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 4, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => true;
}
