import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_stock_model.dart';

class WatchlistNewsWidget extends StatefulWidget {
  final List<WatchlistStock> stocks;
  final bool isDarkMode;

  const WatchlistNewsWidget({
    Key? key,
    required this.stocks,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<WatchlistNewsWidget> createState() => _WatchlistNewsWidgetState();
}

class _WatchlistNewsWidgetState extends State<WatchlistNewsWidget> {
  final MarketNewsController _newsController = Get.put(MarketNewsController());
  final List<Map<String, dynamic>> _allNews = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllNews();
  }

  @override
  void didUpdateWidget(WatchlistNewsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh news if stocks list changed
    if (oldWidget.stocks.length != widget.stocks.length ||
        oldWidget.stocks.any((stock) => !widget.stocks.contains(stock))) {
      _fetchAllNews();
    }
  }

  Future<void> _fetchAllNews() async {
    if (widget.stocks.isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _allNews.clear();
      });
    }

    try {
      // Fetch news for each stock in the watchlist
      for (final stock in widget.stocks) {
        try {
          await _newsController.fetchMarketNews(stock.ticker);
          
          // Get terminal news for this stock
          final stockNews = _newsController.getTerminalNews(limit: 3);
          
          // Add stock ticker to each news item
          for (final news in stockNews) {
            _allNews.add({
              'ticker': stock.ticker,
              'summary': news['summary'],
              'datetime': news['datetime'],
            });
          }
        } catch (e) {
          print('Error fetching news for ${stock.ticker}: $e');
          // Continue with other stocks even if one fails
        }
      }

      // Sort all news by datetime (newest first)
      _allNews.sort((a, b) {
        final aTime = _parseDateTime(a['datetime'] ?? '');
        final bTime = _parseDateTime(b['datetime'] ?? '');
        return bTime.compareTo(aTime);
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching news: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _parseDateTime(String dateTimeStr) {
    try {
      // Parse format like "22/1 14:30"
      final parts = dateTimeStr.split(' ');
      if (parts.length == 2) {
        final datePart = parts[0].split('/');
        final timePart = parts[1].split(':');
        
        if (datePart.length == 2 && timePart.length == 2) {
          final day = int.parse(datePart[0]);
          final month = int.parse(datePart[1]);
          final hour = int.parse(timePart[0]);
          final minute = int.parse(timePart[1]);
          
          // Assume current year
          final year = DateTime.now().year;
          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (e) {
      print('Error parsing datetime: $dateTimeStr');
    }
    
    // Return current time as fallback
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmer();
    }

    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    if (_allNews.isEmpty) {
      return _buildEmpty();
    }

    return _buildNewsList();
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(8, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: 20,
            borderRadius: BorderRadius.circular(4),
            baseColor: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        'Error: $error',
        style: TextStyle(
          color: Colors.red.shade400,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        'No news available for watchlist stocks',
        style: TextStyle(
          color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNewsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'WATCHLIST NEWS',
                style: DashboardTextStyles.columnHeader.copyWith(
                  color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // News items (scrollable, limit to 10 most recent)
        SizedBox(
          height: 200, // Fixed height for news section
          child: ListView.builder(
            itemCount: _allNews.take(10).length,
            itemBuilder: (context, index) {
              return _buildNewsItem(_allNews[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewsItem(Map<String, dynamic> news) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticker and time
              Container(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news['ticker'] ?? '--',
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      news['datetime'] ?? '--',
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Summary
              Expanded(
                child: Text(
                  news['summary'] ?? '--',
                  style: DashboardTextStyles.stockName.copyWith(
                    color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                    fontSize: 11,
                    height: 1.2,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.only(left: 92), // Align with summary text (80 + 12)
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
      ],
    );
  }
}
