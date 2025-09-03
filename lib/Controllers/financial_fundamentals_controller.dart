import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/web_service.dart';

class FinancialFundamentalsController extends ChangeNotifier {
  final WebService _webService = WebService();
  
  Map<String, dynamic>? _fundamentalsData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get fundamentalsData => _fundamentalsData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFinancialFundamentals(String symbol) async {
    if (symbol.isEmpty) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final path = [
        'collections',
        'financial_fundamentals',
        'documents',
        symbol.toUpperCase()
      ];
      
      final response = await WebService.getTypesense_infomanav(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _fundamentalsData = data;
        _error = null;
      } else {
        _error = 'Failed to fetch financial fundamentals data: HTTP ${response.statusCode}';
        _fundamentalsData = null;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _fundamentalsData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFundamentals() {
    _fundamentalsData = null;
    _error = null;
    notifyListeners();
  }

  // Get EPS data for chart
  List<MapEntry<String, double>> getEpsData() {
    if (_fundamentalsData == null || _fundamentalsData!['epsTTM'] == null) {
      return [];
    }
    
    final epsData = _fundamentalsData!['epsTTM'] as Map<String, dynamic>;
    return epsData.entries
        .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Get Revenue per Share data for chart
  List<MapEntry<String, double>> getRevenuePerShareData() {
    if (_fundamentalsData == null || _fundamentalsData!['revenue_per_share'] == null) {
      return [];
    }
    
    final revenueData = _fundamentalsData!['revenue_per_share'] as Map<String, dynamic>;
    return revenueData.entries
        .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Get P/E Ratio data for chart
  List<MapEntry<String, double>> getPERatioData() {
    if (_fundamentalsData == null || _fundamentalsData!['price_to_earning'] == null) {
      return [];
    }
    
    final peData = _fundamentalsData!['price_to_earning'] as Map<String, dynamic>;
    return peData.entries
        .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Get Dividend data for chart
  List<MapEntry<String, double>> getDividendData() {
    if (_fundamentalsData == null || _fundamentalsData!['dividendPerShareTTM'] == null) {
      return [];
    }
    
    final dividendData = _fundamentalsData!['dividendPerShareTTM'] as Map<String, dynamic>;
    return dividendData.entries
        .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Get EBIT per Share data for chart
  List<MapEntry<String, double>> getEbitPerShareData() {
    if (_fundamentalsData == null || _fundamentalsData!['ebit_per_share'] == null) {
      return [];
    }
    
    final ebitData = _fundamentalsData!['ebit_per_share'] as Map<String, dynamic>;
    return ebitData.entries
        .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Get current year data
  String get currentYear {
    final epsData = getEpsData();
    return epsData.isNotEmpty ? epsData.last.key : '--';
  }

  // Get latest EPS
  double? get latestEps {
    final epsData = getEpsData();
    return epsData.isNotEmpty ? epsData.last.value : null;
  }

  // Get latest Revenue per Share
  double? get latestRevenuePerShare {
    final revenueData = getRevenuePerShareData();
    return revenueData.isNotEmpty ? revenueData.last.value : null;
  }

  // Get latest P/E Ratio
  double? get latestPERatio {
    final peData = getPERatioData();
    return peData.isNotEmpty ? peData.last.value : null;
  }

  // Get latest Dividend
  double? get latestDividend {
    final dividendData = getDividendData();
    return dividendData.isNotEmpty ? dividendData.last.value : null;
  }

  // Get latest EBIT per Share
  double? get latestEbitPerShare {
    final ebitData = getEbitPerShareData();
    return ebitData.isNotEmpty ? ebitData.last.value : null;
  }

  // Calculate growth rates
  double? getEpsGrowthRate() {
    final epsData = getEpsData();
    if (epsData.length < 2) return null;
    
    final current = epsData.last.value;
    final previous = epsData[epsData.length - 2].value;
    return ((current - previous) / previous) * 100;
  }

  double? getRevenueGrowthRate() {
    final revenueData = getRevenuePerShareData();
    if (revenueData.length < 2) return null;
    
    final current = revenueData.last.value;
    final previous = revenueData[revenueData.length - 2].value;
    return ((current - previous) / previous) * 100;
  }
}
