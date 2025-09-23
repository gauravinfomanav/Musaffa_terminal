import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/watchlist/models/watchlist_stock_model.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';
import 'dart:convert';

class WatchlistStocksTable extends StatefulWidget {
  final List<WatchlistStock> stocks;
  final bool isLoading;
  final String? errorMessage;
  final bool isDarkMode;
  final Function(List<SimpleRowModel>)? onDataReady;

  const WatchlistStocksTable({
    Key? key,
    required this.stocks,
    required this.isLoading,
    this.errorMessage,
    required this.isDarkMode,
    this.onDataReady,
  }) : super(key: key);

  @override
  State<WatchlistStocksTable> createState() => _WatchlistStocksTableState();
}

class _WatchlistStocksTableState extends State<WatchlistStocksTable> {
  List<SimpleRowModel> _tableData = [];
  bool _isEnrichingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.stocks.isNotEmpty) {
      _enrichStocksData();
    }
  }

  @override
  void didUpdateWidget(WatchlistStocksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the stocks list has changed (different watchlist selected)
    if (oldWidget.stocks.length != widget.stocks.length || 
        (oldWidget.stocks.isNotEmpty && widget.stocks.isNotEmpty && 
         oldWidget.stocks.first.ticker != widget.stocks.first.ticker)) {
      
      // Clear previous data immediately when watchlist changes
      setState(() {
        _tableData = [];
        _isEnrichingData = false;
      });
      
      // If new watchlist has stocks, enrich the data
      if (widget.stocks.isNotEmpty) {
        _enrichStocksData();
      }
    }
  }

  Future<void> _enrichStocksData() async {
    if (widget.stocks.isEmpty || _isEnrichingData) return;

    print('WatchlistStocksTable: Starting data enrichment for ${widget.stocks.length} stocks');
    
    if (mounted) {
      setState(() {
        _isEnrichingData = true;
      });
    }

    try {
      // Extract ticker IDs for Typesense query
      final tickerIds = widget.stocks.map((stock) => stock.ticker).toList();
      
      // First call: Get stock data from stocks_data collection
      final stockParams = {
        'q': '*',
        'filter_by': 'id:=[${tickerIds.map((id) => '`$id`').join(',')}]',
        'include_fields': r'$stocks_data(id,currentPrice,usdMarketCap,volume,currency)',
        'per_page': '50'
      };

      final stockResponse = await WebService.getTypesense(['collections', 'stocks_data', 'documents', 'search'], stockParams);
      
      // Second call: Get logos and names from company_profile_collection_new
      final logoParams = {
        'q': '*',
        'filter_by': '\$company_profile_collection_new(id:*)&&id:=[${tickerIds.map((id) => '`$id`').join(',')}]',
        'include_fields': r'$stocks_data(name,logo,cp_country,city)',
        'per_page': '50'
      };

      final logoResponse = await WebService.getTypesense(['collections', 'stocks_data', 'documents', 'search'], logoParams);
      
      if (stockResponse.statusCode == 200 && logoResponse.statusCode == 200) {
        final stockData = jsonDecode(stockResponse.body);
        final logoData = jsonDecode(logoResponse.body);
        final stocksHits = stockData['hits'] as List<dynamic>;
        final logoHits = logoData['hits'] as List<dynamic>;
        
        
        // Create a map for stock data
        final stocksMap = <String, dynamic>{};
        for (final stock in stocksHits) {
          final stockDoc = stock['document'];
          stocksMap[stockDoc['id']] = stockDoc;
        }
        
        // Create a map for logo and name data
        final logoMap = <String, Map<String, String>>{};
        for (final logo in logoHits) {
          final doc = logo['document'];
          final companyProfile = doc['company_profile_collection_new'] as Map<String, dynamic>?;
          if (companyProfile != null) {
            final id = doc['id'] as String;
            logoMap[id] = {
              'name': companyProfile['name']?.toString() ?? '',
              'logo': companyProfile['logo']?.toString() ?? '',
            };
          }
        }

        // Build table data using SimpleRowModel
        final tableData = <SimpleRowModel>[];
        
        for (final watchlistStock in widget.stocks) {
          final realTimeData = stocksMap[watchlistStock.ticker];
          final logoData = logoMap[watchlistStock.ticker];
          
          if (realTimeData != null) {
            final addedPrice = watchlistStock.currentPrice;
            final currentPrice = realTimeData['currentPrice']?.toDouble() ?? 0.0;
            final marketCap = realTimeData['usdMarketCap']?.toDouble() ?? 0.0;
            final volume = realTimeData['volume']?.toDouble() ?? 0.0;
            
            // Get logo and name from logoData
            final logo = logoData?['logo'] ?? '';
            final name = logoData?['name'] ?? watchlistStock.ticker;
            
            
            // Calculate gain/loss
            final priceDiff = currentPrice - addedPrice;
            final gainLossPercent = addedPrice > 0 ? (priceDiff / addedPrice) * 100 : 0.0;
            final isGain = priceDiff >= 0;
            
            // Format gain/loss to 1 decimal place
            final formattedGainLoss = double.parse(priceDiff.toStringAsFixed(1));
            
            // Format market cap
            final marketCapFormatted = _formatMarketCap(marketCap);
            
            tableData.add(SimpleRowModel(
              symbol: watchlistStock.ticker,
              name: name,
              logo: logo.isEmpty ? null : logo,
              price: currentPrice,
              changePercent: gainLossPercent,
              isPositive: isGain,
              changeColor: isGain ? Colors.green.shade600 : Colors.red.shade600,
              fields: {
                'addedPrice': addedPrice,
                'currentPrice': currentPrice,
                'gainLoss': formattedGainLoss,
                'marketCap': marketCapFormatted,
                'volume': volume,
              },
            ));
          } else {
            // Fallback if no real-time data available
            tableData.add(SimpleRowModel(
              symbol: watchlistStock.ticker,
              name: watchlistStock.ticker,
              logo: null,
              price: watchlistStock.currentPrice,
              changePercent: 0.0,
              isPositive: true,
              changeColor: Colors.grey,
              fields: {
                'addedPrice': watchlistStock.currentPrice,
                'currentPrice': watchlistStock.currentPrice,
                'gainLoss': 0.0,
                'marketCap': '--',
                'volume': 0.0,
              },
            ));
          }
        }
        
        if (mounted) {
          setState(() {
            _tableData = tableData;
            _isEnrichingData = false;
          });
          
          print('WatchlistStocksTable: Data enrichment completed, ${_tableData.length} items ready');
          // Notify parent widget that data is ready
          widget.onDataReady?.call(_tableData);
        }
      } else {
        _buildFallbackTableData();
      }
    } catch (e) {
      _buildFallbackTableData();
    }
  }

  void _buildFallbackTableData() {
    // Build table data with basic information when Typesense fails
    final tableData = <SimpleRowModel>[];
    
    for (final watchlistStock in widget.stocks) {
      tableData.add(SimpleRowModel(
        symbol: watchlistStock.ticker,
        name: watchlistStock.ticker,
        logo: null,
        price: watchlistStock.currentPrice,
        changePercent: 0.0,
        isPositive: true,
        changeColor: Colors.grey,
        fields: {
          'addedPrice': watchlistStock.currentPrice,
          'currentPrice': watchlistStock.currentPrice,
          'gainLoss': 0.0,
          'marketCap': '--',
          'volume': 0.0,
        },
      ));
    }
    
    if (mounted) {
      setState(() {
        _tableData = tableData;
        _isEnrichingData = false;
      });
      
      // Notify parent widget that data is ready
      widget.onDataReady?.call(_tableData);
    }
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1e12) {
      return '\$${(marketCap / 1e12).toStringAsFixed(1)}T';
    } else if (marketCap >= 1e9) {
      return '\$${(marketCap / 1e9).toStringAsFixed(1)}B';
    } else if (marketCap >= 1e6) {
      return '\$${(marketCap / 1e6).toStringAsFixed(1)}M';
    } else if (marketCap >= 1e3) {
      return '\$${(marketCap / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${marketCap.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('WatchlistStocksTable: build called - isLoading: ${widget.isLoading}, _isEnrichingData: $_isEnrichingData, stocks: ${widget.stocks.length}, _tableData: ${_tableData.length}');
    
    if (widget.isLoading || _isEnrichingData) {
      print('WatchlistStocksTable: showing loading state');
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      print('WatchlistStocksTable: showing error state: ${widget.errorMessage}');
      return _buildErrorState();
    }

    // Show empty state if no stocks in current watchlist
    if (widget.stocks.isEmpty) {
      print('WatchlistStocksTable: showing empty state');
      return _buildEmptyState();
    }

    // Show loading state if we have stocks but no table data yet (data enrichment in progress)
    if (_tableData.isEmpty && widget.stocks.isNotEmpty) {
      print('WatchlistStocksTable: showing loading state (no table data)');
      return _buildLoadingState();
    }

    print('WatchlistStocksTable: showing table with ${_tableData.length} items');
    return _buildTable();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        WatchlistShimmer.listItem(isDarkMode: widget.isDarkMode),
        SizedBox(height: 8),
        WatchlistShimmer.listItem(isDarkMode: widget.isDarkMode),
        SizedBox(height: 8),
        WatchlistShimmer.listItem(isDarkMode: widget.isDarkMode),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            'Failed to load stocks',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            widget.errorMessage ?? 'Unknown error',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Colors.grey,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            'No stocks in this watchlist',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add stocks to get started',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final columns = [
      SimpleColumn(label: 'ADDED', fieldName: 'addedPrice', isNumeric: true, width: 75),
      SimpleColumn(label: 'CURRENT', fieldName: 'currentPrice', isNumeric: true, width: 75),
      SimpleColumn(label: 'GAIN/LOSS', fieldName: 'gainLoss', isNumeric: true, width: 85),
      SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true, width: 85),
      SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true, width: 85),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Match watchlist background
        borderRadius: BorderRadius.circular(4),
      ),
      child: DynamicTable(
        columns: columns,
        rows: _tableData,
        considerPadding: false,
        showFixedColumn: true,
        columnSpacing: 15,
        horizontalMargin: 8,
        fixedColumnWidth: 1.5, // Flex value for fixed column (smaller = less space)
      ),
    );
  }

}
