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
    if (key == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty &&
        widget.clauses.isNotEmpty) {
      _removeAt(widget.clauses.length - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String get _hint {
    switch (_parsed.expect) {
      case ScreenerQueryExpect.field:
        return widget.clauses.isEmpty
            ? 'e.g. currentPrice > 200'
            : 'AND next field…';
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
            child: Focus(
              onKeyEvent: _onKey,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(dark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focused
                        ? const Color(0xE3E4621E).withValues(alpha: 0.65)
                        : HomeUi.border(dark),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: dark ? 0.28 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(dark),
                    if (widget.clauses.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(dark),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: HomeUi.borderLight(dark)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.terminal_rounded,
                              size: 15,
                              color: HomeUi.muted(dark),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focus,
                                cursorColor: HomeUi.title(dark),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) =>
                                    _commitDraft(forceValue: true),
                                style: HomeUi.control(dark, active: true)
                                    .copyWith(fontSize: 13, height: 1.25),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  hintText: _hint,
                                  hintStyle: HomeUi.control(dark).copyWith(
                                    fontSize: 13,
                                    color: HomeUi.muted(dark),
                                  ),
                                ),
                              ),
                            ),
                            _StageBadge(
                              label: _stageLabel,
                              isDarkMode: dark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Text(
                        'Tab to accept · Enter to apply · Esc to close',
                        style: HomeUi.subtitle(dark).copyWith(fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
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
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: HomeUi.iconWellGradient,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HomeUi.iconWellBorder),
            ),
            child: Center(
              child: HomeUi.brandIcon(
                icon: Icons.edit_note_rounded,
                size: 14,
                gradient: HomeUi.iconFillGradient,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Query filter',
                  style: HomeUi.control(dark, active: true).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Field → operator → value',
                  style: HomeUi.subtitle(dark).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (widget.clauses.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _clearAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Clear',
                    style: HomeUi.control(dark).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: HomeUi.muted(dark),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.onClose != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: HomeUi.muted(dark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _overlay(bool dark) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Stack(
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
          offset: const Offset(0, 8),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: _panelWidth,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(dark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        dark ? const Color(0xFF1E2230) : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: dark ? 0.40 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      child: Text(
                        _parsed.expect == ScreenerQueryExpect.field
                            ? 'Fields'
                            : _parsed.expect == ScreenerQueryExpect.operator
                                ? 'Operators'
                                : 'Values',
                        style: HomeUi.subtitle(dark).copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.35,
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
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                color: selected
                                    ? (dark
                                        ? const Color(0xFF1A1E2A)
                                        : const Color(0xFFF3F4F6))
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        s.title,
                                        style: HomeUi.control(dark, active: true)
                                            .copyWith(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        s.subtitle,
                                        style: HomeUi.subtitle(dark)
                                            .copyWith(fontSize: 11.5),
                                        overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;
  final bool isDarkMode;

  const _StageBadge({required this.label, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: HomeUi.iconWellGradient,
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: HomeUi.iconWellBorder),
      ),
      child: Text(
        label,
        style: HomeUi.control(isDarkMode, active: true).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4, right: 3),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1E2A) : const Color(0xFFF0F1F4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeUi.border(isDarkMode)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 12,
                color: HomeUi.muted(isDarkMode),
              ),
              const SizedBox(width: 4),
              Text(
                clause.display,
                style: HomeUi.control(isDarkMode, active: true).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: HomeUi.muted(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}