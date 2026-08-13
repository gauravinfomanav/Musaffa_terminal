import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Desktop / plugin capabilities for Infomanav Terminal.
class PlatformCapabilities {
  const PlatformCapabilities._();

  /// `webview_flutter` ships Android, iOS, macOS, and web implementations only.
  /// Windows/Linux have no plugin — constructing [WebViewController] crashes.
  static bool get isWebViewFlutterSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Firebase Messaging is not configured for Windows/Linux in this app.
  static bool get isFcmSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// True when this platform can show HTML/TradingView widgets.
  static bool get isWebViewAvailable =>
      isWebViewFlutterSupported || isWindows;
}

/// Placeholder shown where TradingView WebViews cannot run.
class WebViewUnavailablePlaceholder extends StatelessWidget {
  const WebViewUnavailablePlaceholder({
    super.key,
    this.message = 'This widget is not available on this platform.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}
