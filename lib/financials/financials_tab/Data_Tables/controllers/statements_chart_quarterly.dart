import 'dart:convert';
import 'package:get/get.dart';
import 'package:musaffa_terminal/web_service.dart';

class FinancialStatementsQuarterlyController extends GetxController {
  var isLoading = true.obs;
  final WebService webService = WebService();
  var financialData = <FinancialStatementModel>[].obs;
  var quarters = <String>[].obs;

  // Same mappings as the annual controller
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
        return incomeStatementMapping;
    }
  }

  Future<void> fetchFinancialReport(String symbol, String reportType) async {
  try {
    isLoading.value = true;

    // Get the appropriate structured mapping based on reportType
    Map<String, dynamic> structuredMapping = _getStructuredMapping(reportType);

    Map<String, dynamic> params = {
      'q': '*',
      'filter_by': 'company_symbol:$symbol&&freq:quarterly',
      'page': '1',
      'per_page': '250' // Increased to handle 250 hits
    };

    final response = await WebService.getTypesense_infomanav(
      ['collections', 'financial_statements_1', 'documents', 'search'],
      params,
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body) as Map<String, dynamic>?;

      if (decodedData == null || decodedData['hits'] == null) {
        financialData.clear();
        quarters.clear();
        return;
      }

      List<dynamic> hits = decodedData['hits'] as List<dynamic>;

      // Define the expected quarters for 2024
      const List<String> expectedQuarters = ['Q12024', 'Q22024', 'Q32024', 'Q42024'];
      Map<String, Map<String, dynamic>> dataByQuarter = {};

      // Process hits and filter for 2024 only
      for (var hit in hits) {
        var dataItem = hit['document'] ?? hit;
        String period = dataItem['period'] ?? '';
        String quarterLabel = _getQuarterLabelFromPeriod(period);

        // Only include data for 2024 quarters
        if (quarterLabel.isNotEmpty && quarterLabel.endsWith('2024')) {
          dataByQuarter[quarterLabel] = dataItem;
        }
      }

      // Ensure all 2024 quarters are represented, even if missing
      for (var quarter in expectedQuarters) {
        if (!dataByQuarter.containsKey(quarter)) {
          dataByQuarter[quarter] = {'placeholder': true}; // Placeholder for missing data
        }
      }

      // Populate quarterLabels with all expected quarters
      List<String> quarterLabels = expectedQuarters;

      // Process data and build the model
      List<FinancialStatementModel> newData = _processFinancialData(dataByQuarter, structuredMapping);

      financialData.assignAll(newData);
      quarters.assignAll(quarterLabels);
    } else {
      financialData.clear();
      quarters.clear();
    }
  } catch (e) {
    print('Error fetching quarterly financial report: $e');
    financialData.clear();
    quarters.clear();
  } finally {
    isLoading.value = false;
  }
}

// Helper method to convert period (e.g., "2024-12-28") to quarter label (e.g., "Q42024")
String _getQuarterLabelFromPeriod(String period) {
  if (period.isEmpty) return '';

  try {
    // Parse the date (assuming format "YYYY-MM-DD")
    DateTime date = DateTime.parse(period);
    int month = date.month;
    int year = date.year;

    // Determine the quarter based on the month
    String quarter;
    if (month >= 1 && month <= 3) {
      quarter = 'Q1';
    } else if (month >= 4 && month <= 6) {
      quarter = 'Q2';
    } else if (month >= 7 && month <= 9) {
      quarter = 'Q3';
    } else if (month >= 10 && month <= 12) {
      quarter = 'Q4';
    } else {
      return ''; // Invalid month
    }

    // Return the quarter label with the full year
    return "$quarter$year";
  } catch (e) {
    print("Error parsing period '$period': $e");
    return '';
  }
}

  // Same processing functions as the annual controller
 List<FinancialStatementModel> _processFinancialData(
    Map<String, Map<String, dynamic>> dataByQuarter,
    Map<String, dynamic> structuredMapping) {
  // First, create a map of item name -> Map<quarter, value>
  Map<String, Map<String, String>> valueMap = {};

  // We need to maintain a GLOBAL hierarchy map that combines structures from all quarters
  Map<String, List<String>> globalHierarchyMap = {};

  // Process each quarter's data and fill valueMap
  dataByQuarter.forEach((quarter, data) {
    Map<String, List<String>> quarterHierarchy = {};

    // Check if this is a placeholder (missing data)
    if (data.containsKey('placeholder')) {
      // For missing quarters, we'll leave values as '-' (handled later)
    } else {
      // Process through structured mapping for real data
      _extractValuesFromMapping(structuredMapping, data, quarter, valueMap, quarterHierarchy, "");
    }

    // Merge this quarter's hierarchy into the global hierarchy
    quarterHierarchy.forEach((parent, children) {
      globalHierarchyMap.putIfAbsent(parent, () => []);
      for (var child in children) {
        if (!globalHierarchyMap[parent]!.contains(child)) {
          globalHierarchyMap[parent]!.add(child);
        }
      }
    });
  });


  // Now build top-level models
  List<FinancialStatementModel> result = [];

  // Find all top-level items
  List<String> topLevelNames = globalHierarchyMap[""] ?? [];

  // Create models for top-level items
  for (var name in topLevelNames) {
    for (var quarter in dataByQuarter.keys) {
      String originalValue = '-'; // Default value for all quarters
      if (!dataByQuarter[quarter]!.containsKey('placeholder') &&
          valueMap.containsKey(name) &&
          valueMap[name]!.containsKey(quarter)) {
        originalValue = valueMap[name]![quarter]!;
      }

      result.add(FinancialStatementModel(
        name: name,
        year: quarter, // Using 'year' field for quarter
        originalValue: originalValue,
        subItems: _buildSubItemsWithGlobalHierarchy(name, quarter, valueMap, globalHierarchyMap),
      ));
    }
  }

  return result;
}

 List<FinancialStatementModel> _buildSubItemsWithGlobalHierarchy(
    String parentName,
    String quarter,
    Map<String, Map<String, String>> valueMap,
    Map<String, List<String>> globalHierarchyMap) {
  List<FinancialStatementModel> result = [];

  // Get children of this parent from the global hierarchy
  List<String>? children = globalHierarchyMap[parentName];

  if (children == null || children.isEmpty) {
    return result;
  }

  // Build model for each child
  for (var childName in children) {
    String childValue = '-'; // Default to '-' for missing data
    if (valueMap.containsKey(childName) && valueMap[childName]!.containsKey(quarter)) {
      childValue = valueMap[childName]![quarter]!;
    }

    // Debug for subitems

    result.add(FinancialStatementModel(
      name: childName,
      year: quarter,
      originalValue: childValue,
      isSubItem: true,
      subItems: _buildSubItemsWithGlobalHierarchy(childName, quarter, valueMap, globalHierarchyMap),
    ));
  }

  return result;
}

  void _extractValuesFromMapping(
      Map<String, dynamic> mapping,
      Map<String, dynamic> data,
      String quarter,
      Map<String, Map<String, String>> valueMap,
      Map<String, List<String>> hierarchyMap,
      String parent) {
    
 
    
    mapping.forEach((key, value) {
      if (value is String) {
        // Simple key-value mapping
        String itemName = value;
        String itemValue = data[key]?.toString() ?? '-';
        
        // Debug output
        
        // Add to value map
        valueMap.putIfAbsent(itemName, () => {});
        valueMap[itemName]![quarter] = itemValue;
        
        // Add to hierarchy map for ALL quarters, not just current quarter
        hierarchyMap.putIfAbsent(parent, () => []);
        if (!hierarchyMap[parent]!.contains(itemName)) {
          hierarchyMap[parent]!.add(itemName);
        }
      } else if (value is Map) {
        
        String label = value['label'];
        String valueKey = value['valueKey'];
        
        // Add this item
        String itemValue = data[valueKey]?.toString() ?? '-';
        
        // Debug output
        
        valueMap.putIfAbsent(label, () => {});
        valueMap[label]![quarter] = itemValue;
        
        // Add to hierarchy for ALL quarters
        hierarchyMap.putIfAbsent(parent, () => []);
        if (!hierarchyMap[parent]!.contains(label)) {
          hierarchyMap[parent]!.add(label);
        }
        
        // Process sub-items
        if (value.containsKey('subItems')) {
          _extractValuesFromMapping(value['subItems'], data, quarter, valueMap, hierarchyMap, label);
        }
      }
    });
  }
}

// Reuse the FinancialStatementModel and helper function from annual controller
class FinancialStatementModel {
  final String name;
  final String year; // For quarterly, this will store quarter info
  final String originalValue;
  final bool isSubItem;
  final List<FinancialStatementModel> subItems;

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
    return 'Name: $name, Quarter: $year, Value: $originalValue, IsSubItem: $isSubItem';
  }
}

String getShortened(String value) {
  // Try to parse the string value
  double? numValue = double.tryParse(value);
  
  // Return original value if parsing fails
  if (numValue == null) return value;
  
  // Work with absolute value for calculations (remove minus sign)
  numValue = numValue.abs();
  
  // Multiply by 10 lakh 
  numValue = numValue * 1000000;
  
  // Format based on magnitude (without sign)
  if (numValue >= 1e12) {
    return (numValue / 1e12).toStringAsFixed(1) + " T"; 
  } else if (numValue >= 1e9) {
    return (numValue / 1e9).toStringAsFixed(1) + " B"; 
  } else if (numValue >= 1e6) {
    return (numValue / 1e6).toStringAsFixed(1) + " M"; 
  } else {
    return numValue.toStringAsFixed(2); // Keep the value without sign
  }
}