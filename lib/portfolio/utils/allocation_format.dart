/// Rounding tolerance for treating totals as exactly 100%.
const double kAllocationBalanceTolerance = 0.01;

/// Formats model portfolio allocation percentages for display.
String formatAllocationPercent(double value) {
  final abs = value.abs();
  if ((abs - abs.roundToDouble()).abs() < 0.001) {
    return '${abs.toStringAsFixed(0)}%';
  }
  return '${abs.toStringAsFixed(1)}%';
}

/// Whether total allocation equals 100% within [kAllocationBalanceTolerance].
bool isAllocationBalanced(double totalPercent) {
  return (totalPercent - 100.0).abs() < kAllocationBalanceTolerance;
}

/// Whether total allocation exceeds 100% beyond the balance tolerance.
bool isAllocationOver(double totalPercent) {
  return totalPercent - 100.0 >= kAllocationBalanceTolerance;
}

/// Whether total allocation is below 100% beyond the balance tolerance.
bool isAllocationUnder(double totalPercent) {
  return 100.0 - totalPercent >= kAllocationBalanceTolerance;
}

/// Remaining % to reach 100%; 0 when balanced or over.
double allocationRemainingPercent(double totalPercent) {
  if (isAllocationBalanced(totalPercent) || isAllocationOver(totalPercent)) {
    return 0;
  }
  return 100.0 - totalPercent;
}

/// Amount over 100%; 0 unless meaningfully over-allocated.
double allocationOverPercent(double totalPercent) {
  if (!isAllocationOver(totalPercent)) return 0;
  return totalPercent - 100.0;
}
