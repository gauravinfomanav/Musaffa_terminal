import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/research_notes_controller.dart';
import 'package:musaffa_terminal/models/research_note.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Header pill that opens the Research Notes panel.
class ResearchNotesHeaderButton extends StatefulWidget {
  const ResearchNotesHeaderButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  State<ResearchNotesHeaderButton> createState() =>
      _ResearchNotesHeaderButtonState();
}

class _ResearchNotesHeaderButtonState extends State<ResearchNotesHeaderButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: HomeUi.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_hover
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFF1A1D22))
                : Colors.white,
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _hover
                      ? (widget.isDark ? 0.28 : 0.08)
                      : (widget.isDark ? 0.18 : 0.04),
                ),
                blurRadius: _hover ? 14 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HomeUi.brandIcon(
                icon: Icons.sticky_note_2_outlined,
                size: 14,
                gradient: HomeUi.softBrandIconGradient,
              ),
              const SizedBox(width: 7),
              Text(
                'Research Notes',
                style: HomeUi.control(widget.isDark, active: true).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen barrier + panel with bottom slide enter/exit.
class ResearchNotesSlideLayer extends StatefulWidget {
  const ResearchNotesSlideLayer({
    super.key,
    required this.visible,
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.onRequestClose,
    required this.onExitComplete,
    required this.child,
    this.top = 112,
    this.right = 20,
  });

  final bool visible;
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final VoidCallback onRequestClose;
  final VoidCallback onExitComplete;
  final Widget child;
  final double top;
  final double right;

  @override
  State<ResearchNotesSlideLayer> createState() =>
      _ResearchNotesSlideLayerState();
}

class _ResearchNotesSlideLayerState extends State<ResearchNotesSlideLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.42),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _ctrl.addStatusListener(_onStatus);
    if (widget.visible) {
      _ctrl.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      widget.onExitComplete();
    }
  }

  @override
  void didUpdateWidget(covariant ResearchNotesSlideLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: widget.onRequestClose,
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.28),
              ),
            ),
          ),
        ),
        Positioned(
          top: widget.top,
          right: widget.right,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ResearchNotesOverlayCard(
                isDarkMode: widget.isDarkMode,
                title: widget.title,
                subtitle: widget.subtitle,
                onClose: widget.onRequestClose,
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Floating Research Notes panel shell — shared by ticker / ETF detail.
class ResearchNotesOverlayCard extends StatelessWidget {
  const ResearchNotesOverlayCard({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.child,
  });

  final bool isDarkMode;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 440,
        height: 580,
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDarkMode),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF2A2E38)
                : const Color(0xFFE8EAEE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            if (!isDarkMode)
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: HomeUi.softBrandWellGradient,
                    ),
                    child: HomeUi.brandIcon(
                      icon: Icons.edit_note_rounded,
                      size: 20,
                      gradient: HomeUi.softBrandIconGradient,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: HomeUi.cardTitle(isDarkMode).copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: HomeUi.borderLight(isDarkMode),
                              ),
                            ),
                            child: Text(
                              subtitle.trim().toUpperCase(),
                              style: HomeUi.control(isDarkMode, active: true)
                                  .copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CloseChip(isDark: isDarkMode, onTap: onClose),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: HomeUi.borderLight(isDarkMode).withValues(alpha: 0.7),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a private notebook',
                style: HomeUi.cardTitle(isDarkMode).copyWith(
                  fontSize: 15,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture thesis, catalysts, and reminders for $ticker — kept next to the chart.',
                style: HomeUi.bodyText(isDarkMode).copyWith(
                  height: 1.5,
                  color: HomeUi.muted(isDarkMode),
                ),
              ),
              const SizedBox(height: 22),
              HomeUi.primaryAction(
                label: 'Add note',
                icon: Icons.add_rounded,
                onTap: onAddNote,
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Text(
                  '${controller.notes.length} note${controller.notes.length == 1 ? '' : 's'}',
                  style: HomeUi.subtitle(isDarkMode).copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                HomeUi.primaryAction(
                  label: 'Add note',
                  icon: Icons.add_rounded,
                  onTap: onAddNote,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: controller.notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ResearchNoteTile(
                  note: controller.notes[index],
                  isDark: isDarkMode,
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class _CloseChip extends StatefulWidget {
  const _CloseChip({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_CloseChip> createState() => _CloseChipState();
}

class _CloseChipState extends State<_CloseChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hover
                ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF3F4F6))
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: _hover
                ? HomeUi.body(widget.isDark)
                : HomeUi.muted(widget.isDark),
          ),
        ),
      ),
    );
  }
}

class _ResearchNoteTile extends StatefulWidget {
  const _ResearchNoteTile({
    required this.note,
    required this.isDark,
  });

  final ResearchNote note;
  final bool isDark;

  @override
  State<_ResearchNoteTile> createState() => _ResearchNoteTileState();
}

class _ResearchNoteTileState extends State<_ResearchNoteTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _hover = false;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  ({String title, String body}) _splitNote(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (title: 'Untitled note', body: '');
    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return (title: 'Untitled note', body: '');
    final title = _humanizeTitle(lines.first);
    final body = lines.length > 1 ? lines.sublist(1).join('\n\n') : '';
    if (body.isEmpty && title.length > 72) {
      final cut = title.lastIndexOf(' ', 64);
      final idx = cut > 24 ? cut : 64;
      return (
        title: title.substring(0, idx).trim(),
        body: title.substring(idx).trim(),
      );
    }
    return (title: title, body: body);
  }

  String _humanizeTitle(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'Untitled note';
    if (t.length > 3 && t == t.toUpperCase() && RegExp(r'[A-Z]').hasMatch(t)) {
      final lower = t.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }
    return t;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) {
      return difference.inDays == 1 ? 'Yesterday' : '${difference.inDays}d ago';
    }
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final split = _splitNote(widget.note.text);
    final hasBody = split.body.isNotEmpty;
    final canExpand = hasBody || widget.note.text.trim().length > 72;
    final bodyText =
        split.body.isNotEmpty ? split.body : widget.note.text.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: widget.isDark
              ? (_hover ? const Color(0xFF1A1D24) : const Color(0xFF15181E))
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hover
                ? HomeUi.borderStrong(widget.isDark)
                : HomeUi.borderLight(widget.isDark),
          ),
          boxShadow: _hover && !widget.isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    split.title,
                    style: HomeUi.cardTitle(widget.isDark).copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatDate(widget.note.createdAt),
                  style: HomeUi.subtitle(widget.isDark).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (canExpand) ...[
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _expandAnim,
                  axisAlignment: -1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      bodyText,
                      style: HomeUi.bodyText(widget.isDark).copyWith(
                        fontSize: 13,
                        height: 1.55,
                        color: HomeUi.muted(widget.isDark),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ReadMoreChip(
                isDark: widget.isDark,
                expanded: _expanded,
                onTap: _toggle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadMoreChip extends StatefulWidget {
  const _ReadMoreChip({
    required this.isDark,
    required this.expanded,
    required this.onTap,
  });

  final bool isDark;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_ReadMoreChip> createState() => _ReadMoreChipState();
}

class _ReadMoreChipState extends State<_ReadMoreChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.expanded ? 'Show less' : 'Read more';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 32,
          padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
          decoration: BoxDecoration(
            color: _hover
                ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF8FAFC))
                : (widget.isDark ? const Color(0xFF1A1D22) : Colors.white),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: _hover
                  ? HomeUi.borderStrong(widget.isDark)
                  : HomeUi.borderLight(widget.isDark),
            ),
            boxShadow: _hover && !widget.isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: HomeUi.softBrandWellGradient,
                  shape: BoxShape.circle,
                ),
                child: AnimatedRotation(
                  turns: widget.expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: HomeUi.brandIcon(
                    icon: Icons.expand_more_rounded,
                    size: 14,
                    gradient: HomeUi.softBrandIconGradient,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: HomeUi.control(widget.isDark, active: true).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
