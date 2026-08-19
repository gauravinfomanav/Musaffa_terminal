import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/models/market_news.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
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
      Widget body;
      if (controller.isLoading.value) {
        body = _buildShimmer(isDarkMode);
      } else if (controller.errorMessage.value.isNotEmpty) {
        body = _buildError(controller.errorMessage.value);
      } else {
        final latestNews = controller.getLatestNews(limit: 10);
        body = latestNews.isEmpty
            ? _buildEmpty()
            : _buildNewsList(latestNews, isDarkMode);
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: HomeUi.cardDecoration(isDarkMode),
        child: body,
      );
    });
  }

  Widget _buildShimmer(bool isDarkMode) {
    return Column(
      children: List.generate(
        6,
        (int index) => Padding(
          padding: EdgeInsets.only(bottom: index == 5 ? 0 : 10),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: 116,
            borderRadius: BorderRadius.circular(16),
            baseColor:
                isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor:
                isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
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
      children: <Widget>[
        HomeUi.tableToolbarHeader(
          isDarkMode,
          icon: Icons.newspaper_outlined,
          title: 'Latest News',
          subtitleText: 'Headlines for this ticker',
        ),
        const SizedBox(height: 14),
        ...newsList.asMap().entries.map((MapEntry<int, MarketNews> entry) {
          final bool isLast = entry.key == newsList.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: _buildNewsItem(entry.value, isDarkMode),
          );
        }),
      ],
    );
  }

  Widget _buildNewsItem(MarketNews news, bool isDarkMode) {
    final String headline = (news.headline ?? '').trim().isNotEmpty
        ? _sanitizeDisplayText(news.headline!.trim())
        : '--';
    final String summary = (news.summary ?? '').trim().isNotEmpty
        ? _sanitizeDisplayText(news.summary!.trim())
        : '--';
    final String source = (news.source ?? '').trim().isNotEmpty
        ? _sanitizeDisplayText(news.source!.trim()).toUpperCase()
        : 'UNKNOWN';

    return _NewsCard(
      isDarkMode: isDarkMode,
      onTap: () => _openNewsUrl(news.uRL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTimeColumn(news.datetime, isDarkMode),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _buildSourceBadge(source, isDarkMode),
                    const Spacer(),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: isDarkMode
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFFF9FAFB)
                        : const Color(0xFF111827),
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF64748B),
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(int? timestamp, bool isDarkMode) {
    return Container(
      width: 78,
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            _formatDisplayTime(timestamp),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF334155),
              fontWeight: FontWeight.w700,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDisplayDate(timestamp),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String source, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        source,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
          fontFamily: Constants.FONT_DEFAULT_NEW,
          letterSpacing: 0.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDisplayTime(int? timestamp) {
    if (timestamp == null) return '--';

    final date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDisplayDate(int? timestamp) {
    if (timestamp == null) return '--';

    final date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
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

class _NewsCard extends StatefulWidget {
  const _NewsCard({
    required this.isDarkMode,
    required this.onTap,
    required this.child,
  });

  final bool isDarkMode;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.isDarkMode;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 116,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: _hover
                ? (dark ? const Color(0xFF111827) : const Color(0xFFF8FAFC))
                : (dark ? const Color(0xFF0F172A) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover
                  ? (dark ? const Color(0xFF374151) : const Color(0xFFCBD5E1))
                  : (dark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: _hover ? 0.22 : 0.12)
                    : const Color(0xFF0F172A)
                        .withValues(alpha: _hover ? 0.08 : 0.04),
                blurRadius: _hover ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
