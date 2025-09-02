import 'dart:math';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
import 'package:musaffa_terminal/models/recommendation_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';

class RecommendationWidget extends StatefulWidget {
  final String symbol;
  final RecommendationController controller;

  const RecommendationWidget({
    Key? key,
    required this.symbol,
    required this.controller,
  }) : super(key: key);

  @override
  State<RecommendationWidget> createState() => _RecommendationWidgetState();
}

class _RecommendationWidgetState extends State<RecommendationWidget> {
  double _pointerValue = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchRecommendation(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return _buildShimmerLoading();
        }

        if (widget.controller.error != null) {
          return Center(
            child: Text(
              'Error: ${widget.controller.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final recommendation = widget.controller.recommendation;
        if (recommendation == null) {
          return const Center(child: Text('No recommendation data available'));
        }

        // Update pointer value based on weighted average
        _pointerValue = recommendation.weightedAverage * 20; // Scale to 0-100

        return Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left side: Custom Gauge
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      'Analyst Consensus',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCustomGauge(recommendation),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.recommendationText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(recommendation.recommendationColor),
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                    Text(
                      '${recommendation.weightedAverage.toStringAsFixed(1)}/5.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right side: Recommendation bars
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyst Ratings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendationBar('Strong Buy', recommendation.strongBuy, Colors.green, widget.controller.getStrongBuyPercentage()),
                    _buildRecommendationBar('Buy', recommendation.buy, Colors.lightGreen, widget.controller.getBuyPercentage()),
                    _buildRecommendationBar('Hold', recommendation.hold, Colors.orange, widget.controller.getHoldPercentage()),
                    _buildRecommendationBar('Sell', recommendation.sell, Colors.red, widget.controller.getSellPercentage()),
                    _buildRecommendationBar('Strong Sell', recommendation.strongSell, Colors.red[900]!, widget.controller.getStrongSellPercentage()),
                    const SizedBox(height: 16),
                    Text(
                      'Total: ${widget.controller.totalRecommendations}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomGauge(RecommendationModel recommendation) {
    return Container(
      width: 180,
      height: 100,
      child: CustomPaint(
        painter: GaugePainter(
          value: _pointerValue,
          color: Color(recommendation.recommendationColor),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left side: Gauge shimmer
          Expanded(
            flex: 2,
            child: Column(
              children: [
                ShimmerWidgets.box(
                  height: 14,
                  width: 120,
                ),
                const SizedBox(height: 12),
                ShimmerWidgets.box(
                  height: 100,
                  width: 180,
                ),
                const SizedBox(height: 8),
                ShimmerWidgets.box(
                  height: 16,
                  width: 80,
                ),
                ShimmerWidgets.box(
                  height: 12,
                  width: 60,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right side: Bars shimmer
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidgets.box(
                  height: 14,
                  width: 100,
                ),
                const SizedBox(height: 12),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                _buildShimmerBar(),
                const SizedBox(height: 16),
                ShimmerWidgets.box(
                  height: 11,
                  width: 80,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ShimmerWidgets.box(
            height: 11,
            width: 70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ShimmerWidgets.box(
              height: 14,
              width: double.infinity,
            ),
          ),
          const SizedBox(width: 8),
          ShimmerWidgets.box(
            height: 11,
            width: 25,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationBar(String label, int count, Color color, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(7),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 25,
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    
    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14, // Start from bottom
      3.14,  // Half circle
      false,
      backgroundPaint,
    );

    // Draw value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (value / 100) * 3.14;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14, // Start from bottom
      sweepAngle,
      false,
      valuePaint,
    );

    // Draw needle
    final needlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final needleAngle = -3.14 + sweepAngle;
    final needleEndX = center.dx + (radius - 5) * cos(needleAngle);
    final needleEndY = center.dy + (radius - 5) * sin(needleAngle);
    
    canvas.drawLine(
      center,
      Offset(needleEndX, needleEndY),
      needlePaint,
    );

    // Draw center circle
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, centerPaint);

    // Draw value text (smaller and more compact)
    final textPainter = TextPainter(
      text: TextSpan(
        text: value.toStringAsFixed(0),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
