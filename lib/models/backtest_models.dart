import 'package:musaffa_terminal/models/historical_price_model.dart';

class BacktestResult {
  final double initialInvestment;
  final double currentValue;
  final double totalReturn;
  final double totalReturnPercent;
  final double annualizedReturn;
  final List<StockPerformance> stockPerformances;
  final DateTime backtestDate;
  final DateTime currentDate;

  BacktestResult({
    required this.initialInvestment,
    required this.currentValue,
    required this.totalReturn,
    required this.totalReturnPercent,
    required this.annualizedReturn,
    required this.stockPerformances,
    required this.backtestDate,
    required this.currentDate,
  });

  /// Get best performing stock
  StockPerformance? get bestPerformer {
    if (stockPerformances.isEmpty) return null;
    return stockPerformances.reduce((a, b) => 
      a.gainPercent > b.gainPercent ? a : b
    );
  }

  /// Get worst performing stock
  StockPerformance? get worstPerformer {
    if (stockPerformances.isEmpty) return null;
    return stockPerformances.reduce((a, b) => 
      a.gainPercent < b.gainPercent ? a : b
    );
  }

  /// Get number of winning stocks
  int get winningStocks {
    return stockPerformances.where((stock) => stock.gainPercent > 0).length;
  }

  /// Get number of losing stocks
  int get losingStocks {
    return stockPerformances.where((stock) => stock.gainPercent < 0).length;
  }
}

class StockPerformance {
  final String symbol;
  final double historicalPrice;
  final double currentPrice;
  final double sharesBought;
  final double currentValue;
  final double gain;
  final double gainPercent;

  StockPerformance({
    required this.symbol,
    required this.historicalPrice,
    required this.currentPrice,
    required this.sharesBought,
    required this.currentValue,
    required this.gain,
    required this.gainPercent,
  });

  /// Get formatted gain percentage
  String get formattedGainPercent {
    final sign = gainPercent >= 0 ? '+' : '';
    return '$sign${gainPercent.toStringAsFixed(2)}%';
  }

  /// Get formatted gain amount
  String get formattedGain {
    final sign = gain >= 0 ? '+' : '';
    return '$sign\$${gain.toStringAsFixed(2)}';
  }

  /// Get formatted current value
  String get formattedCurrentValue {
    return '\$${currentValue.toStringAsFixed(2)}';
  }

  /// Get formatted shares bought
  String get formattedSharesBought {
    return sharesBought.toStringAsFixed(4);
  }
}
