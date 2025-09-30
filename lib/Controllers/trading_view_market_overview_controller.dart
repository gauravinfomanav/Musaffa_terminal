import 'package:webview_flutter/webview_flutter.dart';

class TradingViewMarketOverviewController {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String _currentTheme = 'light';

  WebViewController? get webViewController => _webViewController;
  bool get isLoading => _isLoading;
  String get currentTheme => _currentTheme;

  void initializeController(WebViewController controller) {
    _webViewController = controller;
  }

  void setLoading(bool loading) {
    _isLoading = loading;
  }

  void updateTheme(String theme) {
    _currentTheme = theme;
    if (_webViewController != null) {
      _webViewController!.runJavaScript(
        'initMarketOverview("$theme", "400px");'
      );
    }
  }

  void updateHeight(double height) {
    if (_webViewController != null) {
      _webViewController!.runJavaScript(
        'initMarketOverview("$_currentTheme", "${height}px");'
      );
    }
  }

  void dispose() {
    _webViewController = null;
  }
}
