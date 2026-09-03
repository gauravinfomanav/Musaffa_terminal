import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class AddAssetModal extends StatefulWidget {
  const AddAssetModal({
    super.key,
    required this.portfolioName,
    required this.existingHoldings,
    required this.onAddTicker,
    required this.onAddManual,
  });

  final String portfolioName;
  final List<ModelPortfolioHolding> Function() existingHoldings;
  final Future<bool> Function(TickerModel ticker) onAddTicker;
  final Future<bool> Function(ModelPortfolioHolding holding) onAddManual;

  static Future<void> show({
    required BuildContext context,
    required String portfolioName,
    required List<ModelPortfolioHolding> Function() existingHoldings,
    required Future<bool> Function(TickerModel ticker) onAddTicker,
    required Future<bool> Function(ModelPortfolioHolding holding) onAddManual,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Asset',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: AddAssetModal(
              portfolioName: portfolioName,
              existingHoldings: existingHoldings,
              onAddTicker: onAddTicker,
              onAddManual: onAddManual,
            ),
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
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AddAssetModal> createState() => _AddAssetModalState();
}

class _AddAssetModalState extends State<AddAssetModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<TickerModel> _searchResults = [];
  final Set<String> _selectedTickers = {};
  final Map<String, TickerModel> _selectedModels = {};
  bool _isSearching = false;
  bool _searchFocused = false;
  bool _searchHover = false;
  bool _isAdding = false;
  String? _inlineFeedback;

  static const _manualOptions = <_ManualAssetOption>[
    _ManualAssetOption(
      type: ModelAssetType.cash,
      label: 'Cash',
      subtitle: 'Liquidity buffer',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF6B7280),
    ),
    _ManualAssetOption(
      type: ModelAssetType.reit,
      label: 'Real Estate',
      subtitle: 'REITs & property',
      icon: Icons.apartment_rounded,
      color: Color(0xFFEF4444),
    ),
    _ManualAssetOption(
      type: ModelAssetType.gold,
      label: 'Gold',
      subtitle: 'Precious metals',
      icon: Icons.diamond_outlined,
      color: Color(0xFFF97316),
    ),
    _ManualAssetOption(
      type: ModelAssetType.bond,
      label: 'Bonds',
      subtitle: 'Fixed income',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF06B6D4),
    ),
    _ManualAssetOption(
      type: ModelAssetType.commodity,
      label: 'Commodity',
      subtitle: 'Energy, ag, etc.',
      icon: Icons.oil_barrel_outlined,
      color: Color(0xFFD97706),
    ),
    _ManualAssetOption(
      type: ModelAssetType.other,
      label: 'Other',
      subtitle: 'Custom allocation',
      icon: Icons.category_outlined,
      color: Color(0xFF7C3AED),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await SearchService.searchStocks(query.trim());
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _toggleSelection(TickerModel ticker) {
    final symbol = ticker.symbol ?? ticker.ticker ?? '';
    if (symbol.isEmpty) return;

    setState(() {
      if (_selectedTickers.contains(symbol)) {
        _selectedTickers.remove(symbol);
        _selectedModels.remove(symbol);
      } else {
        _selectedTickers.add(symbol);
        _selectedModels[symbol] = ticker;
        _searchController.clear();
        _searchResults = [];
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<void> _addSelected() async {
    if (_selectedTickers.isEmpty || _isAdding) return;

    setState(() => _isAdding = true);
    var addedCount = 0;
    var skippedCount = 0;
    for (final symbol in _selectedTickers.toList()) {
      final model = _selectedModels[symbol];
      if (model == null) continue;
      if (await widget.onAddTicker(model)) {
        addedCount++;
      } else {
        skippedCount++;
      }
    }
    if (!mounted) return;
    setState(() => _isAdding = false);
    Navigator.of(context).pop();
    if (addedCount > 0) {
      final skippedSuffix = skippedCount > 0
          ? ' · $skippedCount already in portfolio'
          : '';
      SnackBarUtils.showSuccess(
        context,
        'Added $addedCount asset${addedCount == 1 ? '' : 's'} to "${widget.portfolioName}"$skippedSuffix',
      );
    } else if (skippedCount > 0) {
      SnackBarUtils.showError(
        context,
        skippedCount == 1
            ? 'That asset is already in the portfolio'
            : '$skippedCount assets are already in the portfolio',
      );
    }
  }

  void _showInlineFeedback(String message) {
    setState(() => _inlineFeedback = message);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _inlineFeedback == message) {
        setState(() => _inlineFeedback = null);
      }
    });
  }

  Future<void> _openManualAsset(_ManualAssetOption option) async {
    final holding = ModelPortfolioHolding.manualAsset(
      type: option.type,
      name: option.label,
      existing: widget.existingHoldings(),
    );

    final added = await widget.onAddManual(holding);
    if (!mounted || !added) return;

    _showInlineFeedback(
      '${option.label} added — set allocation % in the holdings table',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 620,
        maxHeight: (size.height * 0.86).clamp(520.0, 720.0),
      ),
      child: Container(
        width: size.width * 0.92,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField(isDark),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: _buildSearchSection(isDark),
                    ),
                    if (_selectedTickers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSelectedChips(isDark),
                    ],
                    const SizedBox(height: 20),
                    _buildManualSection(isDark),
                  ],
                ),
              ),
            ),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: HomeUi.tableToolbarHeader(
              isDark,
              icon: Icons.add_circle_outline_rounded,
              title: 'Add Asset',
              subtitle: Text.rich(
                TextSpan(
                  text: 'Build allocation for ',
                  children: [
                    TextSpan(
                      text: widget.portfolioName,
                      style: HomeUi.tableCellEmphasis(isDark).copyWith(
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _closeButton(isDark),
        ],
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
          child: Icon(Icons.close_rounded, size: 16, color: HomeUi.muted(isDark)),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return HomeUi.filterFieldColumn(
      dark: isDark,
      label: 'Stocks & ETFs',
      field: MouseRegion(
        onEnter: (_) => setState(() => _searchHover = true),
        onExit: (_) => setState(() => _searchHover = false),
        child: HomeUi.filterFieldShell(
          dark: isDark,
          accent: _searchFocused,
          hover: _searchHover,
          radius: HomeUi.radiusPill,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: HomeUi.muted(isDark)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    setState(() {});
                    _performSearch(value);
                  },
                  style: HomeUi.control(isDark),
                  decoration: HomeUi.filterTextFieldDecoration(
                    isDark,
                    hintText: 'Search ticker or company name',
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _performSearch('');
                      _searchFocusNode.requestFocus();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: HomeUi.muted(isDark),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isDark) {
    if (_isSearching) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(HomeUi.accent(isDark)),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text('No results found', style: HomeUi.subtitle(isDark)),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeUi.elevatedBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusMd),
          border: Border.all(color: HomeUi.borderLight(isDark)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.candlestick_chart_rounded,
                size: 28, color: HomeUi.muted(isDark)),
            const SizedBox(height: 8),
            Text(
              'Search for listed stocks and ETFs',
              style: HomeUi.subtitle(isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final ticker = _searchResults[index];
        final symbol = ticker.symbol ?? ticker.ticker ?? '';
        return _AssetSearchRow(
          isDark: isDark,
          ticker: ticker,
          symbol: symbol,
          isSelected: _selectedTickers.contains(symbol),
          onTap: () => _toggleSelection(ticker),
        );
      },
    );
  }

  Widget _buildSelectedChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedTickers.map((symbol) {
        return InputChip(
          label: Text(symbol, style: HomeUi.control(isDark).copyWith(fontSize: 12)),
          deleteIcon: Icon(Icons.close_rounded, size: 14, color: HomeUi.muted(isDark)),
          onDeleted: () {
            setState(() {
              _selectedTickers.remove(symbol);
              _selectedModels.remove(symbol);
            });
          },
          backgroundColor: HomeUi.elevatedBg(isDark),
          side: BorderSide(color: HomeUi.borderLight(isDark)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildManualSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OTHER ASSET TYPES',
                style: HomeUi.overline(isDark),
              ),
            ),
            Expanded(
              child: Divider(color: HomeUi.borderLight(isDark)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Tap an asset type to add it, then set allocation % in the table.',
          style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth >= 520 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _manualOptions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: crossCount == 3 ? 1.55 : 1.45,
              ),
              itemBuilder: (context, index) {
                return _ManualAssetCard(
                  isDark: isDark,
                  option: _manualOptions[index],
                  onTap: () => _openManualAsset(_manualOptions[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final canAdd = _selectedTickers.isNotEmpty && !_isAdding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _inlineFeedback ??
                      (_selectedTickers.isEmpty
                          ? 'Select tickers or pick an asset type'
                          : '${_selectedTickers.length} selected'),
                  style: _inlineFeedback != null
                      ? HomeUi.control(isDark).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HomeUi.accent(isDark),
                        )
                      : HomeUi.subtitle(isDark),
                ),
              ),
              HomeUi.ghostAction(
                label: 'Cancel',
                dark: isDark,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
              Opacity(
                opacity: canAdd ? 1 : 0.45,
                child: IgnorePointer(
                  ignoring: !canAdd,
                  child: HomeUi.primaryAction(
                    label: _isAdding ? 'Adding…' : 'Add Selected',
                    onTap: _addSelected,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualAssetOption {
  const _ManualAssetOption({
    required this.type,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final ModelAssetType type;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ManualAssetCard extends StatefulWidget {
  const _ManualAssetCard({
    required this.isDark,
    required this.option,
    required this.onTap,
  });

  final bool isDark;
  final _ManualAssetOption option;
  final VoidCallback onTap;

  @override
  State<_ManualAssetCard> createState() => _ManualAssetCardState();
}

class _ManualAssetCardState extends State<_ManualAssetCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final option = widget.option;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hover
                ? option.color.withValues(alpha: isDark ? 0.12 : 0.08)
                : HomeUi.elevatedBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(
              color: _hover
                  ? option.color.withValues(alpha: 0.45)
                  : HomeUi.borderLight(isDark),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(option.icon, size: 18, color: option.color),
              ),
              const Spacer(),
              Text(
                option.label,
                style: HomeUi.control(isDark).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                option.subtitle,
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetSearchRow extends StatefulWidget {
  const _AssetSearchRow({
    required this.isDark,
    required this.ticker,
    required this.symbol,
    required this.isSelected,
    required this.onTap,
  });

  final bool isDark;
  final TickerModel ticker;
  final String symbol;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_AssetSearchRow> createState() => _AssetSearchRowState();
}

class _AssetSearchRowState extends State<_AssetSearchRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final company = widget.ticker.companyName ?? widget.ticker.name ?? '';
    final typeLabel = widget.ticker.isStock ? 'Stock' : 'ETF';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected || _hover
                ? HomeUi.elevatedBg(isDark)
                : HomeUi.cardBg(isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(
              color: widget.isSelected
                  ? HomeUi.iconWellBorder
                  : _hover
                      ? HomeUi.borderStrong(isDark)
                      : HomeUi.borderLight(isDark),
            ),
          ),
          child: Row(
            children: [
              _selectionBox(isDark),
              const SizedBox(width: 12),
              SizedBox(
                width: 28,
                height: 28,
                child: showLogo(
                  widget.symbol,
                  widget.ticker.logo ?? '',
                  sideWidth: 28,
                  circular: true,
                  name: company,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.symbol,
                      style: HomeUi.tableCellEmphasis(isDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (company.isNotEmpty)
                      Text(
                        company,
                        style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HomeUi.elevatedBg(isDark),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: HomeUi.borderLight(isDark)),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.muted(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionBox(bool isDark) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: widget.isSelected ? HomeUi.iconFillGradient : null,
        color: widget.isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isSelected
              ? HomeUi.buttonBorder
              : HomeUi.borderStrong(isDark),
        ),
      ),
      child: widget.isSelected
          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
          : null,
    );
  }
}
