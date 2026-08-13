import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';

class FinancialRatio {
  final String name;
  final String period;
  final double value;

  FinancialRatio({
    required this.name,
    required this.period,
    required this.value,
  });
}

class YearlyRatios {
  final String year;
  Map<String, double> ratios = {};

  YearlyRatios(this.year);

  void addRatio(String name, double value) {
    ratios[name] = value;
  }

  double? getRatio(String name) {
    return ratios[name];
  }
}

class RatiosController extends GetxController {
  var isLoading = true.obs;
  var yearlyRatiosMap = <String, YearlyRatios>{}.obs;
  var years = <String>[].obs;

  /// RisePython annual series key → UI metric key used by TerminalRatiosScreen.
  static const Map<String, String> _annualSeriesToUiKey = {
    'netMargin': 'netMargin',
    'quickRatio': 'quickRatio',
    'currentRatio': 'currentRatio',
    'pe': 'peTTM',
    'ps': 'psTTM',
    'pb': 'pb',
    'fcfMargin': 'fcfMargin',
    'payoutRatio': 'payoutRatioTTM',
    'grossMargin': 'grossMargin',
    'roe': 'roeTTM',
    'roa': 'roa',
    'roic': 'roic',
    'inventoryTurnover': 'inventoryTurnoverTTM',
    'receivablesTurnover': 'receivablesTurnoverTTM',
    'longtermDebtTotalEquity': 'longtermDebtTotalEquity',
    'totalDebtToTotalAsset': 'totalDebtToTotalAsset',
    'longtermDebtTotalAsset': 'longtermDebtTotalAsset',
    'totalDebtToTotalCapital': 'totalDebtToTotalCapital',
    'operatingMargin': 'operatingMargin',
  };

  Future<void> fetchRatio(String symbol) async {
    try {
      isLoading.value = true;

      final decoded =
          await WebService.fetchCompanyBasicFinancialsCached(symbol);
      if (decoded == null) {
        yearlyRatiosMap.clear();
        years.clear();
        return;
      }

      final annual = (decoded['series'] is Map)
          ? (decoded['series'] as Map)['annual']
          : null;
      if (annual is! Map) {
        yearlyRatiosMap.clear();
        years.clear();
        return;
      }

      final allRatios = <FinancialRatio>[];
      for (final entry in _annualSeriesToUiKey.entries) {
        final series = annual[entry.key];
        if (series is! List) continue;
        for (final point in series) {
          if (point is! Map) continue;
          final period = point['period']?.toString() ?? '';
          final v = point['v'];
          if (period.length < 4 || v is! num) continue;
          allRatios.add(FinancialRatio(
            name: entry.value,
            period: period,
            value: v.toDouble(),
          ));
          // UI also lists roaTTM; annual API only has `roa`.
          if (entry.key == 'roa') {
            allRatios.add(FinancialRatio(
              name: 'roaTTM',
              period: period,
              value: v.toDouble(),
            ));
          }
        }
      }

      processRatiosByYear(allRatios);
    } catch (e, stackTrace) {
      debugPrint('Error fetching ratio data: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  void processRatiosByYear(List<FinancialRatio> allRatios) {
    yearlyRatiosMap.clear();
    years.clear();

    final yearSet = <String>{};
    for (final ratio in allRatios) {
      if (ratio.period.length >= 4) {
        yearSet.add(ratio.period.substring(0, 4));
      }
    }

    // Latest 5 fiscal years with data (dynamic — no hard-coded 2020–2024).
    var sortedYears = yearSet.toList()..sort();
    if (sortedYears.length > 5) {
      sortedYears = sortedYears.sublist(sortedYears.length - 5);
    }

    for (final year in sortedYears) {
      yearlyRatiosMap[year] = YearlyRatios(year);
      years.add(year);
    }

    for (final ratio in allRatios) {
      final year = ratio.period.substring(0, 4);
      yearlyRatiosMap[year]?.addRatio(ratio.name, ratio.value);
    }
  }

  Map<String, double?> getRatioForYears(
    String ratioName,
    List<String> yearsList,
  ) {
    final result = <String, double?>{};
    for (final year in yearsList) {
      result[year] = yearlyRatiosMap[year]?.getRatio(ratioName);
    }
    return result;
  }

  Map<String, Map<String, double?>> getFinancialDataForYears() {
    final result = <String, Map<String, double?>>{};
    final ratioNames = <String>{};
    for (final yearData in yearlyRatiosMap.values) {
      ratioNames.addAll(yearData.ratios.keys);
    }
    for (final ratioName in ratioNames) {
      result[ratioName] = getRatioForYears(ratioName, years);
    }
    return result;
  }
}
