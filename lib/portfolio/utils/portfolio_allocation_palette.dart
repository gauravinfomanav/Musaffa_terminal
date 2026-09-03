import 'package:flutter/material.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Brand-aligned colors for model portfolio allocation visuals.
abstract final class PortfolioAllocationPalette {
  static Color primary(bool dark) => HomeUi.accent(dark);

  static Color assetType(String label, bool dark) {
    switch (label) {
      case 'Equity':
        return HomeUi.accent(dark);
      case 'Gold':
        return const Color(0xFFB45309);
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

  /// Per-holding asset type colors for table badges (distinct + readable).
  static Color forModelAssetType(ModelAssetType type, bool dark) {
    switch (type) {
      case ModelAssetType.stock:
        return const Color(0xFF2563EB);
      case ModelAssetType.etf:
        return const Color(0xFF7C3AED);
      case ModelAssetType.bond:
        return const Color(0xFF0891B2);
      case ModelAssetType.reit:
        return const Color(0xFFDC2626);
      case ModelAssetType.gold:
        return const Color(0xFFB45309);
      case ModelAssetType.commodity:
        return const Color(0xFFE4621E);
      case ModelAssetType.cash:
        return const Color(0xFF059669);
      case ModelAssetType.other:
        return HomeUi.muted(dark);
    }
  }

  /// Soft fill behind badge text — strong enough on white rows.
  static Color softFill(Color color, bool dark) =>
      color.withValues(alpha: dark ? 0.18 : 0.12);

  /// Conviction badge tones — jewel colors that read well in light tables.
  static Color conviction(ModelConviction level, bool dark) {
    switch (level) {
      case ModelConviction.high:
        return dark ? const Color(0xFF34D399) : const Color(0xFF047857);
      case ModelConviction.medium:
        return dark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
      case ModelConviction.low:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    }
  }

  static Color convictionSoft(ModelConviction level, bool dark) {
    switch (level) {
      case ModelConviction.high:
        return dark
            ? const Color(0xFF34D399).withValues(alpha: 0.16)
            : const Color(0xFFECFDF5);
      case ModelConviction.medium:
        return dark
            ? const Color(0xFF818CF8).withValues(alpha: 0.16)
            : const Color(0xFFEEF2FF);
      case ModelConviction.low:
        return dark
            ? const Color(0xFFFBBF24).withValues(alpha: 0.16)
            : const Color(0xFFFFFBEB);
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
