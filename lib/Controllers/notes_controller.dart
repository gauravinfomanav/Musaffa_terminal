import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef NotesPanelBuilder = Widget Function(
  BuildContext context,
  VoidCallback onClose,
);

/// Global notes panel state + optional per-screen custom content (e.g. ticker research notes).
class NotesController extends GetxController {
  final RxBool isNotesPanelOpen = false.obs;
  final RxString notesText = ''.obs;
  final RxString panelTitle = 'Memo'.obs;
  final RxString panelSubtitle = 'Private research pad'.obs;
  final RxBool showPeekBadge = false.obs;

  NotesPanelBuilder? _customPanelBuilder;
  final RxInt panelContentRevision = 0.obs;

  static const String _notesKey = 'user_notes';
  Timer? _saveTimer;
  SharedPreferences? _prefs;

  bool get hasCustomPanel => _customPanelBuilder != null;

  @override
  void onInit() {
    super.onInit();
    _initializePrefs();
  }

  @override
  void onClose() {
    _saveTimer?.cancel();
    if (notesText.value.isNotEmpty) {
      _saveNotesImmediately(notesText.value);
    }
    super.onClose();
  }

  void setCustomPanel({
    required NotesPanelBuilder builder,
    required String title,
    String subtitle = '',
    bool showBadge = false,
  }) {
    _customPanelBuilder = builder;
    panelTitle.value = title;
    panelSubtitle.value = subtitle;
    showPeekBadge.value = showBadge;
    panelContentRevision.value++;
  }

  void updatePeekBadge(bool show) {
    showPeekBadge.value = show;
  }

  void clearCustomPanel() {
    _customPanelBuilder = null;
    panelTitle.value = 'Memo';
    panelSubtitle.value = 'Private research pad';
    showPeekBadge.value = false;
    panelContentRevision.value++;
  }

  Widget? buildPanelContent(BuildContext context, VoidCallback onClose) {
    final builder = _customPanelBuilder;
    if (builder != null) {
      return builder(context, onClose);
    }
    return null;
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      loadNotes();
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }
  }

  void toggleNotesPanel() {
    isNotesPanelOpen.value = !isNotesPanelOpen.value;
    if (!isNotesPanelOpen.value && _customPanelBuilder == null) {
      if (notesText.value.isNotEmpty) {
        _saveNotesImmediately(notesText.value);
      }
    }
  }

  void openNotesPanel() {
    if (!isNotesPanelOpen.value) {
      isNotesPanelOpen.value = true;
    }
  }

  void closeNotesPanel() {
    isNotesPanelOpen.value = false;
    if (_customPanelBuilder == null && notesText.value.isNotEmpty) {
      _saveNotesImmediately(notesText.value);
    }
  }

  void updateNotes(String text) {
    notesText.value = text;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1000), () {
      _saveNotesImmediately(text);
    });
  }

  Future<void> _saveNotesImmediately(String text) async {
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('Error getting SharedPreferences instance: $e');
        return;
      }
    }

    try {
      await _prefs!.setString(_notesKey, text);
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  Future<void> loadNotes() async {
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('Error getting SharedPreferences instance: $e');
        return;
      }
    }

    try {
      final savedNotes = _prefs!.getString(_notesKey) ?? '';
      notesText.value = savedNotes;
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }
}
