import 'dart:convert';
import 'package:flutter/services.dart';

class SectorMappingService {
  static Map<String, List<Map<String, String>>>? _sectorBuckets;
  
  /// Initialize the sector mapping from JSON file
  static Future<void> initialize() async {
    if (_sectorBuckets != null) return;
    
    try {
      final String jsonString = await rootBundle.loadString('lib/utils/sector_defaults.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _sectorBuckets = Map<String, List<Map<String, String>>>.from(
        jsonData['buckets'].map((key, value) => MapEntry(
          key,
          List<Map<String, String>>.from(
            value.map((item) => Map<String, String>.from(item))
          )
        ))
      );
    } catch (e) {
      print('Error loading sector defaults: $e');
      _sectorBuckets = {};
    }
  }
  
  /// Map sector/industry to bucket key
  static String mapSectorToBucket(String sector, String industry) {
    if (_sectorBuckets == null) {
      // Fallback to simple mapping if JSON not loaded
      return _simpleSectorMapping(sector, industry);
    }
    
    String sectorLower = sector.toLowerCase().trim();
    String industryLower = industry.toLowerCase().trim();
    
    // Search through all buckets
    for (String bucketKey in _sectorBuckets!.keys) {
      List<Map<String, String>> bucketItems = _sectorBuckets![bucketKey]!;
      
      for (Map<String, String> item in bucketItems) {
        String key = item['key']?.toLowerCase().trim() ?? '';
        String displayValue = item['display_value']?.toLowerCase().trim() ?? '';
        
        // Check if sector or industry matches
        if (sectorLower == key || sectorLower == displayValue ||
            industryLower == key || industryLower == displayValue ||
            sectorLower.contains(key) || key.contains(sectorLower) ||
            industryLower.contains(key) || key.contains(industryLower)) {
          return bucketKey;
        }
      }
    }
    
    // Fallback to simple mapping
    return _simpleSectorMapping(sector, industry);
  }
  
  /// Simple fallback mapping
  static String _simpleSectorMapping(String sector, String industry) {
    String sectorLower = sector.toLowerCase();
    String industryLower = industry.toLowerCase();
    
    if (sectorLower.contains('technology') || industryLower.contains('technology') ||
        sectorLower.contains('information technology') || industryLower.contains('information technology')) {
      return 'technology';
    } else if (sectorLower.contains('health') || industryLower.contains('health') ||
               sectorLower.contains('healthcare') || industryLower.contains('healthcare')) {
      return 'health_care';
    } else if (sectorLower.contains('financial') || industryLower.contains('financial') ||
               sectorLower.contains('finance') || industryLower.contains('finance')) {
      return 'financials';
    } else if (sectorLower.contains('energy') || industryLower.contains('energy')) {
      return 'energy';
    } else if (sectorLower.contains('consumer') || industryLower.contains('consumer')) {
      return 'consumer_goods';
    } else if (sectorLower.contains('industrial') || industryLower.contains('industrial')) {
      return 'industrials';
    } else if (sectorLower.contains('utility') || industryLower.contains('utility')) {
      return 'utilities';
    } else if (sectorLower.contains('real estate') || industryLower.contains('real estate')) {
      return 'real_estate';
    } else if (sectorLower.contains('communication') || industryLower.contains('communication')) {
      return 'communications';
    } else if (sectorLower.contains('material') || industryLower.contains('material')) {
      return 'building_materials';
    } else if (sectorLower.contains('retail') || industryLower.contains('retail')) {
      return 'retail';
    } else if (sectorLower.contains('automobile') || industryLower.contains('automobile')) {
      return 'automobiles';
    } else if (sectorLower.contains('pharmaceutical') || industryLower.contains('pharmaceutical')) {
      return 'pharmaceuticals';
    } else if (sectorLower.contains('biotechnology') || industryLower.contains('biotechnology')) {
      return 'biotechnology';
    } else if (sectorLower.contains('semiconductor') || industryLower.contains('semiconductor')) {
      return 'semiconductor_stocks';
    }
    
    return '';
  }
  
  /// Get all available bucket keys
  static List<String> getAllBucketKeys() {
    return _sectorBuckets?.keys.toList() ?? [];
  }
  
  /// Get bucket items for a specific key
  static List<Map<String, String>>? getBucketItems(String bucketKey) {
    return _sectorBuckets?[bucketKey];
  }
}
