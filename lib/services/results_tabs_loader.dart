import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:musaffa_terminal/models/results_tab_config.dart';

class ResultsTabsLoader {
  static ResultsTabsConfig? _cachedConfig;

  static Future<ResultsTabsConfig> loadTabs() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/results_tabs_config.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _cachedConfig = ResultsTabsConfig.fromJson(jsonData);
      return _cachedConfig!;
    } catch (e) {
      print('Error loading results tabs: $e');
      // Fallback to a basic config
      return ResultsTabsConfig(tabs: [
        ResultsTabConfig(
          id: 'overview',
          label: 'Overview',
          isDefault: true,
          columns: [
            ResultsTabColumn(
              id: 'ticker',
              label: 'Ticker',
              field: 'ticker',
              type: 'text',
              width: 80,
            ),
            ResultsTabColumn(
              id: 'name',
              label: 'Name',
              field: 'name',
              type: 'text',
              width: 200,
            ),
            ResultsTabColumn(
              id: 'price',
              label: 'Price',
              field: 'price',
              type: 'currency',
              width: 80,
            ),
          ],
        ),
      ]);
    }
  }
}
