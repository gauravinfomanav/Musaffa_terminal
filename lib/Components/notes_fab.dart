import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';

class NotesFAB extends StatelessWidget {
  const NotesFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotesController>();

    return Positioned(
      left: 16,
      bottom: 16,
      child: Obx(() {
        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          color: Colors.transparent,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFC107), // Yellow color
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => controller.toggleNotesPanel(),
                child: Center(
                  child: Icon(
                    controller.isNotesPanelOpen.value ? Icons.close : Icons.note,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

