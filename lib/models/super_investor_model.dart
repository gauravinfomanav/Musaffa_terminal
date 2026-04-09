class SuperInvestorPortfolio {
  String? cikId;
  String? symbol;
  int? share;
  int? change;
  double? value;
  double? percentage;
  double? percentageChange;
  String? reportDate;
  String? filingDate;
  String? putCall;

  SuperInvestorPortfolio({
    this.cikId,
    this.symbol,
    this.share,
    this.change,
    this.value,
    this.percentage,
    this.percentageChange,
    this.reportDate,
    this.filingDate,
    this.putCall,
  });

  SuperInvestorPortfolio.fromJson(Map<String, dynamic> json) {
    cikId = json['cik_id']?.toString();
    symbol = json['symbol'];
    share = json['share'] is int ? json['share'] : int.tryParse(json['share']?.toString() ?? '0');
    change = json['change'] is int ? json['change'] : int.tryParse(json['change']?.toString() ?? '0');
    value = json['value'] is double
        ? json['value']
        : double.tryParse(json['value']?.toString() ?? '0');
    percentage = json['percentage'] is double
        ? json['percentage']
        : double.tryParse(json['percentage']?.toString() ?? '0');
    percentageChange = json['percentage_change'] is double
      ? json['percentage_change']
      : double.tryParse(json['percentage_change']?.toString() ?? '0');
    reportDate = json['report_date'];
    filingDate = json['filling_date'] ?? json['filing_date'];
    putCall = json['putCall'] ?? json['put_call'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cik_id'] = cikId;
    data['symbol'] = symbol;
    data['share'] = share;
    data['change'] = change;
    data['value'] = value;
    data['percentage'] = percentage;
    data['percentage_change'] = percentageChange;
    data['report_date'] = reportDate;
    data['filling_date'] = filingDate;
    data['putCall'] = putCall;
    return data;
  }
}

class SuperInvestor {
  String? cik;
  String? manager;
  String? profileImg;
  String? profile;
  String? philosophy;
  double? totalAmount;
  double? halalPercentage;
  String? reportDate;

  SuperInvestor({
    this.cik,
    this.manager,
    this.profileImg,
    this.profile,
    this.philosophy,
    this.totalAmount,
    this.halalPercentage,
    this.reportDate,
  });

  SuperInvestor.fromJson(Map<String, dynamic> json) {
    cik = json['cik']?.toString();
    manager = json['manager'];
    profileImg = json['profileImg'];
    profile = json['profile'];
    philosophy = json['philosophy'];
    totalAmount = json['total_amount'] is double
        ? json['total_amount']
        : double.tryParse(json['total_amount']?.toString() ?? '0');
    halalPercentage = json['halal_percentage'] is double
        ? json['halal_percentage']
        : double.tryParse(json['halal_percentage']?.toString() ?? '0');
    reportDate = json['report_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cik'] = cik;
    data['manager'] = manager;
    data['profileImg'] = profileImg;
    data['profile'] = profile;
    data['philosophy'] = philosophy;
    data['total_amount'] = totalAmount;
    data['halal_percentage'] = halalPercentage;
    data['report_date'] = reportDate;
    return data;
  }
}

class MergedSuperInvestor {
  String? manager;
  String? profileImg;
  int? share;
  int? change;
  int? previousShares;
  double? value;
  double? avgPrice;
  double? previousValue;
  double? valueChange;
  double? percentage;
  double? percentageChange;
  String? reportDate;
  String? filingDate;
  String? putCall;
  double? totalAmount;
  double? halalPercentage;
  String? trend;
  String? convictionLevel;
  String? transactionType; // "Buy", "Sell", "Hold"

  MergedSuperInvestor({
    this.manager,
    this.profileImg,
    this.share,
    this.change,
    this.previousShares,
    this.value,
    this.avgPrice,
    this.previousValue,
    this.valueChange,
    this.percentage,
    this.percentageChange,
    this.reportDate,
    this.filingDate,
    this.putCall,
    this.totalAmount,
    this.halalPercentage,
    this.trend,
    this.convictionLevel,
    this.transactionType,
  });

  static MergedSuperInvestor merge(
    SuperInvestorPortfolio portfolio,
    SuperInvestor investor,
  ) {
    final int? share = portfolio.share;
    final int? change = portfolio.change;
    final double? value = portfolio.value;
    final double? percentage = portfolio.percentage;
    final double? percentageChange = portfolio.percentageChange;

    final int? previousShares = (share == null && change == null)
        ? null
        : (share ?? 0) - (change ?? 0);

    final double? avgPrice = (share != null && share > 0 && value != null)
        ? value / share
        : null;

    double? previousValue;
    if (value != null && percentageChange != null) {
      final denominator = 1 + (percentageChange / 100);
      if (denominator != 0) {
        previousValue = value / denominator;
      }
    }

    final double? valueChange =
        (value != null && previousValue != null) ? value - previousValue : null;

    final String trend;
    if (share != null && share == 0) {
      trend = 'Exited';
    } else if ((change ?? 0) > 0) {
      trend = 'Increasing';
    } else if ((change ?? 0) < 0) {
      trend = 'Decreasing';
    } else {
      trend = 'No Change';
    }

    final String? convictionLevel;
    if (percentage == null) {
      convictionLevel = null;
    } else if (percentage >= 10) {
      convictionLevel = 'High';
    } else if (percentage >= 3) {
      convictionLevel = 'Medium';
    } else {
      convictionLevel = 'Low';
    }

    final transactionType = portfolio.change == null
        ? 'Hold'
        : portfolio.change! > 0
            ? 'Buy'
            : portfolio.change! < 0
                ? 'Sell'
                : 'Hold';

    return MergedSuperInvestor(
      manager: investor.manager,
      profileImg: investor.profileImg,
      share: share,
      change: change,
      previousShares: previousShares,
      value: value,
      avgPrice: avgPrice,
      previousValue: previousValue,
      valueChange: valueChange,
      percentage: percentage,
      percentageChange: percentageChange,
      reportDate: portfolio.reportDate,
      filingDate: portfolio.filingDate,
      putCall: portfolio.putCall,
      totalAmount: investor.totalAmount,
      halalPercentage: investor.halalPercentage,
      trend: trend,
      convictionLevel: convictionLevel,
      transactionType: transactionType,
    );
  }
}
