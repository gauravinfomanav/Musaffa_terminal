import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';
import 'package:musaffa_terminal/services/finnhub/revenue_breakdown_service.dart';

class TickerRevenueGeographyController extends ChangeNotifier {
  TickerRevenueGeographyController({RevenueBreakdownService? service})
      : _service = service ?? RevenueBreakdownService();

  final RevenueBreakdownService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  RevenueBreakdownModel? _model;

  bool get isLoading => _isLoading;
  String? get error => _error;
  RevenueBreakdownModel? get model => _model;
  bool get hasData => _model != null && _model!.items.isNotEmpty;

  RevenueBreakdownItem? get largestRegion {
    if (!hasData) return null;
    final List<RevenueBreakdownItem> sorted = List<RevenueBreakdownItem>.from(_model!.items)
      ..sort((RevenueBreakdownItem a, RevenueBreakdownItem b) => b.revenue.compareTo(a.revenue));
    return sorted.first;
  }

  num get totalRevenue => hasData
      ? _model!.items.fold<num>(0, (num s, RevenueBreakdownItem i) => s + i.revenue)
      : 0;

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;
    if (!forceRefresh && _loadedSymbol == normalized && hasData) return;

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _model = await _service.fetchLatestForSymbol(normalized);
      _error = _model == null ? 'No revenue geography data found' : null;
    } catch (e) {
      _model = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
