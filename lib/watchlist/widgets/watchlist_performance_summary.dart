import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class WatchlistPerformanceSummary extends StatelessWidget {
  final List<SimpleRowModel> tableData;
  final bool isDarkMode;

  const WatchlistPerformanceSummary({
    Key? key,
    required this.tableData,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('WatchlistPerformanceSummary: Building with ${tableData.length} items');
    if (tableData.isEmpty) {
      return _buildEmptyState();
    }

    final performanceData = _calculatePerformanceMetrics();

    return _buildPerformanceSummary(performanceData);
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

    for (final stock in tableData) {
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
      'totalDayPLPercent': totalDayPLPercent / tableData.length,
      'bestPerformer': bestPerformer,
      'bestTicker': bestTicker,
      'worstPerformer': worstPerformer,
      'worstTicker': worstTicker,
      'maxVolume': maxVolume,
      'volumeLeader': volumeLeader,
      'near52WeekHigh': near52WeekHigh,
    };
  }

  Widget _buildPerformanceSummary(Map<String, dynamic> data) {
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
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$volumeLeader ${_formatVolume(maxVolume)}',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
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
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$near52WeekHigh stocks',
                    style: DashboardTextStyles.stockName.copyWith(
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
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
            ],
          ),
        ),
        // Empty state
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Text(
            'No performance data available',
            style: DashboardTextStyles.stockName.copyWith(
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
}
