import 'dart:async';

import 'package:get/get.dart';
import 'package:musaffa_terminal/models/earnings_calendar_model.dart';
import 'package:musaffa_terminal/services/company_enrichment_cache.dart';
import 'package:musaffa_terminal/services/finnhub/earnings_calendar_service.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';
import 'package:musaffa_terminal/services/finnhub/symbol_search_service.dart';

enum EarningsCalendarLoadState {
  initial,
  loading,
  success,
  empty,
  error,
}

enum EarningsDatePreset {
  yesterday,
  today,
  tomorrow,
  thisWeek,
  nextWeek,
  thisMonth,
  custom,
}

enum EarningsHourFilter {
  all,
  bmo,
  amc,
  dmh,
}

enum EarningsSortField {
  time,
  company,
  symbol,
  quarter,
  epsActual,
  epsEstimate,
  revenueActual,
  revenueEstimate,
  marketCap,
}

class EarningsDateGroup {
  const EarningsDateGroup({
    required this.dateKey,
    required this.items,
  });

  final String dateKey;
  final List<EarningsCalendarModel> items;
}

class EarningsCalendarController extends GetxController {
  EarningsCalendarController({
    EarningsCalendarService? calendarService,
    SymbolSearchService? searchService,
  })  : _calendarService = calendarService ?? EarningsCalendarService(),
        _searchService = searchService ?? SymbolSearchService();

  final EarningsCalendarService _calendarService;
  final SymbolSearchService _searchService;

  final Rx<EarningsCalendarLoadState> loadState =
      EarningsCalendarLoadState.initial.obs;
  final RxString errorMessage = ''.obs;

  final Rx<EarningsDatePreset> datePreset = EarningsDatePreset.today.obs;
  final Rx<DateTime> fromDate = FinnhubDateFormat.localDateOnly().obs;
  final Rx<DateTime> toDate = FinnhubDateFormat.localDateOnly().obs;
  final RxBool includeInternational = false.obs;
  final RxBool isEnriching = false.obs;

  final Rx<EarningsHourFilter> hourFilter = EarningsHourFilter.all.obs;
  final RxString marketFilter = 'All Markets'.obs;

  final RxString searchQuery = ''.obs;
  final RxnString activeSymbolFilter = RxnString();
  final RxBool searchResolving = false.obs;
  final RxnString searchError = RxnString();

  final RxList<EarningsCalendarModel> allEvents =
      <EarningsCalendarModel>[].obs;
  final RxList<EarningsCalendarModel> filteredEvents =
      <EarningsCalendarModel>[].obs;

  final RxInt page = 1.obs;
  final RxInt pageSize = 10.obs;

  final Rx<EarningsSortField> sortField = EarningsSortField.time.obs;
  final RxBool sortAscending = true.obs;

  Timer? _searchDebounce;
  int _requestId = 0;

  int get totalEvents => filteredEvents.length;
  int get bmoCount =>
      filteredEvents.where((e) => e.hour?.toLowerCase() == 'bmo').length;
  int get amcCount =>
      filteredEvents.where((e) => e.hour?.toLowerCase() == 'amc').length;
  int get dmhCount =>
      filteredEvents.where((e) => e.hour?.toLowerCase() == 'dmh').length;
  int get unspecifiedHourCount => filteredEvents
      .where((e) {
        final String? h = e.hour?.toLowerCase();
        return h == null || h.isEmpty;
      })
      .length;

  int get totalPages {
    if (filteredEvents.isEmpty) return 1;
    return ((filteredEvents.length - 1) ~/ pageSize.value) + 1;
  }

  List<EarningsCalendarModel> get pageItems {
    final int start = (page.value - 1) * pageSize.value;
    if (start >= filteredEvents.length) return <EarningsCalendarModel>[];
    final int end = (start + pageSize.value).clamp(0, filteredEvents.length);
    return filteredEvents.sublist(start, end);
  }

  List<EarningsDateGroup> get pageGroups {
    final Map<String, List<EarningsCalendarModel>> grouped =
        <String, List<EarningsCalendarModel>>{};
    for (final EarningsCalendarModel item in pageItems) {
      grouped.putIfAbsent(item.date, () => <EarningsCalendarModel>[]).add(item);
    }
    final List<String> keys = grouped.keys.toList()..sort();
    return keys
        .map(
          (String key) => EarningsDateGroup(
            dateKey: key,
            items: grouped[key]!,
          ),
        )
        .toList();
  }

  String get showingLabel {
    if (filteredEvents.isEmpty) return 'Showing 0 events';
    final int start = (page.value - 1) * pageSize.value + 1;
    final int end =
        (page.value * pageSize.value).clamp(0, filteredEvents.length);
    return 'Showing $start to $end of ${filteredEvents.length} events.';
  }

  @override
  void onInit() {
    super.onInit();
    applyDatePreset(EarningsDatePreset.today, fetch: true);
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  void applyDatePreset(EarningsDatePreset preset, {bool fetch = true}) {
    datePreset.value = preset;
    final DateTime today = FinnhubDateFormat.localDateOnly();
    switch (preset) {
      case EarningsDatePreset.yesterday:
        final DateTime d = today.subtract(const Duration(days: 1));
        fromDate.value = d;
        toDate.value = d;
        break;
      case EarningsDatePreset.today:
        fromDate.value = today;
        toDate.value = today;
        break;
      case EarningsDatePreset.tomorrow:
        final DateTime d = today.add(const Duration(days: 1));
        fromDate.value = d;
        toDate.value = d;
        break;
      case EarningsDatePreset.thisWeek:
        final DateTime start =
            today.subtract(Duration(days: today.weekday - DateTime.monday));
        final DateTime end = start.add(const Duration(days: 6));
        fromDate.value = start;
        toDate.value = end;
        break;
      case EarningsDatePreset.nextWeek:
        final DateTime thisWeekStart =
            today.subtract(Duration(days: today.weekday - DateTime.monday));
        final DateTime start = thisWeekStart.add(const Duration(days: 7));
        final DateTime end = start.add(const Duration(days: 6));
        fromDate.value = start;
        toDate.value = end;
        break;
      case EarningsDatePreset.thisMonth:
        final DateTime start = DateTime(today.year, today.month, 1);
        final DateTime end = DateTime(today.year, today.month + 1, 0);
        fromDate.value = start;
        toDate.value = end;
        break;
      case EarningsDatePreset.custom:
        break;
    }
    if (fetch && preset != EarningsDatePreset.custom) {
      loadCalendar();
    }
  }

  void setCustomRange(DateTime from, DateTime to) {
    datePreset.value = EarningsDatePreset.custom;
    if (from.isAfter(to)) {
      fromDate.value = FinnhubDateFormat.localDateOnly(to);
      toDate.value = FinnhubDateFormat.localDateOnly(from);
    } else {
      fromDate.value = FinnhubDateFormat.localDateOnly(from);
      toDate.value = FinnhubDateFormat.localDateOnly(to);
    }
  }

  void setInternational(bool value) {
    if (includeInternational.value == value) return;
    includeInternational.value = value;
    loadCalendar();
  }

  void setHourFilter(EarningsHourFilter filter) {
    hourFilter.value = filter;
    _recomputeFiltered();
  }

  void setMarketFilter(String value) {
    marketFilter.value = value;
    _recomputeFiltered();
  }

  void applyClientFilters() {
    _recomputeFiltered();
  }

  void clearFilters() {
    hourFilter.value = EarningsHourFilter.all;
    marketFilter.value = 'All Markets';
    searchQuery.value = '';
    activeSymbolFilter.value = null;
    searchError.value = null;
    applyDatePreset(EarningsDatePreset.today, fetch: true);
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    searchError.value = null;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _resolveSearchAndLoad(value);
    });
  }

  void onSearchSubmitted(String value) {
    _searchDebounce?.cancel();
    _resolveSearchAndLoad(value);
  }

  Future<void> _resolveSearchAndLoad(String raw) async {
    final String query = raw.trim();
    if (query.isEmpty) {
      activeSymbolFilter.value = null;
      searchError.value = null;
      await loadCalendar();
      return;
    }

    searchResolving.value = true;
    try {
      final String? symbol = await _searchService.resolveToSymbol(query);
      if (symbol == null) {
        activeSymbolFilter.value = null;
        searchError.value = 'No matching company found.';
        allEvents.clear();
        filteredEvents.clear();
        loadState.value = EarningsCalendarLoadState.empty;
        return;
      }
      activeSymbolFilter.value = symbol;
      await loadCalendar();
    } on FinnhubApiException catch (e) {
      searchError.value = e.message;
      loadState.value = EarningsCalendarLoadState.error;
      errorMessage.value = e.message;
    } catch (e) {
      searchError.value = 'Search failed. Please try again.';
      loadState.value = EarningsCalendarLoadState.error;
      errorMessage.value = searchError.value!;
    } finally {
      searchResolving.value = false;
    }
  }

  Future<void> loadCalendar({bool forceRefresh = false}) async {
    final int requestId = ++_requestId;
    loadState.value = EarningsCalendarLoadState.loading;
    errorMessage.value = '';

    try {
      final List<EarningsCalendarModel> results =
          await _calendarService.fetchRange(
        from: fromDate.value,
        to: toDate.value,
        symbol: activeSymbolFilter.value,
        international: includeInternational.value,
        forceRefresh: forceRefresh,
      );

      if (requestId != _requestId) return;

      allEvents.assignAll(results);
      _recomputeFiltered();
      page.value = 1;

      if (filteredEvents.isEmpty) {
        loadState.value = EarningsCalendarLoadState.empty;
      } else {
        loadState.value = EarningsCalendarLoadState.success;
        await _enrichCurrentPage();
      }
    } on FinnhubApiException catch (e) {
      if (requestId != _requestId) return;
      errorMessage.value = e.message;
      loadState.value = EarningsCalendarLoadState.error;
      allEvents.clear();
      filteredEvents.clear();
    } catch (e) {
      if (requestId != _requestId) return;
      errorMessage.value = 'Failed to load earnings calendar.';
      loadState.value = EarningsCalendarLoadState.error;
      allEvents.clear();
      filteredEvents.clear();
    }
  }

  Future<void> refreshCalendar() => loadCalendar(forceRefresh: true);

  void goToPage(int next) {
    if (next < 1 || next > totalPages) return;
    page.value = next;
    _enrichCurrentPage();
  }

  void setPageSize(int newPageSize) {
    if (newPageSize < 1 || newPageSize == pageSize.value) return;
    pageSize.value = newPageSize;
    page.value = 1;
    _enrichCurrentPage();
  }

  void setSort(EarningsSortField field) {
    if (sortField.value == field) {
      sortAscending.value = !sortAscending.value;
    } else {
      sortField.value = field;
      sortAscending.value = true;
    }
    _recomputeFiltered();
  }

  void _recomputeFiltered() {
    Iterable<EarningsCalendarModel> items = allEvents;

    switch (hourFilter.value) {
      case EarningsHourFilter.bmo:
        items = items.where((e) => e.hour?.toLowerCase() == 'bmo');
        break;
      case EarningsHourFilter.amc:
        items = items.where((e) => e.hour?.toLowerCase() == 'amc');
        break;
      case EarningsHourFilter.dmh:
        items = items.where((e) => e.hour?.toLowerCase() == 'dmh');
        break;
      case EarningsHourFilter.all:
        break;
    }

    // Market filter: International toggle drives the API. "US Only" is a
    // client hint when international was fetched but user wants US symbols
    // (heuristic: symbols without exchange suffix dots).
    if (marketFilter.value == 'US Markets') {
      items = items.where((e) => !e.symbol.contains('.'));
    }

    final List<EarningsCalendarModel> list = items.toList();
    list.sort((a, b) => _compare(a, b));
    filteredEvents.assignAll(list);

    if (page.value > totalPages) {
      page.value = totalPages;
    }

    if (loadState.value == EarningsCalendarLoadState.success ||
        loadState.value == EarningsCalendarLoadState.empty) {
      loadState.value = filteredEvents.isEmpty
          ? EarningsCalendarLoadState.empty
          : EarningsCalendarLoadState.success;
    }
  }

  int _compare(EarningsCalendarModel a, EarningsCalendarModel b) {
    int result;
    switch (sortField.value) {
      case EarningsSortField.time:
        result = a.date.compareTo(b.date);
        if (result == 0) {
          result = (a.hour ?? '').compareTo(b.hour ?? '');
        }
        break;
      case EarningsSortField.company:
        final String an =
            CompanyEnrichmentCache.getCached(a.symbol)?.name ?? a.symbol;
        final String bn =
            CompanyEnrichmentCache.getCached(b.symbol)?.name ?? b.symbol;
        result = an.toLowerCase().compareTo(bn.toLowerCase());
        break;
      case EarningsSortField.symbol:
        result = a.symbol.compareTo(b.symbol);
        break;
      case EarningsSortField.quarter:
        result = (a.year ?? 0).compareTo(b.year ?? 0);
        if (result == 0) {
          result = (a.quarter ?? 0).compareTo(b.quarter ?? 0);
        }
        break;
      case EarningsSortField.epsActual:
        result = (a.epsActual ?? double.nan).compareTo(b.epsActual ?? double.nan);
        break;
      case EarningsSortField.epsEstimate:
        result =
            (a.epsEstimate ?? double.nan).compareTo(b.epsEstimate ?? double.nan);
        break;
      case EarningsSortField.revenueActual:
        result = (a.revenueActual ?? double.nan)
            .compareTo(b.revenueActual ?? double.nan);
        break;
      case EarningsSortField.revenueEstimate:
        result = (a.revenueEstimate ?? double.nan)
            .compareTo(b.revenueEstimate ?? double.nan);
        break;
      case EarningsSortField.marketCap:
        final num? am =
            CompanyEnrichmentCache.getCached(a.symbol)?.marketCap;
        final num? bm =
            CompanyEnrichmentCache.getCached(b.symbol)?.marketCap;
        result = (am ?? double.nan).compareTo(bm ?? double.nan);
        break;
    }
    return sortAscending.value ? result : -result;
  }

  Future<void> _enrichCurrentPage() async {
    final List<String> symbols =
        pageItems.map((e) => e.symbol).toSet().toList();
    if (symbols.isEmpty) return;
    isEnriching.value = true;
    try {
      await CompanyEnrichmentCache.ensureSymbols(symbols);
    } finally {
      isEnriching.value = false;
      // Nudge Obx rebuilders after cache fills (names/logos/market cap).
      filteredEvents.refresh();
    }
  }

  String emptyStateMessage() {
    if (searchError.value != null) return searchError.value!;
    if (activeSymbolFilter.value != null) {
      return 'No earnings found for ${activeSymbolFilter.value} in the selected date range.';
    }
    switch (datePreset.value) {
      case EarningsDatePreset.today:
        return 'No earnings releases found for this date.';
      case EarningsDatePreset.yesterday:
      case EarningsDatePreset.tomorrow:
        return 'No earnings releases found for this date.';
      case EarningsDatePreset.custom:
        return 'No earnings found for the selected date range.';
      default:
        return 'No earnings found for the selected date range.';
    }
  }
}
