class EtfComplianceReport {
  const EtfComplianceReport({
    required this.symbol,
    required this.name,
    required this.complianceStatus,
    required this.actualComplianceStatus,
    required this.cbaStatus,
    required this.revenueBreakdownStatus,
    required this.securitiesAndAssetsStatus,
    required this.debtStatus,
    required this.totalHalalRatio,
    required this.totalDoubtfulRatio,
    required this.totalNotHalalRatio,
    required this.totalHalalRevenue,
    required this.totalDoubtfulRevenue,
    required this.totalNotHalalRevenue,
    required this.etfTotalRevenue,
    required this.impermissibleRatio,
    required this.impermissibleAmount,
    required this.totalIbSecAssetRatio,
    required this.totalIbSecAssetRevenue,
    required this.totalDebtRatio,
    required this.totalIbDebtRevenue,
    required this.marketValue,
    required this.aum,
    required this.assetClass,
    required this.investmentSegment,
    required this.etfType,
    required this.numberOfHoldings,
    required this.isin,
    required this.currency,
    required this.navCurrency,
    required this.market,
    required this.shariahReason,
    required this.isLeveraged,
    required this.isInverse,
    required this.lastUpdate,
  });

  final String symbol;
  final String name;
  final String complianceStatus;
  final String actualComplianceStatus;
  final String cbaStatus;
  final String revenueBreakdownStatus;
  final String securitiesAndAssetsStatus;
  final String debtStatus;
  final num totalHalalRatio;
  final num totalDoubtfulRatio;
  final num totalNotHalalRatio;
  final num totalHalalRevenue;
  final num totalDoubtfulRevenue;
  final num totalNotHalalRevenue;
  final num etfTotalRevenue;
  final num impermissibleRatio;
  final num impermissibleAmount;
  final num totalIbSecAssetRatio;
  final num totalIbSecAssetRevenue;
  final num totalDebtRatio;
  final num totalIbDebtRevenue;
  final num marketValue;
  final num aum;
  final String assetClass;
  final String investmentSegment;
  final String etfType;
  final num numberOfHoldings;
  final String isin;
  final String currency;
  final String navCurrency;
  final String market;
  final String shariahReason;
  final String isLeveraged;
  final String isInverse;
  final num lastUpdate;

  factory EtfComplianceReport.fromJson(Map<String, dynamic> json) {
    return EtfComplianceReport(
      symbol: json['symbol']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      complianceStatus: json['complianceStatus']?.toString() ?? '',
      actualComplianceStatus: json['actualComplianceStatus']?.toString() ?? '',
      cbaStatus: json['cbaStatus']?.toString() ?? '',
      revenueBreakdownStatus: json['revenueBreakdownStatus']?.toString() ?? '',
      securitiesAndAssetsStatus:
          json['securitiesAndAssetsStatus']?.toString() ?? '',
      debtStatus: json['debtStatus']?.toString() ?? '',
      totalHalalRatio: _num(json['totalHalalRatio']),
      totalDoubtfulRatio: _num(json['totalDoubtfulRatio']),
      totalNotHalalRatio: _num(json['totalNotHalalRatio']),
      totalHalalRevenue: _num(json['totalHalalRevenue']),
      totalDoubtfulRevenue: _num(json['totalDoubtfulRevenue']),
      totalNotHalalRevenue: _num(json['totalNotHalalRevenue']),
      etfTotalRevenue: _num(json['etfTotalRevenue']),
      impermissibleRatio: _num(json['impermissibleRatio']),
      impermissibleAmount: _num(json['impermissibleAmount']),
      totalIbSecAssetRatio: _num(json['totalIbSecAssetRatio']),
      totalIbSecAssetRevenue: _num(json['totalIbSecAssetRevenue']),
      totalDebtRatio: _num(json['totalDebtRatio']),
      totalIbDebtRevenue: _num(json['totalIbDebtRevenue']),
      marketValue: _num(json['marketValue']),
      aum: _num(json['aum']),
      assetClass: json['assetClass']?.toString() ?? '',
      investmentSegment: json['investmentSegment']?.toString() ?? '',
      etfType: json['etf_type']?.toString() ?? '',
      numberOfHoldings: _num(json['numberOfHoldings']),
      isin: json['isin']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      navCurrency: json['navCurrency']?.toString() ?? '',
      market: json['market']?.toString() ?? '',
      shariahReason: json['shariah_reason']?.toString() ?? '',
      isLeveraged: json['is_leveraged']?.toString() ?? '0',
      isInverse: json['is_inverse']?.toString() ?? '0',
      lastUpdate: _num(json['lastUpdate']),
    );
  }

  static num _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }
}
