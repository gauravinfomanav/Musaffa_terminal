import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';

// Intent classes for keyboard shortcuts
class ToggleWatchlistIntent extends Intent {
  const ToggleWatchlistIntent();
}

class ToggleNotesIntent extends Intent {
  const ToggleNotesIntent();
}

/// Global keyboard shortcuts wrapper widget
/// Wraps the entire app to provide keyboard shortcuts on all screens
class GlobalKeyboardShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const GlobalKeyboardShortcutsWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Cmd+W on Mac, Ctrl+W on Windows/Linux - Toggle Watchlist
        if (defaultTargetPlatform == TargetPlatform.macOS)
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyW):
              const ToggleWatchlistIntent(),
        if (defaultTargetPlatform != TargetPlatform.macOS)
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW):
              const ToggleWatchlistIntent(),
        // Cmd+N on Mac, Ctrl+N on Windows/Linux - Toggle Notes
        if (defaultTargetPlatform == TargetPlatform.macOS)
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
              const ToggleNotesIntent(),
        if (defaultTargetPlatform != TargetPlatform.macOS)
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
              const ToggleNotesIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ToggleWatchlistIntent: CallbackAction<ToggleWatchlistIntent>(
            onInvoke: (ToggleWatchlistIntent intent) {
              print('🎹 ToggleWatchlistIntent invoked');
              _handleToggleWatchlist();
              return null;
            },
          ),
          ToggleNotesIntent: CallbackAction<ToggleNotesIntent>(
            onInvoke: (ToggleNotesIntent intent) {
              print('🎹 ToggleNotesIntent invoked');
              _handleToggleNotes();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          canRequestFocus: true,
          skipTraversal: false,
          onKeyEvent: (node, event) {
            // Additional handler for debugging and fallback
            if (event is KeyDownEvent) {
              final keyboard = HardwareKeyboard.instance;
              final isMac = defaultTargetPlatform == TargetPlatform.macOS;
              
              final isWatchlistShortcut = isMac
                  ? keyboard.isMetaPressed && 
                    event.logicalKey == LogicalKeyboardKey.keyW
                  : keyboard.isControlPressed && 
                    event.logicalKey == LogicalKeyboardKey.keyW;

              final isNotesShortcut = isMac
                  ? keyboard.isMetaPressed && 
                    event.logicalKey == LogicalKeyboardKey.keyN
                  : keyboard.isControlPressed && 
                    event.logicalKey == LogicalKeyboardKey.keyN;

              if (isWatchlistShortcut) {
                print('🎹 Cmd+W detected in onKeyEvent handler');
                _handleToggleWatchlist();
                return KeyEventResult.handled;
              } else if (isNotesShortcut) {
                print('🎹 Cmd+N detected in onKeyEvent handler');
                _handleToggleNotes();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: child,
        ),
      ),
    );
  }

  static void _handleToggleWatchlist() {
    try {
      // Use Get.isRegistered to check if service exists
      if (!Get.isRegistered<GlobalWatchlistService>()) {
        print('GlobalWatchlistService not registered yet');
        return;
      }
      
      final watchlistService = Get.find<GlobalWatchlistService>();
      
      // Try to find WatchlistController, but don't fail if it doesn't exist
      if (Get.isRegistered<WatchlistController>()) {
        final watchlistController = Get.find<WatchlistController>();
        // Reset to default watchlist when opening
        if (!watchlistService.isWatchlistOpen.value) {
          watchlistController.resetToDefaultWatchlist();
        }
      }
      
      watchlistService.toggleWatchlist();
      print('✅ Watchlist toggled via keyboard shortcut');
    } catch (e) {
      print('❌ Error toggling watchlist via keyboard: $e');
    }
  }

  static void _handleToggleNotes() {
    try {
      if (!Get.isRegistered<NotesController>()) {
        print('NotesController not registered yet');
        return;
      }
      
      final notesController = Get.find<NotesController>();
      notesController.toggleNotesPanel();
      print('✅ Notes toggled via keyboard shortcut');
    } catch (e) {
      print('❌ Error toggling notes via keyboard: $e');
    }
  }
}

