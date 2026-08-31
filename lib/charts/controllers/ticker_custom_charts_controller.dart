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
  int _autoRetryCount = 0;
  static const int _maxAutoRetries = 2;

  bool get isIntraday => selectedRange.value == PremiumPriceRange.oneDay;

  /// True only when we're actually rendering true intraday-granularity bars
  /// (as opposed to a daily-candle fallback shown under the 1D tab because
  /// intraday data is momentarily unavailable). Chart axis/tooltip
  /// formatting should key off this, not [isIntraday], so a daily fallback
  /// doesn't get mislabeled with hour-of-day ticks.
  bool get isShowingIntradayData => isIntraday && intradayCandles.isNotEmpty;

  List<OhlcCandlePoint> get _sourceCandles =>
      isIntraday && intradayCandles.isNotEmpty ? intradayCandles : candles;

  List<OhlcCandlePoint> get visibleCandles {
    final List<OhlcCandlePoint> source = _sourceCandles;
    if (source.isEmpty) return <OhlcCandlePoint>[];

    if (isIntraday) {
      if (intradayCandles.isNotEmpty) {
        return _sessionForOneDay(intradayCandles);
      }
      // Intraday data is momentarily unavailable (proxy hiccup / no data
      // published yet). Rather than leaving the chart blank, show a short
      // recent trend from daily candles. Never just 1-2 points, since that
      // draws a fake straight diagonal line.
      final DateTime cutoff =
          source.last.date.subtract(const Duration(days: 6));
      final List<OhlcCandlePoint> recent =
          source.where((OhlcCandlePoint c) => !c.date.isBefore(cutoff)).toList();
      if (recent.length >= 3) return recent;
      if (source.length >= 5) return source.sublist(source.length - 5);
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

  Future<void> loadPriceHistory(
    String symbol, {
    bool forceRefresh = false,
    bool isAutoRetry = false,
  }) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;

    if (!forceRefresh &&
        _loadedSymbol == normalized &&
        (candles.isNotEmpty ||
            (isIntraday && intradayCandles.isNotEmpty))) {
      return;
    }

    if (!isAutoRetry) _autoRetryCount = 0;
    _loadedSymbol = normalized;
    // Keep the current chart on screen during a background retry — flipping
    // to a spinner / "No chart data" is what made first-load look broken.
    if (!isAutoRetry) {
      isLoadingPrice.value = true;
      priceError.value = '';
      candles.clear();
      intradayCandles.clear();
      livePrice.value = null;
    }

    try {
      if (selectedRange.value == PremiumPriceRange.oneDay) {
        // Load intraday and daily together (not intraday-then-daily) so
        // that if intraday comes back empty, the daily fallback data is
        // already there the instant the chart renders — no need for the
        // user to toggle away and back to 1D to "wake it up".
        await Future.wait<void>(<Future<void>>[
          _loadIntraday(normalized, manageLoading: false),
          _loadDaily(normalized, forceRefresh: forceRefresh),
        ]);
      } else {
        await _loadDaily(normalized, forceRefresh: forceRefresh);
      }
    } catch (error) {
      if (_loadedSymbol != normalized) return;
      if (!isAutoRetry) {
        candles.clear();
        intradayCandles.clear();
      }
      priceError.value = _userFacingChartError(error);
    } finally {
      if (_loadedSymbol == normalized) {
        isLoadingPrice.value = false;
      }
    }

    // The upstream proxy can be briefly overloaded right when a page first
    // loads (many widgets requesting data at once). Rather than leaving the
    // chart stuck on "No chart data" until the user does something, quietly
    // retry a couple of times in the background — this is what was actually
    // happening before when navigating away and back "fixed" it.
    if (_loadedSymbol == normalized &&
        visibleCandles.isEmpty &&
        _autoRetryCount < _maxAutoRetries) {
      _autoRetryCount++;
      final int attempt = _autoRetryCount;
      Future<void>.delayed(Duration(seconds: 3 * attempt), () {
        if (_loadedSymbol == normalized && visibleCandles.isEmpty) {
          loadPriceHistory(normalized, forceRefresh: true, isAutoRetry: true);
        }
      });
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
      final DateTime from = now.subtract(const Duration(days: 3));
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

  /// Picks the latest session with enough bars for a real 1D shape.
  /// Thin pre-market clusters are skipped so we don't draw a 2-point diagonal.
  static List<OhlcCandlePoint> _sessionForOneDay(List<OhlcCandlePoint> candles) {
    final List<List<OhlcCandlePoint>> sessions =
        _splitSessions(candles, const Duration(hours: 2));
    if (sessions.isEmpty) return <OhlcCandlePoint>[];

    const int minBars = 4;
    for (int i = sessions.length - 1; i >= 0; i--) {
      if (sessions[i].length >= minBars) {
        return sessions[i];
      }
    }

    List<OhlcCandlePoint> best = sessions.last;
    for (final List<OhlcCandlePoint> session in sessions) {
      if (session.length > best.length) best = session;
    }
    if (best.length >= 4) return best;

    final DateTime latest = sessions.last.last.date;
    final DateTime cutoff = latest.subtract(const Duration(hours: 24));
    final List<OhlcCandlePoint> recent = <OhlcCandlePoint>[];
    for (final List<OhlcCandlePoint> session in sessions) {
      for (final OhlcCandlePoint c in session) {
        if (!c.date.isBefore(cutoff)) recent.add(c);
      }
    }
    if (recent.length >= 4) return recent;
    return best.length >= 3 ? best : <OhlcCandlePoint>[];
  }

  static List<List<OhlcCandlePoint>> _splitSessions(
    List<OhlcCandlePoint> candles,
    Duration gapThreshold,
  ) {
    if (candles.isEmpty) return <List<OhlcCandlePoint>>[];

    final List<OhlcCandlePoint> sorted = candles.toList()
      ..sort((OhlcCandlePoint a, OhlcCandlePoint b) => a.date.compareTo(b.date));

    final List<List<OhlcCandlePoint>> sessions = <List<OhlcCandlePoint>>[
      <OhlcCandlePoint>[sorted.first],
    ];
    for (int i = 1; i < sorted.length; i++) {
      final Duration gap = sorted[i].date.difference(sorted[i - 1].date);
      if (gap > gapThreshold) {
        sessions.add(<OhlcCandlePoint>[sorted[i]]);
      } else {
        sessions.last.add(sorted[i]);
      }
    }
    return sessions;
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
