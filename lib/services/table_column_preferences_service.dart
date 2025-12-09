import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage table column preferences (visibility, order) per table
class TableColumnPreferencesService extends GetxService {
  static const String _prefsPrefix = 'table_column_prefs_';
  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get saved column preferences for a table
  /// Returns a map with 'visibleColumns' (List<String>) and 'columnOrder' (List<String>)
  Map<String, dynamic>? getColumnPreferences(String tableId) {
    if (_prefs == null) return null;
    
    final prefsJson = _prefs!.getString('$_prefsPrefix$tableId');
    if (prefsJson == null) return null;
    
    try {
      return jsonDecode(prefsJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save column preferences for a table
  Future<bool> saveColumnPreferences(
    String tableId,
    List<String> visibleColumns,
    List<String> columnOrder,
  ) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    
    final prefsMap = {
      'visibleColumns': visibleColumns,
      'columnOrder': columnOrder,
    };
    
    return await _prefs!.setString(
      '$_prefsPrefix$tableId',
      jsonEncode(prefsMap),
    );
  }

  /// Reset column preferences for a table to defaults
  Future<bool> resetColumnPreferences(String tableId) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    
    return await _prefs!.remove('$_prefsPrefix$tableId');
  }

  /// Check if a column is visible for a table
  bool isColumnVisible(String tableId, String fieldName) {
    final prefs = getColumnPreferences(tableId);
    if (prefs == null) return true; // Default: all columns visible
    
    final visibleColumns = prefs['visibleColumns'] as List<dynamic>?;
    if (visibleColumns == null) return true;
    
    return visibleColumns.contains(fieldName);
  }

  /// Get column order for a table
  List<String>? getColumnOrder(String tableId) {
    final prefs = getColumnPreferences(tableId);
    if (prefs == null) return null;
    
    final columnOrder = prefs['columnOrder'] as List<dynamic>?;
    if (columnOrder == null) return null;
    
    return columnOrder.map((e) => e.toString()).toList();
  }
}

