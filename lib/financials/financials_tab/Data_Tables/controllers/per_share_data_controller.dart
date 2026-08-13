import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';

class FinancialFundamentalsController extends GetxController {
  var financialData = Rxn<FinancialFundamentals>();
  var isLoading = true.obs;

  Future<void> fetchFinancialFundamentals(String symbol) async {
    try {
      isLoading.value = true;

      final decoded =
          await WebService.fetchCompanyBasicFinancialsCached(symbol);
      if (decoded == null) {
        financialData.value = null;
        return;
      }

      financialData.value = FinancialFundamentals.fromBasicFinancials(decoded);
    } catch (_) {
      financialData.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}

class FinancialFundamentals {
  final Map<String, double?>? revenuePerShareTTM;
  final Map<String, double?>? ebitPerShareTTM;
  final Map<String, double?>? epsTTM;
  final Map<String, double?>? dividendPerShareTTM;
  final String? companySymbol;
  Map<String, double>? epsData;

  FinancialFundamentals({
    this.revenuePerShareTTM,
    this.ebitPerShareTTM,
    this.epsTTM,
    this.dividendPerShareTTM,
    this.companySymbol,
    this.epsData,
  });

  factory FinancialFundamentals.fromBasicFinancials(
    Map<String, dynamic> json,
  ) {
    final annual = (json['series'] is Map)
        ? (json['series'] as Map)['annual']
        : null;
    final annualMap =
        annual is Map ? Map<String, dynamic>.from(annual) : <String, dynamic>{};
    final metric =
        json['metric'] is Map ? Map<String, dynamic>.from(json['metric']) : {};

    const maxYears = 10;

    final sales = WebService.seriesToYearMap(
      annualMap['salesPerShare'],
      maxYears: maxYears,
    );
    final ebit = WebService.seriesToYearMap(
      annualMap['ebitPerShare'],
      maxYears: maxYears,
    );
    final eps = WebService.seriesToYearMap(
      annualMap['eps'],
      maxYears: maxYears,
    );

    // No dividend series from API — attach annual indicated DPS to latest year.
    Map<String, double?>? dividend;
    final dps = metric['dividendPerShareAnnual'];
    if (dps is num && eps.isNotEmpty) {
      final years = eps.keys.toList()..sort();
      dividend = {years.last: dps.toDouble()};
    }

    final epsData = <String, double>{};
    eps.forEach((year, value) {
      if (value != null) epsData[year] = value;
    });

    return FinancialFundamentals(
      revenuePerShareTTM: sales.isEmpty ? null : sales,
      ebitPerShareTTM: ebit.isEmpty ? null : ebit,
      epsTTM: eps.isEmpty ? null : eps,
      dividendPerShareTTM: dividend,
      companySymbol: json['symbol']?.toString(),
      epsData: epsData.isEmpty ? null : epsData,
    );
  }
}
