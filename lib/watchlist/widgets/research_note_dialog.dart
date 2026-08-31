import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class ResearchNoteDialog extends StatefulWidget {
  const ResearchNoteDialog({
    super.key,
    required this.symbol,
    required this.initialText,
  });

  final String symbol;
  final String initialText;

  static Future<String?> show({
    required BuildContext context,
    required String symbol,
    String initialText = '',
  }) {
    return showGeneralDialog<String?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit research note',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ResearchNoteDialog(
              symbol: symbol,
              initialText: initialText,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ResearchNoteDialog> createState() => _ResearchNoteDialogState();
}

class _ResearchNoteDialogState extends State<ResearchNoteDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Note cannot be empty');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.sticky_note_2_outlined,
                      title: 'My Note',
                      subtitleText: 'Private research for ${widget.symbol}',
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: HomeUi.controlHeight,
                        height: HomeUi.controlHeight,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDark),
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeUi.borderLight(isDark)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: HomeUi.muted(isDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: FilterTextField(
                dark: isDark,
                label: 'Research note',
                controller: _controller,
                hintText: 'Add your thesis, catalysts, or reminders…',
                errorText: _errorMessage,
                minLines: 4,
                maxLines: 8,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: HomeUi.ghostAction(
                      label: 'Cancel',
                      dark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HomeUi.primaryAction(
                      label: 'Save',
                      icon: Icons.check_rounded,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
