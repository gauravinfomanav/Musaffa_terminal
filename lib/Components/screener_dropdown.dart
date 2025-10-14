import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Reusable single-select dropdown for screener filters
class ScreenerDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<Map<String, String>> options;
  final Function(String?) onChanged;
  final bool isDarkMode;
  final String? description;
  final bool isApplied;

  const ScreenerDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDarkMode,
    this.description,
    this.isApplied = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add "Any" option at the beginning if not already present
    final allOptions = [
      {"value": "any", "label": "Any"},
      ...options.where((option) => option["value"] != "any"),
    ];
    
    // Use "any" as default if no value is selected
    final selectedValue = value ?? "any";
    
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            label,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          
          // Dropdown
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isApplied 
                  ? (isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5)) // Very subtle tint for applied filters
                  : (isDarkMode ? const Color(0xFF1A1A1A) : Colors.white), // Normal background
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isApplied
                    ? (isDarkMode ? const Color(0xFF505050) : const Color(0xFFD0D0D0)) // Very faint border for applied filters
                    : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)), // Normal border
                width: 1, // Same width for both
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                ),
                dropdownColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                onChanged: onChanged,
                items: allOptions.map<DropdownMenuItem<String>>((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(
                      option['label'] ?? '',
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        fontSize: 12,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable multi-select dropdown for screener filters
class ScreenerMultiSelectDropdown extends StatefulWidget {
  final String label;
  final List<String> selectedValues;
  final List<Map<String, String>> options;
  final Function(List<String>) onChanged;
  final bool isDarkMode;
  final String? description;

  const ScreenerMultiSelectDropdown({
    Key? key,
    required this.label,
    required this.selectedValues,
    required this.options,
    required this.onChanged,
    required this.isDarkMode,
    this.description,
  }) : super(key: key);

  @override
  State<ScreenerMultiSelectDropdown> createState() => _ScreenerMultiSelectDropdownState();
}

class _ScreenerMultiSelectDropdownState extends State<ScreenerMultiSelectDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayText = widget.selectedValues.isEmpty 
        ? 'Any' 
        : widget.selectedValues.length == 1
            ? _getLabelForValue(widget.selectedValues.first)
            : '${widget.selectedValues.length} selected';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Text(
                widget.label,
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              
              // Dropdown trigger
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayText,
                          style: DashboardTextStyles.tickerSymbol.copyWith(
                            fontSize: 12,
                            color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 20,
                        color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Dropdown menu (when expanded) - positioned absolutely to overlay
        if (_isExpanded)
          Positioned(
            top: 40, // Position below the trigger
            left: 0,
            right: 0,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: widget.options.map((option) {
                  final value = option['value'] ?? '';
                  final label = option['label'] ?? '';
                  final isSelected = widget.selectedValues.contains(value);
                  
                  return InkWell(
                    onTap: () {
                      final newValues = List<String>.from(widget.selectedValues);
                      if (isSelected) {
                        newValues.remove(value);
                      } else {
                        newValues.add(value);
                      }
                      widget.onChanged(newValues);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                                  : Colors.transparent,
                              border: Border.all(
                                color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: DashboardTextStyles.tickerSymbol.copyWith(
                                fontSize: 12,
                                color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  String _getLabelForValue(String value) {
    final option = widget.options.firstWhere(
      (opt) => opt['value'] == value,
      orElse: () => {'label': value},
    );
    return option['label'] ?? value;
  }
}

/// Reusable range dropdown for screener filters (from/to)
class ScreenerRangeDropdown extends StatelessWidget {
  final String label;
  final String? fromValue;
  final String? toValue;
  final List<Map<String, String>> options;
  final Function(String?) onFromChanged;
  final Function(String?) onToChanged;
  final bool isDarkMode;
  final String? description;

  const ScreenerRangeDropdown({
    Key? key,
    required this.label,
    required this.fromValue,
    required this.toValue,
    required this.options,
    required this.onFromChanged,
    required this.onToChanged,
    required this.isDarkMode,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add "Any" option at the beginning if not already present
    final allOptions = [
      {"value": "any", "label": "Any"},
      ...options.where((option) => option["value"] != "any"),
    ];
    
    // Use "any" as default if no value is selected
    final selectedFromValue = fromValue ?? "any";
    final selectedToValue = toValue ?? "any";
    
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            label,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          
          // From/To dropdowns
          Row(
            children: [
              // From dropdown
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFromValue,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        fontSize: 11,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                      dropdownColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                      onChanged: onFromChanged,
                      items: allOptions.map<DropdownMenuItem<String>>((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(
                            option['label'] ?? '',
                            style: DashboardTextStyles.tickerSymbol.copyWith(
                              fontSize: 11,
                              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // To dropdown
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedToValue,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        fontSize: 11,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                      dropdownColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                      onChanged: onToChanged,
                      items: allOptions.map<DropdownMenuItem<String>>((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(
                            option['label'] ?? '',
                            style: DashboardTextStyles.tickerSymbol.copyWith(
                              fontSize: 11,
                              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

