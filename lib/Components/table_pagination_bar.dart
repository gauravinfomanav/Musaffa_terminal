import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Shared table pagination strip — rows-per-page, Go-to field, and page nav.
///
/// [currentPage] / [onPageChanged] are **1-based**.
/// Submit Go-to with Enter (no separate Go button).
///
/// Page nav matches a compact first / prev / `current / total` / next / last
/// row with no pill or icon-well background.

class TablePaginationBar extends StatefulWidget {
  const TablePaginationBar({
    super.key,
    required this.isDark,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.summaryText,
    this.showPageButtons = true,
    this.compact = false,
    this.showTopDivider = true,
    this.rowsPerPage,
    this.rowsPerPageOptions = const <int>[10, 14, 25, 50, 100],
    this.onRowsPerPageChanged,
  });

  final bool isDark;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final String? summaryText;
  final bool showPageButtons;
  final bool compact;
  final bool showTopDivider;

  /// Current page size. When null, the rows-per-page dropdown is hidden.
  final int? rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int>? onRowsPerPageChanged;

  @override
  State<TablePaginationBar> createState() => _TablePaginationBarState();
}

class _TablePaginationBarState extends State<TablePaginationBar> {
  late final TextEditingController _gotoController;
  final FocusNode _gotoFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _gotoController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant TablePaginationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage && !_gotoFocus.hasFocus) {
      _gotoController.clear();
    }
  }

  @override
  void dispose() {
    _gotoController.dispose();
    _gotoFocus.dispose();
    super.dispose();
  }

  int get _safePage {
    final int pages = widget.totalPages < 1 ? 1 : widget.totalPages;
    return widget.currentPage.clamp(1, pages);
  }

  int get _safeTotal => widget.totalPages < 1 ? 1 : widget.totalPages;

  void _goTo(int page) {
    final int target = page.clamp(1, _safeTotal);
    if (target == _safePage) return;
    widget.onPageChanged(target);
  }

  void _submitGoto() {
    final String raw = _gotoController.text.trim();
    if (raw.isEmpty) return;
    final int? page = int.tryParse(raw);
    if (page == null) return;
    _goTo(page);
    _gotoController.clear();
    _gotoFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.isDark;
    final int current = _safePage;
    final int total = _safeTotal;
    final bool multi = total > 1;
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      widget.compact ? 14 : 16,
      6,
      widget.compact ? 14 : 16,
      widget.compact ? 8 : 10,
    );

    final Widget? summary = widget.summaryText != null &&
            widget.summaryText!.isNotEmpty
        ? Text(
            widget.summaryText!,
            style: HomeUi.subtitle(dark).copyWith(fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          )
        : null;

    final bool showRows =
        widget.rowsPerPage != null && widget.onRowsPerPageChanged != null;

    final List<Widget> controlChildren = <Widget>[
      if (showRows) ...<Widget>[
        _RowsPerPageDropdown(
          dark: dark,
          rowsPerPage: widget.rowsPerPage!,
          options: widget.rowsPerPageOptions,
          onChanged: widget.onRowsPerPageChanged!,
        ),
        const SizedBox(width: 16),
      ],
      _GotoField(
        dark: dark,
        controller: _gotoController,
        focusNode: _gotoFocus,
        totalPages: total,
        onSubmit: _submitGoto,
      ),
      if (multi) ...<Widget>[
        const SizedBox(width: 28),
        _PageNav(
          dark: dark,
          current: current,
          total: total,
          onFirst: () => _goTo(1),
          onPrev: () => _goTo(current - 1),
          onNext: () => _goTo(current + 1),
          onLast: () => _goTo(total),
        ),
      ],
    ];

    final Widget controls = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: controlChildren,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.showTopDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: HomeUi.borderLight(dark),
          ),
        Padding(
          padding: pad,
          child: widget.compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (summary != null) ...<Widget>[
                      summary,
                      const SizedBox(height: 10),
                    ],
                    Align(alignment: Alignment.centerRight, child: controls),
                  ],
                )
              : Row(
                  children: <Widget>[
                    if (summary != null)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: summary,
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: controls,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Compact first / prev / `n / total` / next / last — no background pill.
class _PageNav extends StatelessWidget {
  const _PageNav({
    required this.dark,
    required this.current,
    required this.total,
    required this.onFirst,
    required this.onPrev,
    required this.onNext,
    required this.onLast,
  });

  final bool dark;
  final int current;
  final int total;
  final VoidCallback onFirst;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onLast;

  @override
  Widget build(BuildContext context) {
    final bool canPrev = current > 1;
    final bool canNext = current < total;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _FlatNavIcon(
          dark: dark,
          icon: Icons.first_page_rounded,
          enabled: canPrev,
          onTap: onFirst,
        ),
        const SizedBox(width: 2),
        _FlatNavIcon(
          dark: dark,
          icon: Icons.chevron_left_rounded,
          enabled: canPrev,
          onTap: onPrev,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _SlidingPageNumber(dark: dark, page: current),
              Text(
                ' / ',
                style: HomeUi.subtitle(dark).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
              Text(
                '$total',
                style: HomeUi.subtitle(dark).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        _FlatNavIcon(
          dark: dark,
          icon: Icons.chevron_right_rounded,
          enabled: canNext,
          onTap: onNext,
        ),
        const SizedBox(width: 2),
        _FlatNavIcon(
          dark: dark,
          icon: Icons.last_page_rounded,
          enabled: canNext,
          onTap: onLast,
        ),
      ],
    );
  }
}

/// Current page digit with a vertical slide on next / prev.
///
/// Next → old slides up, new enters from below.
/// Prev → old slides down, new enters from above.
class _SlidingPageNumber extends StatefulWidget {
  const _SlidingPageNumber({
    required this.dark,
    required this.page,
  });

  final bool dark;
  final int page;

  @override
  State<_SlidingPageNumber> createState() => _SlidingPageNumberState();
}

class _SlidingPageNumberState extends State<_SlidingPageNumber> {
  static const Duration _duration = Duration(milliseconds: 260);
  static const Curve _curve = Curves.easeInOutCubic;

  /// +1 = next (slide up), −1 = prev (slide down).
  int _direction = 1;
  late int _displayed;

  @override
  void initState() {
    super.initState();
    _displayed = widget.page;
  }

  @override
  void didUpdateWidget(covariant _SlidingPageNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page == widget.page) return;
    _direction = widget.page > oldWidget.page ? 1 : -1;
    _displayed = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = HomeUi.tableCell(widget.dark).copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1,
    );

    return SizedBox(
      height: 18,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: _duration,
          switchInCurve: _curve,
          switchOutCurve: _curve,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            final bool isIncoming = child.key == ValueKey<int>(_displayed);
            final Animation<Offset> offset = animation.drive(
              Tween<Offset>(
                begin: Offset(
                  0,
                  isIncoming ? _direction.toDouble() : -_direction.toDouble(),
                ),
                end: Offset.zero,
              ),
            );
            return SlideTransition(
              position: offset,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Text(
            '$_displayed',
            key: ValueKey<int>(_displayed),
            style: style,
          ),
        ),
      ),
    );
  }
}

class _FlatNavIcon extends StatefulWidget {
  const _FlatNavIcon({
    required this.dark,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final bool dark;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_FlatNavIcon> createState() => _FlatNavIconState();
}

class _FlatNavIconState extends State<_FlatNavIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final Color activeColor = HomeUi.title(widget.dark);
    final Color mutedColor = HomeUi.muted(widget.dark);
    // Enabled = dark (like the reference); disabled = soft grey. Hover darkens slightly.
    final Color color = !enabled
        ? mutedColor.withValues(alpha: 0.4)
        : (_hover ? activeColor : activeColor.withValues(alpha: 0.82));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(widget.icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _RowsPerPageDropdown extends StatelessWidget {
  const _RowsPerPageDropdown({
    required this.dark,
    required this.rowsPerPage,
    required this.options,
    required this.onChanged,
  });

  final bool dark;
  final int rowsPerPage;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<int> menuOptions = <int>{
      ...options,
      rowsPerPage,
    }.toList()
      ..sort();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Rows per page',
          maxLines: 1,
          softWrap: false,
          style: HomeUi.subtitle(dark).copyWith(fontSize: 12),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          height: HomeUi.controlHeight,
          child: HomeUi.filterFieldShell(
            dark: dark,
            height: HomeUi.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: rowsPerPage,
                dropdownColor: HomeUi.cardBg(dark),
                borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                menuMaxHeight: 280,
                icon: HomeUi.filterChevron(dark),
                style: HomeUi.control(dark, active: true).copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                items: <DropdownMenuItem<int>>[
                  for (final int n in menuOptions)
                    DropdownMenuItem<int>(
                      value: n,
                      child: Text('$n'),
                    ),
                ],
                onChanged: (int? v) {
                  if (v != null && v != rowsPerPage) onChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GotoField extends StatelessWidget {
  const _GotoField({
    required this.dark,
    required this.controller,
    required this.focusNode,
    required this.totalPages,
    required this.onSubmit,
  });

  final bool dark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int totalPages;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Go to',
          maxLines: 1,
          softWrap: false,
          style: HomeUi.subtitle(dark).copyWith(fontSize: 12),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          height: HomeUi.controlHeight,
          child: HomeUi.filterFieldShell(
            dark: dark,
            height: HomeUi.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: totalPages > 1,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: HomeUi.control(dark, active: true).copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: HomeUi.title(dark),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '1–$totalPages',
                hintStyle: HomeUi.subtitle(dark).copyWith(fontSize: 11.5),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
        ),
      ],
    );
  }
}
