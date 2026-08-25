import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/models/screener_query.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Compact query composer — intended to open from a trigger button, not sit full-width.
class ScreenerQueryBar extends StatefulWidget {
  final bool isDarkMode;
  final List<ScreenerQueryClause> clauses;
  final ValueChanged<List<ScreenerQueryClause>> onChanged;
  final VoidCallback? onClose;
  final bool autofocus;

  /// Preferred panel width; capped by available space.
  final double maxWidth;

  /// Optional text to seed the editor (e.g. when editing an existing clause).
  final String? initialDraft;

  const ScreenerQueryBar({
    super.key,
    required this.isDarkMode,
    required this.clauses,
    required this.onChanged,
    this.onClose,
    this.autofocus = true,
    this.maxWidth = 480,
    this.initialDraft,
  });

  @override
  State<ScreenerQueryBar> createState() => _ScreenerQueryBarState();
}

class _ScreenerQueryBarState extends State<ScreenerQueryBar> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  int _highlight = 0;
  double _panelWidth = 420;
  bool _picking = false;
  List<ScreenerQuerySuggestion> _suggestions = const [];
  ScreenerQueryParseResult _parsed = const ScreenerQueryParseResult(
    clauses: [],
    remainder: '',
    expect: ScreenerQueryExpect.field,
  );

  @override
  void initState() {
    super.initState();
    // Attach to the TextField's own node so arrow/esc/tab don't wrap the field
    // in a parent Focus that can swallow Backspace on desktop.
    _focus.onKeyEvent = _onKey;
    _focus.addListener(_onFocus);
    _controller.addListener(_onText);
    if (widget.initialDraft != null && widget.initialDraft!.isNotEmpty) {
      final draft = widget.initialDraft!.endsWith(' ')
          ? widget.initialDraft!
          : '${widget.initialDraft!} ';
      _controller.text = draft;
    }
    _refreshSuggestions();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ScreenerQueryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDraft != null &&
        widget.initialDraft != oldWidget.initialDraft &&
        widget.initialDraft!.isNotEmpty) {
      final draft = widget.initialDraft!.endsWith(' ')
          ? widget.initialDraft!
          : '${widget.initialDraft!} ';
      _controller.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
      _refreshSuggestions();
      _focus.requestFocus();
      _open();
    }
  }

  @override
  void dispose() {
    _focus.onKeyEvent = null;
    _focus.removeListener(_onFocus);
    _controller.removeListener(_onText);
    if (_portal.isShowing) {
      _portal.hide();
    }
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_picking) return;
    if (_focus.hasFocus) {
      _refreshSuggestions();
      if (_suggestions.isNotEmpty) {
        _open();
      } else {
        _close();
      }
    } else {
      // Defer blur handling so overlay row clicks register before we close.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _picking || _focus.hasFocus) return;
        _commitDraft(forceValue: true);
        _close();
        setState(() {});
      });
    }
    setState(() {});
  }

  void _onText() {
    _refreshSuggestions();
    if (_focus.hasFocus) {
      if (_suggestions.isNotEmpty) {
        _open();
      } else {
        _close();
      }
    }
    setState(() {});
  }

  void _refreshSuggestions() {
    _parsed = ScreenerQueryParser.parse(_controller.text);
    _suggestions = ScreenerQueryParser.suggestions(_parsed);
    if (_highlight >= _suggestions.length) {
      _highlight = _suggestions.isEmpty ? 0 : _suggestions.length - 1;
    }
  }

  void _open() {
    final box = context.findRenderObject() as RenderBox?;
    final w = box?.size.width ?? widget.maxWidth;
    _panelWidth = w.clamp(280.0, widget.maxWidth);
    if (!_portal.isShowing) _portal.show();
  }

  void _close() {
    if (_portal.isShowing) _portal.hide();
  }

  void _emit(List<ScreenerQueryClause> next) {
    widget.onChanged(List<ScreenerQueryClause>.from(next));
  }

  void _acceptSuggestion(ScreenerQuerySuggestion suggestion) {
    if (suggestion.kind == ScreenerQuerySuggestionKind.value &&
        suggestion.insert.isEmpty) {
      return;
    }
    _picking = true;

    var insert = suggestion.insert;
    if (suggestion.kind == ScreenerQuerySuggestionKind.value) {
      insert = _quoteIfNeeded(insert);
    }

    final next = _replaceRemainder(
      insert,
      trailingSpace: suggestion.kind != ScreenerQuerySuggestionKind.value,
    );
    if (suggestion.kind == ScreenerQuerySuggestionKind.value) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      _commitDraft(forceValue: true);
      _picking = false;
      _focus.requestFocus();
      return;
    }

    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _refreshSuggestions();
    if (_focus.hasFocus && _suggestions.isNotEmpty) {
      _open();
    } else {
      _close();
    }
    _picking = false;
    _focus.requestFocus();
    setState(() {});
  }

  String _quoteIfNeeded(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return v;
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'")) ||
        (v.startsWith('`') && v.endsWith('`'))) {
      return v;
    }
    if (v.contains(RegExp(r'\s'))) return '"$v"';
    return v;
  }

  void _editAt(int index) {
    if (index < 0 || index >= widget.clauses.length) return;
    final clause = widget.clauses[index];
    final next = [...widget.clauses]..removeAt(index);
    _emit(next);
    final value = _quoteIfNeeded(clause.rawValue);
    final text = '${clause.field.id} ${clause.operator.symbol} $value ';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _refreshSuggestions();
    _focus.requestFocus();
    _open();
    setState(() {});
  }

  String _replaceRemainder(String insert, {required bool trailingSpace}) {
    final text = _controller.text;
    final parsed = ScreenerQueryParser.parse(text);
    var prefix = text;
    final rem = parsed.remainder;
    if (rem.isNotEmpty) {
      final idx = text.toLowerCase().lastIndexOf(rem.toLowerCase());
      if (idx >= 0) prefix = text.substring(0, idx);
    }
    var next = '${prefix.trimRight()} $insert'.trim();
    if (trailingSpace) next = '$next ';
    return next;
  }

  void _commitDraft({required bool forceValue}) {
    final parsed = ScreenerQueryParser.parse(
      _controller.text,
      closeValue: forceValue,
    );
    if (parsed.clauses.isEmpty) return;

    final leftover = parsed.activeField == null
        ? parsed.remainder
        : [
            parsed.activeField?.id,
            parsed.activeOperator?.symbol,
            parsed.remainder,
          ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    _controller.value = TextEditingValue(
      text: leftover.isEmpty ? '' : '$leftover ',
      selection: TextSelection.collapsed(
        offset: leftover.isEmpty ? 0 : leftover.length + 1,
      ),
    );
    _emit([...widget.clauses, ...parsed.clauses]);
    _refreshSuggestions();
  }

  void _removeAt(int index) {
    final next = [...widget.clauses]..removeAt(index);
    _emit(next);
  }

  void _clearAll() {
    _controller.clear();
    _emit(const []);
    _refreshSuggestions();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    // Let TextField own all text-editing keys. Only steal Backspace when the
    // draft is empty so we can pop the last clause chip.
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      if (key == LogicalKeyboardKey.backspace &&
          _controller.text.isEmpty &&
          widget.clauses.isNotEmpty) {
        _removeAt(widget.clauses.length - 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_suggestions.isEmpty) return KeyEventResult.ignored;
      setState(() => _highlight = (_highlight + 1) % _suggestions.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_suggestions.isEmpty) return KeyEventResult.ignored;
      setState(() {
        _highlight =
            (_highlight - 1 + _suggestions.length) % _suggestions.length;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_portal.isShowing) {
        _close();
        return KeyEventResult.handled;
      }
      widget.onClose?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.enter) {
      if (_suggestions.isNotEmpty &&
          _portal.isShowing &&
          _highlight >= 0 &&
          _highlight < _suggestions.length) {
        final s = _suggestions[_highlight];
        if (!(s.kind == ScreenerQuerySuggestionKind.value &&
            s.insert.isEmpty)) {
          _acceptSuggestion(s);
          return KeyEventResult.handled;
        }
      }
      if (key == LogicalKeyboardKey.enter) {
        _commitDraft(forceValue: true);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  String get _hint {
    switch (_parsed.expect) {
      case ScreenerQueryExpect.field:
        return widget.clauses.isEmpty
            ? 'e.g. Price > 200'
            : 'Add another field…';
      case ScreenerQueryExpect.operator:
        return '>, >=, <, = …';
      case ScreenerQueryExpect.value:
        return _parsed.activeField?.unitHint ?? 'value';
    }
  }

  String get _stageLabel {
    switch (_parsed.expect) {
      case ScreenerQueryExpect.field:
        return 'Field';
      case ScreenerQueryExpect.operator:
        return 'Op';
      case ScreenerQueryExpect.value:
        return 'Value';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final focused = _focus.hasFocus;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => _overlay(dark),
          child: CompositedTransformTarget(
            link: _link,
            child: Container(
              decoration: BoxDecoration(
                color: HomeUi.cardBg(dark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: focused
                      ? HomeUi.borderStrong(dark)
                      : HomeUi.borderLight(dark),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(dark),
                  if (widget.clauses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < widget.clauses.length; i++)
                            _ClauseChip(
                              clause: widget.clauses[i],
                              isDarkMode: dark,
                              onEdit: () => _editAt(i),
                              onRemove: () => _removeAt(i),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF181B20)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        // Hairline only — depth comes from shadow, not a heavy stroke.
                        border: Border.all(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFEEF0F3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: dark
                                  ? (focused ? 0.45 : 0.32)
                                  : (focused ? 0.10 : 0.06),
                            ),
                            blurRadius: focused ? 18 : 12,
                            spreadRadius: focused ? 0 : -1,
                            offset: Offset(0, focused ? 6 : 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: dark ? 0.18 : 0.03,
                            ),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: focused
                                ? HomeUi.body(dark)
                                : HomeUi.muted(dark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focus,
                              cursorColor: HomeUi.title(dark),
                              cursorWidth: 1.2,
                              textInputAction: TextInputAction.search,
                              keyboardType: TextInputType.text,
                              onSubmitted: (_) =>
                                  _commitDraft(forceValue: true),
                              style: HomeUi.control(dark, active: true)
                                  .copyWith(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                hintText: _hint,
                                hintStyle: HomeUi.control(dark).copyWith(
                                  fontSize: 13,
                                  color: HomeUi.muted(dark),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _stageLabel,
                            style: HomeUi.subtitle(dark).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      'Tab to accept  ·  Enter to apply  ·  Esc to close',
                      style: HomeUi.subtitle(dark).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Query filter',
                  style: HomeUi.sectionTitle(dark).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Field, operator, then value',
                  style: HomeUi.subtitle(dark).copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (widget.clauses.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              style: TextButton.styleFrom(
                foregroundColor: HomeUi.muted(dark),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Clear',
                style: HomeUi.control(dark).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              tooltip: 'Close',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: HomeUi.muted(dark),
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }

  Widget _overlay(bool dark) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    final sectionTitle = _parsed.expect == ScreenerQueryExpect.field
        ? 'Fields'
        : _parsed.expect == ScreenerQueryExpect.operator
            ? 'Operators'
            : 'Values';

    return ExcludeFocus(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _focus.unfocus();
                _close();
              },
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 6),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
              width: _panelWidth,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(dark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeUi.borderLight(dark)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                      child: Text(
                        sectionTitle,
                        style: HomeUi.subtitle(dark).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 6),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, i) {
                          final s = _suggestions[i];
                          final selected = i == _highlight;
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => _highlight = i),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_) => _acceptSuggestion(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                color: selected
                                    ? (dark
                                        ? const Color(0xFF1A1D22)
                                        : const Color(0xFFF5F6F8))
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        s.title,
                                        style: HomeUi.control(dark, active: true)
                                            .copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        s.subtitle,
                                        style: HomeUi.subtitle(dark).copyWith(
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

class _ClauseChip extends StatelessWidget {
  final ScreenerQueryClause clause;
  final bool isDarkMode;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  const _ClauseChip({
    required this.clause,
    required this.isDarkMode,
    required this.onRemove,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 4),
          decoration: BoxDecoration(
            color: HomeUi.elevatedBg(dark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HomeUi.borderLight(dark)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clause.display,
                style: HomeUi.control(dark, active: true).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: HomeUi.muted(dark),
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