import 'package:flutter/material.dart';

/// Institutional US fintech palette — Robinhood / Stripe / Bloomberg inspired.
class UsPremiumPalette {
  UsPremiumPalette._();

  // Surfaces
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightMuted = Color(0xFF64748B);
  static const Color lightGrid = Color(0xFFEEF2F6);

  static const Color darkBg = Color(0xFF0B0E11);
  static const Color darkSurface = Color(0xFF131722);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkMuted = Color(0xFF94A3B8);
  static const Color darkGrid = Color(0xFF1A2332);

  // Core chart brand — quieter, institutional, premium.
  static const Color electricBlue = Color(0xFF245C93);
  static const Color electricBlueSoft = Color(0xFF4F7FAF);
  static const Color indigoAccent = Color(0xFF556B8E);
  static const Color tealAccent = Color(0xFF2F7C74);
  static const Color violetAccent = Color(0xFF6D5F8C);
  static const Color cyanAccent = Color(0xFF4A8093);
  static const Color slateMid = Color(0xFF516175);
  static const Color slateLight = Color(0xFF9AA8B8);

  static const Color gain = Color(0xFF2B7A57);
  static const Color gainSoft = Color(0xFF5D9877);
  static const Color loss = Color(0xFFB14E4E);
  static const Color lossSoft = Color(0xFFC77D7D);
  static const Color amber = Color(0xFFB88746);

  static Color surface(bool dark) => dark ? darkSurface : lightSurface;
  static Color border(bool dark) => dark ? darkBorder : lightBorder;
  static Color text(bool dark) => dark ? darkText : lightText;
  static Color muted(bool dark) => dark ? darkMuted : lightMuted;
  static Color grid(bool dark) => dark ? darkGrid : lightGrid;
}

/// Per-chart custom color tokens — never use Syncfusion defaults.
class UsPremiumChartColors {
  UsPremiumChartColors(this.dark);

  final bool dark;

  // ── Price / area ──
  Color get priceLine => dark ? UsPremiumPalette.electricBlueSoft : UsPremiumPalette.electricBlue;

  LinearGradient get priceAreaFill => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          priceLine.withValues(alpha: dark ? 0.32 : 0.20),
          priceLine.withValues(alpha: 0.02),
        ],
      );

  // ── Candles ──
  Color get candleBull => UsPremiumPalette.gain;
  Color get candleBear => UsPremiumPalette.loss;

  Color volumeBar(bool isUp) =>
      (isUp ? UsPremiumPalette.gain : UsPremiumPalette.loss)
          .withValues(alpha: dark ? 0.38 : 0.28);

  // ── Multi-series palette (ordered) ──
  static const List<Color> series = <Color>[
    UsPremiumPalette.electricBlue,
    UsPremiumPalette.indigoAccent,
    UsPremiumPalette.tealAccent,
    UsPremiumPalette.violetAccent,
    UsPremiumPalette.cyanAccent,
    UsPremiumPalette.slateMid,
    UsPremiumPalette.amber,
    UsPremiumPalette.slateLight,
  ];

  Color seriesAt(int index) => series[index % series.length];

  /// Donut / allocation ramp — deep navy → soft steel.
  static const List<Color> allocationRamp = <Color>[
    Color(0xFF17283B),
    Color(0xFF243A52),
    Color(0xFF32506D),
    Color(0xFF476682),
    Color(0xFF6685A0),
    Color(0xFF8CA5B7),
  ];

  Color allocationAt(int index) => allocationRamp[index % allocationRamp.length];

  // ── Benchmark lines ──
  Color get benchmarkPrimary => priceLine;
  Color get benchmarkSecondary =>
      dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // ── Scatter ──
  Color get scatterHighlight => priceLine;
  Color get scatterPeer => UsPremiumPalette.indigoAccent.withValues(alpha: 0.55);

  // ── Dividend area ──
  Color get dividendLine => UsPremiumPalette.tealAccent;

  LinearGradient get dividendFill => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          UsPremiumPalette.tealAccent.withValues(alpha: dark ? 0.22 : 0.14),
          UsPremiumPalette.tealAccent.withValues(alpha: 0.02),
        ],
      );

  // ── Revenue / profit bars ──
  Color get revenueBar => UsPremiumPalette.electricBlue.withValues(alpha: 0.82);
  Color get profitBar => UsPremiumPalette.tealAccent.withValues(alpha: 0.82);

  // ── Analyst stacked ──
  Color get analystStrongBuy => UsPremiumPalette.gain.withValues(alpha: 0.85);
  Color get analystBuy => UsPremiumPalette.gainSoft.withValues(alpha: 0.55);
  Color get analystHold => UsPremiumPalette.amber.withValues(alpha: 0.55);
  Color get analystSell => UsPremiumPalette.lossSoft.withValues(alpha: 0.50);
  Color get analystStrongSell => UsPremiumPalette.loss.withValues(alpha: 0.55);

  // ── Margin lines ──
  Color get grossMargin => UsPremiumPalette.electricBlue;
  Color get operatingMargin => UsPremiumPalette.indigoAccent;
  Color get netMargin => UsPremiumPalette.tealAccent;

  // ── Cash flow stack ──
  Color get cfOperating => UsPremiumPalette.electricBlue.withValues(alpha: 0.75);
  Color get cfInvesting => UsPremiumPalette.violetAccent.withValues(alpha: 0.65);
  Color get cfFinancing => UsPremiumPalette.amber.withValues(alpha: 0.60);

  // ── Valuation lines ──
  Color get peRatio => UsPremiumPalette.indigoAccent;
  Color get evRevenue => UsPremiumPalette.cyanAccent;

  // ── EPS surprise ──
  Color get epsEstimate => UsPremiumPalette.slateLight.withValues(alpha: 0.55);
  Color get epsActual => UsPremiumPalette.electricBlue;

  // ── 52-week range ──
  Color get rangeTrack => grid;
  Color get rangeFill => priceLine.withValues(alpha: 0.55);
  Color get rangeMarker => priceLine;

  // ── Heatmap ──
  Color heatmapPositive(double intensity) => Color.lerp(
        UsPremiumPalette.gain.withValues(alpha: dark ? 0.08 : 0.05),
        UsPremiumPalette.gain.withValues(alpha: dark ? 0.34 : 0.20),
        intensity.clamp(0.0, 1.0),
      )!;

  Color heatmapNegative(double intensity) => Color.lerp(
        UsPremiumPalette.loss.withValues(alpha: dark ? 0.08 : 0.05),
        UsPremiumPalette.loss.withValues(alpha: dark ? 0.34 : 0.20),
        intensity.clamp(0.0, 1.0),
      )!;

  // ── UI chrome ──
  Color get pillSelected => priceLine.withValues(alpha: dark ? 0.22 : 0.10);
  Color get pillBorder => priceLine.withValues(alpha: 0.45);
  Color get crosshair => muted.withValues(alpha: 0.35);
  Color get trackballMarker => priceLine;

  Color get muted => UsPremiumPalette.muted(dark);
  Color get grid => UsPremiumPalette.grid(dark);
  Color get gainColor => UsPremiumPalette.gain;
  Color get lossColor => UsPremiumPalette.loss;

  /// Sunburst quadrant ramp — investments, loans, transfers, cards.
  static const List<Color> sunburstQuadrants = <Color>[
    UsPremiumPalette.violetAccent,
    UsPremiumPalette.amber,
    UsPremiumPalette.tealAccent,
    UsPremiumPalette.electricBlue,
  ];

  Color get butterflyLeft => UsPremiumPalette.indigoAccent;
  Color get butterflyRight => UsPremiumPalette.electricBlue;
}

UsPremiumChartColors chartColors(bool dark) => UsPremiumChartColors(dark);
