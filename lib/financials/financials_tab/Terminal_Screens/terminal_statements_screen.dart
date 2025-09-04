import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_annual.dart' as annual;
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/statements_chart_quarterly.dart' as quarterly;
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalStatementsScreen extends StatefulWidget {
  final String symbol;
  final String currency;

  const TerminalStatementsScreen({
    Key? key,
    required this.symbol,
    required this.currency,
  }) : super(key: key);

  @override
  State<TerminalStatementsScreen> createState() => _TerminalStatementsScreenState();
}

class _TerminalStatementsScreenState extends State<TerminalStatementsScreen> {
  int selectedStatementIndex = 0; // 0: Income Statement, 1: Balance Sheet, 2: Cash Flow
  int selectedPeriodIndex = 0; // 0: Annual, 1: Quarterly
  
  final List<String> statementNames = ["Income Statement", "Balance Sheet", "Cash Flow"];
  final List<String> periodNames = ["Annual", "Quarterly"];
  
  late annual.FinancialStatementsController annualController;
  late quarterly.FinancialStatementsQuarterlyController quarterlyController;

  @override
  void initState() {
    super.initState();
    annualController = Get.put(annual.FinancialStatementsController());
    quarterlyController = Get.put(quarterly.FinancialStatementsQuarterlyController());
    
    // Fetch initial data
    _fetchData();
  }

  void _fetchData() {
    final reportType = selectedStatementIndex == 0 ? 'ic' : selectedStatementIndex == 1 ? 'bs' : 'cf';
    
    if (selectedPeriodIndex == 0) {
      annualController.fetchFinancialReport(widget.symbol, reportType);
    } else {
      quarterlyController.fetchFinancialReport(widget.symbol, reportType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Statement type selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(
              statementNames.length,
              (index) => Expanded(
                child: _buildStatementButton(
                  statementNames[index],
                  selectedStatementIndex == index,
                  () {
                    setState(() {
                      selectedStatementIndex = index;
                    });
                    _fetchData();
                  },
                  isDarkMode,
                ),
              ),
            ),
          ),
        ),
        
        // Period selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(
              periodNames.length,
              (index) => Expanded(
                child: _buildPeriodButton(
                  periodNames[index],
                  selectedPeriodIndex == index,
                  () {
                    setState(() {
                      selectedPeriodIndex = index;
                    });
                    _fetchData();
                  },
                  isDarkMode,
                ),
              ),
            ),
          ),
        ),
        
        // Data table
        Expanded(
          child: selectedPeriodIndex == 0
              ? _buildAnnualTable(isDarkMode)
              : _buildQuarterlyTable(isDarkMode),
        ),
      ],
    );
  }

  Widget _buildStatementButton(String title, bool isSelected, VoidCallback onPressed, bool isDarkMode) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
              : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected 
                ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: isSelected 
                ? Colors.white
                : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String title, bool isSelected, VoidCallback onPressed, bool isDarkMode) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? const Color(0xFF4B5563) : const Color(0xFF6B7280))
              : (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected 
                ? (isDarkMode ? const Color(0xFF4B5563) : const Color(0xFF6B7280))
                : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFD1D5DB)),
            width: 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: isSelected 
                ? Colors.white
                : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnualTable(bool isDarkMode) {
    return Obx(() {
      if (annualController.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading Annual Data...',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }

      if (annualController.financialData.isEmpty) {
        return Center(
          child: Text(
            'No annual data available',
            style: TextStyle(
              fontSize: 11,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      return _buildTerminalDataTable(
        annualController.financialData.toList(),
        annualController.years.toList(),
        isDarkMode,
        'Annual',
      );
    });
  }

  Widget _buildQuarterlyTable(bool isDarkMode) {
    return Obx(() {
      if (quarterlyController.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading Quarterly Data...',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }

      if (quarterlyController.financialData.isEmpty) {
        return Center(
          child: Text(
            'No quarterly data available',
            style: TextStyle(
              fontSize: 11,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      return _buildTerminalDataTable(
        quarterlyController.financialData.toList(),
        quarterlyController.quarters.toList(),
        isDarkMode,
        'Quarterly',
      );
    });
  }

  Widget _buildTerminalDataTable(List<dynamic> data, List<String> periods, bool isDarkMode, String periodType) {
    // Group data by metric name
    Map<String, Map<String, String>> groupedData = {};
    
    for (var item in data) {
      final metricName = item.name;
      final period = item.year;
      final value = item.originalValue;
      
      if (!groupedData.containsKey(metricName)) {
        groupedData[metricName] = {};
      }
      groupedData[metricName]![period] = value;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 8,
          horizontalMargin: 8,
          headingRowColor: MaterialStateProperty.all(
            isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
          ),
          dataRowColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
            }
            return null;
          }),
          columns: [
            DataColumn(
              label: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  statementNames[selectedStatementIndex],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
            ...periods.map((period) => DataColumn(
              label: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
                  ),
                ),
              ),
            )),
          ],
          rows: groupedData.entries.map((entry) {
            final metricName = entry.key;
            final values = entry.value;
            
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      metricName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                ...periods.map((period) => DataCell(
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      values[period] ?? '--',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
