import 'package:musaffa_terminal/models/stocks_data.dart';

class PeerComparisonRow {
  const PeerComparisonRow({
    required this.ticker,
    required this.companyName,
    required this.logo,
    required this.stockData,
    required this.isCurrent,
  });

  final String ticker;
  final String companyName;
  final String logo;
  final StocksData stockData;
  final bool isCurrent;
}
