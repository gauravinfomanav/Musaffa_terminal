import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Premium searchable filter control (overlay menu, not Material dropdown).
class ScreenerDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<Map<String, String>> options;
  final Function(String?) onChanged;
  final bool isDarkMode;
  final String? description;
  final bool isApplied;
  final VoidCallback? onReset;

  const ScreenerDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDarkMode,
    this.description,
    this.isApplied = false,
    this.onReset,
  }) : super(key: key);

  @override
  State<ScreenerDropdown> createState() => _ScreenerDropdownState();
}

class _ScreenerDropdownState extends State<ScreenerDropdown> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _hover = false;
  double _fieldWidth = 220;

  List<Map<String, String>> get _allOptions => [
        {"value": "any", "label": "Any"},
        ...widget.options.where((option) => option["value"] != "any"),
      ];

  String get _selectedValue => widget.value ?? "any";

  String get _selectedLabel {
    for (final o in _allOptions) {
      if (o['value'] == _selectedValue) return o['label'] ?? 'Any';
    }
    return 'Any';
  }

  bool get _isAny => _selectedValue == 'any' || _selectedValue.isEmpty;

  bool get _useSearch => _allOptions.length >= 8;

  List<Map<String, String>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _allOptions;
    return _allOptions
        .where((o) => (o['label'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    if (_portal.isShowing) {
      _portal.hide();
    }
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _open() {
    final box = context.findRenderObject() as RenderBox?;
    _fieldWidth = box?.size.width ?? 220;
    _search.clear();
    _portal.show();
    if (_useSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocus.requestFocus();
      });
    }
    setState(() {});
  }

  void _close() {
    if (_portal.isShowing) {
      _portal.hide();
      setState(() {});
    }
  }

  void _toggle() {
    if (_portal.isShowing) {
      _close();
    } else {
      _open();
    }
  }

  void _pick(String? value) {
    widget.onChanged(value);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final open = _portal.isShowing;
    final showAccent = open;
    final showHover = _hover && !open;

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => _menuOverlay(dark),
      child: CompositedTransformTarget(
        link: _link,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                height: 1.2,
                color: dark
                    ? const Color(0xFF8B8FA3)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): _close,
              },
              child: MouseRegion(
                onEnter: (_) => setState(() => _hover = true),
                onExit: (_) => setState(() => _hover = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _toggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: showAccent
                          ? null
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: dark
                                  ? [const Color(0xFF151822), const Color(0xFF111520)]
                                  : [Colors.white, const Color(0xFFFCFCFD)],
                            ),
                      color: showAccent ? HomeUi.cardBg(dark) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showAccent
                            ? const Color(0xFFE4621E).withValues(alpha: 0.5)
                            : (showHover
                                ? (dark ? const Color(0xFF2A2E3A) : const Color(0xFFD1D5DB))
                                : (dark ? const Color(0xFF1E2230) : const Color(0xFFE5E7EB))),
                        width: showAccent ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: showAccent
                              ? const Color(0xFFE4621E).withValues(alpha: dark ? 0.15 : 0.08)
                              : Colors.black.withValues(alpha: dark ? 0.12 : 0.04),
                          blurRadius: showAccent ? 12 : (showHover ? 8 : 4),
                          offset: Offset(0, showAccent ? 4 : 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isAny
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              fontStyle: _isAny ? FontStyle.italic : FontStyle.normal,
                              color: _isAny
                                  ? (dark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                                  : HomeUi.title(dark),
                            ),
                          ),
                        ),
                        if (widget.isApplied && widget.onReset != null)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                widget.onReset?.call();
                                _close();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: HomeUi.muted(dark),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: showAccent
                                ? HomeUi.iconWellGradient
                                : null,
                            color: showAccent
                                ? null
                                : (dark ? const Color(0xFF1A1E2A) : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AnimatedRotation(
                            turns: open ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: showAccent
                                ? HomeUi.brandIcon(
                                    icon: Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    gradient: HomeUi.iconFillGradient,
                                  )
                                : Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: dark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuOverlay(bool dark) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: _fieldWidth,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(dark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: dark
                        ? const Color(0xFF1E2230)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.40 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.12 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_useSearch) _searchBar(dark),
                    Flexible(
                      child: _filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                'No matches',
                                style: HomeUi.subtitle(dark).copyWith(fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final option = _filtered[i];
                                return _OptionRow(
                                  label: option['label'] ?? '',
                                  selected: option['value'] == _selectedValue,
                                  isAny: option['value'] == 'any',
                                  isDarkMode: dark,
                                  onTap: () => _pick(option['value']),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: TextField(
        controller: _search,
        focusNode: _searchFocus,
        onChanged: (_) => setState(() {}),
        cursorColor: HomeUi.title(dark),
        style: HomeUi.control(dark, active: true).copyWith(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search',
          hintStyle: HomeUi.control(dark).copyWith(fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 16,
            color: HomeUi.muted(dark),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          filled: true,
          fillColor: HomeUi.elevatedBg(dark),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: HomeUi.borderLight(dark)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: HomeUi.borderLight(dark)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: HomeUi.buttonBorder),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatefulWidget {
  final String label;
  final bool selected;
  final bool isAny;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.isAny,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final bg = widget.selected
        ? HomeUi.elevatedBg(dark)
        : (_hover ? HomeUi.tableRowHover(dark) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: bg,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: widget.selected ? HomeUi.iconFillGradient : null,
                  color: widget.selected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.selected
                        ? HomeUi.buttonBorder
                        : HomeUi.borderStrong(dark),
                  ),
                ),
                child: widget.selected
                    ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.control(dark, active: !widget.isAny).copyWith(
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isAny && !widget.selected
                        ? HomeUi.muted(dark)
                        : HomeUi.title(dark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
