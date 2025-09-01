
import 'package:musaffa_terminal/utils/utils.dart';

class EtfModel {
  String? assetClass;
  num? aum;
  String? description;
  String? domicile;
  String? etfCompany;
  EtfsData? etfsData;
  String? id;
  String? investmentSegment;
  String? name;
  String? navCurrency;
  num? ranking;
  ShariahCompliantStatus? shariahStates;
  String? symbol;
  String? website;

  EtfModel(
      {this.assetClass,
      this.aum,
      this.description,
      this.domicile,
      this.etfCompany,
      this.etfsData,
      this.id,
      this.investmentSegment,
      this.name,
      this.navCurrency,
      this.ranking,
      this.shariahStates,
      this.symbol,
      this.website});

  EtfModel.fromJson(Map<String, dynamic> json) {
    assetClass = json['assetClass'];
    aum = json['aum'];
    description = json['description'];
    domicile = json['domicile'];
    etfCompany = json['etfCompany'];
    etfsData = json['etfs_data'] != null
        ? new EtfsData.fromJson(json['etfs_data'])
        : null;
    id = json['id'];
    investmentSegment = json['investmentSegment'];
    name = json['name'];
    navCurrency = json['navCurrency'];
    symbol = json['symbol'];
    website = json['website'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['assetClass'] = this.assetClass;
    data['aum'] = this.aum;
    data['description'] = this.description;
    data['domicile'] = this.domicile;
    data['etfCompany'] = this.etfCompany;
    if (this.etfsData != null) {
      data['etfs_data'] = this.etfsData!.toJson();
    }
    data['id'] = this.id;
    data['investmentSegment'] = this.investmentSegment;
    data['name'] = this.name;
    data['navCurrency'] = this.navCurrency;
    data['symbol'] = this.symbol;
    data['website'] = this.website;
    return data;
  }
}

class EtfsData {
  num? d52WeekHigh;
  String? s52WeekHighDate;
  num? d52WeekLow;
  String? s52WeekLowDate;
  String? assetClass;
  num? aum;
  num? avgVolume10days;
  num? avgVolume30days;
  num? businessCompliantRatio;
  num? businessNonCompliantRatio;
  num? businessQuestionableRatio;
  String? calculatedInvestmentSegment;
  num? change1D;
  num? change1DPercent;
  num? close;
  String? createdAt;
  String? currency;
  num? currentPrice;
  num? dividentAmount;
  String? dividentDate;
  num? dividentFreq;
  String? domicile;
  num? etfTotalAssets;
  String? exchange;
  num? high;
  String? id;
  String? inceptionDate;
  num? interestBearingAssetsRatio;
  num? interestBearingDebtRatio;
  String? investmentSegment;
  num? isEtn;
  num? largecapExposure;
  num? low;
  num? megacapExposure;
  num? microcapExposure;
  num? midcapExposure;
  num? nanocapExposure;
  String? navCurrency;
  num? numberOfHoldings;
  num? open;
  num? priceChange1D;
  num? priceChange1DPercent;
  num? priceChange1M;
  num? priceChange1MPercent;
  num? priceChange1Y;
  num? priceChange1YPercent;
  num? priceChange3Y;
  num? priceChange3YPercent;
  num? priceChange5Y;
  num? priceChange5YPercent;
  String? priceLastUpdated;
  num? priceToBook;
  num? priceToEarnings;
  ShariahCompliantStatus? shariahCompliantStatus;
  num? smallcapExposure;
  String? symbol;
  num? isManualSet;
  String? disclaimer;
  // List<String>? top10holding;
  String? updatedAt;
  num? volume;
  num? rankingV2;

  EtfsData(
      {this.d52WeekHigh,
      this.s52WeekHighDate,
      this.d52WeekLow,
      this.s52WeekLowDate,
      this.assetClass,
      this.aum,
      this.avgVolume10days,
      this.avgVolume30days,
      this.businessCompliantRatio,
      this.businessNonCompliantRatio,
      this.businessQuestionableRatio,
      this.calculatedInvestmentSegment,
      this.change1D,
      this.change1DPercent,
      this.close,
      this.createdAt,
      this.currency,
      this.currentPrice,
      this.dividentAmount,
      this.dividentDate,
      this.dividentFreq,
      this.domicile,
      this.etfTotalAssets,
      this.exchange,
      this.high,
      this.id,
      this.inceptionDate,
      this.interestBearingAssetsRatio,
      this.interestBearingDebtRatio,
      this.investmentSegment,
      this.isEtn,
      this.largecapExposure,
      this.low,
      this.megacapExposure,
      this.microcapExposure,
      this.midcapExposure,
      this.nanocapExposure,
      this.navCurrency,
      this.numberOfHoldings,
      this.open,
      this.priceChange1D,
      this.priceChange1DPercent,
      this.priceChange1M,
      this.priceChange1MPercent,
      this.priceChange1Y,
      this.priceChange1YPercent,
      this.priceChange3Y,
      this.priceChange3YPercent,
      this.priceChange5Y,
      this.priceChange5YPercent,
      this.priceLastUpdated,
      this.priceToBook,
      this.priceToEarnings,
      this.shariahCompliantStatus,
      this.smallcapExposure,
      this.symbol,
      // this.top10holding,
      this.updatedAt,
      this.volume,
        this.disclaimer,
        this.rankingV2,
      this.isManualSet});

  EtfsData.fromJson(Map<String, dynamic> json) {
    d52WeekHigh = json['52WeekHigh'];
    s52WeekHighDate = json['52WeekHighDate'];
    d52WeekLow = json['52WeekLow'];
    s52WeekLowDate = json['52WeekLowDate'];
    assetClass = json['assetClass'];
    aum = json['aum'];
    avgVolume10days = json['avgVolume10days'];
    avgVolume30days = json['avgVolume30days'];
    businessCompliantRatio = json['businessCompliantRatio'];
    businessNonCompliantRatio = json['businessNonCompliantRatio'];
    businessQuestionableRatio = json['businessQuestionableRatio'];
    calculatedInvestmentSegment = json['calculated_investment_segment'];
    change1D = json['change1D'];
    change1DPercent = json['change1DPercent'];
    close = json['close'];
    createdAt = json['created_at'];
    currency = json['currency'];
    currentPrice = json['currentPrice'];
    dividentAmount = json['divident_amount'];
    dividentDate = json['divident_date'];
    dividentFreq = json['divident_freq'];
    domicile = json['domicile'];
    etfTotalAssets = json['etf_totalAssets'];
    exchange = json['exchange'];
    high = json['high'];
    id = json['id'];
    inceptionDate = json['inceptionDate'];
    interestBearingAssetsRatio = json['interestBearingAssetsRatio'];
    interestBearingDebtRatio = json['interestBearingDebtRatio'];
    investmentSegment = json['investmentSegment'];
    isEtn = json['is_etn'];
    largecapExposure = json['largecap_exposure'];
    low = json['low'];
    megacapExposure = json['megacap_exposure'];
    microcapExposure = json['microcap_exposure'];
    midcapExposure = json['midcap_exposure'];
    nanocapExposure = json['nanocap_exposure'];
    navCurrency = json['navCurrency'];
    numberOfHoldings = json['numberOfHoldings'];
    open = json['open'];
    priceChange1D = json['priceChange1D'];
    priceChange1DPercent = json['priceChange1DPercent'];
    priceChange1M = json['priceChange1M'];
    priceChange1MPercent = json['priceChange1MPercent'];
    priceChange1Y = json['priceChange1Y'];
    priceChange1YPercent = json['priceChange1YPercent'];
    priceChange3Y = json['priceChange3Y'];
    priceChange3YPercent = json['priceChange3YPercent'];
    priceChange5Y = json['priceChange5Y'];
    priceChange5YPercent = json['priceChange5YPercent'];
    priceLastUpdated = json['priceLastUpdated'];
    priceToBook = json['priceToBook'];
    priceToEarnings = json['priceToEarnings'];
    shariahCompliantStatus= json["shariahCompliantStatus"] == null
        ? null
        : shariahCompliantStatusValues.map[json["shariahCompliantStatus"]];
    smallcapExposure = json['smallcap_exposure'];
    symbol = json['symbol'];
    // top10holding = json['top10holding'].cast<String>();
    updatedAt = json['updated_at'];
    volume = json['volume'];
    isManualSet = json['is_manual_set'];
    disclaimer = json['disclaimer'];
    rankingV2 = json['ranking_v2'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['52WeekHigh'] = this.d52WeekHigh;
    data['52WeekHighDate'] = this.s52WeekHighDate;
    data['52WeekLow'] = this.d52WeekLow;
    data['52WeekLowDate'] = this.s52WeekLowDate;
    data['assetClass'] = this.assetClass;
    data['aum'] = this.aum;
    data['avgVolume10days'] = this.avgVolume10days;
    data['avgVolume30days'] = this.avgVolume30days;
    data['businessCompliantRatio'] = this.businessCompliantRatio;
    data['businessNonCompliantRatio'] = this.businessNonCompliantRatio;
    data['businessQuestionableRatio'] = this.businessQuestionableRatio;
    data['calculated_investment_segment'] = this.calculatedInvestmentSegment;
    data['change1D'] = this.change1D;
    data['change1DPercent'] = this.change1DPercent;
    data['close'] = this.close;
    data['created_at'] = this.createdAt;
    data['currency'] = this.currency;
    data['currentPrice'] = this.currentPrice;
    data['divident_amount'] = this.dividentAmount;
    data['divident_date'] = this.dividentDate;
    data['divident_freq'] = this.dividentFreq;
    data['domicile'] = this.domicile;
    data['etf_totalAssets'] = this.etfTotalAssets;
    data['exchange'] = this.exchange;
    data['high'] = this.high;
    data['id'] = this.id;
    data['inceptionDate'] = this.inceptionDate;
    data['interestBearingAssetsRatio'] = this.interestBearingAssetsRatio;
    data['interestBearingDebtRatio'] = this.interestBearingDebtRatio;
    data['investmentSegment'] = this.investmentSegment;
    data['is_etn'] = this.isEtn;
    data['largecap_exposure'] = this.largecapExposure;
    data['low'] = this.low;
    data['megacap_exposure'] = this.megacapExposure;
    data['microcap_exposure'] = this.microcapExposure;
    data['midcap_exposure'] = this.midcapExposure;
    data['nanocap_exposure'] = this.nanocapExposure;
    data['navCurrency'] = this.navCurrency;
    data['numberOfHoldings'] = this.numberOfHoldings;
    data['open'] = this.open;
    data['priceChange1D'] = this.priceChange1D;
    data['priceChange1DPercent'] = this.priceChange1DPercent;
    data['priceChange1M'] = this.priceChange1M;
    data['priceChange1MPercent'] = this.priceChange1MPercent;
    data['priceChange1Y'] = this.priceChange1Y;
    data['priceChange1YPercent'] = this.priceChange1YPercent;
    data['priceChange3Y'] = this.priceChange3Y;
    data['priceChange3YPercent'] = this.priceChange3YPercent;
    data['priceChange5Y'] = this.priceChange5Y;
    data['priceChange5YPercent'] = this.priceChange5YPercent;
    data['priceLastUpdated'] = this.priceLastUpdated;
    data['priceToBook'] = this.priceToBook;
    data['priceToEarnings'] = this.priceToEarnings;
    data['shariahCompliantStatus'] = this.shariahCompliantStatus?.name;
    data['smallcap_exposure'] = this.smallcapExposure;
    data['symbol'] = this.symbol;
    // data['top10holding'] = this.top10holding;
    data['updated_at'] = this.updatedAt;
    data['volume'] = this.volume;
    data['is_manual_set'] = this.isManualSet;
    data['disclaimer'] = this.disclaimer;
    data['ranking_v2'] = this.rankingV2;
    return data;
  }
}
