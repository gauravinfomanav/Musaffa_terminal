class ResultsTabColumn {
  final String id;
  final String label;
  final String field;
  final String type; // 'text', 'number', 'percentage', 'currency', 'date'
  final int? width;
  final bool sortable;

  ResultsTabColumn({
    required this.id,
    required this.label,
    required this.field,
    required this.type,
    this.width,
    this.sortable = true,
  });

  factory ResultsTabColumn.fromJson(Map<String, dynamic> json) {
    return ResultsTabColumn(
      id: json['id'] as String,
      label: json['label'] as String,
      field: json['field'] as String,
      type: json['type'] as String,
      width: json['width'] as int?,
      sortable: json['sortable'] as bool? ?? true,
    );
  }
}

class ResultsTabConfig {
  final String id;
  final String label;
  final List<ResultsTabColumn> columns;
  final bool isDefault;

  ResultsTabConfig({
    required this.id,
    required this.label,
    required this.columns,
    this.isDefault = false,
  });

  factory ResultsTabConfig.fromJson(Map<String, dynamic> json) {
    var columnsList = json['columns'] as List;
    List<ResultsTabColumn> columns = columnsList
        .map((columnJson) => ResultsTabColumn.fromJson(columnJson))
        .toList();

    return ResultsTabConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      columns: columns,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class ResultsTabsConfig {
  final List<ResultsTabConfig> tabs;

  ResultsTabsConfig({required this.tabs});

  factory ResultsTabsConfig.fromJson(Map<String, dynamic> json) {
    var tabsList = json['tabs'] as List;
    List<ResultsTabConfig> tabs = tabsList
        .map((tabJson) => ResultsTabConfig.fromJson(tabJson))
        .toList();

    return ResultsTabsConfig(tabs: tabs);
  }

  ResultsTabConfig getDefaultTab() {
    return tabs.firstWhere(
      (tab) => tab.isDefault,
      orElse: () => tabs.first,
    );
  }

  ResultsTabConfig getTabById(String id) {
    return tabs.firstWhere((tab) => tab.id == id);
  }
}
