import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/watchlist/services/watchlist_performance_service.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';

/// Card matching the “Watchlist Performance” mock: period % returns + sparkline.
class WatchlistPerformanceCard extends StatefulWidget {
  const WatchlistPerformanceCard({
    super.key,
    required this.tableData,
    required this.isDarkMode,
    this.compact = false,
  });

  final List<SimpleRowModel> tableData;
  final bool isDarkMode;
  final bool compact;

  @override
  State<WatchlistPerformanceCard> createState() =>
      _WatchlistPerformanceCardState();
}

class _WatchlistPerformanceCardState extends State<WatchlistPerformanceCard> {
  final WatchlistPerformanceService _service = WatchlistPerformanceService();

  static const int _maxRetries = 2;

  WatchlistPeriodPerformance? _data;
  bool _loading = true;
  String? _symbolsKey;
  int _requestId = 0;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WatchlistPerformanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String nextKey = _keyFor(widget.tableData);
    if (nextKey != _symbolsKey) {
      _load();
    } else if (_data != null &&
        widget.tableData.isNotEmpty &&
        oldWidget.tableData != widget.tableData) {
      final Map<String, double> todayMap = _todayMap(widget.tableData);
      if (todayMap.isNotEmpty) {
        final List<double> vals = todayMap.values.toList();
        final double avg =
            vals.reduce((double a, double b) => a + b) / vals.length;
        setState(() {
          _data = WatchlistPeriodPerformance(
            todayPercent: avg,
            weekPercent: _data!.weekPercent,
            monthPercent: _data!.monthPercent,
            yearPercent: _data!.yearPercent,
            sparkline: _data!.sparkline,
            sparklineDates: _data!.sparklineDates,
          );
        });
      }
    }
  }

  String _keyFor(List<SimpleRowModel> rows) {
    final List<String> symbols = rows
        .map((SimpleRowModel r) => r.symbol.trim().toUpperCase())
        .where((String s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return symbols.join('|');
  }

  Map<String, double> _todayMap(List<SimpleRowModel> rows) {
    final Map<String, double> map = <String, double>{};
    for (final SimpleRowModel row in rows) {
      final String s = row.symbol.trim().toUpperCase();
      if (s.isEmpty) continue;
      final dynamic dayField = row.fields['change1DPercent'];
      double? cp;
      if (dayField is num) {
        cp = dayField.toDouble();
      } else if (dayField is String) {
        cp = double.tryParse(dayField.replaceAll('%', '').trim());
      }
      cp ??= row.changePercent?.toDouble();
      if (cp == null) continue;
      map[s] = cp;
    }
    return map;
  }

  Future<void> _load({bool isRetry = false}) async {
    if (!isRetry) _retryCount = 0;
    final List<SimpleRowModel> rows = widget.tableData;
    final String key = _keyFor(rows);
    _symbolsKey = key;

    if (rows.isEmpty) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _loading = true;
      });
      return;
    }

    final int id = ++_requestId;
    // Shimmer only on the first attempt. Retries stay in the background so
    // the card doesn't flip numbers → shimmer → dashes.
    if (!isRetry) {
      setState(() {
        _loading = true;
        _data = null;
      });
    }

    final Map<String, double> todayMap = _todayMap(rows);

    try {
      final WatchlistPeriodPerformance result = await _service.compute(
        symbols: rows.map((SimpleRowModel r) => r.symbol).toList(),
        fallbackTodayPercents: todayMap,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _data = _mergePerformance(_data, result);
        _loading = false;
      });
      // "Today" comes from the table and does not mean the 12-month fetch
      // succeeded. Retry only when week/month/year/sparkline are still empty.
      if (_longTermMissing(_data) && _retryCount < _maxRetries) {
        _retryCount++;
        final int attempt = _retryCount;
        Future<void>.delayed(Duration(seconds: 3 * attempt), () {
          if (mounted && id == _requestId) _load(isRetry: true);
        });
      }
    } catch (_) {
      if (!mounted || id != _requestId) return;
      if (!isRetry) setState(() => _loading = false);
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final int attempt = _retryCount;
        Future<void>.delayed(Duration(seconds: 3 * attempt), () {
          if (mounted && id == _requestId) _load(isRetry: true);
        });
      }
    }
  }

  static bool _longTermMissing(WatchlistPeriodPerformance? data) {
    if (data == null) return true;
    return data.sparkline.length < 2 &&
        data.weekPercent == null &&
        data.monthPercent == null &&
        data.yearPercent == null;
  }

  /// Keep whatever is already on screen; fill in missing long-term fields
  /// from a later retry instead of replacing a partial result with a worse one.
  static WatchlistPeriodPerformance _mergePerformance(
    WatchlistPeriodPerformance? current,
    WatchlistPeriodPerformance next,
  ) {
    if (current == null) return next;
    final bool nextSpark = next.sparkline.length >= 2;
    final bool currentSpark = current.sparkline.length >= 2;
    return WatchlistPeriodPerformance(
      todayPercent: next.todayPercent ?? current.todayPercent,
      weekPercent: next.weekPercent ?? current.weekPercent,
      monthPercent: next.monthPercent ?? current.monthPercent,
      yearPercent: next.yearPercent ?? current.yearPercent,
      sparkline: nextSpark || !currentSpark ? next.sparkline : current.sparkline,
      sparklineDates:
          nextSpark || !currentSpark ? next.sparklineDates : current.sparklineDates,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final bool compact = widget.compact;

    if (_loading || widget.tableData.isEmpty) {
      return WatchlistShimmer.performanceCard(isDarkMode: isDark);
    }

    final WatchlistPeriodPerformance? data = _data;
    final bool positive = data?.isPositiveYear ?? true;
    final Color lineColor =
        positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark);
    final Color fillColor =
        lineColor.withValues(alpha: isDark ? 0.18 : 0.12);

    final Widget metricRows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _PeriodMetric(
                label: 'Today',
                value: data?.todayPercent,
                isDark: isDark,
                compact: compact,
              ),
            ),
            Expanded(
              child: _PeriodMetric(
                label: 'This Week',
                value: data?.weekPercent,
                isDark: isDark,
                compact: compact,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 11 : 10),
        Row(
          children: [
            Expanded(
              child: _PeriodMetric(
                label: 'This Month',
                value: data?.monthPercent,
                isDark: isDark,
                compact: compact,
              ),
            ),
            Expanded(
              child: _PeriodMetric(
                label: 'This Year',
                value: data?.yearPercent,
                isDark: isDark,
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );

    final Widget metricsBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Watchlist Performance',
          style: HomeUi.sectionTitle(isDark).copyWith(
            fontSize: compact ? 14 : 15,
          ),
        ),
        SizedBox(height: compact ? 8 : 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: metricRows,
          ),
        ),
      ],
    );

    final Widget metricsHeader = compact
        ? metricsBlock
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Watchlist Performance',
                style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 15),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PeriodMetric(
                      label: 'Today',
                      value: data?.todayPercent,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _PeriodMetric(
                      label: 'This Week',
                      value: data?.weekPercent,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PeriodMetric(
                      label: 'This Month',
                      value: data?.monthPercent,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _PeriodMetric(
                      label: 'This Year',
                      value: data?.yearPercent,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          );

    final Widget chart = data != null && data.sparkline.length >= 2
        ? CustomPaint(
            painter: _PerformanceSparklinePainter(
              values: data.sparkline,
              lineColor: lineColor,
              fillColor: fillColor,
            ),
            child: const SizedBox.expand(),
          )
        : Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: HomeUi.borderLight(isDark),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 12, 10, 12)
          : const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: HomeUi.cardDecoration(isDark),
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: metricsHeader),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: chart),
              ],
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = constraints.maxWidth >= 420;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: metricsHeader),
                      const SizedBox(width: 20),
                      SizedBox(width: 200, height: 78, child: chart),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    metricsHeader,
                    const SizedBox(height: 14),
                    SizedBox(height: 64, child: chart),
                  ],
                );
              },
            ),
    );
  }
}

class _PeriodMetric extends StatelessWidget {
  const _PeriodMetric({
    required this.label,
    required this.value,
    required this.isDark,
    this.compact = false,
  });

  final String label;
  final double? value;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    final bool positive = (value ?? 0) >= 0;
    final Color color = !hasValue
        ? HomeUi.muted(isDark)
        : (positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark));

    final String text = !hasValue
        ? '—'
        : '${positive ? '▲' : '▼'} ${value!.abs().toStringAsFixed(2)}%';

    return Padding(
      padding: EdgeInsets.only(right: compact ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: HomeUi.subtitle(isDark).copyWith(
              fontSize: compact ? 11 : 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 13.5 : 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSparklinePainter extends CustomPainter {
  const _PerformanceSparklinePainter({
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
      return Offset(
        size.width * t,
        padY + usableH * (1 - norm),
      );
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
          colors: <Color>[
            fillColor,
            fillColor.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _PerformanceSparklinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.values != values;
  }
}
