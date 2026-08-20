import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/global_notes_panel_content.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Left-edge peek tab + slide-in notes drawer (global scratch pad or custom content).
class NotesSideOverlay extends StatelessWidget {
  const NotesSideOverlay({super.key});

  static const double _drawerWidth = 400;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<NotesController>();

    return Obx(() {
      final isOpen = controller.isNotesPanelOpen.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: controller.closeNotesPanel,
                child: AnimatedOpacity(
                  opacity: isOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.32),
                  ),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: isOpen ? 0 : -_drawerWidth,
            top: 0,
            bottom: 0,
            width: _drawerWidth,
            child: _NotesDrawer(
              isDarkMode: isDarkMode,
              controller: controller,
              onClose: controller.closeNotesPanel,
            ),
          ),
          if (!isOpen) _NotesPeekHandle(isDarkMode: isDarkMode),
        ],
      );
    });
  }
}

class _NotesPeekHandle extends StatelessWidget {
  const _NotesPeekHandle({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotesController>();
    final top = MediaQuery.of(context).size.height * 0.42;

    return Positioned(
      left: 0,
      top: top,
      child: Obx(() {
        final showBadge = controller.showPeekBadge.value;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: controller.toggleNotesPanel,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 14, 12, 14),
              decoration: BoxDecoration(
                gradient: HomeUi.iconWellGradient,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: HomeUi.iconWellBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.12),
                    blurRadius: 16,
                    offset: const Offset(4, 0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: HomeUi.accent(isDarkMode),
                      ),
                      if (showBadge)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: HomeUi.accent(isDarkMode),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: HomeUi.pageBg(isDarkMode),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'NOTES',
                      style: HomeUi.overline(isDarkMode).copyWith(
                        fontSize: 9,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NotesDrawer extends StatelessWidget {
  const _NotesDrawer({
    required this.isDarkMode,
    required this.controller,
    required this.onClose,
  });

  final bool isDarkMode;
  final NotesController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: HomeUi.pageBg(isDarkMode),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HomeUi.pageBg(isDarkMode),
          border: Border(
            right: BorderSide(color: HomeUi.borderLight(isDarkMode)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.14),
              blurRadius: 28,
              offset: const Offset(8, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => HomeUi.tableToolbarHeader(
                        isDarkMode,
                        icon: Icons.sticky_note_2_outlined,
                        title: controller.panelTitle.value,
                        subtitleText: controller.panelSubtitle.value.isNotEmpty
                            ? controller.panelSubtitle.value
                            : null,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDarkMode),
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeUi.borderLight(isDarkMode)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: HomeUi.muted(isDarkMode),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDarkMode)),
            Expanded(
              child: Obx(() {
                controller.panelContentRevision.value;
                controller.panelTitle.value;

                final custom = controller.buildPanelContent(context, onClose);
                if (custom != null) return custom;
                return const GlobalNotesPanelContent();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
