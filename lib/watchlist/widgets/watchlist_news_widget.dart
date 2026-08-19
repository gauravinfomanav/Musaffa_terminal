import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
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
      for (final stock in widget.stocks) {
        try {
          await _newsController.fetchMarketNews(stock.ticker);
          final stockNews = _newsController.getTerminalNews(limit: 3);

          for (final news in stockNews) {
            _allNews.add({
              'ticker': stock.ticker,
              'summary': news['summary'],
              'datetime': news['datetime'],
            });
          }
        } catch (e) {
          // Continue with other stocks even if one fails
        }
      }

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
      final parts = dateTimeStr.split(' ');
      if (parts.length == 2) {
        final datePart = parts[0].split('/');
        final timePart = parts[1].split(':');

        if (datePart.length == 2 && timePart.length == 2) {
          final day = int.parse(datePart[0]);
          final month = int.parse(datePart[1]);
          final hour = int.parse(timePart[0]);
          final minute = int.parse(timePart[1]);
          final year = DateTime.now().year;
          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (_) {}

    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeUi.tableToolbarHeader(
          widget.isDarkMode,
          icon: Icons.newspaper_rounded,
          title: 'Watchlist News',
          subtitleText: 'Latest headlines for your holdings',
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _isLoading
              ? _buildShimmer(key: const ValueKey('news-loading'))
              : _errorMessage != null
                  ? _buildError(_errorMessage!, key: const ValueKey('news-error'))
                  : _allNews.isEmpty
                      ? _buildEmpty(key: const ValueKey('news-empty'))
                      : _buildNewsList(key: const ValueKey('news-list')),
        ),
      ],
    );
  }

  Widget _buildShimmer({required Key key}) {
    return Column(
      key: key,
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: 52,
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            baseColor: HomeUi.elevatedBg(widget.isDarkMode),
            highlightColor: HomeUi.cardBg(widget.isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error, {required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeUi.negativeSoft(widget.isDarkMode),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(
          color: HomeUi.negative(widget.isDarkMode).withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        error,
        style: HomeUi.bodyText(widget.isDarkMode).copyWith(
          color: HomeUi.negative(widget.isDarkMode),
        ),
      ),
    );
  }

  Widget _buildEmpty({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        'No news available for watchlist stocks',
        style: HomeUi.subtitle(widget.isDarkMode),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNewsList({required Key key}) {
    final items = _allNews.take(10).toList();

    return ListView.separated(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 220 + (index * 40).clamp(0, 200)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 6),
                child: child,
              ),
            );
          },
          child: _buildNewsItem(items[index]),
        );
      },
    );
  }

  Widget _buildNewsItem(Map<String, dynamic> news) {
    return _NewsTile(
      isDarkMode: widget.isDarkMode,
      ticker: news['ticker'] ?? '--',
      datetime: news['datetime'] ?? '--',
      summary: news['summary'] ?? '--',
    );
  }
}

class _NewsTile extends StatefulWidget {
  final bool isDarkMode;
  final String ticker;
  final String datetime;
  final String summary;

  const _NewsTile({
    required this.isDarkMode,
    required this.ticker,
    required this.datetime,
    required this.summary,
  });

  @override
  State<_NewsTile> createState() => _NewsTileState();
}

class _NewsTileState extends State<_NewsTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hover
              ? HomeUi.elevatedBg(widget.isDarkMode)
              : HomeUi.cardBg(widget.isDarkMode),
          borderRadius: BorderRadius.circular(HomeUi.radiusMd),
          border: Border.all(
            color: _hover
                ? HomeUi.borderStrong(widget.isDarkMode)
                : HomeUi.borderLight(widget.isDarkMode),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ticker,
                    style: HomeUi.tableCellEmphasis(widget.isDarkMode).copyWith(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.datetime,
                    style: HomeUi.subtitle(widget.isDarkMode).copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.summary,
                style: HomeUi.bodyText(widget.isDarkMode).copyWith(
                  fontSize: 12.5,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
