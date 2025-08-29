import 'dart:convert';
import 'package:get/get.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class FinhubController extends GetxController {
  static const String _apiKey = 'd2op649r01qga5gaa41gd2op649r01qga5gaa420';
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  final RxList<MarketIndex> indices = <MarketIndex>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DateTime?> lastUpdated = Rx<DateTime?>(null);
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    fetchMarketIndices();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchMarketIndices();
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchMarketIndices() async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Free-tier friendly ETFs: broad market, sectors, bonds, commodities, intl
      final symbols = [
        // US broad & majors
        'SPY', 'QQQ', 'DIA', 'IWM', 'VTI',
        // Sectors
        'XLK', 'XLF', 'XLE', 'XLV', 'XLY', 'XLI', 'XLP', 'XLB', 'XLRE', 'XLU',
        // International
        'EFA', 'EEM',
        // Bonds & commodities
        'TLT', 'IEF', 'GLD', 'USO',
      ];
      final futures = symbols.map((symbol) => _fetchQuoteWithFallback(symbol));
      final results = await Future.wait(futures);

      indices.clear();
      for (int i = 0; i < symbols.length; i++) {
        if (results[i] != null) {
          indices.add(results[i]!);
        }
      }
      lastUpdated.value = DateTime.now();
    } catch (e) {
      errorMessage.value = 'Failed to fetch market data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<MarketIndex?> _fetchQuote(String symbol) async {
    try {
      final url = Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MarketIndex.fromJson(symbol, data);
      }
    } catch (_) {}
    return null;
  }

  Future<MarketIndex?> _fetchQuoteWithFallback(String symbol) async {
    final quote = await _fetchQuote(symbol);
    if (quote == null) return null;

    // If dp is 0 (common after close) and market is closed, compute yesterday's change from candles
    if (!isMarketOpen && (quote.changePercent == 0 || quote.currentPrice == quote.previousClose)) {
      final prev = await _fetchPreviousDayChangePercent(symbol);
      if (prev != null) {
        return quote.copyWith(overrideChangePercent: prev);
      }
    }
    return quote;
  }

  Future<double?> _fetchPreviousDayChangePercent(String symbol) async {
    try {
      final to = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final from = DateTime.now().toUtc().subtract(const Duration(days: 10)).millisecondsSinceEpoch ~/ 1000;
      final url = Uri.parse('$_baseUrl/stock/candle?symbol=$symbol&resolution=D&from=$from&to=$to&token=$_apiKey');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['s'] == 'ok' && data['c'] is List && data['t'] is List) {
          final List closes = (data['c'] as List);
          final List timestamps = (data['t'] as List);
          if (closes.length >= 2 && timestamps.length == closes.length) {
            final nowUtc = DateTime.now().toUtc();
            final newYorkOffset = _approxNewYorkOffset(nowUtc);
            final nowNy = nowUtc.add(Duration(hours: newYorkOffset));
            final todayNy = DateTime(nowNy.year, nowNy.month, nowNy.day);

            final List<int> validIdx = [];
            for (int i = 0; i < timestamps.length; i++) {
              final tsUtc = DateTime.fromMillisecondsSinceEpoch((timestamps[i] as int) * 1000, isUtc: true);
              final tsNy = tsUtc.add(Duration(hours: newYorkOffset));
              final tsNyDate = DateTime(tsNy.year, tsNy.month, tsNy.day);
              if (tsNyDate.isBefore(todayNy)) {
                validIdx.add(i);
              }
            }

            if (validIdx.length >= 2) {
              final int lastIdx = validIdx.last;
              final int prevIdx = validIdx[validIdx.length - 2];
              final double last = (closes[lastIdx] as num).toDouble();
              final double prev = (closes[prevIdx] as num).toDouble();
              if (prev != 0) {
                return ((last - prev) / prev) * 100.0;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // Rough approximation of New York offset (EST/EDT) relative to UTC without timezone package
  int _approxNewYorkOffset(DateTime nowUtc) {
    // DST starts second Sunday in March, ends first Sunday in November
    final year = nowUtc.year;
    DateTime nthWeekday(int n, int weekday, int month) {
      final first = DateTime.utc(year, month, 1);
      int add = (weekday - first.weekday) % 7;
      return first.add(Duration(days: add + (n - 1) * 7));
    }

    final dstStart = nthWeekday(2, DateTime.sunday, 3); // March 2nd Sunday
    final dstEnd = nthWeekday(1, DateTime.sunday, 11); // Nov 1st Sunday

    if (nowUtc.isAfter(dstStart) && nowUtc.isBefore(dstEnd)) {
      return -4; // EDT
    }
    return -5; // EST
  }

  bool get isMarketOpen {
    final now = DateTime.now();
    final weekday = now.weekday;
    
    // Market is closed on weekends
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return false;
    }

    // Market hours: 9:30 AM - 4:00 PM EST (UTC-5)
    final estTime = now.toUtc().add(const Duration(hours: -5));
    final hour = estTime.hour;
    final minute = estTime.minute;
    final timeInMinutes = hour * 60 + minute;

    // 9:30 AM = 570 minutes, 4:00 PM = 960 minutes
    return timeInMinutes >= 570 && timeInMinutes <= 960;
  }
}

class MarketIndex {
  final String symbol;
  final String displayName;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double highPrice;
  final double lowPrice;
  final double openPrice;
  final double previousClose;

  MarketIndex({
    required this.symbol,
    required this.displayName,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.openPrice,
    required this.previousClose,
  });

  factory MarketIndex.fromJson(String symbol, Map<String, dynamic> json) {
    final displayNames = {
      // Equity proxies for indices (Finnhub free tier)
      'SPY': 'S&P 500',
      'QQQ': 'NASDAQ 100',
      'DIA': 'DOW',
      'IWM': 'RUSSELL 2000',
      'VTI': 'TOTAL MARKET',
      'XLK': 'TECH SECTOR',
      // If actual index symbols ever work, they will fall back to symbol string
    };

    return MarketIndex(
      symbol: symbol,
      displayName: displayNames[symbol] ?? symbol,
      currentPrice: (json['c'] ?? 0.0).toDouble(),
      change: (json['d'] ?? 0.0).toDouble(),
      changePercent: (json['dp'] ?? 0.0).toDouble(),
      highPrice: (json['h'] ?? 0.0).toDouble(),
      lowPrice: (json['l'] ?? 0.0).toDouble(),
      openPrice: (json['o'] ?? 0.0).toDouble(),
      previousClose: (json['pc'] ?? 0.0).toDouble(),
    );
  }

  bool get isPositive => changePercent >= 0;
  String get formattedChangePercent => '${changePercent.abs().toStringAsFixed(2)}%';
  String get formattedChange => change.abs().toStringAsFixed(2);

  MarketIndex copyWith({double? overrideChangePercent}) {
    return MarketIndex(
      symbol: symbol,
      displayName: displayName,
      currentPrice: currentPrice,
      change: change,
      changePercent: overrideChangePercent ?? changePercent,
      highPrice: highPrice,
      lowPrice: lowPrice,
      openPrice: openPrice,
      previousClose: previousClose,
    );
  }
}
