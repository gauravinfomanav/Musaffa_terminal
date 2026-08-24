import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/filter_config.dart';
import 'package:musaffa_terminal/Components/screener_dropdown.dart';

class FilterWidgetBuilder {
  static Widget buildFilter({
    Key? key,
    required FilterConfig config,
    required String? selectedValue,
    required Function(String?) onChanged,
    required bool isDarkMode,
    bool isApplied = false,
    VoidCallback? onReset,
  }) {
    switch (config.type) {
      case 'dropdown':
      case 'range':
      case 'multi-select':
        return ScreenerDropdown(
          key: key,
          label: config.label,
          value: selectedValue,
          options: config.options
              .map((opt) => {"value": opt.value, "label": opt.label})
              .toList(),
          onChanged: onChanged,
          isDarkMode: isDarkMode,
          isApplied: isApplied,
          onReset: onReset,
        );

      default:
        return const SizedBox();
    }
  }
}
