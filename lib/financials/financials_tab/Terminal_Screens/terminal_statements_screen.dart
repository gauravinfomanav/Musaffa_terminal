import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/financial_expandable_table.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_annual.dart' as annual;
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_quarterly.dart' as quarterly;
import 'package:musaffa_terminal/Controllers/peer_comparison_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';

class TerminalStatementsScreen extends StatefulWidget {
  final String symbol;
  final bool isQuarterly;

  const TerminalStatementsScreen({
    Key? key,
    required this.symbol,
    this.isQuarterly = false,
  }) : super(key: key);

  @override
  State<TerminalStatementsScreen> createState() => _TerminalStatementsScreenState();
}

class _TerminalStatementsScreenState extends State<TerminalStatementsScreen> {
  
  // Single controllers for annual and quarterly
  late annual.FinancialStatementsController annualController;
  late quarterly.FinancialStatementsQuarterlyController quarterlyController;
  
  // Data storage for each statement type
  final RxList<annual.FinancialStatementModel> annualIncomeData = <annual.FinancialStatementModel>[].obs;
  final RxList<annual.FinancialStatementModel> annualBalanceData = <annual.FinancialStatementModel>[].obs;
  final RxList<annual.FinancialStatementModel> annualCashflowData = <annual.FinancialStatementModel>[].obs;
  
  final RxList<quarterly.FinancialStatementModel> quarterlyIncomeData = <quarterly.FinancialStatementModel>[].obs;
  final RxList<quarterly.FinancialStatementModel> quarterlyBalanceData = <quarterly.FinancialStatementModel>[].obs;
  final RxList<quarterly.FinancialStatementModel> quarterlyCashflowData = <quarterly.FinancialStatementModel>[].obs;
  
  final RxList<String> annualYears = <String>[].obs;
  final RxList<String> quarterlyQuarters = <String>[].obs;
  
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    
    // Initialize single controllers
    annualController = Get.put(annual.FinancialStatementsController());
    quarterlyController = Get.put(quarterly.FinancialStatementsQuarterlyController());
    
    // Fetch all data
    _fetchAllData();
    
    // Initialize peer comparison
    _initializePeerComparison();
  }

  /// Initialize peer comparison for statements screen
  Future<void> _initializePeerComparison() async {
    try {
      // Get peer comparison controller
      final peerController = Get.find<PeerComparisonController>();
      
      // Wait a bit for data to load
      await Future.delayed(Duration(seconds: 1));
      
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
      print('Error initializing peer comparison in statements: $e');
    }
  }

  Future<void> _fetchAllData() async {
    isLoading.value = true;
    
    try {
      // Create separate controller instances for each statement type
      final annualIncomeController = Get.put(annual.FinancialStatementsController(), tag: 'annual_income');
      final annualBalanceController = Get.put(annual.FinancialStatementsController(), tag: 'annual_balance');
      final annualCashflowController = Get.put(annual.FinancialStatementsController(), tag: 'annual_cashflow');
      
      final quarterlyIncomeController = Get.put(quarterly.FinancialStatementsQuarterlyController(), tag: 'quarterly_income');
      final quarterlyBalanceController = Get.put(quarterly.FinancialStatementsQuarterlyController(), tag: 'quarterly_balance');
      final quarterlyCashflowController = Get.put(quarterly.FinancialStatementsQuarterlyController(), tag: 'quarterly_cashflow');
      
      // Fetch all data in parallel
      await Future.wait([
        annualIncomeController.fetchFinancialReport(widget.symbol, 'ic'),
        annualBalanceController.fetchFinancialReport(widget.symbol, 'bs'),
        annualCashflowController.fetchFinancialReport(widget.symbol, 'cf'),
        quarterlyIncomeController.fetchFinancialReport(widget.symbol, 'ic'),
        quarterlyBalanceController.fetchFinancialReport(widget.symbol, 'bs'),
        quarterlyCashflowController.fetchFinancialReport(widget.symbol, 'cf'),
      ]);
      
      // Store the data
      annualIncomeData.assignAll(annualIncomeController.financialData);
      annualBalanceData.assignAll(annualBalanceController.financialData);
      annualCashflowData.assignAll(annualCashflowController.financialData);
      annualYears.assignAll(annualIncomeController.years);
      
      quarterlyIncomeData.assignAll(quarterlyIncomeController.financialData);
      quarterlyBalanceData.assignAll(quarterlyBalanceController.financialData);
      quarterlyCashflowData.assignAll(quarterlyCashflowController.financialData);
      quarterlyQuarters.assignAll(quarterlyIncomeController.quarters);
      
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading.value) {
        return _buildLoadingShimmer();
      }
      
      if (widget.isQuarterly) {
        return _buildQuarterlyTables();
      } else {
        return _buildAnnualTables();
      }
    });
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatementShimmer('INCOME STATEMENT'),
          const SizedBox(height: 20),
          _buildStatementShimmer('BALANCE SHEET'),
          const SizedBox(height: 20),
          _buildStatementShimmer('CASH FLOW'),
        ],
      ),
    );
  }

  Widget _buildStatementShimmer(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidgets.perShareTableShimmer(),
      ],
    );
  }

  Widget _buildAnnualTables() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatementTable(
            annualIncomeData,
            annualYears,
            'Metric',
          ),
          const SizedBox(height: 20),
          _buildCombinedBalanceSheetAndCashFlowTable(
            annualBalanceData,
            annualCashflowData,
            annualYears,
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterlyTables() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatementTable(
            quarterlyIncomeData,
            quarterlyQuarters,
            'Metric',
          ),
          const SizedBox(height: 20),
          _buildCombinedBalanceSheetAndCashFlowTable(
            quarterlyBalanceData,
            quarterlyCashflowData,
            quarterlyQuarters,
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedBalanceSheetAndCashFlowTable(RxList balanceData, RxList cashflowData, RxList<String> periods) {
    if (balanceData.isEmpty && cashflowData.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('No data available'),
            ),
          ),
        ],
      );
    }

    // Combine balance sheet and cash flow data
    List<dynamic> combinedData = [];
    combinedData.addAll(balanceData);
    combinedData.addAll(cashflowData);

    final transformedData = FinancialDataTransformer.transformFinancialStatements(
      combinedData,
      periods,
    );

    final columns = _buildFinancialColumns(periods, 'Metric');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
          child: FinancialExpandableTable(
            columns: columns,
            data: transformedData,
            showNameColumn: false,
            rowHeight: 40,
            headerHeight: 32,
            indentSize: 20,
            expandIconSize: 14,
            considerPadding: false,
            showYoYGrowth: true, // Enable YoY Growth column
            showThreeYearAvg: true, // Enable 3-Year Average column
            showTwoYearCAGR: true, // Enable 2-Year CAGR column
            showFiveYearCAGR: true, // Enable 5-Year CAGR column
            showStandardDeviation: true, // Enable Standard Deviation column
          ),
        ),
      ],
    );
  }

  Widget _buildStatementTable(RxList data, RxList<String> periods, String columnTitle) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('No data available')),
          ),
        ],
      );
    }

    final columns = _buildFinancialColumns(periods, columnTitle);
    final transformedData = FinancialDataTransformer.transformFinancialStatements(
      data,
      periods,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
          child: FinancialExpandableTable(
            columns: columns,
            data: transformedData,
            showNameColumn: false,
            rowHeight: 40,
            headerHeight: 32,
            indentSize: 20,
            expandIconSize: 14,
            considerPadding: false,
            showYoYGrowth: true, // Enable YoY Growth column
            showThreeYearAvg: true, // Enable 3-Year Average column
            showTwoYearCAGR: true, // Enable 2-Year CAGR column
            showFiveYearCAGR: true, // Enable 5-Year CAGR column
            showStandardDeviation: true, // Enable Standard Deviation column
          ),
        ),
      ],
    );
  }

  List<FinancialExpandableColumn> _buildFinancialColumns(List<String> periods, String title) {
    List<FinancialExpandableColumn> columns = [
      FinancialExpandableColumn(
        key: 'metric',
        title: title,
        width: 200,
        alignment: TextAlign.left,
      ),
    ];

    columns.addAll(periods.map((period) {
      return FinancialExpandableColumn(
        key: period,
        title: period,
        width: 80,
        isNumeric: true,
        alignment: TextAlign.right,
      );
    }));

    return columns;
  }
}
