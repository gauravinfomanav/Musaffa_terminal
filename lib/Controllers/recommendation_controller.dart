import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/recommendation_model.dart';
import 'package:musaffa_terminal/models/recommendation_trend_model.dart';
import 'package:musaffa_terminal/services/finnhub/recommendation_trend_service.dart';
import 'package:musaffa_terminal/web_service.dart';

class RecommendationController extends ChangeNotifier {
  RecommendationModel? _recommendation;
  List<RecommendationTrendModel> _trendHistory = <RecommendationTrendModel>[];
  bool _isLoading = false;
  bool _isTrendLoading = false;
  String? _error;
  String? _trendError;
  String? _loadedTrendSymbol;

  final RecommendationTrendService _trendService = RecommendationTrendService();

  RecommendationModel? get recommendation => _recommendation;
  List<RecommendationTrendModel> get trendHistory => _trendHistory;
  bool get isLoading => _isLoading;
  bool get isTrendLoading => _isTrendLoading;
  String? get error => _error;
  String? get trendError => _trendError;

  Future<void> fetchRecommendation(String symbol) async {
    if (symbol.isEmpty) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await WebService.getTypesense([
        'collections',
        'recommendation_collection',
        'documents',
        symbol.toUpperCase()
      ]);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _recommendation = RecommendationModel.fromJson(data);
        _error = null;
      } else {
        _error = 'Failed to fetch recommendation data';
        _recommendation = null;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _recommendation = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    fetchRecommendationTrends(symbol);
  }

  Future<void> fetchRecommendationTrends(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;
    if (!forceRefresh &&
        _loadedTrendSymbol == normalized &&
        _trendHistory.isNotEmpty) {
      return;
    }

    _isTrendLoading = true;
    _trendError = null;
    _loadedTrendSymbol = normalized;
    notifyListeners();

    try {
      _trendHistory = await _trendService.fetchForSymbol(normalized);
      _trendError = _trendHistory.isEmpty ? 'No recommendation trend data' : null;
    } catch (e) {
      _trendHistory = <RecommendationTrendModel>[];
      _trendError = e.toString();
    } finally {
      _isTrendLoading = false;
      notifyListeners();
    }
  }

  void clearRecommendation() {
    _recommendation = null;
    _trendHistory = <RecommendationTrendModel>[];
    _error = null;
    _trendError = null;
    notifyListeners();
  }

  // Get total number of recommendations
  int get totalRecommendations {
    if (_recommendation == null) return 0;
    return _recommendation!.strongBuy + 
           _recommendation!.buy + 
           _recommendation!.hold + 
           _recommendation!.sell + 
           _recommendation!.strongSell;
  }

  // Get percentage for each recommendation type
  double getStrongBuyPercentage() {
    if (totalRecommendations == 0) return 0.0;
    return (_recommendation?.strongBuy ?? 0) / totalRecommendations * 100;
  }

  double getBuyPercentage() {
    if (totalRecommendations == 0) return 0.0;
    return (_recommendation?.buy ?? 0) / totalRecommendations * 100;
  }

  double getHoldPercentage() {
    if (totalRecommendations == 0) return 0.0;
    return (_recommendation?.hold ?? 0) / totalRecommendations * 100;
  }

  double getSellPercentage() {
    if (totalRecommendations == 0) return 0.0;
    return (_recommendation?.sell ?? 0) / totalRecommendations * 100;
  }

  double getStrongSellPercentage() {
    if (totalRecommendations == 0) return 0.0;
    return (_recommendation?.strongSell ?? 0) / totalRecommendations * 100;
  }
}
