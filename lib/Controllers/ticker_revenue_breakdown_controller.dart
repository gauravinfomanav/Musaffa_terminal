import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';
import 'package:musaffa_terminal/services/finnhub/revenue_breakdown_service.dart';

class TickerRevenueBreakdownController extends ChangeNotifier {
  TickerRevenueBreakdownController({RevenueBreakdownService? service})
      : _service = service ?? RevenueBreakdownService();

  final RevenueBreakdownService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  RevenueBreakdownModel? _model;

  bool get isLoading => _isLoading;
  String? get error => _error;
  RevenueBreakdownModel? get model => _model;
  bool get hasData => _model?.hasData ?? false;
  RevenueBreakdownSlice? get product => _model?.product;
  RevenueBreakdownSlice? get geography => _model?.geography;

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;
    if (!forceRefresh && _loadedSymbol == normalized && hasData) return;

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _model = await _service.fetchLatestForSymbol(
        normalized,
        forceRefresh: forceRefresh,
      );
      _error = _model == null ? 'No revenue breakdown data found' : null;
    } catch (e) {
      _model = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
