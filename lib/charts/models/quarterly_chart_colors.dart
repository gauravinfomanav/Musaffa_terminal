import 'package:flutter/material.dart';

/// Premium muted bar palette for quarterly / overview Charts tab only.
/// Custom Charts (`lib/charts/custom/`) do not use this file.
class QuarterlyChartColors {
  const QuarterlyChartColors._();

  /// Deep slate-blue → soft silver (Charts tab bar fill).
  static const Color barDeep = Color(0xFF2D4E66);
  static const Color barLight = Color(0xFFD4D8DB);

  /// Vertical fill for positive quarterly bars.
  static const LinearGradient barFillGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: <Color>[barDeep, barLight],
  );

  /// Soft multi-tone palette kept for callers that still index by quarter.
  static const List<Color> palette = <Color>[
    Color(0xFFB8C96A), // light olive / pear
    Color(0xFF8FA3B8), // muted steel blue
    Color(0xFF4A5A6E), // deep slate
    Color(0xFFC4847A), // dusty rose / terracotta
    Color(0xFFD4A84B), // warm amber
    Color(0xFF6B9FD4), // soft sky blue
    Color(0xFF7BAFA0), // seafoam / teal
  ];

  /// Slightly lifted tones for dark surfaces.
  static const List<Color> paletteDark = <Color>[
    Color(0xFFC5D67E),
    Color(0xFFA3B5C8),
    Color(0xFF7A8BA0),
    Color(0xFFD49A90),
    Color(0xFFE0BC6A),
    Color(0xFF8BB4E0),
    Color(0xFF95C4B4),
  ];

  /// Default single-series fill (sky blue from palette).
  static const Color positive = Color(0xFF6B9FD4);
  static const Color positiveDark = Color(0xFF8BB4E0);

  /// Muted rose for negative values — matches palette, not harsh red.
  static const Color negative = Color(0xFFC4847A);
  static const Color negativeDark = Color(0xFFD49A90);

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
