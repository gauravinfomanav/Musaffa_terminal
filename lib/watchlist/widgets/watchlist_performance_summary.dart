import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/Controllers/portfolio_backtest_controller.dart';
import 'package:musaffa_terminal/models/backtest_models.dart';
import 'package:intl/intl.dart';

class WatchlistPerformanceSummary extends StatefulWidget {
  final List<SimpleRowModel> tableData;
  final bool isDarkMode;

  const WatchlistPerformanceSummary({
    Key? key,
    required this.tableData,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<WatchlistPerformanceSummary> createState() => _WatchlistPerformanceSummaryState();
}

class _WatchlistPerformanceSummaryState extends State<WatchlistPerformanceSummary> {
  bool _showPastPerformance = false;
  late PortfolioBacktestController _backtestController;

  @override
  void initState() {
    super.initState();
    _backtestController = Get.put(PortfolioBacktestController());
    // Initialize with watchlist stocks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final symbols = widget.tableData.map((stock) => stock.symbol).toList();
      _backtestController.selectedStocks.value = symbols;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('WatchlistPerformanceSummary: Building with ${widget.tableData.length} items');
    if (widget.tableData.isEmpty) {
      return _buildEmptyState();
    }

    final performanceData = _calculatePerformanceMetrics();

    return Column(
      children: [
        _buildPerformanceSummary(performanceData, widget.isDarkMode),
        if (_showPastPerformance) ...[
          const SizedBox(height: 12),
          _buildPastPerformanceResults(),
        ],
      ],
    );
  }

  Map<String, dynamic> _calculatePerformanceMetrics() {
    double totalDayPL = 0.0;
    double totalDayPLPercent = 0.0;
    double bestPerformer = 0.0;
    String bestTicker = '';
    double worstPerformer = 0.0;
    String worstTicker = '';
    double maxVolume = 0.0;
    String volumeLeader = '';
    int near52WeekHigh = 0;

    for (final stock in widget.tableData) {
      final volume = (stock.fields['volume'] as num?)?.toDouble() ?? 0.0;
      final gainLoss = (stock.fields['gainLoss'] as num?)?.toDouble() ?? 0.0;
      final changePercent = stock.changePercent?.toDouble() ?? 0.0;

      // Calculate day P&L (assuming 1 share per stock for simplicity)
      totalDayPL += gainLoss;
      totalDayPLPercent += changePercent;

      // Track best performer
      if (changePercent > bestPerformer) {
        bestPerformer = changePercent;
        bestTicker = stock.symbol;
      }

      // Track worst performer
      if (changePercent < worstPerformer) {
        worstPerformer = changePercent;
        worstTicker = stock.symbol;
      }

      // Track volume leader
      if (volume > maxVolume) {
        maxVolume = volume;
        volumeLeader = stock.symbol;
      }

      // Count stocks near 52-week high (assuming if price is within 5% of high)
      // For now, we'll use a simple heuristic based on positive performance
      if (changePercent > 0) {
        near52WeekHigh++;
      }
    }

    return {
      'totalDayPL': totalDayPL,
      'totalDayPLPercent': totalDayPLPercent / widget.tableData.length,
      'bestPerformer': bestPerformer,
      'bestTicker': bestTicker,
      'worstPerformer': worstPerformer,
      'worstTicker': worstTicker,
      'maxVolume': maxVolume,
      'volumeLeader': volumeLeader,
      'near52WeekHigh': near52WeekHigh,
    };
  }

  Widget _buildPerformanceSummary(Map<String, dynamic> data, bool isDarkMode) {
    final totalDayPL = data['totalDayPL'] as double;
    final totalDayPLPercent = data['totalDayPLPercent'] as double;
    final bestPerformer = data['bestPerformer'] as double;
    final bestTicker = data['bestTicker'] as String;
    final worstPerformer = data['worstPerformer'] as double;
    final worstTicker = data['worstTicker'] as String;
    final maxVolume = data['maxVolume'] as double;
    final volumeLeader = data['volumeLeader'] as String;
    final near52WeekHigh = data['near52WeekHigh'] as int;

    final isPositivePL = totalDayPL >= 0;
    final plColor = isPositivePL ? Colors.green.shade600 : Colors.red.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PERFORMANCE SUMMARY',
                style: DashboardTextStyles.columnHeader.copyWith(
                  color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showPastPerformance = !_showPastPerformance;
                  });
                  if (_showPastPerformance) {
                    _showDatePicker();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 12,
                        color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Past Performance',
                        style: DashboardTextStyles.tickerSymbol.copyWith(
                          color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Performance metrics
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Day P&L
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day P&L:',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${isPositivePL ? '+' : ''}\$${totalDayPL.toStringAsFixed(2)}',
                        style: DashboardTextStyles.stockName.copyWith(
                          color: plColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${isPositivePL ? '+' : ''}${totalDayPLPercent.toStringAsFixed(1)}%)',
                        style: DashboardTextStyles.stockName.copyWith(
                          color: plColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Best/Worst performers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Best:',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$bestTicker ${bestPerformer >= 0 ? '+' : ''}${bestPerformer.toStringAsFixed(1)}%',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: Colors.green.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Worst:',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$worstTicker ${worstPerformer >= 0 ? '+' : ''}${worstPerformer.toStringAsFixed(1)}%',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: Colors.red.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Volume leader
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Volume Leader:',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$volumeLeader ${_formatVolume(maxVolume)}',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Near 52-week high
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Positive Movers:',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$near52WeekHigh stocks',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PERFORMANCE SUMMARY',
                style: DashboardTextStyles.columnHeader.copyWith(
                  color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Empty state
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Text(
            'No performance data available',
            style: DashboardTextStyles.stockName.copyWith(
              color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1e9) {
      return '${(volume / 1e9).toStringAsFixed(1)}B';
    } else if (volume >= 1e6) {
      return '${(volume / 1e6).toStringAsFixed(1)}M';
    } else if (volume >= 1e3) {
      return '${(volume / 1e3).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }

  Widget _buildPastPerformanceResults() {
    return Obx(() {
      if (_backtestController.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading past performance...',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }

      if (_backtestController.errorMessage.value.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF2D1B1B) : Colors.red[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.isDarkMode ? const Color(0xFF5C2A2A) : Colors.red[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _backtestController.errorMessage.value,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    color: widget.isDarkMode ? Colors.red[300] : Colors.red[800],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (_backtestController.backtestResult.value == null) {
        return const SizedBox.shrink();
      }

      final result = _backtestController.backtestResult.value!;
      return _buildSimpleResultsDisplay(result);
    });
  }

  Widget _buildSimpleResultsDisplay(BacktestResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date range
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Past Performance Results',
                style: DashboardTextStyles.columnHeader.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('MMM dd, yyyy').format(result.backtestDate)} - ${DateFormat('MMM dd, yyyy').format(result.currentDate)}',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 10,
              color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          
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
              const SizedBox(width: 6),
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Return %',
                  '${result.totalReturnPercent.toStringAsFixed(2)}%',
                  result.totalReturnPercent >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricCard(
                  'Total Value',
                  _formatCurrency(result.currentValue),
                  result.currentValue >= result.initialInvestment ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Annualized Return',
                  '${result.annualizedReturn.toStringAsFixed(2)}%/year',
                  result.annualizedReturn >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricCard(
                  'Win Rate',
                  '${_calculateWinRate(result.stockPerformances)}%',
                  _calculateWinRate(result.stockPerformances) >= 50 ? Colors.green : Colors.red,
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 9,
              color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: DashboardTextStyles.stockName.copyWith(
              fontSize: 10,
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

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _backtestController.backtestDate.value,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF007AFF), // iOS blue
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF1C1C1E), // iOS dark text
              onSurfaceVariant: const Color(0xFF8E8E93), // iOS secondary text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF007AFF),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFFF2F2F7), // iOS light gray
              headerForegroundColor: const Color(0xFF1C1C1E),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF1C1C1E);
              }),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF007AFF);
                }
                return Colors.transparent;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      _backtestController.setCustomDate(picked);
      // Automatically run backtest after selecting date
      _backtestController.runBacktest();
    }
  }
}
