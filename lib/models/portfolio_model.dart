class PortfolioHolding {
  final String? id;
  final String ticker;
  final String? company;
  final String? exchange;
  final String? sector;
  final double currentPrice;
  final double targetPrice;
  final int quantity;
  final double allocationPercent;
  final double allocationAmount;
  final double? marketCap;
  final double? peRatio;
  final String? notes;
  final String? assetType;
  final String? conviction;
  final String? holdingStatus;
  final String? investmentThesis;
  final String? riskNotes;
  final String? bullCase;
  final String? bearCase;
  final DateTime? reviewDate;
  final String? reasonForSelection;

  PortfolioHolding({
    this.id,
    required this.ticker,
    this.company,
    this.exchange,
    this.sector,
    required this.currentPrice,
    required this.targetPrice,
    required this.quantity,
    required this.allocationPercent,
    required this.allocationAmount,
    this.marketCap,
    this.peRatio,
    this.notes,
    this.assetType,
    this.conviction,
    this.holdingStatus,
    this.investmentThesis,
    this.riskNotes,
    this.bullCase,
    this.bearCase,
    this.reviewDate,
    this.reasonForSelection,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      id: json['id'] as String?,
      ticker: json['ticker'] as String? ?? '',
      company: json['company'] as String?,
      exchange: json['exchange'] as String?,
      sector: json['sector'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      targetPrice: (json['target_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      allocationPercent: (json['allocation_percent'] as num?)?.toDouble() ?? 0.0,
      allocationAmount: (json['allocation_amount'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      peRatio: (json['pe_ratio'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      assetType: json['asset_type'] as String?,
      conviction: json['conviction'] as String?,
      holdingStatus: json['holding_status'] as String? ?? json['status'] as String?,
      investmentThesis: json['investment_thesis'] as String?,
      riskNotes: json['risk_notes'] as String?,
      bullCase: json['bull_case'] as String?,
      bearCase: json['bear_case'] as String?,
      reviewDate: _parseOptionalDate(json['review_date']),
      reasonForSelection: json['reason_for_selection'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ticker': ticker,
      if (company != null) 'company': company,
      if (exchange != null) 'exchange': exchange,
      if (sector != null) 'sector': sector,
      'current_price': currentPrice,
      'target_price': targetPrice,
      'quantity': quantity,
      'allocation_percent': allocationPercent,
      'allocation_amount': allocationAmount,
      if (marketCap != null) 'market_cap': marketCap,
      if (peRatio != null) 'pe_ratio': peRatio,
      if (notes != null) 'notes': notes,
      if (assetType != null) 'asset_type': assetType,
      if (conviction != null) 'conviction': conviction,
      if (holdingStatus != null) 'holding_status': holdingStatus,
      if (investmentThesis != null) 'investment_thesis': investmentThesis,
      if (riskNotes != null) 'risk_notes': riskNotes,
      if (bullCase != null) 'bull_case': bullCase,
      if (bearCase != null) 'bear_case': bearCase,
      if (reviewDate != null) 'review_date': reviewDate!.toIso8601String(),
      if (reasonForSelection != null) 'reason_for_selection': reasonForSelection,
    };
  }
}

DateTime? _parseOptionalDate(dynamic dateData) {
  if (dateData == null) return null;
  if (dateData is String) {
    try {
      return DateTime.parse(dateData);
    } catch (_) {
      return null;
    }
  }
  if (dateData is Map && dateData.containsKey('_seconds')) {
    final seconds = dateData['_seconds'] as int;
    final nanoseconds = dateData['_nanoseconds'] as int? ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000 + (nanoseconds ~/ 1000000),
    );
  }
  return null;
}

class Portfolio {
  final String id;
  final String portfolioName;
  final String? portfolioCode;
  final String clientName;
  final int? clientAge;
  final String? riskProfile;
  final String? strategyType;
  final String? benchmark;
  final String? objective;
  final double initialCapital;
  final String? investmentHorizon;
  final double? expectedRateOfReturn;
  final String? commentary;
  final String? marketOutlook;
  final int? version;
  final double allocatedAmount;
  final double allocationPercent;
  final double estimatedReturns;
  final int holdingsCount;
  final List<PortfolioHolding> holdings;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final String? archiveReason;

  Portfolio({
    required this.id,
    required this.portfolioName,
    this.portfolioCode,
    required this.clientName,
    this.clientAge,
    this.riskProfile,
    this.strategyType,
    this.benchmark,
    this.objective,
    required this.initialCapital,
    this.investmentHorizon,
    this.expectedRateOfReturn,
    this.commentary,
    this.marketOutlook,
    this.version,
    required this.allocatedAmount,
    required this.allocationPercent,
    required this.estimatedReturns,
    required this.holdingsCount,
    required this.holdings,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.archiveReason,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'] as String? ?? '',
      portfolioName: json['portfolio_name'] as String? ?? '',
      portfolioCode: json['portfolio_code'] as String?,
      clientName: json['client_name'] as String? ?? '',
      clientAge: json['client_age'] as int?,
      riskProfile: json['risk_profile'] as String?,
      strategyType: json['strategy_type'] as String?,
      benchmark: json['benchmark'] as String?,
      objective: json['objective'] as String?,
      initialCapital: (json['initial_capital'] as num?)?.toDouble() ?? 0.0,
      investmentHorizon: json['investment_horizon'] as String?,
      expectedRateOfReturn: (json['expected_rate_of_return'] as num?)?.toDouble(),
      commentary: json['commentary'] as String?,
      marketOutlook: json['market_outlook'] as String?,
      version: (json['version'] as num?)?.toInt(),
      allocatedAmount: (json['allocated_amount'] as num?)?.toDouble() ?? 0.0,
      allocationPercent: (json['allocation_percent'] as num?)?.toDouble() ?? 0.0,
      estimatedReturns: (json['estimated_returns'] as num?)?.toDouble() ?? 0.0,
      holdingsCount: (json['holdings_count'] as int?) ?? 0,
      holdings: (json['holdings'] as List<dynamic>?)
              ?.map((h) => PortfolioHolding.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String? ?? 'draft',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      archivedAt: json['archived_at'] != null
          ? _parseDateTime(json['archived_at'])
          : null,
      archiveReason: json['archive_reason'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    
    if (dateData is String) {
      try {
        return DateTime.parse(dateData);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateData is Map) {
      // Handle Firestore timestamp format: {"_seconds": 1762149584, "_nanoseconds": 514000000}
      if (dateData.containsKey('_seconds')) {
        final seconds = dateData['_seconds'] as int;
        final nanoseconds = dateData['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      }
    } else if (dateData is int) {
      // Handle Unix timestamp
      return DateTime.fromMillisecondsSinceEpoch(dateData * 1000);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'portfolio_name': portfolioName,
      if (portfolioCode != null && portfolioCode!.isNotEmpty) 'portfolio_code': portfolioCode,
      'client_name': clientName,
      if (clientAge != null) 'client_age': clientAge,
      if (riskProfile != null) 'risk_profile': riskProfile,
      if (strategyType != null) 'strategy_type': strategyType,
      if (benchmark != null) 'benchmark': benchmark,
      if (objective != null) 'objective': objective,
      'initial_capital': initialCapital,
      if (investmentHorizon != null) 'investment_horizon': investmentHorizon,
      if (expectedRateOfReturn != null) 'expected_rate_of_return': expectedRateOfReturn,
      if (commentary != null) 'commentary': commentary,
      if (marketOutlook != null) 'market_outlook': marketOutlook,
      if (version != null) 'version': version,
      'holdings': holdings.map((h) => h.toJson()).toList(),
      if (status.isNotEmpty) 'status': status,
    };
  }
}

class PortfolioSummary {
  final String id;
  final String portfolioName;
  final String clientName;
  final double initialCapital;
  final double allocatedAmount;
  final double allocationPercent;
  final int holdingsCount;
  final double estimatedReturns;
  final String? investmentHorizon;
  final double? expectedRateOfReturn;
  final String? strategyType;
  final String? riskProfile;
  final String status;
  final DateTime lastUpdated;
  final DateTime createdAt;

  PortfolioSummary({
    required this.id,
    required this.portfolioName,
    required this.clientName,
    required this.initialCapital,
    required this.allocatedAmount,
    required this.allocationPercent,
    required this.holdingsCount,
    required this.estimatedReturns,
    this.investmentHorizon,
    this.expectedRateOfReturn,
    this.strategyType,
    this.riskProfile,
    required this.status,
    required this.lastUpdated,
    required this.createdAt,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      id: json['id'] as String? ?? '',
      portfolioName: json['portfolio_name'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      initialCapital: (json['initial_capital'] as num?)?.toDouble() ?? 0.0,
      allocatedAmount: (json['allocated_amount'] as num?)?.toDouble() ?? 0.0,
      allocationPercent: (json['allocation_percent'] as num?)?.toDouble() ?? 0.0,
      holdingsCount: (json['holdings_count'] as int?) ?? 0,
      estimatedReturns: (json['estimated_returns'] as num?)?.toDouble() ?? 0.0,
      investmentHorizon: json['investment_horizon'] as String?,
      expectedRateOfReturn: (json['expected_rate_of_return'] as num?)?.toDouble(),
      strategyType: json['strategy_type'] as String?,
      riskProfile: json['risk_profile'] as String?,
      status: json['status'] as String? ?? 'draft',
      lastUpdated: Portfolio._parseDateTime(json['last_updated'] ?? json['updated_at']),
      createdAt: Portfolio._parseDateTime(json['created_at']),
    );
  }
}

class PortfolioListResponse {
  final String status;
  final List<PortfolioSummary> portfolios;
  final PaginationInfo pagination;

  PortfolioListResponse({
    required this.status,
    required this.portfolios,
    required this.pagination,
  });

  factory PortfolioListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final portfoliosList = data['portfolios'] as List<dynamic>? ?? [];
    final paginationData = data['pagination'] as Map<String, dynamic>? ?? {};

    return PortfolioListResponse(
      status: json['status'] as String? ?? 'success',
      portfolios: portfoliosList
          .map((item) => PortfolioSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(paginationData),
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      itemsPerPage: (json['items_per_page'] as num?)?.toInt() ?? 20,
    );
  }
}

