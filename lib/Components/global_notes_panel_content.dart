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
  late Worker _notesWorker;
  final NotesController _controller = Get.find<NotesController>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _controller.notesText.value);
    _notesWorker = ever(_controller.notesText, (text) {
      if (_textController.text != text) {
        _textController.text = text;
      }
    });
  }

  @override
  void dispose() {
    _notesWorker.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _textController,
        onChanged: _controller.updateNotes,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: HomeUi.bodyText(isDarkMode).copyWith(height: 1.55),
        decoration: InputDecoration(
          hintText: 'Type your notes here…',
          hintStyle: HomeUi.subtitle(isDarkMode),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
