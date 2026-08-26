import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_revenue_breakdown_controller.dart';
import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class TickerRevenueBreakdownSection extends StatelessWidget {
  const TickerRevenueBreakdownSection({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onRetry,
  });

  final TickerRevenueBreakdownController controller;
  final bool isDarkMode;
  final VoidCallback onRetry;

  static const List<Color> palette = <Color>[
    Color(0xFF1F4E79),
    Color(0xFF3D7A6A),
    Color(0xFF5B7C99),
    Color(0xFF8FA3B8),
    Color(0xFFE4681F),
    Color(0xFFC42329),
    Color(0xFF6B7280),
    Color(0xFF8B5E3C),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        if (controller.isLoading && !controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(),
                const SizedBox(height: 20),
                TickerFinnhubLoadingState(
                  isDarkMode: isDarkMode,
                  height: 240,
                ),
              ],
            ),
          );
        }

        if (!controller.hasData) {
          return TickerFinnhubSectionCard(
            isDarkMode: isDarkMode,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(),
                const SizedBox(height: 12),
                TickerFinnhubEmptyState(
                  isDarkMode: isDarkMode,
                  message:
                      controller.error ?? 'No revenue breakdown data found',
                ),
                const SizedBox(height: 12),
                HomeUi.ghostAction(
                  label: 'Retry',
                  dark: isDarkMode,
                  icon: Icons.refresh_rounded,
                  onTap: onRetry,
                ),
              ],
            ),
          );
        }

        final RevenueBreakdownSlice? product = controller.product;
        final RevenueBreakdownSlice? geography = controller.geography;

        return TickerFinnhubSectionCard(
          isDarkMode: isDarkMode,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _header(),
              const SizedBox(height: 22),
              // Full-height divider (header → legend). Avoid IntrinsicHeight /
              // CrossAxisAlignment.stretch on the panels — those trip hover asserts.
              if (product != null && geography != null)
                Stack(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 28),
                            child: _RevenueSlicePanel(
                              slice: product,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: _RevenueSlicePanel(
                              slice: geography,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                            const Spacer(),
                            ColoredBox(
                              color: HomeUi.borderLight(isDarkMode),
                              child: const SizedBox(width: 1),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else if (product != null)
                _RevenueSlicePanel(
                  slice: product,
                  isDarkMode: isDarkMode,
                )
              else if (geography != null)
                _RevenueSlicePanel(
                  slice: geography,
                  isDarkMode: isDarkMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Revenue Breakdown',
          style: HomeUi.sectionTitle(isDarkMode).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Product mix and geography from company filings',
          style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12.5),
        ),
      ],
    );
  }
}

class _RevenueSlicePanel extends StatelessWidget {
  const _RevenueSlicePanel({
    required this.slice,
    required this.isDarkMode,
  });

  final RevenueBreakdownSlice slice;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final RevenueBreakdownItem? largest = slice.largest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 72,
          child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          slice.title,
                style: HomeUi.sectionTitle(isDarkMode).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 4),
        Text(
          slice.periodLabel,
          style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 11.5),
        ),
        if (largest != null) ...<Widget>[
                const SizedBox(height: 6),
          Text(
                  '${_shortLabel(largest.label)}  ·  ${_fmtPercent(largest.percentage)} of ${_fmtRevenue(slice.total)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.bodyText(isDarkMode).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        _RevenueDonut(
          slice: slice,
          isDarkMode: isDarkMode,
          focusItem: largest,
        ),
        const SizedBox(height: 14),
        _legend(slice),
      ],
    );
  }

  Widget _legend(RevenueBreakdownSlice slice) {
    final List<RevenueBreakdownItem> items = slice.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final bool dark = isDarkMode;
    const int cols = 3;
    final int rowCount = (items.length + cols - 1) ~/ cols;
    final Color line = HomeUi.borderLight(dark);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: line, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        border: TableBorder(
          verticalInside: BorderSide(color: line, width: 0.5),
          horizontalInside: BorderSide(color: line, width: 0.5),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: <TableRow>[
          for (int r = 0; r < rowCount; r++)
            TableRow(
              children: <Widget>[
                for (int c = 0; c < cols; c++)
                  _legendCellAt(items, r * cols + c),
              ],
            ),
        ],
      ),
    );
  }

  Widget _legendCellAt(List<RevenueBreakdownItem> items, int index) {
    if (index >= items.length) return const SizedBox.shrink();
    return _legendCell(
      color: TickerRevenueBreakdownSection
          .palette[index % TickerRevenueBreakdownSection.palette.length],
      item: items[index],
    );
  }

  Widget _legendCell({
    required Color color,
    required RevenueBreakdownItem item,
  }) {
    final bool dark = isDarkMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                  _shortLabel(item.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.control(dark, active: true).copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Text(
                      _fmtRevenue(item.revenue),
                      style: HomeUi.tableCellEmphasis(dark).copyWith(
                        fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.1,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        '·',
                        style: HomeUi.subtitle(dark).copyWith(
                          fontSize: 10.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                        border: Border.all(
                          color: HomeUi.borderLight(dark),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _fmtPercent(item.percentage),
                        style: HomeUi.subtitle(dark).copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom donut — hover thickens the slice in place (in + out), never explodes.
class _RevenueDonut extends StatefulWidget {
  const _RevenueDonut({
    required this.slice,
    required this.isDarkMode,
    required this.focusItem,
  });

  final RevenueBreakdownSlice slice;
  final bool isDarkMode;
  final RevenueBreakdownItem? focusItem;

  @override
  State<_RevenueDonut> createState() => _RevenueDonutState();
}

class _RevenueDonutState extends State<_RevenueDonut>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  Offset? _mousePos;

  late final Ticker _ticker;
  Duration? _lastElapsed;
  final List<double> _expandT = <double>[];

  int? _pendingHoverIndex;
  Offset? _pendingMousePos;
  bool _hoverFrameScheduled = false;

  /// Ring thickness ≈ 14% of radius (professional thin donut).
  static const double _outerFactor = 0.90;
  static const double _innerFactor = 0.76;
  static const double _hoverExpand = 6.0;
  static const double _gapPx = 0.55;
  static const double _chartHeight = 280;
  /// Higher = snappier; ~8–12 feels smooth without lag.
  static const double _smoothSpeed = 11.0;

  @override
  void initState() {
    super.initState();
    _syncExpandLength();
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(covariant _RevenueDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncExpandLength();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _syncExpandLength() {
    final int n = widget.slice.items.length;
    while (_expandT.length < n) {
      _expandT.add(0);
    }
    if (_expandT.length > n) {
      _expandT.removeRange(n, _expandT.length);
    }
  }

  void _ensureTicker() {
    if (!_ticker.isActive) {
      _lastElapsed = null;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastElapsed == null
        ? 1 / 60
        : (elapsed - _lastElapsed!).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final double clampedDt = dt.clamp(0.0, 1 / 30);
    final double factor = 1 - math.exp(-_smoothSpeed * clampedDt);

    bool settling = false;
    for (int i = 0; i < _expandT.length; i++) {
      final double target = i == _hoveredIndex ? 1.0 : 0.0;
      final double next = _expandT[i] + (target - _expandT[i]) * factor;
      if ((next - target).abs() < 0.0015) {
        if (_expandT[i] != target) settling = true;
        _expandT[i] = target;
      } else {
        _expandT[i] = next;
        settling = true;
      }
    }

    if (settling) {
      setState(() {});
    } else {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  /// Never call [setState] synchronously from [MouseRegion] callbacks —
  /// that trips `!_debugDuringDeviceUpdate`.
  void _queuePointerUpdate({required int? index, required Offset? pos}) {
    _pendingHoverIndex = index;
    _pendingMousePos = pos;
    if (_hoverFrameScheduled) return;
    _hoverFrameScheduled = true;
    // scheduleMicrotask runs after the current mouse-tracker update finishes,
    // without waiting for a full frame (safer than setState-in-onHover).
    scheduleMicrotask(() {
      _hoverFrameScheduled = false;
      if (!mounted) return;

      final bool indexChanged = _hoveredIndex != _pendingHoverIndex;
      final bool posChanged = _mousePos != _pendingMousePos;
      if (!indexChanged && !posChanged) return;

      setState(() {
        _mousePos = _pendingMousePos;
        if (indexChanged) {
          _hoveredIndex = _pendingHoverIndex;
          _ensureTicker();
        }
      });
    });
  }

  /// Starts at 12 o'clock, clockwise — matches painter.
  int? _hitTest(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;

    final List<RevenueBreakdownItem> items = widget.slice.items;
    if (items.isEmpty) return null;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outer =
        math.min(size.width, size.height) / 2 * _outerFactor;
    final double inner = outer * _innerFactor;
    final double dx = position.dx - center.dx;
    final double dy = position.dy - center.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double pad = _hoverExpand + 2;

    if (dist < inner - pad || dist > outer + pad) return null;

    double angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);

    final num total = items.fold<num>(
      0,
      (num s, RevenueBreakdownItem i) => s + i.revenue,
    );
    if (total <= 0) return null;

    double cursor = 0;
    for (int i = 0; i < items.length; i++) {
      final double sweep = (items[i].revenue / total) * 2 * math.pi;
      if (angle >= cursor && angle < cursor + sweep) return i;
      cursor += sweep;
    }
    return null;
  }

  Size? _currentSize() {
    final RenderObject? ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    final Size size = ro.size;
    if (size.width <= 0 || size.height <= 0) return null;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.isDarkMode;
    final RevenueBreakdownItem? focus = widget.focusItem;
    final int focusIndex =
        focus == null ? -1 : widget.slice.items.indexOf(focus);
    final int centerIndex = _hoveredIndex ?? (focusIndex >= 0 ? focusIndex : 0);
    final RevenueBreakdownItem? centerItem =
        centerIndex >= 0 && centerIndex < widget.slice.items.length
            ? widget.slice.items[centerIndex]
            : focus;
    final Color? centerColor = centerIndex >= 0
        ? TickerRevenueBreakdownSection
            .palette[centerIndex % TickerRevenueBreakdownSection.palette.length]
        : null;

    return SizedBox(
      height: _chartHeight,
      width: double.infinity,
      child: MouseRegion(
        opaque: false,
        onHover: (PointerHoverEvent event) {
          final Size? size = _currentSize();
          if (size == null) return;
          _queuePointerUpdate(
            index: _hitTest(event.localPosition, size),
            pos: event.localPosition,
          );
        },
        onExit: (_) {
          _queuePointerUpdate(index: null, pos: null);
        },
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            CustomPaint(
              painter: _RevenueDonutPainter(
                items: widget.slice.items,
                palette: TickerRevenueBreakdownSection.palette,
                expandTs: List<double>.from(_expandT),
                dark: dark,
                outerFactor: _outerFactor,
                innerFactor: _innerFactor,
                hoverExpand: _hoverExpand,
                gapPx: _gapPx,
              ),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: centerItem == null
                    ? const SizedBox.shrink()
                    : Column(
                        key: ValueKey<String>(
                          '${centerIndex}_${centerItem.label}',
                        ),
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _fmtPercent(centerItem.percentage),
                            style: HomeUi.tableCellEmphasis(dark).copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                              letterSpacing: -0.4,
                              color: centerColor ?? HomeUi.title(dark),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 110),
                  padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFF1A1D22)
                                  : const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                              _shortLabel(centerItem.label),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HomeUi.control(dark, active: true)
                                  .copyWith(
                      fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_hoveredIndex != null && _mousePos != null)
              _floatingTooltip(
                _hoveredIndex!,
                _currentSize() ?? const Size(_chartHeight, _chartHeight),
              ),
            ],
          ),
        ),
    );
  }

  Widget _floatingTooltip(int index, Size size) {
    final RevenueBreakdownItem item = widget.slice.items[index];
    final Color color = TickerRevenueBreakdownSection
        .palette[index % TickerRevenueBreakdownSection.palette.length];
    final Offset pos = _mousePos!;
    final bool dark = widget.isDarkMode;

    return Positioned(
      left: (pos.dx + 14).clamp(0.0, math.max(0.0, size.width - 180)),
      top: (pos.dy - 52).clamp(0.0, math.max(0.0, size.height - 60)),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double t, Widget? child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 4 * (1 - t)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1A1D22) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFEEF0F3),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.4 : 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                Text(
                      _shortLabel(item.label),
                      style: HomeUi.control(dark, active: true).copyWith(
                    fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtPercent(item.percentage)} allocation',
                      style: HomeUi.subtitle(dark).copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenueDonutPainter extends CustomPainter {
  _RevenueDonutPainter({
    required this.items,
    required this.palette,
    required this.expandTs,
    required this.dark,
    required this.outerFactor,
    required this.innerFactor,
    required this.hoverExpand,
    required this.gapPx,
  });

  final List<RevenueBreakdownItem> items;
  final List<Color> palette;
  final List<double> expandTs;
  final bool dark;
  final double outerFactor;
  final double innerFactor;
  final double hoverExpand;
  final double gapPx;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerBase =
        math.min(size.width, size.height) / 2 * outerFactor;
    final double innerBase = outerBase * innerFactor;
    final num total = items.fold<num>(
      0,
      (num s, RevenueBreakdownItem i) => s + i.revenue,
    );
    if (total <= 0) return;

    final double gapAngle = gapPx / outerBase;
    double start = -math.pi / 2; // 12 o'clock

    // Draw non-hovered first, then hovered on top for clean overlap.
    void drawSlice(int i, double startAngle, double sweep) {
      final double t =
          i < expandTs.length ? expandTs[i].clamp(0.0, 1.0) : 0.0;
      final double outerR = outerBase + hoverExpand * t;
      final double innerR = innerBase - hoverExpand * t;

      // Small single-sided gap so adjacent slices stay close.
      final double drawStart =
          startAngle + (items.length > 1 ? gapAngle * 0.5 : 0);
      final double drawSweep =
          sweep - (items.length > 1 ? gapAngle : 0);
      if (drawSweep <= 0) return;

      final Color base = palette[i % palette.length];
      final Path path =
          _slicePath(center, innerR, outerR, drawStart, drawSweep);
      canvas.drawPath(
        path,
        Paint()
          ..color = base
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      if (t > 0.01) {
        canvas.drawPath(
          path,
          Paint()
            ..color = base.withValues(alpha: 0.12 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5),
        );
      }
    }

    final List<double> starts = <double>[];
    final List<double> sweeps = <double>[];
    double cursor = start;
    for (int i = 0; i < items.length; i++) {
      final double sweep = (items[i].revenue / total) * 2 * math.pi;
      starts.add(cursor);
      sweeps.add(sweep);
      cursor += sweep;
    }

    int? topIndex;
    double topT = 0;
    for (int i = 0; i < items.length; i++) {
      final double t = i < expandTs.length ? expandTs[i] : 0;
      if (t > topT) {
        topT = t;
        topIndex = i;
      }
      if (t < 0.02) {
        drawSlice(i, starts[i], sweeps[i]);
      }
    }
    for (int i = 0; i < items.length; i++) {
      final double t = i < expandTs.length ? expandTs[i] : 0;
      if (t >= 0.02 && i != topIndex) {
        drawSlice(i, starts[i], sweeps[i]);
      }
    }
    if (topIndex != null && topT >= 0.02) {
      drawSlice(topIndex, starts[topIndex], sweeps[topIndex]);
    }

    canvas.drawCircle(
      center,
      innerBase,
      Paint()
        ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  Path _slicePath(
    Offset center,
    double innerR,
    double outerR,
    double start,
    double sweep,
  ) {
    final Path path = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerR),
        start,
        sweep,
        true,
      )
      ..lineTo(
        center.dx + math.cos(start + sweep) * innerR,
        center.dy + math.sin(start + sweep) * innerR,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerR),
        start + sweep,
        -sweep,
        false,
      )
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _RevenueDonutPainter old) {
    if (old.dark != dark ||
        old.items != items ||
        old.expandTs.length != expandTs.length) {
      return true;
    }
    for (int i = 0; i < expandTs.length; i++) {
      if ((old.expandTs[i] - expandTs[i]).abs() > 0.0005) return true;
    }
    return false;
  }
}

String _shortLabel(String raw) {
  var label = raw.trim();
  label = label.replaceAll(
    RegExp(r'\s*\[Member\]\s*', caseSensitive: false),
    '',
  );
  label = label.replaceAll(
    RegExp(r'\s+Member\s*$', caseSensitive: false),
    '',
  );
  label = label.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return label.isEmpty ? raw : label;
  }

  String _fmtRevenue(num value) {
    return valueWithCurrency(
      price: value,
      currency: 'USD',
      showCurrencySymbol: true,
      shorten: true,
    );
  }

  String _fmtPercent(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)}%';
}
