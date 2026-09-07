import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Screens/news_article_webview_screen.dart';
import 'package:musaffa_terminal/models/market_news.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class LatestMarketNewsWidget extends StatefulWidget {
  const LatestMarketNewsWidget({
    super.key,
    this.previewCount,
    this.height,
  });

  final int? previewCount;
  final double? height;

  @override
  State<LatestMarketNewsWidget> createState() => _LatestMarketNewsWidgetState();
}

class _LatestMarketNewsWidgetState extends State<LatestMarketNewsWidget> {
  late final MarketNewsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<MarketNewsController>()
        ? Get.find<MarketNewsController>()
        : Get.put(MarketNewsController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.latestMarketNewsList.isEmpty) {
        _controller.fetchLatestMarketNews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = HomeUi.muted(isDark);

    return Obx(() {
      final loading = _controller.isLoadingLatest.value;
      final error = _controller.latestErrorMessage.value;
      final news = _controller.latestMarketNewsList;

      final header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'Latest Market News',
              style: HomeUi.cardTitle(isDark),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: HomeUi.borderLight(isDark)),
        ],
      );

      final body = _buildBody(loading, error, news, isDark, muted);

      if (widget.height != null) {
        return SizedBox(
          height: widget.height,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: HomeUi.cardDecoration(isDark),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: HomeUi.cardDecoration(isDark),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: body,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBody(
    bool loading,
    String error,
    List<MarketNews> news,
    bool isDark,
    Color muted,
  ) {
    if (loading) return _shimmer(isDark);
    if (error.isNotEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(error, style: DashboardTextStyles.errorMessage),
      );
    }
    if (news.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          'No news available',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            color: muted,
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      physics: widget.height != null
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      shrinkWrap: widget.height == null,
      children: news
          .take(widget.previewCount ?? news.length)
          .map(
            (n) => _NewsRow(
              news: n,
              isDark: isDark,
              controller: _controller,
              compact: widget.height != null,
              onTap: () => openNewsArticle(
                context,
                url: n.uRL,
                title: n.headline,
                source: n.source,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _shimmer(bool isDark) {
    final base = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final highlight =
        isDark ? const Color(0xFF1A1D1E) : const Color(0xFFF3F4F6);

    return ListView(
      padding: EdgeInsets.zero,
      physics: widget.height != null
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      shrinkWrap: widget.height == null,
      children: List.generate(
        widget.previewCount ?? 6,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              ShimmerWidgets.box(
                width: 72,
                height: 52,
                borderRadius: BorderRadius.circular(6),
                baseColor: base,
                highlightColor: highlight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidgets.box(
                      width: double.infinity,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                      baseColor: base,
                      highlightColor: highlight,
                    ),
                    const SizedBox(height: 6),
                    ShimmerWidgets.box(
                      width: 80,
                      height: 10,
                      borderRadius: BorderRadius.circular(4),
                      baseColor: base,
                      highlightColor: highlight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsRow extends StatefulWidget {
  const _NewsRow({
    required this.news,
    required this.isDark,
    required this.controller,
    required this.onTap,
    this.compact = false,
  });

  final MarketNews news;
  final bool isDark;
  final bool compact;
  final MarketNewsController controller;
  final VoidCallback onTap;

  @override
  State<_NewsRow> createState() => _NewsRowState();
}

class _NewsRowState extends State<_NewsRow> {
  bool _hovered = false;

  String _clean(String? v) {
    if (v == null || v.trim().isEmpty) return '--';
    return v.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;
    final title = HomeUi.title(isDark);
    final muted = HomeUi.muted(isDark);
    final imgBg = HomeUi.elevatedBg(isDark);
    final imageUrl = widget.news.image?.trim();
    final compact = widget.compact;

    final imageWidth = compact ? 64.0 : 72.0;
    final imageHeight = compact ? 44.0 : 52.0;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: _hovered
                      ? imgBg.withValues(alpha: isDark ? 0.55 : 0.7)
                      : null,
                  borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                      child: Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: imgBg,
                        alignment: Alignment.center,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: imageWidth,
                                height: imageHeight,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  CupertinoIcons.photo,
                                  size: 18,
                                  color: muted,
                                ),
                              )
                            : Icon(
                                CupertinoIcons.photo,
                                size: 18,
                                color: muted,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: _hovered ? 118 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                            _clean(widget.news.headline),
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: compact ? 13 : 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              letterSpacing: -0.15,
                              color: title,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_clean(widget.news.source)} • ${widget.controller.formatRelativeTime(widget.news.datetime)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 12,
                              color: muted,
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 3),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              alignment: Alignment.topLeft,
                              child: Text(
                                _clean(widget.news.summary),
                                maxLines: _hovered ? null : 1,
                                overflow: _hovered
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hovered)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: HomeUi.cardBg(isDark),
                      borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                      border: Border.all(color: HomeUi.borderLight(isDark)),
                    ),
                    child: Text(
                      'View full news',
                      style: HomeUi.subtitle(isDark).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
