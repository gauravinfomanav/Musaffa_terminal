import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/ticker_earnings_compact_chart.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/earnings_detail_controller.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/earnings_surprise.dart';
import 'package:musaffa_terminal/models/eps_estimate_model.dart';
import 'package:musaffa_terminal/models/financial_statement_model.dart';
import 'package:musaffa_terminal/models/quote_model.dart';
import 'package:musaffa_terminal/models/revenue_estimate_model.dart';
import 'package:musaffa_terminal/models/stock_profile_model.dart';
import 'package:musaffa_terminal/models/transcript_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum _DetailTab {
  overview,
  history,
  financials,
  estimates,
  transcripts,
}

class EarningsDetailScreen extends StatefulWidget {
  const EarningsDetailScreen({super.key, required this.args});

  final EarningsDetailArgs args;

  @override
  State<EarningsDetailScreen> createState() => _EarningsDetailScreenState();
}

class _EarningsDetailScreenState extends State<EarningsDetailScreen> {
  late final String _tag;
  late final EarningsDetailController _controller;
  _DetailTab _selectedTab = _DetailTab.overview;

  @override
  void initState() {
    super.initState();
    _tag = 'earnings_detail_${widget.args.symbol}_${widget.args.date}';
    _controller = Get.put(
      EarningsDetailController(args: widget.args),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<EarningsDetailController>(tag: _tag)) {
      Get.delete<EarningsDetailController>(tag: _tag);
    }
    super.dispose();
  }

  List<_DetailTab> _visibleTabs() {
    return <_DetailTab>[
      _DetailTab.overview,
      if (_controller.showHistoryTab) _DetailTab.history,
      if (_controller.showFinancialsTab) _DetailTab.financials,
      if (_controller.showEstimatesTab) _DetailTab.estimates,
      if (_controller.showTranscriptsTab) _DetailTab.transcripts,
    ];
  }

  String _tabLabel(_DetailTab tab) {
    return switch (tab) {
      _DetailTab.overview => 'Overview',
      _DetailTab.history => 'Earnings History',
      _DetailTab.financials => 'Financials',
      _DetailTab.estimates => 'Estimates',
      _DetailTab.transcripts => 'Transcripts',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: HomeUi.pageBg(isDark),
      body: Column(
        children: [
          HomeTabBar(
            showBackButton: true,
            onThemeToggle: () {
              final Brightness current = Theme.of(context).brightness;
              Get.changeThemeMode(
                current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          Obx(() {
            // Reactive deps for dynamic tabs.
            _controller.historyState.value;
            _controller.incomeState.value;
            _controller.balanceState.value;
            _controller.cashFlowState.value;
            _controller.epsEstimateState.value;
            _controller.revenueEstimateState.value;
            _controller.transcriptListState.value;
            _controller.surprises.length;
            _controller.epsEstimates.length;
            _controller.revenueEstimates.length;
            _controller.transcripts.length;

            final List<_DetailTab> visible = _visibleTabs();
            if (!visible.contains(_selectedTab)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _selectedTab = _DetailTab.overview);
                }
              });
            }

            final int selectedIndex =
                visible.indexOf(_selectedTab).clamp(0, visible.length - 1);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (visible.length * 140.0).clamp(280.0, 720.0),
                  ),
                  child: HomeUi.segmentedControl(
                    dark: isDark,
                    options: visible.map(_tabLabel).toList(),
                    selectedIndex: selectedIndex,
                    onChanged: (int index) {
                      setState(() => _selectedTab = visible[index]);
                    },
                  ),
                ),
              ),
            );
          }),
          Expanded(
            child: RefreshIndicator(
              color: HomeUi.accent(isDark),
              onRefresh: () => _controller.loadAll(forceRefresh: true),
              child: switch (_selectedTab) {
                _DetailTab.overview => _buildOverviewTab(isDark),
                _DetailTab.history => _buildHistoryTab(isDark),
                _DetailTab.financials => _buildFinancialsTab(isDark),
                _DetailTab.estimates => _buildEstimatesTab(isDark),
                _DetailTab.transcripts => _buildTranscriptsTab(isDark),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _buildHeroHeader(isDark),
        const SizedBox(height: 16),
        _buildSelectedEarningsCard(isDark),
        const SizedBox(height: 16),
        _buildQuoteStrip(isDark),
        const SizedBox(height: 16),
        _buildMetricsGrid(isDark),
      ],
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    return Obx(() {
      final StockProfileModel? profile = _controller.profile.value;
      final QuoteModel? quote = _controller.quote.value;
      final bool profileLoading =
          _controller.profileState.value == SectionLoadState.loading;
      final bool quoteLoading =
          _controller.quoteState.value == SectionLoadState.loading;

      final String name = profile?.name?.trim().isNotEmpty == true
          ? profile!.name!
          : widget.args.symbol;
      final String logo = profileLoading &&
              (profile?.logo == null || profile!.logo!.isEmpty)
          ? '__loading__'
          : (profile?.logo ?? '');
      final double? price = quote?.currentPrice;
      final double? change = quote?.change;
      final double? changePct = quote?.percentChange;
      final bool isUp = (changePct ?? 0) >= 0;

      if (profileLoading && profile == null && quote == null) {
        return Container(
          decoration: HomeUi.cardDecoration(isDark),
          padding: const EdgeInsets.all(16),
          child: _heroShimmer(isDark),
        );
      }

      return Container(
        decoration: HomeUi.cardDecoration(isDark),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: HomeUi.elevatedBg(isDark),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: HomeUi.borderLight(isDark),
                                    ),
                                  ),
                                  child: showLogo(
                                    widget.args.symbol,
                                    logo,
                                    sideWidth: 34,
                                    name: name,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (profileLoading && profile == null)
                                        _shimmerLine(
                                          isDark,
                                          width: 160,
                                          height: 16,
                                        )
                                      else
                                        Text(
                                          name,
                                          style: HomeUi.sectionTitle(isDark)
                                              .copyWith(fontSize: 17),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.args.symbol,
                                        style: HomeUi.overline(isDark).copyWith(
                                          letterSpacing: 1.3,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'CURRENT PRICE',
                              style: HomeUi.overline(isDark).copyWith(
                                fontSize: 10,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (quoteLoading && price == null)
                              _shimmerLine(isDark, width: 120, height: 28)
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    price == null
                                        ? '—'
                                        : '\$${price.toStringAsFixed(2)}',
                                    style: HomeUi.display(isDark).copyWith(
                                      fontSize: 28,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (changePct != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isUp
                                                ? HomeUi.positive(isDark)
                                                : HomeUi.negative(isDark))
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${isUp ? '+' : ''}${change?.toStringAsFixed(2) ?? '—'}  (${FinnhubDisplayFormatters.formatPercent(changePct)})',
                                        style: HomeUi.tableNumeric(
                                          isDark,
                                          positiveValue: isUp,
                                        ).copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: HomeUi.borderLight(isDark),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: profileLoading && profile == null
                      ? _kvShimmerBlock(isDark, rows: 5)
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeUi.tableToolbarHeader(
                        isDark,
                        icon: Icons.public_outlined,
                        title: 'Company',
                      ),
                      const SizedBox(height: 12),
                      _kv(isDark, 'Exchange', profile?.exchange ?? '—'),
                      _kv(isDark, 'Country', profile?.country ?? '—'),
                      _kv(isDark, 'Industry', profile?.finnhubIndustry ?? '—'),
                      _kv(isDark, 'Currency', profile?.currency ?? '—'),
                      _kv(isDark, 'IPO', profile?.ipo ?? '—'),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: HomeUi.borderLight(isDark),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: (profileLoading || quoteLoading) &&
                          profile == null &&
                          quote == null
                      ? _kvShimmerBlock(isDark, rows: 4)
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeUi.tableToolbarHeader(
                        isDark,
                        icon: Icons.auto_graph_outlined,
                        title: 'Highlights',
                      ),
                      const SizedBox(height: 12),
                      _kv(
                        isDark,
                        'Shares Out',
                        profile?.shareOutstanding?.toStringAsFixed(2) ?? '—',
                      ),
                      _kv(
                        isDark,
                        'Day Range',
                        quote?.low != null && quote?.high != null
                            ? '\$${quote!.low!.toStringAsFixed(2)} – \$${quote.high!.toStringAsFixed(2)}'
                            : '—',
                      ),
                      _kv(
                        isDark,
                        'Prev Close',
                        quote?.previousClose == null
                            ? '—'
                            : '\$${quote!.previousClose!.toStringAsFixed(2)}',
                      ),
                      if (profile?.weburl != null &&
                          profile!.weburl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: InkWell(
                            onTap: () async {
                              final Uri? uri = Uri.tryParse(profile.weburl!);
                              if (uri != null) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Text(
                              'Visit website',
                              style: HomeUi.subtitle(isDark).copyWith(
                                color: HomeUi.accent(isDark),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSelectedEarningsCard(bool isDark) {
    final EarningsDetailArgs a = widget.args;
    final double? surprisePct = (a.epsActual != null &&
            a.epsEstimate != null &&
            a.epsEstimate != 0)
        ? ((a.epsActual! - a.epsEstimate!) / a.epsEstimate!.abs()) * 100
        : null;
    final double? revSurprisePct = (a.revenueActual != null &&
            a.revenueEstimate != null &&
            a.revenueEstimate != 0)
        ? ((a.revenueActual! - a.revenueEstimate!) /
                a.revenueEstimate!.abs()) *
            100
        : null;
    final String hour = FinnhubDisplayFormatters.formatAnnouncementHour(a.hour);
    final String hourBadge =
        FinnhubDisplayFormatters.formatHourBadge(a.hour);

    return TickerFinnhubSectionCard(
      isDarkMode: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: HomeUi.tableToolbarHeader(
                    isDark,
                    icon: Icons.event_note_outlined,
                    title: 'Selected Earnings Release',
                    subtitleText: 'Non-GAAP / adjusted figures from calendar',
                  ),
                ),
                if (hourBadge != '—')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: HomeUi.elevatedBg(isDark),
                      borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                      border: Border.all(color: HomeUi.borderLight(isDark)),
                    ),
                    child: Text(
                      '$hourBadge · $hour',
                      style: HomeUi.subtitle(isDark).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _earningsStatColumn(
                  isDark,
                  title: 'Event',
                  rows: <(String, String)>[
                    ('Date', a.date),
                    (
                      'Quarter',
                      a.quarter != null && a.year != null
                          ? 'Q${a.quarter} FY${a.year}'
                          : '—'
                    ),
                    ('Timing', hour),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: HomeUi.borderLight(isDark),
                ),
                _earningsStatColumn(
                  isDark,
                  title: 'EPS',
                  rows: <(String, String)>[
                    (
                      'Actual',
                      a.epsActual == null
                          ? '—'
                          : '\$${a.epsActual!.toStringAsFixed(2)}'
                    ),
                    (
                      'Estimate',
                      a.epsEstimate == null
                          ? '—'
                          : '\$${a.epsEstimate!.toStringAsFixed(2)}'
                    ),
                    (
                      'Surprise',
                      surprisePct == null
                          ? '—'
                          : FinnhubDisplayFormatters.formatPercent(surprisePct),
                    ),
                  ],
                  surpriseValue: surprisePct,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: HomeUi.borderLight(isDark),
                ),
                _earningsStatColumn(
                  isDark,
                  title: 'Revenue',
                  rows: <(String, String)>[
                    (
                      'Actual',
                      FinnhubDisplayFormatters.formatCompactCurrency(
                        a.revenueActual,
                      ),
                    ),
                    (
                      'Estimate',
                      FinnhubDisplayFormatters.formatCompactCurrency(
                        a.revenueEstimate,
                      ),
                    ),
                    (
                      'Surprise',
                      revSurprisePct == null
                          ? '—'
                          : FinnhubDisplayFormatters.formatPercent(
                              revSurprisePct,
                            ),
                    ),
                  ],
                  surpriseValue: revSurprisePct,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsStatColumn(
    bool isDark, {
    required String title,
    required List<(String, String)> rows,
    double? surpriseValue,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: HomeUi.overline(isDark).copyWith(
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            for (final (String label, String value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        label,
                        style: HomeUi.tableCellSecondary(isDark)
                            .copyWith(fontSize: 12),
                      ),
                    ),
                    if (label == 'Surprise' &&
                        surpriseValue != null &&
                        value != '—')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (surpriseValue >= 0
                                  ? HomeUi.positive(isDark)
                                  : HomeUi.negative(isDark))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          value,
                          style: HomeUi.tableNumeric(
                            isDark,
                            positiveValue: surpriseValue >= 0,
                          ).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 4,
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: HomeUi.tableCellEmphasis(isDark).copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteStrip(bool isDark) {
    return Obx(() {
      final SectionLoadState state = _controller.quoteState.value;
      final QuoteModel? q = _controller.quote.value;
      if (state == SectionLoadState.loading) {
        return TickerFinnhubSectionCard(
          isDarkMode: isDark,
          child: _sectionShimmer(isDark, height: 72),
        );
      }
      if (q == null) return const SizedBox.shrink();

      final bool isUp = (q.percentChange ?? q.change ?? 0) >= 0;
      final List<(String, String, Color?)> items = <(String, String, Color?)>[
        (
          'Open',
          q.open == null ? '—' : '\$${q.open!.toStringAsFixed(2)}',
          null,
        ),
        (
          'High',
          q.high == null ? '—' : '\$${q.high!.toStringAsFixed(2)}',
          null,
        ),
        (
          'Low',
          q.low == null ? '—' : '\$${q.low!.toStringAsFixed(2)}',
          null,
        ),
        (
          'Prev Close',
          q.previousClose == null
              ? '—'
              : '\$${q.previousClose!.toStringAsFixed(2)}',
          null,
        ),
        (
          'Change',
          q.change == null
              ? '—'
              : '${q.change! >= 0 ? '+' : ''}${q.change!.toStringAsFixed(2)}',
          q.change == null
              ? null
              : (isUp ? HomeUi.positive(isDark) : HomeUi.negative(isDark)),
        ),
        (
          'Change %',
          FinnhubDisplayFormatters.formatPercent(q.percentChange),
          q.percentChange == null
              ? null
              : (isUp ? HomeUi.positive(isDark) : HomeUi.negative(isDark)),
        ),
      ];

      return TickerFinnhubSectionCard(
        isDarkMode: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeUi.tableToolbarHeader(
              isDark,
              icon: Icons.show_chart,
              title: 'Intraday Quote',
              subtitleText: 'Session open, range, and change',
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final int cols = c.maxWidth >= 900
                    ? 6
                    : c.maxWidth >= 640
                        ? 3
                        : 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: items
                      .map(
                        ((String, String, Color?) m) => SizedBox(
                          width: (c.maxWidth - (10 * (cols - 1))) / cols,
                          child: HomeUi.detailSummaryMetric(
                            dark: isDark,
                            label: m.$1,
                            value: m.$2,
                            valueColor: m.$3,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMetricsGrid(bool isDark) {
    const List<(String, String)> keys = <(String, String)>[
      ('peBasicExclExtraTTM', 'P/E'),
      ('52WeekHigh', '52W High'),
      ('52WeekLow', '52W Low'),
      ('roeTTM', 'ROE TTM'),
      ('roaTTM', 'ROA TTM'),
      ('grossMarginTTM', 'Gross Margin'),
      ('operatingMarginTTM', 'Op. Margin'),
      ('netProfitMarginTTM', 'Net Margin'),
      ('revenueGrowthTTMYoy', 'Rev Growth YoY'),
      ('epsGrowthTTMYoy', 'EPS Growth YoY'),
    ];

    return Obx(() {
      final SectionLoadState state = _controller.metricsState.value;
      if (state == SectionLoadState.loading) {
        return TickerFinnhubSectionCard(
          isDarkMode: isDark,
          child: _metricsShimmer(isDark),
        );
      }
      if (state != SectionLoadState.success) {
        return const SizedBox.shrink();
      }

      final List<(String, String)> present = <(String, String)>[];
      for (final (String key, String label) in keys) {
        final num? value = _controller.metrics.value?.metricNum(key);
        if (value == null) continue;
        present.add((label, _formatMetric(key, value)));
      }
      if (present.isEmpty) return const SizedBox.shrink();

      final Map<String, (String, String)> byLabel = <String, (String, String)>{
        for (final (String, String) p in present) p.$1: p,
      };
      final List<List<(String, String)>> columns = <List<(String, String)>>[
        <(String, String)>[
          for (final String l in <String>['P/E', '52W High', '52W Low'])
            if (byLabel.containsKey(l)) byLabel[l]!,
        ],
        <(String, String)>[
          for (final String l in <String>[
            'ROE TTM',
            'ROA TTM',
            'Gross Margin',
            'Op. Margin',
            'Net Margin',
          ])
            if (byLabel.containsKey(l)) byLabel[l]!,
        ],
        <(String, String)>[
          for (final String l in <String>['Rev Growth YoY', 'EPS Growth YoY'])
            if (byLabel.containsKey(l)) byLabel[l]!,
        ],
      ];
      // Append any leftover metrics into the last non-empty column.
      final Set<String> used = <String>{
        for (final List<(String, String)> col in columns)
          for (final (String, String) row in col) row.$1,
      };
      for (final (String, String) p in present) {
        if (!used.contains(p.$1)) {
          columns.last.add(p);
        }
      }
      final List<String> titles = <String>[
        'Price & Range',
        'Profitability',
        'Growth',
      ];

      return Container(
        decoration: HomeUi.cardDecoration(isDark),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: HomeUi.tableToolbarHeader(
                isDark,
                icon: Icons.analytics_outlined,
                title: 'Basic Financials',
                subtitleText: 'Valuation, margins, and growth snapshot',
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDark)),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                if (c.maxWidth < 720) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        for (int col = 0; col < columns.length; col++)
                          if (columns[col].isNotEmpty) ...[
                            if (col > 0) const SizedBox(height: 8),
                            _metricsColumn(
                              isDark,
                              title: titles[col],
                              rows: columns[col],
                            ),
                          ],
                      ],
                    ),
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int col = 0; col < columns.length; col++) ...[
                        if (col > 0)
                          Container(
                            width: 1,
                            color: HomeUi.borderLight(isDark),
                          ),
                        Expanded(
                          child: _metricsColumn(
                            isDark,
                            title: titles[col],
                            rows: columns[col],
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
    });
  }

  Widget _metricsColumn(
    bool isDark, {
    required String title,
    required List<(String, String)> rows,
  }) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: HomeUi.sectionTitle(isDark).copyWith(
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 20,
            height: 2,
            decoration: BoxDecoration(
              gradient: HomeUi.iconFillGradient,
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++)
            _metricKvRow(
              isDark,
              label: rows[i].$1,
              value: rows[i].$2,
              striped: i.isOdd,
            ),
        ],
      ),
    );
  }

  Widget _metricKvRow(
    bool isDark, {
    required String label,
    required String value,
    required bool striped,
  }) {
    final bool? signed = () {
      final String lower = label.toLowerCase();
      if (!(lower.contains('growth') ||
          lower.contains('roe') ||
          lower.contains('roa') ||
          lower.contains('margin'))) {
        return null;
      }
      if (value == '—' || value == '--') return null;
      return !value.trim().startsWith('-');
    }();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: striped ? HomeUi.tableRowOdd(isDark) : Colors.transparent,
        borderRadius: BorderRadius.circular(HomeUi.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: HomeUi.tableCellSecondary(isDark).copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (signed == null
                      ? HomeUi.tableCellEmphasis(isDark)
                      : HomeUi.tableNumeric(isDark, positiveValue: signed))
                  .copyWith(fontSize: 13, letterSpacing: -0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Obx(() {
          final SectionLoadState state = _controller.historyState.value;
          if (state == SectionLoadState.loading) {
            return TickerFinnhubSectionCard(
              isDarkMode: isDark,
              child: _sectionShimmer(isDark, height: 220),
            );
          }
          final List<EarningsSurprise> items = _controller.surprises.toList();
          if (items.isEmpty) return const SizedBox.shrink();

          final List<QuarterDataPoint> actualPoints = <QuarterDataPoint>[];
          final List<QuarterDataPoint> estimatePoints = <QuarterDataPoint>[];
          for (final EarningsSurprise s in items.reversed) {
            if (s.actual != null) {
              actualPoints.add(
                QuarterDataPoint(
                  date: s.period,
                  label: s.quarterLabel,
                  value: s.actual!,
                ),
              );
            }
            if (s.estimate != null) {
              estimatePoints.add(
                QuarterDataPoint(
                  date: s.period,
                  label: s.quarterLabel,
                  value: s.estimate!,
                ),
              );
            }
          }

          return Column(
            children: [
              if (actualPoints.isNotEmpty || estimatePoints.isNotEmpty)
                SizedBox(
                  height: TickerEarningsCompactChart.cardHeight,
                  child: Row(
                    children: [
                      if (actualPoints.isNotEmpty)
                        Expanded(
                          child: TickerEarningsCompactChart.build(
                            title: 'EPS Actual',
                            displayValue:
                                actualPoints.last.value.toStringAsFixed(2),
                            unit: '',
                            data: actualPoints,
                            isDarkMode: isDark,
                          ),
                        ),
                      if (actualPoints.isNotEmpty && estimatePoints.isNotEmpty)
                        const SizedBox(width: 16),
                      if (estimatePoints.isNotEmpty)
                        Expanded(
                          child: TickerEarningsCompactChart.build(
                            title: 'EPS Estimate',
                            displayValue:
                                estimatePoints.last.value.toStringAsFixed(2),
                            unit: '',
                            data: estimatePoints,
                            isDarkMode: isDark,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              DynamicTable(
                title: 'Quarterly Surprises',
                subtitle: 'Actual vs estimate by quarter',
                toolbarLeadingIcon: Icons.history,
                showOuterShadow: true,
                showFixedColumn: true,
                considerPadding: false,
                columnSpacing: 8,
                fixedColumnWidth: 110,
                enableLivePrices: false,
                zebraStripes: true,
                enableColumnCustomization: false,
                tableId: 'earnings_surprises_table',
                tickerHeaderLabel: 'QUARTER',
                columns: const <SimpleColumn>[
                  SimpleColumn(
                    label: 'ACTUAL',
                    fieldName: 'actual',
                    isNumeric: true,
                    width: 100,
                  ),
                  SimpleColumn(
                    label: 'ESTIMATE',
                    fieldName: 'estimate',
                    isNumeric: true,
                    width: 100,
                  ),
                  SimpleColumn(
                    label: 'SURPRISE \$',
                    fieldName: 'surprise',
                    isNumeric: true,
                    width: 110,
                  ),
                  SimpleColumn(
                    label: 'SURPRISE %',
                    fieldName: 'surprisePct',
                    isNumeric: true,
                    width: 110,
                  ),
                ],
                rows: items.map((EarningsSurprise s) {
                  return SimpleRowModel(
                    symbol: s.quarterLabel,
                    name: s.quarterLabel,
                    fields: <String, dynamic>{
                      '_row_id':
                          '${s.period.toIso8601String()}_${s.quarterLabel}',
                      'actual': s.actual?.toStringAsFixed(2) ?? '—',
                      'estimate': s.estimate?.toStringAsFixed(2) ?? '—',
                      'surprise': s.surprise?.toStringAsFixed(2) ?? '—',
                      'surprisePct': FinnhubDisplayFormatters.formatPercent(
                        s.surprisePercent,
                      ),
                      'change': s.surprisePercent ?? 0,
                    },
                    changeColor: s.surprisePercent == null
                        ? null
                        : (s.surprisePercent! >= 0
                            ? HomeUi.positive(isDark)
                            : HomeUi.negative(isDark)),
                    isPositive: s.surprisePercent == null
                        ? null
                        : s.surprisePercent! >= 0,
                  );
                }).toList(),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFinancialsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Frequency',
                    style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: HomeUi.controlHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                      border: Border.all(color: HomeUi.border(isDark)),
                      color: HomeUi.cardBg(isDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _controller.statementFreq.value,
                        isDense: true,
                        style: HomeUi.control(isDark, active: true),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(
                            value: 'quarterly',
                            child: Text('Quarterly'),
                          ),
                          DropdownMenuItem(
                            value: 'annual',
                            child: Text('Annual'),
                          ),
                        ],
                        onChanged: (String? v) {
                          if (v != null) _controller.setStatementFrequency(v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_controller.incomeState.value == SectionLoadState.loading ||
                  _controller.balanceState.value == SectionLoadState.loading ||
                  _controller.cashFlowState.value == SectionLoadState.loading)
                TickerFinnhubSectionCard(
                  isDarkMode: isDark,
                  child: _sectionShimmer(isDark, height: 180),
                ),
              if (_controller.incomeState.value == SectionLoadState.success)
                _statementCard(
                  'Income Statement',
                  _controller.incomeStatement.value,
                  isDark,
                ),
              if (_controller.balanceState.value == SectionLoadState.success) ...[
                const SizedBox(height: 16),
                _statementCard(
                  'Balance Sheet',
                  _controller.balanceSheet.value,
                  isDark,
                ),
              ],
              if (_controller.cashFlowState.value ==
                  SectionLoadState.success) ...[
                const SizedBox(height: 16),
                _statementCard(
                  'Cash Flow',
                  _controller.cashFlow.value,
                  isDark,
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _statementCard(
    String title,
    FinancialStatementModel? model,
    bool isDark,
  ) {
    if (model == null || model.periods.isEmpty) {
      return const SizedBox.shrink();
    }
    final Map<String, dynamic> latest = model.periods.first;
    final List<MapEntry<String, dynamic>> entries = latest.entries
        .where(
          (MapEntry<String, dynamic> e) =>
              e.key != 'period' &&
              e.key != 'year' &&
              e.key != 'quarter' &&
              e.key != 'symbol' &&
              e.key != 'filedDate' &&
              e.key != 'reportDate' &&
              e.value != null,
        )
        .take(16)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return DynamicTable(
      title: title,
      subtitle: 'Period: ${latest['period'] ?? '—'}',
      toolbarLeadingIcon: Icons.description_outlined,
      showOuterShadow: true,
      showFixedColumn: true,
      considerPadding: false,
      columnSpacing: 8,
      fixedColumnWidth: 220,
      enableLivePrices: false,
      zebraStripes: true,
      enableColumnCustomization: false,
      tableId: 'earnings_${title.toLowerCase().replaceAll(' ', '_')}',
      tickerHeaderLabel: 'METRIC',
      columns: const <SimpleColumn>[
        SimpleColumn(
          label: 'VALUE',
          fieldName: 'value',
          isNumeric: true,
          width: 140,
        ),
      ],
      rows: entries.map((MapEntry<String, dynamic> e) {
        final String value = e.value is num
            ? FinnhubDisplayFormatters.formatCompactCurrency(e.value as num)
            : e.value.toString();
        return SimpleRowModel(
          symbol: '',
          name: _humanize(e.key),
          logo: null,
          fields: <String, dynamic>{
            '_row_id': '${title}_${e.key}',
            'value': value,
          },
        );
      }).toList(),
    );
  }

  Widget _buildEstimatesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Obx(() {
          final bool loading =
              _controller.epsEstimateState.value == SectionLoadState.loading ||
                  _controller.revenueEstimateState.value ==
                      SectionLoadState.loading;
          if (loading &&
              _controller.epsEstimates.isEmpty &&
              _controller.revenueEstimates.isEmpty) {
            return TickerFinnhubSectionCard(
              isDarkMode: isDark,
              child: _sectionShimmer(isDark, height: 160),
            );
          }
          if (_controller.epsEstimates.isEmpty &&
              _controller.revenueEstimates.isEmpty) {
            return const SizedBox.shrink();
          }

          final List<EpsEstimateModel> eps = _controller.epsEstimates.toList();
          final List<RevenueEstimateModel> rev =
              _controller.revenueEstimates.toList();

          return Column(
            children: [
              if (eps.isNotEmpty) ...[
                if (eps.first.epsAvg != null ||
                    eps.first.epsHigh != null ||
                    eps.first.epsLow != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: HomeUi.detailSummaryMetric(
                            dark: isDark,
                            label: 'EPS Avg (${eps.first.label})',
                            value: eps.first.epsAvg?.toStringAsFixed(2) ?? '—',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: HomeUi.detailSummaryMetric(
                            dark: isDark,
                            label: 'EPS High',
                            value: eps.first.epsHigh?.toStringAsFixed(2) ?? '—',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: HomeUi.detailSummaryMetric(
                            dark: isDark,
                            label: 'EPS Low',
                            value: eps.first.epsLow?.toStringAsFixed(2) ?? '—',
                          ),
                        ),
                      ],
                    ),
                  ),
                DynamicTable(
                  title: 'Analyst EPS Estimates',
                  subtitle: 'Consensus estimates by period',
                  toolbarLeadingIcon: Icons.insights_outlined,
                  showOuterShadow: true,
                  showFixedColumn: true,
                  considerPadding: false,
                  columnSpacing: 8,
                  fixedColumnWidth: 140,
                  enableLivePrices: false,
                  zebraStripes: true,
                  enableColumnCustomization: false,
                  tableId: 'earnings_eps_estimates_table',
                  tickerHeaderLabel: 'PERIOD',
                  columns: const <SimpleColumn>[
                    SimpleColumn(
                      label: 'AVG',
                      fieldName: 'avg',
                      isNumeric: true,
                      width: 90,
                    ),
                    SimpleColumn(
                      label: 'HIGH',
                      fieldName: 'high',
                      isNumeric: true,
                      width: 90,
                    ),
                    SimpleColumn(
                      label: 'LOW',
                      fieldName: 'low',
                      isNumeric: true,
                      width: 90,
                    ),
                    SimpleColumn(
                      label: 'ANALYSTS',
                      fieldName: 'analysts',
                      isNumeric: true,
                      width: 100,
                    ),
                  ],
                  rows: eps
                      .map(
                        (EpsEstimateModel e) => SimpleRowModel(
                          symbol: e.label,
                          name: e.label,
                          fields: <String, dynamic>{
                            '_row_id': 'eps_${e.label}',
                            'avg': e.epsAvg?.toStringAsFixed(2) ?? '—',
                            'high': e.epsHigh?.toStringAsFixed(2) ?? '—',
                            'low': e.epsLow?.toStringAsFixed(2) ?? '—',
                            'analysts': e.numberAnalysts?.toString() ?? '—',
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              if (rev.isNotEmpty) ...[
                const SizedBox(height: 16),
                DynamicTable(
                  title: 'Analyst Revenue Estimates',
                  subtitle: 'Consensus revenue by period',
                  toolbarLeadingIcon: Icons.stacked_line_chart,
                  showOuterShadow: true,
                  showFixedColumn: true,
                  considerPadding: false,
                  columnSpacing: 8,
                  fixedColumnWidth: 140,
                  enableLivePrices: false,
                  zebraStripes: true,
                  enableColumnCustomization: false,
                  tableId: 'earnings_revenue_estimates_table',
                  tickerHeaderLabel: 'PERIOD',
                  columns: const <SimpleColumn>[
                    SimpleColumn(
                      label: 'AVG',
                      fieldName: 'avg',
                      isNumeric: true,
                      width: 110,
                    ),
                    SimpleColumn(
                      label: 'HIGH',
                      fieldName: 'high',
                      isNumeric: true,
                      width: 110,
                    ),
                    SimpleColumn(
                      label: 'LOW',
                      fieldName: 'low',
                      isNumeric: true,
                      width: 110,
                    ),
                    SimpleColumn(
                      label: 'ANALYSTS',
                      fieldName: 'analysts',
                      isNumeric: true,
                      width: 100,
                    ),
                  ],
                  rows: rev
                      .map(
                        (RevenueEstimateModel e) => SimpleRowModel(
                          symbol: e.label,
                          name: e.label,
                          fields: <String, dynamic>{
                            '_row_id': 'rev_${e.label}',
                            'avg': FinnhubDisplayFormatters.formatCompactCurrency(
                              e.revenueAvg,
                            ),
                            'high':
                                FinnhubDisplayFormatters.formatCompactCurrency(
                              e.revenueHigh,
                            ),
                            'low': FinnhubDisplayFormatters.formatCompactCurrency(
                              e.revenueLow,
                            ),
                            'analysts': e.numberAnalysts?.toString() ?? '—',
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTranscriptsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Obx(() {
          if (_controller.transcripts.isEmpty) {
            return const SizedBox.shrink();
          }
          return TickerFinnhubSectionCard(
            isDarkMode: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeUi.tableToolbarHeader(
                  isDark,
                  icon: Icons.record_voice_over_outlined,
                  title: 'Earnings Call Transcripts',
                ),
                const SizedBox(height: 8),
                ..._controller.transcripts.take(10).map(
                  (TranscriptListItem item) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        item.label,
                        style: HomeUi.tableCellEmphasis(isDark),
                      ),
                      subtitle: Text(
                        item.title ?? item.time ?? '',
                        style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: HomeUi.muted(isDark),
                      ),
                      onTap: () => _controller.openTranscript(item.id),
                    );
                  },
                ),
                Obx(() {
                  final SectionLoadState st =
                      _controller.transcriptDetailState.value;
                  if (st == SectionLoadState.idle) {
                    return const SizedBox.shrink();
                  }
                  if (st == SectionLoadState.loading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _sectionShimmer(isDark, height: 120),
                    );
                  }
                  final TranscriptDetail? detail =
                      _controller.selectedTranscript.value;
                  if (detail == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Management Discussion',
                        style: HomeUi.sectionTitle(isDark).copyWith(
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...detail.managementDiscussion.take(20).map(
                            (TranscriptSpeech s) => _speech(s, isDark),
                          ),
                      const SizedBox(height: 12),
                      Text(
                        'Q&A',
                        style: HomeUi.sectionTitle(isDark).copyWith(
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...detail.qa.take(20).map(
                            (TranscriptSpeech s) => _speech(s, isDark),
                          ),
                    ],
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _speech(TranscriptSpeech s, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.name ?? 'Speaker',
            style: HomeUi.tableCellEmphasis(isDark).copyWith(
              color: HomeUi.accent(isDark),
              fontSize: 12,
            ),
          ),
          Text(
            s.speech ?? '',
            style: HomeUi.bodyText(isDark).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _kv(bool isDark, String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: HomeUi.tableCellEmphasis(isDark).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMetric(String key, num value) {
    final String k = key.toLowerCase();
    if (k.contains('margin') ||
        k.contains('growth') ||
        k.contains('roe') ||
        k.contains('roa')) {
      return '${value.toStringAsFixed(2)}%';
    }
    return value.toStringAsFixed(2);
  }

  String _humanize(String key) {
    if (key.isEmpty) return key;
    final String spaced =
        key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').trim();
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  Color _shimmerBase(bool isDark) =>
      isDark ? const Color(0xFF2A2E34) : Colors.grey.shade200;
  Color _shimmerHighlight(bool isDark) =>
      isDark ? const Color(0xFF3A3F46) : Colors.grey.shade50;

  Widget _shimmerLine(
    bool isDark, {
    required double width,
    required double height,
  }) {
    return ShimmerWidgets.box(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(6),
      baseColor: _shimmerBase(isDark),
      highlightColor: _shimmerHighlight(isDark),
    );
  }

  Widget _sectionShimmer(bool isDark, {double height = 120}) {
    return ShimmerWidgets.box(
      width: double.infinity,
      height: height,
      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
      baseColor: _shimmerBase(isDark),
      highlightColor: _shimmerHighlight(isDark),
    );
  }

  Widget _heroShimmer(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerLine(isDark, width: 48, height: 48),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerLine(isDark, width: 160, height: 16),
                      const SizedBox(height: 8),
                      _shimmerLine(isDark, width: 64, height: 12),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _shimmerLine(isDark, width: 80, height: 10),
              const SizedBox(height: 8),
              _shimmerLine(isDark, width: 120, height: 28),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(flex: 10, child: _kvShimmerBlock(isDark, rows: 5)),
        const SizedBox(width: 16),
        Expanded(flex: 10, child: _kvShimmerBlock(isDark, rows: 4)),
      ],
    );
  }

  Widget _kvShimmerBlock(bool isDark, {required int rows}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerLine(isDark, width: 100, height: 14),
        const SizedBox(height: 14),
        for (int i = 0; i < rows; i++) ...[
          Row(
            children: [
              _shimmerLine(isDark, width: 72, height: 10),
              const Spacer(),
              _shimmerLine(isDark, width: 88, height: 10),
            ],
          ),
          if (i < rows - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _metricsShimmer(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerLine(isDark, width: 140, height: 14),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List<Widget>.generate(
            10,
            (_) => _shimmerLine(isDark, width: 140, height: 64),
          ),
        ),
      ],
    );
  }
}
