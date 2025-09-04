import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/per_share_data_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalPerShareScreen extends StatefulWidget {
  final String symbol;
  final String currency;

  const TerminalPerShareScreen({
    Key? key,
    required this.symbol,
    required this.currency,
  }) : super(key: key);

  @override
  State<TerminalPerShareScreen> createState() => _TerminalPerShareScreenState();
}

class _TerminalPerShareScreenState extends State<TerminalPerShareScreen> {
  late FinancialFundamentalsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FinancialFundamentalsController());
    controller.fetchFinancialFundamentals(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading Per Share Data...',
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

      final financialData = controller.financialData.value;
      if (financialData == null) {
        return Center(
          child: Text(
            'No per share data available',
            style: TextStyle(
              fontSize: 11,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      return _buildTerminalPerShareTable(financialData, isDarkMode);
    });
  }

  Widget _buildTerminalPerShareTable(FinancialFundamentals financialData, bool isDarkMode) {
    // Get all available years from all data sources
    Set<String> allYears = {};
    
    if (financialData.revenuePerShareTTM != null) {
      allYears.addAll(financialData.revenuePerShareTTM!.keys);
    }
    if (financialData.ebitPerShareTTM != null) {
      allYears.addAll(financialData.ebitPerShareTTM!.keys);
    }
    if (financialData.epsTTM != null) {
      allYears.addAll(financialData.epsTTM!.keys);
    }
    if (financialData.dividendPerShareTTM != null) {
      allYears.addAll(financialData.dividendPerShareTTM!.keys);
    }
    if (financialData.epsData != null) {
      allYears.addAll(financialData.epsData!.keys);
    }
    
    List<String> sortedYears = allYears.toList()..sort((a, b) => b.compareTo(a));

    // Define metrics with their data
    final metrics = [
      {
        'name': 'Revenue per Share (TTM)',
        'data': financialData.revenuePerShareTTM,
      },
      {
        'name': 'EBIT per Share (TTM)',
        'data': financialData.ebitPerShareTTM,
      },
      {
        'name': 'Earnings per Share (EPS) (TTM)',
        'data': financialData.epsTTM,
      },
      {
        'name': 'Dividend per Share (TTM)',
        'data': financialData.dividendPerShareTTM,
      },
    ];

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
                  'Per Share Metrics',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
            ...sortedYears.map((year) => DataColumn(
              label: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  year,
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
          rows: metrics.map((metric) {
            final metricName = metric['name'] as String;
            final data = metric['data'] as Map<String, double?>?;
            
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
                ...sortedYears.map((year) {
                  final value = data?[year];
                  
                  return DataCell(
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        value != null ? value.toStringAsFixed(2) : '--',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
