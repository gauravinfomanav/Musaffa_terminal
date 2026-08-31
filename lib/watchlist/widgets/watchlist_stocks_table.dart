import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_stock_model.dart';
import 'package:musaffa_terminal/watchlist/widgets/add_stocks_modal.dart';
import 'package:musaffa_terminal/watchlist/widgets/target_price_cell.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_table_cells.dart';
import 'package:musaffa_terminal/web_service.dart';

enum _WatchlistSortBy {
  changePercent,
  name,
  price,
  marketCap,
  volume,
  gainLoss,
}

class WatchlistStocksTable extends StatefulWidget {
  final List<WatchlistStock> stocks;
  final bool isLoading;
  final String? errorMessage;
  final bool isDarkMode;
  final String? title;
  final String? subtitle;
  final Function(List<SimpleRowModel>)? onDataReady;
  final String? selectedSymbol;
  final ValueChanged<SimpleRowModel>? onStockSelected;

  const WatchlistStocksTable({
    Key? key,
    required this.stocks,
    required this.isLoading,
    this.errorMessage,
    required this.isDarkMode,
    this.title,
    this.subtitle,
    this.onDataReady,
    this.selectedSymbol,
    this.onStockSelected,
  }) : super(key: key);

  @override
  State<WatchlistStocksTable> createState() => _WatchlistStocksTableState();
}

class _WatchlistStocksTableState extends State<WatchlistStocksTable> {
  List<SimpleRowModel> _tableData = <SimpleRowModel>[];
  bool _isEnrichingData = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _WatchlistSortBy _sortBy = _WatchlistSortBy.changePercent;
  bool _sortAsc = false;
  int _page = 1;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    if (widget.stocks.isNotEmpty) {
      _enrichStocksData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WatchlistStocksTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stocks.length != widget.stocks.length ||
        (oldWidget.stocks.isNotEmpty &&
            widget.stocks.isNotEmpty &&
            oldWidget.stocks.first.ticker != widget.stocks.first.ticker) ||
        (oldWidget.stocks.isEmpty && widget.stocks.isNotEmpty) ||
        (oldWidget.stocks.isNotEmpty && widget.stocks.isEmpty)) {
      setState(() {
        _tableData = <SimpleRowModel>[];
        _isEnrichingData = false;
        _page = 1;
        _searchQuery = '';
        _searchController.clear();
      });

      if (widget.stocks.isNotEmpty) {
        _enrichStocksData();
      }
    }
  }

  Future<void> _enrichStocksData() async {
    if (widget.stocks.isEmpty || _isEnrichingData) return;

    if (mounted) {
      setState(() => _isEnrichingData = true);
    }

    try {
      final List<String> tickerIds =
          widget.stocks.map((WatchlistStock s) => s.ticker).toList();

      final Map<String, String> stockParams = <String, String>{
        'q': '*',
        'filter_by':
            'id:=[${tickerIds.map((String id) => '`$id`').join(',')}]',
        'include_fields':
            'id,currentPrice,usdMarketCap,volume,currency,priceChange1DPercent,change1DPercent,change1D,priceChange1D,52WeekHigh,52WeekLow,previous_close,open,high,low,peTTM,avgVolume10days,currentDividendYieldTTM,beta,exchange',
        'per_page': '100',
      };

      final stockResponse = await WebService.getTypesense(
        <String>['collections', 'stocks_data', 'documents', 'search'],
        stockParams,
      );

      final Map<String, String> logoParams = <String, String>{
        'q': '*',
        'filter_by':
            '\$company_profile_collection_new(id:*)&&id:=[${tickerIds.map((String id) => '`$id`').join(',')}]',
        'include_fields':
            r'id,name,logo,$company_profile_collection_new(name,logo),$stocks_data(name,logo,cp_country,city)',
        'per_page': '100',
      };

      final logoResponse = await WebService.getTypesense(
        <String>['collections', 'stocks_data', 'documents', 'search'],
        logoParams,
      );

      if (stockResponse.statusCode == 200 && logoResponse.statusCode == 200) {
        final Map<String, dynamic> stockData =
            jsonDecode(stockResponse.body) as Map<String, dynamic>;
        final Map<String, dynamic> logoData =
            jsonDecode(logoResponse.body) as Map<String, dynamic>;
        final List<dynamic> stocksHits =
            stockData['hits'] as List<dynamic>? ?? <dynamic>[];
        final List<dynamic> logoHits =
            logoData['hits'] as List<dynamic>? ?? <dynamic>[];

        final Map<String, dynamic> stocksMap = <String, dynamic>{};
        for (final dynamic stock in stocksHits) {
          final dynamic stockDoc = stock['document'];
          if (stockDoc is Map && stockDoc['id'] != null) {
            stocksMap[stockDoc['id'].toString()] = stockDoc;
          }
        }

        final Map<String, Map<String, String>> logoMap =
            <String, Map<String, String>>{};
        for (final dynamic logo in logoHits) {
          final Map<String, dynamic> doc =
              (logo['document'] as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{};
          final String id = (doc['id'] ?? '').toString();
          if (id.isEmpty) continue;

          String? name;
          String? logoUrl;

          final Map<String, dynamic>? companyProfile =
              doc['company_profile_collection_new'] as Map<String, dynamic>?;
          if (companyProfile != null) {
            name = companyProfile['name']?.toString();
            logoUrl = companyProfile['logo']?.toString();
          }

          if (name == null ||
              name.isEmpty ||
              logoUrl == null ||
              logoUrl.isEmpty) {
            Map<String, dynamic>? sd;
            final dynamic v = doc['\$stocks_data'] ?? doc['stocks_data'];
            if (v is Map) {
              sd = v.cast<String, dynamic>();
            } else if (v is List && v.isNotEmpty && v.first is Map) {
              sd = (v.first as Map).cast<String, dynamic>();
            }
            if (sd != null) {
              name ??= sd['name']?.toString();
              logoUrl ??= sd['logo']?.toString();
            }
          }

          name ??= doc['name']?.toString();
          logoUrl ??= doc['logo']?.toString();

          if ((name != null && name.isNotEmpty) ||
              (logoUrl != null && logoUrl.isNotEmpty)) {
            logoMap[id] = <String, String>{
              'name': name ?? '',
              'logo': logoUrl ?? '',
            };
          }
        }

        final List<SimpleRowModel> tableData = <SimpleRowModel>[];
        final bool isDark = widget.isDarkMode;

        for (final WatchlistStock watchlistStock in widget.stocks) {
          final dynamic realTimeData = stocksMap[watchlistStock.ticker];
          final Map<String, String>? logoInfo =
              logoMap[watchlistStock.ticker];

          if (realTimeData != null) {
            final double addedPrice = watchlistStock.currentPrice;
            final double currentPrice =
                _toDouble(realTimeData['currentPrice']) ?? 0.0;
            final double marketCap =
                _toDouble(realTimeData['usdMarketCap']) ?? 0.0;
            final double volume = _toDouble(realTimeData['volume']) ?? 0.0;
            final double? dayChangePercent = _toDouble(
                  realTimeData['priceChange1DPercent'],
                ) ??
                _toDouble(realTimeData['change1DPercent']);
            final double? dayChangeAbs = _toDouble(realTimeData['change1D']) ??
                _toDouble(realTimeData['priceChange1D']) ??
                (dayChangePercent != null && currentPrice > 0
                    ? currentPrice *
                        (dayChangePercent / (100 + dayChangePercent))
                    : null);
            final double? weekHigh = _toDouble(realTimeData['52WeekHigh']);
            final double? weekLow = _toDouble(realTimeData['52WeekLow']);
            final double? open = _toDouble(realTimeData['open']);
            final double? previousClose =
                _toDouble(realTimeData['previous_close']);
            final double? high = _toDouble(realTimeData['high']);
            final double? low = _toDouble(realTimeData['low']);
            final double? peTTM = _toDouble(realTimeData['peTTM']);
            final double? avgVolume =
                _toDouble(realTimeData['avgVolume10days']);
            final double? dividendYield =
                _toDouble(realTimeData['currentDividendYieldTTM']);
            final double? beta = _toDouble(realTimeData['beta']);
            final String exchange =
                realTimeData['exchange']?.toString() ?? '';

            final String logo = logoInfo?['logo'] ?? '';
            final String name = logoInfo?['name'] ?? watchlistStock.ticker;

            final double priceDiff = currentPrice - addedPrice;
            final double gainLossPercent =
                addedPrice > 0 ? (priceDiff / addedPrice) * 100 : 0.0;
            final double displayChange =
                dayChangePercent ?? gainLossPercent;
            final bool isGain = displayChange >= 0;

            tableData.add(
              SimpleRowModel(
                symbol: watchlistStock.ticker,
                name: name,
                logo: logo.isEmpty ? null : logo,
                price: currentPrice,
                changePercent: displayChange,
                currency: 'USD',
                isPositive: isGain,
                changeColor: isGain
                    ? Colors.green.shade600
                    : Colors.red.shade600,
                fields: <String, dynamic>{
                  'addedPrice': addedPrice,
                  'currentPrice': currentPrice,
                  'priceDisplay': '\$${currentPrice.toStringAsFixed(2)}',
                  'gainLoss': double.parse(priceDiff.toStringAsFixed(1)),
                  'gainLossPercent': gainLossPercent,
                  'change1DPercent': dayChangePercent,
                  'change1DAbs': dayChangeAbs,
                  'changeCell': WatchlistChangeCell(
                    percent: dayChangePercent ?? displayChange,
                    absolute: dayChangeAbs,
                    isDark: isDark,
                  ),
                  'sparkline': WatchlistSparklineCell(
                    key: ValueKey<String>('spark_${watchlistStock.ticker}'),
                    symbol: watchlistStock.ticker,
                    isDark: isDark,
                    positive: isGain,
                  ),
                  'range52': WatchlistRange52Cell(
                    key: ValueKey<String>('range_${watchlistStock.ticker}'),
                    low: weekLow,
                    high: weekHigh,
                    current: currentPrice,
                    isDark: isDark,
                  ),
                  'weekHigh': weekHigh,
                  'weekLow': weekLow,
                  'open': open,
                  'previousClose': previousClose,
                  'high': high,
                  'low': low,
                  'peTTM': peTTM,
                  'avgVolume': avgVolume,
                  'dividendYield': dividendYield,
                  'beta': beta,
                  'exchange': exchange,
                  'targetPrice': TargetPriceCell(
                    ticker: watchlistStock.ticker,
                    bellStyle: true,
                  ),
                  'notes': _NotesCell(
                    ticker: watchlistStock.ticker,
                    name: name,
                    isDark: isDark,
                  ),
                  'marketCap':
                      Constants.formatMarketCapFromMillions(marketCap),
                  'marketCapRaw': marketCap,
                  'volumeRaw': volume,
                  'volume': _formatVolumeShort(volume),
                },
              ),
            );
          } else {
            tableData.add(
              SimpleRowModel(
                symbol: watchlistStock.ticker,
                name: watchlistStock.ticker,
                logo: null,
                price: watchlistStock.currentPrice,
                changePercent: 0.0,
                currency: 'USD',
                isPositive: true,
                changeColor: Colors.grey,
                fields: <String, dynamic>{
                  'addedPrice': watchlistStock.currentPrice,
                  'currentPrice': watchlistStock.currentPrice,
                  'priceDisplay':
                      '\$${watchlistStock.currentPrice.toStringAsFixed(2)}',
                  'gainLoss': 0.0,
                  'gainLossPercent': 0.0,
                  'change1DPercent': null,
                  'changeCell': WatchlistChangeCell(
                    percent: 0,
                    absolute: 0,
                    isDark: isDark,
                  ),
                  'sparkline': WatchlistSparklineCell(
                    symbol: watchlistStock.ticker,
                    isDark: isDark,
                    positive: true,
                  ),
                  'range52': WatchlistRange52Cell(
                    low: null,
                    high: null,
                    current: watchlistStock.currentPrice,
                    isDark: isDark,
                  ),
                  'targetPrice': TargetPriceCell(
                    ticker: watchlistStock.ticker,
                    bellStyle: true,
                  ),
                  'notes': _NotesCell(
                    ticker: watchlistStock.ticker,
                    name: watchlistStock.ticker,
                    isDark: isDark,
                  ),
                  'marketCap': '--',
                  'marketCapRaw': 0.0,
                  'volumeRaw': 0.0,
                  'volume': '—',
                },
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            _tableData = tableData;
            _isEnrichingData = false;
            _page = 1;
          });
          widget.onDataReady?.call(_tableData);
        }
      } else {
        _buildFallbackTableData();
      }
    } catch (_) {
      _buildFallbackTableData();
    }
  }

  void _buildFallbackTableData() {
    final bool isDark = widget.isDarkMode;
    final List<SimpleRowModel> tableData = <SimpleRowModel>[];

    for (final WatchlistStock watchlistStock in widget.stocks) {
      tableData.add(
        SimpleRowModel(
          symbol: watchlistStock.ticker,
          name: watchlistStock.ticker,
          logo: null,
          price: watchlistStock.currentPrice,
          changePercent: 0.0,
          currency: 'USD',
          isPositive: true,
          changeColor: Colors.grey,
          fields: <String, dynamic>{
            'addedPrice': watchlistStock.currentPrice,
            'currentPrice': watchlistStock.currentPrice,
            'priceDisplay':
                '\$${watchlistStock.currentPrice.toStringAsFixed(2)}',
            'gainLoss': 0.0,
            'gainLossPercent': 0.0,
            'changeCell': WatchlistChangeCell(
              percent: 0,
              absolute: 0,
              isDark: isDark,
            ),
            'sparkline': WatchlistSparklineCell(
              symbol: watchlistStock.ticker,
              isDark: isDark,
              positive: true,
            ),
            'range52': WatchlistRange52Cell(
              low: null,
              high: null,
              current: watchlistStock.currentPrice,
              isDark: isDark,
            ),
            'targetPrice': TargetPriceCell(
                    ticker: watchlistStock.ticker,
                    bellStyle: true,
                  ),
            'notes': _NotesCell(
              ticker: watchlistStock.ticker,
              name: watchlistStock.ticker,
              isDark: isDark,
            ),
            'marketCap': '--',
            'marketCapRaw': 0.0,
            'volumeRaw': 0.0,
            'volume': '—',
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _tableData = tableData;
        _isEnrichingData = false;
        _page = 1;
      });
      widget.onDataReady?.call(_tableData);
    }
  }

  List<SimpleRowModel> get _filteredSorted {
    Iterable<SimpleRowModel> rows = _tableData;
    final String q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      rows = rows.where((SimpleRowModel r) {
        return r.symbol.toLowerCase().contains(q) ||
            r.name.toLowerCase().contains(q);
      });
    }

    final List<SimpleRowModel> list = rows.toList();
    list.sort((SimpleRowModel a, SimpleRowModel b) {
      int cmp;
      switch (_sortBy) {
        case _WatchlistSortBy.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case _WatchlistSortBy.price:
          cmp = (a.price ?? 0).compareTo(b.price ?? 0);
          break;
        case _WatchlistSortBy.marketCap:
          cmp = ((_toDouble(a.fields['marketCapRaw']) ?? 0)
              .compareTo(_toDouble(b.fields['marketCapRaw']) ?? 0));
          break;
        case _WatchlistSortBy.volume:
          cmp = ((_toDouble(a.fields['volumeRaw']) ??
                  _toDouble(a.fields['volume']) ??
                  0)
              .compareTo(_toDouble(b.fields['volumeRaw']) ??
                  _toDouble(b.fields['volume']) ??
                  0));
          break;
        case _WatchlistSortBy.gainLoss:
          cmp = ((_toDouble(a.fields['gainLossPercent']) ?? 0)
              .compareTo(_toDouble(b.fields['gainLossPercent']) ?? 0));
          break;
        case _WatchlistSortBy.changePercent:
          cmp = (a.changePercent ?? 0).compareTo(b.changePercent ?? 0);
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  List<SimpleRowModel> get _pageRows {
    final List<SimpleRowModel> all = _filteredSorted;
    if (all.isEmpty) return all;
    final int start = ((_page - 1) * _pageSize).clamp(0, all.length);
    final int end = (start + _pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  int get _totalPages {
    final int n = _filteredSorted.length;
    if (n <= 0) return 1;
    return ((n - 1) ~/ _pageSize) + 1;
  }

  void _openAddStocks() {
    final WatchlistController controller = Get.find<WatchlistController>();
    final selected = controller.selectedWatchlist.value;
    if (selected == null) return;
    AddStocksModal.show(
      context: context,
      watchlistName: selected.name,
      watchlistId: selected.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || _isEnrichingData) {
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.stocks.isEmpty) {
      return _buildEmptyState();
    }

    if (_tableData.isEmpty && widget.stocks.isNotEmpty) {
      return _buildLoadingState();
    }

    return _buildTable();
  }

  Widget _buildLoadingState() {
    return Column(
      children: <Widget>[
        WatchlistShimmer.listItem(isDarkMode: widget.isDarkMode),
        const SizedBox(height: 8),
        WatchlistShimmer.listItem(isDarkMode: widget.isDarkMode),
        const SizedBox(height: 8),
        WatchlistShimmer.listItem(isDarkMode: widget.isDarkMode),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(height: 8),
          const Text(
            'Failed to load stocks',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            widget.errorMessage ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.inbox_outlined,
              color: HomeUi.muted(widget.isDarkMode),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              'No stocks in this watchlist',
              style: HomeUi.sectionTitle(widget.isDarkMode),
            ),
            const SizedBox(height: 4),
            Text(
              'Add stocks to get started',
              style: HomeUi.subtitle(widget.isDarkMode),
            ),
            const SizedBox(height: 16),
            HomeUi.primaryAction(
              label: 'Add stocks',
              icon: Icons.add_rounded,
              onTap: _openAddStocks,
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(_WatchlistSortBy sort, {bool compact = false}) {
    if (compact) {
      switch (sort) {
        case _WatchlistSortBy.changePercent:
          return '% Chg';
        case _WatchlistSortBy.name:
          return 'Name';
        case _WatchlistSortBy.price:
          return 'Price';
        case _WatchlistSortBy.marketCap:
          return 'Mkt Cap';
        case _WatchlistSortBy.volume:
          return 'Volume';
        case _WatchlistSortBy.gainLoss:
          return 'G/L';
      }
    }

    switch (sort) {
      case _WatchlistSortBy.changePercent:
        return '% Change';
      case _WatchlistSortBy.name:
        return 'Name';
      case _WatchlistSortBy.price:
        return 'Price';
      case _WatchlistSortBy.marketCap:
        return 'Market Cap';
      case _WatchlistSortBy.volume:
        return 'Volume';
      case _WatchlistSortBy.gainLoss:
        return 'Gain / Loss';
    }
  }

  Widget _buildToolbarActions(bool isDark) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compactSort =
            constraints.hasBoundedWidth && constraints.maxWidth < 360;
        final Widget search = _buildSearchField(isDark);
        final Widget sort = _buildSortMenuPill(isDark, compact: compactSort);
        final Widget direction = _buildSortDirectionPill(isDark);

        if (!constraints.hasBoundedWidth) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(width: 200, child: search),
              const SizedBox(width: 8),
              sort,
              const SizedBox(width: 6),
              direction,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: search),
            const SizedBox(width: 8),
            sort,
            const SizedBox(width: 6),
            direction,
          ],
        );
      },
    );
  }

  Widget _buildSearchField(bool isDark) {
    return HomeUi.filterFieldShell(
      dark: isDark,
      height: HomeUi.controlHeight,
      radius: HomeUi.radiusPill,
      padding: EdgeInsets.zero,
      alignment: Alignment.center,
      child: SizedBox(
        height: HomeUi.controlHeight,
        child: TextField(
          controller: _searchController,
          onChanged: (String v) {
            setState(() {
              _searchQuery = v;
              _page = 1;
            });
          },
          cursorColor: HomeUi.title(isDark),
          style: HomeUi.control(isDark, active: true).copyWith(
            fontSize: 12.5,
            height: 1.0,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search stocks...',
            hintStyle: HomeUi.control(isDark).copyWith(
              fontSize: 12.5,
              height: 1.0,
              color: HomeUi.muted(isDark),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 16,
              color: HomeUi.muted(isDark),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: HomeUi.controlHeight,
            ),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: HomeUi.controlHeight,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: HomeUi.muted(isDark),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _page = 1;
                      });
                    },
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 9,
              horizontal: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortMenuPill(bool isDark, {required bool compact}) {
    final String sortLabel = _sortLabel(_sortBy, compact: compact);

    return PopupMenuButton<_WatchlistSortBy>(
      tooltip: 'Sort by',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      color: HomeUi.cardBg(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
      ),
      onSelected: (_WatchlistSortBy value) {
        setState(() {
          if (_sortBy == value) {
            _sortAsc = !_sortAsc;
          } else {
            _sortBy = value;
            _sortAsc = value == _WatchlistSortBy.name;
          }
          _page = 1;
        });
      },
      itemBuilder: (BuildContext context) {
        return _WatchlistSortBy.values
            .map(
              (_WatchlistSortBy value) => PopupMenuItem<_WatchlistSortBy>(
                value: value,
                height: 36,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 18,
                      child: _sortBy == value
                          ? Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: HomeUi.buttonBorder,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        _sortLabel(value),
                        style: HomeUi.control(isDark, active: true).copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: HomeUi.filterFieldShell(
        dark: isDark,
        height: HomeUi.controlHeight,
        radius: HomeUi.radiusPill,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: HomeUi.muted(isDark),
            ),
            const SizedBox(width: 6),
            Text(
              sortLabel,
              maxLines: 1,
              softWrap: false,
              style: HomeUi.control(isDark, active: true).copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            HomeUi.filterChevron(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDirectionPill(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _sortAsc = !_sortAsc),
        child: HomeUi.filterFieldShell(
          dark: isDark,
          height: HomeUi.controlHeight,
          radius: HomeUi.radiusPill,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Icon(
            _sortAsc
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 16,
            color: HomeUi.title(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    final List<SimpleRowModel> filtered = _filteredSorted;
    final int total = filtered.length;
    final int start = total == 0 ? 0 : ((_page - 1) * _pageSize) + 1;
    final int end = total == 0 ? 0 : (start + _pageRows.length - 1);
    final int pages = _totalPages;
    final int page = _page.clamp(1, pages);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: <Widget>[
          HomeUi.ghostAction(
            label: 'Add Stock',
            icon: Icons.add_rounded,
            dark: isDark,
            onTap: _openAddStocks,
          ),
          const Spacer(),
          Text(
            total == 0
                ? 'Showing 0 stocks'
                : 'Showing $start to $end of $total',
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 11.5),
          ),
          if (pages > 1) ...<Widget>[
            const SizedBox(width: 10),
            _PageIconButton(
              isDark: isDark,
              icon: Icons.chevron_left_rounded,
              enabled: page > 1,
              onTap: () => setState(() => _page = page - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '$page / $pages',
                style: HomeUi.control(isDark, active: true).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _PageIconButton(
              isDark: isDark,
              icon: Icons.chevron_right_rounded,
              enabled: page < pages,
              onTap: () => setState(() => _page = page + 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    final bool isDark = widget.isDarkMode;
    final List<SimpleColumn> columns = <SimpleColumn>[
      const SimpleColumn(
        label: 'PRICE',
        fieldName: 'priceDisplay',
        isNumeric: true,
        width: 100,
      ),
      const SimpleColumn(
        label: 'CHANGE %',
        fieldName: 'changeCell',
        isNumeric: true,
        width: 110,
      ),
      const SimpleColumn(
        label: '1D CHART',
        fieldName: 'sparkline',
        isNumeric: false,
        align: TextAlign.center,
        width: 104,
      ),
      const SimpleColumn(
        label: 'MKT CAP',
        fieldName: 'marketCap',
        isNumeric: true,
        width: 112,
      ),
      const SimpleColumn(
        label: 'VOLUME',
        fieldName: 'volume',
        isNumeric: true,
        width: 96,
      ),
      const SimpleColumn(
        label: '52W RANGE',
        fieldName: 'range52',
        isNumeric: false,
        align: TextAlign.center,
        width: 180,
      ),
      const SimpleColumn(
        label: 'ALERTS',
        fieldName: 'targetPrice',
        isNumeric: false,
        align: TextAlign.center,
        width: 120,
      ),
      const SimpleColumn(
        label: 'NOTES',
        fieldName: 'notes',
        isNumeric: false,
        align: TextAlign.center,
        width: 72,
      ),
    ];

    // Ensure page is valid after filter/sort.
    if (_page > _totalPages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = _totalPages);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DynamicTable(
          columns: columns,
          rows: _pageRows,
          title: widget.title ?? 'Stocks',
          subtitle: widget.subtitle ??
              '${_filteredSorted.length} holdings in this watchlist',
          toolbarLeadingIcon: Icons.table_rows_rounded,
          toolbar: _buildToolbarActions(isDark),
          toolbarPadding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          tableEdgeInset: const EdgeInsets.fromLTRB(14, 0, 16, 0),
          horizontalMargin: 0,
          considerPadding: false,
          showFixedColumn: true,
          showOuterShadow: false,
          fixedColumnWidth: 220,
          headerHeight: 44,
          rowHeight: 56,
          columnSpacing: 28,
          zebraStripes: true,
          enableLivePrices: true,
          enableColumnCustomization: true,
          tableId: 'watchlist_stocks_table_v2',
          showColumnActionMenu: true,
          showColumnResizeHandle: true,
          onTickerTap: widget.onStockSelected == null
              ? null
              : (DynamicTableRow row) {
                  final String ticker =
                      row.data['_ticker_symbol']?.toString() ?? '';
                  if (ticker.isEmpty) return;
                  for (final SimpleRowModel r in _tableData) {
                    if (r.symbol == ticker) {
                      widget.onStockSelected!(r);
                      return;
                    }
                  }
                  for (final SimpleRowModel r in _pageRows) {
                    if (r.symbol == ticker) {
                      widget.onStockSelected!(r);
                      return;
                    }
                  }
                },
        ),
        _buildFooter(isDark),
      ],
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '').trim());
    }
    return null;
  }

  /// Compact volume: 23.4K · 25.9M · 1.2B · 3.1T
  String _formatVolumeShort(double volume) {
    if (volume <= 0) return '—';
    if (volume >= 1e12) return '${(volume / 1e12).toStringAsFixed(2)}T';
    if (volume >= 1e9) return '${(volume / 1e9).toStringAsFixed(2)}B';
    if (volume >= 1e6) return '${(volume / 1e6).toStringAsFixed(2)}M';
    if (volume >= 1e3) return '${(volume / 1e3).toStringAsFixed(2)}K';
    return volume.toStringAsFixed(0);
  }
}

class _PageIconButton extends StatelessWidget {
  const _PageIconButton({
    required this.isDark,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = enabled
        ? HomeUi.title(isDark)
        : HomeUi.muted(isDark).withValues(alpha: 0.4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(HomeUi.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _NotesCell extends StatelessWidget {
  const _NotesCell({
    required this.ticker,
    required this.name,
    required this.isDark,
  });

  final String ticker;
  final String name;
  final bool isDark;

  void _openNotes() {
    if (!Get.isRegistered<NotesController>()) return;
    final NotesController notes = Get.find<NotesController>();
    notes.setCustomPanel(
      title: 'Notes · $ticker',
      subtitle: name,
      builder: (BuildContext context, VoidCallback onClose) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Quick notes for $ticker',
                style: HomeUi.sectionTitle(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the global memo pad for private research on this name.',
                style: HomeUi.subtitle(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              const SizedBox(height: 16),
              HomeUi.primaryAction(
                label: 'Open memo pad',
                icon: Icons.sticky_note_2_outlined,
                onTap: () {
                  notes.clearCustomPanel();
                  notes.openNotesPanel();
                },
              ),
            ],
          ),
        );
      },
    );
    notes.openNotesPanel();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: 'Notes',
        onPressed: _openNotes,
        icon: Icon(
          Icons.description_outlined,
          size: 18,
          color: HomeUi.muted(isDark),
        ),
      ),
    );
  }
}
