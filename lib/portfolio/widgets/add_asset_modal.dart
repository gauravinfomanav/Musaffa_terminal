import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/utils/portfolio_allocation_palette.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.52),
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
    ),
    _ManualAssetOption(
      type: ModelAssetType.reit,
      label: 'Real Estate',
      subtitle: 'REITs & property',
      icon: Icons.apartment_rounded,
    ),
    _ManualAssetOption(
      type: ModelAssetType.gold,
      label: 'Gold',
      subtitle: 'Precious metals',
      icon: Icons.diamond_outlined,
    ),
    _ManualAssetOption(
      type: ModelAssetType.bond,
      label: 'Bonds',
      subtitle: 'Fixed income',
      icon: Icons.receipt_long_outlined,
    ),
    _ManualAssetOption(
      type: ModelAssetType.commodity,
      label: 'Commodity',
      subtitle: 'Energy, ag, etc.',
      icon: Icons.oil_barrel_outlined,
    ),
    _ManualAssetOption(
      type: ModelAssetType.other,
      label: 'Other',
      subtitle: 'Custom allocation',
      icon: Icons.category_outlined,
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
        maxWidth: 640,
        maxHeight: (size.height * 0.86).clamp(540.0, 740.0),
      ),
      child: Container(
        width: size.width * 0.92,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? HomeUi.borderLight(isDark)
                : const Color(0xFFE8EAED),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.48 : 0.14),
              blurRadius: 48,
              offset: const Offset(0, 22),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHeader(isDark),
            Divider(height: 1, color: HomeUi.borderLight(isDark)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField(isDark),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 228,
                      child: _buildSearchSection(isDark),
                    ),
                    if (_selectedTickers.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildSelectedChips(isDark),
                    ],
                    const SizedBox(height: 22),
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
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
      child: Row(
        children: [
          Expanded(
            child: HomeUi.tableToolbarHeader(
              isDark,
              icon: Icons.add_rounded,
              title: 'Add Asset',
              titleFontSize: 17,
              subtitle: Text.rich(
                TextSpan(
                  text: 'Build allocation for ',
                  children: [
                    TextSpan(
                      text: widget.portfolioName,
                      style: HomeUi.tableCellEmphasis(isDark).copyWith(
                        fontSize: 12.5,
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: HomeUi.elevatedBg(isDark),
            shape: BoxShape.circle,
            border: Border.all(color: HomeUi.borderLight(isDark)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
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
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18,
                color: _searchFocused
                    ? HomeUi.accent(isDark)
                    : HomeUi.muted(isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    setState(() {});
                    _performSearch(value);
                  },
                  style: HomeUi.control(isDark, active: true).copyWith(
                    fontSize: 13.5,
                  ),
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
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: HomeUi.elevatedBg(isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: HomeUi.muted(isDark),
                      ),
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
      return _resultsShell(
        isDark,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(HomeUi.accent(isDark)),
            ),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _resultsShell(
        isDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 28, color: HomeUi.muted(isDark)),
              const SizedBox(height: 10),
              Text('No results found', style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                'Try another ticker or company name',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _resultsShell(
        isDark,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: HomeUi.softBrandWellGradient,
                  ),
                  child: HomeUi.brandIcon(
                    icon: Icons.candlestick_chart_rounded,
                    size: 24,
                    gradient: HomeUi.softBrandIconGradient,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Search for listed stocks and ETFs',
                  style: HomeUi.control(isDark).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Type a symbol or company to start building your model',
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _resultsShell(
      isDark,
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
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
      ),
    );
  }

  Widget _resultsShell(bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF171A24), const Color(0xFF141720)]
              : [const Color(0xFFF8F9FB), const Color(0xFFFCFCFD)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? HomeUi.borderLight(isDark)
              : const Color(0xFFE8EAED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildSelectedChips(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECTED (${_selectedTickers.length})',
          style: HomeUi.overline(isDark),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedTickers.map((symbol) {
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              decoration: BoxDecoration(
                color: HomeUi.accent(isDark).withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                border: Border.all(
                  color: HomeUi.accent(isDark).withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    symbol,
                    style: HomeUi.control(isDark).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: HomeUi.accent(isDark),
                    ),
                  ),
                  const SizedBox(width: 6),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTickers.remove(symbol);
                          _selectedModels.remove(symbol);
                        });
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: HomeUi.accent(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildManualSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: HomeUi.borderLight(isDark))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OTHER ASSET TYPES',
                style: HomeUi.overline(isDark),
              ),
            ),
            Expanded(child: Divider(color: HomeUi.borderLight(isDark))),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Tap an asset type to add it, then set allocation % in the table.',
          style: HomeUi.subtitle(isDark).copyWith(fontSize: 12.5),
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
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: crossCount == 3 ? 1.65 : 1.5,
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

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      decoration: BoxDecoration(
        color: isDark
            ? HomeUi.elevatedBg(isDark).withValues(alpha: 0.45)
            : const Color(0xFFF8F9FB),
        border: Border(top: BorderSide(color: HomeUi.borderLight(isDark))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _inlineFeedback ??
                  (_selectedTickers.isEmpty
                      ? 'Select tickers or pick an asset type'
                      : '${_selectedTickers.length} selected — ready to add'),
              style: _inlineFeedback != null
                  ? HomeUi.control(isDark).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: HomeUi.accent(isDark),
                    )
                  : HomeUi.subtitle(isDark).copyWith(fontSize: 12.5),
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
                icon: Icons.add_rounded,
                onTap: _addSelected,
              ),
            ),
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
  });

  final ModelAssetType type;
  final String label;
  final String subtitle;
  final IconData icon;
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
    final color =
        PortfolioAllocationPalette.forModelAssetType(option.type, isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _hover
                  ? [
                      color.withValues(alpha: isDark ? 0.16 : 0.08),
                      color.withValues(alpha: isDark ? 0.08 : 0.03),
                    ]
                  : isDark
                      ? [const Color(0xFF1A1D2E), const Color(0xFF151822)]
                      : [Colors.white, const Color(0xFFFCFCFD)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover
                  ? color.withValues(alpha: 0.42)
                  : (isDark
                      ? HomeUi.borderLight(isDark)
                      : const Color(0xFFE8EAED)),
            ),
            boxShadow: [
              BoxShadow(
                color: _hover
                    ? color.withValues(alpha: isDark ? 0.18 : 0.1)
                    : Colors.black.withValues(alpha: isDark ? 0.16 : 0.035),
                blurRadius: _hover ? 14 : 8,
                offset: Offset(0, _hover ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PortfolioAllocationPalette.softFill(color, isDark),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.28 : 0.18),
                  ),
                ),
                child: Icon(option.icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(
                option.label,
                style: HomeUi.control(isDark).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                option.subtitle,
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 11.5),
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
    final typeColor = widget.ticker.isStock
        ? const Color(0xFF2563EB)
        : const Color(0xFF7C3AED);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? HomeUi.accent(isDark).withValues(alpha: isDark ? 0.12 : 0.06)
                : _hover
                    ? (isDark ? const Color(0xFF1C2030) : Colors.white)
                    : (isDark ? const Color(0xFF171A24) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? HomeUi.accent(isDark).withValues(alpha: 0.4)
                  : _hover
                      ? HomeUi.borderStrong(isDark)
                      : HomeUi.borderLight(isDark),
            ),
            boxShadow: _hover || widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _selectionBox(isDark),
              const SizedBox(width: 12),
              SizedBox(
                width: 30,
                height: 30,
                child: showLogo(
                  widget.symbol,
                  widget.ticker.logo ?? '',
                  sideWidth: 30,
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: PortfolioAllocationPalette.softFill(typeColor, isDark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontFamilyFallback: Constants.FONT_FALLBACK,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
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
