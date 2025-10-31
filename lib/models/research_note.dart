class ResearchNote {
  final String id;
  final String ticker;
  final String text;
  final DateTime createdAt;

  ResearchNote({
    required this.id,
    required this.ticker,
    required this.text,
    required this.createdAt,
  });

  factory ResearchNote.fromJson(Map<String, dynamic> json, {String? ticker}) {
    DateTime parseDate(dynamic dateData) {
      if (dateData is Map) {
        // Handle Firestore timestamp format: {"_seconds": 1761887242, "_nanoseconds": 655000000}
        if (dateData.containsKey('_seconds')) {
          final seconds = dateData['_seconds'] as int;
          final nanoseconds = dateData['_nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        }
      } else if (dateData is String) {
        // Handle ISO string format: "2025-10-31T05:07:22.655Z"
        return DateTime.parse(dateData);
      } else if (dateData is int) {
        // Handle Unix timestamp
        return DateTime.fromMillisecondsSinceEpoch(dateData * 1000);
      }
      throw FormatException('Unable to parse date: $dateData');
    }

    return ResearchNote(
      id: json['id'] as String,
      ticker: ticker ?? json['ticker'] as String? ?? '',
      text: json['text'] as String,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticker': ticker,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

