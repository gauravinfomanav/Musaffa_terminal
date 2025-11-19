import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:musaffa_terminal/Controllers/trading_view_controller.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/models/trading_chart_ticker.dart';
import 'dart:convert';
import 'dart:io';

class TradingViewWidget extends StatefulWidget {
  final String symbol;
  final TradingViewController controller;
  final double height;
  final bool showLoading;
  final String? country;
  final String? exchange;

  const TradingViewWidget({
    Key? key,
    required this.symbol,
    required this.controller,
    this.height = 400,
    this.showLoading = true,
    this.country,
    this.exchange,
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
  String _formattedSymbol = '';
  bool _shouldShowChart = false;
  Tickerformat? _tradingChartTicker;

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    _loadHtmlContent();
    _prepareSymbol();
  }

  Future<void> _prepareSymbol() async {
    String symbolStr = '';
    
    if (widget.country == 'US') {
      // For US stocks, use symbol as-is
      symbolStr = widget.symbol;
      _shouldShowChart = true;
      debugPrint('US stock - using symbol as-is: $symbolStr');
    } else if (widget.country == 'IN') {
      // For Indian stocks, lookup in bse_tickers collection
      final mainTicker = widget.symbol.split('.').first;
      debugPrint('Indian stock - main ticker: $mainTicker, exchange: ${widget.exchange}');
      await _lookupTradingViewTicker(mainTicker);
      
      if ((_tradingChartTicker?.found ?? 0) >= 1) {
        if (widget.exchange == 'BOM') {
          // BSE: Use ticker from Typesense, replace - with _, prefix BSE:
          String? ticker = _tradingChartTicker?.hits?.first.document?.ticker;
          String? result = ticker?.replaceAll('-', '_');
          symbolStr = "BSE:$result";
          debugPrint('BSE stock - formatted symbol: $symbolStr');
        } else if (widget.exchange == 'NSE') {
          // NSE: Use main ticker, replace - with _, prefix BSE:
          String? result = mainTicker.replaceAll('-', '_');
          symbolStr = "BSE:$result";
          debugPrint('NSE stock - formatted symbol: $symbolStr');
        }
        _shouldShowChart = true;
      } else {
        _shouldShowChart = false;
        debugPrint('Indian stock not found in bse_tickers collection');
      }
    } else {
      // For other countries, try to show chart
      symbolStr = widget.symbol;
      _shouldShowChart = true;
      debugPrint('Other country - using symbol as-is: $symbolStr');
    }
    
    _formattedSymbol = symbolStr;
    debugPrint('Final formatted symbol: $_formattedSymbol, shouldShowChart: $_shouldShowChart');
    
    // Update chart if WebView is already initialized
    if (_isWebViewInitialized && _webViewController != null && _shouldShowChart) {
      widget.controller.updateSymbol(_formattedSymbol);
    }
  }

  Future<void> _lookupTradingViewTicker(String mainTicker) async {
    try {
      String filterBy;
      if (widget.exchange == 'BOM') {
        filterBy = "code:=$mainTicker";
      } else if (widget.exchange == 'NSE') {
        filterBy = "ticker:=$mainTicker";
      } else {
        debugPrint('No filter for exchange: ${widget.exchange}');
        return;
      }

      Map<String, dynamic> params = {
        'q': '*',
        'filter_by': filterBy,
      };

      debugPrint('Looking up TradingView ticker: $mainTicker with filter: $filterBy');

      final response = await WebService.getTypesense(
        ['collections', 'bse_tickers', 'documents', 'search'],
        params,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('Typesense response: found=${decoded['found']}, hits=${decoded['hits']?.length ?? 0}');
        setState(() {
          _tradingChartTicker = Tickerformat.fromJson(decoded);
        });
        debugPrint('Parsed ticker: ${_tradingChartTicker?.hits?.first.document?.ticker}');
      } else {
        debugPrint('Typesense lookup failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error looking up TradingView ticker: $e');
      debugPrint('Stack trace: $stackTrace');
    }
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
            debugPrint('Navigation request: ${request.url} | isMainFrame=${request.isMainFrame}');
            // Allow all subresource requests (scripts, iframes) for widget functionality
            if (request.isMainFrame == false) {
              return NavigationDecision.navigate;
            }
            final url = request.url;
            final lowerUrl = url.toLowerCase();
            // Allow initial data loads or blank navigations
            if (lowerUrl.startsWith('data:') || lowerUrl == 'about:blank') {
              return NavigationDecision.navigate;
            }
            // If navigating to TradingView hosts, block only known site pages; allow widget/CDN
            final isTvHost = lowerUrl.contains('s3.tradingview.com') ||
                lowerUrl.contains('tradingview-widget.com') ||
                lowerUrl.contains('tradingview.com');
            if (isTvHost) {
              final isSitePage = lowerUrl.contains('/symbols/') ||
                  lowerUrl.contains('/chart/') ||
                  lowerUrl.contains('/screener/') ||
                  lowerUrl.contains('/markets/') ||
                  lowerUrl.contains('/ideas/') ||
                  lowerUrl.contains('/publish/');
              if (isSitePage || lowerUrl.contains('www.tradingview.com')) {
                debugPrint('Blocked TradingView site navigation: $url');
                return NavigationDecision.prevent;
              }
              // Allow widget/CDN navigations
              return NavigationDecision.navigate;
            }
            // Block all other main-frame external navigations
            debugPrint('Blocked main-frame navigation to: ${request.url}');
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
      if (_webViewController != null && _shouldShowChart && _formattedSymbol.isNotEmpty) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final theme = isDarkMode ? 'dark' : 'light';
        
        debugPrint('Flutter: Calling initChart with symbol: $_formattedSymbol, theme: $theme, height: ${widget.height}px');
        
        // First check if the function exists
        final functionExists = await _webViewController!.runJavaScriptReturningResult(
          'typeof initChart === "function"'
        );
        debugPrint('Flutter: initChart function exists: $functionExists');
        
        // Then call the function with formatted symbol
        await _webViewController!.runJavaScript(
          'initChart("$_formattedSymbol", "$theme", "${widget.height}px");'
        );
        
        debugPrint('Flutter: initChart called successfully');
      } else if (!_shouldShowChart) {
        debugPrint('Flutter: Chart not shown - symbol not found in bse_tickers collection');
      }
    } catch (e) {
      debugPrint('Error initializing chart: $e');
    }
  }

  @override
  void didUpdateWidget(TradingViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update chart if symbol, country, or exchange changes
    if ((oldWidget.symbol != widget.symbol || 
         oldWidget.country != widget.country || 
         oldWidget.exchange != widget.exchange) && 
        _webViewController != null && !_isLoading) {
      // Re-prepare symbol and update chart
      _prepareSymbol().then((_) {
        if (mounted && _webViewController != null && _shouldShowChart) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _webViewController != null) {
              widget.controller.updateSymbol(_formattedSymbol);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth,
      height: widget.height,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            // WebView with overscan to clip gaps - only show if chart should be displayed
            if (_isWebViewSupported && _webViewController != null && _shouldShowChart)
              Transform.scale(
                scale: 1.02,
                child: WebViewWidget(
                  controller: _webViewController!,
                  gestureRecognizers: _createGestureRecognizers(),
                ),
              ),
            
            // Show message if chart shouldn't be displayed (e.g., Indian stock not found in lookup)
            if (!_shouldShowChart && widget.country == 'IN')
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                  ),
                  child: Center(
                    child: Text(
                      'Chart not available for this symbol',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Loading indicator - show when loading OR when WebView not ready
            if (_isLoading || _webViewController == null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
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
          ],
        ),
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