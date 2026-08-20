import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/research_notes_controller.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class ResearchNotesPanelContent extends StatelessWidget {
  const ResearchNotesPanelContent({
    super.key,
    required this.ticker,
    required this.controller,
    required this.onAddNote,
  });

  final String ticker;
  final ResearchNotesController controller;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(HomeUi.accent(isDarkMode)),
            ),
          ),
        );
      }

      if (!controller.hasNotes) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No notes yet for this ticker. Add one to keep your research next to the chart.',
                style: HomeUi.bodyText(isDarkMode).copyWith(height: 1.45),
              ),
              const SizedBox(height: 16),
              HomeUi.primaryAction(
                label: 'Add Note',
                icon: Icons.note_add_outlined,
                onTap: onAddNote,
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: HomeUi.ghostAction(
                label: 'Add Note',
                dark: isDarkMode,
                icon: Icons.add_rounded,
                onTap: onAddNote,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: controller.notes.length,
              itemBuilder: (context, index) {
                final note = controller.notes[index];
                return Container(
                  margin: EdgeInsets.only(
                    bottom: index == controller.notes.length - 1 ? 0 : 8,
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: HomeUi.elevatedBg(isDarkMode),
                    borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                    border: Border.all(color: HomeUi.borderLight(isDarkMode)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.text,
                          style: HomeUi.bodyText(isDarkMode)
                              .copyWith(height: 1.45),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(note.createdAt),
                        style: HomeUi.overline(isDarkMode).copyWith(
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
