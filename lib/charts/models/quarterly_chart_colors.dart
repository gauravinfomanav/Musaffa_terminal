import 'package:flutter/material.dart';

/// Bar colors for quarterly charts — faded brand gradient, red for negatives.
class QuarterlyChartColors {
  const QuarterlyChartColors._();

  static const Color positiveBase = Color(0xFFF3D0BC);
  static const Color positiveHighlight = Color(0xFFE4621E);
  static const Color negativeBase = Color(0xFFFBC4C4);
  static const Color negativeHighlight = Color(0xFFDC2626);

  static const LinearGradient fadedBarGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0x80E4621E),
      Color(0x85D2364C),
      Color(0x8AA72669),
      Color(0x8C6A2C72),
      Color(0x90232C64),
    ],
    stops: [0.0, 0.25, 0.50, 0.75, 1.0],
  );

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
