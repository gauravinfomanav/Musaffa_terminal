import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Line chart with a top zoom range slider and a draggable actual/forecast split.
///
/// Left of the split: solid blue area. Right: red diagonal hatch (forecast).
class PremiumLineRangeSliderChart extends StatefulWidget {
  const PremiumLineRangeSliderChart({super.key, required this.dark});

  final bool dark;

  @override
  State<PremiumLineRangeSliderChart> createState() =>
      _PremiumLineRangeSliderChartState();
}

class _PremiumLineRangeSliderChartState
    extends State<PremiumLineRangeSliderChart> {
  static const double _rangeBarH = 28;
  static const double _handleR = 9;
  static const double _yLabelW = 40;
  static const double _xLabelH = 28;
  static const double _plotPadT = 8;
  static const double _plotPadR = 10;

  late final List<StaticRangeLinePoint> _data;
  late final DateTime _minDate;
  late final DateTime _maxDate;
  late DateTime _viewStart;
  late DateTime _viewEnd;
  late DateTime _splitDate;

  int? _hoverIndex;
  _DragKind? _drag;

  final Color _blue = const Color(0xFF5B9BD5);
  final Color _red = const Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _data = StaticPremiumChartData.rangeSliderSeries;
    _minDate = _data.first.date;
    _maxDate = _data.last.date;
    _viewStart = _minDate;
    _viewEnd = _maxDate;
    // Split roughly mid-2028 like the reference.
    _splitDate = DateTime(2028, 6, 15);
    if (_splitDate.isBefore(_minDate)) _splitDate = _minDate;
    if (_splitDate.isAfter(_maxDate)) _splitDate = _maxDate;
  }

  int get _totalMs =>
      math.max(1, _maxDate.difference(_minDate).inMilliseconds);

  DateTime _clampDate(DateTime d) {
    if (d.isBefore(_minDate)) return _minDate;
    if (d.isAfter(_maxDate)) return _maxDate;
    return d;
  }

  DateTime _dateAt(double t) {
    final double clamped = t.clamp(0.0, 1.0);
    return _minDate.add(
      Duration(milliseconds: (_totalMs * clamped).round()),
    );
  }

  double _tOf(DateTime d) =>
      d.difference(_minDate).inMilliseconds / _totalMs;

  List<StaticRangeLinePoint> get _visible {
    return _data
        .where(
          (StaticRangeLinePoint p) =>
              !p.date.isBefore(_viewStart) && !p.date.isAfter(_viewEnd),
        )
        .toList();
  }

  void _onHover(Offset local, Size size) {
    final Rect plot = _plotRect(size);
    if (!plot.contains(local)) {
      if (_hoverIndex != null) setState(() => _hoverIndex = null);
      return;
    }
    final List<StaticRangeLinePoint> vis = _visible;
    if (vis.isEmpty) return;
    final int viewMs =
        math.max(1, _viewEnd.difference(_viewStart).inMilliseconds);
    final double t =
        ((local.dx - plot.left) / plot.width).clamp(0.0, 1.0);
    final DateTime at = _viewStart.add(
      Duration(milliseconds: (viewMs * t).round()),
    );
    int best = 0;
    int bestDiff = 1 << 30;
    for (int i = 0; i < vis.length; i++) {
      final int diff = (vis[i].date.difference(at).inMilliseconds).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    // Map visible index → full data index for painter.
    final DateTime hitDate = vis[best].date;
    final int fullIdx = _data.indexWhere((p) => p.date == hitDate);
    if (fullIdx != _hoverIndex) setState(() => _hoverIndex = fullIdx);
  }

  Rect _plotRect(Size size) {
    return Rect.fromLTRB(
      _yLabelW,
      _rangeBarH + _plotPadT,
      size.width - _plotPadR,
      size.height - _xLabelH,
    );
  }

  Rect _rangeTrackRect(Size size) {
    return Rect.fromLTWH(
      _yLabelW,
      (_rangeBarH - 4) / 2,
      size.width - _yLabelW - _plotPadR,
      4,
    );
  }

  void _startDrag(_DragKind kind) => setState(() => _drag = kind);

  void _updateDrag(Offset local, Size size) {
    if (_drag == null) return;
    final Rect track = _rangeTrackRect(size);
    final Rect plot = _plotRect(size);

    if (_drag == _DragKind.rangeStart ||
        _drag == _DragKind.rangeEnd ||
        _drag == _DragKind.rangeWindow) {
      final double t =
          ((local.dx - track.left) / track.width).clamp(0.0, 1.0);
      final DateTime at = _dateAt(t);
      setState(() {
        switch (_drag!) {
          case _DragKind.rangeStart:
            _viewStart = _clampDate(at);
            if (!_viewStart.isBefore(_viewEnd)) {
              _viewStart = _viewEnd.subtract(const Duration(days: 30));
              if (_viewStart.isBefore(_minDate)) _viewStart = _minDate;
            }
            break;
          case _DragKind.rangeEnd:
            _viewEnd = _clampDate(at);
            if (!_viewEnd.isAfter(_viewStart)) {
              _viewEnd = _viewStart.add(const Duration(days: 30));
              if (_viewEnd.isAfter(_maxDate)) _viewEnd = _maxDate;
            }
            break;
          case _DragKind.rangeWindow:
            // Handled via delta in onPanUpdate with previous — use absolute mid.
            break;
          case _DragKind.split:
            break;
        }
        _splitDate = _clampDate(_splitDate);
        if (_splitDate.isBefore(_viewStart)) _splitDate = _viewStart;
        if (_splitDate.isAfter(_viewEnd)) _splitDate = _viewEnd;
      });
    } else if (_drag == _DragKind.split) {
      final int viewMs =
          math.max(1, _viewEnd.difference(_viewStart).inMilliseconds);
      final double t =
          ((local.dx - plot.left) / plot.width).clamp(0.0, 1.0);
      setState(() {
        _splitDate = _clampDate(
          _viewStart.add(Duration(milliseconds: (viewMs * t).round())),
        );
      });
    }
  }

  DateTime? _windowAnchor;

  void _onPanStart(Offset local, Size size) {
    final Rect track = _rangeTrackRect(size).inflate(_handleR + 6);
    final Rect plot = _plotRect(size);
    final double startX =
        track.left + _tOf(_viewStart) * track.width;
    final double endX = track.left + _tOf(_viewEnd) * track.width;

    if ((local - Offset(startX, track.center.dy)).distance <= _handleR + 8) {
      _startDrag(_DragKind.rangeStart);
      return;
    }
    if ((local - Offset(endX, track.center.dy)).distance <= _handleR + 8) {
      _startDrag(_DragKind.rangeEnd);
      return;
    }
    if (local.dy <= _rangeBarH &&
        local.dx >= startX &&
        local.dx <= endX) {
      _windowAnchor = _viewStart;
      _startDrag(_DragKind.rangeWindow);
      _panStartX = local.dx;
      return;
    }

    // Split handle near bottom of plot at split x.
    final int viewMs =
        math.max(1, _viewEnd.difference(_viewStart).inMilliseconds);
    final double splitT =
        (_splitDate.difference(_viewStart).inMilliseconds / viewMs)
            .clamp(0.0, 1.0);
    final double splitX = plot.left + splitT * plot.width;
    final Offset splitHandle = Offset(splitX, plot.bottom);
    if ((local - splitHandle).distance <= 18 ||
        (local.dx - splitX).abs() < 10 &&
            local.dy >= plot.top &&
            local.dy <= plot.bottom + 16) {
      _startDrag(_DragKind.split);
      return;
    }
  }

  double _panStartX = 0;

  void _onPanUpdate(Offset local, Size size) {
    if (_drag == _DragKind.rangeWindow) {
      final Rect track = _rangeTrackRect(size);
      final double dx = local.dx - _panStartX;
      final double dt = dx / track.width;
      final Duration span = _viewEnd.difference(_viewStart);
      DateTime nextStart = _dateAt(_tOf(_windowAnchor!) + dt);
      DateTime nextEnd = nextStart.add(span);
      if (nextStart.isBefore(_minDate)) {
        nextStart = _minDate;
        nextEnd = nextStart.add(span);
      }
      if (nextEnd.isAfter(_maxDate)) {
        nextEnd = _maxDate;
        nextStart = nextEnd.subtract(span);
        if (nextStart.isBefore(_minDate)) nextStart = _minDate;
      }
      setState(() {
        _viewStart = nextStart;
        _viewEnd = nextEnd;
      });
      return;
    }
    _updateDrag(local, size);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;

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
            'LINE CHART · RANGE SLIDER · ACTUAL / FORECAST',
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
                return MouseRegion(
                  onHover: (event) => _onHover(event.localPosition, size),
                  onExit: (_) {
                    if (_hoverIndex != null) {
                      setState(() => _hoverIndex = null);
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
                      });
                    },
                    child: CustomPaint(
                      size: size,
                      painter: _LineRangePainter(
                        dark: dark,
                        data: _data,
                        viewStart: _viewStart,
                        viewEnd: _viewEnd,
                        splitDate: _splitDate,
                        hoverIndex: _hoverIndex,
                        blue: _blue,
                        red: _red,
                        rangeBarH: _rangeBarH,
                        handleR: _handleR,
                        yLabelW: _yLabelW,
                        xLabelH: _xLabelH,
                        plotPadT: _plotPadT,
                        plotPadR: _plotPadR,
                        minDate: _minDate,
                        maxDate: _maxDate,
                      ),
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

enum _DragKind { rangeStart, rangeEnd, rangeWindow, split }

class _LineRangePainter extends CustomPainter {
  _LineRangePainter({
    required this.dark,
    required this.data,
    required this.viewStart,
    required this.viewEnd,
    required this.splitDate,
    required this.hoverIndex,
    required this.blue,
    required this.red,
    required this.rangeBarH,
    required this.handleR,
    required this.yLabelW,
    required this.xLabelH,
    required this.plotPadT,
    required this.plotPadR,
    required this.minDate,
    required this.maxDate,
  });

  final bool dark;
  final List<StaticRangeLinePoint> data;
  final DateTime viewStart;
  final DateTime viewEnd;
  final DateTime splitDate;
  final int? hoverIndex;
  final Color blue;
  final Color red;
  final double rangeBarH;
  final double handleR;
  final double yLabelW;
  final double xLabelH;
  final double plotPadT;
  final double plotPadR;
  final DateTime minDate;
  final DateTime maxDate;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect track = Rect.fromLTWH(
      yLabelW,
      (rangeBarH - 4) / 2,
      size.width - yLabelW - plotPadR,
      4,
    );
    final Rect plot = Rect.fromLTRB(
      yLabelW,
      rangeBarH + plotPadT,
      size.width - plotPadR,
      size.height - xLabelH,
    );

    _paintRangeBar(canvas, track);
    _paintGridAndAxes(canvas, plot, size);
    _paintSeries(canvas, plot);
    _paintSplit(canvas, plot);
    _paintHover(canvas, plot);
  }

  void _paintRangeBar(Canvas canvas, Rect track) {
    final Paint trackPaint = Paint()
      ..color = (dark ? const Color(0xFF2A3344) : const Color(0xFFD5DBE3))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(2)),
      trackPaint,
    );

    final int totalMs =
        math.max(1, maxDate.difference(minDate).inMilliseconds);
    double tOf(DateTime d) =>
        d.difference(minDate).inMilliseconds / totalMs;

    final double left = track.left + tOf(viewStart) * track.width;
    final double right = track.left + tOf(viewEnd) * track.width;
    final Rect sel = Rect.fromLTRB(left, track.top - 1, right, track.bottom + 1);

    canvas.drawRRect(
      RRect.fromRectAndRadius(sel, const Radius.circular(2)),
      Paint()
        ..color = (dark ? const Color(0xFF4A5568) : const Color(0xFFB0B8C4)),
    );

    _drawRangeHandle(canvas, Offset(left, track.center.dy));
    _drawRangeHandle(canvas, Offset(right, track.center.dy));
  }

  void _drawRangeHandle(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      handleR,
      Paint()
        ..color = dark ? const Color(0xFF2D3748) : const Color(0xFFE8ECF1),
    );
    canvas.drawCircle(
      c,
      handleR,
      Paint()
        ..color = dark ? const Color(0xFF718096) : const Color(0xFF9AA3B2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final Paint grip = Paint()
      ..color = dark ? const Color(0xFFA0AEC0) : const Color(0xFF6B7280)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - 2.2, c.dy - 3.5),
      Offset(c.dx - 2.2, c.dy + 3.5),
      grip,
    );
    canvas.drawLine(
      Offset(c.dx + 2.2, c.dy - 3.5),
      Offset(c.dx + 2.2, c.dy + 3.5),
      grip,
    );
  }

  void _paintGridAndAxes(Canvas canvas, Rect plot, Size size) {
    final Color grid =
        dark ? UsPremiumPalette.darkGrid : const Color(0xFFE6EBF1);
    final Color labelC = UsPremiumPalette.muted(dark);
    final TextStyle labelStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: labelC,
    );

    // Y ticks 50..350
    const double yMin = 50;
    const double yMax = 350;
    for (int v = 50; v <= 350; v += 50) {
      final double t = (v - yMin) / (yMax - yMin);
      final double y = plot.bottom - t * plot.height;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
      final TextPainter tp = TextPainter(
        text: TextSpan(text: '$v', style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(plot.left - tp.width - 6, y - tp.height / 2));
    }

    // Vertical grid + x labels for visible window.
    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);
    final List<DateTime> ticks = _xTicks(viewStart, viewEnd);
    for (final DateTime d in ticks) {
      final double t =
          d.difference(viewStart).inMilliseconds / viewMs;
      if (t < 0 || t > 1) continue;
      final double x = plot.left + t * plot.width;
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
      final String label = d.month == 1
          ? DateFormat('MMM yyyy').format(d)
          : DateFormat('MMM').format(d);
      final TextPainter tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, plot.bottom + 8),
      );
    }

    // Plot border
    canvas.drawRect(
      plot,
      Paint()
        ..color = grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  List<DateTime> _xTicks(DateTime start, DateTime end) {
    final List<DateTime> out = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month >= 7 ? 7 : 1, 1);
    if (cursor.isBefore(start)) {
      cursor = start.month >= 7
          ? DateTime(start.year + 1, 1, 1)
          : DateTime(start.year, 7, 1);
    }
    while (!cursor.isAfter(end)) {
      out.add(cursor);
      cursor = cursor.month == 1
          ? DateTime(cursor.year, 7, 1)
          : DateTime(cursor.year + 1, 1, 1);
    }
    return out;
  }

  Offset _pointOf(StaticRangeLinePoint p, Rect plot, int viewMs) {
    const double yMin = 50;
    const double yMax = 350;
    final double tx =
        p.date.difference(viewStart).inMilliseconds / viewMs;
    final double ty = (p.value - yMin) / (yMax - yMin);
    return Offset(
      plot.left + tx.clamp(0.0, 1.0) * plot.width,
      plot.bottom - ty.clamp(0.0, 1.0) * plot.height,
    );
  }

  void _paintSeries(Canvas canvas, Rect plot) {
    final List<StaticRangeLinePoint> vis = data
        .where(
          (StaticRangeLinePoint p) =>
              !p.date.isBefore(viewStart) && !p.date.isAfter(viewEnd),
        )
        .toList();
    if (vis.length < 2) return;

    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);

    // Build continuous polyline; split into actual / forecast at splitDate.
    final List<Offset> all = <Offset>[
      for (final StaticRangeLinePoint p in vis) _pointOf(p, plot, viewMs),
    ];

    // Insert interpolated split point so fills meet cleanly.
    Offset? splitPt;
    int splitAfter = -1;
    for (int i = 0; i < vis.length - 1; i++) {
      final DateTime a = vis[i].date;
      final DateTime b = vis[i + 1].date;
      if (!splitDate.isBefore(a) && splitDate.isBefore(b) ||
          splitDate == a) {
        final double span =
            math.max(1, b.difference(a).inMilliseconds).toDouble();
        final double u =
            splitDate.difference(a).inMilliseconds / span;
        final Offset pa = all[i];
        final Offset pb = all[i + 1];
        splitPt = Offset(
          ui.lerpDouble(pa.dx, pb.dx, u)!,
          ui.lerpDouble(pa.dy, pb.dy, u)!,
        );
        splitAfter = i;
        break;
      }
    }
    if (splitPt == null) {
      if (!splitDate.isAfter(vis.first.date)) {
        splitPt = all.first;
        splitAfter = -1;
      } else {
        splitPt = all.last;
        splitAfter = vis.length - 1;
      }
    }

    final List<Offset> left = <Offset>[
      for (int i = 0; i <= splitAfter && i < all.length; i++) all[i],
      if (splitAfter < all.length - 1) splitPt,
    ];
    final List<Offset> right = <Offset>[
      splitPt,
      for (int i = splitAfter + 1; i < all.length; i++) all[i],
    ];

    if (left.length >= 2) {
      _fillSolid(canvas, plot, left, blue.withValues(alpha: dark ? 0.35 : 0.28));
      _strokeLine(canvas, left, blue, 2);
    }
    if (right.length >= 2) {
      _fillHatch(canvas, plot, right, red);
      _strokeLine(canvas, right, red, 2);
    }
  }

  void _fillSolid(Canvas canvas, Rect plot, List<Offset> pts, Color color) {
    final Path path = Path()..moveTo(pts.first.dx, plot.bottom);
    path.lineTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.lineTo(pts.last.dx, plot.bottom);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _fillHatch(Canvas canvas, Rect plot, List<Offset> pts, Color color) {
    final Path area = Path()..moveTo(pts.first.dx, plot.bottom);
    area.lineTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      area.lineTo(pts[i].dx, pts[i].dy);
    }
    area.lineTo(pts.last.dx, plot.bottom);
    area.close();

    canvas.save();
    canvas.clipPath(area);
    canvas.drawPath(
      area,
      Paint()..color = color.withValues(alpha: dark ? 0.12 : 0.08),
    );

    final Paint hatch = Paint()
      ..color = color.withValues(alpha: dark ? 0.55 : 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double minX = pts.first.dx;
    final double maxX = pts.last.dx;
    final double step = 7;
    // Diagonal stripes (top-left → bottom-right).
    for (double x = minX - plot.height; x < maxX + plot.height; x += step) {
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x + plot.height, plot.bottom),
        hatch,
      );
    }
    canvas.restore();
  }

  void _strokeLine(Canvas canvas, List<Offset> pts, Color color, double w) {
    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = w
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  void _paintSplit(Canvas canvas, Rect plot) {
    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);
    final double t =
        (splitDate.difference(viewStart).inMilliseconds / viewMs)
            .clamp(0.0, 1.0);
    final double x = plot.left + t * plot.width;

    canvas.drawLine(
      Offset(x, plot.top),
      Offset(x, plot.bottom),
      Paint()
        ..color = blue.withValues(alpha: 0.85)
        ..strokeWidth = 1.4,
    );

    final Offset c = Offset(x, plot.bottom);
    canvas.drawCircle(
      c,
      handleR,
      Paint()
        ..color = dark ? const Color(0xFF2D3748) : const Color(0xFFE8ECF1),
    );
    canvas.drawCircle(
      c,
      handleR,
      Paint()
        ..color = dark ? const Color(0xFF718096) : const Color(0xFF9AA3B2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final Paint grip = Paint()
      ..color = dark ? const Color(0xFFA0AEC0) : const Color(0xFF6B7280)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - 2.2, c.dy - 3.5),
      Offset(c.dx - 2.2, c.dy + 3.5),
      grip,
    );
    canvas.drawLine(
      Offset(c.dx + 2.2, c.dy - 3.5),
      Offset(c.dx + 2.2, c.dy + 3.5),
      grip,
    );
  }

  void _paintHover(Canvas canvas, Rect plot) {
    if (hoverIndex == null || hoverIndex! < 0 || hoverIndex! >= data.length) {
      return;
    }
    final StaticRangeLinePoint p = data[hoverIndex!];
    if (p.date.isBefore(viewStart) || p.date.isAfter(viewEnd)) return;

    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);
    final Offset pt = _pointOf(p, plot, viewMs);
    final bool forecast = p.date.isAfter(splitDate);
    final Color c = forecast ? red : blue;

    canvas.drawCircle(pt, 4, Paint()..color = c);
    canvas.drawCircle(
      pt,
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final String text = p.value.round().toString();
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: UsPremiumPalette.text(dark),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final RRect bubble = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pt.dx, pt.dy - 22),
        width: tp.width + 14,
        height: tp.height + 10,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = UsPremiumPalette.surface(dark).withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = UsPremiumPalette.border(dark)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(
      canvas,
      Offset(
        bubble.left + (bubble.width - tp.width) / 2,
        bubble.top + (bubble.height - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LineRangePainter old) {
    return old.dark != dark ||
        old.viewStart != viewStart ||
        old.viewEnd != viewEnd ||
        old.splitDate != splitDate ||
        old.hoverIndex != hoverIndex ||
        old.data != data;
  }
}
