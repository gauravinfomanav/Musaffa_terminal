import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Pill track whose gradient indicator slides between tabs.
class SlidingPillTabs extends StatefulWidget {
  final int itemCount;
  final int selectedIndex;
  final Widget Function(BuildContext context, int index, bool selected)
      itemBuilder;
  final ValueChanged<int> onSelect;
  final TabController? controller;
  final bool isDarkMode;

  const SlidingPillTabs({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.itemBuilder,
    required this.onSelect,
    required this.isDarkMode,
    this.controller,
  });

  @override
  State<SlidingPillTabs> createState() => _SlidingPillTabsState();
}

class _SlidingPillTabsState extends State<SlidingPillTabs>
    with SingleTickerProviderStateMixin {
  late List<GlobalKey> _keys;
  List<double> _widths = const [];
  List<double> _offsets = const [];
  late final AnimationController _slide;
  double _from = 0;
  double _to = 0;
  TabController? _boundController;

  int get _selected => widget.controller?.index ?? widget.selectedIndex;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.itemCount, (_) => GlobalKey());
    _to = _selected.toDouble();
    _from = _to;
    _slide = AnimationController(
      vsync: this,
      duration: kTabScrollDuration,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _attachControllerListener();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant SlidingPillTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int oldSelected =
        oldWidget.controller?.index ?? oldWidget.selectedIndex;
    final int newSelected = _selected;
    if (oldWidget.itemCount != widget.itemCount) {
      _keys = List.generate(widget.itemCount, (_) => GlobalKey());
      _widths = const [];
      _offsets = const [];
    }
    if (oldWidget.controller != widget.controller) {
      _detachControllerListener();
      _attachControllerListener();
    }
    if (oldSelected != newSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateTo(newSelected);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _detachControllerListener();
    _slide.dispose();
    super.dispose();
  }

  void _attachControllerListener() {
    _boundController = widget.controller;
    _boundController?.addListener(_handleControllerTick);
  }

  void _detachControllerListener() {
    _boundController?.removeListener(_handleControllerTick);
    _boundController = null;
  }

  void _handleControllerTick() {
    if (!mounted || _boundController == null) return;
    if (_boundController!.indexIsChanging || _boundController!.offset == 0) {
      _animateTo(_boundController!.index);
    }
  }

  void _animateTo(int index) {
    final next = index.toDouble();
    if (!mounted) return;
    if ((next - _to).abs() < 0.001 && _slide.isCompleted) return;
    _from = _progress;
    _to = next;
    _slide.forward(from: 0);
  }

  double get _progress {
    final t = Curves.easeOutCubic.transform(_slide.value);
    return _from + (_to - _from) * t;
  }

  void _measure() {
    if (!mounted) return;
    final widths = <double>[];
    final offsets = <double>[];
    var x = 0.0;
    for (final key in _keys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      final w = box?.size.width ?? 0;
      offsets.add(x);
      widths.add(w);
      x += w;
    }
    if (widths.length != _widths.length ||
        !_listEquals(widths, _widths) ||
        !_listEquals(offsets, _offsets)) {
      setState(() {
        _widths = widths;
        _offsets = offsets;
      });
    }
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.5) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.itemCount;
    final selected = _selected;
    final t = _progress.clamp(0.0, (n <= 1 ? 0 : n - 1).toDouble());
    final i = t.floor().clamp(0, n <= 1 ? 0 : n - 2);
    final f = n <= 1 ? 0.0 : (t - i).clamp(0.0, 1.0);
    double left = 0;
    double width = 0;
    if (_offsets.length == n && _widths.length == n && n > 0) {
      if (n == 1) {
        left = _offsets[0];
        width = _widths[0];
      } else {
        left = _offsets[i] + (_offsets[i + 1] - _offsets[i]) * f;
        width = _widths[i] + (_widths[i + 1] - _widths[i]) * f;
      }
    }

    final Color trackBase = HomeUi.elevatedBg(widget.isDarkMode);
    final Color trackHighlight =
        widget.isDarkMode ? const Color(0xFF20242B) : const Color(0xFFFFFFFF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[trackHighlight, trackBase],
        ),
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: HomeUi.borderLight(widget.isDarkMode)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.isDarkMode
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (n > 0 && width > 0)
            Positioned(
              left: left,
              top: 0,
              bottom: 0,
              width: width,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: HomeUi.primaryButton().copyWith(
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF88123E).withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(n, (index) {
              return KeyedSubtree(
                key: _keys[index],
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _animateTo(index);
                      widget.onSelect(index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      child: widget.itemBuilder(
                        context,
                        index,
                        index == selected,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
