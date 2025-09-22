class UserPreferencesModel {
  final String userId;
  final String? defaultWatchlistId;
  final DateTime? dateSet;
  final DateTime? lastUpdated;

  UserPreferencesModel({
    required this.userId,
    this.defaultWatchlistId,
    this.dateSet,
    this.lastUpdated,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      userId: json['user_id'] ?? '',
      defaultWatchlistId: json['default_watchlist_id'],
      dateSet: json['date_set'] != null 
          ? DateTime.tryParse(json['date_set'].toString())
          : null,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.tryParse(json['last_updated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'default_watchlist_id': defaultWatchlistId,
      'date_set': dateSet?.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferencesModel &&
        other.userId == userId &&
        other.defaultWatchlistId == defaultWatchlistId;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ defaultWatchlistId.hashCode;
  }
}
