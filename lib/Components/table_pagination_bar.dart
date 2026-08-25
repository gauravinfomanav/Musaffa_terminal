import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Shared table pagination strip — rows-per-page, Go-to field, and page nav.
///
/// [currentPage] / [onPageChanged] are **1-based**.
/// Submit Go-to with Enter (no separate Go button).

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

  List<int?> _pageItems(int current, int total) {
    if (total <= 7) {
      return <int?>[for (int i = 1; i <= total; i++) i];
    }
    final Set<int> set = <int>{1, total, current};
    if (current - 1 > 1) set.add(current - 1);
    if (current + 1 < total) set.add(current + 1);
    final List<int> sorted = set.toList()..sort();
    final List<int?> out = <int?>[];
    int? prev;
    for (final int p in sorted) {
      if (prev != null && p - prev > 1) out.add(null);
      out.add(p);
      prev = p;
    }
    return out;
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

    final Widget status = Text.rich(
      TextSpan(
        style: HomeUi.subtitle(dark).copyWith(fontSize: 12.5),
        children: <InlineSpan>[
          const TextSpan(text: 'Page '),
          TextSpan(
            text: '$current',
            style: HomeUi.tableCell(dark).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const TextSpan(text: ' of '),
          TextSpan(
            text: _comma(total),
            style: HomeUi.tableCell(dark).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          if (widget.summaryText != null && widget.summaryText!.isNotEmpty)
            TextSpan(text: '  ·  ${widget.summaryText}'),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );

    final bool showRows = widget.rowsPerPage != null &&
        widget.onRowsPerPageChanged != null;

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
        _NavIcon(
          dark: dark,
          icon: Icons.chevron_left_rounded,
          enabled: current > 1,
          onTap: () => _goTo(current - 1),
        ),
        if (widget.showPageButtons) ...<Widget>[
          for (final int? item in _pageItems(current, total))
            if (item == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '…',
                  style: HomeUi.subtitle(dark).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _PageChip(
                  dark: dark,
                  page: item,
                  selected: item == current,
                  onTap: () => _goTo(item),
                ),
              ),
        ],
        _NavIcon(
          dark: dark,
          icon: Icons.chevron_right_rounded,
          enabled: current < total,
          onTap: () => _goTo(current + 1),
        ),
      ],
    ];

    // Always one horizontal line — scroll if the strip is too wide.
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
                    status,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: controls),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: status,
                      ),
                    ),
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

  static String _comma(int value) {
    final String s = value.toString();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
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

class _NavIcon extends StatefulWidget {
  const _NavIcon({
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
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: enabled ? 1 : 0.38,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: HomeUi.controlHeight,
            height: HomeUi.controlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled && _hover
                  ? HomeUi.iconFillGradient
                  : HomeUi.iconWellGradient,
              border: Border.all(
                color: enabled && _hover
                    ? HomeUi.buttonBorder
                    : HomeUi.iconWellBorder,
                width: 0.856,
              ),
            ),
            child: enabled && _hover
                ? Icon(widget.icon, size: 18, color: Colors.white)
                : HomeUi.brandIcon(icon: widget.icon, size: 18),
          ),
        ),
      ),
    );
  }
}

class _PageChip extends StatefulWidget {
  const _PageChip({
    required this.dark,
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final bool dark;
  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PageChip> createState() => _PageChipState();
}

class _PageChipState extends State<_PageChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final bool active = selected || _hover;
    // Match Next/Prev circular hit target; slightly wider only for 3+ digits.
    final double size =
        widget.page >= 100 ? HomeUi.controlHeight + 4 : HomeUi.controlHeight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active ? HomeUi.iconFillGradient : HomeUi.iconWellGradient,
            border: Border.all(
              color: active ? HomeUi.buttonBorder : HomeUi.iconWellBorder,
              width: 0.856,
            ),
          ),
          child: Center(
            child: active
                ? Text(
                    '${widget.page}',
                    style: HomeUi.control(widget.dark, active: true).copyWith(
                      fontSize: widget.page >= 100 ? 11 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '${widget.page}',
                    style: HomeUi.control(widget.dark, active: true).copyWith(
                      fontSize: widget.page >= 100 ? 11 : 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
