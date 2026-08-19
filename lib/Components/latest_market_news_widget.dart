import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/models/market_news.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
              onTap: () => _open(n.uRL),
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

  Future<void> _open(String? raw) async {
    if (raw == null || raw.trim().isEmpty) return;
    var url = raw.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrlString(url);
      }
    } catch (_) {}
  }
}

class _NewsRow extends StatelessWidget {
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

  String _clean(String? v) {
    if (v == null || v.trim().isEmpty) return '--';
    return v.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final title = HomeUi.title(isDark);
    final muted = HomeUi.muted(isDark);
    final imgBg = HomeUi.elevatedBg(isDark);
    final imageUrl = news.image?.trim();

    final imageWidth = compact ? 64.0 : 72.0;
    final imageHeight = compact ? 44.0 : 52.0;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
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
                        errorBuilder: (_, __, ___) => Icon(CupertinoIcons.photo, size: 18, color: muted),
                      )
                    : Icon(CupertinoIcons.photo, size: 18, color: muted),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _clean(news.headline),
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
                    '${_clean(news.source)} • ${controller.formatRelativeTime(news.datetime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: Constants.FONT_DEFAULT_NEW, fontSize: 12, color: muted),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 3),
                    Text(
                      _clean(news.summary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: Constants.FONT_DEFAULT_NEW, fontSize: 12.5, color: muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
