import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/web_service.dart';

class AddStocksModal extends StatefulWidget {
  final String watchlistName;
  final String watchlistId;

  const AddStocksModal({
    super.key,
    required this.watchlistName,
    required this.watchlistId,
  });

  static Future<void> show({
    required BuildContext context,
    required String watchlistName,
    required String watchlistId,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Stocks',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: AddStocksModal(
              watchlistName: watchlistName,
              watchlistId: watchlistId,
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
  State<AddStocksModal> createState() => _AddStocksModalState();
}

class _AddStocksModalState extends State<AddStocksModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final WatchlistController _watchlistController =
      Get.find<WatchlistController>();

  List<TickerModel> _searchResults = [];
  final Set<String> _selectedTickers = {};
  bool _isSearching = false;
  bool _searchFocused = false;
  bool _searchHover = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
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

  void _toggleSelection(String ticker) {
    setState(() {
      if (_selectedTickers.contains(ticker)) {
        _selectedTickers.remove(ticker);
      } else {
        _selectedTickers.add(ticker);
        _searchController.clear();
        _searchResults.clear();
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchRealTimePricesForSelectedStocks() async {
    final stocksToAdd = <Map<String, dynamic>>[];

    try {
      final tickerIds = _selectedTickers.toList();
      final params = {
        'q': '*',
        'filter_by': 'id:=[${tickerIds.map((id) => '`$id`').join(',')}]',
        'include_fields': r'$stocks_data(id,currentPrice)',
        'per_page': '50'
      };

      final response = await WebService.getTypesense(
        ['collections', 'stocks_data', 'documents', 'search'],
        params,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List<dynamic>? ?? [];

        final priceMap = <String, double>{};
        for (final hit in hits) {
          final document = hit['document'] as Map<String, dynamic>?;
          if (document != null) {
            final ticker = document['id']?.toString() ?? '';
            final price = document['currentPrice']?.toDouble() ?? 0.0;
            priceMap[ticker] = price;
          }
        }

        for (final selectedTicker in _selectedTickers) {
          stocksToAdd.add({
            'ticker': selectedTicker,
            'current_price': priceMap[selectedTicker] ?? 1.0,
          });
        }
      } else {
        for (final selectedTicker in _selectedTickers) {
          stocksToAdd.add({
            'ticker': selectedTicker,
            'current_price': 1.0,
          });
        }
      }
    } catch (_) {
      for (final selectedTicker in _selectedTickers) {
        stocksToAdd.add({
          'ticker': selectedTicker,
          'current_price': 1.0,
        });
      }
    }

    return stocksToAdd;
  }

  Future<void> _addSelectedStocks() async {
    if (_selectedTickers.isEmpty) return;

    final stocksToAdd = await _fetchRealTimePricesForSelectedStocks();
    final success = await _watchlistController.addStocksToWatchlist(stocksToAdd);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(
        context,
        'Added ${_selectedTickers.length} stocks to "${widget.watchlistName}"',
      );
    } else {
      SnackBarUtils.showError(
        context,
        _watchlistController.stocksErrorMessage.value,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: (size.height * 0.78).clamp(420.0, 620.0),
      ),
      child: Container(
        width: size.width * 0.9,
        height: (size.height * 0.7).clamp(420.0, 620.0),
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
          children: [
            _buildHeader(isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _buildSearchField(isDark),
            ),
            Expanded(child: _buildResultsSection(isDark)),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: HomeUi.tableToolbarHeader(
              isDark,
              icon: Icons.add_chart_rounded,
              title: 'Add Stocks',
              subtitle: Text.rich(
                TextSpan(
                  text: 'Search and add holdings to ',
                  children: [
                    TextSpan(
                      text: widget.watchlistName,
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
          MouseRegion(
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return HomeUi.filterFieldColumn(
      dark: isDark,
      label: 'Search',
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
                  onChanged: _performSearch,
                  style: HomeUi.control(isDark, active: true).copyWith(fontSize: 13),
                  cursorColor: HomeUi.title(isDark),
                  decoration: HomeUi.filterTextFieldDecoration(
                    isDark,
                    hintText: 'Ticker or company name',
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

  Widget _buildResultsSection(bool isDark) {
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
        child: Text(
          'No stocks found',
          style: HomeUi.subtitle(isDark),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      if (_selectedTickers.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED (${_selectedTickers.length})',
                style: HomeUi.overline(isDark),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: _selectedTickers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ticker = _selectedTickers.elementAt(index);
                    return _buildSelectedStockItem(ticker, isDark);
                  },
                ),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Search for stocks to add to your watchlist',
            textAlign: TextAlign.center,
            style: HomeUi.subtitle(isDark),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final ticker = _searchResults[index];
        final tickerSymbol = ticker.symbol ?? ticker.ticker ?? '';
        final isSelected = _selectedTickers.contains(tickerSymbol);
        return _SearchResultRow(
          isDark: isDark,
          ticker: ticker,
          tickerSymbol: tickerSymbol,
          isSelected: isSelected,
          onTap: () => _toggleSelection(tickerSymbol),
        );
      },
    );
  }

  Widget _buildSelectedStockItem(String ticker, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _toggleSelection(ticker),
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeUi.negative(isDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: HomeUi.negative(isDark).withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 14,
                  color: HomeUi.negative(isDark),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ticker,
              style: HomeUi.tableCellEmphasis(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final canAdd = _selectedTickers.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_selectedTickers.length} selected',
                style: HomeUi.subtitle(isDark),
              ),
              const Spacer(),
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
                    label: 'Add Selected',
                    onTap: _addSelectedStocks,
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

class _SearchResultRow extends StatefulWidget {
  final bool isDark;
  final TickerModel ticker;
  final String tickerSymbol;
  final bool isSelected;
  final VoidCallback onTap;

  const _SearchResultRow({
    required this.isDark,
    required this.ticker,
    required this.tickerSymbol,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final company = widget.ticker.companyName ?? widget.ticker.name ?? '';
    final isDark = widget.isDark;

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
              Container(
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
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 28,
                height: 28,
                child: showLogo(
                  widget.tickerSymbol,
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
                      widget.tickerSymbol,
                      style: HomeUi.tableCellEmphasis(isDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (company.isNotEmpty)
                      Text(
                        company,
                        style: HomeUi.tableCellEmphasis(isDark).copyWith(
                          fontSize: 12,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (widget.ticker.currentPrice != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${widget.ticker.currentPrice!.toStringAsFixed(2)}',
                      style: HomeUi.tableCellEmphasis(isDark).copyWith(fontSize: 12.5),
                    ),
                    if (widget.ticker.percentChange != null)
                      Text(
                        '${widget.ticker.percentChange! >= 0 ? '+' : ''}${widget.ticker.percentChange!.toStringAsFixed(2)}%',
                        style: HomeUi.tableNumeric(
                          isDark,
                          positiveValue: widget.ticker.percentChange! >= 0,
                        ).copyWith(fontSize: 11),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
