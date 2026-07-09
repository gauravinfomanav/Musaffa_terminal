import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_insider_trading_controller.dart';
import 'package:musaffa_terminal/models/insider_transaction_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class TickerInsiderTradingSection extends StatefulWidget {
  const TickerInsiderTradingSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.ticker,
    required this.currentPrice,
    required this.companyLogoUrl,
    required this.onRetry,
  });

  final TickerInsiderTradingController controller;
  final bool isDarkMode;
  final String ticker;
  final double? currentPrice;
  final String companyLogoUrl;
  final VoidCallback onRetry;

  @override
  State<TickerInsiderTradingSection> createState() =>
      _TickerInsiderTradingSectionState();
}

class _TickerInsiderTradingSectionState extends State<TickerInsiderTradingSection> {
  static const int _collapsedRowLimit = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final Color actionColor =
        widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? child) {
        if (widget.controller.isLoading && !widget.controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: widget.isDarkMode,
            child: TickerFinnhubLoadingState(
              isDarkMode: widget.isDarkMode,
              height: 140,
            ),
          );
        }

        if (!widget.controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: widget.isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
              
                TickerFinnhubEmptyState(
                  isDarkMode: widget.isDarkMode,
                  message:
                      widget.controller.error ?? 'No insider transactions found',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: widget.onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final List<SimpleColumn> columns = <SimpleColumn>[
          const SimpleColumn(label: 'INSIDER NAME', fieldName: 'name', width: 170),
          const SimpleColumn(label: 'ACTION', fieldName: 'action', width: 80),
          const SimpleColumn(label: 'SHARES CHANGED', fieldName: 'change', isNumeric: true, width: 130),
          const SimpleColumn(label: 'SHARES HELD', fieldName: 'share', isNumeric: true, width: 130),
          const SimpleColumn(label: 'PRICE', fieldName: 'price', isNumeric: true, width: 100),
          const SimpleColumn(label: 'TXN VALUE', fieldName: 'transactionValue', isNumeric: true, width: 120),
          const SimpleColumn(label: 'CURRENT PRICE', fieldName: 'currentPrice', isNumeric: true, width: 120),
          const SimpleColumn(label: 'HOLDINGS VALUE', fieldName: 'holdingsValue', isNumeric: true, width: 130),
          const SimpleColumn(label: 'TIME AGO', fieldName: 'timeAgo', width: 110),
          const SimpleColumn(label: 'TXN DATE', fieldName: 'transactionDate', width: 110),
          const SimpleColumn(label: 'FILING DATE', fieldName: 'filingDate', width: 110),
        ];

        final DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 120));
        final List<InsiderTransactionModel> filteredItems = widget.controller.items
            .where((InsiderTransactionModel item) {
              final DateTime? primaryDate = item.transactionDate ?? item.filingDate;
              if (primaryDate == null) return false;
              return !primaryDate.isBefore(cutoffDate);
            })
            .toList();

        if (filteredItems.isEmpty) {
          return TickerFinnhubSectionCard(
            isDarkMode: widget.isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
               
                TickerFinnhubEmptyState(
                  isDarkMode: widget.isDarkMode,
                  message: 'No insider transactions found in the last 4 months',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: widget.onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final List<SimpleRowModel> allRows =
            filteredItems.map((InsiderTransactionModel item) {
          final String changed = _formatShares(item.change);
          final bool isRecent = _isRecent(item.transactionDate);
          final num transactionValue = (item.change.abs() * item.transactionPrice);
          final num? currentPriceValue = widget.currentPrice;
          final num holdingsValue = (item.share * (currentPriceValue ?? 0));
          return SimpleRowModel(
            symbol: item.name,
            name: '',
            fields: <String, dynamic>{
              'name': Row(
                children: <Widget>[
                  showLogo(
                    widget.ticker,
                    widget.companyLogoUrl,
                    sideWidth: 18,
                    name: widget.ticker,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DashboardTextStyles.dataCell.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
              'action': Row(
                children: <Widget>[
                  Text(
                    item.isBuy ? '🟢 Buy' : item.isSell ? '🔴 Sell' : '—',
                    style: DashboardTextStyles.dataCell.copyWith(fontSize: 11),
                  ),
                  if (isRecent) ...<Widget>[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Recent',
                        style: DashboardTextStyles.tickerSymbol.copyWith(fontSize: 9),
                      ),
                    ),
                  ],
                ],
              ),
              'change': changed,
              'share': _fmtInt(item.share),
              'price': valueWithCurrency(
                price: item.transactionPrice,
                currency: 'USD',
                showCurrencySymbol: true,
              ),
              'transactionValue': valueWithCurrency(
                price: transactionValue,
                currency: 'USD',
                showCurrencySymbol: true,
                shorten: true,
              ),
              'currentPrice': currentPriceValue == null
                  ? '--'
                  : valueWithCurrency(
                      price: currentPriceValue,
                      currency: 'USD',
                      showCurrencySymbol: true,
                    ),
              'holdingsValue': currentPriceValue == null
                  ? '--'
                  : valueWithCurrency(
                      price: holdingsValue,
                      currency: 'USD',
                      showCurrencySymbol: true,
                      shorten: true,
                    ),
              'timeAgo': _formatTimeAgo(item.transactionDate),
              'transactionDate': FinnhubDisplayFormatters.formatDate(item.transactionDate),
              'filingDate': FinnhubDisplayFormatters.formatDate(item.filingDate),
            },
            changeColor: item.isBuy
                ? Colors.green.shade600
                : item.isSell
                    ? Colors.red.shade600
                    : null,
          );
        }).toList();
        final bool hasMore = allRows.length > _collapsedRowLimit;
        final List<SimpleRowModel> rows =
            _showAll ? allRows : allRows.take(_collapsedRowLimit).toList();

        return TickerFinnhubSectionCard(
          isDarkMode: widget.isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
         
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: DynamicTable(
                  title: 'Recent Transactions',
                   columns: columns,
                  rows: rows,
                  showFixedColumn: false,
                  considerPadding: false,
                  columnSpacing: 16,
                  enableLivePrices: false,
                  zebraStripes: false,
                  enableColumnCustomization: true,
                  tableId: 'insider_trading_table',
                  showColumnActionMenu: true,
                  showColumnResizeHandle: true,
                  compactHeaderText: true,
                ),
              ),
              if (hasMore) ...<Widget>[
                const SizedBox(height: 8),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAll = !_showAll;
                      });
                    },
                    icon: AnimatedRotation(
                      turns: _showAll ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: actionColor,
                      ),
                    ),
                    label: Text(
                      _showAll
                          ? 'Show less'
                          : 'Show more (${allRows.length - _collapsedRowLimit})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: actionColor,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: actionColor.withOpacity(0.6),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

  bool _isRecent(DateTime? date) {
    if (date == null) return false;
    return DateTime.now().difference(date).inDays <= 7;
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '--';
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  String _fmtInt(num value) {
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => ',',
        );
  }

  String _formatShares(num value) {
    final String sign = value > 0 ? '+' : value < 0 ? '-' : '';
    final String number = _fmtInt(value.abs());
    return '$sign$number';
  }
}
