import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Dialog for adding an asset to a model portfolio (search, screener, or manual).
class AddToPortfolioDialog extends StatefulWidget {
  const AddToPortfolioDialog({
    super.key,
    this.ticker,
    this.tickerModel,
    this.replaceTicker,
  })  : isManualAsset = false,
        presetAssetType = null,
        defaultName = null,
        existingHoldings = const [];

  const AddToPortfolioDialog.manual({
    super.key,
    required this.presetAssetType,
    required this.defaultName,
    this.existingHoldings = const [],
    this.replaceTicker,
  })  : isManualAsset = true,
        ticker = null,
        tickerModel = null;

  final String? ticker;
  final TickerModel? tickerModel;
  final String? replaceTicker;
  final bool isManualAsset;
  final ModelAssetType? presetAssetType;
  final String? defaultName;
  final List<ModelPortfolioHolding> existingHoldings;

  @override
  State<AddToPortfolioDialog> createState() => _AddToPortfolioDialogState();
}

class _AddToPortfolioDialogState extends State<AddToPortfolioDialog> {
  final _percentController = TextEditingController(text: '0');
  final _thesisController = TextEditingController();
  final _riskController = TextEditingController();
  late final TextEditingController _nameController;
  late ModelAssetType _assetType;
  ModelConviction _conviction = ModelConviction.medium;

  @override
  void initState() {
    super.initState();
    if (widget.isManualAsset) {
      _assetType = widget.presetAssetType ?? ModelAssetType.other;
      _nameController = TextEditingController(text: widget.defaultName ?? 'Asset');
    } else {
      _assetType = widget.tickerModel?.isStock == false
          ? ModelAssetType.etf
          : ModelAssetType.stock;
      _nameController = TextEditingController(
        text: widget.tickerModel?.companyName ??
            widget.tickerModel?.name ??
            widget.ticker ??
            '',
      );
    }
  }

  @override
  void dispose() {
    _percentController.dispose();
    _thesisController.dispose();
    _riskController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = widget.tickerModel?.symbol ??
        widget.tickerModel?.ticker ??
        widget.ticker ??
        '';
    final title = widget.replaceTicker != null
        ? 'Replace Holding'
        : widget.isManualAsset
            ? 'Add ${_assetType.label}'
            : 'Add to Portfolio';

    return AlertDialog(
      backgroundColor: HomeUi.cardBg(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        side: BorderSide(color: HomeUi.borderLight(isDark)),
      ),
      title: Text(title, style: HomeUi.sectionTitle(isDark)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isManualAsset) ...[
                _assetTypeChip(isDark),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  decoration: HomeUi.filterFieldDecoration(
                    isDark,
                    labelText: 'Asset Name',
                  ),
                ),
              ] else if (symbol.isNotEmpty) ...[
                Text(symbol,
                    style: HomeUi.heading(isDark).copyWith(fontSize: 18)),
              ],
              if (widget.replaceTicker != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Replacing ${widget.replaceTicker}',
                  style: HomeUi.subtitle(isDark),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _percentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: HomeUi.filterFieldDecoration(
                  isDark,
                  labelText: 'Allocation %',
                ),
              ),
              if (!widget.isManualAsset) ...[
                const SizedBox(height: 12),
                _dropdown<ModelAssetType>(
                  isDark,
                  'Asset Category',
                  _assetType,
                  ModelAssetType.values,
                  (v) => v.label,
                  (v) => setState(() => _assetType = v),
                ),
              ],
              const SizedBox(height: 12),
              _dropdown<ModelConviction>(
                isDark,
                'Conviction',
                _conviction,
                ModelConviction.values,
                (v) => v.label,
                (v) => setState(() => _conviction = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _thesisController,
                maxLines: 3,
                decoration: HomeUi.filterFieldDecoration(
                  isDark,
                  labelText: 'Investment Thesis',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _riskController,
                maxLines: 2,
                decoration: HomeUi.filterFieldDecoration(
                  isDark,
                  labelText: 'Risk Notes',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        HomeUi.ghostAction(
          label: 'Cancel',
          dark: isDark,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        HomeUi.primaryAction(
          label: widget.replaceTicker != null ? 'Replace' : 'Add to Draft',
          onTap: () {
            final pct = double.tryParse(_percentController.text.trim()) ?? 0;
            if (pct <= 0) return;

            final displayName = _nameController.text.trim();
            if (widget.isManualAsset && displayName.isEmpty) return;

            final ticker = widget.isManualAsset
                ? ModelPortfolioHolding.manualTickerFor(
                    _assetType,
                    displayName,
                    widget.existingHoldings,
                  )
                : symbol;
            if (ticker.isEmpty) return;

            final holding = ModelPortfolioHolding(
              ticker: ticker,
              company: displayName.isNotEmpty ? displayName : ticker,
              assetType: _assetType,
              targetPercent: pct,
              conviction: _conviction,
              investmentThesis: _thesisController.text.trim().isEmpty
                  ? null
                  : _thesisController.text.trim(),
              riskNotes: _riskController.text.trim().isEmpty
                  ? null
                  : _riskController.text.trim(),
            );
            if (widget.tickerModel != null) {
              holding.applyTicker(widget.tickerModel!);
            }
            Navigator.pop(context, holding);
          },
        ),
      ],
    );
  }

  Widget _assetTypeChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, size: 16, color: HomeUi.accent(isDark)),
          const SizedBox(width: 8),
          Text(
            _assetType.label,
            style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(
    bool isDark,
    String label,
    T value,
    List<T> items,
    String Function(T) itemLabel,
    void Function(T) onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: HomeUi.filterFieldDecoration(isDark, labelText: label),
      dropdownColor: HomeUi.cardBg(isDark),
      items: items
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(itemLabel(v), style: HomeUi.control(isDark)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
