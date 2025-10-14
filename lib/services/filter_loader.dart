import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/models/filter_config.dart';

class FilterLoader {
  static ScreenerFiltersConfig? _cachedConfig;

  static Future<ScreenerFiltersConfig> loadFilters() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/screener_filters.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Parse and cache
      _cachedConfig = ScreenerFiltersConfig.fromJson(jsonData);
      return _cachedConfig!;
    } catch (e) {
      print('Error loading filters: $e');
      // Return empty config on error
      return ScreenerFiltersConfig(
        descriptive: [],
        fundamental: [],
        technical: [],
        growth: [],
        etf: [],
      );
    }
  }

  static void clearCache() {
    _cachedConfig = null;
  }
}

