

import 'package:musaffa_terminal/utils/utils.dart';

class StocksData {
  num? d52WeekHigh;
  String? s52WeekHighDate;
  num? d52WeekLow;
  String? s52WeekLowDate;
  num? operatingIncomeAnnual;
  num? rOE;
  String? analystRecommendationWeightedAvg;
  num? assetTurnoverAnnual;
  num? assetTurnoverTTM;
  num? avgVolume10days;
  num? avgVolume30days;
  num? beta;
  num? bookValuePerShareAnnual;
  num? bookValuePerShareQuarterly;
  num? businessCompliantRatio;
  num? businessNonCompliantRatio;
  num? businessQuestionableRatio;
  num? cashFlowPerShareAnnual;
  num? cashFlowPerShareQuarterly;
  num? cashPerSharePerShareAnnual;
  num? cashPerSharePerShareQuarterly;
  num? cashToDebt;
  num? change1D;
  num? change1DPercent;
  num? close;
  String? companyCountry;
  String? companySymbol;
  String? country;
  String? createdAt;
  String? currency;
  num? currentDividendYieldTTM;
  num? currentEvFreeCashFlowAnnual;
  num? currentEvFreeCashFlowTTM;
  num? currentPrice;
  num? currentRatioAnnual;
  num? currentRatioQuarterly;
  num? dividendPerShareAnnual;
  num? dividendPerShareTTM;
  num? dividendYieldIndicatedAnnual;
  num? doubtfulRevenuePercent;
  num? ebitAnnual;
  num? ebitEstimateAnnual;
  num? ebitdPerShareAnnual;
  num? ebitdPerShareTTM;
  num? ebitdaEstimateAnnual;
  num? ebitdaEstimateQuarterly;
  num? employeeTotal;
  num? enterpriseValue;
  num? epsAnnual;
  num? epsBasicExclExtraItemsTTM;
  num? epsGrowth3Y;
  num? epsGrowth5Y;
  num? epsGrowthQuarterlyYoy;
  num? epsGrowthTTMYoy;
  num? epsNormalizedAnnual;
  num? epsTTM;
  num? epsEstimateAnnual;
  num? epsEstimateQuarterly;
  num? epsGrowth1y;
  num? equityToAssetsAnnual;
  num? evEbit;
  num? evFcf;
  num? evRevenue;
  String? exchange;
  String? exchangeCountry;
  String? exchangeSymbol;
  num? grossIncomeAnnual;
  num? grossMarginAnnual;
  num? grossMarginTTM;
  num? halalRevenuePercent;
  num? high;
  String? id;
  String? industry;
  num? interestBearingAssetsRatio;
  num? interestBearingDebtRatio;
  num? interestbearingDebtPercent;
  num? intrestbearingAssetPercent;
  num? inventoryTurnoverAnnual;
  String? ipoDate;
  num? isMainTicker;
  String? isin;
  num? longTermDebtEquityAnnual;
  num? longTermDebtEquityQuarterly;
  num? low;
  String? marketCapClassification;
  num? marketCapChange3y;
  num? marketcap;
  ShariahCompliantStatus? shariaCompliance;
  String? musaffaIndustry;
  String? musaffaSector;
  num? musaffaEsgRanking;
  num? musaffaEsgScore;
  num? netInterestCoverageAnnual;
  num? netInterestCoverageTTM;
  num? netProfitMarginAnnual;
  num? netProfitMarginTTM;
  num? netIncomeAnnual;
  num? nothalalRevenuePercent;
  num? open;
  num? operatingMarginAnnual;
  num? operatingMarginTTM;
  num? payoutRatioTTM;
  num? pbAnnual;
  num? pbQuarterly;
  num? pc;
  num? pcfShareTTM;
  num? peAnnual;
  num? peBasicExclExtraTTM;
  num? peExclExtraAnnual;
  num? peExclExtraTTM;
  num? peInclExtraTTM;
  num? peNormalizedAnnual;
  num? peTTM;
  num? pfcfShareAnnual;
  num? pfcfShareTTM;
  num? pretaxMarginAnnual;
  num? previousClose;
  num? priceChange1D;
  num? priceChange1DPercent;
  num? priceChange1M;
  num? priceChange1MPercent;
  num? priceChange1W;
  num? priceChange1WPercent;
  num? priceChange1Y;
  num? priceChange1YPercent;
  num? priceChange3M;
  num? priceChange3MPercent;
  num? priceChange3Y;
  num? priceChange3YPercent;
  num? priceChange5Y;
  num? priceChange5YPercent;
  num? priceChange6M;
  num? priceChange6MPercent;
  num? priceChangeYTD;
  num? priceChangeYTDPercent;
  String? priceLastUpdated;
  num? priceTangiblebookValueAnnual;
  num? priceTangiblebookValueQuarterly;
  num? priceToTangibleBookRatioAnnual;
  num? priceToTangibleBookRatioQuarterly;
  num? psAnnual;
  num? psTTM;
  num? ptbvAnnual;
  num? ptbvQuarterly;
  num? quickRatioAnnual;
  num? quickRatioQuarterly;
  num? rankingV2;
  num? receivablesTurnoverTTM;
  String? recommendationWeightedAverage;
  num? revenueGrowth1Y;
  num? revenueGrowth3Y;
  num? revenueGrowth5Y;
  num? revenueGrowthQuarterlyYoy;
  num? revenueGrowthTTMYoy;
  num? revenuePerShareAnnual;
  num? revenuePerShareTTM;
  num? revenueShareGrowth5Y;
  num? revenueAnnual;
  num? revenueEstimateQuarterly;
  num? roa5Y;
  num? roaRfy;
  num? roaTTM;
  num? roe5Y;
  num? roiAnnual;
  num? rotcAnnual;
  num? salesPerShareAnnual;
  String? sector;
  num? sharesOutStanding;
  String? status;
  num? tangibleBookValuePerShareAnnual;
  num? tangibleBookValuePerShareQuarterly;
  String? ticker;
  num? totalDebtTotalEquityAnnual;
  num? totalDebtTotalEquityQuarterly;
  String? updatedAt;
  num? usdMarketCap;
  num? volume;

  StocksData(
      {this.d52WeekHigh,
        this.s52WeekHighDate,
        this.d52WeekLow,
        this.s52WeekLowDate,
        this.operatingIncomeAnnual,
        this.rOE,
        this.analystRecommendationWeightedAvg,
        this.assetTurnoverAnnual,
        this.assetTurnoverTTM,
        this.avgVolume10days,
        this.avgVolume30days,
        this.beta,
        this.bookValuePerShareAnnual,
        this.bookValuePerShareQuarterly,
        this.businessCompliantRatio,
        this.businessNonCompliantRatio,
        this.businessQuestionableRatio,
        this.cashFlowPerShareAnnual,
        this.cashFlowPerShareQuarterly,
        this.cashPerSharePerShareAnnual,
        this.cashPerSharePerShareQuarterly,
        this.cashToDebt,
        this.change1D,
        this.change1DPercent,
        this.close,
        this.companyCountry,
        this.companySymbol,
        this.country,
        this.createdAt,
        this.currency,
        this.currentDividendYieldTTM,
        this.currentEvFreeCashFlowAnnual,
        this.currentEvFreeCashFlowTTM,
        this.currentPrice,
        this.currentRatioAnnual,
        this.currentRatioQuarterly,
        this.dividendPerShareAnnual,
        this.dividendPerShareTTM,
        this.dividendYieldIndicatedAnnual,
        this.doubtfulRevenuePercent,
        this.ebitAnnual,
        this.ebitEstimateAnnual,
        this.ebitdPerShareAnnual,
        this.ebitdPerShareTTM,
        this.ebitdaEstimateAnnual,
        this.ebitdaEstimateQuarterly,
        this.employeeTotal,
        this.enterpriseValue,
        this.epsAnnual,
        this.epsBasicExclExtraItemsTTM,
        this.epsGrowth3Y,
        this.epsGrowth5Y,
        this.epsGrowthQuarterlyYoy,
        this.epsGrowthTTMYoy,
        this.epsNormalizedAnnual,
        this.epsTTM,
        this.epsEstimateAnnual,
        this.epsEstimateQuarterly,
        this.epsGrowth1y,
        this.equityToAssetsAnnual,
        this.evEbit,
        this.evFcf,
        this.evRevenue,
        this.exchange,
        this.exchangeCountry,
        this.exchangeSymbol,
        this.grossIncomeAnnual,
        this.grossMarginAnnual,
        this.grossMarginTTM,
        this.halalRevenuePercent,
        this.high,
        this.id,
        this.industry,
        this.interestBearingAssetsRatio,
        this.interestBearingDebtRatio,
        this.interestbearingDebtPercent,
        this.intrestbearingAssetPercent,
        this.inventoryTurnoverAnnual,
        this.ipoDate,
        this.isMainTicker,
        this.isin,
        this.longTermDebtEquityAnnual,
        this.longTermDebtEquityQuarterly,
        this.low,
        this.marketCapClassification,
        this.marketCapChange3y,
        this.marketcap,
        this.musaffaIndustry,
        this.musaffaSector,
        this.musaffaEsgRanking,
        this.musaffaEsgScore,
        this.netInterestCoverageAnnual,
        this.netInterestCoverageTTM,
        this.netProfitMarginAnnual,
        this.netProfitMarginTTM,
        this.netIncomeAnnual,
        this.nothalalRevenuePercent,
        this.open,
        this.operatingMarginAnnual,
        this.operatingMarginTTM,
        this.payoutRatioTTM,
        this.pbAnnual,
        this.pbQuarterly,
        this.pc,
        this.pcfShareTTM,
        this.peAnnual,
        this.peBasicExclExtraTTM,
        this.peExclExtraAnnual,
        this.peExclExtraTTM,
        this.peInclExtraTTM,
        this.peNormalizedAnnual,
        this.peTTM,
        this.pfcfShareAnnual,
        this.pfcfShareTTM,
        this.pretaxMarginAnnual,
        this.previousClose,
        this.priceChange1D,
        this.priceChange1DPercent,
        this.priceChange1M,
        this.priceChange1MPercent,
        this.priceChange1W,
        this.priceChange1WPercent,
        this.priceChange1Y,
        this.priceChange1YPercent,
        this.priceChange3M,
        this.priceChange3MPercent,
        this.priceChange3Y,
        this.priceChange3YPercent,
        this.priceChange5Y,
        this.priceChange5YPercent,
        this.priceChange6M,
        this.priceChange6MPercent,
        this.priceChangeYTD,
        this.priceChangeYTDPercent,
        this.priceLastUpdated,
        this.priceTangiblebookValueAnnual,
        this.priceTangiblebookValueQuarterly,
        this.priceToTangibleBookRatioAnnual,
        this.priceToTangibleBookRatioQuarterly,
        this.psAnnual,
        this.psTTM,
        this.ptbvAnnual,
        this.ptbvQuarterly,
        this.quickRatioAnnual,
        this.quickRatioQuarterly,
        this.rankingV2,
        this.receivablesTurnoverTTM,
        this.recommendationWeightedAverage,
        this.revenueGrowth1Y,
        this.revenueGrowth3Y,
        this.revenueGrowth5Y,
        this.revenueGrowthQuarterlyYoy,
        this.revenueGrowthTTMYoy,
        this.revenuePerShareAnnual,
        this.revenuePerShareTTM,
        this.revenueShareGrowth5Y,
        this.revenueAnnual,
        this.revenueEstimateQuarterly,
        this.roa5Y,
        this.roaRfy,
        this.roaTTM,
        this.roe5Y,
        this.roiAnnual,
        this.rotcAnnual,
        this.salesPerShareAnnual,
        this.sector,
        this.sharesOutStanding,
        this.shariaCompliance,
        this.status,
        this.tangibleBookValuePerShareAnnual,
        this.tangibleBookValuePerShareQuarterly,
        this.ticker,
        this.totalDebtTotalEquityAnnual,
        this.totalDebtTotalEquityQuarterly,
        this.updatedAt,
        this.usdMarketCap,
        this.volume});

  StocksData.fromJson(Map<String, dynamic> json) {
    d52WeekHigh = json['52WeekHigh'];
    s52WeekHighDate = json['52WeekHighDate'];
    d52WeekLow = json['52WeekLow'];
    s52WeekLowDate = json['52WeekLowDate'];
    operatingIncomeAnnual = json['OperatingIncome_annual'];
    rOE = json['ROE'];
    analystRecommendationWeightedAvg =
    json['analyst_recommendation_weighted_avg'];
    assetTurnoverAnnual = json['assetTurnoverAnnual'];
    assetTurnoverTTM = json['assetTurnoverTTM'];
    avgVolume10days = json['avgVolume10days'];
    avgVolume30days = json['avgVolume30days'];
    beta = json['beta'];
    bookValuePerShareAnnual = json['bookValuePerShareAnnual'];
    bookValuePerShareQuarterly = json['bookValuePerShareQuarterly'];
    businessCompliantRatio = json['businessCompliantRatio'];
    businessNonCompliantRatio = json['businessNonCompliantRatio'];
    businessQuestionableRatio = json['businessQuestionableRatio'];
    cashFlowPerShareAnnual = json['cashFlowPerShareAnnual'];
    cashFlowPerShareQuarterly = json['cashFlowPerShareQuarterly'];
    cashPerSharePerShareAnnual = json['cashPerSharePerShareAnnual'];
    cashPerSharePerShareQuarterly = json['cashPerSharePerShareQuarterly'];
    cashToDebt = json['cash_to_debt'];
    change1D = json['change1D'];
    change1DPercent = json['change1DPercent'];
    close = json['close'];
    companyCountry = json['company_country'];
    companySymbol = json['company_symbol'];
    country = json['country'];
    createdAt = json['created_at'];
    currency = json['currency'];
    currentDividendYieldTTM = json['currentDividendYieldTTM'];
    currentEvFreeCashFlowAnnual = json['currentEv_freeCashFlowAnnual'];
    currentEvFreeCashFlowTTM = json['currentEv_freeCashFlowTTM'];
    currentPrice = json['currentPrice'];
    currentRatioAnnual = json['currentRatioAnnual'];
    currentRatioQuarterly = json['currentRatioQuarterly'];
    dividendPerShareAnnual = json['dividendPerShareAnnual'];
    dividendPerShareTTM = json['dividendPerShareTTM'];
    dividendYieldIndicatedAnnual = json['dividendYieldIndicatedAnnual'];
    doubtfulRevenuePercent = json['doubtful_revenue_percent'];
    ebitAnnual = json['ebit_annual'];
    ebitEstimateAnnual = json['ebit_estimate_annual'];
    ebitdPerShareAnnual = json['ebitdPerShareAnnual'];
    ebitdPerShareTTM = json['ebitdPerShareTTM'];
    ebitdaEstimateAnnual = json['ebitda_estimate_annual'];
    ebitdaEstimateQuarterly = json['ebitda_estimate_quarterly'];
    employeeTotal = json['employeeTotal'];
    enterpriseValue = json['enterpriseValue'];
    epsAnnual = json['epsAnnual'];
    epsBasicExclExtraItemsTTM = json['epsBasicExclExtraItemsTTM'];
    epsGrowth3Y = json['epsGrowth3Y'];
    epsGrowth5Y = json['epsGrowth5Y'];
    epsGrowthQuarterlyYoy = json['epsGrowthQuarterlyYoy'];
    epsGrowthTTMYoy = json['epsGrowthTTMYoy'];
    epsNormalizedAnnual = json['epsNormalizedAnnual'];
    epsTTM = json['epsTTM'];
    epsEstimateAnnual = json['eps_estimate_annual'];
    epsEstimateQuarterly = json['eps_estimate_quarterly'];
    epsGrowth1y = json['eps_growth_1y'];
    equityToAssetsAnnual = json['equity_to_assets_annual'];
    evEbit = json['ev_ebit'];
    evFcf = json['ev_fcf'];
    evRevenue = json['ev_revenue'];
    exchange = json['exchange'];
    exchangeCountry = json['exchange_country'];
    exchangeSymbol = json['exchange_symbol'];
    grossIncomeAnnual = json['grossIncome_annual'];
    grossMarginAnnual = json['gross_margin_annual'];
    grossMarginTTM = json['grossMarginTTM'];
    halalRevenuePercent = json['halal_revenue_percent'];
    high = json['high'];
    id = json['id'];
    industry = json['industry'];
    interestBearingAssetsRatio = json['interestBearingAssetsRatio'];
    interestBearingDebtRatio = json['interestBearingDebtRatio'];
    interestbearingDebtPercent = json['interestbearing_debt_percent'];
    intrestbearingAssetPercent = json['intrestbearing_asset_percent'];
    inventoryTurnoverAnnual = json['inventoryTurnoverAnnual'];
    ipoDate = json['ipoDate'];
    isMainTicker = json['isMainTicker'];
    isin = json['isin'];
    longTermDebtEquityAnnual = json['longTermDebt_equityAnnual'];
    longTermDebtEquityQuarterly = json['longTermDebt_equityQuarterly'];
    low = json['low'];
    marketCapClassification = json['marketCapClassification'];
    marketCapChange3y = json['marketCap_change_3y'];
    marketcap = json['marketcap'];
    shariaCompliance= json["sharia_compliance"] == null
        ? null
        : shariahCompliantStatusValues.map[json["sharia_compliance"]];
    musaffaIndustry = json['musaffaIndustry'];
    musaffaSector = json['musaffaSector'];
    musaffaEsgRanking = json['musaffa_esg_ranking'];
    musaffaEsgScore = json['musaffa_esg_score'];
    netInterestCoverageAnnual = json['netInterestCoverageAnnual'];
    netInterestCoverageTTM = json['netInterestCoverageTTM'];
    netProfitMarginAnnual = json['netProfitMarginAnnual'];
    netProfitMarginTTM = json['netProfitMarginTTM'];
    netIncomeAnnual = json['net_income_annual'];
    nothalalRevenuePercent = json['nothalal_revenue_percent'];
    open = json['open'];
    operatingMarginAnnual = json['operatingMarginAnnual'];
    operatingMarginTTM = json['operatingMarginTTM'];
    payoutRatioTTM = json['payoutRatioTTM'];
    pbAnnual = json['pbAnnual'];
    pbQuarterly = json['pbQuarterly'];
    pc = json['pc'];
    pcfShareTTM = json['pcfShareTTM'];
    peAnnual = json['peAnnual'];
    peBasicExclExtraTTM = json['peBasicExclExtraTTM'];
    peExclExtraAnnual = json['peExclExtraAnnual'];
    peExclExtraTTM = json['peExclExtraTTM'];
    peInclExtraTTM = json['peInclExtraTTM'];
    peNormalizedAnnual = json['peNormalizedAnnual'];
    peTTM = json['peTTM'];
    pfcfShareAnnual = json['pfcfShareAnnual'];
    pfcfShareTTM = json['pfcfShareTTM'];
    pretaxMarginAnnual = json['pretaxMarginAnnual'];
    previousClose = json['previous_close'];
    priceChange1D = json['priceChange1D'];
    priceChange1DPercent = json['priceChange1DPercent'];
    priceChange1M = json['priceChange1M'];
    priceChange1MPercent = json['priceChange1MPercent'];
    priceChange1W = json['priceChange1W'];
    priceChange1WPercent = json['priceChange1WPercent'];
    priceChange1Y = json['priceChange1Y'];
    priceChange1YPercent = json['priceChange1YPercent'];
    priceChange3M = json['priceChange3M'];
    priceChange3MPercent = json['priceChange3MPercent'];
    priceChange3Y = json['priceChange3Y'];
    priceChange3YPercent = json['priceChange3YPercent'];
    priceChange5Y = json['priceChange5Y'];
    priceChange5YPercent = json['priceChange5YPercent'];
    priceChange6M = json['priceChange6M'];
    priceChange6MPercent = json['priceChange6MPercent'];
    priceChangeYTD = json['priceChangeYTD'];
    priceChangeYTDPercent = json['priceChangeYTDPercent'];
    priceLastUpdated = json['priceLastUpdated'];
    priceTangiblebookValueAnnual = json['price_tangiblebook_value_annual'];
    priceTangiblebookValueQuarterly =
    json['price_tangiblebook_value_quarterly'];
    priceToTangibleBookRatioAnnual =
    json['price_to_tangible_book_ratio_annual'];
    priceToTangibleBookRatioQuarterly =
    json['price_to_tangible_book_ratio_quarterly'];
    psAnnual = json['psAnnual'];
    psTTM = json['psTTM'];
    ptbvAnnual = json['ptbvAnnual'];
    ptbvQuarterly = json['ptbvQuarterly'];
    quickRatioAnnual = json['quickRatioAnnual'];
    quickRatioQuarterly = json['quickRatioQuarterly'];
    rankingV2 = json['ranking_v2'];
    receivablesTurnoverTTM = json['receivablesTurnoverTTM'];
    recommendationWeightedAverage = json['recommendationWeightedAverage'];
    revenueGrowth1Y = json['revenueGrowth1Y'];
    revenueGrowth3Y = json['revenueGrowth3Y'];
    revenueGrowth5Y = json['revenueGrowth5Y'];
    revenueGrowthQuarterlyYoy = json['revenueGrowthQuarterlyYoy'];
    revenueGrowthTTMYoy = json['revenueGrowthTTMYoy'];
    revenuePerShareAnnual = json['revenuePerShareAnnual'];
    revenuePerShareTTM = json['revenuePerShareTTM'];
    revenueShareGrowth5Y = json['revenueShareGrowth5Y'];
    revenueAnnual = json['revenue_annual'];
    revenueEstimateQuarterly = json['revenue_estimate_quarterly'];
    roa5Y = json['roa5Y'];
    roaRfy = json['roaRfy'];
    roaTTM = json['roaTTM'];
    roe5Y = json['roe5Y'];
    roiAnnual = json['roiAnnual'];
    rotcAnnual = json['rotc_annual'];
    salesPerShareAnnual = json['salesPerShare_annual'];
    sector = json['sector'];
    sharesOutStanding = json['sharesOutStanding'];
    status = json['status'];
    tangibleBookValuePerShareAnnual = json['tangibleBookValuePerShareAnnual'];
    tangibleBookValuePerShareQuarterly =
    json['tangibleBookValuePerShareQuarterly'];
    ticker = json['ticker'];
    totalDebtTotalEquityAnnual = json['totalDebt_totalEquityAnnual'];
    totalDebtTotalEquityQuarterly = json['totalDebt_totalEquityQuarterly'];
    updatedAt = json['updated_at'];
    usdMarketCap = json['usdMarketCap'];
    volume = json['volume'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['52WeekHigh'] = this.d52WeekHigh;
    data['52WeekHighDate'] = this.s52WeekHighDate;
    data['52WeekLow'] = this.d52WeekLow;
    data['52WeekLowDate'] = this.s52WeekLowDate;
    data['OperatingIncome_annual'] = this.operatingIncomeAnnual;
    data['ROE'] = this.rOE;
    data['analyst_recommendation_weighted_avg'] =
        this.analystRecommendationWeightedAvg;
    data['assetTurnoverAnnual'] = this.assetTurnoverAnnual;
    data['assetTurnoverTTM'] = this.assetTurnoverTTM;
    data['avgVolume10days'] = this.avgVolume10days;
    data['avgVolume30days'] = this.avgVolume30days;
    data['beta'] = this.beta;
    data['bookValuePerShareAnnual'] = this.bookValuePerShareAnnual;
    data['bookValuePerShareQuarterly'] = this.bookValuePerShareQuarterly;
    data['businessCompliantRatio'] = this.businessCompliantRatio;
    data['businessNonCompliantRatio'] = this.businessNonCompliantRatio;
    data['businessQuestionableRatio'] = this.businessQuestionableRatio;
    data['cashFlowPerShareAnnual'] = this.cashFlowPerShareAnnual;
    data['cashFlowPerShareQuarterly'] = this.cashFlowPerShareQuarterly;
    data['cashPerSharePerShareAnnual'] = this.cashPerSharePerShareAnnual;
    data['cashPerSharePerShareQuarterly'] = this.cashPerSharePerShareQuarterly;
    data['cash_to_debt'] = this.cashToDebt;
    data['change1D'] = this.change1D;
    data['change1DPercent'] = this.change1DPercent;
    data['close'] = this.close;
    data['company_country'] = this.companyCountry;
    data['company_symbol'] = this.companySymbol;
    data['country'] = this.country;
    data['created_at'] = this.createdAt;
    data['currency'] = this.currency;
    data['currentDividendYieldTTM'] = this.currentDividendYieldTTM;
    data['currentEv_freeCashFlowAnnual'] = this.currentEvFreeCashFlowAnnual;
    data['currentEv_freeCashFlowTTM'] = this.currentEvFreeCashFlowTTM;
    data['currentPrice'] = this.currentPrice;
    data['currentRatioAnnual'] = this.currentRatioAnnual;
    data['currentRatioQuarterly'] = this.currentRatioQuarterly;
    data['dividendPerShareAnnual'] = this.dividendPerShareAnnual;
    data['dividendPerShareTTM'] = this.dividendPerShareTTM;
    data['dividendYieldIndicatedAnnual'] = this.dividendYieldIndicatedAnnual;
    data['doubtful_revenue_percent'] = this.doubtfulRevenuePercent;
    data['ebit_annual'] = this.ebitAnnual;
    data['ebit_estimate_annual'] = this.ebitEstimateAnnual;
    data['ebitdPerShareAnnual'] = this.ebitdPerShareAnnual;
    data['ebitdPerShareTTM'] = this.ebitdPerShareTTM;
    data['ebitda_estimate_annual'] = this.ebitdaEstimateAnnual;
    data['ebitda_estimate_quarterly'] = this.ebitdaEstimateQuarterly;
    data['employeeTotal'] = this.employeeTotal;
    data['enterpriseValue'] = this.enterpriseValue;
    data['epsAnnual'] = this.epsAnnual;
    data['epsBasicExclExtraItemsTTM'] = this.epsBasicExclExtraItemsTTM;
    data['epsGrowth3Y'] = this.epsGrowth3Y;
    data['epsGrowth5Y'] = this.epsGrowth5Y;
    data['epsGrowthQuarterlyYoy'] = this.epsGrowthQuarterlyYoy;
    data['epsGrowthTTMYoy'] = this.epsGrowthTTMYoy;
    data['epsNormalizedAnnual'] = this.epsNormalizedAnnual;
    data['epsTTM'] = this.epsTTM;
    data['eps_estimate_annual'] = this.epsEstimateAnnual;
    data['eps_estimate_quarterly'] = this.epsEstimateQuarterly;
    data['eps_growth_1y'] = this.epsGrowth1y;
    data['equity_to_assets_annual'] = this.equityToAssetsAnnual;
    data['ev_ebit'] = this.evEbit;
    data['ev_fcf'] = this.evFcf;
    data['ev_revenue'] = this.evRevenue;
    data['exchange'] = this.exchange;
    data['exchange_country'] = this.exchangeCountry;
    data['exchange_symbol'] = this.exchangeSymbol;
    data['grossIncome_annual'] = this.grossIncomeAnnual;
    data['grossMarginAnnual'] = this.grossMarginAnnual;
    data['grossMarginTTM'] = this.grossMarginTTM;
    data['gross_margin_annual'] = this.grossMarginAnnual;
    data['halal_revenue_percent'] = this.halalRevenuePercent;
    data['high'] = this.high;
    data['id'] = this.id;
    data['industry'] = this.industry;
    data['interestBearingAssetsRatio'] = this.interestBearingAssetsRatio;
    data['interestBearingDebtRatio'] = this.interestBearingDebtRatio;
    data['interestbearing_debt_percent'] = this.interestbearingDebtPercent;
    data['intrestbearing_asset_percent'] = this.intrestbearingAssetPercent;
    data['inventoryTurnoverAnnual'] = this.inventoryTurnoverAnnual;
    data['ipoDate'] = this.ipoDate;
    data['isMainTicker'] = this.isMainTicker;
    data['isin'] = this.isin;
    data['longTermDebt_equityAnnual'] = this.longTermDebtEquityAnnual;
    data['longTermDebt_equityQuarterly'] = this.longTermDebtEquityQuarterly;
    data['low'] = this.low;
    data['marketCapClassification'] = this.marketCapClassification;
    data['marketCap_change_3y'] = this.marketCapChange3y;
    data['marketcap'] = this.marketcap;
    data['musaffaIndustry'] = this.musaffaIndustry;
    data['musaffaSector'] = this.musaffaSector;
    data['musaffa_esg_ranking'] = this.musaffaEsgRanking;
    data['musaffa_esg_score'] = this.musaffaEsgScore;
    data['netInterestCoverageAnnual'] = this.netInterestCoverageAnnual;
    data['netInterestCoverageTTM'] = this.netInterestCoverageTTM;
    data['netProfitMarginAnnual'] = this.netProfitMarginAnnual;
    data['netProfitMarginTTM'] = this.netProfitMarginTTM;
    data['net_income_annual'] = this.netIncomeAnnual;
    data['nothalal_revenue_percent'] = this.nothalalRevenuePercent;
    data['open'] = this.open;
    data['operatingMarginAnnual'] = this.operatingMarginAnnual;
    data['operatingMarginTTM'] = this.operatingMarginTTM;
    data['payoutRatioTTM'] = this.payoutRatioTTM;
    data['pbAnnual'] = this.pbAnnual;
    data['pbQuarterly'] = this.pbQuarterly;
    data['pc'] = this.pc;
    data['pcfShareTTM'] = this.pcfShareTTM;
    data['peAnnual'] = this.peAnnual;
    data['peBasicExclExtraTTM'] = this.peBasicExclExtraTTM;
    data['peExclExtraAnnual'] = this.peExclExtraAnnual;
    data['peExclExtraTTM'] = this.peExclExtraTTM;
    data['peInclExtraTTM'] = this.peInclExtraTTM;
    data['peNormalizedAnnual'] = this.peNormalizedAnnual;
    data['peTTM'] = this.peTTM;
    data['pfcfShareAnnual'] = this.pfcfShareAnnual;
    data['pfcfShareTTM'] = this.pfcfShareTTM;
    data['pretaxMarginAnnual'] = this.pretaxMarginAnnual;
    data['previous_close'] = this.previousClose;
    data['priceChange1D'] = this.priceChange1D;
    data['priceChange1DPercent'] = this.priceChange1DPercent;
    data['priceChange1M'] = this.priceChange1M;
    data['priceChange1MPercent'] = this.priceChange1MPercent;
    data['priceChange1W'] = this.priceChange1W;
    data['priceChange1WPercent'] = this.priceChange1WPercent;
    data['priceChange1Y'] = this.priceChange1Y;
    data['priceChange1YPercent'] = this.priceChange1YPercent;
    data['priceChange3M'] = this.priceChange3M;
    data['priceChange3MPercent'] = this.priceChange3MPercent;
    data['priceChange3Y'] = this.priceChange3Y;
    data['priceChange3YPercent'] = this.priceChange3YPercent;
    data['priceChange5Y'] = this.priceChange5Y;
    data['priceChange5YPercent'] = this.priceChange5YPercent;
    data['priceChange6M'] = this.priceChange6M;
    data['priceChange6MPercent'] = this.priceChange6MPercent;
    data['priceChangeYTD'] = this.priceChangeYTD;
    data['priceChangeYTDPercent'] = this.priceChangeYTDPercent;
    data['priceLastUpdated'] = this.priceLastUpdated;
    data['price_tangiblebook_value_annual'] = this.priceTangiblebookValueAnnual;
    data['price_tangiblebook_value_quarterly'] =
        this.priceTangiblebookValueQuarterly;
    data['price_to_tangible_book_ratio_annual'] =
        this.priceToTangibleBookRatioAnnual;
    data['price_to_tangible_book_ratio_quarterly'] =
        this.priceToTangibleBookRatioQuarterly;
    data['psAnnual'] = this.psAnnual;
    data['psTTM'] = this.psTTM;
    data['ptbvAnnual'] = this.ptbvAnnual;
    data['ptbvQuarterly'] = this.ptbvQuarterly;
    data['quickRatioAnnual'] = this.quickRatioAnnual;
    data['quickRatioQuarterly'] = this.quickRatioQuarterly;
    data['receivablesTurnoverTTM'] = this.receivablesTurnoverTTM;
    data['recommendationWeightedAverage'] = this.recommendationWeightedAverage;
    data['revenueGrowth1Y'] = this.revenueGrowth1Y;
    data['revenueGrowth3Y'] = this.revenueGrowth3Y;
    data['revenueGrowth5Y'] = this.revenueGrowth5Y;
    data['revenueGrowthQuarterlyYoy'] = this.revenueGrowthQuarterlyYoy;
    data['revenueGrowthTTMYoy'] = this.revenueGrowthTTMYoy;
    data['revenuePerShareAnnual'] = this.revenuePerShareAnnual;
    data['revenuePerShareTTM'] = this.revenuePerShareTTM;
    data['revenueShareGrowth5Y'] = this.revenueShareGrowth5Y;
    data['revenue_annual'] = this.revenueAnnual;
    data['revenue_estimate_quarterly'] = this.revenueEstimateQuarterly;
    data['roa5Y'] = this.roa5Y;
    data['roaRfy'] = this.roaRfy;
    data['roaTTM'] = this.roaTTM;
    data['roe5Y'] = this.roe5Y;
    data['roiAnnual'] = this.roiAnnual;
    data['rotc_annual'] = this.rotcAnnual;
    data['salesPerShare_annual'] = this.salesPerShareAnnual;
    data['sector'] = this.sector;
    data['sharesOutStanding'] = this.sharesOutStanding;
    data['sharia_compliance'] = this.shariaCompliance?.name;
    data['status'] = this.status;
    data['tangibleBookValuePerShareAnnual'] =
        this.tangibleBookValuePerShareAnnual;
    data['tangibleBookValuePerShareQuarterly'] =
        this.tangibleBookValuePerShareQuarterly;
    data['ticker'] = this.ticker;
    data['totalDebt_totalEquityAnnual'] = this.totalDebtTotalEquityAnnual;
    data['totalDebt_totalEquityQuarterly'] = this.totalDebtTotalEquityQuarterly;
    data['updated_at'] = this.updatedAt;
    data['usdMarketCap'] = this.usdMarketCap;
    data['volume'] = this.volume;
    data['ranking_v2'] = this.rankingV2;
    return data;
  }
}
