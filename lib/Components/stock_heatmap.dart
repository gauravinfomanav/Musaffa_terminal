import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';

/// Widget height constants for stock heatmap TradingView widget
class StockHeatmapConstants {
  /// Default height for medium screens
  static const double defaultHeight = 600.0;
  
  /// Height for small screens (vertical layout)
  static const double smallScreenHeight = 500.0;
  
  /// Height for large screens
  static const double largeScreenHeight = 700.0;
  
  /// Minimum height for responsive sizing
  static const double minHeight = 400.0;
  
  /// Maximum height for responsive sizing
  static const double maxHeight = 900.0;
  
  /// Height for extra large screens
  static const double extraLargeScreenHeight = 800.0;
  
  /// Header section height (title + spacing)
  static const double headerHeight = 42.0;
  
  /// Content padding
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16.0);
  
  /// Title spacing
  static const double titleSpacing = 8.0;
  
  /// Screen width breakpoint for small screens (vertical layout)
  static const double smallScreenBreakpoint = 1000.0;
  
  /// Screen width breakpoint for large screens
  static const double largeScreenBreakpoint = 1600.0;
  
  /// Screen width breakpoint for extra large screens
  static const double extraLargeScreenBreakpoint = 2000.0;
}

/// A TradingView widget that displays stock heatmap with responsive height.
/// 
/// This widget automatically adjusts its height based on screen size, or can be
/// configured with explicit height values. It supports both light and dark themes.
/// 
/// Example usage:
/// ```dart
/// // Responsive height (default)
/// StockHeatmap()
/// 
/// // Custom explicit height
/// StockHeatmap(height: 650)
/// 
/// // Custom min/max bounds
/// StockHeatmap(
///   height: 700,
///   minHeight: 500,
///   maxHeight: 800,
/// )
/// ```
class StockHeatmap extends StatefulWidget {
  /// Explicit height for the widget. If null, uses responsive height calculation.
  /// Will be clamped between [minHeight] and [maxHeight] if provided.
  final double? height;
  
  /// Width of the widget. If null, expands to fill available space.
  final double? width;
  
  /// Whether to use responsive height calculation. Defaults to true.
  /// If false and [height] is null, uses [StockHeatmapConstants.defaultHeight].
  final bool useResponsiveHeight;
  
  /// Custom minimum height override. If null, uses [StockHeatmapConstants.minHeight].
  final double? minHeight;
  
  /// Custom maximum height override. If null, uses [StockHeatmapConstants.maxHeight].
  final double? maxHeight;
  
  /// Title text to display above the chart. Defaults to "Stock Heatmap".
  final String? title;

  const StockHeatmap({
    super.key,
    this.height,
    this.width,
    this.useResponsiveHeight = true,
    this.minHeight,
    this.maxHeight,
    this.title,
  });
  
  // Deprecated: Use [height] instead
  @Deprecated('Use height parameter instead')
  double? get initialHeight => height;

  @override
  State<StockHeatmap> createState() => _StockHeatmapState();
}

class _StockHeatmapState extends State<StockHeatmap> 
    with AutomaticKeepAliveClientMixin {
  late WebViewController _controller;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;
  bool _isWebViewInitialized = false;

  @override
  bool get wantKeepAlive => true;

  /// Calculates responsive height based on screen size if height is not provided
  double _calculateHeight(BuildContext context) {
    // If explicit height is provided, clamp it and return
    if (widget.height != null) {
      final minH = widget.minHeight ?? StockHeatmapConstants.minHeight;
      final maxH = widget.maxHeight ?? StockHeatmapConstants.maxHeight;
      return widget.height!.clamp(minH, maxH);
    }
    
    // If responsive height is disabled, use default
    if (!widget.useResponsiveHeight) {
      return StockHeatmapConstants.defaultHeight;
    }
    
    // Calculate responsive height based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < StockHeatmapConstants.smallScreenBreakpoint) {
      // Small screens (vertical layout)
      return StockHeatmapConstants.smallScreenHeight;
    } else if (screenWidth < StockHeatmapConstants.largeScreenBreakpoint) {
      // Medium screens (horizontal layout)
      return StockHeatmapConstants.defaultHeight;
    } else if (screenWidth < StockHeatmapConstants.extraLargeScreenBreakpoint) {
      // Large screens
      return StockHeatmapConstants.largeScreenHeight;
    } else {
      // Extra large screens
      return StockHeatmapConstants.extraLargeScreenHeight;
    }
  }

  // --- Function to Generate Stock Heatmap HTML ---
  String _generateStockHeatmapHtml(String colorTheme) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Stock Heatmap</title>
        <style>
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; background: #FFFFFF; }
            .tradingview-widget-container { 
                height: 100%; 
                width: 100%; 
                background: #FFFFFF !important; 
            }
            .tradingview-widget-container__widget { 
                background: #FFFFFF !important; 
            }
            iframe { 
                background: #FFFFFF !important; 
            }
            [class*="tradingview"] { 
                background: #FFFFFF !important; 
            }
            div[style*="background"] { 
                background: #FFFFFF !important; 
            }
            
            /* Remove blue highlight on scroll */
            * { -webkit-tap-highlight-color: transparent !important; }
            * { -webkit-touch-callout: none !important; }
            * { -webkit-user-select: none !important; }
            * { -moz-user-select: none !important; }
            * { -ms-user-select: none !important; }
            * { user-select: none !important; }
            
            /* Remove scroll bounce and blue header */
            body { -webkit-overflow-scrolling: touch !important; }
            * { -webkit-overflow-scrolling: touch !important; }
            
            /* Hide scrollbars and prevent scrolling */
            ::-webkit-scrollbar { display: none !important; }
            * { scrollbar-width: none !important; }
            
            /* Prevent any scrolling within the widget */
            * { overflow: hidden !important; }
            body { overflow: hidden !important; }
            html { overflow: hidden !important; }
            
            /* Enable zoom/pan but disable clicks */
            .tradingview-widget-container { 
                pointer-events: auto !important;
                cursor: grab !important;
            }
            .tradingview-widget-container__widget { 
                pointer-events: auto !important;
                cursor: grab !important;
            }
            iframe { 
                pointer-events: auto !important;
                cursor: grab !important;
            }
            
            /* Disable click events on links and buttons */
            a { pointer-events: none !important; }
            button { pointer-events: none !important; }
            [onclick] { pointer-events: none !important; }
            
            /* Keep other elements non-interactive */
            body { pointer-events: none !important; }
            html { pointer-events: none !important; }
        </style>
    </head>
    <body>
        <div class="tradingview-widget-container">
            <div class="tradingview-widget-container__widget"></div>
            <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-stock-heatmap.js" async>
            {
                "dataSource": "SPX500",
                "blockSize": "market_cap_basic",
                "blockColor": "change",
                "grouping": "sector",
                "locale": "en",
                "symbolUrl": "",
                "colorTheme": "$colorTheme",
                "exchanges": [],
                "hasTopBar": false,
                "isDataSetEnabled": false,
                "isZoomEnabled": true,
                "hasSymbolTooltip": true,
                "isMonoSize": false,
                "width": "100%",
                "height": "100%"
            }
            </script>
        </div>
    </body>
    </html>
    ''';
  }

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted && progress < 100 && !_isLoading) {
              // Optionally set loading state during navigation/reload
            }
          },
          onPageStarted: (String url) {
            print("Stock Heatmap WebView page started loading: $url");
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            print('Stock Heatmap WebView page finished loading: $url');
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _isWebViewInitialized = true;
                });
                
                // Inject minimal JavaScript to prevent window.open to TradingView website
                _controller.runJavaScript('''
                  (function() {
                    setTimeout(function() {
                      // Only prevent window.open to TradingView website pages
                      const originalOpen = window.open;
                      window.open = function(url, name, features) {
                        if (!url) return originalOpen.call(this, url, name, features);
                        const urlLower = url.toLowerCase();
                        
                        // Block opening TradingView web pages (symbol detail pages)
                        if (urlLower.includes('tradingview.com') || 
                            urlLower.includes('tradingview-widget.com')) {
                          // Check if it's a symbol detail page (not widget resource)
                          if (urlLower.includes('/symbols/') || 
                              urlLower.includes('/chart/') ||
                              urlLower.includes('/screener/') ||
                              urlLower.includes('/markets/') ||
                              urlLower.includes('/ideas/')) {
                            return null; // Block navigation to TradingView website
                          }
                        }
                        
                        return originalOpen.call(this, url, name, features);
                      };
                    }, 1000); // Wait for widget to fully load
                  })();
                ''');
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            debugPrint('''Stock Heatmap Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}''');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            
            // Always allow initial data URL load
            if (request.url.startsWith('data:text/html;base64')) {
              return NavigationDecision.navigate;
            }
            
            // Allow ALL subresources (scripts, images, iframes) - needed for widget functionality
            // Widget interactions happen within iframes, which are subresources
            if (!request.isMainFrame) {
              return NavigationDecision.navigate; // Allow all subresources
            }
            
            // For main frame navigation, be more selective
            // Block only symbol detail pages and external TradingView website pages
            if (url.contains('tradingview.com') || url.contains('tradingview-widget.com')) {
              // Block symbol detail pages and external website navigation
              if (url.contains('/symbols/') ||
                  url.contains('/chart/') ||
                  url.contains('/screener/') ||
                  url.contains('/markets/') ||
                  url.contains('/ideas/') ||
                  url.contains('/publish/') ||
                  (url.contains('www.tradingview.com') && !url.contains('s3.tradingview.com'))) {
                print('Blocking navigation to TradingView website: ${request.url}');
                return NavigationDecision.prevent;
              }
              // Allow widget resource URLs (may be needed for some widget functionality)
              return NavigationDecision.navigate;
            }
            
            // Block all other external navigation
            print('Blocking navigation to ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      );

    // Initialize WebView content after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadWebViewContent();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if theme actually changed and WebView is already initialized
    if (_isWebViewInitialized) {
      _loadWebViewContent();
    }
  }

  void _loadWebViewContent() {
    final Brightness currentBrightness = Theme.of(context).brightness;

    if (currentBrightness != _currentLoadedBrightness) {
      setState(() {
        _isLoading = true;
      });

      final String colorTheme =
          currentBrightness == Brightness.dark ? 'dark' : 'light';
      final String htmlContent = _generateStockHeatmapHtml(colorTheme);
      final String contentBase64 =
          base64Encode(const Utf8Encoder().convert(htmlContent));
      final String dataUrl = 'data:text/html;base64,$contentBase64';

      _controller.loadRequest(Uri.parse(dataUrl)).then((_) {
        if (mounted) {
          _currentLoadedBrightness = currentBrightness;
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        print("Error loading Stock Heatmap WebView content: $error");
      });
    } else {
      // If theme hasn't changed and we're still loading, it means we've already loaded
      // Set loading to false to prevent continuous loading indicator
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final calculatedHeight = _calculateHeight(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: StockHeatmapConstants.contentPadding,
            child: Text(
              widget.title ?? "Stock Heatmap",
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
              ),
            ),
          ),
          SizedBox(height: StockHeatmapConstants.titleSpacing),
          // WebView with responsive height
          SizedBox(
            height: calculatedHeight.clamp(
              widget.minHeight ?? StockHeatmapConstants.minHeight,
              widget.maxHeight ?? StockHeatmapConstants.maxHeight,
            ),
            width: widget.width ?? double.infinity,
            child: Stack(
              children: [
                // WebView content
                Padding(
                  padding: StockHeatmapConstants.contentPadding,
                  child: WebViewWidget(controller: _controller),
                ),
                // Show loading indicator only when actually loading
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
