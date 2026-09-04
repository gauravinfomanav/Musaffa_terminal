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
    final Color fg = ComplianceFormatters.statusColor(label);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(
          color: fg.withValues(alpha: isDark ? 0.24 : 0.20),
        ),
      ),
      child: Text(
        ComplianceFormatters.statusLabel(label),
        style: HomeUi.control(isDark, active: true).copyWith(
          fontSize: fontSize ?? (compact ? 11 : 12),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }
}

class ComplianceViewCalculationButton extends StatefulWidget {
  const ComplianceViewCalculationButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  State<ComplianceViewCalculationButton> createState() =>
      _ComplianceViewCalculationButtonState();
}

class _ComplianceViewCalculationButtonState
    extends State<ComplianceViewCalculationButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color accent = HomeUi.accent(widget.isDark);
    final Color bg = _pressed
        ? Color.alphaBlend(
            accent.withValues(alpha: widget.isDark ? 0.14 : 0.10),
            HomeUi.cardBg(widget.isDark),
          )
        : _hover
            ? Color.alphaBlend(
                accent.withValues(alpha: widget.isDark ? 0.10 : 0.06),
                HomeUi.cardBg(widget.isDark),
              )
            : HomeUi.cardBg(widget.isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: accent.withValues(
                alpha: _hover || _pressed
                    ? (widget.isDark ? 0.55 : 0.42)
                    : (widget.isDark ? 0.34 : 0.26),
              ),
              width: 1.15,
            ),
            boxShadow: _hover
                ? <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : HomeUi.cardShadow(widget.isDark),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.functions_rounded, size: 15, color: accent),
              const SizedBox(width: 8),
              Text(
                'View calculation',
                style: HomeUi.control(widget.isDark, active: true).copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                offset: _hover ? const Offset(0.08, 0) : Offset.zero,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: accent.withValues(alpha: _hover ? 1 : 0.8),
                ),
              ),
            ],
          ),
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
    this.fillHeight = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: fillHeight ? double.infinity : null,
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
  return ComplianceFormatters.statusColor(selector);
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
            color: index.isEven
                ? HomeUi.tableRowEven(isDark)
                : HomeUi.tableRowOdd(isDark),
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
