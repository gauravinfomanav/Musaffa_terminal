import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';

class CreateWatchlistDialog extends StatefulWidget {
  final bool isDarkMode;

  const CreateWatchlistDialog({
    super.key,
    required this.isDarkMode,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isDarkMode,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Create Watchlist',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: CreateWatchlistDialog(isDarkMode: isDarkMode),
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
  State<CreateWatchlistDialog> createState() => _CreateWatchlistDialogState();
}

class _CreateWatchlistDialogState extends State<CreateWatchlistDialog> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isCreating = false;
  bool _focused = false;
  bool _hover = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _createWatchlist() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Watchlist name cannot be empty');
      return;
    }

    if (name.length > 100) {
      setState(() => _errorMessage = 'Watchlist name must be less than 100 characters');
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final controller = Get.find<WatchlistController>();
      final success = await controller.createWatchlist(name);

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
        SnackBarUtils.showSuccess(
          context,
          'Watchlist "$name" created successfully',
        );
      } else {
        setState(() {
          _errorMessage = controller.errorMessage.value.isNotEmpty
              ? controller.errorMessage.value
              : 'Failed to create watchlist';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error creating watchlist: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: [
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
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.bookmark_add_outlined,
                      title: 'Create Watchlist',
                      subtitleText: 'Name your list to start tracking stocks',
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isCreating ? null : () => Navigator.of(context).pop(),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: HomeUi.filterFieldColumn(
                dark: isDark,
                label: 'Watchlist Name',
                errorText: _errorMessage,
                field: MouseRegion(
                  onEnter: (_) => setState(() => _hover = true),
                  onExit: (_) => setState(() => _hover = false),
                  child: HomeUi.filterFieldShell(
                    dark: isDark,
                    accent: _focused,
                    hover: _hover,
                    child: TextField(
                      controller: _nameController,
                      focusNode: _focusNode,
                      enabled: !_isCreating,
                      maxLength: 100,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createWatchlist(),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      style: HomeUi.control(isDark, active: true).copyWith(fontSize: 13),
                      cursorColor: HomeUi.title(isDark),
                      decoration: HomeUi.filterTextFieldDecoration(
                        isDark,
                        hintText: 'e.g., My Tech Stocks',
                      ).copyWith(counterText: ''),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: _isCreating ? 0.5 : 1,
                      child: HomeUi.ghostAction(
                        label: 'Cancel',
                        dark: isDark,
                        onTap: _isCreating
                            ? () {}
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Opacity(
                      opacity: _isCreating ? 0.7 : 1,
                      child: HomeUi.primaryAction(
                        label: _isCreating ? 'Creating…' : 'Create',
                        onTap: _isCreating ? () {} : _createWatchlist,
                      ),
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
