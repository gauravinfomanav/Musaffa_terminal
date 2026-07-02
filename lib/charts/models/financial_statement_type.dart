/// Financial statement types supported by the Infomanav `statement` query param.
enum FinancialStatementType {
  ic('ic', 'Income Statement'),
  bs('bs', 'Balance Sheet'),
  cf('cf', 'Cash Flow');

  const FinancialStatementType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FinancialStatementType fromIndex(int index) {
    return FinancialStatementType.values[index.clamp(0, 2)];
  }
}
