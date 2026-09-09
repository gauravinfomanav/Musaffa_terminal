import 'package:get/get.dart';
import 'package:musaffa_terminal/charts/api/infomanav_financials_api.dart';
import 'package:musaffa_terminal/charts/mappers/quarterly_financials_mapper.dart';
import 'package:musaffa_terminal/charts/models/financial_statement_type.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/models/quarterly_chart_view_model.dart';
import 'package:musaffa_terminal/charts/models/stock_quarterly_financials.dart';

class TickerQuarterlyChartsController extends GetxController {
  TickerQuarterlyChartsController({
    InfomanavFinancialsApi? api,
  }) : _api = api ?? const InfomanavFinancialsApi();

  final InfomanavFinancialsApi _api;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rx<FinancialStatementType> selectedStatement =
      FinancialStatementType.ic.obs;
  final RxList<QuarterlyChartViewModel> charts = <QuarterlyChartViewModel>[].obs;

  /// Distinct quarter-end dates available for the Select Year range filter.
  final RxList<DateTime> availablePeriods = <DateTime>[].obs;
  final Rxn<DateTime> rangeStart = Rxn<DateTime>();
  final Rxn<DateTime> rangeEnd = Rxn<DateTime>();

  String? _loadedSymbol;
  List<PriceDataPoint>? _priceSeriesCache;
  final Map<FinancialStatementType, List<QuarterlyChartViewModel>> _cache =
      <FinancialStatementType, List<QuarterlyChartViewModel>>{};

  Future<void> load(
    String symbol, {
    FinancialStatementType? statement,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      errorMessage.value = 'Ticker symbol is missing';
      isLoading.value = false;
      return;
    }

    final FinancialStatementType type = statement ?? selectedStatement.value;

    if (normalized != _loadedSymbol) {
      _cache.clear();
      _priceSeriesCache = null;
      _loadedSymbol = null;
      availablePeriods.clear();
      rangeStart.value = null;
      rangeEnd.value = null;
    }

    if (normalized == _loadedSymbol && _cache.containsKey(type)) {
      selectedStatement.value = type;
      charts.assignAll(_cache[type]!);
      _syncPeriodsFromCharts(_cache[type]!);
      errorMessage.value = '';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final StockQuarterlyFinancialsResponse response =
          await _api.fetchQuarterlyFinancials(normalized, type);

      final List<QuarterlyFinancialPeriod> quarters =
          QuarterlyFinancialsMapper.latestQuarters(response.financials);

      if (quarters.isEmpty) {
        throw InfomanavApiException('No quarterly financial data available');
      }

      _priceSeriesCache ??= await _api.fetchDailyPriceSeries(
        normalized,
        from: quarters.first.periodDate,
        to: quarters.last.periodDate,
      );

      final List<QuarterlyChartViewModel> built =
          QuarterlyFinancialsMapper.buildAllCharts(
        quarters,
        statement: type,
        priceData: _priceSeriesCache ?? const <PriceDataPoint>[],
      );

      if (built.isEmpty) {
        throw InfomanavApiException('No chartable quarterly values in response');
      }

      _cache[type] = built;
      _loadedSymbol = normalized;
      selectedStatement.value = type;
      charts.assignAll(built);
      _syncPeriodsFromCharts(built);
    } on InfomanavApiException catch (e) {
      errorMessage.value = e.message;
      if (selectedStatement.value == type) {
        charts.clear();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load chart data';
      if (selectedStatement.value == type) {
        charts.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void selectStatement(FinancialStatementType statement) {
    if (selectedStatement.value == statement && _cache.containsKey(statement)) {
      return;
    }

    selectedStatement.value = statement;

    if (_loadedSymbol == null) {
      return;
    }

    if (_cache.containsKey(statement)) {
      charts.assignAll(_cache[statement]!);
      _syncPeriodsFromCharts(_cache[statement]!);
      errorMessage.value = '';
      isLoading.value = false;
      return;
    }

    load(_loadedSymbol!, statement: statement);
  }

  void setRangeStart(DateTime period) {
    final DateTime? end = rangeEnd.value;
    rangeStart.value = period;
    if (end != null && period.isAfter(end)) {
      rangeEnd.value = period;
    }
  }

  void setRangeEnd(DateTime period) {
    final DateTime? start = rangeStart.value;
    rangeEnd.value = period;
    if (start != null && period.isBefore(start)) {
      rangeStart.value = period;
    }
  }

  /// Charts clipped to the active Select Year range.
  List<QuarterlyChartViewModel> get visibleCharts {
    final DateTime? start = rangeStart.value;
    final DateTime? end = rangeEnd.value;
    if (start == null || end == null) {
      return charts.toList();
    }
    return charts
        .map((QuarterlyChartViewModel chart) => chart.inPeriodRange(start, end))
        .toList();
  }

  void _syncPeriodsFromCharts(List<QuarterlyChartViewModel> built) {
    final Set<int> seen = <int>{};
    final List<DateTime> periods = <DateTime>[];

    for (final QuarterlyChartViewModel chart in built) {
      for (final QuarterDataPoint point in chart.data) {
        final int key = point.date.year * 100 + point.date.month;
        if (seen.add(key)) {
          periods.add(DateTime(point.date.year, point.date.month, point.date.day));
        }
      }
    }

    periods.sort();
    availablePeriods.assignAll(periods);

    if (periods.isEmpty) {
      rangeStart.value = null;
      rangeEnd.value = null;
      return;
    }

    final DateTime? currentStart = rangeStart.value;
    final DateTime? currentEnd = rangeEnd.value;
    final bool startValid = currentStart != null &&
        !currentStart.isBefore(periods.first) &&
        !currentStart.isAfter(periods.last);
    final bool endValid = currentEnd != null &&
        !currentEnd.isBefore(periods.first) &&
        !currentEnd.isAfter(periods.last);

    // Keep user selection when still in bounds; otherwise reset to placeholders.
    rangeStart.value = startValid ? currentStart : null;
    rangeEnd.value = endValid ? currentEnd : null;
  }

  bool get hasData => charts.isNotEmpty;

  String? get loadedSymbol => _loadedSymbol;
}
