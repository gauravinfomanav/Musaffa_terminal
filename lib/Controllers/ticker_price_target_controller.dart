import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/price_target_chart_model.dart';
import 'package:musaffa_terminal/models/price_target_model.dart';
import 'package:musaffa_terminal/services/finnhub/price_target_service.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';

class TickerPriceTargetController extends ChangeNotifier {
  TickerPriceTargetController({
    PriceTargetService? priceTargetService,
    StockCandleService? candleService,
  })  : _priceTargetService = priceTargetService ?? PriceTargetService(),
        _candleService = candleService ?? StockCandleService();

  final PriceTargetService _priceTargetService;
  final StockCandleService _candleService;

  static const Duration _twelveMonths = Duration(days: 365);

  bool _isLoading = false;
  String? _error;
  String? _loadedSymbol;
  PriceTargetModel? _priceTarget;
  PriceTargetChartData? _chartData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  PriceTargetModel? get priceTarget => _priceTarget;
  PriceTargetChartData? get chartData => _chartData;
  bool get hasData => _priceTarget != null && _chartData != null;

  Future<void> load(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }

    if (!forceRefresh &&
        _loadedSymbol == normalized &&
        _priceTarget != null &&
        _chartData != null) {
      return;
    }

    _loadedSymbol = normalized;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _priceTargetService.fetchForSymbol(normalized),
          _candleService.fetchLastTwelveMonths(
            normalized,
            forceRefresh: forceRefresh,
          ),
        ],
      );

      final PriceTargetModel? target = results[0] as PriceTargetModel?;
      final List<PriceDataPoint> historical =
          results[1] as List<PriceDataPoint>;

      if (target == null) {
        _priceTarget = null;
        _chartData = null;
        _error = 'No analyst price target data found';
        return;
      }

      if (historical.isEmpty) {
        _priceTarget = target;
        _chartData = null;
        _error = 'No historical price data available';
        return;
      }

      _priceTarget = target;
      _chartData = _buildChartData(target, historical);
      _error = null;
    } catch (error) {
      _priceTarget = null;
      _chartData = null;
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  PriceTargetChartData _buildChartData(
    PriceTargetModel target,
    List<PriceDataPoint> historical,
  ) {
    final DateTime now = DateTime.now();
    final DateTime historyStart = now.subtract(_twelveMonths);
    final List<PriceDataPoint> trimmedHistory = historical
        .where(
          (PriceDataPoint point) =>
              !point.date.isBefore(historyStart) && !point.date.isAfter(now),
        )
        .toList();

    final List<PriceDataPoint> history =
        trimmedHistory.isNotEmpty ? trimmedHistory : List<PriceDataPoint>.from(historical);

    final PriceDataPoint anchor = history.last;
    final DateTime forecastEndDate = anchor.date.add(_twelveMonths);

    final List<PriceTargetForecastPoint> targetHigh = _buildForecastLine(
      anchor: anchor,
      forecastEndDate: forecastEndDate,
      targetPrice: target.targetHigh,
      targetType: 'High',
      numberAnalysts: target.numberAnalysts,
      lastUpdated: target.lastUpdated,
    );
    final List<PriceTargetForecastPoint> targetMean = _buildForecastLine(
      anchor: anchor,
      forecastEndDate: forecastEndDate,
      targetPrice: target.targetMean,
      targetType: 'Mean',
      numberAnalysts: target.numberAnalysts,
      lastUpdated: target.lastUpdated,
    );
    final List<PriceTargetForecastPoint> targetLow = _buildForecastLine(
      anchor: anchor,
      forecastEndDate: forecastEndDate,
      targetPrice: target.targetLow,
      targetType: 'Low',
      numberAnalysts: target.numberAnalysts,
      lastUpdated: target.lastUpdated,
    );

    final List<double> yValues = <double>[
      ...history.map((PriceDataPoint point) => point.value),
      if (target.targetHigh > 0) target.targetHigh,
      if (target.targetMean > 0) target.targetMean,
      if (target.targetLow > 0) target.targetLow,
    ];

    final double rawMin = yValues.reduce(math.min);
    final double rawMax = yValues.reduce(math.max);
    final double padding = (rawMax - rawMin) * 0.08;
    final double yMin = math.max(0, rawMin - padding);
    final double yMax = rawMax + padding;

    return PriceTargetChartData(
      historical: history,
      targetHigh: targetHigh,
      targetMean: targetMean,
      targetLow: targetLow,
      anchorDate: anchor.date,
      forecastEndDate: forecastEndDate,
      yMin: yMin,
      yMax: yMax,
    );
  }

  List<PriceTargetForecastPoint> _buildForecastLine({
    required PriceDataPoint anchor,
    required DateTime forecastEndDate,
    required double targetPrice,
    required String targetType,
    required int numberAnalysts,
    required DateTime? lastUpdated,
  }) {
    if (targetPrice <= 0) {
      return <PriceTargetForecastPoint>[];
    }

    return <PriceTargetForecastPoint>[
      PriceTargetForecastPoint(
        date: anchor.date,
        price: anchor.value,
        targetType: targetType,
        numberAnalysts: numberAnalysts,
        lastUpdated: lastUpdated,
      ),
      PriceTargetForecastPoint(
        date: forecastEndDate,
        price: targetPrice,
        targetType: targetType,
        numberAnalysts: numberAnalysts,
        lastUpdated: lastUpdated,
        isEndPoint: true,
      ),
    ];
  }
}
