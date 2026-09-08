import 'package:musaffa_terminal/models/company_news_item.dart';
import 'package:musaffa_terminal/services/finnhub/earnings_calendar_service.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class CompanyNewsService {
  CompanyNewsService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  static const int maxItems = 60;

  Future<List<CompanyNewsItem>> fetchForSymbol(
    String symbol, {
    int days = 7,
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return <CompanyNewsItem>[];

    final DateTime today = FinnhubDateFormat.localDateOnly();
    final DateTime from = today.subtract(Duration(days: days));
    final String fromStr = FinnhubDateFormat.format(from);
    final String toStr = FinnhubDateFormat.format(today);

    final dynamic decoded = await _client.get(
      'company-news',
      queryParameters: <String, String>{
        'symbol': normalized,
        'from': fromStr,
        'to': toStr,
      },
      cacheKey: 'company-news:$normalized:$fromStr:$toStr',
      forceRefresh: forceRefresh,
    );

    final List<CompanyNewsItem> items = <CompanyNewsItem>[];
    final Set<String> seen = <String>{};

    for (final dynamic raw in _extractList(decoded)) {
      if (raw is! Map) continue;
      final CompanyNewsItem item =
          CompanyNewsItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.headline.isEmpty) continue;

      final String key = item.url.isNotEmpty
          ? item.url
          : '${item.headline}|${item.datetime}';
      if (!seen.add(key)) continue;
      items.add(item);
    }

    items.sort(
      (CompanyNewsItem a, CompanyNewsItem b) => b.datetime.compareTo(a.datetime),
    );
    if (items.length <= maxItems) return items;
    return items.sublist(0, maxItems);
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final String key in <String>['news', 'data', 'result']) {
        final dynamic value = decoded[key];
        if (value is List<dynamic>) return value;
      }
      for (final dynamic value in decoded.values) {
        if (value is List<dynamic>) return value;
      }
    }
    return <dynamic>[];
  }
}
