import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/research_note.dart';
import 'package:musaffa_terminal/web_service.dart';

class ResearchNotesController extends GetxController {
  final RxList<ResearchNote> notes = <ResearchNote>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> fetchNotes(String ticker) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.GET,
        path: ['research-notes', ticker],
      );

      debugPrint('Research Notes API Response: ${response.data}');
      debugPrint('Response Status: ${response.status}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        debugPrint('Parsed JSON: $jsonData');
        
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final List<dynamic> notesData = jsonData['data'] as List<dynamic>;
          final String responseTicker = jsonData['ticker'] as String? ?? ticker;
          debugPrint('Notes count: ${notesData.length}');
          debugPrint('Ticker from response: $responseTicker');
          
          notes.value = notesData
              .map((note) {
                try {
                  return ResearchNote.fromJson(
                    note as Map<String, dynamic>,
                    ticker: responseTicker,
                  );
                } catch (e) {
                  debugPrint('Error parsing note: $e, note: $note');
                  return null;
                }
              })
              .whereType<ResearchNote>()
              .toList();
          // Sort by creation date, newest first
          notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          debugPrint('Final notes count: ${notes.length}');
        } else {
          notes.value = [];
        }
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to fetch notes';
        notes.value = [];
      }
    } catch (e) {
      debugPrint('Exception fetching notes: $e');
      errorMessage.value = 'Error fetching notes: $e';
      notes.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addNote(String ticker, String noteText) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await WebService.callApi(
        method: HttpMethod.POST,
        path: ['research-notes', ticker],
        body: {
          'note': noteText,
        },
      );

      debugPrint('Add Note API Response: ${response.data}');
      debugPrint('Response Status: ${response.status}');

      if (response.status == ApiStatus.SUCCESS && response.data != null) {
        final jsonData = jsonDecode(response.data!);
        debugPrint('Add Note Parsed JSON: $jsonData');
        
        if (jsonData['status'] == 'success') {
          // Refresh notes after adding
          await fetchNotes(ticker);
          return true;
        }
      }
      errorMessage.value = response.errorMessage ?? 'Failed to add note';
      return false;
    } catch (e) {
      debugPrint('Exception adding note: $e');
      errorMessage.value = 'Error adding note: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasNotes => notes.isNotEmpty;
}

