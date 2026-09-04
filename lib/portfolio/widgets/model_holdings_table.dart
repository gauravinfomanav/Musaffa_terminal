import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/services/model_portfolio_enrichment.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
import 'package:musaffa_terminal/portfolio/utils/portfolio_allocation_palette.dart';
import 'package:musaffa_terminal/portfolio/widgets/inline_target_percent_cell.dart';
import 'package:musaffa_terminal/services/company_enrichment_cache.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class ModelHoldingsTable extends StatefulWidget {
  const ModelHoldingsTable({
    super.key,
    required this.isDark,
    required this.holdings,
    required this.onEdit,
    required this.onRemove,
    required this.onReplace,
    this.onOpenScreener,
    this.onAddAsset,
    this.totalPercent,
    this.onTargetPercentChanged,
    this.onEnrichmentComplete,
  });

  final bool isDark;
  final List<ModelPortfolioHolding> holdings;
  final void Function(ModelPortfolioHolding holding) onEdit;
  final void Function(ModelPortfolioHolding holding) onRemove;
  final void Function(ModelPortfolioHolding holding) onReplace;
  final VoidCallback? onOpenScreener;
  final VoidCallback? onAddAsset;
  final double? totalPercent;
  final void Function(ModelPortfolioHolding holding, double percent)?
      onTargetPercentChanged;
  final VoidCallback? onEnrichmentComplete;

  static const _columns = [
    SimpleColumn(label: 'ASSET TYPE', fieldName: 'asset_type', width: 132),
    SimpleColumn(label: 'SECTOR', fieldName: 'sector', width: 200),
    SimpleColumn(
      label: 'PRICE',
      fieldName: 'price',
      width: 96,
      isNumeric: true,
    ),
    SimpleColumn(
      label: 'ALLOCATION %',
      fieldName: 'target_pct',
      width: 118,
      isNumeric: true,
    ),
    SimpleColumn(
      label: 'MKT CAP',
      fieldName: 'market_cap',
      width: 100,
      isNumeric: true,
    ),
    SimpleColumn(label: 'CONV.', fieldName: 'conviction', width: 108),
    SimpleColumn(label: 'STATUS', fieldName: 'status', width: 108),
    SimpleColumn(label: 'ACTIONS', fieldName: 'actions', width: 64),
  ];

  @override
  State<ModelHoldingsTable> createState() => _ModelHoldingsTableState();
}

class _ModelHoldingsTableState extends State<ModelHoldingsTable> {
  Object? _enrichToken;

  @override
  void initState() {
    super.initState();
    _enrichHoldings();
  }

  @override
  void didUpdateWidget(covariant ModelHoldingsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameTickers(oldWidget.holdings, widget.holdings)) {
      _enrichHoldings();
    }
  }

  bool _sameTickers(
    List<ModelPortfolioHolding> a,
    List<ModelPortfolioHolding> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].ticker.toUpperCase() != b[i].ticker.toUpperCase()) return false;
    }
    return true;
  }

  Future<void> _enrichHoldings() async {
    if (widget.holdings.isEmpty) return;
    final token = Object();
    _enrichToken = token;
    await enrichModelPortfolioHoldings(widget.holdings);
    if (!mounted || _enrichToken != token) return;
    setState(() {});
    widget.onEnrichmentComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalPercent ??
        widget.holdings.fold<double>(0, (sum, h) => sum + h.targetPercent);

    return Container(
      decoration: HomeUi.cardDecoration(widget.isDark),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader(widget.isDark, total),
          Expanded(
            child: widget.holdings.isEmpty
                ? _buildEmptyBody(widget.isDark)
                : SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: DynamicTable(
                      columns: ModelHoldingsTable._columns,
                      rows: _buildRows(context),
                      showFixedColumn: true,
                      considerPadding: false,
                      showOuterShadow: false,
                      columnSpacing: 20,
                      horizontalMargin: 16,
                      fixedColumnWidth: 228,
                      headerHeight: 42,
                      rowHeight: 56,
                      enableLivePrices: false,
                      zebraStripes: true,
                      enableColumnCustomization: false,
                      tickerHeaderLabel: 'COMPANY / ASSET',
                      tableId: 'model_portfolio_holdings',
                    ),
                  ),
          ),
          _buildFooter(widget.isDark, total),
        ],
      ),
    );
  }

  Widget _buildPanelHeader(bool isDark, double total) {
    final isBalanced =
        isAllocationBalanced(total) && widget.holdings.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: HomeUi.borderLight(isDark)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: HomeUi.tableToolbarHeader(
                  isDark,
                  title: 'Holdings (${widget.holdings.length})',
                  subtitleText: compact
                      ? 'Set allocation weights for each asset.'
                      : 'Define allocation weights for each asset in your model portfolio.',
                  icon: Icons.table_chart_rounded,
                ),
              ),
              if (widget.holdings.isNotEmpty) ...[
                const SizedBox(width: 8),
                _allocationBadge(isDark, total, isBalanced),
              ],
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _buildToolbar(isDark),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _allocationBadge(bool isDark, double total, bool isBalanced) {
    final color = isBalanced
        ? HomeUi.positive(isDark)
        : (widget.holdings.isEmpty
            ? HomeUi.muted(isDark)
            : const Color(0xFFD97706));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBalanced
                ? Icons.check_circle_rounded
                : Icons.pie_chart_outline_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            formatAllocationPercent(total),
            style: HomeUi.control(isDark).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBody(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyIcon(isDark),
            const SizedBox(height: 16),
            Text('No holdings yet', style: HomeUi.sectionTitle(isDark)),
            const SizedBox(height: 6),
            Text(
              'Search for listed assets or add cash, real estate, and more.',
              style: HomeUi.subtitle(isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.onOpenScreener != null)
                  HomeUi.ghostAction(
                    label: 'Open Screener',
                    icon: Icons.tune_rounded,
                    dark: isDark,
                    onTap: widget.onOpenScreener,
                  ),
                if (widget.onAddAsset != null)
                  HomeUi.primaryAction(
                    label: 'Add Asset',
                    icon: Icons.add_rounded,
                    onTap: widget.onAddAsset!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyIcon(bool isDark) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: HomeUi.softBrandWellGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Icon(
        CupertinoIcons.square_stack_3d_up,
        size: 30,
        color: HomeUi.accent(isDark),
      ),
    );
  }

  List<SimpleRowModel> _buildRows(BuildContext context) {
    return widget.holdings.map((h) {
      final enrichment = CompanyEnrichmentCache.getCached(h.ticker);
      final logo = h.tickerModel?.logo ?? enrichment?.logo;
      final sector = h.sector ?? enrichment?.sector;
      final isEtf = h.assetType.name == 'etf' || h.tickerModel?.isStock == false;
      final price = h.currentPrice ?? enrichment?.currentPrice?.toDouble();
      final marketCap = isEtf
          ? (h.marketCap ?? enrichment?.aum?.toDouble())
          : (h.marketCap ?? enrichment?.marketCap?.toDouble());

      return SimpleRowModel(
        symbol: h.ticker,
        name: h.company ?? enrichment?.name ?? h.ticker,
        logo: logo,
        fields: {
          'asset_type': _assetTypeChip(widget.isDark, h.assetType),
          'sector': _sectorCell(widget.isDark, sector),
          'price': price != null ? '\$${price.toStringAsFixed(2)}' : '—',
          'target_pct': InlineTargetPercentCell(
            isDark: widget.isDark,
            value: h.targetPercent,
            onChanged: (value) => widget.onTargetPercentChanged?.call(h, value),
          ),
          'market_cap': _formatMarketCap(h, marketCap),
          'conviction': _convictionChip(widget.isDark, h.conviction),
          'status': _statusChip(widget.isDark, h.status),
          'actions': _buildActions(context, h),
        },
      );
    }).toList();
  }

  Widget _sectorCell(bool isDark, String? sector) {
    final label = sector?.trim().isNotEmpty == true ? sector!.trim() : '—';
    if (label == '—') {
      return Text(
        '—',
        style: HomeUi.control(isDark).copyWith(
          color: HomeUi.muted(isDark),
          fontSize: 12.5,
        ),
      );
    }
    return Text(
      label,
      softWrap: false,
      style: HomeUi.control(isDark, active: true).copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _pillBadge({
    required bool isDark,
    required String label,
    required Color foreground,
    required Color background,
    bool allowTruncate = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(
          color: foreground.withValues(alpha: isDark ? 0.32 : 0.26),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: allowTruncate ? TextOverflow.ellipsis : TextOverflow.visible,
        style: HomeUi.control(isDark, active: true).copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: foreground,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _assetTypeChip(bool isDark, ModelAssetType type) {
    final color = PortfolioAllocationPalette.forModelAssetType(type, isDark);
    return _pillBadge(
      isDark: isDark,
      label: type.label,
      foreground: color,
      background: PortfolioAllocationPalette.softFill(color, isDark),
    );
  }

  Widget _convictionChip(bool isDark, ModelConviction conviction) {
    final color = PortfolioAllocationPalette.conviction(conviction, isDark);
    return _pillBadge(
      isDark: isDark,
      label: conviction.label,
      foreground: color,
      background: PortfolioAllocationPalette.convictionSoft(conviction, isDark),
    );
  }

  /// Soft status pill — Active uses positiveSoft like other portfolio badges.
  Widget _statusChip(bool isDark, String status) {
    final lower = status.toLowerCase();
    final Color foreground;
    final Color background;

    if (lower.contains('active') || lower.contains('published')) {
      foreground = HomeUi.positive(isDark);
      background = HomeUi.positiveSoft(isDark);
    } else if (lower.contains('review') || lower.contains('draft')) {
      foreground = const Color(0xFFD97706);
      background = PortfolioAllocationPalette.softFill(foreground, isDark);
    } else if (lower.contains('archiv') || lower.contains('inactive')) {
      foreground = HomeUi.muted(isDark);
      background = HomeUi.elevatedBg(isDark);
    } else {
      foreground = const Color(0xFF2563EB);
      background = PortfolioAllocationPalette.softFill(foreground, isDark);
    }

    return _pillBadge(
      isDark: isDark,
      label: status,
      foreground: foreground,
      background: background,
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onOpenScreener != null) ...[
          HomeUi.ghostAction(
            label: 'Open Screener',
            icon: Icons.tune_rounded,
            dark: isDark,
            onTap: widget.onOpenScreener,
          ),
          const SizedBox(width: 8),
        ],
        if (widget.onAddAsset != null)
          HomeUi.primaryAction(
            label: 'Add Asset',
            icon: Icons.add_rounded,
            onTap: widget.onAddAsset!,
          ),
      ],
    );
  }

  Widget _buildFooter(bool isDark, double total) {
    // Empty portfolio already has Add Asset CTAs in the toolbar + empty body.
    if (widget.holdings.isEmpty) {
      return const SizedBox.shrink();
    }

    final isBalanced = isAllocationBalanced(total);
    final isOver = isAllocationOver(total);
    final remaining = allocationRemainingPercent(total);
    final progress = (total / 100.0).clamp(0.0, 1.0);

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;
    if (isOver) {
      statusColor = HomeUi.negative(isDark);
      statusLabel = 'Over';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isBalanced) {
      statusColor = HomeUi.positive(isDark);
      statusLabel = 'Balanced';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFD97706);
      statusLabel = 'Incomplete';
      statusIcon = Icons.pie_chart_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: HomeUi.borderLight(isDark))),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(HomeUi.radiusCard),
          bottomRight: Radius.circular(HomeUi.radiusCard),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    statusColor.withValues(alpha: 0.10),
                    const Color(0xFF171A24),
                  ),
                  const Color(0xFF141720),
                ]
              : [
                  Color.alphaBlend(
                    statusColor.withValues(alpha: 0.05),
                    const Color(0xFFFCFCFD),
                  ),
                  const Color(0xFFF8F9FB),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ALLOCATION',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontFamilyFallback: Constants.FONT_FALLBACK,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: HomeUi.muted(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatAllocationPercent(total),
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontFamilyFallback: Constants.FONT_FALLBACK,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ 100%',
                          style: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _footerStatusPill(
                isDark: isDark,
                color: statusColor,
                label: statusLabel,
                icon: statusIcon,
              ),
              if (!isBalanced && !isOver) ...[
                const SizedBox(width: 8),
                _footerMetaChip(
                  isDark: isDark,
                  label: '${formatAllocationPercent(remaining)} left',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _footerProgressBar(
            isDark: isDark,
            progress: progress,
            color: statusColor,
            isOver: isOver,
            isBalanced: isBalanced,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: HomeUi.muted(isDark),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isBalanced
                      ? 'Allocation is balanced — ready to publish'
                      : isOver
                          ? 'Reduce weights so total equals 100%'
                          : 'Edit allocation % in the table · must equal 100% to publish',
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerStatusPill({
    required bool isDark,
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: HomeUi.control(isDark).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerMetaChip({
    required bool isDark,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? HomeUi.elevatedBg(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Text(
        label,
        style: HomeUi.control(isDark).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _footerProgressBar({
    required bool isDark,
    required double progress,
    required Color color,
    required bool isOver,
    required bool isBalanced,
  }) {
    final t = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 10,
          width: width,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2D3E)
                      : const Color(0xFFE8EAED),
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                ),
              ),
              if (t > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: (t * width).clamp(6.0, width),
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOver
                          ? [
                              color.withValues(alpha: 0.55),
                              color,
                            ]
                          : isBalanced
                              ? [
                                  color.withValues(alpha: 0.6),
                                  color,
                                ]
                              : [
                                  Color.lerp(color, Colors.white, 0.25)!,
                                  color,
                                ],
                    ),
                    borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, ModelPortfolioHolding h) {
    final isDark = widget.isDark;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: HomeUi.muted(isDark)),
      color: HomeUi.cardBg(isDark),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        side: BorderSide(color: HomeUi.borderLight(isDark)),
      ),
      offset: const Offset(0, 8),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          height: 44,
          child: HomeUi.actionMenuItem(
            dark: isDark,
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
        ),
        PopupMenuItem(
          value: 'replace',
          height: 44,
          child: HomeUi.actionMenuItem(
            dark: isDark,
            icon: Icons.swap_horiz_rounded,
            label: 'Replace',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'remove',
          height: 44,
          child: HomeUi.actionMenuItem(
            dark: isDark,
            icon: Icons.delete_outline_rounded,
            label: 'Remove',
            destructive: true,
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            widget.onEdit(h);
            break;
          case 'remove':
            widget.onRemove(h);
            break;
          case 'replace':
            widget.onReplace(h);
            break;
        }
      },
    );
  }

  String _formatMarketCap(ModelPortfolioHolding holding, double? value) {
    if (value == null || value <= 0) return '—';
    if (holding.assetType.name == 'etf' || holding.tickerModel?.isStock == false) {
      final formatted = Constants.getShortenedMarketCapV2(value);
      return formatted == '-' ? '—' : formatted;
    }
    final formatted = Constants.formatMarketCapFromMillions(value);
    return formatted == '-' ? '—' : formatted;
  }
}
