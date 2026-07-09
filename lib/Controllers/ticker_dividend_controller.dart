import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/dividend_entry.dart';
import 'package:musaffa_terminal/services/finnhub/dividend_service.dart';

class TickerDividendController extends ChangeNotifier {
  TickerDividendController({DividendService? service})
      : _service = service ?? DividendService();

  final DividendService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  List<DividendEntry> _entries = <DividendEntry>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DividendEntry> get entries => _entries;
  bool get hasData => _entries.isNotEmpty;

  DividendEntry? get latestEntry => _entries.isEmpty ? null : _entries.first;

  String get latestDividendLabel {
    final DividendEntry? latest = latestEntry;
    if (latest?.amount == null) {
      return '-';
    }
    return '\$${latest!.amount!.toStringAsFixed(4)}';
  }

  String get frequencyLabel => latestEntry?.frequencyLabel ?? '-';

  String get currencyLabel => latestEntry?.currency ?? 'USD';

  String get annualDividendLabel {
    final DividendEntry? latest = latestEntry;
    if (latest?.amount == null || latest?.frequency == null) {
      return '-';
    }
    final double annual = latest!.amount! * latest.frequency!;
    return '\$${annual.toStringAsFixed(4)}';
  }

  List<DividendEntry> get chartEntries {
    final List<DividendEntry> sorted = List<DividendEntry>.from(_entries)
      ..sort((DividendEntry a, DividendEntry b) => a.date.compareTo(b.date));
    return sorted;
  }

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }

    if (!forceRefresh && _loadedSymbol == normalized && _entries.isNotEmpty) {
      return;
    }

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _service.fetchForSymbol(normalized);
      _error = null;
    } catch (error) {
      _error = error.toString();
      _entries = <DividendEntry>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
