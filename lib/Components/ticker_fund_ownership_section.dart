import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_fund_ownership_controller.dart';
import 'package:musaffa_terminal/models/fund_ownership_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class TickerFundOwnershipSection extends StatelessWidget {
  const TickerFundOwnershipSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
    this.currentPrice,
  });

  final TickerFundOwnershipController controller;
  final bool isDarkMode;
  final VoidCallback onRetry;
  final double? currentPrice;

  static const int _topRows = 10;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isLoading && !controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: TickerFinnhubLoadingState(
              isDarkMode: isDarkMode,
              height: 140,
            ),
          );
        }

        if (!controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const TickerFinnhubSectionTitle(title: 'Fund Ownership'),
                const SizedBox(height: 8),
                TickerFinnhubEmptyState(
                  isDarkMode: isDarkMode,
                  message: controller.error ?? 'No fund ownership data found',
                ),
                const SizedBox(height: 8),
                HomeUi.ghostAction(
                  label: 'Retry',
                  onTap: onRetry,
                  dark: isDarkMode,
                ),
              ],
            ),
          );
        }

        final List<FundOwnershipModel> topItems = List<FundOwnershipModel>.from(
          controller.items,
        )..sort((FundOwnershipModel a, FundOwnershipModel b) => b.share.compareTo(a.share));
        final List<FundOwnershipModel> visibleItems =
            topItems.take(_topRows).toList();

        final num totalVisibleShares = visibleItems.fold<num>(
          0,
          (num sum, FundOwnershipModel e) => sum + e.share,
        );
        final num totalAllShares = controller.totalSharesHeld;
        final num netVisibleChange = visibleItems.fold<num>(
          0,
          (num sum, FundOwnershipModel e) => sum + e.change,
        );

        final List<SimpleColumn> columns = <SimpleColumn>[
          const SimpleColumn(label: 'C. SHARES', fieldName: 'share', isNumeric: true, width: 105),
          const SimpleColumn(label: 'P. SHARES', fieldName: 'prevShare', isNumeric: true, width: 100),
          const SimpleColumn(label: 'CHANGE', fieldName: 'change', isNumeric: true, width: 90),
          const SimpleColumn(label: 'CHANGE %', fieldName: 'changePercent', isNumeric: true, width: 105),
          const SimpleColumn(label: 'ACTIVITY', fieldName: 'activity', width: 95),
          const SimpleColumn(label: 'PORTFOLIO %', fieldName: 'portfolioPercent', isNumeric: true, width: 105),
          const SimpleColumn(label: 'SHARE', fieldName: 'shareOfTop', isNumeric: true, width: 115),
          const SimpleColumn(label: 'TOTAL SHARES', fieldName: 'shareOfTotal', isNumeric: true, width: 115),
          const SimpleColumn(label: 'POSITION VALUE', fieldName: 'positionValue', isNumeric: true, width: 115),
          const SimpleColumn(label: 'FILED AGO', fieldName: 'filedAgo', width: 95),
          const SimpleColumn(label: 'FILING DATE', fieldName: 'filingDate', width: 105),
        ];

        final List<SimpleRowModel> rows = visibleItems.map((FundOwnershipModel item) {
          final num prevShare = item.share - item.change;
          final double shareOfTop = totalVisibleShares > 0
              ? (item.share / totalVisibleShares) * 100
              : 0;
          final double shareOfTotal = totalAllShares > 0
              ? (item.share / totalAllShares) * 100
              : 0;
          final num positionValue = item.share * (currentPrice ?? 0);
          return SimpleRowModel(
            symbol: item.name,
            name: '',
            fields: <String, dynamic>{
              'share': _compact(item.share),
              'prevShare': prevShare > 0 ? _compact(prevShare) : '--',
              'change': _formatSignedCompact(item.change),
              'changePercent': _formatChangePercent(item.change, prevShare),
              'activity': _formatActivity(item.change, prevShare),
              'portfolioPercent': '${item.portfolioPercent.toStringAsFixed(1)}%',
              'shareOfTop': '${shareOfTop.toStringAsFixed(1)}%',
              'shareOfTotal': '${shareOfTotal.toStringAsFixed(2)}%',
              'positionValue': currentPrice == null
                  ? '--'
                  : valueWithCurrency(
                      price: positionValue,
                      currency: 'USD',
                      showCurrencySymbol: true,
                      shorten: true,
                    ),
              'filedAgo': _formatTimeAgo(item.filingDate),
              'filingDate': FinnhubDisplayFormatters.formatDate(item.filingDate),
            },
            changeColor: item.change > 0
                ? HomeUi.positive(isDarkMode)
                : item.change < 0
                    ? HomeUi.negative(isDarkMode)
                    : null,
          );
        }).toList();

        return DynamicTable(
          title: 'Fund Ownership',
          subtitle: 'Largest reported holders',
          toolbarLeadingIcon: Icons.account_balance_outlined,
          showOuterShadow: true,
          columns: columns,
          rows: rows,
          showFixedColumn: true,
          tickerHeaderLabel: 'FUND',
          considerPadding: false,
          columnSpacing: 10,
          fixedColumnWidth: 248,
          enableLivePrices: false,
          zebraStripes: true,
          enableColumnCustomization: true,
          tableId: 'fund_ownership_table',
          showColumnActionMenu: true,
          showColumnResizeHandle: true,
          compactHeaderText: true,
        );
      },
    );
  }



  String _compact(num value) {
    return getShortenedT(value);
  }

  String _formatSignedCompact(num value) {
    if (value == 0) return '0';
    final String sign = value > 0 ? '+' : '-';
    return '$sign${_compact(value.abs())}';
  }

  String _formatChangePercent(num change, num prevShare) {
    if (change == 0) return '0%';
    if (prevShare <= 0) return '--';
    final double pct = (change / prevShare) * 100;
    final String sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  String _formatActivity(num change, num prevShare) {
    if (prevShare <= 0 && change > 0) return 'New';
    if (change > 0) return 'Increased';
    if (change < 0) return 'Decreased';
    return 'Unchanged';
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '--';
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
