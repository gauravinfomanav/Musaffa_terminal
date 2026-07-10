import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/news_sentiment_model.dart';
import 'package:musaffa_terminal/services/finnhub/news_sentiment_service.dart';

class TickerNewsSentimentController extends ChangeNotifier {
  TickerNewsSentimentController({NewsSentimentService? service})
      : _service = service ?? NewsSentimentService();

  final NewsSentimentService _service;

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  NewsSentimentModel? _model;

  bool get isLoading => _isLoading;
  String? get error => _error;
  NewsSentimentModel? get model => _model;
  bool get hasData => _model != null;

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;

    if (!forceRefresh && _loadedSymbol == normalized && _model != null) return;

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _model = await _service.fetchForSymbol(normalized);
      _error = _model == null ? 'No news sentiment data found' : null;
    } catch (e) {
      _model = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
