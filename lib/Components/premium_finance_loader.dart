import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

/// Premium loader — Logo Flower SVG with sequential petal fill reveal.
class PremiumFinanceLoader extends StatefulWidget {
  const PremiumFinanceLoader({
    super.key,
    this.statusLabel,
    this.minHeight = 320,
    this.isLoading = true,
    this.waitForData = true,
    this.fullScreen = false,
    this.duration = const Duration(milliseconds: 2400),
    this.onExitStart,
    this.onFinished,
  });

  final String? statusLabel;
  final double minHeight;
  final bool isLoading;
  final bool waitForData;
  final bool fullScreen;
  final Duration duration;
  final VoidCallback? onExitStart;
  final VoidCallback? onFinished;

  @override
  State<PremiumFinanceLoader> createState() => _PremiumFinanceLoaderState();
}

class _PremiumFinanceLoaderState extends State<PremiumFinanceLoader>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _exit;
  late final AnimationController _glow;
  late final AnimationController _waves;
  late final AnimationController _cursorPulse;
  late final AnimationController _dots;

  late final Animation<double> _flowerFill;
  late final Animation<double> _flowerScale;
  late final Animation<double> _lineReveal;
  late final Animation<double> _lineProgress;
  late final Animation<double> _labelOpacity;
  late final Animation<double> _labelSlide;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitLift;

  bool _exiting = false;
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    _dataReady = !widget.waitForData || !widget.isLoading;

    _enter = AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && _dataReady) {
            _startExit();
          }
        });

    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished?.call();
        }
      });

    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _waves = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _cursorPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _flowerFill = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.68, curve: Curves.easeInOutCubic),
    );
    _flowerScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _lineReveal = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.50, 0.64, curve: Curves.easeOut),
    );
    _lineProgress = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.54, 0.96, curve: Curves.easeInOutCubic),
    );
    _labelOpacity = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.58, 0.74, curve: Curves.easeOut),
    );
    _labelSlide = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.58, 0.76, curve: Curves.easeOutCubic),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exit, curve: Curves.easeInOutCubic),
    );
    _exitLift = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAnimations());
  }

  Future<void> _bootstrapAnimations() async {
    if (!mounted) return;
    final hi = _FlowerImageCache.hiSizeFor(context);
    await _FlowerImageCache.warmUp(hi);
    if (!mounted) return;
    _enter.forward(from: 0);
    _waves.repeat();
    _glow.repeat(reverse: true);
    _cursorPulse.repeat(reverse: true);
    _dots.repeat();
  }

  @override
  void didUpdateWidget(covariant PremiumFinanceLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _enter.duration = widget.duration;
    }
    if (!widget.waitForData) {
      _dataReady = true;
    } else if (!oldWidget.isLoading && widget.isLoading) {
      _dataReady = false;
      _exiting = false;
      _exit.reset();
      _enter.forward(from: 0);
    } else if (oldWidget.isLoading && !widget.isLoading) {
      _dataReady = true;
      if (_enter.isCompleted) {
        _startExit();
      }
    }
  }

  void _startExit() {
    if (_exiting || !mounted) return;
    _exiting = true;
    setState(() {});
    widget.onExitStart?.call();
    _exit.forward(from: 0);
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    _glow.dispose();
    _waves.dispose();
    _cursorPulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final overlayOpacity = _exiting ? _exitOpacity.value : 1.0;
        return Opacity(
          opacity: overlayOpacity,
          child: child,
        );
      },
      child: widget.fullScreen
          ? DecoratedBox(
              decoration: _surfaceDecoration(dark),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _buildCore(dark),
              ),
            )
          : SizedBox(
              width: double.infinity,
              height: widget.minHeight,
              child: DecoratedBox(
                decoration: _surfaceDecoration(dark),
                child: _buildCore(dark),
              ),
            ),
    );
  }

  BoxDecoration _surfaceDecoration(bool dark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xFF0C0D0F), Color(0xFF111418), Color(0xFF0C0D0F)]
            : const [Color(0xFFF3F4F6), Color(0xFFFAFBFC), Color(0xFFF3F4F6)],
        stops: const [0.0, 0.55, 1.0],
      ),
    );
  }

  Widget _buildCore(bool dark) {
    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final lift = _exiting ? _exitLift.value : 0.0;
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([
                _enter,
                _glow,
                _waves,
                _cursorPulse,
              ]),
              builder: (context, _) {
                final glow =
                    (0.06 + _glow.value * 0.12) * _flowerFill.value.clamp(0.0, 1.0);
                final fill = _flowerFill.value;
                final breathe = fill >= 0.98
                    ? 1.0 + _cursorPulse.value * 0.018
                    : 1.0;

                return Transform.scale(
                  scale: _flowerScale.value * breathe,
                  filterQuality: FilterQuality.high,
                  child: _AnimatedFlowerLogo(
                    dark: dark,
                    fillProgress: fill,
                    glow: glow,
                    wavePhase: _waves.value,
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: Listenable.merge([_enter, _cursorPulse]),
              builder: (context, _) {
                return Opacity(
                  opacity: _lineReveal.value,
                  child: _AnimatedProgressLine(
                    dark: dark,
                    progress: _lineProgress.value,
                    cursorPulse: _cursorPulse.value,
                  ),
                );
              },
            ),
            if (widget.statusLabel != null) ...[
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: Listenable.merge([_enter, _dots]),
                builder: (context, _) {
                  return Opacity(
                    opacity: _labelOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _labelSlide.value),
                      child: Text(
                        widget.statusLabel!,
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontFamilyFallback: Constants.FONT_FALLBACK,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.55,
                          color: HomeUi.muted(dark).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: Listenable.merge([_enter, _dots]),
                builder: (context, _) {
                  return Opacity(
                    opacity: _labelOpacity.value,
                    child: _LoadingDots(
                      dark: dark,
                      phase: _dots.value,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Logo Flower — radial fill + soft expanding wave rings.
class _AnimatedFlowerLogo extends StatefulWidget {
  const _AnimatedFlowerLogo({
    required this.dark,
    required this.fillProgress,
    required this.glow,
    required this.wavePhase,
  });

  final bool dark;
  final double fillProgress;
  final double glow;
  final double wavePhase;

  @override
  State<_AnimatedFlowerLogo> createState() => _AnimatedFlowerLogoState();
}

class _AnimatedFlowerLogoState extends State<_AnimatedFlowerLogo> {
  static const double _flowerSize = 56;
  static const double _canvasSize = 100;

  ui.Image? _flowerImage;
  double? _loadedHi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hi = _FlowerImageCache.hiSizeFor(context);
    if (_loadedHi == hi && _flowerImage != null) return;
    _loadedHi = hi;
    _flowerImage = _FlowerImageCache.imageFor(hi);
    _FlowerImageCache.warmUp(hi).then((image) {
      if (!mounted || image == null || _loadedHi != hi) return;
      setState(() => _flowerImage = image);
    });
  }

  Widget _buildFillLayer(double fill, ui.Image image, double hi) {
    final downscale = _flowerSize / hi;
    return RepaintBoundary(
      child: SizedBox(
        width: _flowerSize,
        height: _flowerSize,
        child: ClipRect(
          clipBehavior: Clip.none,
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: hi,
            maxWidth: hi,
            minHeight: hi,
            maxHeight: hi,
            child: Transform.scale(
              scale: downscale,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              child: SizedBox(
                width: hi,
                height: hi,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) {
                    final t = fill.clamp(0.0, 1.0);
                    final core = (t * 0.58).clamp(0.0, 1.0);
                    final rim = (t * 0.92 + 0.04).clamp(0.0, 1.0);
                    return RadialGradient(
                      center: const Alignment(0, 0.05),
                      radius: 0.72,
                      colors: const [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0.0, core, rim],
                    ).createShader(bounds);
                  },
                  child: RawImage(
                    image: image,
                    width: hi,
                    height: hi,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.fillProgress.clamp(0.0, 1.0);
    final image = _flowerImage;

    return SizedBox(
      width: _canvasSize,
      height: _canvasSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (fill > 0.04)
            RepaintBoundary(
              child: CustomPaint(
                size: const Size(_canvasSize, _canvasSize),
                painter: _WaveRingsPainter(
                  dark: widget.dark,
                  phase: widget.wavePhase,
                  fillOpacity: fill,
                ),
              ),
            ),
          if (widget.glow > 0.01 && fill > 0.04)
            IgnorePointer(
              child: Opacity(
                opacity: fill * 0.85,
                child: Container(
                  width: _flowerSize + 20,
                  height: _flowerSize + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE4621E)
                            .withValues(alpha: widget.glow),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: image != null && fill > 0.001
                ? _buildFillLayer(fill, image, _loadedHi!)
                : const SizedBox(
                    width: _flowerSize,
                    height: _flowerSize,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Rasterizes the flower SVG once — avoids re-parsing masks every frame.
class _FlowerImageCache {
  static const String asset = 'resources/Logo Flower.svg';
  static const double _flowerSize = 56;
  static const double _oversample = 3.0;

  static ui.Image? _image;
  static double? _hi;
  static Future<ui.Image?>? _loading;

  static double hiSizeFor(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (_flowerSize * _oversample * dpr).clamp(_flowerSize * 2.5, 280);
  }

  static ui.Image? imageFor(double hi) {
    if (_image != null && _hi == hi) return _image;
    return null;
  }

  static Future<ui.Image?> warmUp(double hi) {
    if (_image != null && _hi == hi) return Future.value(_image);
    return _loading ??= _load(hi);
  }

  static Future<ui.Image?> _load(double hi) async {
    try {
      final pictureInfo = await vg.loadPicture(SvgAssetLoader(asset), null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final iw = pictureInfo.size.width;
      final ih = pictureInfo.size.height;
      final scale = math.min(hi / iw, hi / ih);
      canvas.translate((hi - iw * scale) / 2, (hi - ih * scale) / 2);
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);
      pictureInfo.picture.dispose();

      final picture = recorder.endRecording();
      final image = await picture.toImage(hi.toInt(), hi.toInt());
      _image?.dispose();
      _image = image;
      _hi = hi;
      return image;
    } catch (_) {
      return null;
    } finally {
      _loading = null;
    }
  }
}

/// Three staggered rings expanding outward — calm sonar-style waves.
class _WaveRingsPainter extends CustomPainter {
  _WaveRingsPainter({
    required this.dark,
    required this.phase,
    required this.fillOpacity,
  });

  final bool dark;
  final double phase;
  final double fillOpacity;

  static const int _ringCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (fillOpacity <= 0.04) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 3;
    final minR = size.width * 0.20;

    for (int i = 0; i < _ringCount; i++) {
      final t = (phase + i / _ringCount) % 1.0;
      final eased = Curves.easeOutCubic.transform(t);
      final radius = minR + (maxR - minR) * eased;
      final fade = (1.0 - t);
      final alpha = fade * fade * 0.20 * fillOpacity;
      if (alpha < 0.008) continue;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFE4621E).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65,
      );

      final innerAlpha = alpha * 0.45;
      if (innerAlpha > 0.006) {
        canvas.drawCircle(
          center,
          radius - 0.8,
          Paint()
            ..color = (dark ? const Color(0xFF8B929C) : const Color(0xFF9CA3AF))
                .withValues(alpha: innerAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveRingsPainter old) =>
      old.phase != phase ||
      old.fillOpacity != fillOpacity ||
      old.dark != dark;
}

class _AnimatedProgressLine extends StatelessWidget {
  const _AnimatedProgressLine({
    required this.dark,
    required this.progress,
    required this.cursorPulse,
  });

  final bool dark;
  final double progress;
  final double cursorPulse;

  static const double _width = 220;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: 10,
      child: CustomPaint(
        painter: _ProgressCursorPainter(
          dark: dark,
          progress: progress,
          cursorPulse: cursorPulse,
        ),
      ),
    );
  }
}

class _ProgressCursorPainter extends CustomPainter {
  _ProgressCursorPainter({
    required this.dark,
    required this.progress,
    required this.cursorPulse,
  });

  final bool dark;
  final double progress;
  final double cursorPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height / 2;
    final trackR = RRect.fromLTRBR(
      0,
      trackY - 1,
      size.width,
      trackY + 1,
      const Radius.circular(1),
    );

    canvas.drawRRect(
      trackR,
      Paint()
        ..color = dark ? const Color(0xFF252830) : const Color(0xFFDFE2E8),
    );

    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    final fillW = size.width * p;
    canvas.drawRRect(
      RRect.fromLTRBR(0, trackY - 1, fillW, trackY + 1, const Radius.circular(1)),
      Paint()
        ..shader = HomeUi.brandGradient.createShader(
          Rect.fromLTWH(0, trackY - 1, size.width, 2),
        ),
    );

    final headX = fillW.clamp(2.0, size.width);
    final headR = 2.5 + cursorPulse * 1.2;
    final head = Offset(headX, trackY);

    canvas.drawCircle(
      head,
      headR + 5,
      Paint()
        ..color = const Color(0xFFE4621E)
            .withValues(alpha: 0.12 + cursorPulse * 0.08),
    );
    canvas.drawCircle(
      head,
      headR,
      Paint()..color = const Color(0xFFE4621E).withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressCursorPainter old) =>
      old.progress != progress ||
      old.cursorPulse != cursorPulse ||
      old.dark != dark;
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.dark, required this.phase});

  final bool dark;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final t = (phase + i * 0.22) % 1.0;
        final opacity = 0.25 + math.sin(t * math.pi * 2) * 0.35 + 0.35;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Opacity(
            opacity: opacity.clamp(0.2, 1.0),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark
                    ? const Color(0xFF8B929C)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        );
      }),
    );
  }
}
