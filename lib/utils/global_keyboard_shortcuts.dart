import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/services/global_search_service.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/shariah_compliance/shariah_compliance_screen.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

// Intent classes for keyboard shortcuts
class ToggleWatchlistIntent extends Intent {
  const ToggleWatchlistIntent();
}

class ToggleNotesIntent extends Intent {
  const ToggleNotesIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class OpenShariahComplianceIntent extends Intent {
  const OpenShariahComplianceIntent();
}

/// Global keyboard shortcuts wrapper widget
/// Wraps the entire app to provide keyboard shortcuts on all screens
class GlobalKeyboardShortcutsWrapper extends StatefulWidget {
  final Widget child;

  const GlobalKeyboardShortcutsWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<GlobalKeyboardShortcutsWrapper> createState() =>
      _GlobalKeyboardShortcutsWrapperState();
}

class _GlobalKeyboardShortcutsWrapperState
    extends State<GlobalKeyboardShortcutsWrapper> {
  bool get _shortcutsEnabled {
    if (!Get.isRegistered<AuthController>()) return false;
    final auth = Get.find<AuthController>();
    return auth.isAuthenticated.value && !auth.isInitializing.value;
  }

  bool get _isMac => defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    // App-wide handler so shortcuts still fire when a child Focus/TextField
    // has primary focus (Shortcuts/Focus onKeyEvent alone often miss these).
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    super.dispose();
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!_shortcutsEnabled) return false;

    final keyboard = HardwareKeyboard.instance;
    final bool withCmd = _isMac && keyboard.isMetaPressed;
    final bool withCtrl = keyboard.isControlPressed;
    if (!withCmd && !withCtrl) return false;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyW) {
      _handleToggleWatchlist();
      return true;
    }
    if (key == LogicalKeyboardKey.keyN) {
      _handleToggleNotes();
      return true;
    }
    if (key == LogicalKeyboardKey.keyF) {
      _handleFocusSearch();
      return true;
    }
    // Shariah: Cmd+C (Mac) and Ctrl+C (all platforms, including Mac).
    if (key == LogicalKeyboardKey.keyC) {
      _handleOpenShariahCompliance();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Disable all app shortcuts on login / session-check screens.
    if (Get.isRegistered<AuthController>()) {
      return Obx(() {
        if (!_shortcutsEnabled) return widget.child;
        return _buildShortcuts(widget.child);
      });
    }

    return widget.child;
  }

  Widget _buildShortcuts(Widget child) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Cmd+W / Ctrl+W — Toggle Watchlist
        if (_isMac)
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyW):
              const ToggleWatchlistIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW):
            const ToggleWatchlistIntent(),
        // Cmd+N / Ctrl+N — Toggle Notes
        if (_isMac)
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
              const ToggleNotesIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const ToggleNotesIntent(),
        // Cmd+F / Ctrl+F — Focus Search
        if (_isMac)
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
              const FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const FocusSearchIntent(),
        // Cmd+C / Ctrl+C — Open Shariah Compliance
        if (_isMac)
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):
              const OpenShariahComplianceIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
            const OpenShariahComplianceIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ToggleWatchlistIntent: CallbackAction<ToggleWatchlistIntent>(
            onInvoke: (ToggleWatchlistIntent intent) {
              _handleToggleWatchlist();
              return null;
            },
          ),
          ToggleNotesIntent: CallbackAction<ToggleNotesIntent>(
            onInvoke: (ToggleNotesIntent intent) {
              _handleToggleNotes();
              return null;
            },
          ),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (FocusSearchIntent intent) {
              _handleFocusSearch();
              return null;
            },
          ),
          OpenShariahComplianceIntent:
              CallbackAction<OpenShariahComplianceIntent>(
            onInvoke: (OpenShariahComplianceIntent intent) {
              _handleOpenShariahCompliance();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          canRequestFocus: true,
          child: child,
        ),
      ),
    );
  }

  static void _handleToggleWatchlist() {
    try {
      if (!FeatureNavigation.isEnabled(FeatureKeys.watchlists)) return;

      if (!Get.isRegistered<GlobalWatchlistService>()) {
        return;
      }

      final watchlistService = Get.find<GlobalWatchlistService>();

      if (Get.isRegistered<WatchlistController>()) {
        final watchlistController = Get.find<WatchlistController>();
        if (!watchlistService.isWatchlistOpen.value) {
          watchlistController.resetToDefaultWatchlist();
        }
      }

      watchlistService.toggleWatchlist();
    } catch (e) {
      debugPrint('Error toggling watchlist via keyboard: $e');
    }
  }

  static void _handleToggleNotes() {
    try {
      if (!Get.isRegistered<NotesController>()) {
        return;
      }

      final notesController = Get.find<NotesController>();
      notesController.toggleNotesPanel();
    } catch (e) {
      debugPrint('Error toggling notes via keyboard: $e');
    }
  }

  static void _handleFocusSearch() {
    try {
      if (!FeatureNavigation.isEnabled(FeatureKeys.stockSearch)) return;

      if (!Get.isRegistered<GlobalSearchService>()) {
        return;
      }

      final searchService = Get.find<GlobalSearchService>();
      searchService.focusSearchField();
    } catch (e) {
      debugPrint('Error focusing search field via keyboard: $e');
    }
  }

  static void _handleOpenShariahCompliance() {
    try {
      if (Get.currentRoute == '/shariah-compliance' &&
          FeatureNavigation.isEnabled(FeatureKeys.shariahCompliance)) {
        return;
      }

      FeatureNavigation.toIfAllowed(
        FeatureKeys.shariahCompliance,
        () => const ShariahComplianceScreen(),
        routeName: '/shariah-compliance',
        fullscreenDialog: true,
        transition: Transition.fadeIn,
      );
    } catch (e) {
      debugPrint('Error opening shariah compliance screen: $e');
    }
  }
}
