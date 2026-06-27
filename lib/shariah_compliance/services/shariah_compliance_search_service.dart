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

      onResults(_dedupeAndLimitBalanced(results));
    });
  }

  List<TickerModel> _dedupeAndLimitBalanced(
    List<TickerModel> results, {
    int limit = 6,
  }) {
    final List<TickerModel> stocks = <TickerModel>[];
    final List<TickerModel> etfs = <TickerModel>[];
    final Set<String> seenStockSymbols = <String>{};
    final Set<String> seenEtfSymbols = <String>{};

    for (final TickerModel item in results) {
      final String symbol =
          (item.symbol ?? item.ticker ?? '').trim().toUpperCase();
      if (symbol.isEmpty) {
        continue;
      }

      if (item.isStock) {
        if (seenStockSymbols.contains(symbol)) {
          continue;
        }
        seenStockSymbols.add(symbol);
        stocks.add(item);
      } else {
        if (seenEtfSymbols.contains(symbol)) {
          continue;
        }
        seenEtfSymbols.add(symbol);
        etfs.add(item);
      }
    }

    final int perType = (limit / 2).ceil();
    final List<TickerModel> picked = <TickerModel>[
      ...stocks.take(perType),
      ...etfs.take(perType),
    ];

    if (picked.length >= limit) {
      return picked.take(limit).toList();
    }

    final Set<String> pickedSymbols = picked
        .map(
          (TickerModel item) =>
              (item.symbol ?? item.ticker ?? '').trim().toUpperCase(),
        )
        .toSet();

    for (final TickerModel item in <TickerModel>[
      ...stocks.skip(perType),
      ...etfs.skip(perType),
    ]) {
      if (picked.length >= limit) {
        break;
      }

      final String symbol =
          (item.symbol ?? item.ticker ?? '').trim().toUpperCase();
      if (pickedSymbols.contains(symbol)) {
        continue;
      }

      pickedSymbols.add(symbol);
      picked.add(item);
    }

    return picked;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
