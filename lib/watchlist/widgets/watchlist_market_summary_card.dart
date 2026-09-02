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
    _IndexSpec(symbol: 'QQQ', label: 'NASDAQ'),
    _IndexSpec(symbol: 'SPY', label: 'S&P 500'),
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
    final DateTime from = to.subtract(const Duration(days: 30));

    QuoteModel? quote;
    List<double> spark = const <double>[];
    double? lastClose;
    double? prevClose;

    try {
      final List<Object?> loaded = await Future.wait<Object?>(<Future<Object?>>[
        _tryQuote(spec.symbol),
        _trySpark(spec.symbol, from, to),
      ]);
      quote = loaded[0] as QuoteModel?;
      final _SparkFetch sf = loaded[1] as _SparkFetch;
      spark = sf.sampled;
      lastClose = sf.lastClose;
      prevClose = sf.prevClose;
    } catch (_) {}

    final double? price = quote?.currentPrice ?? lastClose;
    double? change = quote?.percentChange;
    if (change == null &&
        lastClose != null &&
        prevClose != null &&
        prevClose != 0) {
      change = ((lastClose - prevClose) / prevClose) * 100;
    }

    return _IndexSnapshot(
      label: spec.label,
      symbol: spec.symbol,
      price: price,
      changePercent: change,
      sparkline: spark,
    );
  }

  Future<QuoteModel?> _tryQuote(String symbol) async {
    try {
      final QuoteModel? quote = await _quotes.fetchQuote(symbol);
      if (quote != null &&
          quote.currentPrice != null &&
          quote.currentPrice! > 0) {
        return quote;
      }
    } catch (_) {}
    return null;
  }

  Future<_SparkFetch> _trySpark(
    String symbol,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final List<PriceDataPoint> closes = await _candles.fetchDailyCloses(
        symbol,
        from: from,
        to: to,
      );
      if (closes.length >= 2) {
        final List<double> raw =
            closes.map((PriceDataPoint p) => p.value).toList();
        return _SparkFetch(
          sampled: _downsample(raw),
          lastClose: raw.last,
          prevClose: raw[raw.length - 2],
        );
      }
    } catch (_) {}
    return const _SparkFetch();
  }

  static List<double> _downsample(List<double> spark) {
    if (spark.length <= 36) return spark;
    final int step = (spark.length / 36).ceil().clamp(1, spark.length);
    final List<double> sampled = <double>[];
    for (int i = 0; i < spark.length; i += step) {
      sampled.add(spark[i]);
    }
    if (sampled.isEmpty || sampled.last != spark.last) {
      sampled.add(spark.last);
    }
    return sampled;
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: HomeUi.subtitle(isDark).copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            if (snap?.symbol != null) ...[
              const SizedBox(width: 4),
              Text(
                '· ${snap!.symbol}',
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: HomeUi.muted(isDark),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (price == null)
          WatchlistShimmer.metricValue(isDarkMode: isDark)
        else
          Text(
            priceFmt.format(price),
            style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 14),
          ),
        const SizedBox(height: 2),
        if (change == null)
          WatchlistShimmer.metricValue(isDarkMode: isDark, compact: true)
        else
          Text(
            '${positive ? '▲' : '▼'} ${change.abs().toStringAsFixed(2)}%',
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
                  : LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        return WatchlistShimmer.sparkline(
                          isDarkMode: isDark,
                          width: constraints.maxWidth,
                          height: 32,
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Result of a candle fetch used for the sparkline, keeping the raw last
/// two closes around so price/change can be derived from them if the
/// separate quote endpoint fails.
class _SparkFetch {
  const _SparkFetch({
    this.sampled = const <double>[],
    this.lastClose,
    this.prevClose,
  });

  final List<double> sampled;
  final double? lastClose;
  final double? prevClose;
}

class _IndexSpec {
  const _IndexSpec({
    required this.symbol,
    required this.label,
  });
  final String symbol;
  final String label;
}

class _IndexSnapshot {
  const _IndexSnapshot({
    required this.label,
    this.price,
    this.changePercent,
    this.sparkline = const <double>[],
    this.symbol,
  });

  final String label;
  final double? price;
  final double? changePercent;
  final List<double> sparkline;
  /// The ETF/index symbol whose live quote is actually being shown (e.g.
  /// `QQQ`). Surfaced in the UI so the displayed price is never a mystery
  /// number — it's always traceable to a real, named instrument.
  final String? symbol;
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
    final double span = maxV - minV;
    const double padY = 2;
    final double usableH = size.height - padY * 2;
    final int last = values.length - 1;
    final bool flat = span.abs() < 1e-9;

    Offset pointAt(int i) {
      final double t = i / last;
      final double norm = flat ? 0.5 : (values[i] - minV) / span;
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
