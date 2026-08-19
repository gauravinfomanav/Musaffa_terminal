import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
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
    if (widget.tableData.isEmpty) {
      return _buildEmptyState();
    }

    final performanceData = _calculatePerformanceMetrics();

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          _buildPerformanceSummary(performanceData, widget.isDarkMode),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: _showPastPerformance
                ? Padding(
                    key: const ValueKey('past-performance'),
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildPastPerformanceResults(),
                  )
                : const SizedBox.shrink(key: ValueKey('past-performance-hidden')),
          ),
        ],
      ),
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
    final plColor =
        isPositivePL ? HomeUi.positive(isDarkMode) : HomeUi.negative(isDarkMode);

    return Container(
      decoration: HomeUi.cardDecoration(isDarkMode),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: HomeUi.tableToolbarHeader(
                    isDarkMode,
                    icon: Icons.insights_outlined,
                    title: 'Performance Summary',
                    subtitleText: 'Live day metrics for this watchlist',
                  ),
                ),
                const SizedBox(width: 8),
                _PastPerformanceToggle(
                  isDarkMode: isDarkMode,
                  isActive: _showPastPerformance,
                  onTap: () {
                    setState(() => _showPastPerformance = !_showPastPerformance);
                    if (_showPastPerformance) {
                      _showDatePicker();
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                _PlHeroBand(
                  isDark: isDarkMode,
                  isPositive: isPositivePL,
                  amount:
                      '${isPositivePL ? '+' : ''}\$${totalDayPL.toStringAsFixed(2)}',
                  percent:
                      '${isPositivePL ? '+' : ''}${totalDayPLPercent.toStringAsFixed(1)}%',
                  percentValue: totalDayPLPercent,
                  color: plColor,
                ),
                const SizedBox(height: 4),
                _KpiStrip(
                  isDark: isDarkMode,
                  items: [
                    _KpiItem(
                      label: 'Best',
                      ticker: bestTicker.isEmpty ? '--' : bestTicker,
                      value:
                          '${bestPerformer >= 0 ? '+' : ''}${bestPerformer.toStringAsFixed(1)}%',
                      valueColor: HomeUi.positive(isDarkMode),
                    ),
                    _KpiItem(
                      label: 'Worst',
                      ticker: worstTicker.isEmpty ? '--' : worstTicker,
                      value:
                          '${worstPerformer >= 0 ? '+' : ''}${worstPerformer.toStringAsFixed(1)}%',
                      valueColor: HomeUi.negative(isDarkMode),
                    ),
                    _KpiItem(
                      label: 'Volume',
                      ticker: volumeLeader.isEmpty ? '--' : volumeLeader,
                      value: _formatVolume(maxVolume),
                    ),
                    _KpiItem(
                      label: 'Movers',
                      ticker: '$near52WeekHigh',
                      value: 'stocks',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: HomeUi.cardDecoration(widget.isDarkMode),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'No performance data available',
          style: HomeUi.subtitle(widget.isDarkMode),
        ),
      ),
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
          padding: const EdgeInsets.all(20),
          decoration: HomeUi.cardDecoration(widget.isDarkMode),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    HomeUi.accent(widget.isDarkMode),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Loading past performance…',
                style: HomeUi.subtitle(widget.isDarkMode),
              ),
            ],
          ),
        );
      }

      if (_backtestController.errorMessage.value.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HomeUi.negativeSoft(widget.isDarkMode),
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(color: HomeUi.negative(widget.isDarkMode).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: HomeUi.negative(widget.isDarkMode), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _backtestController.errorMessage.value,
                  style: HomeUi.bodyText(widget.isDarkMode).copyWith(
                    color: HomeUi.negative(widget.isDarkMode),
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
    final isDark = widget.isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: HomeUi.cardDecoration(isDark),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDark,
            icon: Icons.timeline_rounded,
            title: 'Past Performance',
            subtitleText:
                '${DateFormat('MMM dd, yyyy').format(result.backtestDate)} – ${DateFormat('MMM dd, yyyy').format(result.currentDate)}',
          ),
          const SizedBox(height: 14),
          _KpiStrip(
            isDark: isDark,
            items: [
              _KpiItem(
                label: 'Best',
                ticker: result.bestPerformer?.symbol ?? '--',
                value: result.bestPerformer?.formattedGainPercent ?? '--',
                valueColor: result.bestPerformer?.gainPercent != null &&
                        result.bestPerformer!.gainPercent >= 0
                    ? HomeUi.positive(isDark)
                    : HomeUi.negative(isDark),
              ),
              _KpiItem(
                label: 'Worst',
                ticker: result.worstPerformer?.symbol ?? '--',
                value: result.worstPerformer?.formattedGainPercent ?? '--',
                valueColor: result.worstPerformer?.gainPercent != null &&
                        result.worstPerformer!.gainPercent >= 0
                    ? HomeUi.positive(isDark)
                    : HomeUi.negative(isDark),
              ),
              _KpiItem(
                label: 'Return',
                ticker: '${result.totalReturnPercent.toStringAsFixed(1)}%',
                value: _formatCurrency(result.currentValue),
                valueColor: result.totalReturnPercent >= 0
                    ? HomeUi.positive(isDark)
                    : HomeUi.negative(isDark),
              ),
              _KpiItem(
                label: 'Win rate',
                ticker: '${_calculateWinRate(result.stockPerformances)}%',
                value:
                    '${result.annualizedReturn.toStringAsFixed(1)}% / yr',
                valueColor: _calculateWinRate(result.stockPerformances) >= 50
                    ? HomeUi.positive(isDark)
                    : HomeUi.negative(isDark),
              ),
            ],
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
    final DateTime? picked = await HomeUi.pickDate(
      context,
      initialDate: _backtestController.backtestDate.value,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      _backtestController.setCustomDate(picked);
      // Automatically run backtest after selecting date
      _backtestController.runBacktest();
    }
  }
}

class _PastPerformanceToggle extends StatefulWidget {
  final bool isDarkMode;
  final bool isActive;
  final VoidCallback onTap;

  const _PastPerformanceToggle({
    required this.isDarkMode,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_PastPerformanceToggle> createState() => _PastPerformanceToggleState();
}

class _PastPerformanceToggleState extends State<_PastPerformanceToggle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: HomeUi.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: widget.isActive || _hover ? HomeUi.iconWellGradient : null,
            color: widget.isActive || _hover ? null : HomeUi.elevatedBg(widget.isDarkMode),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: widget.isActive || _hover
                  ? HomeUi.iconWellBorder
                  : HomeUi.borderLight(widget.isDarkMode),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HomeUi.brandIcon(
                icon: Icons.history_rounded,
                size: HomeUi.iconSm,
              ),
              const SizedBox(width: 6),
              Text(
                'Past Performance',
                style: HomeUi.label(widget.isDarkMode).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlHeroBand extends StatefulWidget {
  final bool isDark;
  final bool isPositive;
  final String amount;
  final String percent;
  final double percentValue;
  final Color color;

  const _PlHeroBand({
    required this.isDark,
    required this.isPositive,
    required this.amount,
    required this.percent,
    required this.percentValue,
    required this.color,
  });

  @override
  State<_PlHeroBand> createState() => _PlHeroBandState();
}

class _PlHeroBandState extends State<_PlHeroBand> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tint = widget.isPositive
        ? HomeUi.positiveSoft(widget.isDark)
        : HomeUi.negativeSoft(widget.isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.color.withValues(alpha: _hover ? 0.28 : 0.14),
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAY P&L',
                      style: HomeUi.overline(widget.isDark).copyWith(
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeUi.heading(widget.isDark).copyWith(
                        fontSize: 22,
                        letterSpacing: -0.6,
                        color: widget.color,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              HomeUi.signedPercentPill(
                widget.isDark,
                widget.percent,
                widget.percentValue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiItem {
  final String label;
  final String ticker;
  final String value;
  final Color? valueColor;

  const _KpiItem({
    required this.label,
    required this.ticker,
    required this.value,
    this.valueColor,
  });
}

class _KpiStrip extends StatelessWidget {
  final bool isDark;
  final List<_KpiItem> items;

  const _KpiStrip({
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: HomeUi.borderLight(isDark),
              ),
            Expanded(child: _KpiStat(isDark: isDark, item: items[i])),
          ],
        ],
      ),
    );
  }
}

class _KpiStat extends StatelessWidget {
  final bool isDark;
  final _KpiItem item;

  const _KpiStat({
    required this.isDark,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HomeUi.overline(isDark).copyWith(
            fontSize: 9.5,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.ticker,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HomeUi.tableCellEmphasis(isDark).copyWith(fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HomeUi.tableNumeric(
            isDark,
            positiveValue: item.valueColor == HomeUi.positive(isDark)
                ? true
                : item.valueColor == HomeUi.negative(isDark)
                    ? false
                    : null,
          ).copyWith(
            fontSize: 12,
            color: item.valueColor ?? HomeUi.muted(isDark),
          ),
        ),
      ],
    );
  }
}

