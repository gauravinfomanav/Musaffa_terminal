import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Shared visual tokens for the premium Custom Charts system.
class PremiumChartTheme {
  const PremiumChartTheme({required this.isDark});

  final bool isDark;

  Color get surface => HomeUi.cardBg(isDark);
  Color get elevated => HomeUi.elevatedBg(isDark);
  Color get border => HomeUi.borderLight(isDark);
  Color get borderStrong => HomeUi.borderStrong(isDark);
  Color get title => HomeUi.title(isDark);
  Color get body => HomeUi.body(isDark);
  Color get muted => HomeUi.muted(isDark);
  Color get accent => HomeUi.accent(isDark);
  Color get positive => HomeUi.positive(isDark);
  Color get negative => HomeUi.negative(isDark);
  Color get grid => border.withValues(alpha: isDark ? 0.35 : 0.55);

  static const Color brandLine = Color(0xFFE4621E);
  static const Color brandSecondary = Color(0xFF6A2C72);

  TextStyle get sectionTitle => HomeUi.bodyText(isDark).copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: title,
      );

  TextStyle get sectionSubtitle => HomeUi.subtitle(isDark);

  TextStyle axisLabel({double size = 11}) => HomeUi.subtitle(isDark).copyWith(
        fontSize: size,
        height: 1.15,
        fontWeight: FontWeight.w500,
        color: muted,
      );

  TextStyle tooltipTitle({double size = 11}) =>
      HomeUi.tableCellSecondary(isDark).copyWith(fontSize: size);

  TextStyle tooltipValue({double size = 13}) =>
      HomeUi.tableCellEmphasis(isDark).copyWith(fontSize: size);

  BoxDecoration cardDecoration({EdgeInsetsGeometry? padding}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(HomeUi.radiusCard),
      border: Border.all(color: border),
      boxShadow: HomeUi.cardShadow(isDark),
    );
  }

  BoxDecoration tooltipDecoration() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
      border: Border.all(color: border),
      boxShadow: HomeUi.cardShadow(isDark),
    );
  }
}

/// Compact financial number formatting for chart axes and labels.
class PremiumChartFormatters {
  PremiumChartFormatters._();

  static final NumberFormat _price = NumberFormat('#,##0.00');
  static final NumberFormat _compact = NumberFormat.compact();
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _tooltipDate = DateFormat('MMM d, yyyy');
  static final DateFormat _tooltipDateTime = DateFormat('MMM d, yyyy  h:mm a');

  static String price(double? value, {String prefix = '\$'}) {
    if (value == null || value.isNaN) return '--';
    return '$prefix${_price.format(value)}';
  }

  static String compact(num? value, {String prefix = '\$'}) {
    if (value == null) return '--';
    return '$prefix${_compact.format(value)}';
  }

  static String percent(double? value, {int digits = 2, bool showSign = true}) {
    if (value == null || value.isNaN) return '--';
    final sign = showSign && value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(digits)}%';
  }

  static String change(double? absolute, double? percent) {
    if (absolute == null || percent == null) return '--';
    final sign = absolute >= 0 ? '+' : '';
    return '$sign${price(absolute.abs(), prefix: '\$')}  (${PremiumChartFormatters.percent(percent)})';
  }

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String tooltipDate(DateTime date, {bool includeTime = false}) {
    return includeTime ? _tooltipDateTime.format(date) : _tooltipDate.format(date);
  }

  static String volume(double volume) {
    if (volume >= 1e9) return '${(volume / 1e9).toStringAsFixed(1)}B';
    if (volume >= 1e6) return '${(volume / 1e6).toStringAsFixed(1)}M';
    if (volume >= 1e3) return '${(volume / 1e3).toStringAsFixed(1)}K';
    return volume.toStringAsFixed(0);
  }

  static String marketCap(num? value) {
    if (value == null) return '--';
    return Constants.getShortenedMarketCapV2(value);
  }
}

/// Reusable chart section card shell.
class PremiumChartCard extends StatelessWidget {
  const PremiumChartCard({
    super.key,
    required this.isDark,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  final bool isDark;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final PremiumChartTheme theme = PremiumChartTheme(isDark: isDark);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: theme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: HomeUi.tableToolbarHeader(
                  isDark,
                  icon: icon ?? Icons.insights_outlined,
                  title: title,
                  subtitleText: subtitle,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Horizontal pill selector for time ranges and chart modes.
class PremiumChartPillBar extends StatelessWidget {
  const PremiumChartPillBar({
    super.key,
    required this.isDark,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final bool isDark;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List<Widget>.generate(options.length, (int index) {
        final bool selected = index == selectedIndex;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? HomeUi.accent(isDark).withValues(alpha: isDark ? 0.18 : 0.10)
                    : HomeUi.elevatedBg(isDark),
                borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                border: Border.all(
                  color: selected
                      ? HomeUi.accent(isDark).withValues(alpha: 0.45)
                      : HomeUi.borderLight(isDark),
                ),
              ),
              child: Text(
                options[index],
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? HomeUi.accent(isDark) : HomeUi.muted(isDark),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
