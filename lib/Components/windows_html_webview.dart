import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/platform_capabilities.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

bool _forwardWheelToParent(BuildContext context, dynamic message) {
  double? dy;
  try {
    final decoded = message is String ? jsonDecode(message) : message;
    if (decoded is Map && decoded['type'] == 'wheel') {
      dy = (decoded['dy'] as num?)?.toDouble();
    }
  } catch (_) {
    return false;
  }
  if (dy == null || dy == 0) return false;

  final controller = PrimaryScrollController.maybeOf(context);
  if (controller == null || !controller.hasClients) return false;

  final position = controller.position;
  final next = (position.pixels + dy).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if (next != position.pixels) {
    controller.jumpTo(next);
  }
  return true;
}

/// Handle for running JS in the Windows WebView2 instance.
class WindowsWebViewHandle {
  WindowsWebViewHandle(this._controller);

  final WebviewController _controller;

  Future<dynamic> runJavaScript(String script) =>
      _controller.executeScript(script);
}

/// WebView2 (Edge) HTML view — used on Windows only.
class WindowsHtmlWebView extends StatefulWidget {
  const WindowsHtmlWebView({
    super.key,
    this.html,
    this.url,
    this.onCreated,
    this.onPageFinished,
    this.onJsMessage,
    this.backgroundColor,
  }) : assert(html != null || url != null, 'html or url is required');

  final String? html;
  final String? url;
  final void Function(WindowsWebViewHandle handle)? onCreated;
  final VoidCallback? onPageFinished;
  final void Function(dynamic message)? onJsMessage;
  final Color? backgroundColor;

  @override
  State<WindowsHtmlWebView> createState() => _WindowsHtmlWebViewState();
}

class _WindowsHtmlWebViewState extends State<WindowsHtmlWebView> {
  final WebviewController _controller = WebviewController();
  StreamSubscription<LoadingState>? _loadingSub;
  StreamSubscription<dynamic>? _messageSub;
  StreamSubscription<String>? _urlSub;
  bool _ready = false;
  String? _error;

  static const String _channelBridge = r'''
(function () {
  if (window.__musaffaChannelBound) return;
  window.__musaffaChannelBound = true;
  if (window !== window.top) return;
  function bindChannel(name) {
    var target = window[name];
    if (target && typeof target === "function") {
      target.postMessage = function (msg) {
        if (window.chrome && window.chrome.webview) {
          window.chrome.webview.postMessage(String(msg));
        }
      };
      return;
    }
    window[name] = {
      postMessage: function (msg) {
        if (window.chrome && window.chrome.webview) {
          window.chrome.webview.postMessage(String(msg));
        }
      }
    };
  }
  bindChannel("Print");
})();
''';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      if (widget.backgroundColor != null) {
        await _controller.setBackgroundColor(widget.backgroundColor!);
      }
      await _controller.addScriptToExecuteOnDocumentCreated(_channelBridge);

      widget.onCreated?.call(WindowsWebViewHandle(_controller));

      _loadingSub = _controller.loadingState.listen((LoadingState state) {
        if (state == LoadingState.navigationCompleted) {
          widget.onPageFinished?.call();
        }
      });
      _messageSub = _controller.webMessage.listen((dynamic message) {
        if (!mounted) return;
        if (_forwardWheelToParent(context, message)) return;
        widget.onJsMessage?.call(message);
      });
      _urlSub = _controller.url.listen(_blockExternalSiteNavigation);

      if (widget.url != null) {
        await _controller.loadUrl(widget.url!);
      } else {
        await _controller.loadStringContent(widget.html!);
      }
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _blockExternalSiteNavigation(String url) {
    final String lower = url.toLowerCase();
    if (lower.startsWith('data:') ||
        lower == 'about:blank' ||
        lower.contains('s3.tradingview.com') ||
        lower.contains('s.tradingview.com/embed-widget') ||
        lower.contains('tradingview-widget.com')) {
      return;
    }
    if (lower.contains('www.tradingview.com') ||
        lower.contains('/symbols/') ||
        lower.contains('/chart/')) {
      _controller.goBack();
    }
  }

  @override
  void didUpdateWidget(WindowsHtmlWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    if (widget.url != null && oldWidget.url != widget.url) {
      _controller.loadUrl(widget.url!);
      return;
    }
    if (widget.html != null && oldWidget.html != widget.html) {
      _controller.loadStringContent(widget.html!);
    }
  }

  @override
  void dispose() {
    _loadingSub?.cancel();
    _messageSub?.cancel();
    _urlSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return WebViewUnavailablePlaceholder(
        message:
            'WebView2 is required on Windows.\nInstall the Microsoft Edge WebView2 Runtime.\n\n$_error',
      );
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return Webview(_controller);
  }
}

/// Shrinks [logicalSize] to cover a whole number of device pixels.
///
/// A WebView whose height lands on a fractional device pixel leaves the last
/// physical pixel row uncovered by the page, which macOS renders as a dark
/// hairline. Snapping the layout size removes that sliver at the source.
///
/// This always rounds down. Callers sit in height-constrained layouts with no
/// spare room, so growing the size — even by a fraction of a pixel — would
/// overflow the parent.
double snapToDevicePixels(BuildContext context, double logicalSize) {
  final double ratio = MediaQuery.of(context).devicePixelRatio;
  if (ratio <= 0 || !logicalSize.isFinite) return logicalSize;
  return (logicalSize * ratio).floorToDouble() / ratio;
}

/// Hides the platform-view edge seam that macOS draws under a WKWebView.
///
/// macOS composites the WKWebView as a native view rather than into the Flutter
/// layer. Wherever the page does not paint every device pixel of that view —
/// typically the bottom or right edge on a fractional-pixel boundary — the
/// window backing shows through as a ~1px dark line. Growing the WebView past
/// its layout box and clipping the overflow pushes that edge out of sight.
///
/// Note: this cannot be fixed with [WebViewController.setBackgroundColor].
/// On macOS that call throws, because `webview_flutter_wkwebview` routes it
/// through `WKWebView.scrollView`, which only exists on iOS.
class _EdgeSeamGuard extends StatelessWidget {
  const _EdgeSeamGuard({required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  /// One logical pixel covers the seam at every device pixel ratio >= 1.
  static const double _overscan = 1.0;

  @override
  Widget build(BuildContext context) {
    final Widget clipped = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return child;
        }
        final double width = constraints.maxWidth + _overscan;
        final double height = constraints.maxHeight + _overscan;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxWidth: width,
            maxHeight: height,
            child: SizedBox(width: width, height: height, child: child),
          ),
        );
      },
    );

    final Color? background = backgroundColor;
    if (background == null) return clipped;
    return ColoredBox(color: background, child: clipped);
  }
}

/// Picks the Mac/iOS/Android [WebViewWidget] or Windows WebView2.
///
/// On macOS the WebView is wrapped in an [_EdgeSeamGuard] to suppress the
/// native platform-view edge seam. Windows never constructs `webview_flutter`
/// controllers, and WebView2 has no seam because it honours
/// [WebviewController.setBackgroundColor].
class AdaptiveHtmlWebView extends StatelessWidget {
  const AdaptiveHtmlWebView({
    super.key,
    this.html,
    this.url,
    this.flutterController,
    this.onWindowsCreated,
    this.onWindowsPageFinished,
    this.onWindowsJsMessage,
    this.backgroundColor,
    this.gestureRecognizers,
  }) : assert(html != null || url != null, 'html or url is required');

  final String? html;
  final String? url;
  final WebViewController? flutterController;
  final void Function(WindowsWebViewHandle handle)? onWindowsCreated;
  final VoidCallback? onWindowsPageFinished;
  final void Function(dynamic message)? onWindowsJsMessage;
  final Color? backgroundColor;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.isWebViewFlutterSupported &&
        flutterController != null) {
      return _EdgeSeamGuard(
        backgroundColor: backgroundColor,
        child: gestureRecognizers != null
            ? WebViewWidget(
                controller: flutterController!,
                gestureRecognizers: gestureRecognizers!,
              )
            : WebViewWidget(controller: flutterController!),
      );
    }

    if (PlatformCapabilities.isWindows) {
      return WindowsHtmlWebView(
        html: html,
        url: url,
        onCreated: onWindowsCreated,
        onPageFinished: onWindowsPageFinished,
        onJsMessage: onWindowsJsMessage,
        backgroundColor: backgroundColor,
      );
    }

    return const WebViewUnavailablePlaceholder();
  }
}
