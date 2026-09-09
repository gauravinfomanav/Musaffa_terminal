import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Premium From / To calendar fields for Charts tab (no outer track card).
class ChartPeriodRangeFilter extends StatefulWidget {
  const ChartPeriodRangeFilter({
    super.key,
    required this.periods,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.isDark,
  });

  final List<DateTime> periods;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final bool isDark;

  static String formatPeriod(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  State<ChartPeriodRangeFilter> createState() => _ChartPeriodRangeFilterState();
}

class _ChartPeriodRangeFilterState extends State<ChartPeriodRangeFilter> {
  DateTime get _firstBound => widget.periods.first;
  DateTime get _lastBound => widget.periods.last;

  Future<void> _pickFrom() async {
    final DateTime initial = widget.start ?? _firstBound;
    final DateTime lastAllowed = widget.end ?? _lastBound;
    final DateTime? picked = await HomeUi.pickDate(
      context,
      initialDate: initial.isAfter(lastAllowed) ? lastAllowed : initial,
      firstDate: _firstBound,
      lastDate: lastAllowed.isBefore(_firstBound) ? _firstBound : lastAllowed,
    );
    if (!mounted || picked == null) {
      return;
    }

    widget.onStartChanged(picked);

    // From select hone ke baad To calendar auto-open.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) {
      return;
    }
    await _pickTo(afterFrom: picked);
  }

  Future<void> _pickTo({DateTime? afterFrom}) async {
    final DateTime firstAllowed = afterFrom ?? widget.start ?? _firstBound;
    final DateTime initial = widget.end ?? _lastBound;
    final DateTime clampedInitial =
        initial.isBefore(firstAllowed) ? firstAllowed : initial;

    final DateTime? picked = await HomeUi.pickDate(
      context,
      initialDate: clampedInitial,
      firstDate: firstAllowed.isAfter(_lastBound) ? _lastBound : firstAllowed,
      lastDate: _lastBound,
    );
    if (!mounted || picked == null) {
      return;
    }
    widget.onEndChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.periods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _PremiumDateField(
          label: 'From',
          value: widget.start,
          isDark: widget.isDark,
          onTap: _pickFrom,
        ),
        const SizedBox(width: 10),
        _PremiumDateField(
          label: 'To',
          value: widget.end,
          isDark: widget.isDark,
          onTap: () => _pickTo(),
        ),
      ],
    );
  }
}

class _PremiumDateField extends StatefulWidget {
  const _PremiumDateField({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_PremiumDateField> createState() => _PremiumDateFieldState();
}

class _PremiumDateFieldState extends State<_PremiumDateField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = widget.value != null;
    final Color textColor = hasValue
        ? (widget.isDark ? const Color(0xFFE8EAED) : const Color(0xFF111827))
        : HomeUi.muted(widget.isDark);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 128,
          child: HomeUi.filterFieldShell(
            dark: widget.isDark,
            hover: _hovered,
            accent: false,
            height: 36,
            radius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                HomeUi.brandIcon(
                  icon: Icons.event_outlined,
                  size: 16,
                  gradient: HomeUi.softBrandIconGradient,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // Default: placeholder "From" / "To". After pick: "Oct 2024".
                    hasValue
                        ? ChartPeriodRangeFilter.formatPeriod(widget.value!)
                        : widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: hasValue ? -0.1 : 0.15,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
