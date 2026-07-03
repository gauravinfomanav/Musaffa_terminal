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
    }

    if (normalized == _loadedSymbol && _cache.containsKey(type)) {
      selectedStatement.value = type;
      charts.assignAll(_cache[type]!);
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
      errorMessage.value = '';
      isLoading.value = false;
      return;
    }

    load(_loadedSymbol!, statement: statement);
  }

  bool get hasData => charts.isNotEmpty;

  String? get loadedSymbol => _loadedSymbol;
}
