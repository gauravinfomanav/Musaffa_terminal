import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_peer_comparison_controller.dart';
import 'package:musaffa_terminal/models/peer_comparison_row.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class TickerPeerComparisonSection extends StatelessWidget {
  const TickerPeerComparisonSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  final TickerPeerComparisonController controller;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isLoading && !controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            child: const TickerFinnhubLoadingState(
              isDarkMode: true,
              height: 140,
            ),
          );
        }

        if (!controller.hasData) {
          return const SizedBox.shrink();
        }

        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (controller.error != null && controller.error!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Some peers failed to load',
                    style: DashboardTextStyles.tickerSymbol.copyWith(
                      fontSize: 11,
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              DynamicTable(
                title: 'Peer Comparison',
                columns: _buildColumns(),
                rows: _buildRows(controller.rows),
                showFixedColumn: true,
                considerPadding: false,
                columnSpacing: 8,
                fixedColumnWidth: 240,
                enableLivePrices: false,
                zebraStripes: false,
                enableColumnCustomization: true,
                tableId: 'peer_comparison_table',
              ),
            ],
          ),
        );
      },
    );
  }

  List<SimpleColumn> _buildColumns() {
    return <SimpleColumn>[
      const SimpleColumn(label: 'CURRENT PRICE', fieldName: 'currentPrice', isNumeric: true, width: 120),
      const SimpleColumn(label: '1D CHANGE %', fieldName: 'change1DPercent', isNumeric: true, width: 110),
      const SimpleColumn(label: 'MARKET CAP', fieldName: 'marketCap', isNumeric: true, width: 120),
      const SimpleColumn(label: 'P/E', fieldName: 'peTTM', isNumeric: true, width: 90),
      const SimpleColumn(label: 'EPS (TTM)', fieldName: 'epsTTM', isNumeric: true, width: 100),
      const SimpleColumn(label: 'ROE', fieldName: 'roe', isNumeric: true, width: 90),
      const SimpleColumn(label: 'REVENUE GROWTH', fieldName: 'revenueGrowth', isNumeric: true, width: 130),
      const SimpleColumn(label: 'DIVIDEND YIELD', fieldName: 'dividendYield', isNumeric: true, width: 130),
      const SimpleColumn(label: 'BETA', fieldName: 'beta', isNumeric: true, width: 80),
      const SimpleColumn(label: 'ROA', fieldName: 'roa', isNumeric: true, width: 90),
      const SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true, width: 110),
      const SimpleColumn(label: 'EV/REVENUE', fieldName: 'evRevenue', isNumeric: true, width: 120),
    ];
  }

  List<SimpleRowModel> _buildRows(List<PeerComparisonRow> rows) {
    return rows.map((PeerComparisonRow row) {
      return SimpleRowModel(
        symbol: row.ticker,
        name: row.companyName,
        logo: row.logo,
        fields: <String, dynamic>{
          'currentPrice': _fmtPrice(row),
          'change1DPercent': _fmtPercent(row.stockData.change1DPercent),
          'marketCap': Constants.getShortenedMarketCapV2(row.stockData.usdMarketCap),
          'peTTM': _fmtNum(row.stockData.peTTM),
          'epsTTM': _fmtNum(row.stockData.epsTTM),
          'roe': _fmtPercent(row.stockData.rOE),
          'revenueGrowth': _fmtPercent(row.stockData.revenueGrowth1Y),
          'dividendYield': _fmtPercent(row.stockData.currentDividendYieldTTM),
          'beta': _fmtNum(row.stockData.beta),
          'roa': _fmtPercent(row.stockData.roaTTM),
          'volume': _fmtVolume(row.stockData.volume),
          'evRevenue': _fmtNum(row.stockData.evRevenue),
          // keep this for built-in percent color logic in DynamicTable
          'change': row.stockData.change1DPercent ?? 0,
          // optional current row marker
          'isCurrent': row.isCurrent,
        },
        changeColor: _percentColor(row.stockData.change1DPercent),
      );
    }).toList();
  }

  String _fmtPrice(PeerComparisonRow row) {
    final num? price = row.stockData.currentPrice;
    if (price == null) return '--';
    return '\$${price.toStringAsFixed(2)}';
  }

  String _fmtNum(num? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(2);
  }

  String _fmtPercent(num? value) {
    if (value == null) return '--';
    final String sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  String _fmtVolume(num? value) {
    if (value == null) return '--';
    return getShortenedT(value);
  }

  Color? _percentColor(num? value) {
    if (value == null) return null;
    return value >= 0 ? Colors.green.shade600 : Colors.red.shade600;
  }
}
