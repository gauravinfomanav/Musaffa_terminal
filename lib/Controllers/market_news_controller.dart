import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/market_news.dart';
import 'package:musaffa_terminal/web_service.dart';

class MarketNewsController extends GetxController {
  final RxList<MarketNews> marketNewsList = <MarketNews>[].obs;
  final RxList<MarketNews> latestMarketNewsList = <MarketNews>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingLatest = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString latestErrorMessage = ''.obs;

  static const List<String> _marketNewsSymbols = [
    'SPY',
    'QQQ',
    'AAPL',
    'MSFT',
    'NVDA',
    'TSLA',
    'AMZN',
    'META',
  ];

  List<MarketNews> _parseNewsResponseBody(String body) {
    final Map<String, dynamic> data = json.decode(body);

    if (data.containsKey('News') && data['News'] is List) {
      return (data['News'] as List)
          .map((newsData) {
            try {
              return MarketNews.fromJson(
                Map<String, dynamic>.from(newsData as Map),
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<MarketNews>()
          .toList();
    }

    if (data.containsKey('document')) {
      return [MarketNews.fromJson(Map<String, dynamic>.from(data['document']))];
    }

    try {
      return [MarketNews.fromJson(data)];
    } catch (_) {
      return [];
    }
  }

  /// Aggregated latest market news for the dashboard panel.
  Future<void> fetchLatestMarketNews({int limit = 20}) async {
    if (isLoadingLatest.value) return;

    isLoadingLatest.value = true;
    latestErrorMessage.value = '';

    try {
      final aggregated = <MarketNews>[];
      final seen = <String>{};

      for (final symbol in _marketNewsSymbols) {
        try {
          final response = await WebService.getTypesense([
            'collections',
            'company_news_collection',
            'documents',
            symbol,
          ]);

          if (response.statusCode != 200) continue;

          for (final news in _parseNewsResponseBody(response.body)) {
            final key = '${news.uRL ?? ''}|${news.headline ?? ''}';
            if (key == '|' || seen.contains(key)) continue;
            seen.add(key);
            aggregated.add(news);
          }
        } catch (_) {
          continue;
        }
      }

      aggregated.sort((a, b) => (b.datetime ?? 0).compareTo(a.datetime ?? 0));
      latestMarketNewsList.value = aggregated.take(limit).toList();
    } catch (e) {
      latestErrorMessage.value = 'Error fetching market news: $e';
      latestMarketNewsList.clear();
    } finally {
      isLoadingLatest.value = false;
    }
  }

  /// Fetch market news for a specific symbol
  Future<void> fetchMarketNews(String symbol) async {
    try {
      if (isLoading.value) return;

      isLoading.value = true;
      errorMessage.value = '';

      final response = await WebService.getTypesense([
        'collections',
        'company_news_collection',
        'documents',
        symbol,
      ]);

      if (response.statusCode == 200) {
        marketNewsList.value = _parseNewsResponseBody(response.body);
      } else {
        errorMessage.value =
            'Failed to fetch market news: ${response.statusCode} - ${response.body}';
        marketNewsList.clear();
      }
    } catch (e) {
      errorMessage.value = 'Error fetching market news: $e';
      marketNewsList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void clearNews() {
    marketNewsList.clear();
    errorMessage.value = '';
  }

  List<MarketNews> getNewsByCategory(String category) {
    return marketNewsList.where((news) => news.category == category).toList();
  }

  List<MarketNews> getNewsBySource(String source) {
    return marketNewsList.where((news) => news.source == source).toList();
  }

  List<MarketNews> getLatestNews({int limit = 10}) {
    final sortedNews = List<MarketNews>.from(marketNewsList);
    sortedNews.sort((a, b) => (b.datetime ?? 0).compareTo(a.datetime ?? 0));
    return sortedNews.take(limit).toList();
  }

  List<Map<String, String>> getTerminalNews({int limit = 5}) {
    final latestNews = getLatestNews(limit: limit);

    return latestNews.map((news) {
      final summary = _cleanText(news.summary ?? '--');
      final datetime = _formatDateTime(news.datetime);
      return {
        'summary': summary,
        'datetime': datetime,
      };
    }).toList();
  }

  String _cleanText(String text) {
    if (text.isEmpty) return '--';

    return text
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '')
        .replaceAll(RegExp(r'\u0019'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formatDateTime(int? timestamp) {
    if (timestamp == null) return '--';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Relative time for dashboard cards, e.g. "2m ago".
  String formatRelativeTime(int? timestamp) {
    if (timestamp == null) return '--';

    final date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
