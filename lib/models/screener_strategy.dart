class ScreenerStrategy {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic> filters;
  final String? sortBy;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final int? resultsCount;

  ScreenerStrategy({
    required this.id,
    required this.name,
    this.description,
    required this.filters,
    this.sortBy,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.resultsCount,
  });

  factory ScreenerStrategy.fromJson(Map<String, dynamic> json) {
    return ScreenerStrategy(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      filters: Map<String, dynamic>.from(json['filters'] as Map? ?? {}),
      sortBy: json['sortBy'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      userId: json['userId'] as String?,
      resultsCount: json['resultsCount'] as int?,
    );
  }

  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData is Map) {
      // Handle Firestore timestamp format: {"_seconds": 1762149584, "_nanoseconds": 514000000}
      if (dateData.containsKey('_seconds')) {
        final seconds = dateData['_seconds'] as int;
        final nanoseconds = dateData['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      }
    } else if (dateData is String) {
      // Handle ISO string format: "2025-01-15T10:30:00.000Z"
      try {
        return DateTime.parse(dateData);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateData is int) {
      // Handle Unix timestamp
      return DateTime.fromMillisecondsSinceEpoch(dateData * 1000);
    }
    // Default to now if parsing fails
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'filters': filters,
      'sortBy': sortBy,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'resultsCount': resultsCount,
    };
  }

  // Convert filters to format expected by FilterController (Map<String, dynamic>)
  Map<String, dynamic> getFiltersForController() {
    return Map<String, dynamic>.from(filters);
  }
}

class ScreenerStrategyListResponse {
  final String status;
  final List<ScreenerStrategy> strategies;
  final PaginationInfo? pagination;

  ScreenerStrategyListResponse({
    required this.status,
    required this.strategies,
    this.pagination,
  });

  factory ScreenerStrategyListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    return ScreenerStrategyListResponse(
      status: json['status'] as String? ?? 'success',
      strategies: data
          .map((item) => ScreenerStrategy.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaginationInfo {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  PaginationInfo({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

