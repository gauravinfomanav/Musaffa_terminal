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
    
    // Update chart if symbol changes
    if (oldWidget.symbol != widget.symbol) {
      widget.controller.updateSymbol(widget.symbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // WebView or Fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _isWebViewSupported && _webViewController != null
              ? WebViewWidget(
                  controller: _webViewController!,
                  gestureRecognizers: _createGestureRecognizers(),
                )
              : _buildFallback(isDarkMode),
          ),
          
          // Loading indicator
          if (_isLoading && widget.showLoading && _isWebViewSupported && _webViewController != null)
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
                        'Loading Chart...',
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
          
          // Chart header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    color: const Color(0xFF81AACE),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.symbol} Chart',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                  const Spacer(),
                  // Theme toggle button
                  IconButton(
                    onPressed: () {
                      final newTheme = isDarkMode ? 'light' : 'dark';
                      widget.controller.updateTheme(newTheme);
                    },
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: const Color(0xFF81AACE),
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(bool isDarkMode) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: const Color(0xFF81AACE),
          ),
          const SizedBox(height: 16),
          Text(
            'Chart Not Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TradingView chart is not supported on this platform',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
            textAlign: TextAlign.center,
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
    super.dispose();
  }
}
