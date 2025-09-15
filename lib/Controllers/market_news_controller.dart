import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/market_news.dart';
import 'package:musaffa_terminal/web_service.dart';

class MarketNewsController extends GetxController {
  final RxList<MarketNews> marketNewsList = <MarketNews>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Fetch market news for a specific symbol
  Future<void> fetchMarketNews(String symbol) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('Fetching news for symbol: $symbol'); // Debug log

      final response = await WebService.getTypesense([
        'collections',
        'company_news_collection',
        'documents',
        symbol
      ]);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Handle array of news items (like the AAPL response)
        if (data.containsKey('News') && data['News'] is List) {
          final List<dynamic> newsList = data['News'];
          
          marketNewsList.value = newsList
              .map((newsData) {
                try {
                  return MarketNews.fromJson(newsData);
                } catch (e) {
                  return null;
                }
              })
              .where((news) => news != null)
              .cast<MarketNews>()
              .toList();
        }
        // Handle single document response
        else if (data.containsKey('document')) {
          final document = data['document'];
          final news = MarketNews.fromJson(document);
          marketNewsList.value = [news];
        }
        // Handle direct document response
        else {
          final news = MarketNews.fromJson(data);
          marketNewsList.value = [news];
        }
      } else {
        errorMessage.value = 'Failed to fetch market news: ${response.statusCode} - ${response.body}';
        marketNewsList.clear();
        print('API Error: ${response.statusCode} - ${response.body}'); // Debug log
      }
    } catch (e) {
      errorMessage.value = 'Error fetching market news: $e';
      marketNewsList.clear();
      print('Exception: $e'); // Debug log
    } finally {
      isLoading.value = false;
    }
  }


  /// Clear the news list
  void clearNews() {
    marketNewsList.clear();
    errorMessage.value = '';
  }


  /// Get news by category
  List<MarketNews> getNewsByCategory(String category) {
    return marketNewsList.where((news) => news.category == category).toList();
  }

  /// Get news by source
  List<MarketNews> getNewsBySource(String source) {
    return marketNewsList.where((news) => news.source == source).toList();
  }

  /// Get latest news (sorted by datetime)
  List<MarketNews> getLatestNews({int limit = 10}) {
    final sortedNews = List<MarketNews>.from(marketNewsList);
    sortedNews.sort((a, b) => (b.datetime ?? 0).compareTo(a.datetime ?? 0));
    return sortedNews.take(limit).toList();
  }

  /// Get news formatted for terminal display (just summary with datetime)
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

  /// Clean text by removing weird Unicode characters and normalizing
  String _cleanText(String text) {
    if (text.isEmpty) return '--';
    
    // Remove weird Unicode control characters and normalize
    return text
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '') // Remove control characters
        .replaceAll(RegExp(r'\u0019'), '') // Remove specific problematic character
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim(); // Remove leading/trailing whitespace
  }

  /// Format datetime for terminal display
  String _formatDateTime(int? timestamp) {
    if (timestamp == null) return '--';
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

}
