import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashOverlay extends StatefulWidget {
  final Widget child;
  
  const SplashOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _hideSplash();
  }

  _hideSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      _fadeController.forward().then((_) {
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content with opacity
        Opacity(
          opacity: _showSplash ? 0.3 : 1.0,
          child: widget.child,
        ),
        // Splash overlay
        if (_showSplash)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF0F0F0F).withOpacity(0.95)
                  : const Color(0xFFFAFAFA).withOpacity(0.95),
              child: Center(
                child: Lottie.asset(
                  'resources/Sandy Loading.json',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

