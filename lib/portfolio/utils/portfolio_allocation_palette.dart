import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Brand-aligned colors for model portfolio allocation visuals.
abstract final class PortfolioAllocationPalette {
  static Color primary(bool dark) => HomeUi.accent(dark);

  static Color assetType(String label, bool dark) {
    switch (label) {
      case 'Equity':
        return HomeUi.accent(dark);
      case 'Gold':
        return const Color(0xFFD97706);
      case 'Bonds':
        return const Color(0xFF0891B2);
      case 'Real Estate':
        return const Color(0xFFDC2626);
      case 'Cash':
        return HomeUi.muted(dark);
      case 'Commodity':
        return const Color(0xFFE4621E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static List<Color> sectorPalette(bool dark) => <Color>[
        HomeUi.accent(dark),
        const Color(0xFFE4621E),
        const Color(0xFFD2364C),
        const Color(0xFF6A2C72),
        const Color(0xFF232C64),
        const Color(0xFF0891B2),
        HomeUi.muted(dark),
      ];

  static Color sectorColor(String label, bool dark) {
    final palette = sectorPalette(dark);
    return palette[label.hashCode.abs() % palette.length];
  }

  static LinearGradient primaryBarGradient(bool dark) =>
      HomeUi.chartBarGradient(dark);

  static List<Color> donutHoldingColors(bool dark) => <Color>[
        HomeUi.accent(dark),
        const Color(0xFFE4621E),
        const Color(0xFFD2364C),
        const Color(0xFF6A2C72),
        const Color(0xFF232C64),
        const Color(0xFF0891B2),
        const Color(0xFF6B7280),
      ];
}
