import 'package:musaffa_terminal/utils/utils.dart';

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
  num? priceChange1W;
  num? priceChange1WPercent;
  num? priceChange3M;
  num? priceChange3MPercent;
  num? priceChange6M;
  num? priceChange6MPercent;
  num? priceChangeYTD;
  num? priceChangeYTDPercent;
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
  num? expenseRatio;
  num? nav;
  num? previousClose;
  num? isInverse;
  num? isLeveraged;
  Map<String, dynamic>? sectorExposure;
  Map<String, dynamic>? countryExposure;
  num? totalReturn1M;
  num? totalReturn1W;
  num? totalReturn1Y;
  num? totalReturn3M;
  num? totalReturn3Y;
  num? totalReturn5Y;
  num? totalReturn6M;
  EtfProfileData? etfProfile;

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
      this.isManualSet,
      this.expenseRatio,
      this.nav,
      this.previousClose,
      this.isInverse,
      this.isLeveraged,
      this.sectorExposure,
      this.countryExposure,
      this.totalReturn1M,
      this.totalReturn1W,
      this.totalReturn1Y,
      this.totalReturn3M,
      this.totalReturn3Y,
      this.totalReturn5Y,
      this.totalReturn6M,
      this.priceChange1W,
      this.priceChange1WPercent,
      this.priceChange3M,
      this.priceChange3MPercent,
      this.priceChange6M,
      this.priceChange6MPercent,
      this.priceChangeYTD,
      this.priceChangeYTDPercent,
      this.etfProfile});

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
    expenseRatio = json['expense_ratio'];
    nav = json['nav'];
    previousClose = json['previous_close'];
    isInverse = json['is_inverse'];
    isLeveraged = json['is_leveraged'];
    sectorExposure = json['sector_exposure'] != null 
        ? Map<String, dynamic>.from(json['sector_exposure']) 
        : null;
    countryExposure = json['country_exposure'] != null 
        ? Map<String, dynamic>.from(json['country_exposure']) 
        : null;
    totalReturn1M = json['totalReturn1M'];
    totalReturn1W = json['totalReturn1W'];
    totalReturn1Y = json['totalReturn1Y'];
    totalReturn3M = json['totalReturn3M'];
    totalReturn3Y = json['totalReturn3Y'];
    totalReturn5Y = json['totalReturn5Y'];
    totalReturn6M = json['totalReturn6M'];
    priceChange1W = json['priceChange1W'];
    priceChange1WPercent = json['priceChange1WPercent'];
    priceChange3M = json['priceChange3M'];
    priceChange3MPercent = json['priceChange3MPercent'];
    priceChange6M = json['priceChange6M'];
    priceChange6MPercent = json['priceChange6MPercent'];
    priceChangeYTD = json['priceChangeYTD'];
    priceChangeYTDPercent = json['priceChangeYTDPercent'];
    etfProfile = json['etf_profile_collection_4'] != null
        ? EtfProfileData.fromJson(json['etf_profile_collection_4'])
        : null;
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
    data['expense_ratio'] = this.expenseRatio;
    data['nav'] = this.nav;
    data['previous_close'] = this.previousClose;
    data['is_inverse'] = this.isInverse;
    data['is_leveraged'] = this.isLeveraged;
    data['sector_exposure'] = this.sectorExposure;
    data['country_exposure'] = this.countryExposure;
    data['totalReturn1M'] = this.totalReturn1M;
    data['totalReturn1W'] = this.totalReturn1W;
    data['totalReturn1Y'] = this.totalReturn1Y;
    data['totalReturn3M'] = this.totalReturn3M;
    data['totalReturn3Y'] = this.totalReturn3Y;
    data['totalReturn5Y'] = this.totalReturn5Y;
    data['totalReturn6M'] = this.totalReturn6M;
    data['priceChange1W'] = this.priceChange1W;
    data['priceChange1WPercent'] = this.priceChange1WPercent;
    data['priceChange3M'] = this.priceChange3M;
    data['priceChange3MPercent'] = this.priceChange3MPercent;
    data['priceChange6M'] = this.priceChange6M;
    data['priceChange6MPercent'] = this.priceChange6MPercent;
    data['priceChangeYTD'] = this.priceChangeYTD;
    data['priceChangeYTDPercent'] = this.priceChangeYTDPercent;
    if (this.etfProfile != null) {
      data['etf_profile_collection_4'] = this.etfProfile!.toJson();
    }
    return data;
  }
}

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

class EtfProfileData {
  String? name;
  String? description;
  String? navCurrency;
  String? symbol;

  EtfProfileData({
    this.name,
    this.description,
    this.navCurrency,
    this.symbol,
  });

  EtfProfileData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    navCurrency = json['navCurrency'];
    symbol = json['symbol'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'navCurrency': navCurrency,
      'symbol': symbol,
    };
  }
}