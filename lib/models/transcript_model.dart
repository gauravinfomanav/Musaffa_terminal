class TranscriptListItem {
  const TranscriptListItem({
    required this.id,
    this.title,
    this.symbol,
    this.year,
    this.quarter,
    this.time,
    this.audio,
  });

  final String id;
  final String? title;
  final String? symbol;
  final int? year;
  final int? quarter;
  final String? time;
  final String? audio;

  String get label {
    final String q =
        quarter != null && year != null ? 'Q$quarter $year' : (title ?? id);
    return q;
  }

  factory TranscriptListItem.fromJson(Map<String, dynamic> json) {
    return TranscriptListItem(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString(),
      symbol: json['symbol']?.toString(),
      year: _toInt(json['year']),
      quarter: _toInt(json['quarter']),
      time: json['time']?.toString(),
      audio: json['audio']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class TranscriptParticipant {
  const TranscriptParticipant({
    this.name,
    this.description,
    this.role,
  });

  final String? name;
  final String? description;
  final String? role;

  factory TranscriptParticipant.fromJson(Map<String, dynamic> json) {
    return TranscriptParticipant(
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class TranscriptSpeech {
  const TranscriptSpeech({
    this.name,
    this.speech,
    this.session,
  });

  final String? name;
  final String? speech;
  final String? session;

  bool get isQa {
    final String s = (session ?? '').toLowerCase();
    return s.contains('q&a') || s.contains('qa') || s == 'q and a';
  }

  factory TranscriptSpeech.fromJson(Map<String, dynamic> json) {
    return TranscriptSpeech(
      name: json['name']?.toString() ?? json['speaker']?.toString(),
      speech: json['speech']?.toString(),
      session: json['session']?.toString(),
    );
  }
}

class TranscriptDetail {
  const TranscriptDetail({
    required this.id,
    this.title,
    this.symbol,
    this.year,
    this.quarter,
    this.time,
    this.audio,
    this.participants = const <TranscriptParticipant>[],
    this.transcript = const <TranscriptSpeech>[],
  });

  final String id;
  final String? title;
  final String? symbol;
  final int? year;
  final int? quarter;
  final String? time;
  final String? audio;
  final List<TranscriptParticipant> participants;
  final List<TranscriptSpeech> transcript;

  List<TranscriptSpeech> get managementDiscussion =>
      transcript.where((TranscriptSpeech s) => !s.isQa).toList();

  List<TranscriptSpeech> get qa =>
      transcript.where((TranscriptSpeech s) => s.isQa).toList();

  factory TranscriptDetail.fromJson(Map<String, dynamic> json) {
    final List<TranscriptParticipant> participants =
        (json['participant'] as List<dynamic>? ??
                json['participants'] as List<dynamic>? ??
                <dynamic>[])
            .whereType<Map>()
            .map(
              (Map item) =>
                  TranscriptParticipant.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

    final List<TranscriptSpeech> speeches =
        (json['transcript'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map(
              (Map item) =>
                  TranscriptSpeech.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

    return TranscriptDetail(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString(),
      symbol: json['symbol']?.toString(),
      year: _toInt(json['year']),
      quarter: _toInt(json['quarter']),
      time: json['time']?.toString(),
      audio: json['audio']?.toString(),
      participants: participants,
      transcript: speeches,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
