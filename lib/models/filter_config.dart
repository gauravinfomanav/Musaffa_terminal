class FilterOption {
  final String value;
  final String label;

  FilterOption({
    required this.value,
    required this.label,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}

class FilterConfig {
  final String id;
  final String label;
  final String type; // 'dropdown', 'range', 'multi-select'
  final String? field; // stocks_data field name
  final List<FilterOption> options;

  FilterConfig({
    required this.id,
    required this.label,
    required this.type,
    this.field,
    required this.options,
  });

  factory FilterConfig.fromJson(Map<String, dynamic> json) {
    return FilterConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      field: json['field'] as String?,
      options: (json['options'] as List<dynamic>)
          .map((option) => FilterOption.fromJson(option as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'field': field,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

class ScreenerFiltersConfig {
  final List<FilterConfig> descriptive;
  final List<FilterConfig> fundamental;
  final List<FilterConfig> technical;
  final List<FilterConfig> growth;
  final List<FilterConfig> etf;

  ScreenerFiltersConfig({
    required this.descriptive,
    required this.fundamental,
    required this.technical,
    required this.growth,
    required this.etf,
  });

  factory ScreenerFiltersConfig.fromJson(Map<String, dynamic> json) {
    return ScreenerFiltersConfig(
      descriptive: (json['descriptive'] as List<dynamic>)
          .map((filter) => FilterConfig.fromJson(filter as Map<String, dynamic>))
          .toList(),
      fundamental: (json['fundamental'] as List<dynamic>)
          .map((filter) => FilterConfig.fromJson(filter as Map<String, dynamic>))
          .toList(),
      technical: (json['technical'] as List<dynamic>)
          .map((filter) => FilterConfig.fromJson(filter as Map<String, dynamic>))
          .toList(),
      growth: (json['growth'] as List<dynamic>)
          .map((filter) => FilterConfig.fromJson(filter as Map<String, dynamic>))
          .toList(),
      etf: (json['etf'] as List<dynamic>)
          .map((filter) => FilterConfig.fromJson(filter as Map<String, dynamic>))
          .toList(),
    );
  }

  List<FilterConfig> getFiltersForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'descriptive':
        return descriptive;
      case 'fundamental':
        return fundamental;
      case 'technical':
        return technical;
      case 'growth':
        return growth;
      case 'etf':
        return etf;
      default:
        return [];
    }
  }
}

