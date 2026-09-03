import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/services/model_portfolio_enrichment.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
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
    SimpleColumn(label: 'ASSET TYPE', fieldName: 'asset_type', width: 100),
    SimpleColumn(label: 'SECTOR', fieldName: 'sector', width: 120),
    SimpleColumn(
      label: 'PRICE',
      fieldName: 'price',
      width: 100,
      isNumeric: true,
    ),
    SimpleColumn(
      label: 'ALLOCATION %',
      fieldName: 'target_pct',
      width: 110,
      isNumeric: true,
    ),
    SimpleColumn(
      label: 'MKT CAP',
      fieldName: 'market_cap',
      width: 100,
      isNumeric: true,
    ),
    SimpleColumn(label: 'CONV.', fieldName: 'conviction', width: 80),
    SimpleColumn(label: 'STATUS', fieldName: 'status', width: 80),
    SimpleColumn(label: 'ACTIONS', fieldName: 'actions', width: 72),
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
          _buildPanelHeader(widget.isDark),
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
                      columnSpacing: 24,
                      horizontalMargin: 16,
                      fixedColumnWidth: 220,
                      headerHeight: 44,
                      rowHeight: 52,
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

  Widget _buildPanelHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.table_chart_rounded,
            size: 20,
            color: HomeUi.accent(isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Holdings (${widget.holdings.length})',
                  style: HomeUi.sectionTitle(isDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Define allocation weights for each asset in your model portfolio.',
                  style: HomeUi.subtitle(isDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildToolbar(isDark),
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
        color: isDark ? const Color(0xFF2A2D33) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F47) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Icon(
        CupertinoIcons.square_stack_3d_up,
        size: 30,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
          'asset_type': h.assetType.label,
          'sector': sector?.trim().isNotEmpty == true ? sector! : '—',
          'price': price != null ? '\$${price.toStringAsFixed(2)}' : '—',
          'target_pct': InlineTargetPercentCell(
            isDark: widget.isDark,
            value: h.targetPercent,
            onChanged: (value) => widget.onTargetPercentChanged?.call(h, value),
          ),
          'market_cap': _formatMarketCap(h, marketCap),
          'conviction': h.conviction.label,
          'status': h.status,
          'actions': _buildActions(context, h),
        },
      );
    }).toList();
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
    final isBalanced =
        isAllocationBalanced(total) && widget.holdings.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: HomeUi.borderLight(isDark))),
        color: HomeUi.cardBg(isDark),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showTipInline = constraints.maxWidth > 480;
          return Row(
            children: [
              Text(
                'Total',
                style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                formatAllocationPercent(total),
                style: HomeUi.control(isDark).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isBalanced
                      ? const Color(0xFF059669)
                      : (widget.holdings.isEmpty
                          ? HomeUi.muted(isDark)
                          : const Color(0xFFD97706)),
                ),
              ),
              if (showTipInline) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Tip: Edit allocation % in the table; total must equal 100% before publishing.',
                    style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, ModelPortfolioHolding h) {
    final isDark = widget.isDark;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: HomeUi.muted(isDark)),
      color: HomeUi.cardBg(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        side: BorderSide(color: HomeUi.borderLight(isDark)),
      ),
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
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: HomeUi.actionMenuItem(
            dark: isDark,
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
        ),
        PopupMenuItem(
          value: 'replace',
          child: HomeUi.actionMenuItem(
            dark: isDark,
            icon: Icons.swap_horiz_rounded,
            label: 'Replace',
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: HomeUi.actionMenuItem(
            dark: isDark,
            icon: Icons.delete_outline_rounded,
            label: 'Remove',
            destructive: true,
          ),
        ),
      ],
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
