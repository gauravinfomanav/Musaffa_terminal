import 'package:flutter/material.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/models/portfolio_allocation_insights.dart';
import 'package:musaffa_terminal/portfolio/services/portfolio_allocation_insights_service.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
import 'package:musaffa_terminal/portfolio/utils/portfolio_allocation_palette.dart';
import 'package:musaffa_terminal/portfolio/widgets/model_allocation_ring.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Detailed allocation analytics — sector donut, holdings, geo, full market profile.
class PortfolioAllocationAnalyticsSection extends StatefulWidget {
  const PortfolioAllocationAnalyticsSection({
    super.key,
    required this.isDark,
    required this.holdings,
    required this.totalPercent,
  });

  final bool isDark;
  final List<ModelPortfolioHolding> holdings;
  final double totalPercent;

  @override
  State<PortfolioAllocationAnalyticsSection> createState() =>
      _PortfolioAllocationAnalyticsSectionState();
}

class _PortfolioAllocationAnalyticsSectionState
    extends State<PortfolioAllocationAnalyticsSection> {
  final _insightsService = PortfolioAllocationInsightsService();
  PortfolioAllocationInsights _insights = PortfolioAllocationInsights.empty;
  bool _loadingInsights = false;
  Object? _loadToken;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  @override
  void didUpdateWidget(covariant PortfolioAllocationAnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameHoldings(oldWidget.holdings, widget.holdings)) {
      _loadInsights();
    }
  }

  bool _sameHoldings(
    List<ModelPortfolioHolding> a,
    List<ModelPortfolioHolding> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].ticker.toUpperCase() != b[i].ticker.toUpperCase()) return false;
      if (a[i].targetPercent != b[i].targetPercent) return false;
      if (a[i].sector != b[i].sector) return false;
    }
    return true;
  }

  Future<void> _loadInsights() async {
    if (widget.holdings.isEmpty) {
      setState(() {
        _insights = PortfolioAllocationInsights.empty;
        _loadingInsights = false;
      });
      return;
    }

    final token = Object();
    _loadToken = token;
    setState(() => _loadingInsights = true);

    try {
      final insights = await _insightsService.load(widget.holdings);
      if (!mounted || _loadToken != token) return;
      setState(() {
        _insights = insights;
        _loadingInsights = false;
      });
    } catch (_) {
      if (!mounted || _loadToken != token) return;
      setState(() => _loadingInsights = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final holdings = widget.holdings;
    if (holdings.isEmpty) {
      return Text(
        'Add holdings to see sector breakdown, geographic exposure, and market profile.',
        style: HomeUi.subtitle(isDark),
      );
    }

    final sectorSlices = _sectorSlices(holdings, _insights);
    final countrySlices = _countrySlices(holdings, _insights);
    final topHoldings = _topHoldings(holdings);
    final largest = _largestPosition(holdings);
    final top5 = _top5Concentration(holdings);
    final assetSlices = _assetTypeSlices(holdings, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (assetSlices.isNotEmpty) ...[
          ...assetSlices.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _highlightBar(
                isDark: isDark,
                title: 'Asset mix',
                label: s.label,
                percent: s.percent,
                color: s.color,
                useBrandGradient: true,
              ),
            ),
          ),
          if (sectorSlices.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...sectorSlices.take(6).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _highlightBar(
                      isDark: isDark,
                      title: 'Sector exposure',
                      label: s.label,
                      percent: s.percent,
                      color: PortfolioAllocationPalette.sectorColor(
                        s.label,
                        isDark,
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Text('Market profile', style: HomeUi.label(isDark)),
            const Spacer(),
            if (_loadingInsights)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: HomeUi.accent(isDark),
                ),
              )
            else
              Text(
                'Source: Finnhub',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 10),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _buildMarketMetrics(
          isDark: isDark,
          insights: _insights,
          top5: top5,
          largest: largest,
        ),
        const SizedBox(height: 18),
        _buildBreakdownRow(
          isDark: isDark,
          sectorSlices: sectorSlices,
          topHoldings: topHoldings,
          countrySlices: countrySlices,
          totalPercent: widget.totalPercent,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow({
    required bool isDark,
    required List<({String label, double percent})> sectorSlices,
    required List<({String label, double percent})> topHoldings,
    required List<({String label, double percent})> countrySlices,
    required double totalPercent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final sectorDonut = _breakdownCard(
          isDark,
          title: 'Sector exposure',
          child: sectorSlices.isEmpty
              ? _emptyHint(isDark, 'No sector data')
              : Column(
                  children: [
                    Center(
                      child: ModelBreakdownDonut(
                        isDark: isDark,
                        slices: sectorSlices.take(5).toList(),
                        centerValue: formatAllocationPercent(totalPercent),
                        centerLabel: 'Total',
                        size: 140,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...sectorSlices.take(5).map(
                          (s) => _legendRow(
                            isDark,
                            label: s.label,
                            percent: s.percent,
                            color: PortfolioAllocationPalette.sectorColor(
                              s.label,
                              isDark,
                            ),
                          ),
                        ),
                  ],
                ),
        );

        final topHoldingsCard = _breakdownCard(
          isDark,
          title: 'Top holdings',
          child: topHoldings.isEmpty
              ? _emptyHint(isDark, 'No holdings')
              : Column(
                  children: topHoldings
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _holdingWeightRow(isDark, h),
                        ),
                      )
                      .toList(),
                ),
        );

        final geoCard = _breakdownCard(
          isDark,
          title: 'Geographic exposure',
          child: countrySlices.isEmpty
              ? _emptyHint(isDark, 'No country data')
              : Column(
                  children: countrySlices
                      .take(6)
                      .map(
                        (c) => _legendRow(
                          isDark,
                          label: c.label,
                          percent: c.percent,
                          color: PortfolioAllocationPalette.primary(isDark),
                        ),
                      )
                      .toList(),
                ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: sectorDonut),
              const SizedBox(width: 12),
              Expanded(child: topHoldingsCard),
              const SizedBox(width: 12),
              Expanded(child: geoCard),
            ],
          );
        }

        return Column(
          children: [
            sectorDonut,
            const SizedBox(height: 12),
            topHoldingsCard,
            const SizedBox(height: 12),
            geoCard,
          ],
        );
      },
    );
  }

  Widget _buildMarketMetrics({
    required bool isDark,
    required PortfolioAllocationInsights insights,
    required double top5,
    required ({String label, double percent})? largest,
  }) {
    final cap = insights.weightedAvgMarketCapMillions;
    final volume = insights.weightedAvgDailyVolume;
    final pe = insights.weightedAvgPe;
    final divYield = insights.weightedAvgDividendYield;

    final tiles = [
      _metricTile(
        isDark,
        icon: Icons.account_balance_wallet_outlined,
        label: 'Wtd avg mkt cap',
        value: cap != null ? Constants.formatMarketCapFromMillions(cap) : '—',
        hint: 'Allocation-weighted',
      ),
      _metricTile(
        isDark,
        icon: Icons.bar_chart_rounded,
        label: 'Wtd avg volume (10D)',
        value: volume != null ? _formatVolume(volume) : '—',
        hint: 'Avg shares',
      ),
      _metricTile(
        isDark,
        icon: Icons.pie_chart_outline_rounded,
        label: 'Top 5 weight',
        value: formatAllocationPercent(top5),
        hint: largest?.label ?? 'Concentration',
      ),
      _metricTile(
        isDark,
        icon: Icons.show_chart_rounded,
        label: 'Price / earnings',
        value: pe != null ? pe.toStringAsFixed(2) : '—',
        hint: 'Portfolio PE',
      ),
      _metricTile(
        isDark,
        icon: Icons.savings_outlined,
        label: 'Dividend yield',
        value: divYield != null ? '${divYield.toStringAsFixed(2)}%' : '—',
        hint: 'Portfolio yield',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 560
                ? 3
                : 2;
        final tileWidth = (constraints.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tiles
              .map((t) => SizedBox(width: tileWidth, child: t))
              .toList(),
        );
      },
    );
  }

  Widget _metricTile(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: HomeUi.accent(isDark)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 10),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: HomeUi.control(isDark).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _highlightBar({
    required bool isDark,
    required String title,
    required String label,
    required double percent,
    required Color color,
    bool useBrandGradient = false,
  }) {
    final fraction = (percent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title, style: HomeUi.label(isDark)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '· $label',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatAllocationPercent(percent),
              style: HomeUi.control(isDark).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 7,
            child: Stack(
              children: [
                Container(color: HomeUi.borderLight(isDark)),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: useBrandGradient ? null : color,
                      gradient: useBrandGradient
                          ? PortfolioAllocationPalette.primaryBarGradient(isDark)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _breakdownCard(
    bool isDark, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: HomeUi.label(isDark)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _emptyHint(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _legendRow(
    bool isDark, {
    required String label,
    required double percent,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: HomeUi.control(isDark).copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatAllocationPercent(percent),
            style: HomeUi.control(isDark).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _holdingWeightRow(
    bool isDark,
    ({String label, double percent}) holding,
  ) {
    final fraction = (holding.percent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                holding.label,
                style: HomeUi.control(isDark).copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatAllocationPercent(holding.percent),
              style: HomeUi.control(isDark).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(color: HomeUi.borderLight(isDark)),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: PortfolioAllocationPalette.primaryBarGradient(
                        isDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<({String label, double percent, Color color})> _assetTypeSlices(
    List<ModelPortfolioHolding> items,
    bool isDark,
  ) {
    final map = <String, double>{};
    for (final h in items) {
      if (h.targetPercent <= 0) continue;
      final label = _assetCategoryLabel(h.assetType);
      map[label] = (map[label] ?? 0) + h.targetPercent;
    }
    return map.entries
        .map(
          (e) => (
            label: e.key,
            percent: e.value,
            color: PortfolioAllocationPalette.assetType(e.key, isDark),
          ),
        )
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  List<({String label, double percent})> _sectorSlices(
    List<ModelPortfolioHolding> items,
    PortfolioAllocationInsights insights,
  ) {
    final industryByTicker = {
      for (final d in insights.holdingData) d.ticker: d.industry,
    };

    final map = <String, double>{};
    for (final h in items) {
      if (h.targetPercent <= 0) continue;
      if (!ModelPortfolioHolding.isSearchableAsset(h.assetType)) {
        final label = _assetCategoryLabel(h.assetType);
        map[label] = (map[label] ?? 0) + h.targetPercent;
        continue;
      }

      final sector = h.sector?.trim();
      final industry = industryByTicker[h.ticker.trim().toUpperCase()];
      final label = (sector != null && sector.isNotEmpty)
          ? sector
          : (industry != null && industry.isNotEmpty ? industry : 'Other');
      map[label] = (map[label] ?? 0) + h.targetPercent;
    }

    return map.entries
        .map((e) => (label: e.key, percent: e.value))
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  List<({String label, double percent})> _countrySlices(
    List<ModelPortfolioHolding> items,
    PortfolioAllocationInsights insights,
  ) {
    final countryByTicker = {
      for (final d in insights.holdingData) d.ticker: d.country,
    };

    final map = <String, double>{};
    for (final h in items) {
      if (h.targetPercent <= 0) continue;
      String label = 'Other';
      if (ModelPortfolioHolding.isSearchableAsset(h.assetType)) {
        final country = countryByTicker[h.ticker.trim().toUpperCase()];
        label = (country != null && country.isNotEmpty) ? country : 'Other';
      } else {
        label = _assetCategoryLabel(h.assetType);
      }
      map[label] = (map[label] ?? 0) + h.targetPercent;
    }

    return map.entries
        .map((e) => (label: e.key, percent: e.value))
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  List<({String label, double percent})> _topHoldings(
    List<ModelPortfolioHolding> items,
  ) {
    final sorted = [...items]
      ..sort((a, b) => b.targetPercent.compareTo(a.targetPercent));
    return sorted
        .where((h) => h.targetPercent > 0)
        .take(5)
        .map((h) => (label: h.company ?? h.ticker, percent: h.targetPercent))
        .toList();
  }

  double _top5Concentration(List<ModelPortfolioHolding> items) {
    if (items.isEmpty) return 0;
    final sorted = [...items]
      ..sort((a, b) => b.targetPercent.compareTo(a.targetPercent));
    return sorted.take(5).fold<double>(0, (sum, h) => sum + h.targetPercent);
  }

  ({String label, double percent})? _largestPosition(
    List<ModelPortfolioHolding> items,
  ) {
    if (items.isEmpty) return null;
    final sorted = [...items]
      ..sort((a, b) => b.targetPercent.compareTo(a.targetPercent));
    final top = sorted.first;
    return (label: top.company ?? top.ticker, percent: top.targetPercent);
  }

  String _assetCategoryLabel(ModelAssetType type) {
    switch (type) {
      case ModelAssetType.stock:
      case ModelAssetType.etf:
        return 'Equity';
      case ModelAssetType.gold:
        return 'Gold';
      case ModelAssetType.bond:
        return 'Bonds';
      case ModelAssetType.reit:
        return 'Real Estate';
      case ModelAssetType.cash:
        return 'Cash';
      case ModelAssetType.commodity:
        return 'Commodity';
      case ModelAssetType.other:
        return 'Other';
    }
  }

  String _formatVolume(num value) {
    return FinnhubDisplayFormatters.formatCompactCurrency(value)
        .replaceAll('\$', '');
  }
}
