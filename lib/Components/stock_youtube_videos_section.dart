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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1100
                ? 5
                : width >= 800
                    ? 3
                    : width >= 520
                        ? 2
                        : 1;
            const gap = 20.0;
            final cardWidth = (width - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final video in controller.videos)
                  SizedBox(
                    width: cardWidth,
                    child: _YouTubeVideoCard(
                      video: video,
                      isDarkMode: isDarkMode,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(int? count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Videos',
                style: HomeUi.sectionTitle(isDarkMode).copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Curated YouTube analysis for this stock, ranked by views',
                style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HomeUi.elevatedBg(isDarkMode),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HomeUi.borderLight(isDarkMode)),
            ),
            child: Text(
              '$count videos',
              style: HomeUi.overline(isDarkMode).copyWith(
                fontSize: 11,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 5
            : width >= 800
                ? 3
                : width >= 520
                    ? 2
                    : 1;
        const gap = 20.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(
            columns * 2,
            (_) => SizedBox(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ShimmerWidgets.box(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(12),
                      baseColor: isDarkMode
                          ? const Color(0xFF404040)
                          : const Color(0xFFE5E7EB),
                      highlightColor: isDarkMode
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFF3F4F6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ShimmerWidgets.box(
                    width: cardWidth * 0.9,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                    highlightColor: isDarkMode
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF3F4F6),
                  ),
                  const SizedBox(height: 8),
                  ShimmerWidgets.box(
                    width: cardWidth * 0.45,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                    highlightColor: isDarkMode
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF3F4F6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium YouTube-style card: soft float, 16:9 media, channel identity.
class _YouTubeVideoCard extends StatefulWidget {
  const _YouTubeVideoCard({
    required this.video,
    required this.isDarkMode,
  });

  final StockYouTubeVideo video;
  final bool isDarkMode;

  @override
  State<_YouTubeVideoCard> createState() => _YouTubeVideoCardState();
}

class _YouTubeVideoCardState extends State<_YouTubeVideoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final video = widget.video;
    final channel = video.channel?.trim();
    final channelInitial = (channel != null && channel.isNotEmpty)
        ? channel[0].toUpperCase()
        : 'Y';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openVideo(video.videoUrl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? HomeUi.elevatedBg(true) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? HomeUi.borderStrong(isDark)
                  : HomeUi.borderLight(isDark).withValues(alpha: 0.85),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(
                  alpha: isDark
                      ? (_hovered ? 0.35 : 0.18)
                      : (_hovered ? 0.10 : 0.05),
                ),
                blurRadius: _hovered ? 28 : 18,
                offset: Offset(0, _hovered ? 12 : 6),
                spreadRadius: _hovered ? -2 : -4,
              ),
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _Thumbnail(
                  url: video.thumbnail,
                  duration: video.duration,
                  isDarkMode: isDark,
                  hovered: _hovered,
                ),
              ),
              // Fixed meta block → every card same total height
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? const [
                                    Color(0xFF3A4556),
                                    Color(0xFF1E293B),
                                  ]
                                : const [
                                    Color(0xFFE8EDF2),
                                    Color(0xFFD0D8E2),
                                  ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          channelInitial,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 36,
                              child: Text(
                                video.title,
                                style: HomeUi.bodyText(isDark).copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.32,
                                  letterSpacing: -0.15,
                                  color: HomeUi.title(isDark),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (channel != null && channel.isNotEmpty)
                                  ? channel
                                  : ' ',
                              style: HomeUi.subtitle(isDark).copyWith(
                                fontSize: 12,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                                color: HomeUi.muted(isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _metaLine(video),
                              style: HomeUi.overline(isDark).copyWith(
                                fontSize: 11,
                                height: 1.2,
                                letterSpacing: 0.05,
                                fontWeight: FontWeight.w500,
                                color: HomeUi.muted(isDark)
                                    .withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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
    if (video.viewCount != null) {
      parts.add(_formatViewCount(video.viewCount!));
    }
    if (video.publishedAt?.trim().isNotEmpty == true) {
      parts.add(video.publishedAt!.trim());
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
    required this.hovered,
  });

  final String? url;
  final String? duration;
  final bool isDarkMode;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft zoom on hover — premium media feel
        AnimatedScale(
          scale: hovered ? 1.04 : 1,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: url?.trim().isNotEmpty == true
              ? Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        // Bottom vignette for duration legibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: hovered ? 0.45 : 0.28),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        // Soft hover wash
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          color: Colors.black.withValues(alpha: hovered ? 0.18 : 0.0),
        ),
        // Play control — quiet at rest, present on hover
        Center(
          child: AnimatedOpacity(
            opacity: hovered ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: AnimatedScale(
              scale: hovered ? 1 : 0.86,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 30,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
        if (duration?.trim().isNotEmpty == true)
          Positioned(
            right: 9,
            bottom: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                duration!.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.25,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
              : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.ondemand_video_rounded,
        color: HomeUi.muted(isDarkMode).withValues(alpha: 0.55),
        size: 34,
      ),
    );
  }
}
