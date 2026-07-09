import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class RevenueBreakdownService {
  RevenueBreakdownService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<RevenueBreakdownModel?> fetchLatestForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final dynamic decoded = await _client.get(
      'stock/revenue-breakdown',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/revenue-breakdown:$normalized',
    );

    final _ParsedRevenue? parsed = _parse(decoded);
    if (parsed == null || parsed.items.isEmpty) return null;

    final num total =
        parsed.items.fold<num>(0, (num sum, RevenueBreakdownItem e) => sum + e.revenue);
    if (total <= 0) return null;

    final List<RevenueBreakdownItem> withShare = parsed.items
        .map((RevenueBreakdownItem item) => RevenueBreakdownItem(
              region: item.region,
              revenue: item.revenue,
              percentage: (item.revenue / total) * 100,
            ))
        .toList()
      ..sort((RevenueBreakdownItem a, RevenueBreakdownItem b) =>
          b.revenue.compareTo(a.revenue));

    return RevenueBreakdownModel(
      period: parsed.period,
      items: withShare,
    );
  }

  _ParsedRevenue? _parse(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;

    // Shape A: {"symbol":"AAPL","cik":"...","data":[{"period":"2024-09-28","Americas":...}]}
    final dynamic data = decoded['data'];
    if (data is List && data.isNotEmpty) {
      final Map<String, dynamic>? latest = data
          .whereType<Map>()
          .map((Map e) => Map<String, dynamic>.from(e))
          .toList()
          .cast<Map<String, dynamic>>()
          .fold<Map<String, dynamic>?>(null, (Map<String, dynamic>? acc, Map<String, dynamic> cur) {
        if (acc == null) return cur;
        final String p1 = (acc['period'] ?? acc['date'] ?? '').toString();
        final String p2 = (cur['period'] ?? cur['date'] ?? '').toString();
        return p2.compareTo(p1) > 0 ? cur : acc;
      });

      if (latest != null) {
        return _fromMap(latest);
      }
    }

    // Shape B: {"series":{"2023-12-31":{"Americas":...}}}
    final dynamic series = decoded['series'];
    if (series is Map) {
      final Map<String, dynamic> mapped = Map<String, dynamic>.from(series);
      if (mapped.isNotEmpty) {
        final List<String> periods = mapped.keys.map((dynamic e) => e.toString()).toList()
          ..sort();
        final String period = periods.last;
        final dynamic bucket = mapped[period];
        if (bucket is Map) {
          return _fromMap(<String, dynamic>{'period': period, ...Map<String, dynamic>.from(bucket)});
        }
      }
    }

    return null;
  }

  _ParsedRevenue? _fromMap(Map<String, dynamic> map) {
    final String period = (map['period'] ?? map['date'] ?? '--').toString();
    final List<RevenueBreakdownItem> items = <RevenueBreakdownItem>[];
    for (final MapEntry<String, dynamic> entry in map.entries) {
      final String key = entry.key;
      if (key == 'period' ||
          key == 'date' ||
          key == 'symbol' ||
          key == 'ticker' ||
          key == 'currency') {
        continue;
      }
      final num? value = _num(entry.value);
      if (value == null || value <= 0) continue;
      items.add(RevenueBreakdownItem(region: key, revenue: value));
    }
    if (items.isEmpty) return null;
    return _ParsedRevenue(period: period, items: items);
  }

  num? _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}

class _ParsedRevenue {
  const _ParsedRevenue({required this.period, required this.items});

  final String period;
  final List<RevenueBreakdownItem> items;
}
