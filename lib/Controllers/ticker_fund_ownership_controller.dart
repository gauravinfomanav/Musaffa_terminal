import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/fund_ownership_model.dart';
import 'package:musaffa_terminal/services/finnhub/fund_ownership_service.dart';

class TickerFundOwnershipController extends ChangeNotifier {
  TickerFundOwnershipController({FundOwnershipService? service})
      : _service = service ?? FundOwnershipService();

  final FundOwnershipService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  List<FundOwnershipModel> _items = <FundOwnershipModel>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<FundOwnershipModel> get items => _items;
  bool get hasData => _items.isNotEmpty;

  int get totalFunds => _items.length;
  num get totalSharesHeld => _items.fold<num>(0, (num sum, FundOwnershipModel e) => sum + e.share);
  num get netChange => _items.fold<num>(0, (num sum, FundOwnershipModel e) => sum + e.change);

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;

    if (!forceRefresh && _loadedSymbol == normalized && _items.isNotEmpty) return;

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.fetchForSymbol(normalized);
      _error = _items.isEmpty ? 'No fund ownership data found' : null;
    } catch (e) {
      _items = <FundOwnershipModel>[];
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
