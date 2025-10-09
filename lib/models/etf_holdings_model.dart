import 'package:musaffa_terminal/models/stocks_data.dart';
import 'package:musaffa_terminal/models/company_profile.dart';

class EtfHolding {
  final String assetType;
  final String cbaComment;
  final String cbaStatus;
  final String cusip;
  final String id;
  final String isin;
  final String logo;
  final String name;
  final double percent;
  final double share;
  final String shariahStates;
  final String shariahStatus;
  final String symbol;
  final String totalHoldings;
  final String updatedDate;
  final double value;

  EtfHolding({
    required this.assetType,
    required this.cbaComment,
    required this.cbaStatus,
    required this.cusip,
    required this.id,
    required this.isin,
    required this.logo,
    required this.name,
    required this.percent,
    required this.share,
    required this.shariahStates,
    required this.shariahStatus,
    required this.symbol,
    required this.totalHoldings,
    required this.updatedDate,
    required this.value,
  });

  factory EtfHolding.fromJson(Map<String, dynamic> json) {
    return EtfHolding(
      assetType: json['assetType'] ?? '',
      cbaComment: json['cbaComment'] ?? '',
      cbaStatus: json['cbaStatus'] ?? '',
      cusip: json['cusip'] ?? '',
      id: json['id'] ?? '',
      isin: json['isin'] ?? '',
      logo: json['logo'] ?? '',
      name: json['name'] ?? '',
      percent: (json['percent'] ?? 0).toDouble(),
      share: (json['share'] ?? 0).toDouble(),
      shariahStates: json['shariahStates'] ?? '',
      shariahStatus: json['shariahStatus'] ?? '',
      symbol: json['symbol'] ?? '',
      totalHoldings: json['total_holdings'] ?? '',
      updatedDate: json['updated_date'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetType': assetType,
      'cbaComment': cbaComment,
      'cbaStatus': cbaStatus,
      'cusip': cusip,
      'id': id,
      'isin': isin,
      'logo': logo,
      'name': name,
      'percent': percent,
      'share': share,
      'shariahStates': shariahStates,
      'shariahStatus': shariahStatus,
      'symbol': symbol,
      'total_holdings': totalHoldings,
      'updated_date': updatedDate,
      'value': value,
    };
  }
}

class EtfHoldingsData {
  final String etfProfileId;
  final List<EtfHolding> holdings;

  EtfHoldingsData({
    required this.etfProfileId,
    required this.holdings,
  });

  factory EtfHoldingsData.fromJson(Map<String, dynamic> json) {
    return EtfHoldingsData(
      etfProfileId: json['etfProfileId'] ?? '',
      holdings: (json['holdings'] as List<dynamic>?)
          ?.map((holding) => EtfHolding.fromJson(holding))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etfProfileId': etfProfileId,
      'holdings': holdings.map((holding) => holding.toJson()).toList(),
    };
  }
}

// Enriched holding with stock data
class EtfHoldingWithStockData {
  final EtfHolding holding;
  final StocksData? stockData;
  final CompanyProfile? companyProfile;

  EtfHoldingWithStockData({
    required this.holding,
    this.stockData,
    this.companyProfile,
  });
}
