import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.initialHolding,
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
    this.initialHolding,
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
  final ModelPortfolioHolding? initialHolding;

  static Future<ModelPortfolioHolding?> show({
    required BuildContext context,
    String? ticker,
    TickerModel? tickerModel,
    String? replaceTicker,
    ModelPortfolioHolding? initialHolding,
  }) {
    return _present(
      context: context,
      barrierLabel: replaceTicker != null ? 'Replace Holding' : 'Add to Portfolio',
      child: AddToPortfolioDialog(
        ticker: ticker,
        tickerModel: tickerModel,
        replaceTicker: replaceTicker,
        initialHolding: initialHolding,
      ),
    );
  }

  static Future<ModelPortfolioHolding?> showManual({
    required BuildContext context,
    required ModelAssetType presetAssetType,
    required String defaultName,
    List<ModelPortfolioHolding> existingHoldings = const [],
    String? replaceTicker,
    ModelPortfolioHolding? initialHolding,
  }) {
    return _present(
      context: context,
      barrierLabel: 'Add ${presetAssetType.label}',
      child: AddToPortfolioDialog.manual(
        presetAssetType: presetAssetType,
        defaultName: defaultName,
        existingHoldings: existingHoldings,
        replaceTicker: replaceTicker,
        initialHolding: initialHolding,
      ),
    );
  }

  static Future<ModelPortfolioHolding?> _present({
    required BuildContext context,
    required String barrierLabel,
    required Widget child,
  }) {
    return showGeneralDialog<ModelPortfolioHolding>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.018),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<AddToPortfolioDialog> createState() => _AddToPortfolioDialogState();
}

class _AddToPortfolioDialogState extends State<AddToPortfolioDialog> {
  late final TextEditingController _percentController;
  late final TextEditingController _thesisController;
  late final TextEditingController _riskController;
  late final TextEditingController _nameController;
  late ModelAssetType _assetType;
  late ModelConviction _conviction;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialHolding;

    if (widget.isManualAsset) {
      _assetType = seed?.assetType ??
          widget.presetAssetType ??
          ModelAssetType.other;
      _nameController = TextEditingController(
        text: seed?.company ?? widget.defaultName ?? 'Asset',
      );
    } else {
      _assetType = seed?.assetType ??
          (widget.tickerModel?.isStock == false
              ? ModelAssetType.etf
              : ModelAssetType.stock);
      _nameController = TextEditingController(
        text: seed?.company ??
            widget.tickerModel?.companyName ??
            widget.tickerModel?.name ??
            widget.ticker ??
            '',
      );
    }

    final pct = seed?.targetPercent;
    _percentController = TextEditingController(
      text: pct != null && pct > 0 ? _formatPercent(pct) : '0',
    );
    _thesisController =
        TextEditingController(text: seed?.investmentThesis ?? '');
    _riskController = TextEditingController(text: seed?.riskNotes ?? '');
    _conviction = seed?.conviction ?? ModelConviction.medium;
  }

  String _formatPercent(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _percentController.dispose();
    _thesisController.dispose();
    _riskController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _symbol =>
      widget.tickerModel?.symbol ??
      widget.tickerModel?.ticker ??
      widget.ticker ??
      '';

  String get _title {
    if (widget.replaceTicker != null) return 'Replace Holding';
    if (widget.isManualAsset) return 'Add ${_assetType.label}';
    if (widget.initialHolding != null) return 'Edit Holding';
    return 'Add to Portfolio';
  }

  String get _subtitle {
    if (widget.replaceTicker != null) {
      return 'Replacing ${widget.replaceTicker}';
    }
    if (widget.isManualAsset) {
      return _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : _assetType.label;
    }
    if (_symbol.isNotEmpty) return _symbol;
    return 'Set allocation and conviction for this holding';
  }

  void _submit() {
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
        : _symbol;
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryLabel = widget.replaceTicker != null
        ? 'Replace'
        : widget.initialHolding != null
            ? 'Save Changes'
            : 'Add to Draft';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: widget.replaceTicker != null
                          ? Icons.swap_horiz_rounded
                          : Icons.pie_chart_outline_rounded,
                      title: _title,
                      subtitleText: _subtitle,
                    ),
                  ),
                  _closeButton(isDark),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: HomeUi.borderLight(isDark)),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isManualAsset) ...[
                    _assetTypeChip(isDark),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isManualAsset) ...[
                        Expanded(
                          flex: 3,
                          child: FilterTextField(
                            dark: isDark,
                            label: 'Asset Name',
                            controller: _nameController,
                            hintText: 'Display name',
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: FilterTextField(
                          dark: isDark,
                          label: 'Allocation %',
                          controller: _percentController,
                          hintText: 'e.g. 5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isManualAsset) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilterDropdown<ModelAssetType>(
                            dark: isDark,
                            label: 'Asset Category',
                            value: _assetType,
                            items: ModelAssetType.values
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _assetType = v);
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilterDropdown<ModelConviction>(
                          dark: isDark,
                          label: 'Conviction',
                          value: _conviction,
                          items: ModelConviction.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _conviction = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilterTextField(
                    dark: isDark,
                    label: 'Investment Thesis',
                    controller: _thesisController,
                    hintText: 'Why this holding belongs here',
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  FilterTextField(
                    dark: isDark,
                    label: 'Risk Notes',
                    controller: _riskController,
                    hintText: 'Key risks to watch',
                    minLines: 2,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.ghostAction(
                      label: 'Cancel',
                      dark: isDark,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HomeUi.primaryAction(
                      label: primaryLabel,
                      onTap: _submit,
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

  Widget _closeButton(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: HomeUi.controlHeight,
          height: HomeUi.controlHeight,
          decoration: BoxDecoration(
            color: HomeUi.elevatedBg(isDark),
            shape: BoxShape.circle,
            border: Border.all(color: HomeUi.borderLight(isDark)),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: HomeUi.muted(isDark),
          ),
        ),
      ),
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
}
