class InstitutionalInvestorProfile {
  const InstitutionalInvestorProfile({
    required this.cik,
    required this.manager,
    this.profile,
    this.philosophy,
    this.profileImg,
    this.firmType,
  });

  final String cik;
  final String manager;
  final String? profile;
  final String? philosophy;
  final String? profileImg;
  final String? firmType;

  factory InstitutionalInvestorProfile.fromJson(Map<String, dynamic> json) {
    return InstitutionalInvestorProfile(
      cik: (json['cik'] ?? '').toString().trim(),
      manager: (json['manager'] ?? json['name'] ?? '').toString().trim(),
      profile: _optional(json['profile']),
      philosophy: _optional(json['philosophy']),
      profileImg: _optional(json['profileImg']),
      firmType: _optional(json['firmType']),
    );
  }
}

class InstitutionalHolding {
  const InstitutionalHolding({
    required this.symbol,
    required this.name,
    required this.share,
    required this.change,
    required this.percentage,
    required this.value,
  });

  final String symbol;
  final String name;
  final num share;
  final num change;
  final double percentage;
  final num value;

  factory InstitutionalHolding.fromJson(Map<String, dynamic> json) {
    return InstitutionalHolding(
      symbol: (json['symbol'] ?? '').toString().trim().toUpperCase(),
      name: (json['name'] ?? json['symbol'] ?? '').toString().trim(),
      share: _num(json['share']),
      change: _num(json['change']),
      percentage: _double(json['percentage']),
      value: _num(json['value']),
    );
  }
}

class InstitutionalPortfolioSnapshot {
  const InstitutionalPortfolioSnapshot({
    required this.reportDate,
    required this.filingDate,
    required this.holdings,
  });

  final DateTime? reportDate;
  final DateTime? filingDate;
  final List<InstitutionalHolding> holdings;
}

String? _optional(dynamic value) {
  final String raw = (value ?? '').toString().trim();
  return raw.isEmpty ? null : raw;
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
