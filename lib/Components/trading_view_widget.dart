import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:musaffa_terminal/Controllers/trading_view_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'dart:io';

class TradingViewWidget extends StatefulWidget {
  final String symbol;
  final TradingViewController controller;
  final double height;
  final bool showLoading;

  const TradingViewWidget({
    Key? key,
    required this.symbol,
    required this.controller,
    this.height = 400,
    this.showLoading = true,
  }) : super(key: key);

  @override
  State<TradingViewWidget> createState() => _TradingViewWidgetState();
}

class _TradingViewWidgetState extends State<TradingViewWidget> {
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
      
      debugPrint('Initializing WebView for ${widget.symbol}');
      
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..enableZoom(false);
      
      _webViewController!.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            debugPrint('Navigation request: ${request.url}');
            // Allow TradingView scripts to load, block other external navigation
            if (request.url.startsWith('https://s3.tradingview.com') ||
                request.url.startsWith('https://www.tradingview.com')) {
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
      debugPrint('Loading HTML content for ${widget.symbol}');
      // Load the HTML content from the web directory
      _htmlContent = await rootBundle.loadString('web/tradingview_chart.html');
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
    
    // Initialize the chart with the current symbol and theme
    _initializeChart();
    
    // Add a small delay to ensure the chart is fully loaded
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _initializeChart() async {
    try {
      if (_webViewController != null) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final theme = isDarkMode ? 'dark' : 'light';
        
        debugPrint('Flutter: Calling initChart with symbol: ${widget.symbol}, theme: $theme, height: ${widget.height}px');
        
        // First check if the function exists
        final functionExists = await _webViewController!.runJavaScriptReturningResult(
          'typeof initChart === "function"'
        );
        debugPrint('Flutter: initChart function exists: $functionExists');
        
        // Then call the function
        await _webViewController!.runJavaScript(
          'initChart("${widget.symbol}", "$theme", "${widget.height}px");'
        );
        
        debugPrint('Flutter: initChart called successfully');
      }
    } catch (e) {
      debugPrint('Error initializing chart: $e');
    }
  }

  @override
  void didUpdateWidget(TradingViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update chart if symbol changes, but only if WebView is ready
    if (oldWidget.symbol != widget.symbol && _webViewController != null && !_isLoading) {
      // Use a small delay to avoid rapid successive calls
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _webViewController != null) {
          widget.controller.updateSymbol(widget.symbol);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          // WebView or Fallback
          if (_isWebViewSupported && _webViewController != null)
            WebViewWidget(
              controller: _webViewController!,
              gestureRecognizers: _createGestureRecognizers(),
            ),
          
          // Loading indicator - show when loading OR when WebView not ready
          if (_isLoading || _webViewController == null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
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
                        _webViewController == null ? 'Initializing Chart...' : 'Loading Chart...',
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
          
          // Theme toggle button - positioned at top right corner
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF404040).withOpacity(0.8) : const Color(0xFFE5E7EB).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  final newTheme = isDarkMode ? 'light' : 'dark';
                  widget.controller.updateTheme(newTheme);
                },
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: const Color(0xFF81AACE),
                  size: 18,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fallback method removed - loading indicator handles all states now

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
