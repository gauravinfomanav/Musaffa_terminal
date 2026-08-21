import 'dart:convert';

import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/web_service.dart';

class CompanyEnrichment {
  const CompanyEnrichment({
    this.name,
    this.logo,
    this.marketCap,
  });

  final String? name;
  final String? logo;
  final num? marketCap; // stocks_data usdMarketCap — millions of USD
}

/// Cached Typesense lookups for company name / logo / market cap by symbol.
class CompanyEnrichmentCache {
  CompanyEnrichmentCache._();

  static final Map<String, CompanyEnrichment> _cache =
      <String, CompanyEnrichment>{};
  static final Set<String> _pending = <String>{};

  static CompanyEnrichment? getCached(String symbol) =>
      _cache[symbol.trim().toUpperCase()];

  static bool isPending(String symbol) =>
      _pending.contains(symbol.trim().toUpperCase());

  static bool hasCached(String symbol) =>
      _cache.containsKey(symbol.trim().toUpperCase());

  static Future<void> ensureSymbols(Iterable<String> symbols) async {
    final List<String> missing = symbols
        .map((String s) => s.trim().toUpperCase())
        .where((String s) => s.isNotEmpty && !_cache.containsKey(s))
        .toSet()
        .toList();
    if (missing.isEmpty) return;

    _pending.addAll(missing);
    try {
      const int chunkSize = 40;
      for (int i = 0; i < missing.length; i += chunkSize) {
        final List<String> chunk = missing.sublist(
          i,
          i + chunkSize > missing.length ? missing.length : i + chunkSize,
        );
        await _fetchChunk(chunk);
        _pending.removeAll(chunk);
      }
    } finally {
      _pending.removeAll(missing);
    }
  }

  static Future<void> _fetchChunk(List<String> symbols) async {
    final String ids = symbols.map((String id) => '`$id`').join(',');
    final Map<String, String?> names = <String, String?>{};
    final Map<String, String?> logos = <String, String?>{};
    final Map<String, num?> caps = <String, num?>{};

    // 1) Company profile collection — name + logo (same source as watchlist/ideas)
    try {
      final profileResponse = await WebService.getTypesense(
        <String>[
          'collections',
          FirestoreConstants.COMPANY_PROFILE_COLLECTION,
          'documents',
          'search',
        ],
        <String, dynamic>{
          'q': '*',
          'per_page': '${symbols.length}',
          'filter_by': 'id:=[$ids]',
          'include_fields': 'id,name,logo',
        },
      );

      if (profileResponse.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(profileResponse.body) as Map<String, dynamic>;
        final List<dynamic> hits =
            body['hits'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic hit in hits) {
          if (hit is! Map<String, dynamic>) continue;
          final Map<String, dynamic>? doc =
              hit['document'] as Map<String, dynamic>?;
          if (doc == null) continue;
          final String id = (doc['id'] ?? '').toString().toUpperCase();
          if (id.isEmpty) continue;
          names[id] = _nonEmpty(doc['name']?.toString());
          logos[id] = _nonEmpty(doc['logo']?.toString());
        }
      }
    } catch (_) {}

    // 2) stocks_data — market cap + logo/name fallback
    try {
      final stockResponse = await WebService.getTypesense(
        <String>[
          'collections',
          'stocks_data',
          'documents',
          'search',
        ],
        <String, dynamic>{
          'q': '*',
          'per_page': '${symbols.length}',
          'filter_by': 'id:=[$ids]',
          'include_fields':
              'id,name,logo,usdMarketCap,marketCap,marketcap',
        },
      );

      if (stockResponse.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(stockResponse.body) as Map<String, dynamic>;
        final List<dynamic> hits =
            body['hits'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic hit in hits) {
          if (hit is! Map<String, dynamic>) continue;
          final Map<String, dynamic>? doc =
              hit['document'] as Map<String, dynamic>?;
          if (doc == null) continue;
          final String id = (doc['id'] ?? '').toString().toUpperCase();
          if (id.isEmpty) continue;

          names.putIfAbsent(id, () => _nonEmpty(doc['name']?.toString()));
          logos.putIfAbsent(id, () => _nonEmpty(doc['logo']?.toString()));
          caps[id] = _toNum(doc['usdMarketCap']) ??
              _toNum(doc['marketCap']) ??
              _toNum(doc['marketcap']);
        }
      }
    } catch (_) {}

    for (final String symbol in symbols) {
      _cache[symbol] = CompanyEnrichment(
        name: names[symbol],
        logo: logos[symbol],
        marketCap: caps[symbol],
      );
    }
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }
}
