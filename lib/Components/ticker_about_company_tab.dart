import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/stock_twitter_section.dart';
import 'package:musaffa_terminal/Components/stock_youtube_videos_section.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Components/ticker_revenue_breakdown_section.dart';
import 'package:musaffa_terminal/Controllers/stock_profile_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_twitter_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_youtube_videos_controller.dart';
import 'package:musaffa_terminal/Controllers/ticker_revenue_breakdown_controller.dart';
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
    required this.twitterController,
    required this.revenueController,
    required this.isDarkMode,
  });

  final TickerModel ticker;
  final StockProfileController profileController;
  final StockYouTubeVideosController youtubeController;
  final StockTwitterController twitterController;
  final TickerRevenueBreakdownController revenueController;
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
      widget.revenueController.load(_symbol);
      widget.youtubeController.load(
        ticker: _symbol,
        companyName: _companyName,
      );
      widget.twitterController.load(
        ticker: _symbol,
        companyName: _companyName,
      );
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.profileController.load(_symbol, forceRefresh: true),
      widget.revenueController.load(_symbol, forceRefresh: true),
      widget.youtubeController.load(
        ticker: _symbol,
        companyName: _companyName,
        forceRefresh: true,
      ),
      widget.twitterController.load(
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: [
              if (isLoading)
                TickerFinnhubSectionCard(
                  isDarkMode: widget.isDarkMode,
                  padding: const EdgeInsets.all(18),
                  child: const TickerFinnhubLoadingState(
                    isDarkMode: true,
                    height: 180,
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
                        subtitleText: 'Profile unavailable',
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
                _CompanyProfileCard(
                  ticker: widget.ticker,
                  profile: profile,
                  companyName: _companyName,
                  isDarkMode: widget.isDarkMode,
                ),
                const SizedBox(height: 12),
                _CompanyDetailsCard(
                  profile: profile,
                  fallbackTicker: _symbol,
                  sectorFallback: widget.ticker.sectorname,
                  isDarkMode: widget.isDarkMode,
                ),
              ],
              const SizedBox(height: 12),
              TickerRevenueBreakdownSection(
                controller: widget.revenueController,
                isDarkMode: widget.isDarkMode,
                onRetry: () => widget.revenueController.load(
                  _symbol,
                  forceRefresh: true,
                ),
              ),
              const SizedBox(height: 12),
              StockTwitterSection(
                controller: widget.twitterController,
                isDarkMode: widget.isDarkMode,
                ticker: _symbol,
                onRetry: () => widget.twitterController.load(
                  ticker: _symbol,
                  companyName: _companyName,
                  forceRefresh: true,
                ),
              ),
              const SizedBox(height: 12),
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

/// One composition: identity + metrics strip + description.
class _CompanyProfileCard extends StatefulWidget {
  const _CompanyProfileCard({
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
  State<_CompanyProfileCard> createState() => _CompanyProfileCardState();
}

class _CompanyProfileCardState extends State<_CompanyProfileCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final profile = widget.profile;
    final symbol =
        widget.ticker.symbol ?? widget.ticker.ticker ?? profile?.ticker ?? '';
    final logoUrl = profile?.logo ?? widget.ticker.logo ?? '';
    final website = profile?.weburl?.trim();
    final chips = <String>[
      if (profile?.finnhubIndustry?.trim().isNotEmpty == true)
        profile!.finnhubIndustry!.trim(),
      if (profile?.currency?.trim().isNotEmpty == true)
        profile!.currency!.trim(),
      if (profile?.country?.trim().isNotEmpty == true)
        profile!.country!.trim(),
    ];

    final description = profile?.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final longDescription = hasDescription && description.length > 320;

    final metrics = <(String, String)>[
      (
        'Market Cap',
        profile?.marketCapitalization != null &&
                profile!.marketCapitalization! > 0
            ? Constants.formatMarketCapFromMillions(
                profile.marketCapitalization,
              )
            : '--',
      ),
      (
        'Employees',
        profile?.employeeTotal != null && profile!.employeeTotal! > 0
            ? _formatEmployees(profile.employeeTotal!)
            : '--',
      ),
      (
        'Shares Out',
        profile?.shareOutstanding != null && profile!.shareOutstanding! > 0
            ? Constants.getShortenedMarketCapV2(
                    profile.shareOutstanding! * 1000000)
                .replaceAll('\$', '')
            : '--',
      ),
      ('IPO', _formatIpo(profile?.ipo) ?? '--'),
      (
        'Currency',
        profile?.currency?.trim().isNotEmpty == true
            ? profile!.currency!.trim()
            : '--',
      ),
    ];

    return TickerFinnhubSectionCard(
      isDarkMode: isDark,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              showLogo(
                symbol,
                logoUrl,
                sideWidth: 52,
                name: symbol,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.companyName,
                      style: HomeUi.sectionTitle(isDark).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        symbol.toUpperCase(),
                        if (profile?.exchange?.trim().isNotEmpty == true)
                          profile!.exchange!.trim(),
                      ].join('  ·  '),
                      style: HomeUi.overline(isDark).copyWith(
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: chips
                            .map(
                              (chip) => Text(
                                chip,
                                style: HomeUi.control(isDark).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: HomeUi.title(isDark),
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
                const SizedBox(width: 10),
                HomeUi.ghostAction(
                  label: _displayWebsite(website!),
                  dark: isDark,
                  icon: Icons.open_in_new_rounded,
                  onTap: () => _openUrl(website),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(HomeUi.radiusLg),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                if (wide) {
                  return IntrinsicHeight(
                    child: Row(
                      children: [
                        for (int i = 0; i < metrics.length; i++) ...[
                          if (i > 0)
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: HomeUi.borderLight(isDark),
                            ),
                          Expanded(
                            child: _CompactMetricCell(
                              label: metrics[i].$1,
                              value: metrics[i].$2,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Wrap(
                  children: [
                    for (int i = 0; i < metrics.length; i++)
                      SizedBox(
                        width: (constraints.maxWidth / 2).clamp(120.0, 400.0),
                        child: _CompactMetricCell(
                          label: metrics[i].$1,
                          value: metrics[i].$2,
                          isDark: isDark,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (hasDescription) ...[
            const SizedBox(height: 14),
            Text(
              'Business Overview',
              style: HomeUi.sectionTitle(isDark).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: !_expanded && longDescription ? 4 : null,
              overflow: !_expanded && longDescription
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
              style: HomeUi.bodyText(isDark).copyWith(
                fontSize: 13,
                height: 1.55,
              ),
            ),
            if (longDescription) ...[
              const SizedBox(height: 8),
              HomeUi.ghostAction(
                label: _expanded ? 'Show less' : 'Read more',
                dark: isDark,
                icon: _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CompactMetricCell extends StatelessWidget {
  const _CompactMetricCell({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: HomeUi.overline(isDark).copyWith(
              fontSize: 11,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeUi.tableCellEmphasis(isDark).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches page section chrome — same card + toolbar as profile.
class _CompanyDetailsCard extends StatelessWidget {
  const _CompanyDetailsCard({
    required this.profile,
    required this.fallbackTicker,
    required this.sectorFallback,
    required this.isDarkMode,
  });

  final StockProfileModel? profile;
  final String fallbackTicker;
  final String? sectorFallback;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;

    final address = profile?.address?.trim();
    final cityLine = [
      if (profile?.city?.trim().isNotEmpty == true)
        _titleCase(profile!.city!.trim()),
      if (profile?.state?.trim().isNotEmpty == true)
        _titleCase(profile!.state!.trim()),
    ].join(', ');
    final phone = _formatPhone(profile?.phone);
    final website = profile?.weburl?.trim();

    final hqRows = <(String, String, VoidCallback?)>[
      if (address?.isNotEmpty == true) ('Address', address!, null),
      if (cityLine.isNotEmpty) ('City', cityLine, null),
      if (profile?.country?.trim().isNotEmpty == true)
        ('Country', profile!.country!.trim(), null),
      if (phone != null) ('Phone', phone, null),
      if (website?.isNotEmpty == true)
        (
          'Website',
          _displayWebsite(website!),
          () => _openUrl(website),
        ),
    ];
    if (hqRows.isEmpty) {
      hqRows.add(('Location', '--', null));
    }

    final idRows = <(String, String, VoidCallback?)>[
      (
        'Ticker',
        profile?.ticker?.trim().isNotEmpty == true
            ? profile!.ticker!.trim()
            : fallbackTicker,
        null,
      ),
      if (profile?.isin?.trim().isNotEmpty == true)
        ('ISIN', profile!.isin!.trim(), null),
      if (profile?.cusip?.trim().isNotEmpty == true)
        ('CUSIP', profile!.cusip!.trim(), null),
      if (profile?.sedol?.trim().isNotEmpty == true)
        ('SEDOL', profile!.sedol!.trim(), null),
      if (profile?.exchange?.trim().isNotEmpty == true)
        ('Exchange', profile!.exchange!.trim(), null),
    ];

    final industryRows = <(String, String, VoidCallback?)>[
      if (profile?.finnhubIndustry?.trim().isNotEmpty == true)
        ('Industry', profile!.finnhubIndustry!.trim(), null)
      else if (sectorFallback?.trim().isNotEmpty == true)
        ('Industry', sectorFallback!.trim(), null),
      if (profile?.naicsSector?.trim().isNotEmpty == true)
        ('NAICS Sector', profile!.naicsSector!.trim(), null),
      if (profile?.naicsSubsector?.trim().isNotEmpty == true)
        ('NAICS Subsector', profile!.naicsSubsector!.trim(), null),
      if (profile?.naicsNationalIndustry?.trim().isNotEmpty == true)
        ('National Industry', profile!.naicsNationalIndustry!.trim(), null),
      if (profile?.naics?.trim().isNotEmpty == true)
        ('NAICS', profile!.naics!.trim(), null),
    ];
    if (industryRows.isEmpty) {
      industryRows.add(('Industry', '--', null));
    }

    final sections = <(IconData, String, List<(String, String, VoidCallback?)>)>[
      (Icons.location_on_outlined, 'Headquarters', hqRows),
      (Icons.fingerprint_rounded, 'Identifiers', idRows),
      (Icons.category_outlined, 'Industry', industryRows),
    ];

    return TickerFinnhubSectionCard(
      isDarkMode: isDark,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.info_outline_rounded,
            title: 'Company Details',
            subtitleText: 'Location, identifiers, and classification',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              if (!wide) {
                return Column(
                  children: [
                    for (int i = 0; i < sections.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _DetailTilePanel(
                        icon: sections[i].$1,
                        title: sections[i].$2,
                        rows: sections[i].$3,
                        isDark: isDark,
                      ),
                    ],
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < sections.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _DetailTilePanel(
                          icon: sections[i].$1,
                          title: sections[i].$2,
                          rows: sections[i].$3,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailTilePanel extends StatelessWidget {
  const _DetailTilePanel({
    required this.icon,
    required this.title,
    required this.rows,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final List<(String, String, VoidCallback?)> rows;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(HomeUi.radiusLg),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: HomeUi.title(isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: HomeUi.cardTitle(isDark).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _StackedField(
              label: rows[i].$1,
              value: rows[i].$2,
              isDark: isDark,
              onTap: rows[i].$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _StackedField extends StatelessWidget {
  const _StackedField({
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: HomeUi.overline(isDark).copyWith(
            fontSize: 10,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w600,
            color: isDark
                ? HomeUi.muted(true)
                : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: HomeUi.tableCellEmphasis(isDark).copyWith(
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: onTap != null
                ? HomeUi.accent(isDark)
                : HomeUi.title(isDark),
          ),
        ),
      ],
    );

    if (onTap == null) return field;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: field),
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
