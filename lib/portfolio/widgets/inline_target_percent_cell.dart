import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Compact inline editor for model portfolio target allocation %.
class InlineTargetPercentCell extends StatefulWidget {
  const InlineTargetPercentCell({
    super.key,
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  final bool isDark;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<InlineTargetPercentCell> createState() =>
      _InlineTargetPercentCellState();
}

class _InlineTargetPercentCellState extends State<InlineTargetPercentCell> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant InlineTargetPercentCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commit();
    if (mounted) setState(() {});
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0) {
      _controller.text = _format(widget.value);
      return;
    }
    final clamped = parsed.clamp(0.0, 100.0);
    _controller.text = _format(clamped);
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final focused = _focusNode.hasFocus;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: 64,
        height: 32,
        decoration: BoxDecoration(
          color: _hover || focused
              ? HomeUi.borderStrong(dark)
              : HomeUi.borderLight(dark),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            color: HomeUi.cardBg(dark),
            borderRadius: BorderRadius.circular(7),
          ),
          padding: const EdgeInsets.only(left: 6, right: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  cursorColor: HomeUi.title(dark),
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontFamilyFallback: Constants.FONT_FALLBACK,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: HomeUi.title(dark),
                    height: 1.1,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _commit(),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '%',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontFamilyFallback: Constants.FONT_FALLBACK,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: focused
                      ? HomeUi.accent(dark)
                      : HomeUi.muted(dark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
