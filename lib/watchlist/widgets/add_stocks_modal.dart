import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/web_service.dart';

class AddStocksModal extends StatefulWidget {
  final String watchlistName;
  final String watchlistId;

  const AddStocksModal({
    Key? key,
    required this.watchlistName,
    required this.watchlistId,
  }) : super(key: key);

  @override
  State<AddStocksModal> createState() => _AddStocksModalState();
}

class _AddStocksModalState extends State<AddStocksModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final WatchlistController _watchlistController = Get.find<WatchlistController>();
  
  List<TickerModel> _searchResults = [];
  Set<String> _selectedTickers = {};
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when modal opens
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

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await SearchService.searchStocks(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _toggleSelection(String ticker) {
    print('DEBUG: Toggling selection for ticker: $ticker');
    setState(() {
      if (_selectedTickers.contains(ticker)) {
        _selectedTickers.remove(ticker);
        print('DEBUG: Removed ticker: $ticker');
      } else {
        _selectedTickers.add(ticker);
        print('DEBUG: Added ticker: $ticker');
        
        // Clear search field and results after selection
        _searchController.clear();
        _searchResults.clear();
        _searchFocusNode.requestFocus(); // Keep focus on search field
      }
      print('DEBUG: Current selected tickers: $_selectedTickers');
    });
  }

  Future<List<Map<String, dynamic>>> _fetchRealTimePricesForSelectedStocks() async {
    final stocksToAdd = <Map<String, dynamic>>[];
    
    try {
      // Get real-time prices from Typesense for selected stocks
      final tickerIds = _selectedTickers.toList();
      final params = {
        'q': '*',
        'filter_by': 'id:=[${tickerIds.map((id) => '`$id`').join(',')}]',
        'include_fields': r'$stocks_data(id,currentPrice)',
        'per_page': '50'
      };
      
      final response = await WebService.getTypesense(['collections', 'stocks_data', 'documents', 'search'], params);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List<dynamic>? ?? [];
        
        // Create a map of ticker -> current price
        final priceMap = <String, double>{};
        for (final hit in hits) {
          final document = hit['document'] as Map<String, dynamic>?;
          if (document != null) {
            final ticker = document['id']?.toString() ?? '';
            final price = document['currentPrice']?.toDouble() ?? 0.0;
            priceMap[ticker] = price;
          }
        }
        
        // Build stocks data with real-time prices
        for (String selectedTicker in _selectedTickers) {
          final currentPrice = priceMap[selectedTicker] ?? 1.0; // Fallback to 1.0 if no price found
          stocksToAdd.add({
            'ticker': selectedTicker,
            'current_price': currentPrice,
          });
        }
      } else {
        // Fallback: use 1.0 as price if API fails
        for (String selectedTicker in _selectedTickers) {
          stocksToAdd.add({
            'ticker': selectedTicker,
            'current_price': 1.0,
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error fetching real-time prices: $e');
      // Fallback: use 1.0 as price if error occurs
      for (String selectedTicker in _selectedTickers) {
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Fetch real-time prices for selected stocks
    final stocksToAdd = await _fetchRealTimePricesForSelectedStocks();

    print('DEBUG: Selected tickers: $_selectedTickers');
    print('DEBUG: Search results count: ${_searchResults.length}');
    for (var ticker in _searchResults) {
      print('DEBUG: Search result - symbol: ${ticker.symbol}, ticker: ${ticker.ticker}, name: ${ticker.companyName}');
    }
    print('DEBUG: Stocks to add: $stocksToAdd');
    print('DEBUG: Watchlist ID: ${widget.watchlistId}');

    final success = await _watchlistController.addStocksToWatchlist(stocksToAdd);
    
    if (success) {
      Get.back(); // Close modal
      // Show success message with proper styling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${_selectedTickers.length} stocks to "${widget.watchlistName}"',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF374151) : const Color(0xFF6B7280),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    } else {
      // Show error message with proper styling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _watchlistController.stocksErrorMessage.value,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
        child: Center(
          child: Container(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.7,
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 500,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(isDarkMode),
                
                // Search bar
                _buildSearchBar(isDarkMode),
                
                // Results section
                Expanded(
                  child: _buildResultsSection(isDarkMode),
                ),
                
                // Bottom action bar
                _buildBottomBar(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add Stocks to "${widget.watchlistName}"',
              style: DashboardTextStyles.columnHeader.copyWith(
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _performSearch,
        decoration: InputDecoration(
          hintText: 'Search stocks...',
          hintStyle: TextStyle(
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
        ),
        style: TextStyle(
          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildResultsSection(bool isDarkMode) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(
          'No stocks found',
          style: TextStyle(
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      if (_selectedTickers.isNotEmpty) {
        return Column(
          children: [
            // Selected stocks header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'SELECTED STOCKS (${_selectedTickers.length})',
                    style: DashboardTextStyles.columnHeader.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Selected stocks list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedTickers.length,
                itemBuilder: (context, index) {
                  final ticker = _selectedTickers.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildSelectedStockItem(ticker, isDarkMode),
                  );
                },
              ),
            ),
          ],
        );
      }
      
      return Center(
        child: Text(
          'Search for stocks to add to your watchlist',
          style: TextStyle(
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final ticker = _searchResults[index];
        final tickerSymbol = ticker.symbol ?? ticker.ticker ?? '';
        final isSelected = _selectedTickers.contains(tickerSymbol);
        
        return _buildSearchResultItem(ticker, isSelected, isDarkMode);
      },
    );
  }

  Widget _buildSelectedStockItem(String ticker, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Remove button
          GestureDetector(
            onTap: () => _toggleSelection(ticker),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  width: 1,
                ),
                color: Colors.transparent,
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 1,
                  color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Ticker symbol
          Expanded(
            child: Text(
              ticker,
              style: DashboardTextStyles.stockName.copyWith(
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(TickerModel ticker, bool isSelected, bool isDarkMode) {
    final tickerSymbol = ticker.symbol ?? ticker.ticker ?? '';
    print('DEBUG: Building search result item - symbol: ${ticker.symbol}, ticker: ${ticker.ticker}, final: $tickerSymbol');
    
    return GestureDetector(
      onTap: () => _toggleSelection(tickerSymbol),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Checkbox - terminal style
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151))
                      : (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                  width: 1,
                ),
                color: isSelected 
                    ? (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151))
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Logo
            Container(
              width: 24,
              height: 24,
              child: showLogo(
                tickerSymbol,
                ticker.logo ?? '',
                sideWidth: 24,
                name: ticker.companyName ?? ticker.name ?? '',
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Ticker and Company Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tickerSymbol,
                    style: DashboardTextStyles.stockName.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ticker.companyName ?? ticker.name ?? '',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price (if available)
            if (ticker.currentPrice != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${ticker.currentPrice!.toStringAsFixed(2)}',
                    style: DashboardTextStyles.dataCell.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (ticker.percentChange != null)
                    Text(
                      '${ticker.percentChange! >= 0 ? '+' : ''}${ticker.percentChange!.toStringAsFixed(2)}%',
                      style: DashboardTextStyles.dataCell.copyWith(
                        color: ticker.percentChange! >= 0 
                            ? Colors.green.shade600 
                            : Colors.red.shade600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedTickers.length} selected',
            style: TextStyle(
              color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          // Cancel button - terminal style
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Text(
                'CANCEL',
                style: DashboardTextStyles.columnHeader.copyWith(
                  color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add Selected button - terminal style
          GestureDetector(
            onTap: _selectedTickers.isEmpty ? null : _addSelectedStocks,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedTickers.isEmpty 
                    ? (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB))
                    : (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB)),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Text(
                'ADD SELECTED',
                style: DashboardTextStyles.columnHeader.copyWith(
                  color: _selectedTickers.isEmpty 
                      ? (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                      : (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151)),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
