import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingViewController extends ChangeNotifier {
  WebViewController? _webViewController;
  Future<dynamic> Function(String script)? _jsRunner;
  bool _isLoading = true;
  String _currentSymbol = '';
  String _currentTheme = 'light';
  String _currentHeight = '400px';

  WebViewController? get webViewController => _webViewController;
  bool get isLoading => _isLoading;
  String get currentSymbol => _currentSymbol;
  String get currentTheme => _currentTheme;
  String get currentHeight => _currentHeight;

  void initializeController(WebViewController controller) {
    _webViewController = controller;
    notifyListeners();
  }

  /// Windows WebView2 path — Mac continues to use [initializeController].
  void initializeJsRunner(Future<dynamic> Function(String script) runner) {
    _jsRunner = runner;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _run(String script) async {
    if (_webViewController != null) {
      await _webViewController!.runJavaScript(script);
      return;
    }
    if (_jsRunner != null) {
      await _jsRunner!(script);
    }
  }

  bool get _canRunJs => _webViewController != null || _jsRunner != null;

  Future<void> updateSymbol(String symbol) async {
    if (_canRunJs && symbol != _currentSymbol) {
      _currentSymbol = symbol;
      try {
        await _run('updateSymbol("$symbol");');
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating symbol: $e');
      }
    }
  }

  Future<void> updateTheme(String theme) async {
    if (_canRunJs && theme != _currentTheme) {
      _currentTheme = theme;
      try {
        await _run('updateTheme("$theme");');
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating theme: $e');
      }
    }
  }

  Future<void> updateHeight(String height) async {
    if (_canRunJs && height != _currentHeight) {
      _currentHeight = height;
      try {
        await _run('updateHeight("$height");');
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating height: $e');
      }
    }
  }

  Future<void> reloadChart() async {
    if (_canRunJs) {
      try {
        await _run('location.reload();');
      } catch (e) {
        debugPrint('Error reloading chart: $e');
      }
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    _jsRunner = null;
    super.dispose();
  }
}
