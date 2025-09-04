import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/ratios_annual_controller.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/ratios_quarterly_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalRatiosScreen extends StatefulWidget {
  final String symbol;
  final String currency;

  const TerminalRatiosScreen({
    Key? key,
    required this.symbol,
    required this.currency,
  }) : super(key: key);

  @override
  State<TerminalRatiosScreen> createState() => _TerminalRatiosScreenState();
}

class _TerminalRatiosScreenState extends State<TerminalRatiosScreen> {
  int selectedPeriodIndex = 0; // 0: Annual, 1: Quarterly
  
  final List<String> periodNames = ["Annual", "Quarterly"];
  
  late RatiosController annualController;
  late QuarterlyRatiosController quarterlyController;

  @override
  void initState() {
    super.initState();
    annualController = Get.put(RatiosController());
    quarterlyController = Get.put(QuarterlyRatiosController());
    
    // Fetch initial data
    _fetchData();
  }

  void _fetchData() {
    if (selectedPeriodIndex == 0) {
      annualController.fetchRatio(widget.symbol);
    } else {
      quarterlyController.fetchQuarterlyRatios(widget.symbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
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
              ? _buildAnnualRatiosTable(isDarkMode)
              : _buildQuarterlyRatiosTable(isDarkMode),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String title, bool isSelected, VoidCallback onPressed, bool isDarkMode) {
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

  Widget _buildAnnualRatiosTable(bool isDarkMode) {
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
                'Loading Annual Ratios...',
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

      if (annualController.yearlyRatiosMap.isEmpty) {
        return Center(
          child: Text(
            'No annual ratios data available',
            style: TextStyle(
              fontSize: 11,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      return _buildTerminalRatiosTable(
        annualController.yearlyRatiosMap,
        annualController.years.toList(),
        isDarkMode,
        'Annual',
      );
    });
  }

  Widget _buildQuarterlyRatiosTable(bool isDarkMode) {
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
                'Loading Quarterly Ratios...',
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

      if (!quarterlyController.processingComplete.value || quarterlyController.tableData.isEmpty) {
        return Center(
          child: Text(
            'No quarterly ratios data available',
            style: TextStyle(
              fontSize: 11,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        );
      }

      return _buildTerminalQuarterlyRatiosTable(
        quarterlyController.tableData.toList(),
        quarterlyController.quarters.toList(),
        isDarkMode,
        'Quarterly',
      );
    });
  }

  Widget _buildTerminalRatiosTable(Map<String, YearlyRatios> ratiosMap, List<String> years, bool isDarkMode, String periodType) {
    // Get all unique ratio names
    Set<String> allRatioNames = {};
    for (var yearlyRatios in ratiosMap.values) {
      allRatioNames.addAll(yearlyRatios.ratios.keys);
    }
    
    List<String> sortedRatioNames = allRatioNames.toList()..sort();

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
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Financial Ratios',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
            ...years.map((year) => DataColumn(
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
          rows: sortedRatioNames.map((ratioName) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 180,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      ratioName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                ...years.map((year) {
                  final yearlyRatios = ratiosMap[year];
                  final value = yearlyRatios?.getRatio(ratioName);
                  
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

  Widget _buildTerminalQuarterlyRatiosTable(List<dynamic> tableData, List<String> quarters, bool isDarkMode, String periodType) {
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
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Financial Ratios',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
            ...quarters.map((quarter) => DataColumn(
              label: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  quarter,
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
          rows: tableData.map((ratioData) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 180,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      ratioData.metric,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                ...quarters.map((quarter) {
                  final value = ratioData.values[quarter];
                  
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
