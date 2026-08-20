import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/stock_profile_model.dart';
import 'package:musaffa_terminal/services/finnhub/stock_profile_service.dart';

class StockProfileController extends ChangeNotifier {
  StockProfileController({StockProfileService? service})
      : _service = service ?? StockProfileService();

  final StockProfileService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  StockProfileModel? _profile;

  bool get isLoading => _isLoading;
  String? get error => _error;
  StockProfileModel? get profile => _profile;
  bool get hasData => _profile != null;

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;

    if (!forceRefresh &&
        _loadedSymbol == normalized &&
        _profile != null) {
      return;
    }

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.fetchBySymbol(
        normalized,
        forceRefresh: forceRefresh,
      );
      if (_profile == null) {
        _error = 'Company profile not available for $normalized';
      }
    } catch (e) {
      debugPrint('StockProfileController.load error: $e');
      _profile = null;
      _error = 'Unable to load company profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
