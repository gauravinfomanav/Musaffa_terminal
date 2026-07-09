import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/peer_comparison_row.dart';
import 'package:musaffa_terminal/services/finnhub/peer_comparison_service.dart';

class TickerPeerComparisonController extends ChangeNotifier {
  TickerPeerComparisonController({PeerComparisonService? service})
      : _service = service ?? PeerComparisonService();

  final PeerComparisonService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  List<PeerComparisonRow> _rows = <PeerComparisonRow>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PeerComparisonRow> get rows => _rows;
  bool get hasData => _rows.isNotEmpty;

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }

    if (!forceRefresh && _loadedSymbol == normalized && _rows.isNotEmpty) {
      return;
    }

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<String> peerSymbols = await _service.fetchPeerSymbols(normalized);
      final List<String> symbolsToLoad = <String>[
        normalized,
        ...peerSymbols.take(10),
      ];

      final List<Future<PeerComparisonRow?>> tasks =
          symbolsToLoad.map((String item) {
        return _service.fetchStockRow(item, isCurrent: item == normalized);
      }).toList();

      final List<PeerComparisonRow?> loaded = await Future.wait(tasks);
      final List<PeerComparisonRow> validRows =
          loaded.whereType<PeerComparisonRow>().toList();

      validRows.sort((PeerComparisonRow a, PeerComparisonRow b) {
        if (a.isCurrent && !b.isCurrent) return -1;
        if (!a.isCurrent && b.isCurrent) return 1;
        return a.ticker.compareTo(b.ticker);
      });

      _rows = validRows;
      if (_rows.isEmpty) {
        _error = 'No peer comparison data found';
      }
    } catch (error) {
      _rows = <PeerComparisonRow>[];
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
