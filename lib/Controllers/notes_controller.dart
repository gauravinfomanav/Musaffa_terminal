import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesController extends GetxController {
  final RxBool isNotesPanelOpen = false.obs;
  final RxString notesText = ''.obs;
  
  static const String _notesKey = 'user_notes';
  Timer? _saveTimer;
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _initializePrefs();
  }

  @override
  void onClose() {
    _saveTimer?.cancel();
    // Save immediately when controller is disposed
    if (notesText.value.isNotEmpty) {
      _saveNotesImmediately(notesText.value);
    }
    super.onClose();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      loadNotes();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  void toggleNotesPanel() {
    isNotesPanelOpen.value = !isNotesPanelOpen.value;
  }

  void closeNotesPanel() {
    isNotesPanelOpen.value = false;
    // Save immediately when closing
    if (notesText.value.isNotEmpty) {
      _saveNotesImmediately(notesText.value);
    }
  }

  void updateNotes(String text) {
    notesText.value = text;
    // Debounce: Cancel previous timer and start new one
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
        print('Error getting SharedPreferences instance: $e');
        return;
      }
    }

    try {
      await _prefs!.setString(_notesKey, text);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  Future<void> loadNotes() async {
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        print('Error getting SharedPreferences instance: $e');
        return;
      }
    }

    try {
      final savedNotes = _prefs!.getString(_notesKey) ?? '';
      notesText.value = savedNotes;
    } catch (e) {
      print('Error loading notes: $e');
    }
  }
}

