import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';


class FinancialStatementsController extends GetxController {
  var isLoading = true.obs;
  final WebService webService = WebService();
  var financialData = <FinancialStatementModel>[].obs;
  var years = <String>[].obs;

  final Map<String, dynamic> incomeStatementMapping = {
    'revenue': 'Total Revenue',
    'costOfGoodsSold': 'Cost of Goods Sold',
    'grossIncome': 'Gross Profit',
    'totalOperatingExpense': {
      'label': 'Total Operating Expenses',
      'valueKey': 'totalOperatingExpense',
      'subItems': {
        'researchDevelopment': 'Research and Development',
        'sgaExpense': 'Selling, General & Adm',
      },
    },
    'ebit': 'Earnings Before Interest and Taxes (EBIT)',
    'totalOtherIncomeExpenseNet': 'Total Other Income (Expense), Net',
    'pretaxIncome': 'Income Before Taxes',
    'provisionforIncomeTaxes': 'Provision for Income Taxes',
    'netIncomeAfterTaxes': 'Net Income After Taxes',
    'netIncome': 'Net Income',
    'dilutedAverageSharesOutstanding': 'Average Shares Outstanding (diluted)',
    'dilutedEPS': 'Earnings Per Share (diluted)',
  };

 
  final Map<String, dynamic> balanceSheetMapping = {
  'totalAssets': {
    'label': 'Total Assets',
    'valueKey': 'totalAssets',
    'subItems': {
      'totalCurrentAssets': {
        'label': 'Total Current Assets',
        'valueKey': 'currentAssets',
        'subItems': {
          'cashShortTermInvestments': {
            'label': 'Cash & Short-Term Investments',
            'valueKey': 'cashShortTermInvestments',
            'subItems': {
              'cash': 'Cash',
              'cashEquivalents': 'Cash Equivalents',
              'shortTermInvestments': 'Short-Term Investments',
            },
          },
          'accountsReceivables': 'Accounts Receivables',
          'inventory': 'Inventory',
          'otherCurrentAssets': 'Other Current Assets',
        },
      },
      'propertyPlantEquipment': 'Property, Plant & Equipment',
      'accumulatedDepreciation': 'Accumulated Depreciation',
      'longTermInvestments': 'Long-Term Investments',
      'otherLongTermAssets': 'Other Long-Term Assets',
      'goodwill': 'Goodwill',
      'intangiblesAssets': 'Intangible Assets'

    },
  },

  'totalLiabilities': {
    'label': 'Total Liabilities',
    'valueKey': 'totalLiabilities',
    'subItems': {
      'totalCurrentLiabilities': {
        'label': 'Total Current Liabilities',
        'valueKey': 'currentLiabilities',
        'subItems': {
          'accountsPayable': 'Accounts Payable',
          'accruedLiability': 'Accrued Liability',
          'shortTermDebt': 'Short-Term Debt',
          'currentPortionLongTermDebt': 'Current Portion of Long-Term Debt',
          'otherCurrentliabilities': 'Other Current Liabilities',
        },
      },
    },
  },

  // Free-standing items under Total Liabilities
  'longTermDebt': 'Long-Term Debt',
  'netDebt': 'Net Debt',
  'otherLiabilities': 'Other Liabilities',
  'totalDebt': 'Total Debt',
  'liabilitiesShareholdersEquity': 'Total Liabilities & Shareholders Equity',
  'totalEquity': 'Total Shareholders Equity',
  'commonStock': 'Common Stock',
  'additionalPaidInCapital': 'Additional Paid-In Capital',
  'retainedEarnings': 'Retained Earnings',
  'otherEquity': 'Other Equity',
  'sharesOutstanding': 'Shares Outstanding',
};


  // Structured mapping for Cash Flow (cf)
  final Map<String, dynamic> cashFlowMapping = {
  'netIncome': 'Net Income',

  'netOperatingCashFlow': {
    'label': 'Net Cash from Operating Activities',
    'valueKey': 'netOperatingCashFlow',
    'subItems': {
      'stockBasedCompensation': 'Stock-Based Compensation Expense',
      'depreciationAmortization': 'Depreciation & Amortization',
      'otherFundsNonCashItems': 'Other Non-Cash Items',
      'changesinWorkingCapital': 'Change in Working Capital',
    },
  },

  'netInvestingCashFlow': {
    'label': 'Net Cash from Investing Activities',
    'valueKey': 'netInvestingCashFlow',
    'subItems': {
      'capex': 'Capital Expenditure',
      'otherInvestingCashFlowItemsTotal': 'Other Investing Cash Flow Items',
    },
  },

  'netCashFinancingActivities': {
    'label': 'Net Cash from Financing Activities',
    'valueKey': 'netCashFinancingActivities',
    'subItems': {
      'issuanceReductionDebtNet': 'Net Issuance (Reduction) of Debt',
      'otherFundsFinancingItems': 'Other Financing Cash Flow Items',
      'cashDividendsPaid': 'Payments for Dividends and Dividend Equivalents',
      'cashTaxesPaid': 'Payments for Taxes',
    },
  },
};
 

  // Method to get the appropriate structured mapping based on reportType
  Map<String, dynamic> _getStructuredMapping(String reportType) {
    switch (reportType) {
      case 'ic':
        return incomeStatementMapping;
      case 'bs':
        return balanceSheetMapping;
      case 'cf':
        return cashFlowMapping;
      default:
        return incomeStatementMapping; // Default to Income Statement if reportType is invalid
    }
  }

  // Recursive function to process nested mappings
 

Future<void> fetchFinancialReport(String symbol, String reportType) async {
  try {
    isLoading.value = true;

    // Get the appropriate structured mapping based on reportType
    Map<String, dynamic> structuredMapping = _getStructuredMapping(reportType);

    Map<String, dynamic> params = {
      'q': '*',
      'filter_by': 'company_symbol:$symbol&&freq:annual',
      'page': '1',
      'per_page': '250'
    };

    final response = await WebService.getTypesense_infomanav(
      ['collections', 'financial_statements_1', 'documents', 'search'],
      params,
    );

    if (response.statusCode == 200) {
      // print("Raw Response: ${response.body}");
      final decodedData = jsonDecode(response.body) as Map<String, dynamic>?;

      if (decodedData == null || decodedData['hits'] == null) {
        financialData.clear();
        years.clear();
        return;
      }

      List<dynamic> hits = decodedData['hits'] as List<dynamic>;
      Set<String> uniqueYears = {};

      // Collect raw data by year
      Map<String, Map<String, dynamic>> dataByYear = {};

      for (var hit in hits) {
        var dataItem = hit['document'] ?? hit;
        String year = dataItem['year']?.toString() ?? '';

        if (year.isEmpty) continue;

        uniqueYears.add(year);
        dataByYear[year] = dataItem;
      }

      // Process data and build the model
      List<FinancialStatementModel> newData = _processFinancialData(dataByYear, structuredMapping);

      financialData.assignAll(newData);
      years.assignAll(uniqueYears.toList()..sort());
    } else {
      financialData.clear();
      years.clear();
    }
  } catch (e) {
    print('Error fetching financial report: $e');
    financialData.clear();
    years.clear();
  } finally {
    isLoading.value = false;
  }
}

List<FinancialStatementModel> _processFinancialData(
    Map<String, Map<String, dynamic>> dataByYear,
    Map<String, dynamic> structuredMapping) {
  // First, create a map of item name -> Map<year, value>
  Map<String, Map<String, String>> valueMap = {};
  
  // We need to maintain a GLOBAL hierarchy map that combines structures from all years
  Map<String, List<String>> globalHierarchyMap = {};
  
  // Process each year's data and fill valueMap
  dataByYear.forEach((year, data) {
    Map<String, List<String>> yearHierarchy = {};
    
    // Process through structured mapping
    _extractValuesFromMapping(structuredMapping, data, year, valueMap, yearHierarchy, "");
    
    // Merge this year's hierarchy into the global hierarchy
    yearHierarchy.forEach((parent, children) {
      globalHierarchyMap.putIfAbsent(parent, () => []);
      for (var child in children) {
        if (!globalHierarchyMap[parent]!.contains(child)) {
          globalHierarchyMap[parent]!.add(child);
        }
      }
    });
  });

  List<FinancialStatementModel> result = [];

  // Find all top-level items
  List<String> topLevelNames = globalHierarchyMap[""] ?? [];

  // Create models for top-level items
  for (var name in topLevelNames) {
    // For each top-level item, create a model per year
    for (var year in dataByYear.keys) {
      // Even if we don't have data for this item in this year, we create a placeholder
      // to maintain consistent structure
      String originalValue = '-';
      if (valueMap.containsKey(name) && valueMap[name]!.containsKey(year)) {
        originalValue = valueMap[name]![year]!;
      }
      
      result.add(FinancialStatementModel(
        name: name,
        year: year,
        originalValue: originalValue,
        subItems: _buildSubItemsWithGlobalHierarchy(name, year, valueMap, globalHierarchyMap),
      ));
    }
  }

  return result;
}
List<FinancialStatementModel> _buildSubItemsWithGlobalHierarchy(
    String parentName,
    String year,
    Map<String, Map<String, String>> valueMap,
    Map<String, List<String>> globalHierarchyMap) {
  
  List<FinancialStatementModel> result = [];
  
  // Get children of this parent from the global hierarchy
  List<String>? children = globalHierarchyMap[parentName];
  
  if (children == null || children.isEmpty) {
    return result;
  }
  
  // Build model for each child, regardless of whether this year has data
  for (var childName in children) {
    // Default to empty value if no data exists for this year
    String childValue = '-';
    
    // If we have data for this child for this year, use it
    if (valueMap.containsKey(childName) && valueMap[childName]!.containsKey(year)) {
      childValue = valueMap[childName]![year]!;
    }
    
    // Debug for subitems
    
    
    result.add(FinancialStatementModel(
      name: childName,
      year: year,
      originalValue: childValue,
      isSubItem: true,
      // Recursively build further nested items
      subItems: _buildSubItemsWithGlobalHierarchy(childName, year, valueMap, globalHierarchyMap),
    ));
  }
  
  return result;
}

void _extractValuesFromMapping(
    Map<String, dynamic> mapping,
    Map<String, dynamic> data,
    String year,
    Map<String, Map<String, String>> valueMap,
    Map<String, List<String>> hierarchyMap,
    String parent) {
  mapping.forEach((key, value) {
    if (value is String) {
      // Simple key-value mapping
      String itemName = value;
      String itemValue = data[key]?.toString() ?? '-';
      // Normalize empty string, "0", or null to '-'
      if (itemValue.isEmpty || itemValue == '0' || itemValue == 'null') {
        itemValue = '-';
      }
      
      // Add to value map
      valueMap.putIfAbsent(itemName, () => {});
      valueMap[itemName]![year] = itemValue;
      
      // Add to hierarchy map for ALL years, not just current year
      hierarchyMap.putIfAbsent(parent, () => []);
      if (!hierarchyMap[parent]!.contains(itemName)) {
        hierarchyMap[parent]!.add(itemName);
      }
    } else if (value is Map) {
      // Nested structure
      String label = value['label'];
      String valueKey = value['valueKey'];
      
      // Add this item
      String itemValue = data[valueKey]?.toString() ?? '-';
      // Normalize empty string, "0", or null to '-'
      if (itemValue.isEmpty || itemValue == '0' || itemValue == 'null') {
        itemValue = '-';
      }
      
      valueMap.putIfAbsent(label, () => {});
      valueMap[label]![year] = itemValue;
      
      // Add to hierarchy for ALL years
      hierarchyMap.putIfAbsent(parent, () => []);
      if (!hierarchyMap[parent]!.contains(label)) {
        hierarchyMap[parent]!.add(label);
      }
      
      // Process sub-items
      if (value.containsKey('subItems')) {
        _extractValuesFromMapping(value['subItems'], data, year, valueMap, hierarchyMap, label);
      }
    }
  });
}

List<FinancialStatementModel> _buildSubItems(
    String parentName,
    String year,
    Map<String, Map<String, String>> valueMap,
    Map<String, List<String>> hierarchyMap) {
  
  List<FinancialStatementModel> result = [];
  
  // Get children of this parent for the specific year
  List<String>? children = hierarchyMap[parentName];
  
  if (children == null || children.isEmpty) {
    return result;
  }
  
  // Build model for each child
  for (var childName in children) {
    // We need to check if this child has data for this specific year
    if (valueMap.containsKey(childName)) {
      // Even if this specific year doesn't have data, we include the child
      // and set a default value so the structure is consistent
      String childValue = valueMap[childName]![year] ?? '-';
      
      result.add(FinancialStatementModel(
        name: childName,
        year: year,
        originalValue: childValue,
        isSubItem: true,
        // Recursively build nested subitems for this specific year
        subItems: _buildSubItems(childName, year, valueMap, hierarchyMap),
      ));
    }
  }
  
  return result;
}
 
}

class FinancialStatementModel {
  final String name;
  final String year;
  final String originalValue;
  final bool isSubItem; // To identify if this is a child item
  final List<FinancialStatementModel> subItems; // For expandable rows

  FinancialStatementModel({
    required this.name,
    required this.year,
    required String originalValue,
    this.isSubItem = false,
    this.subItems = const [],
  }) : originalValue = _formatValue(originalValue);

  static String _formatValue(String value) {
  // Check if it's a number first
  double? numValue = double.tryParse(value);
  if (numValue == null) return value;

  // For special cases like "-" placeholder
  if (value == "-") return value;
  
  // For numeric values, apply the shortening
  return getShortened(value);
}

  @override
  String toString() {
    return 'Name: $name, Year: $year, Value: $originalValue, IsSubItem: $isSubItem';
  }
}



String getShortened(String value) {
  // Try to parse the string value
  double? numValue = double.tryParse(value);
  
  // Return original value if parsing fails
  if (numValue == null) return value;
  
  // Work with absolute value for calculations (remove minus sign)
  numValue = numValue.abs();
  
  // Multiply by 10 lakh (1,000,000)
  numValue = numValue * 1000000;
  
  // Format based on magnitude (without sign)
  if (numValue >= 1e12) {
    return (numValue / 1e12).toStringAsFixed(1) + " T"; // Trillions
  } else if (numValue >= 1e9) {
    return (numValue / 1e9).toStringAsFixed(1) + " B"; // Billions
  } else if (numValue >= 1e6) {
    return (numValue / 1e6).toStringAsFixed(1) + " M"; // Millions
  } else {
    return numValue.toStringAsFixed(1); // Keep the value without sign
  }
}