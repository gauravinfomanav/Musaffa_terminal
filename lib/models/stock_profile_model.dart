class StockProfileModel {
  StockProfileModel({
    this.address,
    this.city,
    this.country,
    this.currency,
    this.cusip,
    this.sedol,
    this.description,
    this.employeeTotal,
    this.exchange,
    this.ipo,
    this.isin,
    this.marketCapitalization,
    this.naics,
    this.naicsNationalIndustry,
    this.naicsSector,
    this.naicsSubsector,
    this.name,
    this.phone,
    this.shareOutstanding,
    this.state,
    this.ticker,
    this.weburl,
    this.logo,
    this.finnhubIndustry,
  });

  final String? address;
  final String? city;
  final String? country;
  final String? currency;
  final String? cusip;
  final String? sedol;
  final String? description;
  final num? employeeTotal;
  final String? exchange;
  final String? ipo;
  final String? isin;
  final num? marketCapitalization;
  final String? naics;
  final String? naicsNationalIndustry;
  final String? naicsSector;
  final String? naicsSubsector;
  final String? name;
  final String? phone;
  final num? shareOutstanding;
  final String? state;
  final String? ticker;
  final String? weburl;
  final String? logo;
  final String? finnhubIndustry;

  bool get hasContent =>
      (description?.trim().isNotEmpty ?? false) ||
      (name?.trim().isNotEmpty ?? false) ||
      (weburl?.trim().isNotEmpty ?? false);

  factory StockProfileModel.fromJson(Map<String, dynamic> json) {
    return StockProfileModel(
      address: _string(json['address']),
      city: _string(json['city']),
      country: _string(json['country']),
      currency: _string(json['currency']),
      cusip: _string(json['cusip']),
      sedol: _string(json['sedol']),
      description: _string(json['description']),
      employeeTotal: _num(json['employeeTotal']),
      exchange: _string(json['exchange']),
      ipo: _string(json['ipo']),
      isin: _string(json['isin']),
      marketCapitalization: _num(json['marketCapitalization']),
      naics: _string(json['naics']),
      naicsNationalIndustry: _string(json['naicsNationalIndustry']),
      naicsSector: _string(json['naicsSector']),
      naicsSubsector: _string(json['naicsSubsector']),
      name: _string(json['name']),
      phone: _string(json['phone']),
      shareOutstanding: _num(json['shareOutstanding']),
      state: _string(json['state']),
      ticker: _string(json['ticker']),
      weburl: _string(json['weburl']),
      logo: _string(json['logo']),
      finnhubIndustry: _string(json['finnhubIndustry']),
    );
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static num? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    final parsed = num.tryParse(value.toString().trim());
    return parsed;
  }
}
