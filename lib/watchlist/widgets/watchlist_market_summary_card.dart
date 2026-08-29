import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/models/quote_model.dart';
import 'package:musaffa_terminal/services/finnhub/quote_service.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';

/// US market proxies via Finnhub (ETF symbols that map to major indices).
class WatchlistMarketSummaryCard extends StatefulWidget {
  const WatchlistMarketSummaryCard({
    super.key,
    required this.isDarkMode,
  });

  final bool isDarkMode;

  @override
  State<WatchlistMarketSummaryCard> createState() =>
      _WatchlistMarketSummaryCardState();
}

class _WatchlistMarketSummaryCardState extends State<WatchlistMarketSummaryCard> {
  static const List<_IndexSpec> _indices = <_IndexSpec>[
    _IndexSpec(
      symbol: '^IXIC',
      fallbackSymbol: 'QQQ',
      label: 'NASDAQ',
    ),
    _IndexSpec(
      symbol: '^GSPC',
      fallbackSymbol: 'SPY',
      label: 'S&P 500',
    ),
  ];

  final QuoteService _quotes = QuoteService();
  final StockCandleService _candles = StockCandleService();

  List<_IndexSnapshot?> _rows = const <_IndexSnapshot?>[null, null];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<_IndexSnapshot> _loadOne(_IndexSpec spec) async {
    final DateTime to = DateTime.now();
    final DateTime from = to.subtract(const Duration(days: 45));

    Future<_IndexSnapshot?> trySymbol(String symbol) async {
      final QuoteModel? quote = await _quotes.fetchQuote(symbol);
      if (quote == null || quote.currentPrice == null) return null;

      final List<PriceDataPoint> closes = await _candles.fetchDailyCloses(
        symbol,
        from: from,
        to: to,
      );
      List<double> spark =
          closes.map((PriceDataPoint p) => p.value).toList();
      if (spark.length > 36) {
        final int step = (spark.length / 36).ceil().clamp(1, spark.length);
        final List<double> sampled = <double>[];
        for (int i = 0; i < spark.length; i += step) {
          sampled.add(spark[i]);
        }
        if (sampled.isEmpty || sampled.last != spark.last) {
          sampled.add(spark.last);
        }
        spark = sampled;
      }

      return _IndexSnapshot(
        label: spec.label,
        price: quote.currentPrice,
        changePercent: quote.percentChange,
        sparkline: spark,
      );
    }

    try {
      final _IndexSnapshot? primary = await trySymbol(spec.symbol);
      if (primary != null) return primary;
      final _IndexSnapshot? fallback = await trySymbol(spec.fallbackSymbol);
      if (fallback != null) return fallback;
    } catch (_) {
      try {
        final _IndexSnapshot? fallback = await trySymbol(spec.fallbackSymbol);
        if (fallback != null) return fallback;
      } catch (_) {}
    }
    return _IndexSnapshot(label: spec.label);
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final List<_IndexSnapshot> next = await Future.wait(
      _indices.map(_loadOne),
    );

    if (!mounted) return;
    setState(() {
      _rows = next;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;

    if (_loading) {
      return WatchlistShimmer.marketSummaryCard(isDarkMode: isDark);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Summary',
            style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildIndexPane(
                    _rows.isNotEmpty ? _rows[0] : null,
                    isDark,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 1,
                    color: HomeUi.borderLight(isDark),
                  ),
                ),
                Expanded(
                  child: _buildIndexPane(
                    _rows.length > 1 ? _rows[1] : null,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexPane(_IndexSnapshot? snap, bool isDark) {
    final String label = snap?.label ?? '—';
    final double? price = snap?.price;
    final double? change = snap?.changePercent;
    final bool positive = (change ?? 0) >= 0;
    final Color tone = change == null
        ? HomeUi.muted(isDark)
        : (positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark));
    final NumberFormat priceFmt = NumberFormat('#,##0.00');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: HomeUi.subtitle(isDark).copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price == null ? '—' : priceFmt.format(price),
          style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          change == null
              ? '—'
              : '${positive ? '▲' : '▼'} ${change.abs().toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tone,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 32,
              width: double.infinity,
              child: snap != null && snap.sparkline.length >= 2
                  ? CustomPaint(
                      painter: _MiniSparklinePainter(
                        values: snap.sparkline,
                        lineColor: tone == HomeUi.muted(isDark)
                            ? HomeUi.positive(isDark)
                            : tone,
                        fillColor: (tone == HomeUi.muted(isDark)
                                ? HomeUi.positive(isDark)
                                : tone)
                            .withValues(alpha: isDark ? 0.16 : 0.12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _IndexSpec {
  const _IndexSpec({
    required this.symbol,
    required this.fallbackSymbol,
    required this.label,
  });
  final String symbol;
  final String fallbackSymbol;
  final String label;
}

class _IndexSnapshot {
  const _IndexSnapshot({
    required this.label,
    this.price,
    this.changePercent,
    this.sparkline = const <double>[],
  });

  final String label;
  final double? price;
  final double? changePercent;
  final List<double> sparkline;
}

class _MiniSparklinePainter extends CustomPainter {
  const _MiniSparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    double minV = values.first;
    double maxV = values.first;
    for (final double v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final double span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    const double padY = 2;
    final double usableH = size.height - padY * 2;
    final int last = values.length - 1;

    Offset pointAt(int i) {
      final double t = i / last;
      final double norm = (values[i] - minV) / span;
      return Offset(size.width * t, padY + usableH * (1 - norm));
    }

    final Path line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i <= last; i++) {
      line.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final Path area = Path.from(line)
      ..lineTo(pointAt(last).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[fillColor, fillColor.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.values != values;
  }
}
