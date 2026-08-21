import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class GlobalNotesPanelContent extends StatefulWidget {
  const GlobalNotesPanelContent({super.key});

  @override
  State<GlobalNotesPanelContent> createState() =>
      _GlobalNotesPanelContentState();
}

class _GlobalNotesPanelContentState extends State<GlobalNotesPanelContent>
    with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late Worker _notesWorker;
  late AnimationController _pulse;
  final NotesController _controller = Get.find<NotesController>();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _controller.notesText.value);
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() => _focused = _focusNode.hasFocus);
      });
    _notesWorker = ever(_controller.notesText, (text) {
      if (_textController.text != text) {
        _textController.text = text;
      }
    });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _notesWorker.dispose();
    _focusNode.dispose();
    _textController.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool empty = _textController.text.trim().isEmpty;
    final int charCount = empty ? 0 : _textController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141820) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _focused
                      ? const Color(0xFFE4621E).withValues(alpha: 0.42)
                      : HomeUi.borderLight(isDark),
                  width: _focused ? 1.35 : 1,
                ),
                boxShadow: _focused
                    ? <BoxShadow>[
                        BoxShadow(
                          color:
                              const Color(0xFFE4621E).withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : HomeUi.cardShadow(isDark),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  children: [
                    if (empty && !_focused)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _EmptyChatState(isDark: isDark, pulse: _pulse),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        onChanged: (value) {
                          _controller.updateNotes(value);
                          setState(() {});
                        },
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: const Color(0xFFE4621E),
                        cursorWidth: 2,
                        style: HomeUi.bodyText(isDark).copyWith(
                          fontSize: 14.5,
                          height: 1.6,
                          letterSpacing: -0.12,
                        ),
                        decoration: InputDecoration(
                          hintText: empty && _focused
                              ? 'Write a thought, ticker idea, or follow-up…'
                              : null,
                          hintStyle: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 14,
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _ComposerFooter(
          isDark: isDark,
          empty: empty,
          charCount: charCount,
          onFocusComposer: () => _focusNode.requestFocus(),
        ),
      ],
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.isDark,
    required this.pulse,
  });

  final bool isDark;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.78, end: 1).animate(pulse),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: HomeUi.iconWellGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: HomeUi.iconWellBorder),
                ),
                child: HomeUi.brandIcon(
                  icon: Icons.edit_note_rounded,
                  size: 20,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Start a memo',
                style: HomeUi.heading(isDark).copyWith(
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Capture ideas and research — autosaved on this device.',
                textAlign: TextAlign.center,
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerFooter extends StatelessWidget {
  const _ComposerFooter({
    required this.isDark,
    required this.empty,
    required this.charCount,
    required this.onFocusComposer,
  });

  final bool isDark;
  final bool empty;
  final int charCount;
  final VoidCallback onFocusComposer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onFocusComposer,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  gradient: HomeUi.iconFillGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFE4621E).withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Write',
                      style: HomeUi.control(isDark, active: true).copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.cloud_done_outlined,
            size: 14,
            color: HomeUi.muted(isDark),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Autosaved locally',
              style: HomeUi.subtitle(isDark).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: HomeUi.elevatedBg(isDark),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Text(
              empty ? 'Empty' : '$charCount',
              style: HomeUi.overline(isDark).copyWith(
                fontSize: 10,
                letterSpacing: 0.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
