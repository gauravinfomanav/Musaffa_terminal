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

  /// Per-holding asset type colors for table badges (muted, premium).
  static Color forModelAssetType(ModelAssetType type, bool dark) {
    switch (type) {
      case ModelAssetType.stock:
        return dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
      case ModelAssetType.etf:
        return dark ? const Color(0xFFA78BFA) : const Color(0xFF5B21B6);
      case ModelAssetType.bond:
        return dark ? const Color(0xFF22D3EE) : const Color(0xFF0E7490);
      case ModelAssetType.reit:
        return dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      case ModelAssetType.gold:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      case ModelAssetType.commodity:
        return dark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
      case ModelAssetType.cash:
        return dark ? const Color(0xFF34D399) : const Color(0xFF047857);
      case ModelAssetType.other:
        return HomeUi.muted(dark);
    }
  }

  /// Soft fill behind badge text — quiet wash, no loud borders.
  static Color softFill(Color color, bool dark) => dark
      ? Color.alphaBlend(color.withValues(alpha: 0.16), const Color(0xFF151822))
      : Color.alphaBlend(color.withValues(alpha: 0.10), const Color(0xFFF8FAFC));

  /// Conviction badge tones — aligned with [HomeUi.convictionLevelPill].
  static Color conviction(ModelConviction level, bool dark) {
    switch (level) {
      case ModelConviction.high:
        return dark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case ModelConviction.medium:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case ModelConviction.low:
        return dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  static Color convictionSoft(ModelConviction level, bool dark) {
    switch (level) {
      case ModelConviction.high:
        return dark
            ? const Color(0xFF064E3B).withValues(alpha: 0.38)
            : const Color(0xFFECFDF5);
      case ModelConviction.medium:
        return dark
            ? const Color(0xFF78350F).withValues(alpha: 0.36)
            : const Color(0xFFFFF7ED);
      case ModelConviction.low:
        return dark
            ? const Color(0xFF1E293B).withValues(alpha: 0.50)
            : const Color(0xFFF8FAFC);
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
