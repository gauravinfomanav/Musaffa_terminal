class ComplianceLineItem {
  const ComplianceLineItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.amountInOnes,
    required this.percentage,
    required this.selector,
    this.comment,
    this.items = const <ComplianceLineItem>[],
  });

  final String id;
  final String name;
  final num amount;
  final num amountInOnes;
  final num percentage;
  final String selector;
  final String? comment;
  final List<ComplianceLineItem> items;

  factory ComplianceLineItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> nested = json['items'] as List<dynamic>? ?? [];
    return ComplianceLineItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: _num(json['amount']),
      amountInOnes: _num(json['amountInOnes']),
      percentage: _num(json['percentage']),
      selector: json['selector']?.toString() ?? '',
      comment: _extractComment(json['comment']),
      items: nested
          .whereType<Map<String, dynamic>>()
          .map(ComplianceLineItem.fromJson)
          .toList(),
    );
  }
}

num _num(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _extractComment(dynamic raw) {
  if (raw == null) return null;
  if (raw is String && raw.trim().isNotEmpty) return raw;
  if (raw is List && raw.isNotEmpty) {
    final first = raw.first;
    if (first is Map && first['body'] != null) {
      return first['body'].toString();
    }
  }
  return null;
}

class ComplianceDebtTerm {
  const ComplianceDebtTerm({
    required this.name,
    required this.amount,
    required this.amountInOnes,
    required this.ratio,
    required this.items,
  });

  final String name;
  final num amount;
  final num amountInOnes;
  final num ratio;
  final List<ComplianceLineItem> items;
}

class ComplianceReport {
  const ComplianceReport({
    required this.raw,
    required this.ticker,
    required this.companyName,
    required this.status,
    required this.exchange,
    required this.country,
    required this.currency,
    required this.units,
    required this.reportDate,
    required this.reportTypeSection,
    required this.reportSource,
    required this.lastUpdate,
    required this.ranking,
    required this.rankingV2,
    required this.trailing36MonAvgCap,
    required this.totalRevenue,
    required this.halalPercent,
    required this.notHalalPercent,
    required this.questionablePercent,
    required this.halalRevenue,
    required this.notHalalRevenue,
    required this.questionableRevenue,
    required this.debtRatio,
    required this.debtStatus,
    required this.revenueBreakdownStatus,
    required this.securitiesStatus,
    required this.cbaStatus,
    required this.securitiesRatio,
    required this.securitiesTotalAmount,
    required this.debtTotalAmount,
    required this.revenueItems,
    required this.interestIncomeItems,
    required this.debtShortTerm,
    required this.debtLongTerm,
    required this.securitiesShortTerm,
    required this.securitiesLongTerm,
    required this.msciStatus,
    required this.msciSecuritiesRatio,
    required this.msciSecuritiesStatus,
    required this.msciDebtRatio,
    required this.msciDebtStatus,
    required this.msciArCashRatio,
    required this.msciArCashStatus,
    required this.msciHalalPercent,
    required this.msciNotHalalPercent,
    required this.msciDoubtfulPercent,
    required this.msciTotalAssets,
    required this.shareOutstanding,
    required this.marketCapitalization,
    required this.isIpo,
  });

  final Map<String, dynamic> raw;
  final String ticker;
  final String companyName;
  final String status;
  final String exchange;
  final String country;
  final String currency;
  final num units;
  final String reportDate;
  final String reportTypeSection;
  final String reportSource;
  final String lastUpdate;
  final num ranking;
  final num rankingV2;
  final num trailing36MonAvgCap;
  final num totalRevenue;
  final num halalPercent;
  final num notHalalPercent;
  final num questionablePercent;
  final num halalRevenue;
  final num notHalalRevenue;
  final num questionableRevenue;
  final num debtRatio;
  final String debtStatus;
  final String revenueBreakdownStatus;
  final String securitiesStatus;
  final String cbaStatus;
  final num securitiesRatio;
  final num securitiesTotalAmount;
  final num debtTotalAmount;
  final List<ComplianceLineItem> revenueItems;
  final List<ComplianceLineItem> interestIncomeItems;
  final ComplianceDebtTerm? debtShortTerm;
  final ComplianceDebtTerm? debtLongTerm;
  final ComplianceDebtTerm? securitiesShortTerm;
  final ComplianceDebtTerm? securitiesLongTerm;
  final String msciStatus;
  final num msciSecuritiesRatio;
  final String msciSecuritiesStatus;
  final num msciDebtRatio;
  final String msciDebtStatus;
  final num msciArCashRatio;
  final String msciArCashStatus;
  final num msciHalalPercent;
  final num msciNotHalalPercent;
  final num msciDoubtfulPercent;
  final num msciTotalAssets;
  final num shareOutstanding;
  final num marketCapitalization;
  final String isIpo;

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? msci = _map(json['msci_report']);

    return ComplianceReport(
      raw: json,
      ticker: json['id']?.toString() ?? json['stockName']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      exchange: json['exchange']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      units: _num(json['units'], fallback: 1000000),
      reportDate: json['reportDate']?.toString() ?? '',
      reportTypeSection: json['reportTypeSection']?.toString() ?? '',
      reportSource: json['reportSource']?.toString() ?? '',
      lastUpdate: json['lastUpdate']?.toString() ?? '',
      ranking: _num(json['ranking']),
      rankingV2: _num(json['ranking_v2']),
      trailing36MonAvgCap: _num(json['trailing36MonAvrCap']),
      totalRevenue: _num(json['totalRevenue']),
      halalPercent: _num(json['halal']),
      notHalalPercent: _num(json['notHalal']),
      questionablePercent: _num(json['questionable']),
      halalRevenue: _num(json['halalRevenue']),
      notHalalRevenue: _num(json['notHalalRevenue']),
      questionableRevenue: _num(json['questionableRevenue']),
      debtRatio: _num(json['debt']),
      debtStatus: json['debtStatus']?.toString() ?? '',
      revenueBreakdownStatus: json['revenueBreakdownStatus']?.toString() ?? '',
      securitiesStatus: json['securitiesAndAssetsStatus']?.toString() ?? '',
      cbaStatus: json['cbaStatus']?.toString() ?? '',
      securitiesRatio: _num(json['securitiesAndAssetsJson.totalRetio']),
      securitiesTotalAmount: _num(json['securitiesAndAssetsJson.totalAmount']),
      debtTotalAmount: _num(json['interestBearingDebtJson.totalAmount']),
      revenueItems: _items(json['revenueBreakdownJson.items']),
      interestIncomeItems: _items(json['interestIncomeJson.items']),
      debtShortTerm: _debtTerm(json, 'interestBearingDebtJson.shortTermJson'),
      debtLongTerm: _debtTerm(json, 'interestBearingDebtJson.longTermJson'),
      securitiesShortTerm:
          _debtTerm(json, 'securitiesAndAssetsJson.shortTermJson'),
      securitiesLongTerm:
          _debtTerm(json, 'securitiesAndAssetsJson.longTermJson'),
      msciStatus: _msciStatus(msci),
      msciSecuritiesRatio: _msciRatio(msci, 'interestBearingSecuritiesAndAssets'),
      msciSecuritiesStatus:
          _msciPassFail(msci, 'interestBearingSecuritiesAndAssets'),
      msciDebtRatio: _msciRatio(msci, 'interestBearingDebt'),
      msciDebtStatus: _msciPassFail(msci, 'interestBearingDebt'),
      msciArCashRatio: _msciRatio(msci, 'accountsReceivableAndCash'),
      msciArCashStatus: _msciPassFail(msci, 'accountsReceivableAndCash'),
      msciHalalPercent: _num(msci?['revenueBreakdown']?['halalPercentage']),
      msciNotHalalPercent: _num(msci?['revenueBreakdown']?['notHalalPercentage']),
      msciDoubtfulPercent:
          _num(msci?['revenueBreakdown']?['questionablePercentage']),
      msciTotalAssets: _num(json['totalAssets']),
      shareOutstanding: _num(json['shareOutstanding']),
      marketCapitalization: _num(json['marketCapitalization']),
      isIpo: json['is_ipo']?.toString() ?? '',
    );
  }

  num get businessActivityFailPercent => notHalalPercent + questionablePercent;

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<ComplianceLineItem> _items(dynamic value) {
    if (value is! List) return const <ComplianceLineItem>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ComplianceLineItem.fromJson)
        .toList();
  }

  static ComplianceDebtTerm? _debtTerm(
    Map<String, dynamic> json,
    String prefix,
  ) {
    final String name = json['$prefix.name']?.toString() ?? '';
    final num amount = _num(json['$prefix.amount']);
    if (name.isEmpty && amount == 0) return null;

    return ComplianceDebtTerm(
      name: name,
      amount: amount,
      amountInOnes: _num(json['$prefix.amountInOnes']),
      ratio: _num(json['$prefix.retio']),
      items: _items(json['$prefix.items']),
    );
  }

  static String _msciStatus(Map<String, dynamic>? msci) {
    if (msci == null) return '';
    return (msci['msci_status'] ??
            msci['shariahComplianceStatus'] ??
            msci['status'])
        ?.toString() ??
        '';
  }

  static num _msciRatio(Map<String, dynamic>? msci, String key) {
    final dynamic block = msci?[key];
    if (block is Map) {
      return _num(block['ratio']);
    }
    return 0;
  }

  static String _msciPassFail(Map<String, dynamic>? msci, String key) {
    final dynamic block = msci?[key];
    if (block is Map) {
      return block['status']?.toString() ?? '';
    }
    return '';
  }
}
