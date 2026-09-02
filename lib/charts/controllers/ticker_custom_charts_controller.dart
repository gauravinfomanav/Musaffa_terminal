import 'dart:async';

import 'package:get/get.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';

enum PremiumPriceRange {
  oneDay('1D'),
  oneWeek('1W'),
  oneMonth('1M'),
  threeMonths('3M'),
  sixMonths('6M'),
  ytd('YTD'),
  oneYear('1Y'),
  fiveYears('5Y'),
  all('All');

  const PremiumPriceRange(this.label);

  final String label;

  static List<PremiumPriceRange> get valuesOrdered => PremiumPriceRange.values;
}

enum PremiumPriceChartMode { area, candlestick }

class TickerCustomChartsController extends GetxController {
  TickerCustomChartsController({StockCandleService? candleService})
      : _candleService = candleService ?? StockCandleService();

  final StockCandleService _candleService;

  final RxBool isLoadingPrice = false.obs;
  final RxString priceError = ''.obs;
  final RxList<OhlcCandlePoint> candles = <OhlcCandlePoint>[].obs;
  final RxList<OhlcCandlePoint> intradayCandles = <OhlcCandlePoint>[].obs;
  final Rx<PremiumPriceRange> selectedRange = PremiumPriceRange.oneYear.obs;
  final Rx<PremiumPriceChartMode> chartMode = PremiumPriceChartMode.area.obs;
  final RxnDouble livePrice = RxnDouble();

  String? _loadedSymbol;

  bool get isIntraday => selectedRange.value == PremiumPriceRange.oneDay;

  bool get isShowingIntradayData => isIntraday && intradayCandles.isNotEmpty;

  List<OhlcCandlePoint> get _sourceCandles =>
      isIntraday && intradayCandles.isNotEmpty ? intradayCandles : candles;

  List<OhlcCandlePoint> get visibleCandles {
    final List<OhlcCandlePoint> source = _sourceCandles;
    if (source.isEmpty) return <OhlcCandlePoint>[];

    if (isIntraday) {
      if (intradayCandles.length >= 3) {
        return _lastCalendarDay(intradayCandles);
      }
      if (candles.length >= 3) {
        final int start = candles.length > 7 ? candles.length - 7 : 0;
        return candles.sublist(start);
      }
      return <OhlcCandlePoint>[];
    }

    final DateTime? cutoff = _cutoffForRange(selectedRange.value);
    if (cutoff == null) return source.toList();
    return source
        .where((OhlcCandlePoint c) => !c.date.isBefore(cutoff))
        .toList();
  }

  OhlcCandlePoint? get latestCandle =>
      visibleCandles.isEmpty ? null : visibleCandles.last;

  double? get displayPrice =>
      livePrice.value ?? latestCandle?.close;

  double? get rangeChangePercent {
    final List<OhlcCandlePoint> visible = visibleCandles;
    if (visible.isEmpty) return null;
    final double first = visible.first.close;
    final double last = livePrice.value ?? visible.last.close;
    if (first == 0) return null;
    return ((last - first) / first) * 100;
  }

  double? get rangeChangeAbsolute {
    final List<OhlcCandlePoint> visible = visibleCandles;
    if (visible.isEmpty) return null;
    final double last = livePrice.value ?? visible.last.close;
    return last - visible.first.close;
  }

  Future<void> loadPriceHistory(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;

    if (!forceRefresh &&
        _loadedSymbol == normalized &&
        candles.isNotEmpty) {
      return;
    }

    _loadedSymbol = normalized;
    isLoadingPrice.value = true;
    priceError.value = '';
    candles.clear();
    intradayCandles.clear();
    livePrice.value = null;

    try {
      if (selectedRange.value == PremiumPriceRange.oneDay) {
        await Future.wait<void>(<Future<void>>[
          _loadIntraday(normalized, manageLoading: false),
          _loadDaily(normalized, forceRefresh: forceRefresh),
        ]);
      } else {
        await _loadDaily(normalized, forceRefresh: forceRefresh);
      }
      if (_loadedSymbol != normalized) return;
      if (visibleCandles.length < 3) {
        priceError.value = 'No chart data';
      }
    } catch (error) {
      if (_loadedSymbol != normalized) return;
      candles.clear();
      intradayCandles.clear();
      priceError.value = _userFacingChartError(error);
    } finally {
      if (_loadedSymbol == normalized) {
        isLoadingPrice.value = false;
      }
    }
  }

  Future<void> selectRange(PremiumPriceRange range) async {
    selectedRange.value = range;
    if (_loadedSymbol == null) return;
    if (range == PremiumPriceRange.oneDay) {
      if (intradayCandles.isEmpty) {
        await _loadIntraday(_loadedSymbol!);
      }
      return;
    }
    if (candles.isEmpty) {
      await _loadDaily(_loadedSymbol!);
    }
  }

  Future<void> _loadDaily(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty || _loadedSymbol != normalized) return;

    try {
      final DateTime now = DateTime.now();
      final DateTime from = DateTime(now.year - 5, now.month, now.day);
      final List<OhlcCandlePoint> loaded = await _candleService.fetchOhlc(
        normalized,
        from: from,
        to: now,
        resolution: 'D',
        forceRefresh: forceRefresh,
      );

      if (_loadedSymbol != normalized) return;

      if (loaded.isEmpty) {
        if (intradayCandles.isEmpty) {
          priceError.value = 'No chart data';
        }
      } else {
        candles.assignAll(loaded);
        if (intradayCandles.isNotEmpty) {
          priceError.value = '';
        }
      }
    } catch (error) {
      if (_loadedSymbol != normalized) return;
      if (intradayCandles.isEmpty) {
        priceError.value = _userFacingChartError(error);
      }
    }
  }

  Future<void> _loadIntraday(
    String symbol, {
    bool manageLoading = true,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty || _loadedSymbol != normalized) return;

    if (manageLoading) isLoadingPrice.value = true;
    priceError.value = '';

    try {
      final DateTime now = DateTime.now();
      final DateTime from = now.subtract(const Duration(days: 7));
      final List<OhlcCandlePoint> intraday = await _candleService.fetchOhlc(
        normalized,
        from: from,
        to: now,
        resolution: '5',
      );

      if (_loadedSymbol != normalized) return;

      if (intraday.isNotEmpty) {
        intradayCandles.assignAll(intraday);
        priceError.value = '';
      }
    } catch (_) {
      if (_loadedSymbol != normalized) return;
    } finally {
      if (manageLoading && _loadedSymbol == normalized) {
        isLoadingPrice.value = false;
      }
    }
  }

  /// Soft-merge a live tick into the last candle for a smooth live chart.
  void applyLivePrice(double price) {
    livePrice.value = price;
    if (!isIntraday || intradayCandles.isEmpty) return;

    final OhlcCandlePoint last = intradayCandles.last;
    final OhlcCandlePoint updated = OhlcCandlePoint(
      date: last.date,
      open: last.open,
      high: price > last.high ? price : last.high,
      low: price < last.low ? price : last.low,
      close: price,
      volume: last.volume,
    );
    intradayCandles[intradayCandles.length - 1] = updated;
  }

  void setChartMode(PremiumPriceChartMode mode) {
    chartMode.value = mode;
  }

  DateTime? _cutoffForRange(PremiumPriceRange range) {
    final DateTime now = DateTime.now();
    switch (range) {
      case PremiumPriceRange.oneDay:
        return DateTime(now.year, now.month, now.day);
      case PremiumPriceRange.oneWeek:
        return now.subtract(const Duration(days: 7));
      case PremiumPriceRange.oneMonth:
        return now.subtract(const Duration(days: 30));
      case PremiumPriceRange.threeMonths:
        return now.subtract(const Duration(days: 90));
      case PremiumPriceRange.sixMonths:
        return now.subtract(const Duration(days: 180));
      case PremiumPriceRange.ytd:
        return DateTime(now.year, 1, 1);
      case PremiumPriceRange.oneYear:
        return now.subtract(const Duration(days: 365));
      case PremiumPriceRange.fiveYears:
        return now.subtract(const Duration(days: 365 * 5));
      case PremiumPriceRange.all:
        return null;
    }
  }

  /// Bars from the last candle's calendar day. If that day is too thin,
  /// fall back to the last 24 hours of points.
  static List<OhlcCandlePoint> _lastCalendarDay(List<OhlcCandlePoint> candles) {
    final DateTime last = candles.last.date;
    final List<OhlcCandlePoint> sameDay = candles
        .where(
          (OhlcCandlePoint c) =>
              c.date.year == last.year &&
              c.date.month == last.month &&
              c.date.day == last.day,
        )
        .toList();
    if (sameDay.length >= 3) return sameDay;
    final DateTime cutoff = last.subtract(const Duration(hours: 24));
    return candles.where((OhlcCandlePoint c) => !c.date.isBefore(cutoff)).toList();
  }

  static String _userFacingChartError(Object error) {
    if (error is FinnhubApiException) {
      final String lower = error.message.toLowerCase();
      if (lower.contains('internet') ||
          lower.contains('network') ||
          lower.contains('timed out')) {
        return error.message;
      }
    }
    return 'No chart data';
  }
}
