import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/financial_expandable_table.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_annual.dart' as annual;
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_quarterly.dart' as quarterly;

class TerminalStatementsScreen extends StatefulWidget {
  final String symbol;

  const TerminalStatementsScreen({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  State<TerminalStatementsScreen> createState() => _TerminalStatementsScreenState();
}

class _TerminalStatementsScreenState extends State<TerminalStatementsScreen> {
  bool isQuarterly = false;
  
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

  void togglePeriod() {
    setState(() {
      isQuarterly = !isQuarterly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (isQuarterly) {
        return _buildQuarterlyTables();
      } else {
        return _buildAnnualTables();
      }
    });
  }

  Widget _buildAnnualTables() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatementTable(
            'INCOME STATEMENT',
            annualIncomeData,
            annualYears,
            'Income Statement',
          ),
          const SizedBox(height: 20),
          _buildStatementTable(
            'BALANCE SHEET',
            annualBalanceData,
            annualYears,
            'Balance Sheet',
          ),
          const SizedBox(height: 20),
          _buildStatementTable(
            'CASH FLOW',
            annualCashflowData,
            annualYears,
            'Cash Flow',
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
            'INCOME STATEMENT',
            quarterlyIncomeData,
            quarterlyQuarters,
            'Income Statement',
          ),
          const SizedBox(height: 20),
          _buildStatementTable(
            'BALANCE SHEET',
            quarterlyBalanceData,
            quarterlyQuarters,
            'Balance Sheet',
          ),
          const SizedBox(height: 20),
          _buildStatementTable(
            'CASH FLOW',
            quarterlyCashflowData,
            quarterlyQuarters,
            'Cash Flow',
          ),
        ],
      ),
    );
  }

  Widget _buildStatementTable(String title, RxList data, RxList<String> periods, String columnTitle) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('No $title data available')),
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
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
