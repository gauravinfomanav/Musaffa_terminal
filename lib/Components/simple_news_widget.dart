import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/models/market_news.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SimpleNewsWidget extends StatefulWidget {
  final String symbol;

  const SimpleNewsWidget({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  State<SimpleNewsWidget> createState() => _SimpleNewsWidgetState();
}

class _SimpleNewsWidgetState extends State<SimpleNewsWidget> {
  final MarketNewsController controller = Get.put(MarketNewsController());
  String? _lastFetchedSymbol;

  @override
  void initState() {
    super.initState();
    _fetchNewsIfNeeded();
  }

  @override
  void didUpdateWidget(SimpleNewsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _fetchNewsIfNeeded();
    }
  }

  void _fetchNewsIfNeeded() {
    if (_lastFetchedSymbol != widget.symbol) {
      _lastFetchedSymbol = widget.symbol;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.fetchMarketNews(widget.symbol);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildShimmer(isDarkMode);
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildError(controller.errorMessage.value);
      }

      final latestNews = controller.getLatestNews(limit: 10);
      
      if (latestNews.isEmpty) {
        return _buildEmpty();
      }

      return _buildNewsList(latestNews, isDarkMode);
    });
  }

  Widget _buildShimmer(bool isDarkMode) {
    return Column(
      children: List.generate(10, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: 30,
            borderRadius: BorderRadius.circular(4),
            baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
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
        style: const TextStyle(color: Colors.red, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: const Text(
        'No news available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNewsList(List<MarketNews> newsList, bool isDarkMode) {
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
                  color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Latest News',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // News items
        ...newsList.map((news) => _buildNewsItem(news, isDarkMode)).toList(),
      ],
    );
  }

  Widget _buildNewsItem(MarketNews news, bool isDarkMode) {
    final headline = (news.headline ?? '').trim().isNotEmpty
      ? _sanitizeDisplayText(news.headline!.trim())
        : '--';
    final summary = (news.summary ?? '').trim().isNotEmpty
      ? _sanitizeDisplayText(news.summary!.trim())
        : '--';
    final source = (news.source ?? '').trim().isNotEmpty
      ? _sanitizeDisplayText(news.source!.trim()).toUpperCase()
        : 'UNKNOWN';

    return Column(
      children: [
        InkWell(
          onTap: () async {
            
            await _openNewsUrl(news.uRL);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                SizedBox(
                  width: 82,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDisplayTime(news.datetime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDisplayDate(news.datetime),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              source,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          // if (category.isNotEmpty) ...[
                          //   const SizedBox(width: 8),
                          //   Text(
                          //     category,
                          //     style: TextStyle(
                          //       fontSize: 11,
                          //       fontWeight: FontWeight.w600,
                          //       color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          //       fontFamily: Constants.FONT_DEFAULT_NEW,
                          //       letterSpacing: 0.4,
                          //     ),
                          //     maxLines: 1,
                          //     overflow: TextOverflow.ellipsis,
                          //   ),
                          // ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        headline,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.only(left: 94),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
      ],
    );
  }

  String _formatDisplayTime(int? timestamp) {
    if (timestamp == null) return '--';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDisplayDate(int? timestamp) {
    if (timestamp == null) return '--';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final dayDifference = todayOnly.difference(dateOnly).inDays;

    if (dayDifference == 0) {
      return 'TODAY';
    }

    if (dayDifference == 1) {
      return 'YESTERDAY';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _sanitizeDisplayText(String input) {
    return input
        // Remove control chars.
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '')
        // Remove replacement/tofu square-style artifacts.
        .replaceAll(RegExp(r'[\uFFFD\u25A0-\u25FF]'), '')
        // Normalize smart punctuation to plain ASCII.
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        // Collapse extra whitespace.
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _openNewsUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL available for this news item')),
      );
      return;
    }

    var url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid news URL')),
      );
      return;
    }

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        launched = false;
      }
    }

    if (!launched) {
      try {
        launched = await launchUrlString(url);
      } catch (_) {
        launched = false;
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link')),
      );
    }
  }
}
