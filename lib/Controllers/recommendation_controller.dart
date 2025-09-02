import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/recommendation_model.dart';
import 'package:musaffa_terminal/web_service.dart';

class RecommendationController extends ChangeNotifier {
  RecommendationModel? _recommendation;
  bool _isLoading = false;
  String? _error;

  RecommendationModel? get recommendation => _recommendation;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
  }

  void clearRecommendation() {
    _recommendation = null;
    _error = null;
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
