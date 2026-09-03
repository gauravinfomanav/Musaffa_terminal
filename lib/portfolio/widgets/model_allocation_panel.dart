import 'package:flutter/material.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
import 'package:musaffa_terminal/portfolio/utils/portfolio_allocation_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Compact allocation summary for the builder sidebar — ticker-detail bar style.
class ModelAllocationPanel extends StatelessWidget {
  const ModelAllocationPanel({
    super.key,
    required this.isDark,
    required this.holdings,
    required this.totalPercent,
  });

  final bool isDark;
  final List<ModelPortfolioHolding> holdings;
  final double totalPercent;

  @override
  Widget build(BuildContext context) {
    final remaining = allocationRemainingPercent(totalPercent);
    final isValid = isAllocationBalanced(totalPercent) && holdings.isNotEmpty;
    final isOver = isAllocationOver(totalPercent);
    final overBy = allocationOverPercent(totalPercent);

    final status = _statusMeta(
      isDark: isDark,
      isValid: isValid,
      isOver: isOver,
      holdingsEmpty: holdings.isEmpty,
      remaining: remaining,
      overBy: overBy,
    );

    final assetSlices = _assetTypeSlices(holdings, isDark);
    final sectorSlices = _sectorSlices(holdings);
    final largest = _largestPosition(holdings);
    final progress = isValid
        ? 1.0
        : (totalPercent / 100).clamp(0.0, 1.05);

    return DecoratedBox(
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allocation Summary',
                        style: HomeUi.sectionTitle(isDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progress toward 100% strategy weight',
                        style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _statusBadge(isDark, status),
              ],
            ),
          ),
          Expanded(
            child: holdings.isEmpty
                ? _buildEmptyBody(isDark)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AllocationPremiumCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'STRATEGY WEIGHT',
                                style: _overline(isDark),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text('0%', style: _rangeLabel(isDark)),
                                  const Spacer(),
                                  Text(
                                    formatAllocationPercent(totalPercent),
                                    style: TextStyle(
                                      fontFamily: Constants.FONT_DEFAULT_NEW,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      height: 1,
                                      color: isOver
                                          ? HomeUi.negative(isDark)
                                          : isValid
                                              ? HomeUi.positive(isDark)
                                              : HomeUi.title(isDark),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text('100%', style: _rangeLabel(isDark)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _AllocationProgressBar(
                                isDark: isDark,
                                progress: progress,
                                isOver: isOver,
                                isValid: isValid,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isOver
                                    ? 'Over target by ${formatAllocationPercent(overBy)}'
                                    : isValid
                                        ? 'Fully allocated — ready to publish'
                                        : '${formatAllocationPercent(remaining)} remaining to reach 100%',
                                style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _AllocationStatTile(
                                      isDark: isDark,
                                      label: 'Allocated',
                                      value: formatAllocationPercent(totalPercent),
                                      valueColor: isValid
                                          ? HomeUi.positive(isDark)
                                          : (isOver
                                              ? HomeUi.negative(isDark)
                                              : null),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _AllocationStatTile(
                                      isDark: isDark,
                                      label: 'Remaining',
                                      value: isOver
                                          ? '0%'
                                          : formatAllocationPercent(remaining),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _AllocationStatTile(
                                      isDark: isDark,
                                      label: 'Holdings',
                                      value: '${holdings.length}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (largest != null) ...[
                          const SizedBox(height: 10),
                          _AllocationPremiumCard(
                            isDark: isDark,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: HomeUi.accent(isDark),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'LARGEST HOLDING',
                                        style: _overline(isDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        largest.label,
                                        style: HomeUi.control(isDark).copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatAllocationPercent(largest.percent),
                                  style: HomeUi.control(isDark).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: HomeUi.accent(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (assetSlices.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _AllocationPremiumCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('COMPOSITION', style: _overline(isDark)),
                                const SizedBox(height: 12),
                                _StackedAllocationBar(
                                  isDark: isDark,
                                  slices: assetSlices.take(5).toList(),
                                ),
                                const SizedBox(height: 12),
                                for (var i = 0; i < assetSlices.take(4).length; i++) ...[
                                  if (i > 0) const SizedBox(height: 8),
                                  _CompositionLegendRow(
                                    isDark: isDark,
                                    label: assetSlices[i].label,
                                    percent: assetSlices[i].percent,
                                    color: assetSlices[i].color,
                                  ),
                                ],
                                if (sectorSlices.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Divider(
                                    height: 1,
                                    color: HomeUi.borderLight(isDark),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'TOP SECTOR',
                                    style: _overline(isDark),
                                  ),
                                  const SizedBox(height: 8),
                                  _CompositionLegendRow(
                                    isDark: isDark,
                                    label: sectorSlices.first.label,
                                    percent: sectorSlices.first.percent,
                                    color: PortfolioAllocationPalette.sectorColor(
                                      sectorSlices.first.label,
                                      isDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'Full market profile & exposure → Portfolio Analytics',
                          style: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          _buildStatusBanner(isDark, status),
        ],
      ),
    );
  }

  TextStyle _overline(bool isDark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: isDark ? const Color(0xFF8B8FA3) : const Color(0xFF9CA3AF),
      );

  TextStyle _rangeLabel(bool isDark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF8B8FA3) : const Color(0xFF6B7280),
      );

  Widget _buildEmptyBody(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: HomeUi.muted(isDark)),
            const SizedBox(height: 12),
            Text('No allocation yet', style: HomeUi.sectionTitle(isDark)),
            const SizedBox(height: 6),
            Text(
              'Add assets to track progress toward 100%.',
              style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    bool isDark,
    ({Color color, String label, String text, bool showCheck}) status,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: HomeUi.borderLight(isDark))),
      ),
      child: Row(
        children: [
          Icon(
            status.showCheck
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 16,
            color: status.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.text,
              style: HomeUi.control(isDark).copyWith(
                color: status.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    bool isDark,
    ({Color color, String label, String text, bool showCheck}) status,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: HomeUi.control(isDark).copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  ({
    Color color,
    String label,
    String text,
    bool showCheck,
  }) _statusMeta({
    required bool isDark,
    required bool isValid,
    required bool isOver,
    required bool holdingsEmpty,
    required double remaining,
    required double overBy,
  }) {
    if (isOver) {
      return (
        color: HomeUi.negative(isDark),
        label: 'Over-allocated',
        text: 'Over by ${formatAllocationPercent(overBy)} — reduce weights',
        showCheck: false,
      );
    }
    if (isValid) {
      return (
        color: HomeUi.positive(isDark),
        label: 'Balanced',
        text: 'Ready to publish',
        showCheck: true,
      );
    }
    if (holdingsEmpty) {
      return (
        color: HomeUi.muted(isDark),
        label: 'Empty',
        text: 'Add assets to begin',
        showCheck: false,
      );
    }
    return (
      color: const Color(0xFFD97706),
      label: 'Incomplete',
      text: '${formatAllocationPercent(remaining)} left to allocate',
      showCheck: false,
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
  ) {
    final map = <String, double>{};
    for (final h in items) {
      if (h.targetPercent <= 0) continue;
      if (!ModelPortfolioHolding.isSearchableAsset(h.assetType)) continue;
      final sector = h.sector?.trim();
      if (sector == null || sector.isEmpty) continue;
      map[sector] = (map[sector] ?? 0) + h.targetPercent;
    }
    return map.entries
        .map((e) => (label: e.key, percent: e.value))
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
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

  ({String label, double percent})? _largestPosition(
    List<ModelPortfolioHolding> items,
  ) {
    if (items.isEmpty) return null;
    final sorted = [...items]
      ..sort((a, b) => b.targetPercent.compareTo(a.targetPercent));
    final top = sorted.first;
    return (label: top.company ?? top.ticker, percent: top.targetPercent);
  }
}

class _AllocationPremiumCard extends StatelessWidget {
  const _AllocationPremiumCard({
    required this.isDark,
    required this.child,
  });

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1D2E), const Color(0xFF151822)]
              : [const Color(0xFFF9FAFB), const Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2D3E).withValues(alpha: 0.8)
              : const Color(0xFFE5E7EB).withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF6366F1).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _AllocationStatTile extends StatelessWidget {
  const _AllocationStatTile({
    required this.isDark,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12151F).withValues(alpha: 0.55)
            : const Color(0xFFF3F4F6).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2D3E).withValues(alpha: 0.6)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF8B8FA3) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.05,
              color: valueColor ?? HomeUi.title(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// 52-week range style progress bar from ticker detail.
class _AllocationProgressBar extends StatelessWidget {
  const _AllocationProgressBar({
    required this.isDark,
    required this.progress,
    required this.isOver,
    required this.isValid,
  });

  final bool isDark;
  final double progress;
  final bool isOver;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final fillGradient = isOver
        ? LinearGradient(
            colors: [
              HomeUi.negative(isDark).withValues(alpha: 0.5),
              HomeUi.negative(isDark),
            ],
          )
        : isValid
            ? LinearGradient(
                colors: [
                  HomeUi.positive(isDark).withValues(alpha: 0.55),
                  HomeUi.positive(isDark),
                ],
              )
            : HomeUi.iconFillGradient;

    final markerColor = isOver
        ? HomeUi.negative(isDark)
        : isValid
            ? HomeUi.positive(isDark)
            : const Color(0xFFE4621E);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumb = (t * width).clamp(6.0, width - 6);

        return SizedBox(
          height: 14,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2D3E)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                ),
              ),
              if (t > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: (t * width).clamp(4.0, width),
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: fillGradient,
                      borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                    ),
                  ),
                ),
              Positioned(
                left: thumb - 7,
                top: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: markerColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: markerColor.withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StackedAllocationBar extends StatelessWidget {
  const _StackedAllocationBar({
    required this.isDark,
    required this.slices,
  });

  final bool isDark;
  final List<({String label, double percent, Color color})> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const SizedBox.shrink();

    final total = slices.fold<double>(0, (s, e) => s + e.percent);
    if (total <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(HomeUi.radiusPill),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (var i = 0; i < slices.length; i++)
              Expanded(
                flex: (slices[i].percent * 100).round().clamp(1, 1000),
                child: Container(
                  color: slices[i].color,
                  height: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompositionLegendRow extends StatelessWidget {
  const _CompositionLegendRow({
    required this.isDark,
    required this.label,
    required this.percent,
    required this.color,
  });

  final bool isDark;
  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (percent / 100).clamp(0.0, 1.0);
    final barWidth = percent > 0 ? fraction.clamp(0.04, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
                style: HomeUi.control(isDark).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(
                  color: isDark
                      ? const Color(0xFF2A2D3E)
                      : const Color(0xFFE5E7EB),
                ),
                FractionallySizedBox(
                  widthFactor: barWidth,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.65),
                          color,
                        ],
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
}
