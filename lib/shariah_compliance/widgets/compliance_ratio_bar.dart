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

  /// Maps 0..1 along the track to [Alignment.x] (−1 left … +1 right).
  static Alignment _along(double t) => Alignment(2 * t.clamp(0.0, 1.0) - 1, 0);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color statusColor = pass
        ? ComplianceFormatters.halalColor
        : ComplianceFormatters.notHalalColor;
    final double fillFactor = (value.clamp(0.0, 100.0) / 100).clamp(0.0, 1.0);
    final double thresholdFactor = (threshold / 100).clamp(0.0, 1.0);
    final String valueText = '${value.toStringAsFixed(2)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Current ratio',
              style: HomeUi.subtitle(isDark).copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                border: Border.all(
                  color: statusColor.withValues(alpha: isDark ? 0.28 : 0.18),
                ),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF24292F)
                        : const Color(0xFFEEF0F3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: thresholdFactor,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: ComplianceFormatters.halalColor.withValues(
                        alpha: isDark ? 0.10 : 0.07,
                      ),
                      borderRadius: BorderRadius.circular(999),
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
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: <Color>[
                            statusColor.withValues(alpha: 0.72),
                            statusColor,
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: _along(thresholdFactor),
                child: Container(
                  width: 2,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.08 : 0.9,
                        ),
                        blurRadius: 0,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              if (fillFactor > 0.04)
                Align(
                  alignment: _along(fillFactor),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF14161A) : Colors.white,
                      border: Border.all(color: statusColor, width: 2.5),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.10,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '0%',
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                ),
              ),
              Align(
                alignment: _along(thresholdFactor),
                child: Text(
                  '${threshold.toInt()}% limit',
                  style: HomeUi.control(isDark, active: true).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '100%',
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: HomeUi.elevatedBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(color: HomeUi.borderLight(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$numeratorLabel ÷ $denominatorLabel',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                '$numeratorValue ÷ $denominatorValue = $valueText',
                style: HomeUi.control(isDark, active: true).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
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
      ],
    );
  }
}
