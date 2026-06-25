class ComplianceHistoryItem {
  const ComplianceHistoryItem({
    required this.id,
    required this.companyName,
    required this.ticker,
    required this.mainTicker,
    this.isin,
    required this.complianceStatus,
    required this.reportDate,
    required this.reportedQuarter,
    required this.reportedYear,
    required this.reportPeriod,
    required this.startDate,
    required this.endDate,
    required this.doubtfulAmount,
    required this.notHalalAmount,
    required this.shareOutstanding,
    required this.createDateTime,
    required this.currency,
    this.subtickerCurrency,
    required this.isIpo,
  });

  final String id;
  final String companyName;
  final String ticker;
  final String mainTicker;
  final String? isin;
  final String complianceStatus;
  final String reportDate;
  final String reportedQuarter;
  final String reportedYear;
  final int reportPeriod;
  final String startDate;
  final String endDate;
  final num doubtfulAmount;
  final num notHalalAmount;
  final num shareOutstanding;
  final String createDateTime;
  final String currency;
  final String? subtickerCurrency;
  final String isIpo;

  factory ComplianceHistoryItem.fromJson(Map<String, dynamic> json) {
    return ComplianceHistoryItem(
      id: _asString(json['id']),
      companyName: _asString(json['company_name']),
      ticker: _asString(json['ticker']),
      mainTicker: _asString(json['main_ticker']),
      isin: _asOptionalString(json['isin']),
      complianceStatus: _asString(json['compliance_status']),
      reportDate: _asString(json['report_date']),
      reportedQuarter: _asString(json['reported_quarter']),
      reportedYear: _asString(json['reported_year']),
      reportPeriod: _asInt(json['report_period']),
      startDate: _asString(json['start_date']),
      endDate: _asString(json['end_date']),
      doubtfulAmount: _asNum(json['doubtful_amount']),
      notHalalAmount: _asNum(json['not_halal_amount']),
      shareOutstanding: _asNum(json['share_outstanding']),
      createDateTime: _asString(json['create_date_time']),
      currency: _asString(json['currency'], fallback: 'USD'),
      subtickerCurrency: _asOptionalString(json['subticker_currency']),
      isIpo: _asString(json['is_ipo']),
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  static String? _asOptionalString(dynamic value) {
    final String text = _asString(value);
    return text.isEmpty ? null : text;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}
