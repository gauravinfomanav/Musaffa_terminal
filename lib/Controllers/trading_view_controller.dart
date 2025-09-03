import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingViewController extends ChangeNotifier {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String _currentSymbol = '';
  String _currentTheme = 'light';
  String _currentHeight = '400px';

  // Getters
  WebViewController? get webViewController => _webViewController;
  bool get isLoading => _isLoading;
  String get currentSymbol => _currentSymbol;
  String get currentTheme => _currentTheme;
  String get currentHeight => _currentHeight;

  // Initialize the controller
  void initializeController(WebViewController controller) {
    _webViewController = controller;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Update chart symbol
  Future<void> updateSymbol(String symbol) async {
    if (_webViewController != null && symbol != _currentSymbol) {
      _currentSymbol = symbol;
      
      try {
        await _webViewController!.runJavaScript(
          'updateSymbol("$symbol");'
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating symbol: $e');
      }
    }
  }

  // Update chart theme
  Future<void> updateTheme(String theme) async {
    if (_webViewController != null && theme != _currentTheme) {
      _currentTheme = theme;
      
      try {
        await _webViewController!.runJavaScript(
          'updateTheme("$theme");'
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating theme: $e');
      }
    }
  }

  // Update chart height
  Future<void> updateHeight(String height) async {
    if (_webViewController != null && height != _currentHeight) {
      _currentHeight = height;
      
      try {
        await _webViewController!.runJavaScript(
          'updateHeight("$height");'
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating height: $e');
      }
    }
  }

  // Reload chart
  Future<void> reloadChart() async {
    if (_webViewController != null) {
      try {
        await _webViewController!.runJavaScript(
          'location.reload();'
        );
      } catch (e) {
        debugPrint('Error reloading chart: $e');
      }
    }
  }

  // Dispose
  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
