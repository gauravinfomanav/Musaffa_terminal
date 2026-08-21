import 'package:flutter/material.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_per_share_screen.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_ratios_screen.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_statements_screen.dart';
import 'package:musaffa_terminal/Components/reusable_bar_graph.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financials',
                    style: HomeUi.sectionTitle(isDarkMode).copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Per-share metrics, ratios, and full statements',
                    style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                // Fixed equal height — avoids IntrinsicHeight + mouse_tracker crash.
                const topRowHeight = 360.0;

                final perShare = TerminalPerShareScreen(
                  symbol: widget.symbol,
                  currency: widget.currency,
                  title: 'Per Share Data',
                  height: topRowHeight,
                  onMetricSelected: (metric) {
                    // Defer — avoids mouse_tracker assert during pointer updates.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => selectedMetric = metric);
                    });
                  },
                );
                final chart = _buildDynamicChart(
                  isDarkMode,
                  height: topRowHeight,
                );

                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      perShare,
                      const SizedBox(height: 12),
                      chart,
                    ],
                  );
                }

                return SizedBox(
                  height: topRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 55, child: perShare),
                      const SizedBox(width: 12),
                      Expanded(flex: 45, child: chart),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TerminalRatiosScreen(
              symbol: widget.symbol,
              title: 'Company Financials',
            ),
            const SizedBox(height: 12),
            TerminalStatementsScreen(
              symbol: widget.symbol,
              title: 'Financial Statements',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicChart(bool isDarkMode, {required double height}) {
    return Container(
      height: height,
      decoration: HomeUi.cardDecoration(isDarkMode),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: ShimmerWidgets.chartShimmer(
              baseColor: HomeUi.elevatedBg(isDarkMode),
              highlightColor: HomeUi.borderLight(isDarkMode),
              width: 400,
              height: height - 40,
            ),
          );
        }

        final financialData = controller.financialData.value;
        if (financialData == null) {
          return Center(
            child: Text(
              'No chart data available',
              style: HomeUi.subtitle(isDarkMode),
            ),
          );
        }

        final chartData =
            _getRealChartDataForMetric(selectedMetric, financialData);

        return TerminalBarChart(
          title: selectedMetric,
          data: chartData,
          unit: '',
          height: (height - 72).clamp(200.0, 400.0),
          barColor: HomeUi.accent(isDarkMode),
          titleWidget: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getShortMetricName(selectedMetric),
                      style: HomeUi.sectionTitle(isDarkMode).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedMetric,
                      style:
                          HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildMetricToggleButton(isDarkMode),
            ],
          ),
        );
      }),
    );
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
    return HomeUi.ghostAction(
      label: 'Next',
      dark: isDarkMode,
      icon: Icons.swap_vert_rounded,
      onTap: () {
        final currentIndex = availableMetrics.indexOf(selectedMetric);
        final nextIndex = (currentIndex + 1) % availableMetrics.length;
        setState(() => selectedMetric = availableMetrics[nextIndex]);
      },
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
