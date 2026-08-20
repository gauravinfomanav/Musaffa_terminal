import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/stock_youtube_videos_section.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/stock_profile_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_youtube_videos_controller.dart';
import 'package:musaffa_terminal/models/stock_profile_model.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TickerAboutCompanyTab extends StatefulWidget {
  const TickerAboutCompanyTab({
    super.key,
    required this.ticker,
    required this.profileController,
    required this.youtubeController,
    required this.isDarkMode,
  });

  final TickerModel ticker;
  final StockProfileController profileController;
  final StockYouTubeVideosController youtubeController;
  final bool isDarkMode;

  @override
  State<TickerAboutCompanyTab> createState() => _TickerAboutCompanyTabState();
}

class _TickerAboutCompanyTabState extends State<TickerAboutCompanyTab> {
  String get _symbol => widget.ticker.symbol ?? widget.ticker.ticker ?? '';

  String get _companyName {
    final profileName = widget.profileController.profile?.name?.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;
    return widget.ticker.companyName ?? widget.ticker.name ?? _symbol;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.profileController.load(_symbol);
      widget.youtubeController.load(
        ticker: _symbol,
        companyName: _companyName,
      );
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.profileController.load(_symbol, forceRefresh: true),
      widget.youtubeController.load(
        ticker: _symbol,
        companyName: _companyName,
        forceRefresh: true,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: HomeUi.accent(widget.isDarkMode),
      onRefresh: _refresh,
      child: ListenableBuilder(
        listenable: widget.profileController,
        builder: (context, _) {
          final profile = widget.profileController.profile;
          final isLoading =
              widget.profileController.isLoading && profile == null;
          final error = widget.profileController.error;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              if (isLoading)
                TickerFinnhubSectionCard(
                  isDarkMode: widget.isDarkMode,
                  child: const TickerFinnhubLoadingState(
                    isDarkMode: true,
                    height: 220,
                  ),
                )
              else if (error != null && profile == null)
                TickerFinnhubSectionCard(
                  isDarkMode: widget.isDarkMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeUi.tableToolbarHeader(
                        widget.isDarkMode,
                        icon: Icons.apartment_outlined,
                        title: 'About Company',
                        subtitleText: 'Finnhub company profile',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error,
                        style: HomeUi.subtitle(widget.isDarkMode).copyWith(
                          color: HomeUi.negative(widget.isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 12),
                      HomeUi.ghostAction(
                        label: 'Retry',
                        dark: widget.isDarkMode,
                        icon: Icons.refresh_rounded,
                        onTap: () => widget.profileController.load(
                          _symbol,
                          forceRefresh: true,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _CompanyHeroCard(
                  ticker: widget.ticker,
                  profile: profile,
                  companyName: _companyName,
                  isDarkMode: widget.isDarkMode,
                ),
                const SizedBox(height: 16),
                _SnapshotMetricsRow(
                  profile: profile,
                  isDarkMode: widget.isDarkMode,
                ),
                const SizedBox(height: 16),
                _BusinessDescriptionCard(
                  description: profile?.description,
                  isDarkMode: widget.isDarkMode,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 920;
                    final headquarters = _HeadquartersCard(
                      profile: profile,
                      isDarkMode: widget.isDarkMode,
                    );
                    final identifiers = _IdentifiersCard(
                      profile: profile,
                      fallbackTicker: _symbol,
                      isDarkMode: widget.isDarkMode,
                    );
                    final industry = _IndustryCard(
                      profile: profile,
                      sectorFallback: widget.ticker.sectorname,
                      isDarkMode: widget.isDarkMode,
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          headquarters,
                          const SizedBox(height: 16),
                          identifiers,
                          const SizedBox(height: 16),
                          industry,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: headquarters),
                        const SizedBox(width: 16),
                        Expanded(child: identifiers),
                        const SizedBox(width: 16),
                        Expanded(child: industry),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              StockYouTubeVideosSection(
                controller: widget.youtubeController,
                isDarkMode: widget.isDarkMode,
                onRetry: () => widget.youtubeController.load(
                  ticker: _symbol,
                  companyName: _companyName,
                  forceRefresh: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompanyHeroCard extends StatelessWidget {
  const _CompanyHeroCard({
    required this.ticker,
    required this.profile,
    required this.companyName,
    required this.isDarkMode,
  });

  final TickerModel ticker;
  final StockProfileModel? profile;
  final String companyName;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final symbol = ticker.symbol ?? ticker.ticker ?? profile?.ticker ?? '';
    final logoUrl = profile?.logo ?? ticker.logo ?? '';
    final website = profile?.weburl?.trim();
    final chips = <String>[
      if (profile?.finnhubIndustry?.trim().isNotEmpty == true)
        profile!.finnhubIndustry!.trim(),
      if (profile?.currency?.trim().isNotEmpty == true)
        profile!.currency!.trim(),
      if (profile?.country?.trim().isNotEmpty == true)
        profile!.country!.trim(),
    ];

    return TickerFinnhubSectionCard(
      isDarkMode: isDarkMode,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeUi.elevatedBg(isDarkMode),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomeUi.borderLight(isDarkMode)),
            ),
            child: showLogo(
              symbol,
              logoUrl,
              sideWidth: 36,
              name: symbol,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: HomeUi.sectionTitle(isDarkMode).copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    symbol,
                    if (profile?.exchange?.trim().isNotEmpty == true)
                      profile!.exchange!.trim(),
                  ].join('  ·  '),
                  style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips
                        .map(
                          (chip) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: HomeUi.elevatedBg(isDarkMode),
                              borderRadius:
                                  BorderRadius.circular(HomeUi.radiusPill),
                              border: Border.all(
                                color: HomeUi.borderLight(isDarkMode),
                              ),
                            ),
                            child: Text(
                              chip,
                              style: HomeUi.control(isDarkMode)
                                  .copyWith(fontSize: 11),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (website?.isNotEmpty == true) ...[
            const SizedBox(width: 12),
            HomeUi.ghostAction(
              label: _displayWebsite(website!),
              dark: isDarkMode,
              icon: Icons.open_in_new_rounded,
              onTap: () => _openUrl(website),
            ),
          ],
        ],
      ),
    );
  }
}

class _SnapshotMetricsRow extends StatelessWidget {
  const _SnapshotMetricsRow({
    required this.profile,
    required this.isDarkMode,
  });

  final StockProfileModel? profile;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final marketCap = profile?.marketCapitalization;
    final employees = profile?.employeeTotal;
    final shares = profile?.shareOutstanding;
    final ipo = _formatIpo(profile?.ipo);
    final currency = profile?.currency?.trim();

    final metrics = <(String, String)>[
      (
        'Market Cap',
        marketCap != null && marketCap > 0
            ? Constants.getShortenedMarketCapV2(marketCap * 1000000)
            : '--',
      ),
      (
        'Employees',
        employees != null && employees > 0
            ? _formatEmployees(employees)
            : '--',
      ),
      (
        'Shares Outstanding',
        shares != null && shares > 0
            ? Constants.getShortenedMarketCapV2(shares * 1000000)
                .replaceAll('\$', '')
            : '--',
      ),
      ('IPO Date', ipo ?? '--'),
      ('Currency', currency?.isNotEmpty == true ? currency! : '--'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 720
                ? 3
                : 2;
        final gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: HomeUi.detailSummaryMetric(
                    dark: isDarkMode,
                    label: metric.$1,
                    value: metric.$2,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _BusinessDescriptionCard extends StatefulWidget {
  const _BusinessDescriptionCard({
    required this.description,
    required this.isDarkMode,
  });

  final String? description;
  final bool isDarkMode;

  @override
  State<_BusinessDescriptionCard> createState() =>
      _BusinessDescriptionCardState();
}

class _BusinessDescriptionCardState extends State<_BusinessDescriptionCard> {
  bool _expanded = false;
  static const int _collapsedLines = 5;

  @override
  Widget build(BuildContext context) {
    final text = widget.description?.trim();
    final hasText = text != null && text.isNotEmpty;
    final textStyle = HomeUi.bodyText(widget.isDarkMode).copyWith(height: 1.6);

    return TickerFinnhubSectionCard(
      isDarkMode: widget.isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            widget.isDarkMode,
            icon: Icons.menu_book_outlined,
            title: 'Business Overview',
            subtitleText: 'Company description from Finnhub',
          ),
          const SizedBox(height: 14),
          if (!hasText)
            Text(
              'No company description available for this ticker.',
              style: HomeUi.subtitle(widget.isDarkMode),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final textPainter = TextPainter(
                  text: TextSpan(text: text, style: textStyle),
                  maxLines: _collapsedLines,
                  textDirection: Directionality.of(context),
                )..layout(maxWidth: constraints.maxWidth);
                final hasOverflow = textPainter.didExceedMaxLines;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      maxLines: !_expanded && hasOverflow ? _collapsedLines : null,
                      overflow: !_expanded && hasOverflow
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                      style: textStyle,
                    ),
                    if (hasOverflow) ...[
                      const SizedBox(height: 10),
                      HomeUi.ghostAction(
                        label: _expanded ? 'Show less' : 'Read more',
                        dark: widget.isDarkMode,
                        icon: _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        onTap: () => setState(() => _expanded = !_expanded),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HeadquartersCard extends StatelessWidget {
  const _HeadquartersCard({
    required this.profile,
    required this.isDarkMode,
  });

  final StockProfileModel? profile;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final address = profile?.address?.trim();
    final cityLine = [
      if (profile?.city?.trim().isNotEmpty == true)
        _titleCase(profile!.city!.trim()),
      if (profile?.state?.trim().isNotEmpty == true)
        _titleCase(profile!.state!.trim()),
    ].join(', ');
    final phone = _formatPhone(profile?.phone);
    final website = profile?.weburl?.trim();

    final rows = <(String, String)>[
      if (address?.isNotEmpty == true) ('Address', address!),
      if (cityLine.isNotEmpty) ('City', cityLine),
      if (profile?.country?.trim().isNotEmpty == true)
        ('Country', profile!.country!.trim()),
      if (phone != null) ('Phone', phone),
      if (website?.isNotEmpty == true) ('Website', _displayWebsite(website!)),
    ];

    return HomeUi.detailPanel(
      dark: isDarkMode,
      title: 'Headquarters',
      rows: rows.isEmpty ? const [('Location', '--')] : rows,
    );
  }
}

class _IdentifiersCard extends StatelessWidget {
  const _IdentifiersCard({
    required this.profile,
    required this.fallbackTicker,
    required this.isDarkMode,
  });

  final StockProfileModel? profile;
  final String fallbackTicker;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Ticker', profile?.ticker?.trim().isNotEmpty == true
          ? profile!.ticker!.trim()
          : fallbackTicker),
      if (profile?.isin?.trim().isNotEmpty == true) ('ISIN', profile!.isin!),
      if (profile?.cusip?.trim().isNotEmpty == true) ('CUSIP', profile!.cusip!),
      if (profile?.sedol?.trim().isNotEmpty == true) ('SEDOL', profile!.sedol!),
      if (profile?.exchange?.trim().isNotEmpty == true)
        ('Exchange', profile!.exchange!),
    ];

    return HomeUi.detailPanel(
      dark: isDarkMode,
      title: 'Identifiers',
      rows: rows,
    );
  }
}

class _IndustryCard extends StatelessWidget {
  const _IndustryCard({
    required this.profile,
    required this.sectorFallback,
    required this.isDarkMode,
  });

  final StockProfileModel? profile;
  final String? sectorFallback;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (profile?.finnhubIndustry?.trim().isNotEmpty == true)
        ('Industry', profile!.finnhubIndustry!.trim())
      else if (sectorFallback?.trim().isNotEmpty == true)
        ('Industry', sectorFallback!.trim()),
      if (profile?.naicsSector?.trim().isNotEmpty == true)
        ('NAICS Sector', profile!.naicsSector!),
      if (profile?.naicsSubsector?.trim().isNotEmpty == true)
        ('NAICS Subsector', profile!.naicsSubsector!),
      if (profile?.naicsNationalIndustry?.trim().isNotEmpty == true)
        ('National Industry', profile!.naicsNationalIndustry!),
      if (profile?.naics?.trim().isNotEmpty == true) ('NAICS', profile!.naics!),
    ];

    return HomeUi.detailPanel(
      dark: isDarkMode,
      title: 'Industry Classification',
      rows: rows.isEmpty ? const [('Industry', '--')] : rows,
    );
  }
}

String _titleCase(String value) {
  return value
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String _formatEmployees(num value) {
  if (value >= 1000) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }
  return value.toStringAsFixed(0);
}

String? _formatIpo(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  const months = [
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
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

String? _formatPhone(String? raw) {
  final digits = raw?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digits.isEmpty) return null;
  if (digits.length == 11 && digits.startsWith('1')) {
    return '+1 ${digits.substring(1, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }
  return raw?.trim();
}

String _displayWebsite(String url) {
  return url
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'^www\.'), '')
      .replaceFirst(RegExp(r'/$'), '');
}

Future<void> _openUrl(String rawUrl) async {
  final normalized = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    await launchUrlString(normalized);
    return;
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrlString(normalized);
  }
}
