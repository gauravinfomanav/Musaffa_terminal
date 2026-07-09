class RevenueBreakdownItem {
  const RevenueBreakdownItem({
    required this.region,
    required this.revenue,
    this.percentage,
  });

  final String region;
  final num revenue;
  final double? percentage;
}

class RevenueBreakdownModel {
  const RevenueBreakdownModel({
    required this.period,
    required this.items,
  });

  final String period;
  final List<RevenueBreakdownItem> items;
}
