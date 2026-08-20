import 'package:intl/intl.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';
import 'package:musaffa_terminal/models/earnings_calendar_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

/// Formats calendar dates for Finnhub as `YYYY-MM-DD` using local calendar days.
class FinnhubDateFormat {
  FinnhubDateFormat._();

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');

  static String format(DateTime date) {
    final DateTime local = DateTime(date.year, date.month, date.day);
    return _ymd.format(local);
  }

  static DateTime localDateOnly([DateTime? source]) {
    final DateTime now = source ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

class EarningsCalendarService {
  EarningsCalendarService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  /// Range query used by the Earnings Calendar screen.
  Future<List<EarningsCalendarModel>> fetchRange({
    required DateTime from,
    required DateTime to,
    String? symbol,
    bool international = false,
    bool forceRefresh = false,
  }) async {
    final String fromStr = FinnhubDateFormat.format(from);
    final String toStr = FinnhubDateFormat.format(to);
    final String? normalizedSymbol =
        symbol == null || symbol.trim().isEmpty
            ? null
            : symbol.trim().toUpperCase();

    final Map<String, String> params = <String, String>{
      'from': fromStr,
      'to': toStr,
      'international': international ? 'true' : 'false',
      if (normalizedSymbol != null) 'symbol': normalizedSymbol,
    };

    final String cacheKey =
        'calendar/earnings:$fromStr:$toStr:${normalizedSymbol ?? '*'}:$international';

    final dynamic decoded = await _client.get(
      'calendar/earnings',
      queryParameters: params,
      cacheKey: cacheKey,
      forceRefresh: forceRefresh,
    );

    final List<dynamic> rawList =
        _extractList(decoded, key: 'earningsCalendar');
    final List<EarningsCalendarModel> items = rawList
        .whereType<Map>()
        .map(
          (Map item) =>
              EarningsCalendarModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((EarningsCalendarModel e) => e.symbol.isNotEmpty)
        .toList();

    if (normalizedSymbol != null) {
      items.retainWhere(
        (EarningsCalendarModel e) => e.symbol == normalizedSymbol,
      );
    }

    items.sort((EarningsCalendarModel a, EarningsCalendarModel b) {
      final int byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.symbol.compareTo(b.symbol);
    });
    return items;
  }

  /// Existing symbol-scoped helper used by ticker detail screens.
  Future<List<EarningsCalendarEntry>> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <EarningsCalendarEntry>[];
    }

    final DateTime today = FinnhubDateFormat.localDateOnly();
    final DateTime from =
        DateTime(today.year - 2, today.month, today.day);
    final DateTime to = DateTime(today.year + 1, today.month, today.day);
    final String fromStr = FinnhubDateFormat.format(from);
    final String toStr = FinnhubDateFormat.format(to);

    final dynamic decoded = await _client.get(
      'calendar/earnings',
      queryParameters: <String, String>{
        'symbol': normalized,
        'from': fromStr,
        'to': toStr,
      },
      cacheKey: 'calendar/earnings:$normalized:$fromStr:$toStr',
    );

    final List<dynamic> rawList =
        _extractList(decoded, key: 'earningsCalendar');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(EarningsCalendarEntry.fromJson)
        .where((EarningsCalendarEntry entry) => entry.symbol == normalized)
        .toList()
      ..sort((EarningsCalendarEntry a, EarningsCalendarEntry b) =>
          b.date.compareTo(a.date));
  }

  List<dynamic> _extractList(dynamic decoded, {String? key}) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      if (key != null && decoded[key] is List<dynamic>) {
        return decoded[key] as List<dynamic>;
      }
      for (final dynamic value in decoded.values) {
        if (value is List<dynamic>) {
          return value;
        }
      }
    }
    return <dynamic>[];
  }
}
