import 'package:intl/intl.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class EarningsCalendarService {
  EarningsCalendarService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<EarningsCalendarEntry>> fetchForSymbol(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return <EarningsCalendarEntry>[];
    }

    final DateTime today = DateTime.now();
    final DateTime from = DateTime(today.year - 2, today.month, today.day);
    final DateTime to = DateTime(today.year + 1, today.month, today.day);
    final String fromStr = DateFormat('yyyy-MM-dd').format(from);
    final String toStr = DateFormat('yyyy-MM-dd').format(to);

    final dynamic decoded = await _client.get(
      'calendar/earnings',
      queryParameters: <String, String>{
        'symbol': normalized,
        'from': fromStr,
        'to': toStr,
      },
      cacheKey: 'calendar/earnings:$normalized:$fromStr:$toStr',
    );

    final List<dynamic> rawList = _extractList(decoded, key: 'earningsCalendar');
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
