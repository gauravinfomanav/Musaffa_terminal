class FinancialFundamentalsModel {
  final double? bookValuePerShareAnnual;
  final double? bookValuePerShareQuarterly;
  final double? cashPerSharePerShareAnnual;
  final double? cashPerSharePerShareQuarterly;
  final String? companySymbol;
  final Map<String, double>? dividendPerShareTTM;
  final Map<String, double>? ebitPerShare;
  final Map<String, double>? epsTTM;
  final String? id;
  final Map<String, double>? priceToEarning;
  final Map<String, double>? revenuePerShare;
  final double? tangibleBookValuePerShareAnnual;
  final double? tangibleBookValuePerShareQuarterly;

  FinancialFundamentalsModel({
    this.bookValuePerShareAnnual,
    this.bookValuePerShareQuarterly,
    this.cashPerSharePerShareAnnual,
    this.cashPerSharePerShareQuarterly,
    this.companySymbol,
    this.dividendPerShareTTM,
    this.ebitPerShare,
    this.epsTTM,
    this.id,
    this.priceToEarning,
    this.revenuePerShare,
    this.tangibleBookValuePerShareAnnual,
    this.tangibleBookValuePerShareQuarterly,
  });

  factory FinancialFundamentalsModel.fromJson(Map<String, dynamic> json) {
    return FinancialFundamentalsModel(
      bookValuePerShareAnnual: json['bookValuePerShareAnnual']?.toDouble(),
      bookValuePerShareQuarterly: json['bookValuePerShareQuarterly']?.toDouble(),
      cashPerSharePerShareAnnual: json['cashPerSharePerShareAnnual']?.toDouble(),
      cashPerSharePerShareQuarterly: json['cashPerSharePerShareQuarterly']?.toDouble(),
      companySymbol: json['company_symbol'],
      dividendPerShareTTM: _parseMap(json['dividendPerShareTTM']),
      ebitPerShare: _parseMap(json['ebit_per_share']),
      epsTTM: _parseMap(json['epsTTM']),
      id: json['id'],
      priceToEarning: _parseMap(json['price_to_earning']),
      revenuePerShare: _parseMap(json['revenue_per_share']),
      tangibleBookValuePerShareAnnual: json['tangibleBookValuePerShareAnnual']?.toDouble(),
      tangibleBookValuePerShareQuarterly: json['tangibleBookValuePerShareQuarterly']?.toDouble(),
    );
  }

  static Map<String, double>? _parseMap(dynamic data) {
    if (data == null || data is! Map) return null;
    
    return Map.fromEntries(
      data.entries.map((e) => MapEntry(e.key.toString(), (e.value as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookValuePerShareAnnual': bookValuePerShareAnnual,
      'bookValuePerShareQuarterly': bookValuePerShareQuarterly,
      'cashPerSharePerShareAnnual': cashPerSharePerShareAnnual,
      'cashPerSharePerShareQuarterly': cashPerSharePerShareQuarterly,
      'company_symbol': companySymbol,
      'dividendPerShareTTM': dividendPerShareTTM,
      'ebit_per_share': ebitPerShare,
      'epsTTM': epsTTM,
      'id': id,
      'price_to_earning': priceToEarning,
      'revenue_per_share': revenuePerShare,
      'tangibleBookValuePerShareAnnual': tangibleBookValuePerShareAnnual,
      'tangibleBookValuePerShareQuarterly': tangibleBookValuePerShareQuarterly,
    };
  }

  // Get sorted data for charts
  List<MapEntry<String, double>> getSortedEpsData() {
    if (epsTTM == null) return [];
    return epsTTM!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<String, double>> getSortedRevenueData() {
    if (revenuePerShare == null) return [];
    return revenuePerShare!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<String, double>> getSortedPERatioData() {
    if (priceToEarning == null) return [];
    return priceToEarning!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<String, double>> getSortedDividendData() {
    if (dividendPerShareTTM == null) return [];
    return dividendPerShareTTM!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<String, double>> getSortedEbitData() {
    if (ebitPerShare == null) return [];
    return ebitPerShare!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Get latest values
  double? get latestEps => getSortedEpsData().isNotEmpty ? getSortedEpsData().last.value : null;
  double? get latestRevenue => getSortedRevenueData().isNotEmpty ? getSortedRevenueData().last.value : null;
  double? get latestPERatio => getSortedPERatioData().isNotEmpty ? getSortedPERatioData().last.value : null;
  double? get latestDividend => getSortedDividendData().isNotEmpty ? getSortedDividendData().last.value : null;
  double? get latestEbit => getSortedEbitData().isNotEmpty ? getSortedEbitData().last.value : null;

  // Get current year
  String get currentYear => getSortedEpsData().isNotEmpty ? getSortedEpsData().last.key : '--';

  // Calculate growth rates
  double? getEpsGrowthRate() {
    final data = getSortedEpsData();
    if (data.length < 2) return null;
    
    final current = data.last.value;
    final previous = data[data.length - 2].value;
    return ((current - previous) / previous) * 100;
  }

  double? getRevenueGrowthRate() {
    final data = getSortedRevenueData();
    if (data.length < 2) return null;
    
    final current = data.last.value;
    final previous = data[data.length - 2].value;
    return ((current - previous) / previous) * 100;
  }
}
