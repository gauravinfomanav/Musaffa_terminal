import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/insider_transaction_model.dart';
import 'package:musaffa_terminal/services/finnhub/insider_trading_service.dart';

class TickerInsiderTradingController extends ChangeNotifier {
  TickerInsiderTradingController({InsiderTradingService? service})
      : _service = service ?? InsiderTradingService();

  final InsiderTradingService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  List<InsiderTransactionModel> _items = <InsiderTransactionModel>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<InsiderTransactionModel> get items => _items;
  bool get hasData => _items.isNotEmpty;

  int get totalTransactions => _items.length;
  int get buyTransactions => _items.where((InsiderTransactionModel e) => e.isBuy).length;
  int get sellTransactions => _items.where((InsiderTransactionModel e) => e.isSell).length;
  num get netSharesChanged =>
      _items.fold<num>(0, (num sum, InsiderTransactionModel e) => sum + e.change);
  num get netTransactionValue => _items.fold<num>(
        0,
        (num sum, InsiderTransactionModel e) =>
            sum + (e.change.abs() * e.transactionPrice),
      );

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
      _error = _items.isEmpty ? 'No insider transactions found' : null;
    } catch (e) {
      _items = <InsiderTransactionModel>[];
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
