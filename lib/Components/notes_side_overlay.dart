import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/global_notes_panel_content.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Premium left-edge notes drawer with smooth open/close motion.
class NotesSideOverlay extends StatefulWidget {
  const NotesSideOverlay({super.key});

  static const double drawerWidth = 428;

  @override
  State<NotesSideOverlay> createState() => _NotesSideOverlayState();
}

class _NotesSideOverlayState extends State<NotesSideOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scrim;
  late final Worker _openWorker;
  late final NotesController _notes;

  @override
  void initState() {
    super.initState();
    _notes = Get.find<NotesController>();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 300),
    );

    final curve = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(-1.02, 0),
      end: Offset.zero,
    ).animate(curve);

    _fade = Tween<double>(begin: 0.92, end: 1).animate(curve);
    _scrim = Tween<double>(begin: 0, end: 1).animate(curve);

    if (_notes.isNotesPanelOpen.value) {
      _anim.value = 1;
    }

    _openWorker = ever<bool>(_notes.isNotesPanelOpen, (open) {
      if (open) {
        _anim.forward();
      } else {
        _anim.reverse();
      }
    });
  }

  @override
  void dispose() {
    _openWorker.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final openProgress = _anim.value;
        final handleVisible = openProgress < 0.85;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Dim scrim
            if (openProgress > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: openProgress < 0.05,
                  child: GestureDetector(
                    onTap: _notes.closeNotesPanel,
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: (isDark ? 0.48 : 0.30) * _scrim.value,
                      ),
                    ),
                  ),
                ),
              ),

            // Sliding drawer
            Align(
              alignment: Alignment.centerLeft,
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: NotesSideOverlay.drawerWidth,
                    height: double.infinity,
                    child: _NotesDrawer(
                      isDarkMode: isDark,
                      controller: _notes,
                      onClose: _notes.closeNotesPanel,
                    ),
                  ),
                ),
              ),
            ),

            // Peek handle
            if (handleVisible)
              Positioned(
                left: 0,
                bottom: 28,
                child: Opacity(
                  opacity: (1 - openProgress * 1.35).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(-18 * openProgress, 0),
                    child: IgnorePointer(
                      ignoring: openProgress > 0.2,
                      child: _NotesPeekHandle(isDarkMode: isDark),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotesPeekHandle extends StatefulWidget {
  const _NotesPeekHandle({required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<_NotesPeekHandle> createState() => _NotesPeekHandleState();
}

class _NotesPeekHandleState extends State<_NotesPeekHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final notes = Get.find<NotesController>();

    return Obx(() {
      final showBadge = notes.showPeekBadge.value;

      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: notes.toggleNotesPanel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_hovered ? 4 : 0, 0, 0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D22) : Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: _hovered
                    ? HomeUi.accent(isDark).withValues(alpha: 0.45)
                    : (isDark
                        ? const Color(0xFF2A2F38)
                        : const Color(0xFFE2E8F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: HomeUi.accent(isDark).withValues(
                    alpha: _hovered ? 0.18 : 0.08,
                  ),
                  blurRadius: _hovered ? 24 : 14,
                  offset: Offset(_hovered ? 6 : 3, 2),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(
                    alpha: isDark ? 0.35 : 0.06,
                  ),
                  blurRadius: 18,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accent rail
                  Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: HomeUi.accent(isDark),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 16, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: HomeUi.accent(isDark)
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.notes_rounded,
                                size: 18,
                                color: HomeUi.accent(isDark),
                              ),
                            ),
                            if (showBadge)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: HomeUi.accent(isDark),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1A1D22)
                                          : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'NOTES',
                            style: HomeUi.overline(isDark).copyWith(
                              fontSize: 10.5,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
    final isDark = isDarkMode;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xF214161A),
                        Color(0xF01A1D22),
                      ]
                    : const [
                        Color(0xFFFAFBFC),
                        Color(0xFFFFFFFF),
                      ],
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A2F38)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(
                    alpha: isDark ? 0.55 : 0.18,
                  ),
                  blurRadius: 48,
                  offset: const Offset(16, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DrawerHeader(
                  isDark: isDark,
                  controller: controller,
                  onClose: onClose,
                ),
                Expanded(
                  child: Obx(() {
                    controller.panelContentRevision.value;
                    controller.panelTitle.value;
                    final custom =
                        controller.buildPanelContent(context, onClose);
                    if (custom != null) return custom;
                    return const GlobalNotesPanelContent();
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatefulWidget {
  const _DrawerHeader({
    required this.isDark,
    required this.controller,
    required this.onClose,
  });

  final bool isDark;
  final NotesController controller;
  final VoidCallback onClose;

  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader> {
  bool _closeHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF1F5F9).withValues(alpha: 0.65),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A2F38) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: HomeUi.accent(isDark).withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: HomeUi.accent(isDark).withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.notes_rounded,
              size: 22,
              color: HomeUi.accent(isDark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.controller.panelTitle.value,
                    style: HomeUi.sectionTitle(isDark).copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.controller.panelSubtitle.value.isNotEmpty
                        ? widget.controller.panelSubtitle.value
                        : 'Private scratch space',
                    style: HomeUi.subtitle(isDark).copyWith(
                      fontSize: 12.5,
                      color: isDark
                          ? HomeUi.muted(true)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _closeHovered = true),
            onExit: (_) => setState(() => _closeHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onClose,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _closeHovered
                      ? (isDark
                          ? HomeUi.elevatedBg(true)
                          : Colors.white)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _closeHovered
                        ? HomeUi.borderStrong(isDark)
                        : HomeUi.borderLight(isDark),
                  ),
                  boxShadow: _closeHovered && !isDark
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _closeHovered
                      ? HomeUi.title(isDark)
                      : HomeUi.muted(isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
