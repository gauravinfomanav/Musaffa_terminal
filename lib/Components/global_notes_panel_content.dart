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

class _GlobalNotesPanelContentState extends State<GlobalNotesPanelContent> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late Worker _notesWorker;
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
  }

  @override
  void dispose() {
    _notesWorker.dispose();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final charCount =
        _textController.text.trim().isEmpty ? 0 : _textController.text.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF14161A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _focused
                      ? HomeUi.accent(isDarkMode).withValues(alpha: 0.45)
                      : (isDarkMode
                          ? const Color(0xFF2A2F38)
                          : const Color(0xFFE2E8F0)),
                  width: _focused ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _focused
                        ? HomeUi.accent(isDarkMode).withValues(alpha: 0.10)
                        : const Color(0xFF0F172A).withValues(
                            alpha: isDarkMode ? 0.25 : 0.04,
                          ),
                    blurRadius: _focused ? 20 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                cursorColor: HomeUi.accent(isDarkMode),
                cursorWidth: 2,
                style: HomeUi.bodyText(isDarkMode).copyWith(
                  fontSize: 14.5,
                  height: 1.65,
                  letterSpacing: -0.15,
                ),
                decoration: InputDecoration(
                  hintText: 'Jot a thought, ticker idea, or follow-up…',
                  hintStyle: HomeUi.subtitle(isDarkMode).copyWith(
                    fontSize: 14.5,
                    height: 1.6,
                    color: isDarkMode
                        ? HomeUi.muted(true)
                        : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? HomeUi.elevatedBg(true)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF2A2F38)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  size: 15,
                  color: HomeUi.accent(isDarkMode),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Autosaved on this device',
                    style: HomeUi.subtitle(isDarkMode).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF2A2F38)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    charCount == 0 ? 'Empty' : '$charCount',
                    style: HomeUi.overline(isDarkMode).copyWith(
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w700,
                    ),
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
