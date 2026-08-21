import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/global_notes_panel_content.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Premium left-edge memo drawer with smooth open/close motion.
class NotesSideOverlay extends StatefulWidget {
  const NotesSideOverlay({super.key});

  static const double drawerWidth = 400;

  @override
  State<NotesSideOverlay> createState() => _NotesSideOverlayState();
}

class _NotesSideOverlayState extends State<NotesSideOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _scrim;
  late final Animation<double> _contentSlide;
  late final Worker _openWorker;
  late final NotesController _notes;

  @override
  void initState() {
    super.initState();
    _notes = Get.find<NotesController>();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      reverseDuration: const Duration(milliseconds: 320),
    );

    final curve = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(-1.04, 0),
      end: Offset.zero,
    ).animate(curve);

    _fade = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.96, end: 1).animate(curve);

    _scrim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.22, 1.0, curve: Curves.easeOutCubic),
      ),
    );

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
        final handleVisible = openProgress < 0.72;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (openProgress > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: openProgress < 0.05,
                  child: GestureDetector(
                    onTap: _notes.closeNotesPanel,
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: (isDark ? 0.52 : 0.28) * _scrim.value,
                      ),
                    ),
                  ),
                ),
              ),

            Align(
              alignment: Alignment.centerLeft,
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: NotesSideOverlay.drawerWidth,
                      height: double.infinity,
                      child: _NotesDrawer(
                        isDarkMode: isDark,
                        controller: _notes,
                        onClose: _notes.closeNotesPanel,
                        contentOffsetY: _contentSlide.value,
                        contentOpacity: Curves.easeOut.transform(
                          ((openProgress - 0.15) / 0.85).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (handleVisible)
              Align(
                alignment: const Alignment(-1, 0.62),
                child: Opacity(
                  opacity: (1 - openProgress * 1.5).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(-6 * openProgress, 0),
                    child: IgnorePointer(
                      ignoring: openProgress > 0.15,
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

  static const IconData _memoIcon = Icons.edit_note_rounded;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final notes = Get.find<NotesController>();

    return Obx(() {
      final showBadge = notes.showPeekBadge.value;
      const accent = Color(0xFFE4621E);
      final idleBg = isDark ? const Color(0xFF1A1F28) : HomeUi.cardBg(false);
      // Logo gradient fill on hover; white glyphs stay readable on brand colors.
      final fg = _hovered ? Colors.white : HomeUi.muted(isDark);

      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: notes.toggleNotesPanel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_hovered ? 0 : -6, 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
            decoration: BoxDecoration(
              gradient: _hovered ? HomeUi.brandGradient : null,
              color: _hovered ? null : idleBg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
              border: Border(
                top: BorderSide(
                  color: _hovered
                      ? HomeUi.buttonBorder
                      : HomeUi.borderLight(isDark),
                ),
                right: BorderSide(
                  width: _hovered ? 1.5 : 1,
                  color: _hovered
                      ? HomeUi.buttonBorder
                      : HomeUi.borderLight(isDark),
                ),
                bottom: BorderSide(
                  color: _hovered
                      ? HomeUi.buttonBorder
                      : HomeUi.borderLight(isDark),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(
                    alpha: isDark
                        ? (_hovered ? 0.40 : 0.22)
                        : (_hovered ? 0.10 : 0.04),
                  ),
                  blurRadius: _hovered ? 12 : 6,
                  offset: Offset(_hovered ? 2 : 1, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: Icon(
                          _memoIcon,
                          size: 16,
                          color: fg,
                        ),
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _hovered ? Colors.white : accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _hovered ? accent : idleBg,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'MEMO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.5,
                      letterSpacing: 1.7,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: fg,
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

class _NotesDrawer extends StatelessWidget {
  const _NotesDrawer({
    required this.isDarkMode,
    required this.controller,
    required this.onClose,
    required this.contentOffsetY,
    required this.contentOpacity,
  });

  final bool isDarkMode;
  final NotesController controller;
  final VoidCallback onClose;
  final double contentOffsetY;
  final double contentOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xF2161A21),
                        Color(0xF01C2129),
                      ]
                    : const [
                        Color(0xFFF8FAFC),
                        Color(0xFFFFFFFF),
                      ],
              ),
              border: Border(
                right: BorderSide(color: HomeUi.borderLight(isDark)),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(
                    alpha: isDark ? 0.55 : 0.16,
                  ),
                  blurRadius: 40,
                  offset: const Offset(12, 0),
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
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Transform.translate(
                      offset: Offset(0, contentOffsetY),
                      child: Obx(() {
                        controller.panelContentRevision.value;
                        controller.panelTitle.value;
                        final custom =
                            controller.buildPanelContent(context, onClose);
                        if (custom != null) return custom;
                        return const GlobalNotesPanelContent();
                      }),
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(color: HomeUi.borderLight(isDark)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: HomeUi.iconWellGradient,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: HomeUi.iconWellBorder),
            ),
            child: HomeUi.brandIcon(
              icon: Icons.edit_note_rounded,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.controller.panelTitle.value,
                    style: HomeUi.sectionTitle(isDark).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.controller.panelSubtitle.value.isNotEmpty
                        ? widget.controller.panelSubtitle.value
                        : 'Private research pad',
                    style: HomeUi.subtitle(isDark).copyWith(
                      fontSize: 12,
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
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _closeHovered
                      ? HomeUi.elevatedBg(isDark)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _closeHovered
                        ? HomeUi.borderStrong(isDark)
                        : HomeUi.borderLight(isDark),
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
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
