import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/stock_twitter_controller.dart';
import 'package:musaffa_terminal/models/stock_twitter_posts.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Market Conversations — matches Analysis Videos card language (HomeUi theme).
class StockTwitterSection extends StatelessWidget {
  const StockTwitterSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
    this.ticker = '',
  });

  final StockTwitterController controller;
  final bool isDarkMode;
  final VoidCallback onRetry;
  final String ticker;

  String get _searchUrl =>
      'https://x.com/search?q=%24${Uri.encodeComponent(ticker.toUpperCase())}&src=typed_query&f=live';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.featureDisabled) return const SizedBox.shrink();

        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildBody(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final dark = isDarkMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Conversations',
                style: HomeUi.sectionTitle(dark).copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticker.isEmpty
                    ? 'What the street is saying right now'
                    : 'Analyst takes and chatter around \$${ticker.toUpperCase()}',
                style: HomeUi.subtitle(dark).copyWith(fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (ticker.isNotEmpty) ...[
          const SizedBox(width: 12),
          HomeUi.ghostAction(
            label: 'Open',
            dark: dark,
            icon: Icons.open_in_new_rounded,
            onTap: () => _open(_searchUrl),
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    final dark = isDarkMode;

    if (controller.isLoading && !controller.hasTweets) {
      return _Shimmer(dark: dark);
    }

    if (controller.error != null && !controller.hasTweets) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.error!,
            style: HomeUi.subtitle(dark).copyWith(
              color: HomeUi.negative(dark),
            ),
          ),
          const SizedBox(height: 12),
          HomeUi.ghostAction(
            label: 'Retry',
            dark: dark,
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        ],
      );
    }

    if (!controller.hasTweets) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TickerFinnhubEmptyState(
            isDarkMode: dark,
            message: controller.message ?? 'No conversations found yet',
          ),
          if (ticker.isNotEmpty) ...[
            const SizedBox(height: 12),
            HomeUi.ghostAction(
              label: 'Browse on X',
              dark: dark,
              icon: Icons.open_in_new_rounded,
              onTap: () => _open(_searchUrl),
            ),
          ],
        ],
      );
    }

    final tweets = controller.tweets;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        const cardHeight = 188.0;
        final cardW = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tweet in tweets)
              SizedBox(
                width: cardW,
                height: cardHeight,
                child: _TweetCard(
                  tweet: tweet,
                  dark: dark,
                  ticker: ticker,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TweetCard extends StatefulWidget {
  const _TweetCard({
    required this.tweet,
    required this.dark,
    required this.ticker,
  });

  final StockTweet tweet;
  final bool dark;
  final String ticker;

  @override
  State<_TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends State<_TweetCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final t = widget.tweet;
    final initial =
        t.authorName.isNotEmpty ? t.authorName[0].toUpperCase() : 'M';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final url = t.url?.trim();
          if (url != null && url.isNotEmpty) _open(url);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: dark ? HomeUi.elevatedBg(true) : Colors.white,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(
              color: _hovered
                  ? HomeUi.borderStrong(dark)
                  : HomeUi.borderLight(dark).withValues(alpha: 0.85),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(
                  alpha: dark
                      ? (_hovered ? 0.35 : 0.18)
                      : (_hovered ? 0.10 : 0.05),
                ),
                blurRadius: _hovered ? 28 : 18,
                offset: Offset(0, _hovered ? 12 : 6),
                spreadRadius: _hovered ? -2 : -4,
              ),
              if (!dark)
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(
                    initial: initial,
                    url: t.avatarUrl,
                    dark: dark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                t.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HomeUi.bodyText(dark).copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.15,
                                  color: HomeUi.title(dark),
                                ),
                              ),
                            ),
                            if (t.verified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: HomeUi.accent(dark),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            '@${t.authorHandle}',
                            if (t.createdAt != null) _ago(t.createdAt!),
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeUi.subtitle(dark).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text.rich(
                  _bodySpan(t.text, widget.ticker, dark),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: HomeUi.borderLight(dark).withValues(alpha: 0.8),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _Metric(
                      kind: _MetricKind.reply,
                      value: t.replyCount,
                      dark: dark,
                    ),
                    const SizedBox(width: 16),
                    _Metric(
                      kind: _MetricKind.repost,
                      value: t.repostCount,
                      dark: dark,
                    ),
                    const SizedBox(width: 16),
                    _Metric(
                      kind: _MetricKind.like,
                      value: t.likeCount,
                      dark: dark,
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

  TextSpan _bodySpan(String text, String ticker, bool dark) {
    final base = HomeUi.bodyText(dark).copyWith(
      fontSize: 13.5,
      height: 1.45,
      letterSpacing: -0.1,
      fontWeight: FontWeight.w400,
      color: HomeUi.title(dark).withValues(alpha: dark ? 0.9 : 0.86),
    );
    final accent = base.copyWith(
      color: HomeUi.accent(dark),
      fontWeight: FontWeight.w600,
    );

    final sym = ticker.trim().toUpperCase();
    if (sym.isEmpty) return TextSpan(style: base, text: text);

    final re = RegExp(r'(\$' + RegExp.escape(sym) + r')', caseSensitive: false);
    final spans = <InlineSpan>[];
    var i = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
      spans.add(TextSpan(text: m.group(0), style: accent));
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return TextSpan(style: base, children: spans);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    required this.dark,
    this.url,
  });

  final String initial;
  final bool dark;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF3A4556), Color(0xFF1E293B)]
              : const [Color(0xFFE8EDF2), Color(0xFFD0D8E2)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: u != null && u.isNotEmpty
          ? Image.network(
              u,
              fit: BoxFit.cover,
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => _letter(),
            )
          : _letter(),
    );
  }

  Widget _letter() {
    return Text(
      initial,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: dark ? const Color(0xFFF8FAFC) : const Color(0xFF334155),
      ),
    );
  }
}

enum _MetricKind { reply, repost, like }

class _Metric extends StatelessWidget {
  const _Metric({
    required this.kind,
    required this.value,
    required this.dark,
  });

  final _MetricKind kind;
  final int value;
  final bool dark;

  IconData get _icon => switch (kind) {
        _MetricKind.reply => Icons.chat_bubble_outline_rounded,
        _MetricKind.repost => Icons.repeat_rounded,
        _MetricKind.like => Icons.favorite_border_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = HomeUi.muted(dark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 15, color: color),
        if (value > 0) ...[
          const SizedBox(width: 5),
          Text(
            _n(value),
            style: HomeUi.subtitle(dark).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final base = dark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final hi = dark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final w = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(
            4,
            (_) => ShimmerWidgets.box(
              width: w,
              height: 188,
              borderRadius: BorderRadius.circular(HomeUi.radiusCard),
              baseColor: base,
              highlightColor: hi,
            ),
          ),
        );
      },
    );
  }
}

String _n(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) {
    final k = v / 1000;
    return k >= 10 ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
  }
  return '$v';
}

String _ago(DateTime d) {
  final x = DateTime.now().difference(d);
  if (x.inMinutes < 1) return 'now';
  if (x.inMinutes < 60) return '${x.inMinutes}m';
  if (x.inHours < 24) return '${x.inHours}h';
  if (x.inDays < 7) return '${x.inDays}d';
  return '${d.month}/${d.day}';
}

Future<void> _open(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }
}
