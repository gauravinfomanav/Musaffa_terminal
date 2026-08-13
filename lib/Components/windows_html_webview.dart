import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/platform_capabilities.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

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
    required this.html,
    this.onCreated,
    this.onPageFinished,
    this.onJsMessage,
    this.backgroundColor,
  });

  final String html;
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
  bindChannel("ResizeObserver");
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
        widget.onJsMessage?.call(message);
      });
      _urlSub = _controller.url.listen(_blockExternalSiteNavigation);

      await _controller.loadStringContent(widget.html);
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
    if (oldWidget.html != widget.html && _ready) {
      _controller.loadStringContent(widget.html);
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

/// Picks the Mac/iOS/Android [WebViewWidget] or Windows WebView2.
///
/// On macOS this is a passthrough to [WebViewWidget] — same controller,
/// same behavior. Windows never constructs `webview_flutter` controllers.
class AdaptiveHtmlWebView extends StatelessWidget {
  const AdaptiveHtmlWebView({
    super.key,
    required this.html,
    this.flutterController,
    this.onWindowsCreated,
    this.onWindowsPageFinished,
    this.onWindowsJsMessage,
    this.backgroundColor,
    this.gestureRecognizers,
  });

  final String html;
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
      if (gestureRecognizers != null) {
        return WebViewWidget(
          controller: flutterController!,
          gestureRecognizers: gestureRecognizers!,
        );
      }
      return WebViewWidget(controller: flutterController!);
    }

    if (PlatformCapabilities.isWindows) {
      return WindowsHtmlWebView(
        html: html,
        onCreated: onWindowsCreated,
        onPageFinished: onWindowsPageFinished,
        onJsMessage: onWindowsJsMessage,
        backgroundColor: backgroundColor,
      );
    }

    return const WebViewUnavailablePlaceholder();
  }
}
