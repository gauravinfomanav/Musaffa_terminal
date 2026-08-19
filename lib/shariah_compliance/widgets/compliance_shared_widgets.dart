import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class ComplianceStatusBadge extends StatelessWidget {
  const ComplianceStatusBadge({
    super.key,
    required this.label,
    this.compact = false,
    this.fontSize,
  });

  final String label;
  final bool compact;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String normalized = label.toUpperCase();
    final Color bg;
    final Color fg;
    if (normalized.contains('COMPLIANT') && !normalized.contains('NON')) {
      bg = HomeUi.positiveSoft(isDark);
      fg = HomeUi.positive(isDark);
    } else if (normalized.contains('FAIL') ||
        normalized.contains('NON') ||
        normalized.contains('NOT')) {
      bg = HomeUi.negativeSoft(isDark);
      fg = HomeUi.negative(isDark);
    } else if (normalized.contains('QUESTION')) {
      bg = isDark ? const Color(0xFF3A2A10) : const Color(0xFFFEF3C7);
      fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
    } else {
      bg = HomeUi.elevatedBg(isDark);
      fg = HomeUi.muted(isDark);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        ComplianceFormatters.statusLabel(label),
        style: HomeUi.control(isDark, active: true).copyWith(
          fontSize: fontSize ?? (compact ? 11 : 12),
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class ComplianceSectionCard extends StatelessWidget {
  const ComplianceSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: HomeUi.cardDecoration(isDark),
      child: child,
    );
  }
}

class ComplianceMetricRow extends StatelessWidget {
  const ComplianceMetricRow({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style:
                      HomeUi.tableCellEmphasis(isDark).copyWith(fontSize: 13),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.right,
                    style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color complianceSelectorColor(String selector) {
  final String s = selector.toUpperCase();
  if (s.contains('COMPLIANT') && !s.contains('NON')) {
    return const Color(0xFF16A34A);
  }
  if (s.contains('QUESTION')) return const Color(0xFFF59E0B);
  return const Color(0xFFDC2626);
}

String formatLineAmount(
  ComplianceLineItem item, {
  required bool showPercent,
}) {
  if (showPercent) {
    return ComplianceFormatters.percent(item.percentage);
  }
  if (item.amountInOnes > 0) {
    return ComplianceFormatters.compactMoney(item.amountInOnes, fromOnes: true);
  }
  return ComplianceFormatters.millions(item.amount);
}

class ComplianceOutlinedActionButton extends StatelessWidget {
  const ComplianceOutlinedActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.color,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor =
        isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final Color textColor =
        color ?? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  Icon(leadingIcon, size: 16, color: textColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
                if (trailingIcon != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 16, color: textColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ComplianceSearchResultsShimmer extends StatelessWidget {
  const ComplianceSearchResultsShimmer({
    super.key,
    this.itemCount = 4,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor =
        isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);
    final Color highlightColor =
        isDark ? const Color(0xFF404040) : const Color(0xFFF3F4F6);
    final Color borderColor =
        isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(itemCount, (int index) {
        final bool isLast = index == itemCount - 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: borderColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
          ),
          child: Row(
            children: <Widget>[
              ShimmerWidgets.box(
                width: 52,
                height: 28,
                borderRadius: BorderRadius.circular(8),
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerWidgets.box(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 6),
                    ShimmerWidgets.box(
                      width: 120,
                      height: 11,
                      borderRadius: BorderRadius.circular(4),
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
