import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';

class NotesPanel extends StatefulWidget {
  const NotesPanel({Key? key}) : super(key: key);

  @override
  State<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<NotesPanel> {
  late TextEditingController _textController;
  final NotesController _controller = Get.find<NotesController>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _controller.notesText.value);
    // Listen to controller changes to update text field
    _controller.notesText.listen((text) {
      if (_textController.text != text) {
        _textController.text = text;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (!_controller.isNotesPanelOpen.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: 16,
        bottom: 80, // Above the FAB
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          child: Container(
            width: 400,
            height: 500,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 18,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _controller.closeNotesPanel(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Notes content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _textController,
                      onChanged: (text) => _controller.updateNotes(text),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF111827),
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your notes here...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

