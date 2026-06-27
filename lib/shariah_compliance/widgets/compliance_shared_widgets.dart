import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/compliance_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';

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
    final String normalized = label.toUpperCase();
    Color bg;
    Color fg;
    if (normalized.contains('COMPLIANT') && !normalized.contains('NON')) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
    } else if (normalized.contains('FAIL') ||
        normalized.contains('NON') ||
        normalized.contains('NOT')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    } else if (normalized.contains('QUESTION')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else {
      bg = const Color(0xFFE5E7EB);
      fg = const Color(0xFF374151);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ComplianceFormatters.statusLabel(label),
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
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
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
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
    final Color secondary = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: secondary,
              ),
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
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 11,
                      color: secondary,
                    ),
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
    final Color textColor = color ??
        (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
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
