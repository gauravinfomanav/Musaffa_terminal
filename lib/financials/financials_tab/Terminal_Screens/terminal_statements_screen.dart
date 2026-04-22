import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/Components/financial_expandable_table.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_annual.dart'
    as annual;
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_quarterly.dart'
    as quarterly;
import 'package:musaffa_terminal/Controllers/peer_comparison_controller.dart';
import 'package:musaffa_terminal/Controllers/stock_details_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalStatementsScreen extends StatefulWidget {
  final String symbol;
  final bool isQuarterly;
  final String? title;

  const TerminalStatementsScreen({
    Key? key,
    required this.symbol,
    this.isQuarterly = false,
    this.title,
  }) : super(key: key);

  @override
  State<TerminalStatementsScreen> createState() =>
      _TerminalStatementsScreenState();
}

class _TerminalStatementsScreenState extends State<TerminalStatementsScreen> {
  // Single controllers for annual and quarterly
  late annual.FinancialStatementsController annualController;
  late quarterly.FinancialStatementsQuarterlyController quarterlyController;

  // Data storage for each statement type
  final RxList<annual.FinancialStatementModel> annualIncomeData =
      <annual.FinancialStatementModel>[].obs;
  final RxList<annual.FinancialStatementModel> annualBalanceData =
      <annual.FinancialStatementModel>[].obs;
  final RxList<annual.FinancialStatementModel> annualCashflowData =
      <annual.FinancialStatementModel>[].obs;

  final RxList<quarterly.FinancialStatementModel> quarterlyIncomeData =
      <quarterly.FinancialStatementModel>[].obs;
  final RxList<quarterly.FinancialStatementModel> quarterlyBalanceData =
      <quarterly.FinancialStatementModel>[].obs;
  final RxList<quarterly.FinancialStatementModel> quarterlyCashflowData =
      <quarterly.FinancialStatementModel>[].obs;

  final RxList<String> annualYears = <String>[].obs;
  final RxList<String> quarterlyQuarters = <String>[].obs;

  final RxBool isLoading = true.obs;

  double _getResponsiveStatementsColumnSpacing(List<String> periods) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Mirrors this screen's outer layout: container margin (12+12) and inner padding (12+12).
    final usableWidth = (screenWidth - 48).clamp(0, double.infinity).toDouble();

    const metricColumnWidth = 200.0;
    const periodColumnWidth = 80.0;
    const derivedStatColumnsCount = 5;
    const derivedStatColumnWidth = 110.0;

    final centerColumnCount = periods.length + derivedStatColumnsCount;
    if (centerColumnCount <= 1) {
      return 40;
    }

    final centerColumnsWidth =
        (periods.length * periodColumnWidth) +
        (derivedStatColumnsCount * derivedStatColumnWidth);

    final availableCenterWidth = (usableWidth - metricColumnWidth)
        .clamp(0, double.infinity)
        .toDouble();

    final spacingSlots = centerColumnCount - 1;
    final calculatedSpacing =
        (availableCenterWidth - centerColumnsWidth) / spacingSlots;

    return calculatedSpacing.clamp(40, 100).toDouble();
  }

  @override
  void initState() {
    super.initState();

    // Initialize single controllers
    annualController = Get.put(annual.FinancialStatementsController());
    quarterlyController =
        Get.put(quarterly.FinancialStatementsQuarterlyController());

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
          sector: stockData.musaffaSector ??
              'Technology', // Use actual sector or fallback
          industry: stockData.musaffaIndustry ??
              'Software', // Use actual industry or fallback
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
      final annualIncomeController =
          Get.put(annual.FinancialStatementsController(), tag: 'annual_income');
      final annualBalanceController = Get.put(
          annual.FinancialStatementsController(),
          tag: 'annual_balance');
      final annualCashflowController = Get.put(
          annual.FinancialStatementsController(),
          tag: 'annual_cashflow');

      final quarterlyIncomeController = Get.put(
          quarterly.FinancialStatementsQuarterlyController(),
          tag: 'quarterly_income');
      final quarterlyBalanceController = Get.put(
          quarterly.FinancialStatementsQuarterlyController(),
          tag: 'quarterly_balance');
      final quarterlyCashflowController = Get.put(
          quarterly.FinancialStatementsQuarterlyController(),
          tag: 'quarterly_cashflow');

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
      quarterlyCashflowData
          .assignAll(quarterlyCashflowController.financialData);
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
            title: 'COMPANY FINANCIALS',
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
            title: 'COMPANY FINANCIALS',
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

  Widget _buildCombinedBalanceSheetAndCashFlowTable(
      RxList balanceData, RxList cashflowData, RxList<String> periods) {
    if (balanceData.isEmpty && cashflowData.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'No data available',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Combine balance sheet and cash flow data
    List<dynamic> combinedData = [];
    combinedData.addAll(balanceData);
    combinedData.addAll(cashflowData);

    final transformedData =
        FinancialDataTransformer.transformFinancialStatements(
      combinedData,
      periods,
    );

    final responsiveColumnSpacing =
        _getResponsiveStatementsColumnSpacing(periods);

    final columns = _buildFinancialColumns(periods, 'Metric');

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DynamicTableFromWeb(
          title: widget.title,
          columns: columns,
          rows: _mapFinancialRowsToDynamicRows(transformedData),
          paginated: false,
          selectable: false,
          showTickerCell: false,
          enableColumnFilters: false,
          loading: isLoading.value,
          rowHeight: 40,
          headerHeight: 32,
          indentSize: 20,
          considerPadding: false,
          showNameColumn: false,
          showYoYGrowth: true,
          showThreeYearAvg: true,
          showTwoYearCAGR: true,
          showFiveYearCAGR: true,
          showStandardDeviation: true,
          compactPinnedLayout: true,
          autoPinStatColumns: false,
          showPinnedSectionDividers: false,
          columnSpacing: responsiveColumnSpacing,
        ),
      ),
    );
  }

  Widget _buildStatementTable(
      RxList data, RxList<String> periods, String columnTitle,
      {String? title}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 12,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    final columns = _buildFinancialColumns(periods, columnTitle);
    final transformedData =
        FinancialDataTransformer.transformFinancialStatements(
      data,
      periods,
    );

    final responsiveColumnSpacing =
        _getResponsiveStatementsColumnSpacing(periods);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: DynamicTableFromWeb(
          title: title,
          columns: columns,
          rows: _mapFinancialRowsToDynamicRows(transformedData),
          paginated: false,
          selectable: false,
          showTickerCell: false,  
          enableColumnFilters: false,
          loading: isLoading.value,
          rowHeight: 40,
          headerHeight: 32,
          indentSize: 20,
          considerPadding: false,
          showNameColumn: false,
          showYoYGrowth: true,
          showThreeYearAvg: true,
          showTwoYearCAGR: true,
          showFiveYearCAGR: true,
          showStandardDeviation: true,
          compactPinnedLayout: true,
          autoPinStatColumns: false,
          showPinnedSectionDividers: false,
          columnSpacing: responsiveColumnSpacing,
        ),
      ),
    );
  }

  List<DynamicTableColumn> _buildFinancialColumns(
      List<String> periods, String title) {
    List<DynamicTableColumn> columns = [
      DynamicTableColumn(
        key: 'metric',
        label: title,
        width: 200,
        align: TextAlign.left,
        sortable: false,
      ),
    ];

    columns.addAll(periods.map((period) {
      return DynamicTableColumn(
        key: period,
        label: period,
        width: 80,
        align: TextAlign.center,
        sortable: true,
      );
    }));

    return columns;
  }

  List<DynamicTableRow> _mapFinancialRowsToDynamicRows(
    List<FinancialExpandableRowData> rows, {
    int level = 0,
  }) {
    return rows.map((row) {
      final children = row.children == null
          ? null
          : _mapFinancialRowsToDynamicRows(row.children!, level: level + 1);
      return DynamicTableRow(
        id: row.id,
        data: row.data,
        isExpandable: row.isExpandable,
        isExpanded: row.isExpanded,
        children: children,
        level: row.level > 0 ? row.level : level,
      );
    }).toList();
  }
}
