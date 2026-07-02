import 'package:flutter/material.dart';

/// Bar colors for quarterly charts — blue for positive values, red for negative.
class QuarterlyChartColors {
  const QuarterlyChartColors._();

  static const Color positiveBase = Color(0xFFC9D9F5);
  static const Color positiveHighlight = Color(0xFF2F5FE0);
  static const Color negativeBase = Color(0xFFFBC4C4);
  static const Color negativeHighlight = Color(0xFFEF4444);

  static Color barColor(
    double value, {
    required bool highlighted,
  }) {
    if (value < 0) {
      return highlighted ? negativeHighlight : negativeBase;
    }
    return highlighted ? positiveHighlight : positiveBase;
  }
}
