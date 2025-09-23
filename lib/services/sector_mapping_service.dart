import 'dart:convert';
import 'package:flutter/services.dart';

class SectorMappingService {
  static Map<String, List<String>>? _sectorApiMapping;
  
  /// Initialize the sector mapping from JSON file
  static Future<void> initialize() async {
    if (_sectorApiMapping != null) return;
    
    try {
      final String jsonString = await rootBundle.loadString('lib/utils/sector_api_mapping.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _sectorApiMapping = Map<String, List<String>>.from(
        jsonData.map((key, value) => MapEntry(
          key,
          List<String>.from(value)
        ))
      );
    } catch (e) {
      print('Error loading sector API mapping: $e');
      _sectorApiMapping = {};
    }
  }
  
  /// Get mapped sectors for a given API sector name
  static List<String>? getMappedSectors(String sectorName) {
    return _sectorApiMapping?[sectorName];
  }
  
  /// Check if a sector exists in the mapping
  static bool hasSectorMapping(String sectorName) {
    return _sectorApiMapping?.containsKey(sectorName) ?? false;
  }
  
  /// Get all available API sector names
  static List<String> getAllApiSectorNames() {
    return _sectorApiMapping?.keys.toList() ?? [];
  }
}
