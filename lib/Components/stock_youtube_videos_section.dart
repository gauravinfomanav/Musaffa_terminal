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
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: _YouTubeVideoCard(
              video: entry.value,
              isDarkMode: isDarkMode,
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
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: 104,
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

class _YouTubeVideoCard extends StatelessWidget {
  const _YouTubeVideoCard({
    required this.video,
    required this.isDarkMode,
  });

  final StockYouTubeVideo video;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openVideo(video.videoUrl),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: HomeUi.elevatedBg(isDarkMode),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(color: HomeUi.borderLight(isDarkMode)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(
                  url: video.thumbnail,
                  duration: video.duration,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: HomeUi.bodyText(isDarkMode).copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (video.channel?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          video.channel!.trim(),
                          style: HomeUi.subtitle(isDarkMode).copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (video.publishedAt?.trim().isNotEmpty == true)
                            _MetaChip(
                              text: video.publishedAt!.trim(),
                              isDarkMode: isDarkMode,
                            ),
                          if (video.viewCount != null)
                            _MetaChip(
                              text: _formatViewCount(video.viewCount!),
                              isDarkMode: isDarkMode,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: HomeUi.muted(isDarkMode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  });

  final String? url;
  final String? duration;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    const width = 128.0;
    const height = 72.0;

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
      color: HomeUi.elevatedBg(isDarkMode),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_circle_outline_rounded,
        color: HomeUi.muted(isDarkMode),
        size: 28,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
    required this.isDarkMode,
  });

  final String text;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: HomeUi.overline(isDarkMode).copyWith(
        fontSize: 10,
        letterSpacing: 0.3,
      ),
    );
  }
}
