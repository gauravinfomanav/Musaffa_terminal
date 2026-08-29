import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/charts/custom/static_premium_chart_data.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Clean intraday line + markers with a top zoom range slider.
///
/// Value labels stay visible by default. Hover upgrades the active point with
/// a filled tip, dashed crosshair, and axis date tooltip.
class PremiumIntradayMarkerLineChart extends StatefulWidget {
  const PremiumIntradayMarkerLineChart({super.key, required this.dark});

  final bool dark;

  @override
  State<PremiumIntradayMarkerLineChart> createState() =>
      _PremiumIntradayMarkerLineChartState();
}

class _PremiumIntradayMarkerLineChartState
    extends State<PremiumIntradayMarkerLineChart> {
  static const double _rangeBarH = 30;
  static const double _handleR = 8;
  static const double _yLabelW = 44;
  static const double _xLabelH = 34;
  static const double _plotPadT = 22;
  static const double _plotPadR = 8;
  static const double _yMin = 99.0;
  static const double _yMax = 102.5;
  static const double _yStep = 0.5;

  late final List<StaticRangeLinePoint> _data;
  late final DateTime _minDate;
  late final DateTime _maxDate;
  late DateTime _viewStart;
  late DateTime _viewEnd;

  int? _hoverIndex;
  _DragKind? _drag;
  double? _panStartX;
  DateTime? _windowAnchor;

  Color get _line => widget.dark
      ? UsPremiumPalette.electricBlueSoft
      : UsPremiumPalette.electricBlue;

  @override
  void initState() {
    super.initState();
    _data = StaticPremiumChartData.intradayMarkerSeries;
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
      (_rangeBarH - 3) / 2,
      size.width - _yLabelW - _plotPadR,
      3,
    );
  }

  Offset? _pointForIndex(int index, Size size) {
    if (index < 0 || index >= _data.length) return null;
    final StaticRangeLinePoint p = _data[index];
    if (p.date.isBefore(_viewStart) || p.date.isAfter(_viewEnd)) return null;
    final Rect plot = _plotRect(size);
    final int viewMs =
        math.max(1, _viewEnd.difference(_viewStart).inMilliseconds);
    final double tx =
        p.date.difference(_viewStart).inMilliseconds / viewMs;
    final double ty = 1 - ((p.value - _yMin) / (_yMax - _yMin)).clamp(0.0, 1.0);
    return Offset(plot.left + tx * plot.width, plot.top + ty * plot.height);
  }

  void _onHover(Offset local, Size size) {
    final Rect plot = _plotRect(size);
    if (!plot.contains(local)) {
      if (_hoverIndex != null) setState(() => _hoverIndex = null);
      return;
    }

    int bestFull = -1;
    double bestDx = double.infinity;
    for (int i = 0; i < _data.length; i++) {
      final Offset? pt = _pointForIndex(i, size);
      if (pt == null) continue;
      final double dx = (pt.dx - local.dx).abs();
      if (dx < bestDx) {
        bestDx = dx;
        bestFull = i;
      }
    }
    final int? next = bestFull >= 0 ? bestFull : null;
    if (next != _hoverIndex) setState(() => _hoverIndex = next);
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
          _viewStart = _viewEnd.subtract(const Duration(minutes: 30));
          if (_viewStart.isBefore(_minDate)) _viewStart = _minDate;
        }
      } else if (_drag == _DragKind.rangeEnd) {
        _viewEnd = _clampDate(at);
        if (!_viewEnd.isAfter(_viewStart)) {
          _viewEnd = _viewStart.add(const Duration(minutes: 30));
          if (_viewEnd.isAfter(_maxDate)) _viewEnd = _maxDate;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final Color line = _line;

    return Container(
      height: 400,
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
            'LINE CHART · RANGE SLIDER · INTRADAY',
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
                  cursor: SystemMouseCursors.basic,
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
                        _panStartX = null;
                      });
                    },
                    child: CustomPaint(
                      size: size,
                      painter: _IntradayPainter(
                        dark: dark,
                        data: _data,
                        viewStart: _viewStart,
                        viewEnd: _viewEnd,
                        hoverIndex: _hoverIndex,
                        line: line,
                        rangeBarH: _rangeBarH,
                        handleR: _handleR,
                        yLabelW: _yLabelW,
                        xLabelH: _xLabelH,
                        plotPadT: _plotPadT,
                        plotPadR: _plotPadR,
                        minDate: _minDate,
                        maxDate: _maxDate,
                        yMin: _yMin,
                        yMax: _yMax,
                        yStep: _yStep,
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

enum _DragKind { rangeStart, rangeEnd, rangeWindow }

class _IntradayPainter extends CustomPainter {
  _IntradayPainter({
    required this.dark,
    required this.data,
    required this.viewStart,
    required this.viewEnd,
    required this.hoverIndex,
    required this.line,
    required this.rangeBarH,
    required this.handleR,
    required this.yLabelW,
    required this.xLabelH,
    required this.plotPadT,
    required this.plotPadR,
    required this.minDate,
    required this.maxDate,
    required this.yMin,
    required this.yMax,
    required this.yStep,
  });

  final bool dark;
  final List<StaticRangeLinePoint> data;
  final DateTime viewStart;
  final DateTime viewEnd;
  final int? hoverIndex;
  final Color line;
  final double rangeBarH;
  final double handleR;
  final double yLabelW;
  final double xLabelH;
  final double plotPadT;
  final double plotPadR;
  final DateTime minDate;
  final DateTime maxDate;
  final double yMin;
  final double yMax;
  final double yStep;

  final DateFormat _timeFmt = DateFormat('HH:mm');
  final DateFormat _axisTipFmt = DateFormat('HH:mm - MMM dd, yyyy');

  int get _totalMs =>
      math.max(1, maxDate.difference(minDate).inMilliseconds);

  double _tOf(DateTime d) =>
      d.difference(minDate).inMilliseconds / _totalMs;

  String _fmtValue(double v) {
    final String s = v.toStringAsFixed(2);
    if (s.endsWith('00')) return v.toStringAsFixed(0);
    if (s.endsWith('0')) return v.toStringAsFixed(1);
    return s;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect track = Rect.fromLTWH(
      yLabelW,
      (rangeBarH - 3) / 2,
      size.width - yLabelW - plotPadR,
      3,
    );
    final Rect plot = Rect.fromLTRB(
      yLabelW,
      rangeBarH + plotPadT,
      size.width - plotPadR,
      size.height - xLabelH,
    );

    _paintRangeBar(canvas, track);
    _paintGridAndAxes(canvas, plot);
    _paintSeries(canvas, plot);
    _paintHover(canvas, plot, size);
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
      Paint()..color = line.withValues(alpha: dark ? 0.35 : 0.22),
    );

    void drawHandle(double x) {
      final Offset c = Offset(x, track.center.dy);
      canvas.drawCircle(
        c,
        handleR,
        Paint()..color = UsPremiumPalette.surface(dark),
      );
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

  void _paintGridAndAxes(Canvas canvas, Rect plot) {
    final Color grid = UsPremiumPalette.grid(dark);
    final Color muted = UsPremiumPalette.muted(dark);
    final TextStyle labelStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: muted,
    );
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    canvas.drawRect(
      plot,
      Paint()
        ..color = grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (double y = yMin; y <= yMax + 0.001; y += yStep) {
      final double ty = 1 - ((y - yMin) / (yMax - yMin));
      final double py = plot.top + ty * plot.height;
      canvas.drawLine(Offset(plot.left, py), Offset(plot.right, py), gridPaint);
      final TextPainter tp = TextPainter(
        text: TextSpan(text: y.toStringAsFixed(1), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: yLabelW - 4);
      tp.paint(canvas, Offset(plot.left - tp.width - 6, py - tp.height / 2));
    }

    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);
    for (final StaticRangeLinePoint p in data) {
      if (p.date.isBefore(viewStart) || p.date.isAfter(viewEnd)) continue;
      final double tx =
          p.date.difference(viewStart).inMilliseconds / viewMs;
      final double px = plot.left + tx * plot.width;
      canvas.drawLine(Offset(px, plot.top), Offset(px, plot.bottom), gridPaint);
      final TextPainter tp = TextPainter(
        text: TextSpan(text: _timeFmt.format(p.date), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, plot.bottom + 6));
    }
  }

  void _paintSeries(Canvas canvas, Rect plot) {
    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);
    final List<Offset> pts = <Offset>[];
    final List<int> idxs = <int>[];
    final List<double> vals = <double>[];

    for (int i = 0; i < data.length; i++) {
      final StaticRangeLinePoint p = data[i];
      if (p.date.isBefore(viewStart) || p.date.isAfter(viewEnd)) continue;
      final double tx =
          p.date.difference(viewStart).inMilliseconds / viewMs;
      final double ty =
          1 - ((p.value - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
      pts.add(Offset(plot.left + tx * plot.width, plot.top + ty * plot.height));
      idxs.add(i);
      vals.add(p.value);
    }
    if (pts.length < 2) return;

    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    for (int i = 0; i < pts.length; i++) {
      final bool hot = hoverIndex != null && idxs[i] == hoverIndex;
      canvas.drawCircle(
        pts[i],
        hot ? 4.2 : 3.2,
        Paint()..color = line,
      );

      // Default outline value labels (skip active hover — filled tip replaces it).
      if (hot) continue;
      _paintOutlineLabel(canvas, pts[i], _fmtValue(vals[i]), plot);
    }
  }

  void _paintOutlineLabel(
    Canvas canvas,
    Offset point,
    String text,
    Rect plot,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.1,
          color: line,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const double padX = 5;
    const double padY = 2.5;
    final double boxW = tp.width + padX * 2;
    final double boxH = tp.height + padY * 2;
    double left = point.dx - boxW / 2;
    double top = point.dy - boxH - 8;
    // Flip below if near plot top.
    if (top < plot.top + 2) top = point.dy + 8;
    left = left.clamp(plot.left + 1, plot.right - boxW - 1);

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxW, boxH),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = UsPremiumPalette.surface(dark).withValues(alpha: 0.96),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = line.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(left + padX, top + padY));
  }

  void _paintHover(Canvas canvas, Rect plot, Size size) {
    if (hoverIndex == null) return;
    final StaticRangeLinePoint p = data[hoverIndex!];
    if (p.date.isBefore(viewStart) || p.date.isAfter(viewEnd)) return;

    final int viewMs =
        math.max(1, viewEnd.difference(viewStart).inMilliseconds);
    final double tx =
        p.date.difference(viewStart).inMilliseconds / viewMs;
    final double ty =
        1 - ((p.value - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
    final Offset point =
        Offset(plot.left + tx * plot.width, plot.top + ty * plot.height);

    // Dashed vertical crosshair.
    final Paint dashPaint = Paint()
      ..color = dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    const double dash = 4;
    const double gap = 3;
    double y = plot.top;
    while (y < plot.bottom) {
      final double y2 = math.min(y + dash, plot.bottom);
      canvas.drawLine(Offset(point.dx, y), Offset(point.dx, y2), dashPaint);
      y += dash + gap;
    }

    // Filled value tip (replaces outline label).
    final String valueText = _fmtValue(p.value);
    final TextPainter valueTp = TextPainter(
      text: TextSpan(
        text: valueText,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    const double vPadX = 7;
    const double vPadY = 4;
    final double vW = valueTp.width + vPadX * 2;
    final double vH = valueTp.height + vPadY * 2;
    double vLeft = point.dx - vW / 2;
    double vTop = point.dy - vH - 10;
    if (vTop < plot.top + 2) vTop = point.dy + 10;
    vLeft = vLeft.clamp(plot.left + 1, plot.right - vW - 1);
    final RRect vRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(vLeft, vTop, vW, vH),
      const Radius.circular(4),
    );
    canvas.drawRRect(vRect, Paint()..color = line);
    valueTp.paint(canvas, Offset(vLeft + vPadX, vTop + vPadY));

    // Axis date tip.
    final String axisText = _axisTipFmt.format(p.date);
    final TextPainter axisTp = TextPainter(
      text: TextSpan(
        text: axisText,
        style: const TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.1,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    const double aPadX = 8;
    const double aPadY = 4;
    final double aW = axisTp.width + aPadX * 2;
    final double aH = axisTp.height + aPadY * 2;
    double aLeft = point.dx - aW / 2;
    final double aTop = plot.bottom + 4;
    aLeft = aLeft.clamp(2.0, size.width - aW - 2);
    final RRect aRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(aLeft, aTop, aW, aH),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      aRect,
      Paint()..color = dark ? const Color(0xFF0F172A) : const Color(0xFF0F172A),
    );
    axisTp.paint(canvas, Offset(aLeft + aPadX, aTop + aPadY));
  }

  @override
  bool shouldRepaint(covariant _IntradayPainter old) {
    return old.dark != dark ||
        old.viewStart != viewStart ||
        old.viewEnd != viewEnd ||
        old.hoverIndex != hoverIndex ||
        old.line != line ||
        old.data != data;
  }
}
