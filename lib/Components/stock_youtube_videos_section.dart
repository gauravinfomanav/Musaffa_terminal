import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/stock_youtube_videos_controller.dart';
import 'package:musaffa_terminal/models/youtube_videos.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StockYouTubeVideosSection extends StatelessWidget {
  const StockYouTubeVideosSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
  });

  final StockYouTubeVideosController controller;
  final bool isDarkMode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.featureDisabled) {
          return const SizedBox.shrink();
        }

        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading && !controller.hasVideos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(null),
          const SizedBox(height: 16),
          _buildShimmer(),
        ],
      );
    }

    if (controller.error != null && !controller.hasVideos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(null),
          const SizedBox(height: 12),
          Text(
            controller.error!,
            style: HomeUi.subtitle(isDarkMode).copyWith(
              color: HomeUi.negative(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          HomeUi.ghostAction(
            label: 'Retry',
            dark: isDarkMode,
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        ],
      );
    }

    if (!controller.hasVideos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(null),
          const SizedBox(height: 12),
          TickerFinnhubEmptyState(
            isDarkMode: isDarkMode,
            message: controller.message ??
                'No analysis videos found for this stock',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(controller.videos.length),
        const SizedBox(height: 16),
        ...controller.videos.asMap().entries.map((entry) {
          final isLast = entry.key == controller.videos.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: _YouTubeVideoCard(
              video: entry.value,
              isDarkMode: isDarkMode,
              featured: entry.key == 0,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHeader(int? count) {
    final searchText = controller.searchSummary?.trim();
    final qualityText = controller.qualitySubtitle?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: HomeUi.tableToolbarHeader(
            isDarkMode,
            icon: Icons.play_circle_outline_rounded,
            title: 'Analysis Videos',
            subtitle: (searchText?.isNotEmpty == true ||
                    qualityText?.isNotEmpty == true)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (searchText?.isNotEmpty == true)
                        Text(
                          'Searched: $searchText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (qualityText?.isNotEmpty == true)
                        Text(
                          qualityText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  )
                : null,
            subtitleText: (searchText?.isNotEmpty == true ||
                    qualityText?.isNotEmpty == true)
                ? null
                : 'YouTube stock analysis ranked by popularity',
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: HomeUi.iconWellGradient,
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              border: Border.all(color: HomeUi.iconWellBorder),
            ),
            child: Text(
              '$count Videos',
              style: HomeUi.control(isDarkMode, active: true).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: index == 0 ? 118 : 104,
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            baseColor:
                isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor:
                isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
          ),
        ),
      ),
    );
  }
}

class _YouTubeVideoCard extends StatefulWidget {
  const _YouTubeVideoCard({
    required this.video,
    required this.isDarkMode,
    this.featured = false,
  });

  final StockYouTubeVideo video;
  final bool isDarkMode;
  final bool featured;

  @override
  State<_YouTubeVideoCard> createState() => _YouTubeVideoCardState();
}

class _YouTubeVideoCardState extends State<_YouTubeVideoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final video = widget.video;
    final featured = widget.featured;

    final thumbW = featured ? 160.0 : 140.0;
    final thumbH = featured ? 90.0 : 80.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openVideo(video.videoUrl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HomeUi.elevatedBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(
              color: _hovered
                  ? HomeUi.accent(isDark).withValues(alpha: 0.35)
                  : HomeUi.borderLight(isDark),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(
                url: video.thumbnail,
                duration: video.duration,
                isDarkMode: isDark,
                width: thumbW,
                height: thumbH,
                hovered: _hovered,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: thumbH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: HomeUi.bodyText(isDark).copyWith(
                          fontSize: featured ? 14 : 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: HomeUi.title(isDark),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (video.channel?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          video.channel!.trim(),
                          style: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _metaLine(video),
                        style: HomeUi.overline(isDark).copyWith(
                          fontSize: 11,
                          letterSpacing: 0.15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? HomeUi.accent(isDark).withValues(alpha: 0.12)
                        : (isDark
                            ? HomeUi.cardBg(true)
                            : Colors.white.withValues(alpha: 0.85)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HomeUi.borderLight(isDark)),
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 15,
                    color: _hovered
                        ? HomeUi.accent(isDark)
                        : HomeUi.muted(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _metaLine(StockYouTubeVideo video) {
    final parts = <String>[];
    if (video.publishedAt?.trim().isNotEmpty == true) {
      parts.add(video.publishedAt!.trim());
    }
    if (video.viewCount != null) {
      parts.add(_formatViewCount(video.viewCount!));
    }
    return parts.isEmpty ? 'Watch on YouTube' : parts.join(' · ');
  }

  Future<void> _openVideo(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      await launchUrlString(url);
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrlString(url);
    }
  }

  static String _formatViewCount(int count) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1)}M views';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1)}K views';
    }
    return '$count views';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.duration,
    required this.isDarkMode,
    required this.width,
    required this.height,
    required this.hovered,
  });

  final String? url;
  final String? duration;
  final bool isDarkMode;
  final double width;
  final double height;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url?.trim().isNotEmpty == true)
              Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              color: Colors.black.withValues(alpha: hovered ? 0.28 : 0.12),
            ),
            Center(
              child: AnimatedScale(
                scale: hovered ? 1.06 : 1,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: hovered ? 0.96 : 0.88),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            if (duration?.trim().isNotEmpty == true)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration!.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: HomeUi.cardBg(isDarkMode),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_circle_outline_rounded,
        color: HomeUi.muted(isDarkMode),
        size: 28,
      ),
    );
  }
}
