import 'package:flutter/material.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Premium ratio meter for Shariah securities / debt screening.
///
/// Uses [FractionallySizedBox] / [Align] instead of [LayoutBuilder] so it
/// stays safe inside tight IntrinsicHeight / nested layout parents.
class ComplianceRatioBar extends StatelessWidget {
  const ComplianceRatioBar({
    super.key,
    required this.value,
    required this.threshold,
    required this.pass,
    required this.numeratorLabel,
    required this.numeratorValue,
    required this.denominatorValue,
    this.denominatorLabel = 'Trailing 36M Avg Market Cap',
  });

  final double value;
  final double threshold;
  final bool pass;
  final String numeratorLabel;
  final String numeratorValue;
  final String denominatorValue;
  final String denominatorLabel;

  static Alignment _along(double t) => Alignment(2 * t.clamp(0.0, 1.0) - 1, 0);

  List<BoxShadow> _softShadow(bool isDark) => <BoxShadow>[
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(
            alpha: isDark ? 0.32 : 0.07,
          ),
          blurRadius: 22,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        if (!isDark)
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color statusColor = pass
        ? ComplianceFormatters.halalColor
        : ComplianceFormatters.notHalalColor;
    final double fillFactor = (value.clamp(0.0, 100.0) / 100).clamp(0.0, 1.0);
    final double thresholdFactor = (threshold / 100).clamp(0.0, 1.0);
    final String valueText = '${value.toStringAsFixed(2)}%';
    final String limitText = '${threshold.toInt()}%';
    final Color surface = isDark ? HomeUi.elevatedBg(true) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ── Meter ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(
              color: HomeUi.borderLight(isDark).withValues(alpha: 0.85),
            ),
            boxShadow: _softShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Current ratio',
                          style: HomeUi.sectionTitle(isDark).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Measured against the $limitText screening limit',
                          style: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ValueBadge(
                    valueText: valueText,
                    statusColor: statusColor,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (fillFactor > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fillFactor,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 7,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? const <Color>[
                                    Color(0xFF151A20),
                                    Color(0xFF2C343E),
                                  ]
                                : const <Color>[
                                    Color(0xFFE2E8F0),
                                    Color(0xFFF8FAFC),
                                  ],
                          ),
                          border: Border.all(
                            color: HomeUi.borderLight(isDark).withValues(
                              alpha: isDark ? 0.45 : 0.65,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: thresholdFactor,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: ComplianceFormatters.halalColor.withValues(
                              alpha: isDark ? 0.12 : 0.08,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (fillFactor > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fillFactor,
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color.lerp(statusColor, Colors.white, 0.18)!,
                                  statusColor,
                                  Color.lerp(statusColor, Colors.black, 0.08)!,
                                ],
                                stops: const <double>[0.0, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: _along(thresholdFactor),
                      child: Container(
                        width: 2,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF0F172A),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.1 : 1,
                              ),
                              blurRadius: 0,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (fillFactor > 0.02)
                      Align(
                        alignment: _along(fillFactor),
                        child: _Thumb(
                          statusColor: statusColor,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '0%',
                        style: HomeUi.subtitle(isDark).copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: _along(thresholdFactor),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius:
                              BorderRadius.circular(HomeUi.radiusPill),
                          border: Border.all(
                            color: HomeUi.borderStrong(isDark)
                                .withValues(alpha: 0.5),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(
                                alpha: isDark ? 0.25 : 0.06,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: limitText,
                                style: TextStyle(
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.15,
                                  color: HomeUi.title(isDark),
                                ),
                              ),
                              TextSpan(
                                text: ' limit',
                                style: TextStyle(
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: HomeUi.muted(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '100%',
                        style: HomeUi.subtitle(isDark).copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Calculation (no accent rail) ────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(
              color: HomeUi.borderLight(isDark).withValues(alpha: 0.9),
            ),
            boxShadow: _softShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.functions_rounded,
                    size: 14,
                    color: HomeUi.muted(isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CALCULATION',
                    style: HomeUi.overline(isDark).copyWith(
                      fontSize: 10,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                numeratorLabel,
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                numeratorValue,
                style: HomeUi.control(isDark, active: true).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 1,
                        color: HomeUi.borderLight(isDark),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '÷',
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HomeUi.muted(isDark),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: HomeUi.borderLight(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                denominatorLabel,
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                denominatorValue,
                style: HomeUi.control(isDark, active: true).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor.withValues(
                      alpha: isDark ? 0.35 : 0.22,
                    ),
                  ),
                  gradient: LinearGradient(
                    colors: <Color>[
                      statusColor.withValues(
                        alpha: isDark ? 0.14 : 0.07,
                      ),
                      statusColor.withValues(
                        alpha: isDark ? 0.05 : 0.02,
                      ),
                    ],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      'Result',
                      style: HomeUi.subtitle(isDark).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      valueText,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: statusColor,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Status ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: isDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: isDark ? 0.28 : 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 15,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pass
                      ? 'Pass — ratio is below the ${threshold.toInt()}% Shariah screening limit.'
                      : 'Fail — ratio exceeds the ${threshold.toInt()}% Shariah screening limit.',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({
    required this.valueText,
    required this.statusColor,
    required this.isDark,
  });

  final String valueText;
  final Color statusColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            statusColor.withValues(alpha: isDark ? 0.24 : 0.13),
            statusColor.withValues(alpha: isDark ? 0.10 : 0.04),
          ],
        ),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.42 : 0.30),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.6),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valueText,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: statusColor,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.statusColor,
    required this.isDark,
  });

  final Color statusColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: statusColor.withValues(alpha: 0.32),
            blurRadius: 8,
          ),
        ],
      ),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF14161A) : Colors.white,
          border: Border.all(color: statusColor, width: 2.25),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
