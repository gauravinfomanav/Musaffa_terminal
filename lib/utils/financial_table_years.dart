/// Shared helpers for year/period columns on financial **data tables**.
///
/// Charts must keep their own chronological (oldest → newest) ordering.
/// Table column builders should use [descendingForDisplay] so headers read
/// latest → oldest without affecting YoY/CAGR math that assumes ascending.
class FinancialTableYears {
  const FinancialTableYears._();

  /// Returns a new list sorted latest → oldest for table column display.
  ///
  /// Works for fiscal years (`"2025"`) and quarter labels (`"2025-Q3"`,
  /// `"Q3 2025"`, etc.) via lexicographic compare, which matches the
  /// ascending order already used elsewhere in this codebase.
  static List<String> descendingForDisplay(Iterable<String> periods) {
    final List<String> sorted = periods.toList()
      ..sort((String a, String b) => b.compareTo(a));
    return sorted;
  }
}
