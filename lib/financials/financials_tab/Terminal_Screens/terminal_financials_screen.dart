import 'package:flutter/material.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_per_share_screen.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_ratios_screen.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_statements_screen.dart';
import 'package:musaffa_terminal/Components/reusable_bar_graph.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/per_share_data_controller.dart';
import 'package:musaffa_terminal/Controllers/peer_comparison_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';
import 'package:get/get.dart';

class TerminalFinancialsScreen extends StatefulWidget {
  final String symbol;
  final String currency;
  final bool isQuarterly;

  const TerminalFinancialsScreen({
    Key? key,
    required this.symbol,
    required this.currency,
    this.isQuarterly = false,
  }) : super(key: key);

  @override
  State<TerminalFinancialsScreen> createState() => _TerminalFinancialsScreenState();
}

class _TerminalFinancialsScreenState extends State<TerminalFinancialsScreen> { 
  String selectedMetric = 'Revenue per Share (TTM)'; 
  late FinancialFundamentalsController controller;
  late PeerComparisonController peerController;
  
  // List of available metrics for cycling
  final List<String> availableMetrics = [
    'Revenue per Share (TTM)',
    'EBIT per Share (TTM)',
    'Earnings per Share (EPS) (TTM)',
    'Dividend per Share (TTM)',
    'EPS Annual Data',
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.put(FinancialFundamentalsController());
    controller.fetchFinancialFundamentals(widget.symbol);
    
    // Initialize peer comparison controller
    peerController = Get.put(PeerComparisonController());
    _fetchPeerComparison();
  }

  /// Fetch peer comparison data
  Future<void> _fetchPeerComparison() async {
    try {
      // Wait a bit for the financial data to load
      await Future.delayed(Duration(seconds: 2));
      
      // Get actual sector/industry from stock details controller
      final stockDetailsController = Get.find<StockDetailsController>();
      final stockData = stockDetailsController.stockData.value;
      
      if (stockData != null) {
        await peerController.fetchPeerStocks(
          currentStockTicker: widget.symbol,
          sector: stockData.musaffaSector ?? 'Technology', // Use actual sector or fallback
          industry: stockData.musaffaIndustry ?? 'Software', // Use actual industry or fallback
          country: stockData.country ?? 'US', // Use actual country or fallback
          limit: 5,
        );
      } else {
        // Fallback if stock data not available
        await peerController.fetchPeerStocks(
          currentStockTicker: widget.symbol,
          sector: 'Technology',
          industry: 'Software',
          country: 'US',
          limit: 5,
        );
      }
    } catch (e) {
      print('Error fetching peer comparison: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTerminalTitle(isDarkMode, title: 'PER SHARE DATA'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TerminalPerShareScreen(
                    symbol: widget.symbol,
                    currency: widget.currency,
                    onMetricSelected: (metric) {
                      setState(() {
                        selectedMetric = metric;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildDynamicChart(isDarkMode),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTerminalTitle(isDarkMode, title: 'COMPANY FINANCIALS'),
            TerminalRatiosScreen(symbol: widget.symbol),
            const SizedBox(height: 12),
            _buildTerminalTitle(isDarkMode, title: 'FINANCIAL STATEMENTS'),
            TerminalStatementsScreen(symbol: widget.symbol),
          ],
        ),
      ),
    );
  }


  Widget _buildTerminalTitle(bool isDarkMode, {String title = 'PER SHARE DATA'}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: Constants.FONT_DEFAULT_NEW,
          color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildDynamicChart(bool isDarkMode) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
            ),
          ),
        );
      }

      final financialData = controller.financialData.value;
      if (financialData == null) {
        return Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 12,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      // Get real data based on selected metric
      List<BarData> chartData = _getRealChartDataForMetric(selectedMetric, financialData);
      
      return TerminalBarChart(
        title: selectedMetric,
        data: chartData,
        unit: '',
        titleWidget: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedMetric,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
              ),
            ),
            _buildMetricToggleButton(isDarkMode),
          ],
        ),
      );
    });
  }

  List<BarData> _getRealChartDataForMetric(String metric, FinancialFundamentals financialData) {
    Map<String, double?>? dataMap;
    
    // Get the appropriate data map based on selected metric
    switch (metric) {
      case 'Revenue per Share (TTM)':
        dataMap = financialData.revenuePerShareTTM;
        break;
      case 'EBIT per Share (TTM)':
        dataMap = financialData.ebitPerShareTTM;
        break;
      case 'Earnings per Share (EPS) (TTM)':
        dataMap = financialData.epsTTM;
        break;
      case 'Dividend per Share (TTM)':
        dataMap = financialData.dividendPerShareTTM;
        break;
      case 'EPS Annual Data':
        // Convert epsData Map<String, double> to Map<String, double?>
        dataMap = financialData.epsData?.map((key, value) => MapEntry(key, value));
        break;
      default:
        dataMap = financialData.revenuePerShareTTM;
    }
    
    if (dataMap == null || dataMap.isEmpty) {
      return [];
    }
    
    // Convert the data map to BarData list and sort by year
    List<BarData> chartData = dataMap.entries
        .where((entry) => entry.value != null)
        .map((entry) => BarData(year: entry.key, value: entry.value!))
        .toList();
    
    // Sort by year (ascending)
    chartData.sort((a, b) => a.year.compareTo(b.year));
    
    return chartData;
  }

  Widget _buildMetricToggleButton(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        final currentIndex = availableMetrics.indexOf(selectedMetric);
        final nextIndex = (currentIndex + 1) % availableMetrics.length;
        setState(() => selectedMetric = availableMetrics[nextIndex]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getShortMetricName(selectedMetric),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_up,
              size: 14,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortMetricName(String fullName) {
    switch (fullName) {
      case 'Revenue per Share (TTM)':
        return 'Revenue';
      case 'EBIT per Share (TTM)':
        return 'EBIT';
      case 'Earnings per Share (EPS) (TTM)':
        return 'EPS';
      case 'Dividend per Share (TTM)':
        return 'Dividend';
      case 'EPS Annual Data':
        return 'EPS Annual';
      default:
        return fullName;
    }
  }


}
