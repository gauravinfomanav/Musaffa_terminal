import 'dart:convert';

import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';

class TopMoverItem {
  final String symbol;
  final String name;
  final String? logo;
  final num? currentPrice;
  final num? change1DPercent;
  final String? currency;

  const TopMoverItem({
    required this.symbol,
    required this.name,
    this.logo,
    this.currentPrice,
    this.change1DPercent,
    this.currency,
  });

  TopMoverItem copyWith({
    String? name,
    String? logo,
    num? currentPrice,
    num? change1DPercent,
    String? currency,
  }) {
    return TopMoverItem(
      symbol: symbol,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      currentPrice: currentPrice ?? this.currentPrice,
      change1DPercent: change1DPercent ?? this.change1DPercent,
      currency: currency ?? this.currency,
    );
  }
}

class TopGainerLosersController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TopMoverItem> gainers = <TopMoverItem>[].obs;
  final RxList<TopMoverItem> losers = <TopMoverItem>[].obs;

  Future<void> loadGainers() async {
    await _loadMovers(isGainers: true);
  }

  Future<void> loadLosers() async {
    await _loadMovers(isGainers: false);
  }

  Future<void> _loadMovers({required bool isGainers}) async {
    isLoading.value = true;
    errorMessage.value = '';

    final String halalId = isGainers ? 'trending_gainers' : 'tranding_losers';

    final params = {
      'q': '*',
      'filter_by': 'halal_collection_id:=$halalId&&country:=US&&\$stocks_data(sharia_compliance:=COMPLIANT)',
      'sort_by': 'sort_order:asc',
      'per_page': '5',
      'include_fields': r'$stocks_data(id,change1D,change1DPercent,country,currency,currentPrice,exchange,isMainTicker,marketCapClassification,sharia_compliance,priceChange1D,priceChange1DPercent,status,usdMarketCap,volume,marketcap,musaffaSector,ranking_v2,recommendationWeightedAverage)'
    };

    try {
      final resp = await WebService.getTypesense([
        'collections', 'halal_collection_symbols_2', 'documents', 'search'
      ], params);

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        errorMessage.value = 'Request failed (${resp.statusCode})';
        isLoading.value = false;
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final hits = (data['hits'] as List?) ?? [];

      final Map<String, TopMoverItem> base = {};
      final List<String> symbols = [];

      for (final h in hits) {
        final doc = (h['document'] as Map?)?.cast<String, dynamic>() ?? {};
        Map<String, dynamic>? sd;
        final v = doc['\$stocks_data'] ?? doc['stocks_data'];
        if (v is Map) sd = v.cast<String, dynamic>();
        if (v is List && v.isNotEmpty) sd = (v.first as Map).cast<String, dynamic>();
        if (sd == null) continue;

        final String id = (sd['id'] ?? '').toString();
        if (id.isEmpty) continue;
        symbols.add(id);
        base[id] = TopMoverItem(
          symbol: id,
          name: id,
          logo: null,
          currentPrice: _toNum(sd['currentPrice']),
          change1DPercent: _toNum(sd['priceChange1DPercent'] ?? sd['change1DPercent']),
          currency: sd['currency']?.toString(),
        );
      }

      if (symbols.isNotEmpty) {
        final extra = await _fetchLogosAndNames(symbols);
        extra.forEach((sym, info) {
          final existing = base[sym];
          if (existing != null) {
            base[sym] = existing.copyWith(
              name: (info['name'] ?? '').toString(),
              logo: (info['logo'] ?? '').toString(),
            );
          }
        });
      }

      final list = base.values.toList();
      if (isGainers) {
        gainers.assignAll(list);
      } else {
        losers.assignAll(list);
      }
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  Future<Map<String, Map<String, String>>> _fetchLogosAndNames(List<String> tickers) async {
    final ids = tickers.map((e) => '`$e`').join(',');
    final filterBy = r'$company_profile_collection_new(id:*)&&id:=[' + ids + ']';

    final params2 = {
      'q': '*',
      'per_page': '200',
      'include_fields': r'$stocks_data(name,logo,cp_country,city)',
      'filter_by': filterBy,
    };

    try {
      final resp2 = await WebService.getTypesense([
        'collections', 'stocks_data', 'documents', 'search'
      ], params2);
      if (resp2.statusCode < 200 || resp2.statusCode >= 300) return {};

      final data2 = jsonDecode(resp2.body) as Map<String, dynamic>;
      final hits2 = (data2['hits'] as List?) ?? [];
      final map = <String, Map<String, String>>{};
      
      for (final h in hits2) {
        final doc = (h['document'] as Map?)?.cast<String, dynamic>() ?? {};
        
        // Try different paths for the data
        String? name;
        String? logo;
        
        // Try company_profile_collection_new first
        final cp = doc['company_profile_collection_new'] as Map<String, dynamic>?;
        if (cp != null) {
          name = cp['name']?.toString();
          logo = cp['logo']?.toString();
        }
        
        // Fallback to stocks_data
        if (name == null || logo == null) {
          Map<String, dynamic>? sd;
          final v = doc['\$stocks_data'] ?? doc['stocks_data'];
          if (v is Map) sd = v.cast<String, dynamic>();
          if (v is List && v.isNotEmpty) sd = (v.first as Map).cast<String, dynamic>();
          if (sd != null) {
            name ??= (sd['name'] ?? '').toString();
            logo ??= (sd['logo'] ?? '').toString();
          }
        }
        
        final id = (doc['id'] ?? '').toString();
        if (id.isNotEmpty && (name?.isNotEmpty == true || logo?.isNotEmpty == true)) {
          map[id] = {
            'name': name ?? '',
            'logo': logo ?? '',
          };
        }
      }
      
      return map;
    } catch (e) {
      return {};
    }
  }

  num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v.replaceAll('%', ''));
    return null;
  }
}


