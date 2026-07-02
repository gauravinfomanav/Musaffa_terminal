import 'package:musaffa_terminal/charts/models/financial_statement_type.dart';

/// Human-readable labels and preferred field order per statement type.
class QuarterlyMetricLabels {
  const QuarterlyMetricLabels._();

  static const Map<String, String> _incomeStatement = <String, String>{
    'revenue': 'Total Revenue',
    'costOfGoodsSold': 'Cost of Goods Sold',
    'grossIncome': 'Gross Profit',
    'researchDevelopment': 'Research and Development',
    'sgaExpense': 'Selling, General & Adm',
    'totalOperatingExpense': 'Total Operating Expenses',
    'ebit': 'Earnings Before Interest and Taxes (EBIT)',
    'totalOtherIncomeExpenseNet': 'Total Other Income (Expense), Net',
    'pretaxIncome': 'Income Before Taxes',
    'provisionforIncomeTaxes': 'Provision for Income Taxes',
    'netIncomeAfterTaxes': 'Net Income After Taxes',
    'netIncome': 'Net Income',
    'dilutedAverageSharesOutstanding': 'Average Shares Outstanding (diluted)',
    'dilutedEPS': 'Earnings Per Share (diluted)',
  };

  static const Map<String, String> _balanceSheet = <String, String>{
    'totalAssets': 'Total Assets',
    'currentAssets': 'Total Current Assets',
    'cashShortTermInvestments': 'Cash & Short-Term Investments',
    'cash': 'Cash',
    'cashEquivalents': 'Cash Equivalents',
    'shortTermInvestments': 'Short-Term Investments',
    'accountsReceivables': 'Accounts Receivables',
    'totalReceivables': 'Total Receivables',
    'otherReceivables': 'Other Receivables',
    'inventory': 'Inventory',
    'otherCurrentAssets': 'Other Current Assets',
    'propertyPlantEquipment': 'Property, Plant & Equipment',
    'accumulatedDepreciation': 'Accumulated Depreciation',
    'longTermInvestments': 'Long-Term Investments',
    'otherLongTermAssets': 'Other Long-Term Assets',
    'intangiblesAssets': 'Intangible Assets',
    'totalLiabilities': 'Total Liabilities',
    'currentLiabilities': 'Total Current Liabilities',
    'accountsPayable': 'Accounts Payable',
    'accruedLiability': 'Accrued Liability',
    'shortTermDebt': 'Short-Term Debt',
    'currentPortionLongTermDebt': 'Current Portion of Long-Term Debt',
    'otherCurrentliabilities': 'Other Current Liabilities',
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
    'tangibleBookValueperShare': 'Tangible Book Value per Share',
    'unrealizedProfitLossSecurity': 'Unrealized Profit/Loss on Securities',
    'deferredRevenue': 'Deferred Revenue',
  };

  static const Map<String, String> _cashFlow = <String, String>{
    'netIncomeStartingLine': 'Net Income',
    'netIncome': 'Net Income',
    'netOperatingCashFlow': 'Net Cash from Operating Activities',
    'stockBasedCompensation': 'Stock-Based Compensation Expense',
    'depreciationAmortization': 'Depreciation & Amortization',
    'otherFundsNonCashItems': 'Other Non-Cash Items',
    'changesinWorkingCapital': 'Change in Working Capital',
    'netInvestingCashFlow': 'Net Cash from Investing Activities',
    'capex': 'Capital Expenditure',
    'otherInvestingCashFlowItemsTotal': 'Other Investing Cash Flow Items',
    'netCashFinancingActivities': 'Net Cash from Financing Activities',
    'issuanceReductionDebtNet': 'Net Issuance (Reduction) of Debt',
    'issuanceReductionCapitalStock': 'Net Issuance (Reduction) of Capital Stock',
    'otherFundsFinancingItems': 'Other Financing Cash Flow Items',
    'cashDividendsPaid': 'Payments for Dividends and Dividend Equivalents',
    'cashTaxesPaid': 'Payments for Taxes',
    'cashInterestPaid': 'Cash Interest Paid',
    'deferredTaxesInvestmentTaxCredit': 'Deferred Taxes & Investment Tax Credit',
    'changeinCash': 'Change in Cash',
    'fcf': 'Free Cash Flow',
  };

  static const List<String> _incomeStatementOrder = <String>[
    'revenue',
    'costOfGoodsSold',
    'grossIncome',
    'researchDevelopment',
    'sgaExpense',
    'totalOperatingExpense',
    'ebit',
    'totalOtherIncomeExpenseNet',
    'pretaxIncome',
    'provisionforIncomeTaxes',
    'netIncomeAfterTaxes',
    'netIncome',
    'dilutedAverageSharesOutstanding',
    'dilutedEPS',
  ];

  static const List<String> _balanceSheetOrder = <String>[
    'totalAssets',
    'currentAssets',
    'cashShortTermInvestments',
    'cash',
    'cashEquivalents',
    'shortTermInvestments',
    'accountsReceivables',
    'totalReceivables',
    'otherReceivables',
    'inventory',
    'otherCurrentAssets',
    'propertyPlantEquipment',
    'accumulatedDepreciation',
    'longTermInvestments',
    'otherLongTermAssets',
    'intangiblesAssets',
    'totalLiabilities',
    'currentLiabilities',
    'accountsPayable',
    'accruedLiability',
    'shortTermDebt',
    'currentPortionLongTermDebt',
    'otherCurrentliabilities',
    'longTermDebt',
    'netDebt',
    'otherLiabilities',
    'totalDebt',
    'liabilitiesShareholdersEquity',
    'totalEquity',
    'commonStock',
    'additionalPaidInCapital',
    'retainedEarnings',
    'otherEquity',
    'sharesOutstanding',
    'tangibleBookValueperShare',
    'unrealizedProfitLossSecurity',
    'deferredRevenue',
  ];

  static const List<String> _cashFlowOrder = <String>[
    'netIncomeStartingLine',
    'netIncome',
    'netOperatingCashFlow',
    'stockBasedCompensation',
    'depreciationAmortization',
    'otherFundsNonCashItems',
    'changesinWorkingCapital',
    'netInvestingCashFlow',
    'capex',
    'otherInvestingCashFlowItemsTotal',
    'netCashFinancingActivities',
    'issuanceReductionDebtNet',
    'issuanceReductionCapitalStock',
    'otherFundsFinancingItems',
    'cashDividendsPaid',
    'cashTaxesPaid',
    'cashInterestPaid',
    'deferredTaxesInvestmentTaxCredit',
    'changeinCash',
    'fcf',
  ];

  static String titleFor(String key, FinancialStatementType statement) {
    final Map<String, String> labels = switch (statement) {
      FinancialStatementType.ic => _incomeStatement,
      FinancialStatementType.bs => _balanceSheet,
      FinancialStatementType.cf => _cashFlow,
    };
    return labels[key] ?? _formatCamelCase(key);
  }

  static List<String> orderedKeys(
    Set<String> availableKeys,
    FinancialStatementType statement,
  ) {
    final List<String> preferred = switch (statement) {
      FinancialStatementType.ic => _incomeStatementOrder,
      FinancialStatementType.bs => _balanceSheetOrder,
      FinancialStatementType.cf => _cashFlowOrder,
    };

    final List<String> ordered = <String>[];
    for (final String key in preferred) {
      if (availableKeys.contains(key)) {
        ordered.add(key);
      }
    }

    final List<String> remaining = availableKeys
        .where((String key) => !ordered.contains(key))
        .toList()
      ..sort();
    ordered.addAll(remaining);
    return ordered;
  }

  static String _formatCamelCase(String key) {
    final String spaced = key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (Match match) => ' ${match[1]}',
        )
        .replaceAllMapped(
          RegExp(r'([a-z])([0-9])'),
          (Match match) => '${match[1]} ${match[2]}',
        )
        .trim();
    if (spaced.isEmpty) {
      return key;
    }
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
