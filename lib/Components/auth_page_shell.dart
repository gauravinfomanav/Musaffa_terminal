import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';

/// Shared premium shell for Login / Register: ambient motion, glass card,
/// staggered entrance, brand CTA.
class AuthPageShell extends StatefulWidget {
  const AuthPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    this.footnote,
    this.maxWidth = 440,
    this.skipEntranceAnimation = false,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;
  final String? footnote;
  final double maxWidth;
  final bool skipEntranceAnimation;

  @override
  State<AuthPageShell> createState() => _AuthPageShellState();
}

class _AuthPageShellState extends State<AuthPageShell>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _ambient;
  late final AnimationController _pulse;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    final enterCurve = CurvedAnimation(
      parent: _enter,
      curve: Curves.easeOutCubic,
    );
    _cardFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.085),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _cardScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.015)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.015, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 28,
      ),
    ]).animate(enterCurve);

    if (widget.skipEntranceAnimation) {
      _enter.value = 1.0;
    } else {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _ambient.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 720;
    final palette = AuthPalette.of(isDark);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.bgTop,
              Color.lerp(palette.bgTop, palette.bgBottom, 0.55)!,
              palette.bgBottom,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient orbs only — avoids rebuilding the form every tick.
            AnimatedBuilder(
              animation: Listenable.merge([_ambient, _pulse]),
              builder: (context, _) {
                final t = _ambient.value;
                final p = _pulse.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -120 + 22 * math.sin(t * math.pi),
                      right: -90 + 28 * t,
                      child: Transform.scale(
                        scale: 0.94 + 0.08 * p,
                        child: _AmbientOrb(
                          size: 340,
                          colors: [
                            const Color(0xFFE4681F)
                                .withValues(alpha: isDark ? 0.26 : 0.18),
                            const Color(0xFFC42329)
                                .withValues(alpha: isDark ? 0.10 : 0.06),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -140 + 16 * math.cos(t * math.pi),
                      left: -70 - 20 * t,
                      child: Transform.scale(
                        scale: 1.02 - 0.06 * p,
                        child: _AmbientOrb(
                          size: 380,
                          colors: [
                            const Color(0xFF1F2760)
                                .withValues(alpha: isDark ? 0.32 : 0.14),
                            const Color(0xFF88123E)
                                .withValues(alpha: isDark ? 0.12 : 0.07),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: size.height * 0.36 + 10 * math.sin(t * math.pi * 2),
                      left: size.width * 0.40,
                      child: _AmbientOrb(
                        size: 200,
                        colors: [
                          const Color(0xFFDB3E20)
                              .withValues(alpha: isDark ? 0.12 : 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.15,
                      colors: [
                        Colors.transparent,
                        (isDark ? Colors.black : const Color(0xFF0F172A))
                            .withValues(alpha: isDark ? 0.35 : 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 20 : 32,
                  vertical: 36,
                ),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: widget.maxWidth),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Soft brand aura behind the card
                            Positioned(
                              left: 24,
                              right: 24,
                              top: 40,
                              bottom: 20,
                              child: AnimatedBuilder(
                                animation: _pulse,
                                builder: (context, _) {
                                  final glow = 0.08 + 0.06 * _pulse.value;
                                  return IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE4621E)
                                                .withValues(alpha: glow),
                                            blurRadius: 48,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF1F2760)
                                                .withValues(
                                              alpha: glow * 0.7,
                                            ),
                                            blurRadius: 56,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            _AuthGlassCard(
                              isDark: isDark,
                              isCompact: isCompact,
                              palette: palette,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Center(
                                      // ® sits on the right — slight nudge so the wordmark looks centered.
                                      child: Transform.translate(
                                        offset: const Offset(3, 0),
                                        child: const MusaffaLogo(height: 30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _StaggerIn(
                                    controller: _enter,
                                    begin: 0.12,
                                    end: 0.48,
                                    child: Text(
                                      widget.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                        height: 1.15,
                                        color: palette.title,
                                        fontFamily:
                                            Constants.FONT_DEFAULT_NEW,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _StaggerIn(
                                    controller: _enter,
                                    begin: 0.16,
                                    end: 0.52,
                                    child: Text(
                                      widget.subtitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        height: 1.35,
                                        color: palette.muted,
                                        fontFamily:
                                            Constants.FONT_DEFAULT_NEW,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  _StaggerIn(
                                    controller: _enter,
                                    begin: 0.26,
                                    end: 0.70,
                                    child: widget.form,
                                  ),
                                  const SizedBox(height: 20),
                                  _StaggerIn(
                                    controller: _enter,
                                    begin: 0.40,
                                    end: 0.84,
                                    child: widget.footer,
                                  ),
                                  if (widget.footnote != null) ...[
                                    const SizedBox(height: 12),
                                    _StaggerIn(
                                      controller: _enter,
                                      begin: 0.48,
                                      end: 0.95,
                                      child: Text(
                                        widget.footnote!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.35,
                                          color: palette.muted
                                              .withValues(alpha: 0.85),
                                          fontFamily:
                                              Constants.FONT_DEFAULT_NEW,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPalette {
  const AuthPalette({
    required this.isDark,
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.border,
    required this.title,
    required this.muted,
    required this.accent,
    required this.fieldFill,
    required this.hint,
  });

  final bool isDark;
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color border;
  final Color title;
  final Color muted;
  final Color accent;
  final Color fieldFill;
  final Color hint;

  factory AuthPalette.of(bool isDark) {
    return AuthPalette(
      isDark: isDark,
      bgTop: isDark ? const Color(0xFF0A0C12) : const Color(0xFFF4F6FA),
      bgBottom: isDark ? const Color(0xFF12151E) : const Color(0xFFE7ECF4),
      card: isDark
          ? const Color(0xFF161A22).withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.86),
      border: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE5E7EB).withValues(alpha: 0.95),
      title: HomeUi.title(isDark),
      muted: HomeUi.muted(isDark),
      accent: const Color(0xFFE4621E),
      fieldFill: isDark
          ? const Color(0xFF0F131A).withValues(alpha: 0.9)
          : const Color(0xFFF7F8FB),
      hint: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
    );
  }
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = HomeUi.muted(isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: muted,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isError
        ? (isDark ? const Color(0xFF2A1518) : const Color(0xFFFEF2F2))
        : (isDark ? const Color(0xFF12241C) : const Color(0xFFECFDF5));
    final border = isError
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
        : (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0));
    final iconColor =
        isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final textColor = isError
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 17,
              color: iconColor,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _hoverAnim;

  @override
  void initState() {
    super.initState();
    _hoverAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _hoverAnim.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() {
      _hovered = value;
      if (!value) _pressed = false;
    });
    if (value && (widget.onPressed != null && !widget.loading)) {
      _hoverAnim.forward(from: 0);
    } else {
      _hoverAnim
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final scale = !enabled
        ? 1.0
        : _pressed
            ? 0.98
            : _hovered
                ? 1.025
                : 1.0;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _hoverAnim,
            builder: (context, child) {
              final t = _hoverAnim.value;
              final shimmerAlign = Alignment(-1.4 + 2.8 * t, 0);
              final shift = _hovered ? 0.28 * math.sin(t * math.pi) : 0.0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: 48,
                decoration: BoxDecoration(
                  gradient: enabled
                      ? LinearGradient(
                          begin: Alignment(-1 + shift, -1),
                          end: Alignment(1 - shift, 1),
                          colors: HomeUi.iconFillGradient.colors,
                          stops: HomeUi.iconFillGradient.stops,
                        )
                      : LinearGradient(
                          colors: HomeUi.iconFillGradient.colors
                              .map((c) => c.withValues(alpha: 0.5))
                              .toList(),
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: HomeUi.buttonBorder
                        .withValues(alpha: enabled ? 1 : 0.45),
                    width: 0.9,
                  ),
                  boxShadow: enabled && (_hovered || _pressed)
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE4621E)
                                .withValues(alpha: 0.40),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (enabled && _hovered)
                        IgnorePointer(
                          child: Align(
                            alignment: shimmerAlign,
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.28),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Center(child: child),
                    ],
                  ),
                ),
              );
            },
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                      color: Colors.white,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthTextLink extends StatefulWidget {
  const AuthTextLink({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
  });

  final String prefix;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  State<AuthTextLink> createState() => _AuthTextLinkState();
}

class _AuthTextLinkState extends State<AuthTextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = HomeUi.muted(isDark);
    const accent = Color(0xFFE4621E);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          widget.prefix,
          style: TextStyle(
            fontSize: 12.5,
            color: muted,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _hovered ? accent : accent.withValues(alpha: 0.92),
                decoration:
                    _hovered ? TextDecoration.underline : TextDecoration.none,
                decorationColor: accent,
                fontFamily: Constants.FONT_DEFAULT_NEW,
              ),
              child: Text(widget.linkLabel),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration authInputDecoration({
  required String hint,
  required AuthPalette palette,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 13,
      color: palette.hint,
      fontFamily: Constants.FONT_DEFAULT_NEW,
    ),
    filled: true,
    fillColor: palette.fieldFill,
    prefixIcon: Icon(prefixIcon, size: 18, color: palette.accent),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );
}

class _AuthGlassCard extends StatelessWidget {
  const _AuthGlassCard({
    required this.isDark,
    required this.isCompact,
    required this.palette,
    required this.child,
  });

  final bool isDark;
  final bool isCompact;
  final AuthPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 24 : 34,
            vertical: isCompact ? 30 : 38,
          ),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(
                  alpha: isDark ? 0.45 : 0.10,
                ),
                blurRadius: 40,
                offset: const Offset(0, 22),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: const Color(0xFFE4621E).withValues(
                  alpha: isDark ? 0.06 : 0.04,
                ),
                blurRadius: 48,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors.length >= 2
                ? colors
                : [colors.first, colors.first.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
  });

  final AnimationController controller;
  final double begin;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(fade);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
