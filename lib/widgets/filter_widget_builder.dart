import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/filter_config.dart';
import 'package:musaffa_terminal/Components/screener_dropdown.dart';

class FilterWidgetBuilder {
  static Widget buildFilter({
    required FilterConfig config,
    required String? selectedValue,
    required Function(String?) onChanged,
    required bool isDarkMode,
    bool isApplied = false,
  }) {
    switch (config.type) {
      case 'dropdown':
        return ScreenerDropdown(
          label: config.label,
          value: selectedValue,
          options: config.options
              .map((opt) => {"value": opt.value, "label": opt.label})
              .toList(),
          onChanged: onChanged,
          isDarkMode: isDarkMode,
          isApplied: isApplied,
        );
      
      case 'range':
        // For range dropdowns, we'd need to handle from/to separately
        // For now, treat as regular dropdown
        return ScreenerDropdown(
          label: config.label,
          value: selectedValue,
          options: config.options
              .map((opt) => {"value": opt.value, "label": opt.label})
              .toList(),
          onChanged: onChanged,
          isDarkMode: isDarkMode,
          isApplied: isApplied,
        );
      
      case 'multi-select':
        // For multi-select, we'd need different handling
        // For now, treat as regular dropdown
        return ScreenerDropdown(
          label: config.label,
          value: selectedValue,
          options: config.options
              .map((opt) => {"value": opt.value, "label": opt.label})
              .toList(),
          onChanged: onChanged,
          isDarkMode: isDarkMode,
          isApplied: isApplied,
        );
      
      default:
        return const SizedBox();
    }
  }
}

