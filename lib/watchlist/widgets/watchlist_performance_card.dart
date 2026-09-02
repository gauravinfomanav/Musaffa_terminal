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

  WatchlistPeriodPerformance? _data;
  bool _loading = true;
  String? _symbolsKey;
  int _requestId = 0;

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
      setState(() {
        final WatchlistPeriodPerformance instant =
            _instantFromTable(widget.tableData);
        _data = WatchlistPeriodPerformance(
          todayPercent: instant.todayPercent,
          weekPercent: _data!.weekPercent,
          monthPercent: _data!.monthPercent,
          yearPercent: instant.yearPercent,
          sparkline: _data!.sparkline,
          sparklineDates: _data!.sparklineDates,
        );
      });
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
      final double? cp = _asDouble(row.fields['change1DPercent']) ??
          row.changePercent?.toDouble();
      if (cp == null) continue;
      map[s] = cp;
    }
    return map;
  }

  List<double> _sinceAddedPercents(List<SimpleRowModel> rows) {
    final List<double> out = <double>[];
    for (final SimpleRowModel row in rows) {
      final double? added = _asDouble(row.fields['addedPrice']);
      final double? current = _asDouble(row.fields['currentPrice']) ??
          row.price?.toDouble();
      if (added == null || added <= 0 || current == null) continue;
      final double? stored = _asDouble(row.fields['gainLossPercent']);
      out.add(stored ?? ((current - added) / added) * 100);
    }
    return out;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '').replaceAll('\$', '').trim());
    }
    return null;
  }

  WatchlistPeriodPerformance _instantFromTable(List<SimpleRowModel> rows) {
    return _service.fromTable(
      todayPercents: _todayMap(rows).values.toList(),
      sinceAddedPercents: _sinceAddedPercents(rows),
    );
  }

  Future<void> _load() async {
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
    final WatchlistPeriodPerformance instant = _instantFromTable(rows);
    setState(() {
      _data = instant;
      _loading = false;
    });

    try {
      final WatchlistPeriodPerformance history =
          await _service.fromRecentCloses(
        rows.map((SimpleRowModel r) => r.symbol).toList(),
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _data = WatchlistPeriodPerformance(
          todayPercent: instant.todayPercent,
          weekPercent: history.weekPercent,
          monthPercent: history.monthPercent,
          yearPercent: instant.yearPercent,
          sparkline: history.sparkline,
          sparklineDates: history.sparklineDates,
        );
      });
    } catch (_) {}
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
                loading: data?.weekPercent == null,
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
                loading: data?.monthPercent == null,
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
                      loading: data?.weekPercent == null,
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
                      loading: data?.monthPercent == null,
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
        : LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return WatchlistShimmer.sparkline(
                isDarkMode: isDark,
                width: constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 200,
                height: constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 64,
              );
            },
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
    this.loading = false,
  });

  final String label;
  final double? value;
  final bool isDark;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    final bool positive = (value ?? 0) >= 0;
    final Color color = !hasValue
        ? HomeUi.muted(isDark)
        : (positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark));

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
          if (loading)
            WatchlistShimmer.metricValue(isDarkMode: isDark, compact: compact)
          else
            Text(
              !hasValue
                  ? '—'
                  : '${positive ? '▲' : '▼'} ${value!.abs().toStringAsFixed(2)}%',
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
