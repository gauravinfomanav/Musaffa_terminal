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
  final Rx<PremiumPriceRange> selectedRange = PremiumPriceRange.oneYear.obs;
  final Rx<PremiumPriceChartMode> chartMode = PremiumPriceChartMode.area.obs;

  String? _loadedSymbol;

  List<OhlcCandlePoint> get visibleCandles {
    if (candles.isEmpty) return <OhlcCandlePoint>[];
    final DateTime? cutoff = _cutoffForRange(selectedRange.value);
    if (cutoff == null) return candles.toList();
    return candles.where((OhlcCandlePoint c) => !c.date.isBefore(cutoff)).toList();
  }

  OhlcCandlePoint? get latestCandle =>
      visibleCandles.isEmpty ? null : visibleCandles.last;

  double? get rangeChangePercent {
    final List<OhlcCandlePoint> visible = visibleCandles;
    if (visible.length < 2) return null;
    final double first = visible.first.close;
    final double last = visible.last.close;
    if (first == 0) return null;
    return ((last - first) / first) * 100;
  }

  double? get rangeChangeAbsolute {
    final List<OhlcCandlePoint> visible = visibleCandles;
    if (visible.length < 2) return null;
    return visible.last.close - visible.first.close;
  }

  Future<void> loadPriceHistory(String symbol, {bool forceRefresh = false}) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return;

    if (!forceRefresh && _loadedSymbol == normalized && candles.isNotEmpty) {
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
        if (todaySession.isNotEmpty) {
          candles.assignAll(todaySession);
          return;
        }
        candles.assignAll(intraday);
      }
    } catch (_) {
      // Fall back to daily filter below.
    } finally {
      isLoadingPrice.value = false;
    }
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
