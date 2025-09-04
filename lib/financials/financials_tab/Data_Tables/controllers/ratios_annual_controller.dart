import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

import 'package:musaffa_terminal/web_service.dart';



class FinancialRatio {
  final String name;
  final String period;
  final double value;

  FinancialRatio({
    required this.name,
    required this.period,
    required this.value,
  });

  factory FinancialRatio.fromJson(Map<String, dynamic> json) {
    return FinancialRatio(
      name: json['name'],
      period: json['period'],
      value: json['v'] is double ? json['v'] : (json['v'] as num).toDouble(),
    );
  }
}

class YearlyRatios {
  final String year;
  Map<String, double> ratios = {};

  YearlyRatios(this.year);

  void addRatio(String name, double value) {
    ratios[name] = value;
  }

  double? getRatio(String name) {
    return ratios[name];
  }
}


class RatiosController extends GetxController {
  var isLoading = true.obs;
  var yearlyRatiosMap = <String, YearlyRatios>{}.obs;
  var years = <String>[].obs;
  
  Future<void> fetchRatio(String symbol) async {
  try {
    isLoading.value = true;
    
    // First call - get older data (ascending order)
    final paramsAsc = {
      'q': '*',
      'filter_by': 'company_symbol:$symbol&&time_period:annual',
      'name': 'netMargin,quickRatio,currentRatio,peTTM,psTTM,pb,fcfMargin,payoutRatioTTM,grossMargin,roeTTM,roa,roaTTM,roic,inventoryTurnoverTTM,receivablesTurnoverTTM,assetTurnoverTTM,longtermDebtTotalEquity,totalDebtToTotalAsset,longtermDebtTotalAsset,totalDebtToTotalCapital,operatingMargin',
      'per_page': '250',
      'sort_by': 'period:asc',
      'page': '1',
    };
    
    final webService = WebService();
    final responseAsc = await WebService.getTypesense_infomanav(
      ['collections', 'company_financials_series', 'documents', 'search'],
      paramsAsc,
    );
    
    List<FinancialRatio> allRatios = [];
    
    if (responseAsc.statusCode == 200) {
      final decodedData = jsonDecode(responseAsc.body);
      
      if (decodedData.containsKey('hits')) {
        final hits = decodedData['hits'] as List;
        
        for (var hit in hits) {
          if (hit['document'] != null) {
            final document = hit['document'];
            final ratio = FinancialRatio.fromJson(document);
            allRatios.add(ratio);
          }
        }
      }
    }
    
    // Second call - get newer data (descending order)
    final paramsDesc = {
      'q': '*',
      'filter_by': 'company_symbol:$symbol&&time_period:annual',
      'name': 'netMargin,quickRatio,currentRatio,peTTM,psTTM,pb,fcfMargin,payoutRatioTTM,grossMargin,roeTTM,roa,roaTTM,roic,inventoryTurnoverTTM,receivablesTurnoverTTM,assetTurnoverTTM,longtermDebtTotalEquity,totalDebtToTotalAsset,longtermDebtTotalAsset,totalDebtToTotalCapital,operatingMargin',
      'per_page': '250',
      'sort_by': 'period:desc',
      'page': '1',
    };
    
    final responseDesc = await WebService.getTypesense_infomanav(
      ['collections', 'company_financials_series', 'documents', 'search'],
      paramsDesc,
    );
    
    if (responseDesc.statusCode == 200) {
      final decodedData = jsonDecode(responseDesc.body);
      
      if (decodedData.containsKey('hits')) {
        final hits = decodedData['hits'] as List;
        
        for (var hit in hits) {
          if (hit['document'] != null) {
            final document = hit['document'];
            final ratio = FinancialRatio.fromJson(document);
            // Add only if we don't already have this ratio (to avoid duplicates)
            if (!allRatios.any((r) => r.name == ratio.name && r.period == ratio.period)) {
              allRatios.add(ratio);
            }
          }
        }
      }
    }
    
    processRatiosByYear(allRatios);
    
  } catch (e, stackTrace) {
    debugPrint('Error fetching ratio data: $e');
    debugPrint('Stack trace: $stackTrace');
  } finally {
    isLoading.value = false;
  }
}

 void processRatiosByYear(List<FinancialRatio> allRatios) {
  yearlyRatiosMap.clear();
  years.clear();

  // Debug what years are actually coming from the API
 
 

  // Always include 2020-2024 regardless of what's in the data
  Set<String> allExpectedYears = {'2020', '2021', '2022', '2023', '2024'};
  
  // Create year objects for all expected years, even if they have no data
  for (var year in allExpectedYears) {
    yearlyRatiosMap[year] = YearlyRatios(year);
    years.add(year);
  }

  // Sort years in desired order (ascending)
  years.sort();  // For descending order: years.sort((a, b) => b.compareTo(a));
  
  // Process the ratios we actually have
  for (var ratio in allRatios) {
    final year = ratio.period.substring(0, 4);
    if (yearlyRatiosMap.containsKey(year)) {
      yearlyRatiosMap[year]?.addRatio(ratio.name, ratio.value);
    }
  }


  
}

  
  Map<String, double?> getRatioForYears(String ratioName, List<String> yearsList) {
    Map<String, double?> result = {};
    
    for (var year in yearsList) {
      final yearData = yearlyRatiosMap[year];
      result[year] = yearData?.getRatio(ratioName);
    }
    
    return result;
  }
  
  Map<String, Map<String, double?>> getFinancialDataForYears() {
    Map<String, Map<String, double?>> result = {};
    
    // Get all available ratio names from the data
    Set<String> ratioNames = {};
    for (var yearData in yearlyRatiosMap.values) {
      ratioNames.addAll(yearData.ratios.keys);
    }
    
    // Create data map for each ratio
    for (var ratioName in ratioNames) {
      result[ratioName] = getRatioForYears(ratioName, years);
    }
    
    return result;
  }
}