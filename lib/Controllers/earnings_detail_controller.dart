import 'package:get/get.dart';
import 'package:musaffa_terminal/models/basic_financials_model.dart';
import 'package:musaffa_terminal/models/earnings_calendar_model.dart';
import 'package:musaffa_terminal/models/earnings_surprise.dart';
import 'package:musaffa_terminal/models/eps_estimate_model.dart';
import 'package:musaffa_terminal/models/financial_statement_model.dart';
import 'package:musaffa_terminal/models/quote_model.dart';
import 'package:musaffa_terminal/models/revenue_estimate_model.dart';
import 'package:musaffa_terminal/models/stock_profile_model.dart';
import 'package:musaffa_terminal/models/transcript_model.dart';
import 'package:musaffa_terminal/services/finnhub/basic_financials_service.dart';
import 'package:musaffa_terminal/services/finnhub/earnings_surprises_service.dart';
import 'package:musaffa_terminal/services/finnhub/eps_estimate_service.dart';
import 'package:musaffa_terminal/services/finnhub/financials_service.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';
import 'package:musaffa_terminal/services/finnhub/quote_service.dart';
import 'package:musaffa_terminal/services/finnhub/revenue_estimate_service.dart';
import 'package:musaffa_terminal/services/finnhub/stock_profile_service.dart';
import 'package:musaffa_terminal/services/finnhub/transcript_service.dart';

enum SectionLoadState {
  idle,
  loading,
  success,
  empty,
  error,
  premiumUnavailable,
}

class EarningsDetailArgs {
  const EarningsDetailArgs({
    required this.symbol,
    required this.date,
    this.quarter,
    this.year,
    this.epsActual,
    this.epsEstimate,
    this.revenueActual,
    this.revenueEstimate,
    this.hour,
  });

  final String symbol;
  final String date;
  final int? quarter;
  final int? year;
  final double? epsActual;
  final double? epsEstimate;
  final double? revenueActual;
  final double? revenueEstimate;
  final String? hour;

  factory EarningsDetailArgs.fromModel(EarningsCalendarModel model) {
    return EarningsDetailArgs(
      symbol: model.symbol,
      date: model.date,
      quarter: model.quarter,
      year: model.year,
      epsActual: model.epsActual,
      epsEstimate: model.epsEstimate,
      revenueActual: model.revenueActual,
      revenueEstimate: model.revenueEstimate,
      hour: model.hour,
    );
  }

  factory EarningsDetailArgs.fromMap(Map<String, dynamic> map) {
    return EarningsDetailArgs(
      symbol: (map['symbol'] ?? '').toString().toUpperCase(),
      date: (map['date'] ?? '').toString(),
      quarter: map['quarter'] is int
          ? map['quarter'] as int
          : int.tryParse('${map['quarter']}'),
      year: map['year'] is int
          ? map['year'] as int
          : int.tryParse('${map['year']}'),
      epsActual: _d(map['epsActual']),
      epsEstimate: _d(map['epsEstimate']),
      revenueActual: _d(map['revenueActual']),
      revenueEstimate: _d(map['revenueEstimate']),
      hour: map['hour']?.toString(),
    );
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class EarningsDetailController extends GetxController {
  EarningsDetailController({
    required this.args,
    StockProfileService? profileService,
    QuoteService? quoteService,
    EarningsSurprisesService? surprisesService,
    BasicFinancialsService? financialsMetricService,
    FinancialsService? statementsService,
    EpsEstimateService? epsEstimateService,
    RevenueEstimateService? revenueEstimateService,
    TranscriptService? transcriptService,
  })  : _profileService = profileService ?? StockProfileService(),
        _quoteService = quoteService ?? QuoteService(),
        _surprisesService = surprisesService ?? EarningsSurprisesService(),
        _financialsMetricService =
            financialsMetricService ?? BasicFinancialsService(),
        _statementsService = statementsService ?? FinancialsService(),
        _epsEstimateService = epsEstimateService ?? EpsEstimateService(),
        _revenueEstimateService =
            revenueEstimateService ?? RevenueEstimateService(),
        _transcriptService = transcriptService ?? TranscriptService();

  final EarningsDetailArgs args;

  final StockProfileService _profileService;
  final QuoteService _quoteService;
  final EarningsSurprisesService _surprisesService;
  final BasicFinancialsService _financialsMetricService;
  final FinancialsService _statementsService;
  final EpsEstimateService _epsEstimateService;
  final RevenueEstimateService _revenueEstimateService;
  final TranscriptService _transcriptService;

  final Rx<SectionLoadState> profileState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> quoteState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> historyState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> metricsState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> incomeState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> balanceState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> cashFlowState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> epsEstimateState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> revenueEstimateState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> transcriptListState = SectionLoadState.idle.obs;
  final Rx<SectionLoadState> transcriptDetailState = SectionLoadState.idle.obs;

  final Rxn<StockProfileModel> profile = Rxn<StockProfileModel>();
  final Rxn<QuoteModel> quote = Rxn<QuoteModel>();
  final RxList<EarningsSurprise> surprises = <EarningsSurprise>[].obs;
  final Rxn<BasicFinancialsModel> metrics = Rxn<BasicFinancialsModel>();
  final Rxn<FinancialStatementModel> incomeStatement =
      Rxn<FinancialStatementModel>();
  final Rxn<FinancialStatementModel> balanceSheet =
      Rxn<FinancialStatementModel>();
  final Rxn<FinancialStatementModel> cashFlow = Rxn<FinancialStatementModel>();
  final RxList<EpsEstimateModel> epsEstimates = <EpsEstimateModel>[].obs;
  final RxList<RevenueEstimateModel> revenueEstimates =
      <RevenueEstimateModel>[].obs;
  final RxList<TranscriptListItem> transcripts = <TranscriptListItem>[].obs;
  final Rxn<TranscriptDetail> selectedTranscript = Rxn<TranscriptDetail>();

  final RxString statementFreq = 'quarterly'.obs;

  bool get showHistoryTab =>
      historyState.value == SectionLoadState.success && surprises.isNotEmpty;

  bool get showFinancialsTab =>
      incomeState.value == SectionLoadState.success ||
      balanceState.value == SectionLoadState.success ||
      cashFlowState.value == SectionLoadState.success;

  bool get showEstimatesTab =>
      (epsEstimateState.value == SectionLoadState.success &&
          epsEstimates.isNotEmpty) ||
      (revenueEstimateState.value == SectionLoadState.success &&
          revenueEstimates.isNotEmpty);

  bool get showTranscriptsTab =>
      transcriptListState.value == SectionLoadState.success &&
      transcripts.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll({bool forceRefresh = false}) async {
    await Future.wait<void>(<Future<void>>[
      loadProfile(forceRefresh: forceRefresh),
      loadQuote(forceRefresh: forceRefresh),
      loadHistory(forceRefresh: forceRefresh),
      loadMetrics(forceRefresh: forceRefresh),
      loadStatements(forceRefresh: forceRefresh),
      loadEpsEstimates(forceRefresh: forceRefresh),
      loadRevenueEstimates(forceRefresh: forceRefresh),
      loadTranscriptList(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    profileState.value = SectionLoadState.loading;
    try {
      StockProfileModel? result =
          await _profileService.fetchProfile2(args.symbol,
              forceRefresh: forceRefresh);
      result ??= await _profileService.fetchBySymbol(args.symbol,
          forceRefresh: forceRefresh);
      profile.value = result;
      profileState.value =
          result == null ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      profileState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      profileState.value = SectionLoadState.error;
    }
  }

  Future<void> loadQuote({bool forceRefresh = false}) async {
    quoteState.value = SectionLoadState.loading;
    try {
      final QuoteModel? result = await _quoteService.fetchQuote(
        args.symbol,
        forceRefresh: forceRefresh,
      );
      quote.value = result;
      quoteState.value =
          result == null ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      quoteState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      quoteState.value = SectionLoadState.error;
    }
  }

  Future<void> loadHistory({bool forceRefresh = false}) async {
    historyState.value = SectionLoadState.loading;
    try {
      if (forceRefresh) {
        FinnhubApiClient.clearCacheForSymbol(args.symbol);
      }
      final List<EarningsSurprise> result =
          await _surprisesService.fetchForSymbol(args.symbol, limit: 8);
      surprises.assignAll(result);
      historyState.value =
          result.isEmpty ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      historyState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      historyState.value = SectionLoadState.error;
    }
  }

  Future<void> loadMetrics({bool forceRefresh = false}) async {
    metricsState.value = SectionLoadState.loading;
    try {
      final BasicFinancialsModel? result =
          await _financialsMetricService.fetchAll(
        args.symbol,
        forceRefresh: forceRefresh,
      );
      metrics.value = result;
      metricsState.value =
          result == null ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      metricsState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      metricsState.value = SectionLoadState.error;
    }
  }

  Future<void> loadStatements({bool forceRefresh = false}) async {
    await Future.wait<void>(<Future<void>>[
      _loadStatement(
        state: incomeState,
        target: incomeStatement,
        statement: 'ic',
        forceRefresh: forceRefresh,
      ),
      _loadStatement(
        state: balanceState,
        target: balanceSheet,
        statement: 'bs',
        forceRefresh: forceRefresh,
      ),
      _loadStatement(
        state: cashFlowState,
        target: cashFlow,
        statement: 'cf',
        forceRefresh: forceRefresh,
      ),
    ]);
  }

  Future<void> _loadStatement({
    required Rx<SectionLoadState> state,
    required Rxn<FinancialStatementModel> target,
    required String statement,
    required bool forceRefresh,
  }) async {
    state.value = SectionLoadState.loading;
    try {
      final FinancialStatementModel? result = await _statementsService.fetch(
        symbol: args.symbol,
        statement: statement,
        freq: statementFreq.value,
        forceRefresh: forceRefresh,
      );
      target.value = result;
      state.value =
          result == null ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      target.value = null;
      state.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      target.value = null;
      state.value = SectionLoadState.error;
    }
  }

  Future<void> setStatementFrequency(String freq) async {
    if (statementFreq.value == freq) return;
    statementFreq.value = freq;
    await loadStatements(forceRefresh: true);
  }

  Future<void> loadEpsEstimates({bool forceRefresh = false}) async {
    epsEstimateState.value = SectionLoadState.loading;
    try {
      final List<EpsEstimateModel> result = await _epsEstimateService.fetch(
        symbol: args.symbol,
        forceRefresh: forceRefresh,
      );
      epsEstimates.assignAll(result);
      epsEstimateState.value =
          result.isEmpty ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      epsEstimates.clear();
      epsEstimateState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      epsEstimates.clear();
      epsEstimateState.value = SectionLoadState.error;
    }
  }

  Future<void> loadRevenueEstimates({bool forceRefresh = false}) async {
    revenueEstimateState.value = SectionLoadState.loading;
    try {
      final List<RevenueEstimateModel> result =
          await _revenueEstimateService.fetch(
        symbol: args.symbol,
        forceRefresh: forceRefresh,
      );
      revenueEstimates.assignAll(result);
      revenueEstimateState.value =
          result.isEmpty ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      revenueEstimates.clear();
      revenueEstimateState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      revenueEstimates.clear();
      revenueEstimateState.value = SectionLoadState.error;
    }
  }

  Future<void> loadTranscriptList({bool forceRefresh = false}) async {
    transcriptListState.value = SectionLoadState.loading;
    try {
      if (forceRefresh) {
        FinnhubApiClient.clearCacheKey(
          'stock/transcripts/list:${args.symbol}',
        );
      }
      final List<TranscriptListItem> result =
          await _transcriptService.fetchList(args.symbol);
      transcripts.assignAll(result);
      transcriptListState.value =
          result.isEmpty ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      transcripts.clear();
      transcriptListState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      transcripts.clear();
      transcriptListState.value = SectionLoadState.error;
    }
  }

  Future<void> openTranscript(String id) async {
    transcriptDetailState.value = SectionLoadState.loading;
    selectedTranscript.value = null;
    try {
      final TranscriptDetail? detail = await _transcriptService.fetchById(id);
      selectedTranscript.value = detail;
      transcriptDetailState.value =
          detail == null ? SectionLoadState.empty : SectionLoadState.success;
    } on FinnhubApiException catch (e) {
      transcriptDetailState.value = e.isAccessDenied
          ? SectionLoadState.premiumUnavailable
          : SectionLoadState.error;
    } catch (_) {
      transcriptDetailState.value = SectionLoadState.error;
    }
  }
}
