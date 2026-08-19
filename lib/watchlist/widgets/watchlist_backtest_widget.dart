import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Controllers/portfolio_backtest_controller.dart';
import 'package:musaffa_terminal/models/backtest_models.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class WatchlistBacktestWidget extends StatelessWidget {
  final List<String> watchlistStocks;
  
  const WatchlistBacktestWidget({
    Key? key,
    required this.watchlistStocks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PortfolioBacktestController());
    
    // Initialize with watchlist stocks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedStocks.value = List.from(watchlistStocks);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildViewPastPerformanceButton(controller),
        const SizedBox(height: 12),
        _buildResults(controller),
      ],
    );
  }

  Widget _buildViewPastPerformanceButton(PortfolioBacktestController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : () => _showDatePicker(controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: DashboardTextStyles.accentColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: controller.isLoading.value
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(DashboardTextStyles.accentColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading...',
                  style: DashboardTextStyles.buttonText.copyWith(
                    color: DashboardTextStyles.accentColor,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: DashboardTextStyles.accentColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'View Past Performance',
                  style: DashboardTextStyles.buttonText.copyWith(
                    color: DashboardTextStyles.accentColor,
                  ),
                ),
              ],
            ),
      ),
    ));
  }

  Widget _buildResults(PortfolioBacktestController controller) {
    return Obx(() {
      if (controller.errorMessage.value.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            ],
          ),
        );
      }

      if (controller.backtestResult.value == null) {
        return const SizedBox.shrink(); // Don't show anything if no results
      }

      final result = controller.backtestResult.value!;
      return _buildSimpleResultsDisplay(result);
    });
  }

  Widget _buildSimpleResultsDisplay(BacktestResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date range
          Row(
            children: [
              Icon(Icons.trending_up, color: DashboardTextStyles.accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Past Performance Results',
                style: DashboardTextStyles.columnHeader.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('MMM dd, yyyy').format(result.backtestDate)} - ${DateFormat('MMM dd, yyyy').format(result.currentDate)}',
            style: DashboardTextStyles.tickerSymbol,
          ),
          const SizedBox(height: 12),
          
          // Key metrics in a simple row layout
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Best Performer',
                  result.bestPerformer != null 
                    ? '${result.bestPerformer!.symbol} (${result.bestPerformer!.formattedGainPercent})'
                    : '--',
                  result.bestPerformer?.gainPercent != null && result.bestPerformer!.gainPercent >= 0 
                    ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Worst Performer',
                  result.worstPerformer != null 
                    ? '${result.worstPerformer!.symbol} (${result.worstPerformer!.formattedGainPercent})'
                    : '--',
                  result.worstPerformer?.gainPercent != null && result.worstPerformer!.gainPercent >= 0 
                    ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Return %',
                  '${result.totalReturnPercent.toStringAsFixed(2)}%',
                  result.totalReturnPercent >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Total Value',
                  _formatCurrency(result.currentValue),
                  result.currentValue >= result.initialInvestment ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Annualized Return',
                  '${result.annualizedReturn.toStringAsFixed(2)}%/year',
                  result.annualizedReturn >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Win Rate',
                  '${_calculateWinRate(result.stockPerformances)}%',
                  _calculateWinRate(result.stockPerformances) >= 50 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Volatility',
                  '${_calculateVolatility(result.stockPerformances).toStringAsFixed(1)}%',
                  _calculateVolatility(result.stockPerformances) <= 15 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Risk Level',
                  _getRiskLevel(_calculateVolatility(result.stockPerformances)),
                  _calculateVolatility(result.stockPerformances) <= 15 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DashboardTextStyles.stockName.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Format currency with commas (e.g., 1,000.00)
  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  /// Calculate win rate percentage
  int _calculateWinRate(List<StockPerformance> performances) {
    if (performances.isEmpty) return 0;
    final winningStocks = performances.where((stock) => stock.gainPercent > 0).length;
    return ((winningStocks / performances.length) * 100).round();
  }

  /// Calculate volatility (standard deviation of returns)
  double _calculateVolatility(List<StockPerformance> performances) {
    if (performances.isEmpty) return 0.0;
    
    // Calculate average return
    final averageReturn = performances.fold(0.0, (sum, stock) => sum + stock.gainPercent) / performances.length;
    
    // Calculate variance
    final variance = performances.fold(0.0, (sum, stock) {
      final deviation = stock.gainPercent - averageReturn;
      return sum + (deviation * deviation);
    }) / performances.length;
    
    // Return standard deviation (volatility)
    return sqrt(variance);
  }

  /// Get risk level based on volatility
  String _getRiskLevel(double volatility) {
    if (volatility <= 10) return 'Low';
    if (volatility <= 20) return 'Medium';
    return 'High';
  }

  Future<void> _showDatePicker(PortfolioBacktestController controller) async {
    final DateTime? picked = await HomeUi.pickDate(
      Get.context!,
      initialDate: controller.backtestDate.value,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      controller.setCustomDate(picked);
      // Automatically run backtest after selecting date
      controller.runBacktest();
    }
  }
}
