class AssignmentHolding {
  final String? id;
  final String ticker;
  final String? company;
  final String? sector;
  final String? assetType;
  final double allocationPercent;
  final double allocationAmount;
  final double currentPrice;
  final double quantity;

  AssignmentHolding({
    this.id,
    required this.ticker,
    this.company,
    this.sector,
    this.assetType,
    required this.allocationPercent,
    required this.allocationAmount,
    required this.currentPrice,
    required this.quantity,
  });

  factory AssignmentHolding.fromJson(Map<String, dynamic> json) {
    return AssignmentHolding(
      id: json['id'] as String?,
      ticker: json['ticker'] as String? ?? '',
      company: json['company'] as String?,
      sector: json['sector'] as String?,
      assetType: json['asset_type'] as String?,
      allocationPercent:
          (json['allocation_percent'] as num?)?.toDouble() ?? 0,
      allocationAmount:
          (json['allocation_amount'] as num?)?.toDouble() ?? 0,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AssignmentPreview {
  final String modelPortfolioId;
  final String modelPortfolioName;
  final double investmentAmount;
  final String currency;
  final double totalAllocationPercent;
  final List<AssignmentHolding> holdings;

  AssignmentPreview({
    required this.modelPortfolioId,
    required this.modelPortfolioName,
    required this.investmentAmount,
    required this.currency,
    required this.totalAllocationPercent,
    required this.holdings,
  });

  factory AssignmentPreview.fromJson(Map<String, dynamic> json) {
    return AssignmentPreview(
      modelPortfolioId: json['model_portfolio_id'] as String? ?? '',
      modelPortfolioName: json['model_portfolio_name'] as String? ?? '',
      investmentAmount:
          (json['investment_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      totalAllocationPercent:
          (json['total_allocation_percent'] as num?)?.toDouble() ?? 0,
      holdings: (json['holdings'] as List<dynamic>?)
              ?.map((h) => AssignmentHolding.fromJson(h as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class PortfolioAssignment {
  final String id;
  final String? assignmentCode;
  final String modelPortfolioId;
  final String modelPortfolioName;
  final String customerId;
  final String customerName;
  final String? customerEmail;
  final double investmentAmount;
  final String currency;
  final String status;
  final double totalAllocationPercent;
  final int holdingsCount;
  final List<AssignmentHolding> holdings;
  final String? analystNotes;
  final String? effectiveDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PortfolioAssignment({
    required this.id,
    this.assignmentCode,
    required this.modelPortfolioId,
    required this.modelPortfolioName,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    required this.investmentAmount,
    this.currency = 'USD',
    required this.status,
    required this.totalAllocationPercent,
    required this.holdingsCount,
    this.holdings = const [],
    this.analystNotes,
    this.effectiveDate,
    this.createdAt,
    this.updatedAt,
  });

  factory PortfolioAssignment.fromJson(Map<String, dynamic> json) {
    return PortfolioAssignment(
      id: json['id'] as String? ?? '',
      assignmentCode: json['assignment_code'] as String?,
      modelPortfolioId: json['model_portfolio_id'] as String? ?? '',
      modelPortfolioName: json['model_portfolio_name'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerEmail: json['customer_email'] as String?,
      investmentAmount:
          (json['investment_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'draft',
      totalAllocationPercent:
          (json['total_allocation_percent'] as num?)?.toDouble() ?? 0,
      holdingsCount: (json['holdings_count'] as num?)?.toInt() ?? 0,
      holdings: (json['holdings'] as List<dynamic>?)
              ?.map((h) => AssignmentHolding.fromJson(h as Map<String, dynamic>))
              .toList() ??
          const [],
      analystNotes: json['analyst_notes'] as String?,
      effectiveDate: json['effective_date'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class PortfolioAssignmentSummary {
  final String id;
  final String? assignmentCode;
  final String customerName;
  final String modelPortfolioName;
  final double investmentAmount;
  final String currency;
  final double allocationPercent;
  final int holdingsCount;
  final String status;
  final DateTime? lastUpdated;
  final DateTime? createdAt;

  PortfolioAssignmentSummary({
    required this.id,
    this.assignmentCode,
    required this.customerName,
    required this.modelPortfolioName,
    required this.investmentAmount,
    this.currency = 'USD',
    required this.allocationPercent,
    required this.holdingsCount,
    required this.status,
    this.lastUpdated,
    this.createdAt,
  });

  factory PortfolioAssignmentSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioAssignmentSummary(
      id: json['id'] as String? ?? '',
      assignmentCode: json['assignment_code'] as String?,
      customerName: json['customer_name'] as String? ?? '',
      modelPortfolioName: json['model_portfolio_name'] as String? ?? '',
      investmentAmount:
          (json['investment_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      allocationPercent:
          (json['allocation_percent'] as num?)?.toDouble() ?? 0,
      holdingsCount: (json['holdings_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      lastUpdated: _parseDate(json['last_updated']),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}
