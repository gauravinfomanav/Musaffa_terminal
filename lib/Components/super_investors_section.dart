import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/models/super_investor_model.dart';
import 'package:musaffa_terminal/services/super_investor_service.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class SuperInvestorsSection extends StatefulWidget {
  final String symbol;

  const SuperInvestorsSection({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  State<SuperInvestorsSection> createState() => _SuperInvestorsSectionState();
}

class _SuperInvestorsSectionState extends State<SuperInvestorsSection> {
  static const int _collapsedRowLimit = 5;
  late Future<List<MergedSuperInvestor>> _investorDataFuture;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _investorDataFuture = SuperInvestorService().fetchMergedData(widget.symbol);
  }

  String _formatValue(double? value) {
    if (value == null) return '--';

    if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }

  String _formatShareCount(int? shares) {
    if (shares == null) return '--';
    return NumberFormat('#,##0').format(shares);
  }

  String _formatChange(int? change) {
    if (change == null) return '--';
    final abs = NumberFormat('#,##0').format(change.abs());
    if (change > 0) return '+$abs';
    if (change < 0) return '-$abs';
    return '0';
  }

  String _formatPercentage(double? percentage) {
    if (percentage == null) return '--';
    return '${percentage.toStringAsFixed(1)}%';
  }

  String _formatSignedPercent(double? value) {
    if (value == null) return '--';
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  String _formatAvgPrice(double? value) {
    if (value == null) return '--';
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatSignedValue(double? value) {
    if (value == null) return '--';
    if (value > 0) return '+${_formatValue(value)}';
    if (value < 0) return '-${_formatValue(value.abs())}';
    return _formatValue(value);
  }

  String _formatReportDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '--';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }


  List<SimpleRowModel> _buildRows(List<MergedSuperInvestor> investors) {
    return investors.asMap().entries.map((entry) {
      // Removed old index variable
      final investor = entry.value;
      final managerName =
          (investor.manager == null || investor.manager!.isEmpty)
              ? 'Unknown Manager'
              : investor.manager!;

      return SimpleRowModel(
        symbol: managerName,
        name: '',
        logo: null,
        fields: {
          'transactionType': investor.transactionType ?? '--',
          'share': _formatShareCount(investor.share),
          'previousShares': _formatShareCount(investor.previousShares),
          'change': _formatChange(investor.change),
          'value': _formatValue(investor.value),
          'avgPrice': _formatAvgPrice(investor.avgPrice),
          'valueChange': _formatSignedValue(investor.valueChange),
          'percentage': _formatPercentage(investor.percentage),
          'percentageChange': _formatSignedPercent(investor.percentageChange),
          'trend': investor.trend ?? '--',
          'convictionLevel': investor.convictionLevel ?? '--',
          'reportDate': _formatReportDate(investor.reportDate),
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final nameColumnWidth = screenWidth <= 1512 ? 240.0 : 320.0;

    return FutureBuilder<List<MergedSuperInvestor>>(
      future: _investorDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading(isDarkMode);
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDarkMode);
        }

        final investors = snapshot.data ?? [];

        if (investors.isEmpty) {
          return const SizedBox.shrink();
        }

        final rows = _buildRows(investors);
          final columns = [
            SimpleColumn(label: 'TXN', fieldName: 'transactionType', width: 70),
            SimpleColumn(label: 'CURRENT SHARES', fieldName: 'share', isNumeric: true),
            SimpleColumn(label: 'PREVIOUS SHARES', fieldName: 'previousShares', isNumeric: true),
            SimpleColumn(label: 'CHANGE (SHARES)', fieldName: 'change', isNumeric: true),
            SimpleColumn(label: 'VALUE', fieldName: 'value', isNumeric: true),
            SimpleColumn(label: 'AVG PRICE', fieldName: 'avgPrice', isNumeric: true),
            SimpleColumn(label: 'VALUE CHANGE', fieldName: 'valueChange', isNumeric: true),
            SimpleColumn(label: 'PORTFOLIO %', fieldName: 'percentage', isNumeric: true),
            SimpleColumn(label: 'CHANGE %', fieldName: 'percentageChange', isNumeric: true),
            SimpleColumn(label: 'TREND', fieldName: 'trend', width: 80),
            SimpleColumn(label: 'CONVICTION', fieldName: 'convictionLevel', width: 90),
          ];
        final hasMoreRows = rows.length > _collapsedRowLimit;
        final visibleRows =
            hasMoreRows && !_isExpanded ? rows.take(_collapsedRowLimit).toList() : rows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DynamicTable(
              title: 'Super Investors',
              subtitle: 'Holdings and conviction in this ticker',
              toolbarLeadingIcon: Icons.workspace_premium_outlined,
              showOuterShadow: true,
              columns: columns,
              rows: visibleRows,
              showFixedColumn: true,
              tickerHeaderLabel: 'SUPER INVESTOR',
              considerPadding: false,
              columnSpacing: 4,
              fixedColumnWidth: nameColumnWidth,
              enableLivePrices: false,
              zebraStripes: true,
              enableColumnCustomization: true,
              tableId: 'super_investors_table',
            ),
            if (hasMoreRows) ...[
              const SizedBox(height: 12),
              HomeUi.expandToggle(
                dark: isDarkMode,
                expanded: _isExpanded,
                remaining: rows.length - _collapsedRowLimit,
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShimmerLoading(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidgets.box(
            width: 200,
            height: 20,
            borderRadius: BorderRadius.circular(4),
            baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShimmerWidgets.box(
                width: double.infinity,
                height: 80,
                borderRadius: BorderRadius.circular(6),
                baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                highlightColor:
                    isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load super investors',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade400,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
