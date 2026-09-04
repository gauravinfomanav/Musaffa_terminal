import 'package:flutter/material.dart';

/// Bar colors for quarterly charts — solid single tone (no gradient).
class QuarterlyChartColors {
  const QuarterlyChartColors._();

  /// Calm institutional blue — modern terminal bars.
  static const Color positive = Color(0xFF3B6EA5);
  static const Color positiveDark = Color(0xFF7BA3C9);
  static const Color negative = Color(0xFFDC2626);
  static const Color negativeDark = Color(0xFFF07178);

  /// Kept for callers that still expect a gradient API; resolves to flat color.
  static const LinearGradient fadedBarGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [positive, positive],
  );

  static Color barColor(
    double value, {
    required bool highlighted,
    bool dark = false,
  }) {
    if (value < 0) {
      return dark ? negativeDark : negative;
    }
    return dark ? positiveDark : positive;
  }
}
