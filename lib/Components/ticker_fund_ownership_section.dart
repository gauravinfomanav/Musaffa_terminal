import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/Controllers/ticker_fund_ownership_controller.dart';
import 'package:musaffa_terminal/Screens/etf_details_screen.dart';
import 'package:musaffa_terminal/Screens/fund_ownership_detail_screen.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/models/fund_ownership_model.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class TickerFundOwnershipSection extends StatelessWidget {
  const TickerFundOwnershipSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
    required this.holdingSymbol,
    this.holdingName,
    this.currentPrice,
  });

  final TickerFundOwnershipController controller;
  final bool isDarkMode;
  final VoidCallback onRetry;
  final String holdingSymbol;
  final String? holdingName;
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
          const SimpleColumn(label: 'CURRENT SHARES', fieldName: 'share', isNumeric: true, width: 130),
          const SimpleColumn(label: 'PREVIOUS SHARES', fieldName: 'prevShare', isNumeric: true, width: 130),
          const SimpleColumn(label: 'CHANGE', fieldName: 'change', isNumeric: true, width: 90),
          const SimpleColumn(label: 'CHANGE %', fieldName: 'changePercent', isNumeric: true, width: 105),
          const SimpleColumn(label: 'ACTIVITY', fieldName: 'activity', width: 95),
          const SimpleColumn(label: 'PORTFOLIO %', fieldName: 'portfolioPercent', isNumeric: true, width: 115),
          const SimpleColumn(label: 'SHARE OF LIST', fieldName: 'shareOfTop', isNumeric: true, width: 120),
          const SimpleColumn(label: 'TOTAL SHARES', fieldName: 'shareOfTotal', isNumeric: true, width: 120),
          const SimpleColumn(label: 'POSITION VALUE', fieldName: 'positionValue', isNumeric: true, width: 130),
          const SimpleColumn(label: 'FILED AGO', fieldName: 'filedAgo', width: 95),
          const SimpleColumn(label: 'FILING DATE', fieldName: 'filingDate', width: 110),
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
          columnSpacing: 2,
          fixedColumnWidth: 248,
          enableLivePrices: false,
          zebraStripes: true,
          enableColumnCustomization: true,
          enableColumnStretch: true,
          shrinkColumnsToFit: false,
          tableId: 'fund_ownership_table',
          showColumnActionMenu: true,
          showColumnResizeHandle: true,
          compactHeaderText: true,
          onTickerTap: (row) {
            final String name = row.data['_ticker_symbol']?.toString() ?? '';
            FundOwnershipModel? match;
            for (final FundOwnershipModel item in visibleItems) {
              if (item.name == name) {
                match = item;
                break;
              }
            }
            match ??= visibleItems.isEmpty ? null : visibleItems.first;
            if (match == null) return;
            _openHolder(context, match);
          },
        );
      },
    );
  }



  Future<void> _openHolder(
    BuildContext context,
    FundOwnershipModel fund,
  ) async {
    if (_nameLooksLikeEtf(fund.name) ||
        (fund.symbol ?? '').trim().isNotEmpty) {
      final TickerModel? etf = await _resolveEtfTicker(fund);
      if (!context.mounted) return;
      if (etf != null) {
        FeatureNavigation.pushIfAllowed(
          context,
          FeatureKeys.etfDetails,
          EtfDetailsScreen(ticker: etf),
        );
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FundOwnershipDetailScreen(
          fund: fund,
          holdingSymbol: holdingSymbol,
          holdingName: holdingName ?? holdingSymbol,
          currentPrice: currentPrice,
        ),
      ),
    );
  }

  bool _nameLooksLikeEtf(String name) {
    return RegExp(r'\bETFs?\b', caseSensitive: false).hasMatch(name);
  }

  Future<TickerModel?> _resolveEtfTicker(FundOwnershipModel fund) async {
    final String? symbol = fund.symbol?.trim();
    final List<String> queries = <String>[
      if (symbol != null && symbol.isNotEmpty) symbol,
      fund.name,
    ];

    for (final String query in queries) {
      if (query.trim().isEmpty) continue;
      final List<TickerModel> results = await SearchService.searchStocks(query);
      if (symbol != null && symbol.isNotEmpty) {
        final String needle = symbol.toUpperCase();
        for (final TickerModel ticker in results) {
          final String candidate =
              (ticker.symbol ?? ticker.ticker ?? '').trim().toUpperCase();
          if (candidate == needle && !ticker.isStock) {
            return ticker;
          }
        }
      }
      if (_nameLooksLikeEtf(fund.name)) {
        for (final TickerModel ticker in results) {
          if (!ticker.isStock) {
            return ticker;
          }
        }
      }
    }

    if (symbol != null &&
        symbol.isNotEmpty &&
        _nameLooksLikeEtf(fund.name)) {
      return TickerModel(
        symbol: symbol.toUpperCase(),
        ticker: symbol.toUpperCase(),
        name: fund.name,
        companyName: fund.name,
        isStock: false,
      );
    }
    return null;
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
