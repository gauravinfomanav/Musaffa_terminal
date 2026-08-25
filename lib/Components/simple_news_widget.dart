import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/models/market_news.dart';
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
        body = _buildError(controller.errorMessage.value, isDarkMode);
      } else {
        final latestNews = controller.getLatestNews(limit: 10);
        body = latestNews.isEmpty
            ? _buildEmpty(isDarkMode)
            : _buildNewsList(latestNews, isDarkMode);
      }

      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: HomeUi.cardDecoration(isDarkMode),
        child: body,
      );
    });
  }

  Widget _buildShimmer(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: List.generate(
          5,
          (int index) => Padding(
            padding: EdgeInsets.only(bottom: index == 4 ? 0 : 12),
            child: ShimmerWidgets.box(
              width: double.infinity,
              height: 88,
              borderRadius: BorderRadius.circular(12),
              baseColor: isDarkMode
                  ? const Color(0xFF2A2E34)
                  : const Color(0xFFE8EAED),
              highlightColor: isDarkMode
                  ? const Color(0xFF1A1D22)
                  : const Color(0xFFF7F8FA),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Error: $error',
        style: HomeUi.subtitle(isDarkMode).copyWith(color: HomeUi.negative(isDarkMode)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmpty(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'No news available',
        style: HomeUi.subtitle(isDarkMode),
        textAlign: TextAlign.center,
      ),
    );
  }

  static const double _newsItemHeight = 156;

  Widget _buildNewsList(List<MarketNews> newsList, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPremiumHeader(newsList.length, isDarkMode),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool twoCol = constraints.maxWidth >= 720;
              const double gap = 36;

              if (!twoCol) {
                return Column(
                  children: <Widget>[
                    for (int i = 0; i < newsList.length; i++)
                      _buildNewsItem(
                        newsList[i],
                        isDarkMode,
                        showBottomBorder: i < newsList.length - 1,
                      ),
                  ],
                );
              }

              return Column(
                children: <Widget>[
                  for (int i = 0; i < newsList.length; i += 2)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _buildNewsItem(
                            newsList[i],
                            isDarkMode,
                            showBottomBorder: i + 2 < newsList.length,
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: i + 1 < newsList.length
                              ? _buildNewsItem(
                                  newsList[i + 1],
                                  isDarkMode,
                                  showBottomBorder: i + 2 < newsList.length,
                                )
                              : SizedBox(height: _newsItemHeight),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(int itemCount, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Latest News',
                style: HomeUi.sectionTitle(isDarkMode).copyWith(
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Headlines for this ticker',
                style: HomeUi.subtitle(isDarkMode).copyWith(
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            gradient: isDarkMode ? null : HomeUi.iconWellGradient,
            color: isDarkMode ? HomeUi.elevatedBg(true) : null,
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          ),
          child: Text(
            '$itemCount Stories',
            style: HomeUi.overline(isDarkMode).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.35,
              color: HomeUi.muted(isDarkMode),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsItem(
    MarketNews news,
    bool isDarkMode, {
    bool showBottomBorder = true,
  }) {
    final String headline = (news.headline ?? '').trim().isNotEmpty
        ? _sanitizeDisplayText(news.headline!.trim())
        : '--';
    final String summary = (news.summary ?? '').trim().isNotEmpty
        ? _sanitizeDisplayText(news.summary!.trim())
        : '--';
    final String source = (news.source ?? '').trim().isNotEmpty
        ? _sanitizeDisplayText(news.source!.trim()).toUpperCase()
        : 'UNKNOWN';
    final bool hasSummary = summary != '--';

    return SizedBox(
      height: _newsItemHeight,
      child: _NewsRow(
        isDarkMode: isDarkMode,
        showBottomBorder: showBottomBorder,
        onTap: () => _openNewsUrl(news.uRL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              source,
              style: HomeUi.overline(isDarkMode).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: HomeUi.muted(isDarkMode),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              style: HomeUi.sectionTitle(isDarkMode).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.35,
                letterSpacing: -0.25,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  hasSummary ? summary : ' ',
                  style: HomeUi.subtitle(isDarkMode).copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: hasSummary
                        ? (isDarkMode
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF374151))
                        : Colors.transparent,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildTimeBelow(news.datetime, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBelow(int? timestamp, bool isDarkMode) {
    return Text(
      '${_formatDisplayTime(timestamp)}  ·  ${_formatDisplayDate(timestamp)}'
          '  ·  ${_formatRelativeLabel(timestamp)}',
      style: HomeUi.subtitle(isDarkMode).copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: HomeUi.muted(isDarkMode),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatRelativeLabel(int? timestamp) {
    if (timestamp == null) return 'Coverage';
    final date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return '${m}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return 'Coverage';
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

    if (dayDifference == 0) return 'TODAY';
    if (dayDifference == 1) return 'YESTERDAY';

    const months = <String>[
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
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _sanitizeDisplayText(String input) {
    return input
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '')
        .replaceAll(RegExp(r'[\uFFFD\u25A0-\u25FF]'), '')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
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

class _NewsRow extends StatefulWidget {
  const _NewsRow({
    required this.isDarkMode,
    required this.onTap,
    required this.child,
    this.showBottomBorder = true,
  });

  final bool isDarkMode;
  final VoidCallback onTap;
  final Widget child;
  final bool showBottomBorder;

  @override
  State<_NewsRow> createState() => _NewsRowState();
}

class _NewsRowState extends State<_NewsRow> {
  @override
  Widget build(BuildContext context) {
    final bool dark = widget.isDarkMode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(4, 14, 8, 14),
          decoration: BoxDecoration(
            border: widget.showBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: HomeUi.tableBorder(dark),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
