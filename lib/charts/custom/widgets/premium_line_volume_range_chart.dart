import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Professional line + volume chart with a top zoom range slider.
///
/// Matches a clean Syncfusion-style layout: range handles, price pane,
/// volume bars, and month axis.
class PremiumLineVolumeRangeChart extends StatefulWidget {
  const PremiumLineVolumeRangeChart({super.key, required this.dark});

  final bool dark;

  @override
  State<PremiumLineVolumeRangeChart> createState() =>
      _PremiumLineVolumeRangeChartState();
}

class _PremiumLineVolumeRangeChartState
    extends State<PremiumLineVolumeRangeChart> {
  static const double _rangeBarH = 28;
  static const double _handleR = 8;
  static const double _yLabelW = 42;
  static const double _xLabelH = 28;
  static const double _plotPadT = 8;
  static const double _plotPadR = 10;
  static const double _volumeFrac = 0.18;
  static const double _paneGap = 6;
  static const Duration _tipDuration = Duration(milliseconds: 160);
  static const Curve _tipCurve = Curves.easeOutCubic;

  late final List<StaticVolumePricePoint> _data;
  late final DateTime _minDate;
  late final DateTime _maxDate;
  late DateTime _viewStart;
  late DateTime _viewEnd;

  int? _hoverIndex;
  Offset? _tipAt;
  bool _tipVisible = false;
  _DragKind? _drag;
  double? _panStartX;
  DateTime? _windowAnchor;

  Color get _accent => widget.dark
      ? const Color(0xFF4FA89E)
      : UsPremiumPalette.tealAccent;

  @override
  void initState() {
    super.initState();
    _data = StaticPremiumChartData.lineVolumeRangeSeries;
    _minDate = _data.first.date;
    _maxDate = _data.last.date;
    _viewStart = _minDate;
    _viewEnd = _maxDate;
  }

  int get _totalMs =>
      math.max(1, _maxDate.difference(_minDate).inMilliseconds);

  DateTime _clampDate(DateTime d) {
    if (d.isBefore(_minDate)) return _minDate;
    if (d.isAfter(_maxDate)) return _maxDate;
    return d;
  }

  DateTime _dateAt(double t) {
    return _minDate.add(
      Duration(milliseconds: (_totalMs * t.clamp(0.0, 1.0)).round()),
    );
  }

  double _tOf(DateTime d) =>
      d.difference(_minDate).inMilliseconds / _totalMs;

  Rect _fullPlot(Size size) {
    return Rect.fromLTRB(
      _yLabelW,
      _rangeBarH + _plotPadT,
      size.width - _plotPadR,
      size.height - _xLabelH,
    );
  }

  Rect _pricePlot(Size size) {
    final Rect full = _fullPlot(size);
    final double volH = full.height * _volumeFrac;
    return Rect.fromLTRB(
      full.left,
      full.top,
      full.right,
      full.bottom - volH - _paneGap,
    );
  }

  Rect _rangeTrackRect(Size size) {
    return Rect.fromLTWH(
      _yLabelW,
      (_rangeBarH - 3) / 2,
      size.width - _yLabelW - _plotPadR,
      3,
    );
  }

  List<StaticVolumePricePoint> get _visible {
    return _data
        .where(
          (StaticVolumePricePoint p) =>
              !p.date.isBefore(_viewStart) && !p.date.isAfter(_viewEnd),
        )
        .toList();
  }

  (double, double) _priceExtents(List<StaticVolumePricePoint> vis) {
    if (vis.isEmpty) return (980.0, 1070.0);
    double lo = vis.first.price;
    double hi = vis.first.price;
    for (final StaticVolumePricePoint p in vis) {
      if (p.price < lo) lo = p.price;
      if (p.price > hi) hi = p.price;
    }
    final double pad = math.max(8, (hi - lo) * 0.12);
    lo = (lo - pad).floorToDouble();
    hi = (hi + pad).ceilToDouble();
    // Snap toward nice 10s like the reference.
    lo = (lo / 10).floor() * 10;
    hi = (hi / 10).ceil() * 10;
    if (hi - lo < 40) {
      final double mid = (lo + hi) / 2;
      lo = mid - 20;
      hi = mid + 20;
    }
    return (lo, hi);
  }

  Offset? _pricePointForIndex(int index, Size size) {
    if (index < 0 || index >= _data.length) return null;
    final StaticVolumePricePoint p = _data[index];
    if (p.date.isBefore(_viewStart) || p.date.isAfter(_viewEnd)) return null;
    final List<StaticVolumePricePoint> vis = _visible;
    final int visIdx = vis.indexWhere((StaticVolumePricePoint x) => x.date == p.date);
    if (visIdx < 0) return null;
    final (double yMin, double yMax) = _priceExtents(vis);
    final Rect plot = _pricePlot(size);
    final double slot = plot.width / vis.length;
    final double px = plot.left + (visIdx + 0.5) * slot;
    final double ty = 1 - ((p.price - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
    return Offset(px, plot.top + ty * plot.height);
  }

  void _onHover(Offset local, Size size) {
    final Rect hit = _fullPlot(size);
    if (!hit.contains(local)) {
      if (_hoverIndex != null || _tipVisible) {
        setState(() {
          _hoverIndex = null;
          _tipVisible = false;
        });
      }
      return;
    }

    int best = -1;
    double bestDx = double.infinity;
    for (int i = 0; i < _data.length; i++) {
      final Offset? pt = _pricePointForIndex(i, size);
      if (pt == null) continue;
      final double dx = (pt.dx - local.dx).abs();
      if (dx < bestDx) {
        bestDx = dx;
        best = i;
      }
    }
    final int? next = best >= 0 ? best : null;
    setState(() {
      _hoverIndex = next;
      if (next != null) {
        _tipVisible = true;
        _tipAt = _pricePointForIndex(next, size);
      } else {
        _tipVisible = false;
      }
    });
  }

  void _onPanStart(Offset local, Size size) {
    final Rect track = _rangeTrackRect(size).inflate(_handleR + 6);
    final double startX = track.left + _tOf(_viewStart) * track.width;
    final double endX = track.left + _tOf(_viewEnd) * track.width;

    if ((local - Offset(startX, track.center.dy)).distance <= _handleR + 8) {
      setState(() => _drag = _DragKind.rangeStart);
      return;
    }
    if ((local - Offset(endX, track.center.dy)).distance <= _handleR + 8) {
      setState(() => _drag = _DragKind.rangeEnd);
      return;
    }
    if (local.dy <= _rangeBarH && local.dx >= startX && local.dx <= endX) {
      _windowAnchor = _viewStart;
      _panStartX = local.dx;
      setState(() => _drag = _DragKind.rangeWindow);
    }
  }

  void _onPanUpdate(Offset local, Size size) {
    if (_drag == null) return;
    final Rect track = _rangeTrackRect(size);

    if (_drag == _DragKind.rangeWindow &&
        _panStartX != null &&
        _windowAnchor != null) {
      final double dx = local.dx - _panStartX!;
      final double dt = dx / track.width;
      final int spanMs =
          math.max(1, _viewEnd.difference(_viewStart).inMilliseconds);
      DateTime nextStart = _clampDate(
        _windowAnchor!.add(
          Duration(milliseconds: (_totalMs * dt).round()),
        ),
      );
      DateTime nextEnd = nextStart.add(Duration(milliseconds: spanMs));
      if (nextEnd.isAfter(_maxDate)) {
        nextEnd = _maxDate;
        nextStart = nextEnd.subtract(Duration(milliseconds: spanMs));
        if (nextStart.isBefore(_minDate)) nextStart = _minDate;
      }
      setState(() {
        _viewStart = nextStart;
        _viewEnd = nextEnd;
      });
      return;
    }

    final double t =
        ((local.dx - track.left) / track.width).clamp(0.0, 1.0);
    final DateTime at = _dateAt(t);
    setState(() {
      if (_drag == _DragKind.rangeStart) {
        _viewStart = _clampDate(at);
        if (!_viewStart.isBefore(_viewEnd)) {
          _viewStart = _viewEnd.subtract(const Duration(days: 14));
          if (_viewStart.isBefore(_minDate)) _viewStart = _minDate;
        }
      } else if (_drag == _DragKind.rangeEnd) {
        _viewEnd = _clampDate(at);
        if (!_viewEnd.isAfter(_viewStart)) {
          _viewEnd = _viewStart.add(const Duration(days: 14));
          if (_viewEnd.isAfter(_maxDate)) _viewEnd = _maxDate;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final Color accent = _accent;
    final List<StaticVolumePricePoint> vis = _visible;
    final (double yMin, double yMax) = _priceExtents(vis);

    return Container(
      height: 420,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UsPremiumPalette.border(dark)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'LINE · VOLUME · RANGE SLIDER',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: UsPremiumPalette.muted(dark),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Size size = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final StaticVolumePricePoint? hover =
                    _hoverIndex == null ? null : _data[_hoverIndex!];

                return MouseRegion(
                  onHover: (event) => _onHover(event.localPosition, size),
                  onExit: (_) {
                    if (_hoverIndex != null || _tipVisible) {
                      setState(() {
                        _hoverIndex = null;
                        _tipVisible = false;
                      });
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _onPanStart(d.localPosition, size),
                    onPanUpdate: (d) => _onPanUpdate(d.localPosition, size),
                    onPanEnd: (_) {
                      setState(() {
                        _drag = null;
                        _windowAnchor = null;
                        _panStartX = null;
                      });
                    },
                    child: Stack(
                      children: <Widget>[
                        CustomPaint(
                          size: size,
                          painter: _LineVolumePainter(
                            dark: dark,
                            data: _data,
                            viewStart: _viewStart,
                            viewEnd: _viewEnd,
                            hoverIndex: _hoverIndex,
                            accent: accent,
                            rangeBarH: _rangeBarH,
                            handleR: _handleR,
                            yLabelW: _yLabelW,
                            xLabelH: _xLabelH,
                            plotPadT: _plotPadT,
                            plotPadR: _plotPadR,
                            volumeFrac: _volumeFrac,
                            paneGap: _paneGap,
                            minDate: _minDate,
                            maxDate: _maxDate,
                            yMin: yMin,
                            yMax: yMax,
                          ),
                        ),
                        if (_tipAt != null && hover != null)
                          Positioned(
                            left: (_tipAt!.dx + 12)
                                .clamp(8.0, size.width - 148),
                            top: (_tipAt!.dy - 52)
                                .clamp(4.0, size.height - 80),
                            child: IgnorePointer(
                              child: _HoverCard(
                                visible: _tipVisible,
                                dark: dark,
                                accent: accent,
                                date: hover.date,
                                price: hover.price,
                                volumeK: hover.volumeK,
                                duration: _tipDuration,
                                curve: _tipCurve,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _DragKind { rangeStart, rangeEnd, rangeWindow }

class _HoverCard extends StatelessWidget {
  const _HoverCard({
    required this.visible,
    required this.dark,
    required this.accent,
    required this.date,
    required this.price,
    required this.volumeK,
    required this.duration,
    required this.curve,
  });

  final bool visible;
  final bool dark;
  final Color accent;
  final DateTime date;
  final double price;
  final double volumeK;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat('MMM dd, yyyy');
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: curve,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        duration: duration,
        curve: curve,
        child: Container(
          width: 136,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: UsPremiumPalette.surface(dark).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: UsPremiumPalette.border(dark)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                fmt.format(date),
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: UsPremiumPalette.muted(dark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Vol  ${volumeK.toStringAsFixed(0)}K',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: UsPremiumPalette.muted(dark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineVolumePainter extends CustomPainter {
  _LineVolumePainter({
    required this.dark,
    required this.data,
    required this.viewStart,
    required this.viewEnd,
    required this.hoverIndex,
    required this.accent,
    required this.rangeBarH,
    required this.handleR,
    required this.yLabelW,
    required this.xLabelH,
    required this.plotPadT,
    required this.plotPadR,
    required this.volumeFrac,
    required this.paneGap,
    required this.minDate,
    required this.maxDate,
    required this.yMin,
    required this.yMax,
  });

  final bool dark;
  final List<StaticVolumePricePoint> data;
  final DateTime viewStart;
  final DateTime viewEnd;
  final int? hoverIndex;
  final Color accent;
  final double rangeBarH;
  final double handleR;
  final double yLabelW;
  final double xLabelH;
  final double plotPadT;
  final double plotPadR;
  final double volumeFrac;
  final double paneGap;
  final DateTime minDate;
  final DateTime maxDate;
  final double yMin;
  final double yMax;

  int get _totalMs =>
      math.max(1, maxDate.difference(minDate).inMilliseconds);

  double _tOf(DateTime d) =>
      d.difference(minDate).inMilliseconds / _totalMs;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect track = Rect.fromLTWH(
      yLabelW,
      (rangeBarH - 3) / 2,
      size.width - yLabelW - plotPadR,
      3,
    );
    final Rect full = Rect.fromLTRB(
      yLabelW,
      rangeBarH + plotPadT,
      size.width - plotPadR,
      size.height - xLabelH,
    );
    final double volH = full.height * volumeFrac;
    final Rect price = Rect.fromLTRB(
      full.left,
      full.top,
      full.right,
      full.bottom - volH - paneGap,
    );
    final Rect volume = Rect.fromLTRB(
      full.left,
      full.bottom - volH,
      full.right,
      full.bottom,
    );

    _paintRangeBar(canvas, track);
    _paintPriceGrid(canvas, price);
    _paintVolumePane(canvas, volume);
    _paintXAxis(canvas, full, size);
    _paintSeries(canvas, price, volume);
    _paintHoverLine(canvas, price, volume);
  }

  void _paintRangeBar(Canvas canvas, Rect track) {
    final Color muted = UsPremiumPalette.muted(dark);
    final Color border = UsPremiumPalette.border(dark);

    canvas.drawRRect(
      RRect.fromRectAndRadius(track.inflate(1), const Radius.circular(2)),
      Paint()
        ..color = dark ? const Color(0xFF243044) : const Color(0xFFE8EEF4),
    );

    final double startX = track.left + _tOf(viewStart) * track.width;
    final double endX = track.left + _tOf(viewEnd) * track.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(startX, track.top - 1, endX, track.bottom + 1),
        const Radius.circular(2),
      ),
      Paint()..color = accent.withValues(alpha: dark ? 0.35 : 0.22),
    );

    void drawHandle(double x) {
      final Offset c = Offset(x, track.center.dy);
      canvas.drawCircle(c, handleR, Paint()..color = UsPremiumPalette.surface(dark));
      canvas.drawCircle(
        c,
        handleR,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      final Paint grip = Paint()
        ..color = muted.withValues(alpha: 0.7)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(c + const Offset(-2.2, -3), c + const Offset(-2.2, 3), grip);
      canvas.drawLine(c + const Offset(2.2, -3), c + const Offset(2.2, 3), grip);
    }

    drawHandle(startX);
    drawHandle(endX);
  }

  void _paintPriceGrid(Canvas canvas, Rect plot) {
    final Color grid = UsPremiumPalette.grid(dark);
    final Color muted = UsPremiumPalette.muted(dark);
    final TextStyle labelStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: muted,
    );

    canvas.drawRect(
      plot,
      Paint()
        ..color = grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final int steps = math.max(4, ((yMax - yMin) / 10).round());
    final double step = (yMax - yMin) / steps;
    for (int i = 0; i <= steps; i++) {
      final double y = yMin + step * i;
      final double ty = 1 - ((y - yMin) / (yMax - yMin));
      final double py = plot.top + ty * plot.height;
      canvas.drawLine(
        Offset(plot.left, py),
        Offset(plot.right, py),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
      final String label = y >= 1000
          ? NumberFormat('#,###').format(y.round())
          : y.round().toString();
      final TextPainter tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: yLabelW - 4);
      tp.paint(canvas, Offset(plot.left - tp.width - 6, py - tp.height / 2));
    }

    // Month vertical grid lines.
    DateTime cursor = DateTime(viewStart.year, viewStart.month, 1);
    if (cursor.isBefore(viewStart)) {
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);
    while (!cursor.isAfter(viewEnd)) {
      final double tx =
          cursor.difference(viewStart).inMilliseconds / viewMs;
      if (tx >= 0 && tx <= 1) {
        final double px = plot.left + tx * plot.width;
        canvas.drawLine(
          Offset(px, plot.top),
          Offset(px, plot.bottom),
          Paint()
            ..color = grid
            ..strokeWidth = 1,
        );
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  }

  void _paintVolumePane(Canvas canvas, Rect plot) {
    final Color grid = UsPremiumPalette.grid(dark);
    canvas.drawRect(
      plot,
      Paint()
        ..color = grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintXAxis(Canvas canvas, Rect full, Size size) {
    final Color muted = UsPremiumPalette.muted(dark);
    final TextStyle labelStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: muted,
    );
    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);

    DateTime cursor = DateTime(viewStart.year, viewStart.month, 1);
    if (cursor.isBefore(viewStart)) {
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    int? lastYear;
    while (!cursor.isAfter(viewEnd)) {
      final double tx =
          cursor.difference(viewStart).inMilliseconds / viewMs;
      if (tx >= 0 && tx <= 1) {
        final double px = full.left + tx * full.width;
        final bool showYear =
            lastYear == null || cursor.year != lastYear || cursor.month == 1;
        lastYear = cursor.year;
        final String text = showYear
            ? DateFormat('MMM yyyy').format(cursor)
            : DateFormat('MMM').format(cursor);
        final TextPainter tp = TextPainter(
          text: TextSpan(text: text, style: labelStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(px - tp.width / 2, full.bottom + 6));
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  }

  void _paintSeries(Canvas canvas, Rect price, Rect volume) {
    final List<StaticVolumePricePoint> vis = data
        .where(
          (StaticVolumePricePoint p) =>
              !p.date.isBefore(viewStart) && !p.date.isAfter(viewEnd),
        )
        .toList();
    if (vis.length < 2) return;

    double maxVol = 1;
    for (final StaticVolumePricePoint p in vis) {
      if (p.volumeK > maxVol) maxVol = p.volumeK;
    }

    // Equal slot per bar → thinner bars with generous gap.
    final double slot = volume.width / vis.length;
    final double barW = math.max(1.8, slot * 0.32);

    final Paint barPaint = Paint()
      ..color = accent.withValues(alpha: dark ? 0.50 : 0.62)
      ..style = PaintingStyle.fill;

    final Path line = Path();
    for (int i = 0; i < vis.length; i++) {
      final StaticVolumePricePoint p = vis[i];
      // Index-based x keeps bar gaps even; line still tracks the same centers.
      final double px = volume.left + (i + 0.5) * slot;
      final double ty =
          1 - ((p.price - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
      final double py = price.top + ty * price.height;
      if (i == 0) {
        line.moveTo(px, py);
      } else {
        line.lineTo(px, py);
      }

      final double vh = (p.volumeK / maxVol) * volume.height * 0.88;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            px - barW / 2,
            volume.bottom - vh,
            barW,
            vh,
          ),
          const Radius.circular(1.5),
        ),
        barPaint,
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  void _paintHoverLine(Canvas canvas, Rect price, Rect volume) {
    if (hoverIndex == null) return;
    final StaticVolumePricePoint p = data[hoverIndex!];
    final List<StaticVolumePricePoint> vis = data
        .where(
          (StaticVolumePricePoint x) =>
              !x.date.isBefore(viewStart) && !x.date.isAfter(viewEnd),
        )
        .toList();
    final int visIdx =
        vis.indexWhere((StaticVolumePricePoint x) => x.date == p.date);
    if (visIdx < 0) return;

    final double slot = price.width / vis.length;
    final double px = price.left + (visIdx + 0.5) * slot;
    final double ty =
        1 - ((p.price - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
    final Offset point = Offset(px, price.top + ty * price.height);

    final Paint dashPaint = Paint()
      ..color = (dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))
          .withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const double dash = 3.5;
    const double gap = 2.5;
    double y = price.top;
    while (y < volume.bottom) {
      final double y2 = math.min(y + dash, volume.bottom);
      canvas.drawLine(Offset(px, y), Offset(px, y2), dashPaint);
      y += dash + gap;
    }

    canvas.drawCircle(point, 4.2, Paint()..color = accent);
    canvas.drawCircle(
      point,
      4.2,
      Paint()
        ..color = UsPremiumPalette.surface(dark)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _LineVolumePainter old) {
    return old.dark != dark ||
        old.viewStart != viewStart ||
        old.viewEnd != viewEnd ||
        old.hoverIndex != hoverIndex ||
        old.accent != accent ||
        old.yMin != yMin ||
        old.yMax != yMax ||
        old.data != data;
  }
}
