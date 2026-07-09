import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';
import 'package:musaffa_terminal/models/earnings_surprise.dart';
import 'package:musaffa_terminal/services/finnhub/earnings_calendar_service.dart';
import 'package:musaffa_terminal/services/finnhub/earnings_surprises_service.dart';

class TickerEarningsController extends ChangeNotifier {
  TickerEarningsController({
    EarningsCalendarService? calendarService,
    EarningsSurprisesService? surprisesService,
  })  : _calendarService = calendarService ?? EarningsCalendarService(),
        _surprisesService = surprisesService ?? EarningsSurprisesService();

  final EarningsCalendarService _calendarService;
  final EarningsSurprisesService _surprisesService;

  bool _isLoadingCalendar = false;
  bool _isLoadingSurprises = false;
  String? _calendarError;
  String? _surprisesError;
  String? _loadedSymbol;

  List<EarningsCalendarEntry> _calendarEntries = <EarningsCalendarEntry>[];
  List<EarningsSurprise> _surprises = <EarningsSurprise>[];

  bool get isLoadingCalendar => _isLoadingCalendar;
  bool get isLoadingSurprises => _isLoadingSurprises;
  bool get isLoading => _isLoadingCalendar || _isLoadingSurprises;
  String? get calendarError => _calendarError;
  String? get surprisesError => _surprisesError;

  List<EarningsCalendarEntry> get calendarEntries => _calendarEntries;
  List<EarningsSurprise> get surprises => _surprises;

  EarningsCalendarEntry? get upcomingEarnings {
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);

    final List<EarningsCalendarEntry> upcoming = _calendarEntries
        .where((EarningsCalendarEntry entry) {
          final DateTime entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          return !entryDate.isBefore(todayDate);
        })
        .toList()
      ..sort((EarningsCalendarEntry a, EarningsCalendarEntry b) =>
          a.date.compareTo(b.date));

    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<EarningsCalendarEntry> get historicalEarnings {
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);

    return _calendarEntries
        .where((EarningsCalendarEntry entry) {
          final DateTime entryDate =
              DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate.isBefore(todayDate);
        })
        .toList()
      ..sort((EarningsCalendarEntry a, EarningsCalendarEntry b) =>
          b.date.compareTo(a.date));
  }

  EarningsCalendarEntry? get previousEarnings {
    final List<EarningsCalendarEntry> history = historicalEarnings;
    return history.isEmpty ? null : history.first;
  }

  /// Last 4 reported quarters, oldest → newest (for charts).
  List<EarningsCalendarEntry> get lastFourHistoricalQuarters {
    final List<EarningsCalendarEntry> recent =
        historicalEarnings.take(4).toList()
          ..sort(
            (EarningsCalendarEntry a, EarningsCalendarEntry b) =>
                a.date.compareTo(b.date),
          );
    return recent;
  }

  List<EarningsSurprise> get chartSurprises {
    final List<EarningsSurprise> sorted =
        List<EarningsSurprise>.from(_surprises)
          ..sort((EarningsSurprise a, EarningsSurprise b) =>
              a.period.compareTo(b.period));
    return sorted;
  }

  double? surprisePercentForEntry(EarningsCalendarEntry entry) {
    final EarningsSurprise? matched = _findMatchingSurprise(entry);
    if (matched?.surprisePercent != null) {
      return matched!.surprisePercent;
    }
    return entry.surprisePercent;
  }

  EarningsSurprise? _findMatchingSurprise(EarningsCalendarEntry entry) {
    for (final EarningsSurprise surprise in _surprises) {
      if (entry.quarter != null &&
          entry.year != null &&
          surprise.quarter == entry.quarter &&
          surprise.year == entry.year) {
        return surprise;
      }

      if (surprise.period.year == entry.date.year &&
          surprise.period.month == entry.date.month &&
          surprise.period.day == entry.date.day) {
        return surprise;
      }
    }
    return null;
  }

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }

    if (!forceRefresh && _loadedSymbol == normalized && hasAnyData) {
      return;
    }

    _loadedSymbol = normalized;
    await Future.wait(<Future<void>>[
      _loadCalendar(normalized),
      _loadSurprises(normalized),
    ]);
  }

  bool get hasAnyData =>
      _calendarEntries.isNotEmpty || _surprises.isNotEmpty;

  Future<void> _loadCalendar(String symbol) async {
    _isLoadingCalendar = true;
    _calendarError = null;
    notifyListeners();

    try {
      _calendarEntries = await _calendarService.fetchForSymbol(symbol);
      _calendarError = null;
    } catch (error) {
      _calendarError = error.toString();
      _calendarEntries = <EarningsCalendarEntry>[];
    } finally {
      _isLoadingCalendar = false;
      notifyListeners();
    }
  }

  Future<void> _loadSurprises(String symbol) async {
    _isLoadingSurprises = true;
    _surprisesError = null;
    notifyListeners();

    try {
      _surprises = await _surprisesService.fetchForSymbol(symbol);
      _surprisesError = null;
    } catch (error) {
      _surprisesError = error.toString();
      _surprises = <EarningsSurprise>[];
    } finally {
      _isLoadingSurprises = false;
      notifyListeners();
    }
  }
}
