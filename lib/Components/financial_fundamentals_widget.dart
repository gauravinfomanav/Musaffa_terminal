import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Controllers/financial_fundamentals_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';

class FinancialFundamentalsWidget extends StatefulWidget {
  final String symbol;
  final FinancialFundamentalsController controller;

  const FinancialFundamentalsWidget({
    Key? key,
    required this.symbol,
    required this.controller,
  }) : super(key: key);

  @override
  State<FinancialFundamentalsWidget> createState() => _FinancialFundamentalsWidgetState();
}

class _FinancialFundamentalsWidgetState extends State<FinancialFundamentalsWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.fetchFinancialFundamentals(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildShimmerKeyMetricsTable(isDarkMode),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildShimmerComprehensiveTable(isDarkMode),
                ),
              ],
            ),
          );
        }

        if (widget.controller.error != null) {
          return Center(
            child: Text(
              'Error: ${widget.controller.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final fundamentals = widget.controller.fundamentalsData;
        if (fundamentals == null) {
          return const Center(child: Text('No financial data available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Metrics Table (Annual/Quarterly values)
              Expanded(
                flex: 2,
                child: _buildKeyMetricsTable(fundamentals, isDarkMode),
              ),
              const SizedBox(width: 8),
              // Comprehensive 5-Year Data Table
              Expanded(
                flex: 3,
                child: _buildComprehensiveTable(fundamentals, isDarkMode),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyMetricsTable(Map<String, dynamic> fundamentals, bool isDarkMode) {
    final data = [
      ['Book Value/Share', '\$${fundamentals['bookValuePerShareAnnual']?.toStringAsFixed(2) ?? '--'}'],
      ['Cash/Share', '\$${fundamentals['cashPerSharePerShareAnnual']?.toStringAsFixed(2) ?? '--'}'],
      ['Tangible BV/Share', '\$${fundamentals['tangibleBookValuePerShareAnnual']?.toStringAsFixed(2) ?? '--'}'],
      ['Latest EPS', '\$${fundamentals['epsTTM']?['2024']?.toStringAsFixed(2) ?? '--'}'],
      ['Latest Revenue/Share', '\$${fundamentals['revenue_per_share']?['2024']?.toStringAsFixed(2) ?? '--'}'],
      ['Latest EBIT/Share', '\$${fundamentals['ebit_per_share']?['2024']?.toStringAsFixed(2) ?? '--'}'],
    ];
    
    return _buildCompactTable('Key Metrics (Latest)', data, isDarkMode);
  }

  Widget _buildComprehensiveTable(Map<String, dynamic> fundamentals, bool isDarkMode) {
    final years = ['2020', '2021', '2022', '2023', '2024'];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with years as columns
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Financial Metrics',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
                ...years.map((year) => Expanded(
                  child: Text(
                    year,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
          // Data rows
          _buildDataRow('EPS', fundamentals['epsTTM'], years, isDarkMode, isCurrency: true),
          _buildDataRow('Revenue/Share', fundamentals['revenue_per_share'], years, isDarkMode, isCurrency: true),
          _buildDataRow('EBIT/Share', fundamentals['ebit_per_share'], years, isDarkMode, isCurrency: true),
          _buildDataRow('P/E Ratio', fundamentals['price_to_earning'], years, isDarkMode, isCurrency: false),
          _buildDataRow('Dividend/Share', fundamentals['dividendPerShareTTM'], years, isDarkMode, isCurrency: true),
        ],
      ),
    );
  }

  Widget _buildDataRow(String metric, dynamic data, List<String> years, bool isDarkMode, {required bool isCurrency}) {
    if (data == null || data is! Map<String, dynamic>) {
      return _buildEmptyRow(metric, years.length, isDarkMode);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 11,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
          ...years.map((year) => Expanded(
            child: Text(
              _formatValue(data[year], isCurrency),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyRow(String metric, int yearCount, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 11,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
          ...List.generate(yearCount, (index) => Expanded(
            child: Text(
              '--',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          )),
        ],
      ),
    );
  }

  String _formatValue(dynamic value, bool isCurrency) {
    if (value == null || value == 0 || value.toString().isEmpty) return '--';
    
    try {
      final numValue = double.tryParse(value.toString());
      if (numValue == null || numValue == 0) return '--';
      
      if (isCurrency) {
        return '\$${_formatNumber(numValue)}';
      } else {
        return _formatNumber(numValue);
      }
    } catch (e) {
      return '--';
    }
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else if ((value * 10) == (value * 10).toInt()) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Widget _buildShimmerKeyMetricsTable(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: ShimmerWidgets.box(height: 14, width: 80),
          ),
          // Row shimmers
          ...List.generate(6, (index) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerWidgets.box(height: 12, width: 60),
                ShimmerWidgets.box(height: 12, width: 40),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildShimmerComprehensiveTable(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer with years
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ShimmerWidgets.box(height: 14, width: 80),
                ),
                ...List.generate(5, (index) => Expanded(
                  child: ShimmerWidgets.box(height: 14, width: 30),
                )),
              ],
            ),
          ),
          // Row shimmers
          ...List.generate(5, (index) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ShimmerWidgets.box(height: 12, width: 60),
                ),
                ...List.generate(5, (yearIndex) => Expanded(
                  child: ShimmerWidgets.box(height: 12, width: 30),
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCompactTable(String title, List<List<String>> data, bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ),
          ...data.map((row) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row[0],
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontSize: 11,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
                Text(
                  row[1],
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
