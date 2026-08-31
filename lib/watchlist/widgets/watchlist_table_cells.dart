import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/services/finnhub/stock_candle_service.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Compact dual change cell: percent + absolute $ move.
class WatchlistChangeCell extends StatelessWidget {
  const WatchlistChangeCell({
    super.key,
    required this.percent,
    required this.absolute,
    required this.isDark,
  });

  final double? percent;
  final double? absolute;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (percent == null && absolute == null) {
      return Text('—', style: HomeUi.tableCellSecondary(isDark));
    }
    final double pct = percent ?? 0;
    final bool positive = pct >= 0;
    final Color tone =
        positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${positive ? '+' : ''}${pct.toStringAsFixed(2)}%',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: tone,
            height: 1.15,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        if (absolute != null)
          Text(
            '${absolute! >= 0 ? '+' : ''}${absolute!.toStringAsFixed(2)}',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tone.withValues(alpha: 0.85),
              height: 1.15,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

/// 52-week range: low — clean track + marker — high.
class WatchlistRange52Cell extends StatelessWidget {
  const WatchlistRange52Cell({
    super.key,
    required this.low,
    required this.high,
    required this.current,
    required this.isDark,
  });

  final double? low;
  final double? high;
  final double? current;
  final bool isDark;

  String _fmt(double v) {
    if (v >= 1000) return v.toStringAsFixed(0);
    if (v >= 100) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRange =
        low != null && high != null && high! > low! && current != null;
    if (!hasRange) {
      return Text('—', style: HomeUi.tableCellSecondary(isDark));
    }

    final double t = ((current! - low!) / (high! - low!)).clamp(0.0, 1.0);
    final TextStyle labelStyle = HomeUi.tableCellSecondary(isDark).copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.15,
      height: 1,
      color: HomeUi.muted(isDark),
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    return SizedBox(
      width: 172,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              _fmt(low!),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.right,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 14),
                  painter: _Range52TrackPainter(
                    progress: t,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              _fmt(high!),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.left,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Range52TrackPainter extends CustomPainter {
  const _Range52TrackPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  static const double _trackHeight = 3;
  static const double _thumbRadius = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double w = size.width;
    final double thumbX =
        (progress * w).clamp(_thumbRadius, w - _thumbRadius);
    final Color green = HomeUi.positive(isDark);
    final Color trackColor = isDark
        ? const Color(0xFF2E3440)
        : const Color(0xFFE2E5EA);
    final Color thumbFill = isDark ? const Color(0xFFF1F5F9) : Colors.white;

    final RRect track = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, cy),
        width: w,
        height: _trackHeight,
      ),
      Radius.circular(_trackHeight / 2),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);

    if (thumbX > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, cy - _trackHeight / 2, thumbX, _trackHeight),
          Radius.circular(_trackHeight / 2),
        ),
        Paint()..color = green,
      );
    }

    final Offset thumbCenter = Offset(thumbX, cy);

    canvas.drawCircle(
      thumbCenter + const Offset(0, 0.75),
      _thumbRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.22 : 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawCircle(
      thumbCenter,
      _thumbRadius,
      Paint()..color = thumbFill,
    );

    canvas.drawCircle(
      thumbCenter,
      _thumbRadius,
      Paint()
        ..color = green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75,
    );
  }

  @override
  bool shouldRepaint(covariant _Range52TrackPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

/// Lazy 1D / recent-price sparkline for a single symbol (loads on mount).
class WatchlistSparklineCell extends StatefulWidget {
  const WatchlistSparklineCell({
    super.key,
    required this.symbol,
    required this.isDark,
    required this.positive,
  });

  final String symbol;
  final bool isDark;
  final bool positive;

  @override
  State<WatchlistSparklineCell> createState() => _WatchlistSparklineCellState();
}

class _WatchlistSparklineCellState extends State<WatchlistSparklineCell> {
  static final StockCandleService _candles = StockCandleService();
  static final Map<String, List<double>> _cache = <String, List<double>>{};

  List<double>? _values;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WatchlistSparklineCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _load();
    }
  }

  Future<void> _load() async {
    final String symbol = widget.symbol.trim().toUpperCase();
    if (symbol.isEmpty) {
      setState(() {
        _values = null;
        _loading = false;
      });
      return;
    }

    final List<double>? cached = _cache[symbol];
    if (cached != null) {
      setState(() {
        _values = cached;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final DateTime to = DateTime.now();
      // Prefer intraday 5-min for a true 1D feel; fall back to recent daily.
      List<OhlcCandlePoint> ohlc = await _candles.fetchOhlc(
        symbol,
        from: to.subtract(const Duration(hours: 30)),
        to: to,
        resolution: '5',
      );
      List<double> series =
          ohlc.map((OhlcCandlePoint p) => p.close).toList();

      if (series.length < 4) {
        final List<PriceDataPoint> daily = await _candles.fetchDailyCloses(
          symbol,
          from: to.subtract(const Duration(days: 45)),
          to: to,
        );
        series = daily.map((PriceDataPoint p) => p.value).toList();
      }

      if (series.length > 48) {
        final int step = (series.length / 48).ceil().clamp(1, series.length);
        final List<double> sampled = <double>[];
        for (int i = 0; i < series.length; i += step) {
          sampled.add(series[i]);
        }
        if (sampled.isEmpty || sampled.last != series.last) {
          sampled.add(series.last);
        }
        series = sampled;
      }

      _cache[symbol] = series;
      if (!mounted) return;
      setState(() {
        _values = series;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _values = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color tone = widget.positive
        ? HomeUi.positive(widget.isDark)
        : HomeUi.negative(widget.isDark);

    if (_loading) {
      return SizedBox(
        width: 88,
        height: 28,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.4,
              color: HomeUi.muted(widget.isDark),
            ),
          ),
        ),
      );
    }

    if (_values == null || _values!.length < 2) {
      return SizedBox(
        width: 88,
        child: Text('—', style: HomeUi.tableCellSecondary(widget.isDark)),
      );
    }

    return SizedBox(
      width: 88,
      height: 32,
      child: CustomPaint(
        painter: _SparkPainter(
          values: _values!,
          lineColor: tone,
          fillColor: tone.withValues(alpha: widget.isDark ? 0.18 : 0.12),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({
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
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.values != values;
  }
}
