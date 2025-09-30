import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/Controllers/trading_view_market_overview_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'dart:io';

class TradingViewMarketOverviewWidget extends StatefulWidget {
  final TradingViewMarketOverviewController controller;
  final double height;
  final bool showLoading;

  const TradingViewMarketOverviewWidget({
    Key? key,
    required this.controller,
    this.height = 400,
    this.showLoading = true,
  }) : super(key: key);

  @override
  State<TradingViewMarketOverviewWidget> createState() => _TradingViewMarketOverviewWidgetState();
}

class _TradingViewMarketOverviewWidgetState extends State<TradingViewMarketOverviewWidget> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String _htmlContent = '';
  bool _isWebViewSupported = true;
  bool _isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    _loadHtmlContent();
  }

  void _checkPlatformSupport() {
    // Check if webview is supported on current platform
    if (Platform.isMacOS) {
      _isWebViewSupported = true;
      debugPrint('macOS platform detected, WebView should be supported');
    } else {
      _isWebViewSupported = false;
      debugPrint('Platform not supported for WebView');
    }
  }

  Future<void> _initializeWebView() async {
    try {
      // Prevent multiple initializations
      if (_isWebViewInitialized) {
        debugPrint('WebView already initialized, skipping...');
        return;
      }
      
      debugPrint('Initializing WebView for Market Overview');
      
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..enableZoom(false);
      
      _webViewController!.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            debugPrint('Navigation request: ${request.url}');
            // Allow TradingView scripts and widget domains to load
            if (request.url.startsWith('https://s3.tradingview.com') ||
                request.url.startsWith('https://www.tradingview.com') ||
                request.url.startsWith('https://www.tradingview-widget.com')) {
              return NavigationDecision.navigate;
            }
            // Block external navigation to prevent leaving the app
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (url) {
            debugPrint('Page finished loading: $url');
            _onPageFinished();
          },
          onWebResourceError: (error) {
            debugPrint('WebView resource error: ${error.description}, URL: ${error.url}');
            // If there's an error, fall back to alternative display
            setState(() {
              _isWebViewSupported = false;
            });
          },
          onProgress: (progress) {
            debugPrint('WebView loading progress: $progress%');
          },
        ),
      );

      // Add JavaScript channel for console logging
      _webViewController!.addJavaScriptChannel(
        'Print',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('JS Console: ${message.message}');
        },
      );

      // Initialize the controller
      widget.controller.initializeController(_webViewController!);
      
      // Load the HTML content into the WebView
      await _webViewController!.loadHtmlString(
        _htmlContent,
        baseUrl: 'https://s3.tradingview.com', // Required for external script loading
      );
      
      _isWebViewInitialized = true;
      debugPrint('WebView initialized successfully');
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      setState(() {
        _isWebViewSupported = false;
      });
    }
  }

  Future<void> _loadHtmlContent() async {
    try {
      debugPrint('Loading HTML content for Market Overview');
      // Load the HTML content from the web directory
      _htmlContent = await rootBundle.loadString('web/trading_view_market_overview.html');
      debugPrint('HTML content loaded successfully, length: ${_htmlContent.length}');
      
      // Initialize webview after content is loaded
      if (_isWebViewSupported) {
        _initializeWebView();
      }
    } catch (e) {
      debugPrint('Error loading HTML content: $e');
      setState(() {
        _isWebViewSupported = false;
      });
    }
  }

  void _onPageFinished() {
    setState(() {
      _isLoading = false;
    });
    widget.controller.setLoading(false);
    
    // Initialize the Market Overview with the current theme and height
    _initializeMarketOverview();
    
    // Add a small delay to ensure the widget is fully loaded
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _initializeMarketOverview() async {
    try {
      if (_webViewController != null) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final theme = isDarkMode ? 'dark' : 'light';
        
        debugPrint('Flutter: Calling initMarketOverview with theme: $theme, height: ${widget.height}px');
        
        // Wait a bit for the page to fully load before calling the function
        await Future.delayed(const Duration(milliseconds: 500));
        
        // First check if the function exists
        final functionExists = await _webViewController!.runJavaScriptReturningResult(
          'typeof initMarketOverview === "function"'
        );
        debugPrint('Flutter: initMarketOverview function exists: $functionExists');
        
        // Then call the function
        await _webViewController!.runJavaScript(
          'initMarketOverview("$theme", "${widget.height}px");'
        );
        
        // Force transparency after widget loads
        await Future.delayed(const Duration(milliseconds: 1500));
        await _webViewController!.runJavaScript(
          'forceTransparency();'
        );
        
        debugPrint('Flutter: initMarketOverview called successfully');
      }
    } catch (e) {
      debugPrint('Error initializing Market Overview: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // WebView or Fallback
          if (_isWebViewSupported && _webViewController != null)
            WebViewWidget(
              key: const ValueKey('market_overview_webview'),
              controller: _webViewController!,
              gestureRecognizers: _createGestureRecognizers(),
            ),
          
          // Loading indicator - show when loading OR when WebView not ready
          if (_isLoading || _webViewController == null)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF81AACE),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _webViewController == null ? 'Initializing Market Overview...' : 'Loading Market Overview...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
        ],
      ),
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>> _createGestureRecognizers() {
    return <Factory<OneSequenceGestureRecognizer>>{
      Factory<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(),
      ),
      Factory<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(),
      ),
      Factory<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(),
      ),
      Factory<TapGestureRecognizer>(
        () => TapGestureRecognizer(),
      ),
    };
  }

  @override
  void dispose() {
    // Clean up WebView controller to prevent recreation errors
    if (_webViewController != null) {
      _webViewController = null;
    }
    super.dispose();
  }
}
