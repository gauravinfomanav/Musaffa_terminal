

import 'package:musaffa_terminal/models/ticker_model.dart';

class TickerCellModel {

  final String currency;
  final String tickerName;
  final String mainTicker;
  final String companyName;
  final num? currentPrice;
  final ShariahCompliantStatus? halalRate;
  final num? ranking;
  final num? percentchange;
  final bool hideBadge;
  final String? logoUrl;
  final String?country;
  final bool isStock;
  final bool? detailProfileavailable;
  final TickerModel? stock;
  // final bool forceShowLogoSection;

final bool? showLockOnStars;
  final String? analystRating;
  const TickerCellModel( {
    // this.forceShowLogoSection = false,
    this.analystRating,
    required this.currency,
    required this.tickerName,
    required this.companyName,
    this.currentPrice,
    required this.halalRate,
    this.country,
    this.ranking,
    this.stock,
    this.percentchange,
    this.detailProfileavailable,
    this.hideBadge = false,
    required this.logoUrl,
    required this.isStock,
    this.showLockOnStars,
    required this.mainTicker
  });

  Map<String, dynamic> toJson() => {
    'country':country,
    'currency': currency,
    'detailProfileavailable':detailProfileavailable,
    'tickerName': tickerName,
    'stock': stock,
    'companyName': companyName,
    'currentPrice': currentPrice,
    'halalRate': halalRate,
    'ranking': ranking,
    'hideBadge': hideBadge,
    'logoUrl': logoUrl,
    'isStock': isStock,
    'percentchange':percentchange,
    'mainTicker':mainTicker
  };

}
enum ShariahCompliantStatus {
  NOT_UNDER_COVERAGE,
  NON_COMPLIANT,
  QUESTIONABLE,
  COMPLIANT,
  DEFAULT,
}

final shariahCompliantStatusValues = EnumValues({
  "NOT_UNDER_COVERAGE": ShariahCompliantStatus.NOT_UNDER_COVERAGE,
  "COMPLIANT": ShariahCompliantStatus.COMPLIANT,
  "QUESTIONABLE": ShariahCompliantStatus.QUESTIONABLE,
  "NON_COMPLIANT": ShariahCompliantStatus.NON_COMPLIANT,
  "DEFAULT": ShariahCompliantStatus.DEFAULT,
});
class EnumValues<T> {
  Map<String, T> map;
  Map<T, String>? reverseMap;

  EnumValues(this.map);

  Map<T, String>? get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}
