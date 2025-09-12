import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/financial_expandable_table.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/ratios_annual_controller.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/ratios_quarterly_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalRatiosScreen extends StatefulWidget {
  final String symbol;

  const TerminalRatiosScreen({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  State<TerminalRatiosScreen> createState() => _TerminalRatiosScreenState();
}

class _TerminalRatiosScreenState extends State<TerminalRatiosScreen> {
  bool isQuarterly = false;
  late RatiosController annualRatiosController;
  late QuarterlyRatiosController quarterlyRatiosController;

  @override
  void initState() {
    super.initState();
    
    // Initialize ratios controllers
    annualRatiosController = Get.put(RatiosController());
    annualRatiosController.fetchRatio(widget.symbol);
    
    quarterlyRatiosController = Get.put(QuarterlyRatiosController());
    quarterlyRatiosController.fetchQuarterlyRatios(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Obx(() {
      if (isQuarterly) {
        // Show Quarterly Ratios
        if (quarterlyRatiosController.isLoading.value) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            child: ShimmerWidgets.perShareTableShimmer(),
          );
        }

        if (!quarterlyRatiosController.processingComplete.value || 
            quarterlyRatiosController.tableData.isEmpty) {
          return Center(
            child: Text(
              'No quarterly data available',
              style: TextStyle(
                fontSize: 12,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          );
        }

        // Transform quarterly data for the new table
        final transformedData = FinancialDataTransformer.transformRatios(
          quarterlyRatiosController.tableData,
          quarterlyRatiosController.quarters,
        );

        final columns = _buildFinancialColumns(quarterlyRatiosController.quarters);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
          child: FinancialExpandableTable(
            columns: columns,
            data: transformedData,
            showNameColumn: false, // Don't show separate name column since we have metric column
            rowHeight: 40,
            headerHeight: 32,
            indentSize: 20,
            expandIconSize: 14,
            considerPadding: false,
            showYoYGrowth: true, // Enable YoY Growth column
            showThreeYearAvg: true, // Enable 3-Year Average column
            showFiveYearCAGR: true, // Enable 5-Year CAGR column
          ),
        );
      } else {
        // Show Annual Ratios
        if (annualRatiosController.isLoading.value) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            child: ShimmerWidgets.perShareTableShimmer(),
          );
        }

        final annualData = annualRatiosController.getFinancialDataForYears();
        if (annualData.isEmpty) {
          return Center(
            child: Text(
              'No annual data available',
              style: TextStyle(
                fontSize: 12,
                fontFamily: Constants.FONT_DEFAULT_NEW,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          );
        }

        // Transform annual data for the new table
        final transformedData = _transformAnnualRatiosData(annualData, annualRatiosController.years);
        final columns = _buildFinancialColumns(annualRatiosController.years);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
          child: FinancialExpandableTable(
            columns: columns,
            data: transformedData,
            showNameColumn: false, // Don't show separate name column since we have metric column
            rowHeight: 40,
            headerHeight: 32,
            indentSize: 20,
            expandIconSize: 14,
            considerPadding: false,
            showYoYGrowth: true, // Enable YoY Growth column
            showThreeYearAvg: true, // Enable 3-Year Average column
            showFiveYearCAGR: true, // Enable 5-Year CAGR column
          ),
        );
      }
    });
  }

  List<FinancialExpandableColumn> _buildFinancialColumns(List<String> periods) {
    List<FinancialExpandableColumn> columns = [
      FinancialExpandableColumn(
        key: 'metric',
        title: 'Name',
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

  List<FinancialExpandableRowData> _transformAnnualRatiosData(
    Map<String, Map<String, double?>> annualData,
    List<String> years,
  ) {
    // Define the order for ratios display
    final orderedMetrics = [
      'netMargin',
      'quickRatio',
      'currentRatio',
      'peTTM',
      'psTTM',
      'pb',
      'fcfMargin',
      'payoutRatioTTM',
      'grossMargin',
      'roeTTM',
      'roa',
      'roaTTM',
      'roic',
      'inventoryTurnoverTTM',
      'receivablesTurnoverTTM',
      'assetTurnoverTTM',
      'longtermDebtTotalEquity',
      'totalDebtToTotalAsset',
      'longtermDebtTotalAsset',
      'totalDebtToTotalCapital',
      'operatingMargin',
    ];

    // Mapping of metric keys to display names
    final displayNames = {
      'netMargin': 'Net Margin',
      'quickRatio': 'Quick Ratio',
      'currentRatio': 'Current Ratio',
      'peTTM': 'P/E (TTM)',
      'psTTM': 'P/S (TTM)',
      'pb': 'Price to Book',
      'fcfMargin': 'Free Cash Flow Margin',
      'payoutRatioTTM': 'Payout Ratio (TTM)',
      'grossMargin': 'Gross Margin',
      'roeTTM': 'ROE (TTM)',
      'roa': 'Return on Assets',
      'roaTTM': 'ROA (TTM)',
      'roic': 'Return on Invested Capital',
      'inventoryTurnoverTTM': 'Inventory Turnover (TTM)',
      'receivablesTurnoverTTM': 'Receivables Turnover (TTM)',
      'assetTurnoverTTM': 'Asset Turnover (TTM)',
      'longtermDebtTotalEquity': 'Long-Term Debt to Equity',
      'totalDebtToTotalAsset': 'Total Debt to Total Asset',
      'longtermDebtTotalAsset': 'Long-Term Debt to Total Asset',
      'totalDebtToTotalCapital': 'Total Debt to Total Capital',
      'operatingMargin': 'Operating Margin',
    };

    return orderedMetrics
        .where((metric) => annualData.containsKey(metric))
        .map((metric) {
      Map<String, dynamic> data = {};
      for (var year in years) {
        double? value = annualData[metric]?[year];
        data[year] = value?.toStringAsFixed(2) ?? '--';
      }

      // Calculate YoY Growth
      data['yoy_growth'] = _calculateYoYGrowth(annualData[metric], years);
      
      // Calculate 3-Year Average
      data['three_year_avg'] = _calculateThreeYearAverage(annualData[metric], years);
      
      // Calculate 5-Year CAGR
      data['five_year_cagr'] = _calculateFiveYearCAGR(annualData[metric], years);

      return FinancialExpandableRowData(
        id: metric,
        name: displayNames[metric] ?? metric,
        data: {
          'metric': displayNames[metric] ?? metric,
          ...data,
        },
        level: 0,
      );
    }).toList();
  }

  // Calculate Year-on-Year Growth for ratios
  String _calculateYoYGrowth(Map<String, double?>? metricData, List<String> years) {
    if (metricData == null || years.length < 2) return '-';
    
    String currentYear = years.last;
    String previousYear = years[years.length - 2];
    
    double? current = metricData[currentYear];
    double? previous = metricData[previousYear];
    
    if (current == null || previous == null || previous == 0) {
      return '-';
    }
    
    double growth = ((current - previous) / previous) * 100;
    
    // Format with + or - sign
    if (growth > 0) {
      return '+${growth.toStringAsFixed(1)}%';
    } else if (growth < 0) {
      return '${growth.toStringAsFixed(1)}%';
    } else {
      return '0.0%';
    }
  }

  // Calculate 3-Year Average for ratios
  String _calculateThreeYearAverage(Map<String, double?>? metricData, List<String> years) {
    if (metricData == null || years.length < 3) return '-';
    
    // Get the last 3 years
    List<String> lastThreeYears = years.skip(years.length - 3).toList();
    List<double> values = [];
    
    for (String year in lastThreeYears) {
      double? value = metricData[year];
      if (value != null) {
        values.add(value);
      }
    }
    
    if (values.isEmpty) return '-';
    
    double average = values.reduce((a, b) => a + b) / values.length;
    return average.toStringAsFixed(2);
  }

  // Calculate 5-Year CAGR for ratios
  String _calculateFiveYearCAGR(Map<String, double?>? metricData, List<String> years) {
    if (metricData == null || years.length < 5) return '-';
    
    // Get the first and last 5 years
    List<String> lastFiveYears = years.skip(years.length - 5).toList();
    String oldestYear = lastFiveYears.first;
    String latestYear = lastFiveYears.last;
    
    double? oldestValue = metricData[oldestYear];
    double? latestValue = metricData[latestYear];
    
    if (oldestValue == null || latestValue == null || oldestValue <= 0) {
      return '-';
    }
    
    // Calculate CAGR: (Latest Year / Oldest Year)^(1/5) - 1
    double cagr = pow(latestValue / oldestValue, 1.0 / 5.0) - 1.0;
    
    // Format as percentage with + or - sign
    if (cagr > 0) {
      return '+${(cagr * 100).toStringAsFixed(1)}%';
    } else if (cagr < 0) {
      return '${(cagr * 100).toStringAsFixed(1)}%';
    } else {
      return '0.0%';
    }
  }

}
