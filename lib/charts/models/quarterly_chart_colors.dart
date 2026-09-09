import 'package:flutter/material.dart';

/// Soft pastel bar palette for quarterly / overview Charts tab only.
/// Custom Charts (`lib/charts/custom/`) do not use this file.
///
/// Sequence (left → right, then repeats):
/// `#F4BA7D`, `#F0A2A3`, `#E3ABC0`, `#B493B8`, `#9BBDF5`
class QuarterlyChartColors {
  const QuarterlyChartColors._();

  /// Soft multi-tone palette matching Charts-tab bar reference.
  static const List<Color> palette = <Color>[
    Color(0xFFF4BA7D), // warm peach / orange
    Color(0xFFF0A2A3), // salmon pink
    Color(0xFFE3ABC0), // light rose
    Color(0xFFB493B8), // muted purple
    Color(0xFF9BBDF5), // soft sky blue
  ];

  /// Slightly lifted tones for dark surfaces.
  static const List<Color> paletteDark = <Color>[
    Color(0xFFF7C892),
    Color(0xFFF5B5B6),
    Color(0xFFEBBDCE),
    Color(0xFFC4A8C8),
    Color(0xFFAECBF7),
  ];

  /// Default single-series fill (sky blue from palette).
  static const Color positive = Color(0xFF9BBDF5);
  static const Color positiveDark = Color(0xFFAECBF7);

  /// Salmon from palette for negative values.
  static const Color negative = Color(0xFFF0A2A3);
  static const Color negativeDark = Color(0xFFF5B5B6);

  /// Kept for callers that still expect a gradient API; resolves to flat color.
  static const LinearGradient fadedBarGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [positive, positive],
  );

  static Color paletteAt(int index, {bool dark = false}) {
    final List<Color> colors = dark ? paletteDark : palette;
    if (colors.isEmpty) return dark ? positiveDark : positive;
    final int i = index % colors.length;
    return colors[i < 0 ? i + colors.length : i];
  }

  static Color barColor(
    double value, {
    required bool highlighted,
    bool dark = false,
    int index = 0,
  }) {
    if (value < 0) {
      return dark ? negativeDark : negative;
    }
    return paletteAt(index, dark: dark);
  }
}
