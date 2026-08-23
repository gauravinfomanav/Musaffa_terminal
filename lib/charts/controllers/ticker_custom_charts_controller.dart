import 'package:get/get.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
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

  List<OhlcCandlePoint> get _sourceCandles =>
      isIntraday && intradayCandles.isNotEmpty ? intradayCandles : candles;

  List<OhlcCandlePoint> get visibleCandles {
    final List<OhlcCandlePoint> source = _sourceCandles;
    if (source.isEmpty) return <OhlcCandlePoint>[];
    if (isIntraday) return source.toList();
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

    try {
      final DateTime now = DateTime.now();
      final DateTime from = DateTime(now.year - 10, now.month, now.day);
      final List<OhlcCandlePoint> loaded = await _candleService.fetchOhlc(
        normalized,
        from: from,
        to: now,
        resolution: 'D',
        forceRefresh: forceRefresh,
      );

      if (loaded.isEmpty) {
        candles.clear();
        priceError.value = 'No price history available';
      } else {
        candles.assignAll(loaded);
      }

      if (selectedRange.value == PremiumPriceRange.oneDay) {
        await _loadIntraday(normalized);
      }
    } catch (error) {
      candles.clear();
      priceError.value = error.toString();
    } finally {
      isLoadingPrice.value = false;
    }
  }

  Future<void> selectRange(PremiumPriceRange range) async {
    selectedRange.value = range;
    if (range == PremiumPriceRange.oneDay && _loadedSymbol != null) {
      await _loadIntraday(_loadedSymbol!);
    }
  }

  Future<void> _loadIntraday(String symbol) async {
    isLoadingPrice.value = true;
    priceError.value = '';

    try {
      final DateTime now = DateTime.now();
      final DateTime from = now.subtract(const Duration(days: 3));
      final List<OhlcCandlePoint> intraday = await _candleService.fetchOhlc(
        symbol,
        from: from,
        to: now,
        resolution: '15',
        forceRefresh: true,
      );

      if (intraday.isNotEmpty) {
        final DateTime cutoff = DateTime(now.year, now.month, now.day);
        final List<OhlcCandlePoint> todaySession = intraday
            .where((OhlcCandlePoint c) => !c.date.isBefore(cutoff))
            .toList();
        intradayCandles.assignAll(
          todaySession.isNotEmpty ? todaySession : intraday,
        );
      } else {
        intradayCandles.clear();
      }
    } catch (_) {
      // Keep daily candles as fallback via visibleCandles.
    } finally {
      isLoadingPrice.value = false;
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
}
