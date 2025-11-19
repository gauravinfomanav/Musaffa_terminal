class Tickerformat {
  final int? found;
  final List<TickerHit>? hits;

  Tickerformat({
    this.found,
    this.hits,
  });

  factory Tickerformat.fromJson(Map<String, dynamic> json) {
    return Tickerformat(
      found: json['found'] as int?,
      hits: json['hits'] != null
          ? (json['hits'] as List)
              .map((hit) => TickerHit.fromJson(hit))
              .toList()
          : null,
    );
  }
}

class TickerHit {
  final TickerDocument? document;

  TickerHit({
    this.document,
  });

  factory TickerHit.fromJson(Map<String, dynamic> json) {
    return TickerHit(
      document: json['document'] != null
          ? TickerDocument.fromJson(json['document'])
          : null,
    );
  }
}

class TickerDocument {
  final String? ticker;
  final int? code;
  final String? id;
  final String? isin;

  TickerDocument({
    this.ticker,
    this.code,
    this.id,
    this.isin,
  });

  factory TickerDocument.fromJson(Map<String, dynamic> json) {
    return TickerDocument(
      ticker: json['ticker'] as String?,
      code: json['code'] is int ? json['code'] as int? : (json['code'] is String ? int.tryParse(json['code'] as String) : null),
      id: json['id'] is String ? json['id'] as String? : json['id']?.toString(),
      isin: json['isin'] as String?,
    );
  }
}

