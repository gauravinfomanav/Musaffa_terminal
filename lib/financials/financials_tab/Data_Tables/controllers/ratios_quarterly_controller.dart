import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';

class quarterlyRatioDataModel {
  final String metric;
  final Map<String, double> values;

  quarterlyRatioDataModel({required this.metric, required this.values});
}

class QuarterlyRatiosController extends GetxController {
  var isLoading = true.obs;
  var quarterlyData = <Map<String, dynamic>>[].obs;
  final WebService webService = WebService();

  var processingComplete = false.obs;
  var tableData = <quarterlyRatioDataModel>[].obs;
  var quarters = <String>[].obs;
  var currency = 'USD'.obs;

  get nameMapping => null;

  /// RisePython quarterly series key → display label.
  static const Map<String, String> _quarterlyDisplayNames = {
    'netMargin': 'Net Margin',
    'quickRatio': 'Quick Ratio',
    'currentRatio': 'Current Ratio',
    'peTTM': 'Price to Earnings (TTM)',
    'psTTM': 'Price to Sales (TTM)',
    'pb': 'Price to Book',
    'fcfMargin': 'Free Cash Flow Margin',
    'payoutRatioTTM': 'Payout Ratio (TTM)',
    'grossMargin': 'Gross Margin',
    'operatingMargin': 'Operating Margin',
    'longtermDebtTotalEquity': 'Long-Term Debt to Equity (TTM)',
    'totalDebtToTotalAsset': 'Total Debt to Total Asset (TTM)',
    'longtermDebtTotalAsset': 'Long-Term Debt to Total Asset (TTM)',
    'totalDebtToTotalCapital': 'Total Debt to Total Capital',
    'inventoryTurnoverTTM': 'Inventory Turnover (TTM)',
    'receivablesTurnoverTTM': 'Receivables Turnover (TTM)',
    'assetTurnoverTTM': 'Asset Turnover (TTM)',
    'roeTTM': 'Return on Equity (TTM)',
    'roaTTM': 'Return on Assets (TTM)',
    'roicTTM': 'Return on Invested Capital (TTM)',
  };

  Future<void> fetchQuarterlyRatios(String symbol) async {
    try {
      isLoading.value = true;

      final decoded =
          await WebService.fetchCompanyBasicFinancialsCached(symbol);
      if (decoded == null) {
        quarterlyData.clear();
        tableData.clear();
        quarters.clear();
        processingComplete.value = false;
        return;
      }

      final quarterly = (decoded['series'] is Map)
          ? (decoded['series'] as Map)['quarterly']
          : null;
      if (quarterly is! Map) {
        quarterlyData.clear();
        tableData.clear();
        quarters.clear();
        processingComplete.value = false;
        return;
      }

      // Collect latest periods from first available series (API is newest-first).
      List sampleSeries = const [];
      for (final key in _quarterlyDisplayNames.keys) {
        final series = quarterly[key];
        if (series is List && series.isNotEmpty) {
          sampleSeries = series;
          break;
        }
      }

      final periods = <String>[];
      for (final point in sampleSeries) {
        if (point is! Map) continue;
        final period = point['period']?.toString() ?? '';
        if (period.isEmpty) continue;
        periods.add(period);
        if (periods.length >= 8) break;
      }

      final periodSet = periods.toSet();
      final formattedData = <Map<String, dynamic>>[];

      for (final entry in _quarterlyDisplayNames.entries) {
        final series = quarterly[entry.key];
        if (series is! List) continue;

        for (final point in series) {
          if (point is! Map) continue;
          final period = point['period']?.toString() ?? '';
          if (!periodSet.contains(period)) continue;
          final v = point['v'];
          if (v is! num) continue;

          formattedData.add({
            'Quarter': getQuarter(period),
            'Metric': entry.value,
            'Value': v.toDouble(),
            '_period': period,
          });
        }
      }

      formattedData.sort((a, b) {
        final pa = a['_period'] as String;
        final pb = b['_period'] as String;
        return pa.compareTo(pb);
      });

      quarterlyData.value = formattedData;
      processDataForTable();
    } catch (e) {
      print('Error fetching turnover ratios: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void processDataForTable() {
    quarters.value =
        quarterlyData.map((item) => item['Quarter'] as String).toSet().toList();

    quarters.sort((a, b) {
      final partsA = a.split(' ');
      final partsB = b.split(' ');
      if (partsA.length != 2 || partsB.length != 2) return a.compareTo(b);
      final quarterA = int.tryParse(partsA[0].substring(1)) ?? 0;
      final quarterB = int.tryParse(partsB[0].substring(1)) ?? 0;
      final yearA = int.tryParse(partsA[1]) ?? 0;
      final yearB = int.tryParse(partsB[1]) ?? 0;
      if (yearA != yearB) return yearA.compareTo(yearB);
      return quarterA.compareTo(quarterB);
    });

    final metrics =
        quarterlyData.map((item) => item['Metric'] as String).toSet();
    final result = <quarterlyRatioDataModel>[];

    for (final metric in metrics) {
      final values = <String, double>{};
      for (final quarter in quarters) {
        final item = quarterlyData.firstWhereOrNull(
          (element) =>
              element['Metric'] == metric && element['Quarter'] == quarter,
        );
        if (item != null) {
          final raw = item['Value'];
          values[quarter] =
              raw is double ? raw : double.parse(raw.toString());
        } else {
          values[quarter] = 0.0;
        }
      }
      result.add(quarterlyRatioDataModel(metric: metric, values: values));
    }

    tableData.value = result;
    processingComplete.value = true;
  }

  /// Map period date to fiscal quarter label (calendar month heuristic).
  String getQuarter(String period) {
    if (period.length < 7) return 'Unknown';
    final year = period.substring(0, 4);
    final month = int.tryParse(period.substring(5, 7)) ?? 0;
    if (month >= 10) return 'Q4 $year';
    if (month >= 7) return 'Q3 $year';
    if (month >= 4) return 'Q2 $year';
    if (month >= 1) return 'Q1 $year';
    return 'Unknown';
  }

  String formatQuarterForDisplay(String quarter) {
    final parts = quarter.split(' ');
    if (parts.length != 2) return quarter;
    final quarterPart = parts[0];
    final yearPart =
        parts[1].length >= 2 ? parts[1].substring(parts[1].length - 2) : parts[1];
    return "$quarterPart'$yearPart";
  }
}
