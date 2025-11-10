import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashOverlay extends StatefulWidget {
  final Widget child;
  final Duration displayDuration;
  final Duration fadeDuration;
  final double blurSigma;
  final double backgroundOpacity;
  final Widget? splashContent;

  const SplashOverlay({
    Key? key,
    required this.child,
    this.displayDuration = const Duration(seconds: 3),
    this.fadeDuration = const Duration(milliseconds: 400),
    this.blurSigma = 4,
    this.backgroundOpacity = 0.35,
    this.splashContent,
  }) : super(key: key);

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _hideSplash();
  }

  Future<void> _hideSplash() async {
    await Future.delayed(widget.displayDuration);
    if (!mounted) return;
    await _fadeController.forward();
    if (!mounted) return;
    setState(() {
      _showSplash = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _defaultSplashContent() {
    return Lottie.asset(
      'resources/Sandy Loading.json',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      repeat: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final splashTint = (Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white)
        .withOpacity(widget.backgroundOpacity);

    return Stack(
      children: [
        widget.child,
        if (_showSplash)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blurSigma,
                    sigmaY: widget.blurSigma,
                  ),
                  child: Container(
                    color: splashTint,
                    alignment: Alignment.center,
                    child: widget.splashContent ?? _defaultSplashContent(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

