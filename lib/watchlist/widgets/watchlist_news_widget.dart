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
        const SizedBox(height: 16),
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
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: 64,
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
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(widget.isDarkMode),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(widget.isDarkMode)),
      ),
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
    final dark = widget.isDarkMode;

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: HomeUi.cardBg(dark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(dark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: HomeUi.borderLight(dark).withValues(alpha: 0.85),
              ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200 + (i * 35).clamp(0, 180)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 4),
                    child: child,
                  ),
                );
              },
              child: _NewsTile(
                isDarkMode: dark,
                ticker: items[i]['ticker'] ?? '--',
                datetime: items[i]['datetime'] ?? '--',
                summary: items[i]['summary'] ?? '--',
              ),
            ),
          ],
        ],
      ),
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
    final dark = widget.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        // Soft tint only — never a flat grey block fill.
        color: _hover
            ? (dark
                ? const Color(0xFF181B20)
                : const Color(0xFFFAFBFC))
            : HomeUi.cardBg(dark),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1F2329)
                        : const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                    border: Border.all(
                      color: HomeUi.borderLight(dark),
                    ),
                  ),
                  child: Text(
                    widget.ticker,
                    style: HomeUi.tableCellEmphasis(dark).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.datetime,
                  style: HomeUi.subtitle(dark).copyWith(
                    fontSize: 11.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.summary,
              style: HomeUi.bodyText(dark).copyWith(
                fontSize: 13,
                height: 1.45,
                letterSpacing: -0.1,
                color: HomeUi.title(dark).withValues(alpha: 0.88),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
