import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/models/backtest_models.dart';
import 'package:musaffa_terminal/models/historical_price_model.dart';
import 'package:intl/intl.dart';

class PortfolioBacktestController extends GetxController {
  // Observable variables
  final RxList<String> selectedStocks = <String>[].obs;
  final RxDouble investmentAmount = 10000.0.obs;
  final Rx<DateTime> backtestDate = DateTime.now().subtract(Duration(days: 365)).obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Backtest results
  final Rx<BacktestResult?> backtestResult = Rx<BacktestResult?>(null);
  final RxList<StockPerformance> stockPerformances = <StockPerformance>[].obs;
  
  // Date selection
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    // Initialize with 1 year ago (but ensure it's within 2020-2025 range)
    final oneYearAgo = DateTime.now().subtract(Duration(days: 365));
    backtestDate.value = oneYearAgo.isBefore(DateTime(2020, 1, 1)) 
        ? DateTime(2020, 1, 1) 
        : oneYearAgo;
  }


  /// Set custom date
  void setCustomDate(DateTime date) {
    selectedDate.value = date;
    backtestDate.value = date;
  }

  /// Add stock to backtest
  void addStock(String symbol) {
    if (!selectedStocks.contains(symbol)) {
      selectedStocks.add(symbol);
    }
  }

  /// Remove stock from backtest
  void removeStock(String symbol) {
    selectedStocks.remove(symbol);
  }

  /// Set investment amount
  void setInvestmentAmount(double amount) {
    investmentAmount.value = amount;
  }

  /// Run backtest
  Future<void> runBacktest() async {
    if (selectedStocks.isEmpty) {
      errorMessage.value = 'Please select at least one stock';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      print('🚀 Starting backtest for stocks: ${selectedStocks.join(", ")}');
      print('📅 Backtest date: ${backtestDate.value}');
      
      // Get current prices
      print('📊 Fetching current prices...');
      final currentPrices = await _getCurrentPrices(selectedStocks);
      print('✅ Current prices: $currentPrices');
      
      // Get historical prices
      print('📈 Fetching historical prices...');
      final historicalPrices = await _getHistoricalPrices(selectedStocks);
      print('✅ Historical prices: ${historicalPrices.keys.join(", ")}');
      
      // Calculate results
      print('🧮 Calculating results...');
      final result = _calculateBacktestResults(
        currentPrices: currentPrices,
        historicalPrices: historicalPrices,
        investmentAmount: investmentAmount.value,
        backtestDate: backtestDate.value,
      );
      
      print('✅ Backtest completed successfully');
      print('📊 Results: Initial=${result.initialInvestment}, Current=${result.currentValue}, Return=${result.totalReturnPercent}%');
      
      backtestResult.value = result;
      stockPerformances.value = result.stockPerformances;
      
    } catch (e) {
      print('❌ Backtest error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      errorMessage.value = 'Error running backtest: $e';
      backtestResult.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current prices from existing Typesense API
  Future<Map<String, double>> _getCurrentPrices(List<String> symbols) async {
    print('🔍 Fetching current prices for: ${symbols.join(", ")}');
    final Map<String, double> currentPrices = {};
    
    for (String symbol in symbols) {
      try {
        print('📊 Fetching price for $symbol...');
        
        // Use existing search service to get current price
        final response = await WebService.getTypesense([
          'collections',
          'stocks_data',
          'documents',
          'search'
        ], {
          "q": "*",
          "filter_by": "id:=[`$symbol`]",
          "per_page": "1"
        });
        
        print('📡 API Response status: ${response.statusCode}');
        print('📡 API Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('📊 Parsed data: $data');
          
          if (data['hits'] != null && data['hits'].isNotEmpty) {
            final stockData = data['hits'][0]['document'];
            print('📊 Stock data: $stockData');
            
            final price = stockData['currentPrice'] ?? stockData['price'] ?? 0.0;
            currentPrices[symbol] = (price as num).toDouble();
            print('✅ Got price for $symbol: ${currentPrices[symbol]}');
          } else {
            print('⚠️ No data found for $symbol');
            currentPrices[symbol] = 0.0;
          }
        } else {
          print('❌ API error for $symbol: ${response.statusCode}');
          currentPrices[symbol] = 0.0;
        }
      } catch (e) {
        print('❌ Error fetching current price for $symbol: $e');
        currentPrices[symbol] = 0.0;
      }
    }
    
    print('📊 Final current prices: $currentPrices');
    return currentPrices;
  }

  /// Get historical prices from your API
  Future<Map<String, HistoricalPrice>> _getHistoricalPrices(List<String> symbols) async {
    final dateString = DateFormat('yyyy-MM-dd').format(backtestDate.value);
    print('📈 Fetching historical prices for: ${symbols.join(", ")} on $dateString');
    
    final response = await WebService.getHistoricalPrices(
      symbols: symbols,
      date: dateString,
    );
    
    print('📡 Historical API Response status: ${response.statusCode}');
    print('📡 Historical API Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('📊 Historical data: $data');
      
      if (data['results'] != null) {
        final results = data['results'] as List;
        print('📊 Historical results count: ${results.length}');
        
        final historicalPrices = <String, HistoricalPrice>{
          for (final item in results)
            item['company_symbol'] as String: HistoricalPrice.fromJson(item)
        };
        
        print('✅ Historical prices: ${historicalPrices.keys.join(", ")}');
        return historicalPrices;
      } else {
        print('❌ No results in historical data');
        throw Exception('No results in historical data');
      }
    } else {
      print('❌ Historical API error: ${response.statusCode}');
      if (response.statusCode == 404) {
        throw Exception('No historical data available for the selected date. Try a more recent date (2020-2024).');
      } else {
        throw Exception('Failed to fetch historical prices: ${response.statusCode}');
      }
    }
  }

  /// Calculate backtest results
  BacktestResult _calculateBacktestResults({
    required Map<String, double> currentPrices,
    required Map<String, HistoricalPrice> historicalPrices,
    required double investmentAmount,
    required DateTime backtestDate,
  }) {
    final List<StockPerformance> performances = [];
    double totalHistoricalValue = 0.0;
    double totalCurrentValue = 0.0;
    
    // Calculate equal weight allocation (1 share per stock for comparison)
    final double sharesPerStock = 1.0;
    
    for (String symbol in selectedStocks) {
      final double currentPrice = currentPrices[symbol] ?? 0.0;
      final HistoricalPrice? historicalPrice = historicalPrices[symbol];
      
      if (historicalPrice != null && currentPrice > 0) {
        final double historicalPriceValue = historicalPrice.close;
        final double historicalValue = sharesPerStock * historicalPriceValue;
        final double currentValue = sharesPerStock * currentPrice;
        final double gain = currentValue - historicalValue;
        final double gainPercent = ((currentPrice - historicalPriceValue) / historicalPriceValue) * 100;
        
        performances.add(StockPerformance(
          symbol: symbol,
          historicalPrice: historicalPriceValue,
          currentPrice: currentPrice,
          sharesBought: sharesPerStock,
          currentValue: currentValue,
          gain: gain,
          gainPercent: gainPercent,
        ));
        
        totalHistoricalValue += historicalValue;
        totalCurrentValue += currentValue;
      }
    }
    
    final double totalReturn = totalCurrentValue - totalHistoricalValue;
    final double totalReturnPercent = totalHistoricalValue > 0 ? (totalReturn / totalHistoricalValue) * 100 : 0.0;
    
    // Calculate annualized return
    final int daysDiff = DateTime.now().difference(backtestDate).inDays;
    final double years = daysDiff / 365.25;
    final double annualizedReturn = years > 0 ? (totalReturnPercent / years) : 0.0;
    
    return BacktestResult(
      initialInvestment: totalHistoricalValue,
      currentValue: totalCurrentValue,
      totalReturn: totalReturn,
      totalReturnPercent: totalReturnPercent,
      annualizedReturn: annualizedReturn,
      stockPerformances: performances,
      backtestDate: backtestDate,
      currentDate: DateTime.now(),
    );
  }

  /// Clear results
  void clearResults() {
    backtestResult.value = null;
    stockPerformances.clear();
  }

  /// Reset to default values
  void reset() {
    selectedStocks.clear();
    investmentAmount.value = 10000.0;
    final oneYearAgo = DateTime.now().subtract(Duration(days: 365));
    backtestDate.value = oneYearAgo.isBefore(DateTime(2020, 1, 1)) 
        ? DateTime(2020, 1, 1) 
        : oneYearAgo;
    selectedDate.value = null;
    clearResults();
  }
}
