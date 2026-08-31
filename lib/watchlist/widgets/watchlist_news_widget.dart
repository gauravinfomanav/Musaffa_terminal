import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
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
  static const double _columnGap = 24;

  final MarketNewsController _newsController = Get.put(MarketNewsController());
  final List<Map<String, dynamic>> _allNews = <Map<String, dynamic>>[];
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
        oldWidget.stocks.any((WatchlistStock stock) => !widget.stocks.contains(stock))) {
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
      for (final WatchlistStock stock in widget.stocks) {
        try {
          await _newsController.fetchMarketNews(stock.ticker);
          final List<Map<String, dynamic>> stockNews =
              _newsController.getTerminalNews(limit: 3);

          for (final Map<String, dynamic> news in stockNews) {
            _allNews.add(<String, dynamic>{
              'ticker': stock.ticker,
              'summary': news['summary'],
              'datetime': news['datetime'],
            });
          }
        } catch (_) {
          // Continue with other stocks even if one fails.
        }
      }

      _allNews.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final DateTime aTime = _parseDateTime(a['datetime'] ?? '');
        final DateTime bTime = _parseDateTime(b['datetime'] ?? '');
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
      final List<String> parts = dateTimeStr.split(' ');
      if (parts.length == 2) {
        final List<String> datePart = parts[0].split('/');
        final List<String> timePart = parts[1].split(':');

        if (datePart.length == 2 && timePart.length == 2) {
          final int day = int.parse(datePart[0]);
          final int month = int.parse(datePart[1]);
          final int hour = int.parse(timePart[0]);
          final int minute = int.parse(timePart[1]);
          final int year = DateTime.now().year;
          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (_) {}

    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.isDarkMode;
    final int visibleCount = _allNews.length.clamp(0, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Watchlist News', style: HomeUi.sectionTitle(dark)),
                  const SizedBox(height: 3),
                  Text(
                    'Latest headlines for your holdings',
                    style: HomeUi.subtitle(dark).copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (!_isLoading && _errorMessage == null && visibleCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HomeUi.elevatedBg(dark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                  border: Border.all(color: HomeUi.borderLight(dark)),
                ),
                child: Text(
                  '$visibleCount',
                  style: HomeUi.control(dark).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _isLoading
              ? _buildShimmer(key: const ValueKey<String>('news-loading'))
              : _errorMessage != null
                  ? _buildError(_errorMessage!, key: const ValueKey<String>('news-error'))
                  : _allNews.isEmpty
                      ? _buildEmpty(key: const ValueKey<String>('news-empty'))
                      : _buildNewsList(key: const ValueKey<String>('news-list')),
        ),
      ],
    );
  }

  Widget _buildShimmer({required Key key}) {
    return Column(
      key: key,
      children: List<Widget>.generate(2, (int row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row == 1 ? 0 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ShimmerWidgets.box(
                  width: double.infinity,
                  height: 88,
                  borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                  baseColor: HomeUi.elevatedBg(widget.isDarkMode),
                  highlightColor: HomeUi.cardBg(widget.isDarkMode),
                ),
              ),
              const SizedBox(width: _columnGap),
              Expanded(
                child: ShimmerWidgets.box(
                  width: double.infinity,
                  height: 88,
                  borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                  baseColor: HomeUi.elevatedBg(widget.isDarkMode),
                  highlightColor: HomeUi.cardBg(widget.isDarkMode),
                ),
              ),
            ],
          ),
        );
      }),
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
          color: HomeUi.negative(widget.isDarkMode).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: HomeUi.negative(widget.isDarkMode),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: HomeUi.bodyText(widget.isDarkMode).copyWith(
                color: HomeUi.negative(widget.isDarkMode),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(widget.isDarkMode),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(widget.isDarkMode)),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.article_outlined,
            size: 22,
            color: HomeUi.muted(widget.isDarkMode),
          ),
          const SizedBox(height: 10),
          Text(
            'No headlines yet',
            style: HomeUi.control(widget.isDarkMode, active: true).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'News will appear here when available for your watchlist stocks.',
            style: HomeUi.subtitle(widget.isDarkMode).copyWith(fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList({required Key key}) {
    final List<Map<String, dynamic>> items = _allNews.take(10).toList();
    final bool dark = widget.isDarkMode;
    final List<Widget> rows = <Widget>[];

    for (int i = 0; i < items.length; i += 2) {
      final bool isLastRow = i + 2 >= items.length;
      final bool hasRightColumn = i + 1 < items.length;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _animatedNewsTile(
                  index: i,
                  dark: dark,
                  item: items[i],
                  showBottomBorder: !isLastRow,
                ),
              ),
              const SizedBox(width: _columnGap),
              Expanded(
                child: hasRightColumn
                    ? _animatedNewsTile(
                        index: i + 1,
                        dark: dark,
                        item: items[i + 1],
                        showBottomBorder: !isLastRow,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      key: key,
      children: rows,
    );
  }

  Widget _animatedNewsTile({
    required int index,
    required bool dark,
    required Map<String, dynamic> item,
    required bool showBottomBorder,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 35).clamp(0, 180)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
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
        ticker: item['ticker'] ?? '--',
        datetime: item['datetime'] ?? '--',
        summary: item['summary'] ?? '--',
        showBottomBorder: showBottomBorder,
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({
    required this.isDarkMode,
    required this.ticker,
    required this.datetime,
    required this.summary,
    this.showBottomBorder = true,
  });

  final bool isDarkMode;
  final String ticker;
  final String datetime;
  final String summary;
  final bool showBottomBorder;

  String get _cleanSummary => summary.replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkMode;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 13),
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: HomeUi.borderLight(dark).withValues(alpha: 0.9),
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HomeUi.elevatedBg(dark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                  border: Border.all(color: HomeUi.borderLight(dark)),
                ),
                child: Text(
                  ticker,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1,
                    color: HomeUi.title(dark),
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                datetime,
                style: HomeUi.subtitle(dark).copyWith(
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                _cleanSummary,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  height: 1.5,
                  letterSpacing: -0.15,
                  fontWeight: FontWeight.w500,
                  color: HomeUi.title(dark).withValues(alpha: 0.9),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
