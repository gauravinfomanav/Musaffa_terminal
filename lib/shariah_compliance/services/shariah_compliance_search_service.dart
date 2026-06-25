import 'dart:async';

import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';

class ShariahComplianceSearchService {
  Timer? _debounceTimer;
  int _requestId = 0;

  void searchTickersDebounced(
    String query, {
    required void Function(List<TickerModel> results) onResults,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();

    final String normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      onResults(const <TickerModel>[]);
      return;
    }

    _debounceTimer = Timer(debounceDuration, () async {
      _requestId++;
      final int currentRequestId = _requestId;

      final List<TickerModel> results =
          await SearchService.searchStocks(normalizedQuery);

      if (currentRequestId != _requestId) {
        return;
      }

      onResults(_dedupeAndLimit(results));
    });
  }

  List<TickerModel> _dedupeAndLimit(List<TickerModel> results) {
    final Set<String> seenSymbols = <String>{};
    final List<TickerModel> filtered = <TickerModel>[];

    for (final TickerModel item in results) {
      final String symbol =
          (item.symbol ?? item.ticker ?? '').trim().toUpperCase();
      if (symbol.isEmpty || seenSymbols.contains(symbol)) {
        continue;
      }

      seenSymbols.add(symbol);
      filtered.add(item);

      if (filtered.length == 6) {
        break;
      }
    }

    return filtered;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
