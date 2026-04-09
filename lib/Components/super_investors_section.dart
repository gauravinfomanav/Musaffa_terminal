import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/dynamic_table.dart';
import 'package:musaffa_terminal/models/super_investor_model.dart';
import 'package:musaffa_terminal/services/super_investor_service.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';

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

  List<TableColumn> _buildColumns() {
    return [
      TableColumn(key: 'transactionType', title: 'Txn'),
      TableColumn(key: 'share', title: 'Current Shares'),
      TableColumn(key: 'previousShares', title: 'Previous Shares'),
      TableColumn(key: 'change', title: 'Change(shares)'),
      TableColumn(key: 'value', title: 'Value'),
      TableColumn(key: 'avgPrice', title: 'Avg Price'),
      TableColumn(key: 'valueChange', title: 'Value Change'),
      TableColumn(key: 'percentage', title: 'Portfolio %'),
      TableColumn(key: 'percentageChange', title: 'Change %'),
      TableColumn(key: 'trend', title: 'Trend'),
      TableColumn(key: 'convictionLevel', title: 'Conviction'),
      
    ];
  }

  List<TableRowData> _buildRows(List<MergedSuperInvestor> investors) {
    return investors.asMap().entries.map((entry) {
      final index = entry.key;
      final investor = entry.value;
      final managerName =
          (investor.manager == null || investor.manager!.isEmpty)
              ? 'Unknown Manager'
              : investor.manager!;

      return TableRowData(
        id: '${widget.symbol}_$index',
        // Keep first column simple: show only manager name.
        symbol: managerName,
        name: '',
        logo: null,
        data: {
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
    final headingColor = isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final tableHeaderColor =
        isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final tableCellColor = isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final actionColor = isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);

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
        final columns = _buildColumns();
        final hasMoreRows = rows.length > _collapsedRowLimit;
        final visibleRows =
            hasMoreRows && !_isExpanded ? rows.take(_collapsedRowLimit).toList() : rows;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super Investors Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: headingColor,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                      
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: DynamicTable(
                  columns: columns,
                  data: visibleRows,
                  showNameColumn: true,
                  considerPadding: false,
                  nameColumnWidth: nameColumnWidth,
                rowHeight: 48,
                headerHeight: 32,
                  headerTextColor: tableHeaderColor,
                  cellTextColor: tableCellColor,
                  nameColumnBackgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  disableHoverHighlight: true,
                  useChangeColors: true,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                headerFontSize: 12,
                headerFontWeight: FontWeight.w500,
                cellFontSize: 14,
                cellFontWeight: FontWeight.w400,
                nameFontSize: 14,
                nameFontWeight: FontWeight.w400,
                ),
              ),
              if (hasMoreRows) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: actionColor,
                      ),
                    ),
                    label: Text(
                      _isExpanded
                          ? 'Show less'
                          : 'Show more (${rows.length - _collapsedRowLimit})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: actionColor,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
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
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
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
