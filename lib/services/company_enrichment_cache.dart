import 'dart:convert';

import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/web_service.dart';

class CompanyEnrichment {
  const CompanyEnrichment({
    this.name,
    this.logo,
    this.sector,
    this.marketCap,
    this.currentPrice,
    this.aum,
    this.isEtf,
  });

  final String? name;
  final String? logo;
  final String? sector;
  /// stocks_data usdMarketCap — millions of USD
  final num? marketCap;
  final num? currentPrice;
  /// etfs_data aum — absolute USD
  final num? aum;
  final bool? isEtf;

  bool get isEtfAsset => isEtf == true;
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
        await _fetchStockChunk(chunk);
        _pending.removeAll(chunk);
      }
    } finally {
      _pending.removeAll(missing);
    }
  }

  /// Routes symbols to stock vs ETF Typesense collections (etfs_data for ETFs).
  static Future<void> ensureForHoldings(
    Iterable<dynamic> holdings,
  ) async {
    final List<String> stockSymbols = <String>[];
    final List<String> etfSymbols = <String>[];

    for (final dynamic holding in holdings) {
      final String symbol = _holdingTicker(holding).trim().toUpperCase();
      if (symbol.isEmpty || _cache.containsKey(symbol)) continue;
      if (_isEtfHolding(holding)) {
        etfSymbols.add(symbol);
      } else {
        stockSymbols.add(symbol);
      }
    }

    await _fetchInChunks(stockSymbols, _fetchStockChunk);
    await _fetchInChunks(etfSymbols, _fetchEtfChunk);

    // If a symbol was misclassified as stock, retry via etfs_data.
    final List<String> retryAsEtf = stockSymbols
        .where((String symbol) {
          final CompanyEnrichment? cached = _cache[symbol];
          return cached != null && !cached.isEtfAsset && _isSparseEnrichment(cached);
        })
        .toList();
    if (retryAsEtf.isNotEmpty) {
      await _fetchInChunks(retryAsEtf, _fetchEtfChunk);
    }
  }

  static Future<void> _fetchInChunks(
    List<String> symbols,
    Future<void> Function(List<String>) fetcher,
  ) async {
    if (symbols.isEmpty) return;
    _pending.addAll(symbols);
    try {
      const int chunkSize = 40;
      for (int i = 0; i < symbols.length; i += chunkSize) {
        final List<String> chunk = symbols.sublist(
          i,
          i + chunkSize > symbols.length ? symbols.length : i + chunkSize,
        );
        await fetcher(chunk);
        _pending.removeAll(chunk);
      }
    } finally {
      _pending.removeAll(symbols);
    }
  }

  static String _holdingTicker(dynamic holding) {
    try {
      return (holding.ticker as String?) ?? '';
    } catch (_) {
      return holding.toString();
    }
  }

  static bool _isEtfHolding(dynamic holding) {
    try {
      if (holding.assetType?.name == 'etf') return true;
    } catch (_) {}

    try {
      if (holding.tickerModel?.isStock == false) return true;
    } catch (_) {}

    return false;
  }

  static bool _isSparseEnrichment(CompanyEnrichment enrichment) {
    return enrichment.currentPrice == null &&
        enrichment.sector == null &&
        enrichment.marketCap == null &&
        enrichment.aum == null;
  }

  static Future<void> _fetchStockChunk(List<String> symbols) async {
    final String ids = symbols.map((String id) => '`$id`').join(',');
    final Map<String, String?> names = <String, String?>{};
    final Map<String, String?> logos = <String, String?>{};
    final Map<String, String?> sectors = <String, String?>{};
    final Map<String, num?> caps = <String, num?>{};
    final Map<String, num?> prices = <String, num?>{};

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
              'id,name,logo,sector,musaffaSector,usdMarketCap,marketCap,marketcap,currentPrice,current_price,close',
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
          sectors.putIfAbsent(
            id,
            () =>
                _nonEmpty(doc['sector']?.toString()) ??
                _nonEmpty(doc['musaffaSector']?.toString()),
          );
          caps[id] = _toNum(doc['usdMarketCap']) ??
              _toNum(doc['marketCap']) ??
              _toNum(doc['marketcap']);
          prices.putIfAbsent(
            id,
            () =>
                _toNum(doc['currentPrice']) ??
                _toNum(doc['current_price']) ??
                _toNum(doc['close']),
          );
        }
      }
    } catch (_) {}

    for (final String symbol in symbols) {
      _cache[symbol] = CompanyEnrichment(
        name: names[symbol],
        logo: logos[symbol],
        sector: sectors[symbol],
        marketCap: caps[symbol],
        currentPrice: prices[symbol],
        isEtf: false,
      );
    }
  }

  static Future<void> _fetchEtfChunk(List<String> symbols) async {
    final String ids = symbols.map((String id) => '`$id`').join(',');
    final Map<String, String?> names = <String, String?>{};
    final Map<String, String?> logos = <String, String?>{};
    final Map<String, String?> sectors = <String, String?>{};
    final Map<String, num?> prices = <String, num?>{};
    final Map<String, num?> aums = <String, num?>{};

    // ETF profile — name + logo (same source as search)
    try {
      final profileResponse = await WebService.getTypesense(
        <String>[
          'collections',
          FirestoreConstants.ETF_PROFILE_COLLECTION,
          'documents',
          'search',
        ],
        <String, dynamic>{
          'q': '*',
          'per_page': '${symbols.length}',
          'filter_by': 'id:=[$ids]',
          'include_fields': 'id,name,logo,symbol',
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
          final String id = (doc['id'] ?? doc['symbol'] ?? '')
              .toString()
              .toUpperCase();
          if (id.isEmpty) continue;
          names[id] = _nonEmpty(doc['name']?.toString());
          logos[id] = _nonEmpty(doc['logo']?.toString());
        }
      }
    } catch (_) {}

    // etfs_data — price, AUM, segment (same source as EtfDetailsController)
    try {
      final etfResponse = await WebService.getTypesense(
        <String>[
          'collections',
          'etfs_data',
          'documents',
          'search',
        ],
        <String, dynamic>{
          'q': '*',
          'per_page': '${symbols.length}',
          'include_fields':
              'id,symbol,currentPrice,close,nav,aum,investmentSegment,assetClass,sector_exposure,\$etf_profile_collection_4(name,symbol,logo)',
          'filter_by': '\$etf_profile_collection_4(id:*)&&id:=[$ids]',
        },
      );

      if (etfResponse.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(etfResponse.body) as Map<String, dynamic>;
        final List<dynamic> hits =
            body['hits'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic hit in hits) {
          if (hit is! Map<String, dynamic>) continue;
          final Map<String, dynamic>? doc =
              hit['document'] as Map<String, dynamic>?;
          if (doc == null) continue;
          final String id = (doc['id'] ?? doc['symbol'] ?? '')
              .toString()
              .toUpperCase();
          if (id.isEmpty) continue;

          final dynamic profileRaw = doc['etf_profile_collection_4'] ??
              doc['\$etf_profile_collection_4'];
          if (profileRaw is Map<String, dynamic>) {
            names.putIfAbsent(
              id,
              () => _nonEmpty(profileRaw['name']?.toString()),
            );
            logos.putIfAbsent(
              id,
              () => _nonEmpty(profileRaw['logo']?.toString()),
            );
          }

          prices[id] = _toNum(doc['currentPrice']) ??
              _toNum(doc['close']) ??
              _toNum(doc['nav']);
          aums[id] = _toNum(doc['aum']);
          sectors[id] = _etfSectorLabel(doc);
        }
      }
    } catch (_) {}

    for (final String symbol in symbols) {
      _cache[symbol] = CompanyEnrichment(
        name: names[symbol],
        logo: logos[symbol],
        sector: sectors[symbol],
        currentPrice: prices[symbol],
        aum: aums[symbol],
        isEtf: true,
      );
    }
  }

  static String? _etfSectorLabel(Map<String, dynamic> doc) {
    final String? segment = _nonEmpty(doc['investmentSegment']?.toString());
    if (segment != null) return segment;

    final String? assetClass = _nonEmpty(doc['assetClass']?.toString());
    if (assetClass != null) return assetClass;

    return _topSectorFromExposure(
      doc['sector_exposure'] is Map
          ? Map<String, dynamic>.from(doc['sector_exposure'] as Map)
          : null,
    );
  }

  static String? _topSectorFromExposure(Map<String, dynamic>? exposure) {
    if (exposure == null || exposure.isEmpty) return null;

    String? topKey;
    num topValue = -1;
    exposure.forEach((String key, dynamic value) {
      if (value is num && value > topValue) {
        topValue = value;
        topKey = key;
      }
    });
    return _nonEmpty(topKey);
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
