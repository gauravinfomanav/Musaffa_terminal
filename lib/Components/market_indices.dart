import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async'; // Import for Timer

/// Widget height constants for market indices TradingView widget
class DynamicHeightTradingViewConstants {
  /// Default height for medium screens (horizontal layout)
  static const double defaultHeight = 600.0;
  
  /// Height for small screens (vertical layout)
  static const double smallScreenHeight = 600.0;
  
  /// Height for large screens
  static const double largeScreenHeight = 700.0;
  
  /// Minimum height for responsive sizing
  static const double minHeight = 410.0;
  
  /// Maximum height for responsive sizing
  static const double maxHeight = 910.0;
  
  /// Height for extra large screens
  static const double extraLargeScreenHeight = 800.0;
  
  /// Title section height (title + spacing)
  static const double titleHeight = 42.0;
  
  /// Content padding
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16.0);
  
  /// Title spacing
  static const double titleSpacing = 26.0;
  
  /// Animation duration for height changes
  static const Duration animationDuration = Duration(milliseconds: 250);
  
  /// Screen width breakpoint for small screens (vertical layout)
  static const double smallScreenBreakpoint = 1000.0;
  
  /// Screen width breakpoint for large screens
  static const double largeScreenBreakpoint = 1600.0;
  
  /// Screen width breakpoint for extra large screens
  static const double extraLargeScreenBreakpoint = 2000.0;
}

/// A TradingView widget that displays market indices overview with responsive height.
/// 
/// This widget automatically adjusts its height based on screen size, or can be
/// configured with explicit height values. It supports both light and dark themes.
/// 
/// Example usage:
/// ```dart
/// // Responsive height (default)
/// DynamicHeightTradingView()
/// 
/// // Custom explicit height
/// DynamicHeightTradingView(height: 650)
/// 
/// // Custom min/max bounds
/// DynamicHeightTradingView(
///   height: 700,
///   minHeight: 500,
///   maxHeight: 800,
/// )
/// 
/// // Disable responsive height
/// DynamicHeightTradingView(
///   height: 600,
///   useResponsiveHeight: false,
/// )
/// ```
class DynamicHeightTradingView extends StatefulWidget {
  /// Explicit height for the widget. If null, uses responsive height calculation.
  /// Will be clamped between [minHeight] and [maxHeight] if provided.
  final double? height;
  
  /// Width of the widget. If null, expands to fill available space.
  final double? width;
  
  /// Whether to use responsive height calculation. Defaults to true.
  /// If false and [height] is null, uses [DynamicHeightTradingViewConstants.defaultHeight].
  final bool useResponsiveHeight;
  
  /// Custom minimum height override. If null, uses [DynamicHeightTradingViewConstants.minHeight].
  final double? minHeight;
  
  /// Custom maximum height override. If null, uses [DynamicHeightTradingViewConstants.maxHeight].
  final double? maxHeight;
  
  /// Title text to display above the chart. Defaults to "Market Indices".
  final String? title;

  /// Optional padding applied to the title and content. Defaults to
  /// [DynamicHeightTradingViewConstants.contentPadding].
  final EdgeInsetsGeometry? contentPadding;

  const DynamicHeightTradingView({
    super.key,
    this.height,
    this.width,
    this.useResponsiveHeight = true,
    this.minHeight,
    this.maxHeight,
    this.title,
    this.contentPadding,
  });
  
  // Deprecated: Use [height] instead
  @Deprecated('Use height parameter instead')
  double? get initialHeight => height;

  @override
  State<DynamicHeightTradingView> createState() =>
      _DynamicHeightTradingViewState();
}

class _DynamicHeightTradingViewState extends State<DynamicHeightTradingView> {
  late WebViewController _controller;
  double? _webViewHeight; // State variable to hold the dynamic height
  bool _isLoading = true; // Track loading state (initial and theme changes)
  Brightness? _currentLoadedBrightness; // Track the theme loaded in WebView
  Timer? _resizeTimer; // Timer to debounce resize events

  // --- Function to Generate TradingView HTML ---
  String _generateTradingViewHtml(String colorTheme) {
    // Ensure width and height in the *script config* are 100%
    // Added ResizeObserver JavaScript
    return '''
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>TradingView Widget</title>        
        <style>
          
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; }
            
            .tradingview-widget-container { height: 100%; width: 100%; }
            
        </style>
    </head>
    <body>
        <!-- TradingView Widget BEGIN -->
        <div class="tradingview-widget-container">
          <div class="tradingview-widget-container__widget"></div>
          
          <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-market-overview.js" async>
          {
      "title": "Indices",
      "tabs": [
        {
          "title": "US & Canada",
          "title_raw": "US & Canada",
          "symbols": [
            {
              "s": "FOREXCOM:SPXUSD",
              "d": "S&P 500"
            },
            {
              "s": "FOREXCOM:NSXUSD",
              "d": "US 100"
            },
            {
              "s": "BMFBOVESPA:ISP1!",
              "d": "S&P 500"
            },
            {
          "s": "CAPITALCOM:US500",
          "d": "US 500",
          "logoid": "indices/s-and-p-500",
          "currency-logoid": "country/US"
        },
            {
              "s": "FOREXCOM:DJI",
              "d": "Dow 30"
            },
            {
          "s": "CAPITALCOM:GOLD",
          "d": "GOLD",
          "logoid": "metal/gold",
          "currency-logoid": "country/US"
        }, {
          "s": "CAPITALCOM:SILVER",
          "d": "SILVER",
          "logoid": "metal/silver",
          "currency-logoid": "country/US"
        }
          ]
        },
        {
          "title": "Europe",
          "title_raw": "Europe",
          "symbols": [
            {
              "s": "INDEX:SX5E",
              "d": "Euro Stoxx 50"
            },
            {
              "s": "FOREXCOM:UKXGBP",
              "d": "UK 100"
            },
            {
              "s": "INDEX:DEU40",
              "d": "DAX Index"
            },
            {
              "s": "INDEX:CAC40",
              "d": "CAC 40 Index"
            },
            {
              "s": "INDEX:SMI",
              "d": "SWISS MARKET INDEX SMI® PRICE"
            },
            {
          "s": "CAPITALCOM:GOLD",
          "d": "GOLD",
          "logoid": "metal/gold",
          "currency-logoid": "country/GB"
        },
         {
          "s": "CAPITALCOM:SILVER",
          "d": "SILVER",
          "logoid": "metal/silver",
          "currency-logoid": "country/US"
        }
          ]
        },
        {
          "title": "Asia/Pacific",
          "title_raw": "Asia/Pacific",
          "symbols": [
            {
              "s": "INDEX:NKY",
              "d": "Nikkei 225"
            },
            {
              "s": "INDEX:HSI",
              "d": "Hang Seng"
            },
            {
              "s": "BSE:SENSEX",
              "d": "Sensex"
            },
            {
              "s": "BSE:BSE500",
              "d": "S&P BSE 500 INDEX"
            },
            {
              "s": "INDEX:KSIC",
              "d": "Kospi Composite"
            },
            {
          "s": "CAPITALCOM:GOLD",
          "d": "GOLD",
          "logoid": "metal/gold",
          "currency-logoid": "country/IN"
        }, {
          "s": "CAPITALCOM:SILVER",
          "d": "SILVER",
          "logoid": "metal/silver",
          "currency-logoid": "country/US"
        }
          ]
        }
      ],
      "width": "100%",
      "height": "100%",
      "showChart": true,
      "showFloatingTooltip": false,
      "locale": "en",
      "plotLineColorGrowing": "#1FB16E",
      "plotLineColorFalling": "#1FB16E",
      "belowLineFillColorGrowing": "rgba(31, 177, 110, 0.12)",
      "belowLineFillColorFalling": "rgba(31, 177, 110, 0.12)",
      "belowLineFillColorGrowingBottom": "rgba(31, 177, 110, 0)",
      "belowLineFillColorFallingBottom": "rgba(31, 177, 110, 0)",
      "gridLineColor": "rgba(240, 243, 250, 0)",
      "scaleFontColor": "rgba(120, 123, 134, 1)",
      "showSymbolLogo": true,
      "symbolActiveColor": "rgba(41, 98, 255, 0.12)",
      "colorTheme": "$colorTheme"
    }
          </script>
        </div>
        <!-- TradingView Widget END -->

    </body>
    </html>
    ''';
  }
  // --- End of HTML Generator ---

  /// Calculates responsive height based on screen size if height is not provided
  double _calculateHeight(BuildContext context) {
    // If explicit height is provided, clamp it and return
    if (widget.height != null) {
      final minH = widget.minHeight ?? DynamicHeightTradingViewConstants.minHeight;
      final maxH = widget.maxHeight ?? DynamicHeightTradingViewConstants.maxHeight;
      return widget.height!.clamp(minH, maxH);
    }
    
    // If responsive height is disabled, use default
    if (!widget.useResponsiveHeight) {
      return DynamicHeightTradingViewConstants.defaultHeight;
    }
    
    // Calculate responsive height based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < DynamicHeightTradingViewConstants.smallScreenBreakpoint) {
      // Small screens (vertical layout)
      return DynamicHeightTradingViewConstants.smallScreenHeight;
    } else if (screenWidth < DynamicHeightTradingViewConstants.largeScreenBreakpoint) {
      // Medium screens (horizontal layout)
      return DynamicHeightTradingViewConstants.defaultHeight;
    } else if (screenWidth < DynamicHeightTradingViewConstants.extraLargeScreenBreakpoint) {
      // Large screens
      return DynamicHeightTradingViewConstants.largeScreenHeight;
    } else {
      // Extra large screens
      return DynamicHeightTradingViewConstants.extraLargeScreenHeight;
    }
  }

  @override
  void initState() {
    super.initState();
    // Set initial height - will be calculated properly in build method
    _webViewHeight = widget.height;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // print("WebView loading progress: $progress%");
            if (mounted && progress < 100 && !_isLoading) {
              // Optionally set loading state during navigation/reload
              // setState(() { _isLoading = true; });
            }
          },
          onPageStarted: (String url) {
            print("WebView page started loading: $url");
            if (mounted) {
              setState(() {
                _isLoading = true; // Show loading indicator on page start
              });
            }
          },
          onPageFinished: (String url) {
            print('WebView page finished loading: $url');
            // Small delay to allow JS (like ResizeObserver setup) to potentially run
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isLoading = false; // Hide loading indicator
                });
                
                // Inject minimal JavaScript to prevent window.open to TradingView website
                // NavigationDelegate handles most navigation blocking
                _controller.runJavaScript('''
                  (function() {
                    // Wait for TradingView widget to load
                    setTimeout(function() {
                      // Only prevent window.open to TradingView website pages
                      // This allows widget interactions while blocking external navigation
                      const originalOpen = window.open;
                      window.open = function(url, name, features) {
                        if (!url) return originalOpen.call(this, url, name, features);
                        const urlLower = url.toLowerCase();
                        
                        // Block opening TradingView web pages (symbol detail pages)
                        // But allow widget resource URLs
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
              }); // Stop loading on error
            }
            debugPrint('''Page resource error:
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

    // Initial load is handled in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWebViewContent();
  }

  void _loadWebViewContent() {
    final Brightness currentBrightness = Theme.of(context).brightness;
    print(
        "didChangeDependencies: Current theme brightness: $currentBrightness");

    // Load or reload only if the theme has changed since the last load
    if (currentBrightness != _currentLoadedBrightness) {
      print(
          "Theme changed or initial load. Reloading WebView. New theme: $currentBrightness");
      setState(() {
        _isLoading = true; // Show loading indicator during reload
      });

      final String colorTheme =
          currentBrightness == Brightness.dark ? 'dark' : 'light';
      final String htmlContent = _generateTradingViewHtml(colorTheme);
      final String contentBase64 =
          base64Encode(const Utf8Encoder().convert(htmlContent));
      final String dataUrl = 'data:text/html;base64,$contentBase64';

      _controller.loadRequest(Uri.parse(dataUrl)).then((_) {
        if (mounted) {
          _currentLoadedBrightness =
              currentBrightness; // Update the loaded theme state
          // Note: _isLoading will be set to false in onPageFinished
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          }); // Ensure loading stops on error
        }
        print("Error loading WebView content: $error");
      });
    } else {
      print("Theme hasn't changed. No reload needed.");
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
    _resizeTimer?.cancel();
    // Consider cleaning up the controller if webview_flutter requires it
    // _controller = null; // Or proper disposal if available
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the height to use
    final calculatedHeight = _calculateHeight(context);
    final effectiveHeight = _webViewHeight ?? calculatedHeight;
    final EdgeInsetsGeometry contentPadding =
        widget.contentPadding ?? DynamicHeightTradingViewConstants.contentPadding;
    
    // Use AnimatedSize for smoother height transitions
    return Visibility(
      visible: true,
      child: SizedBox(
        width: widget.width ?? double.infinity, // Ensure full width
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make column take minimum space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: contentPadding,
            child: Text(
              widget.title ?? "Market Indices",
              textAlign: TextAlign.start,
              style: DashboardTextStyles.titleSmall.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0A0A0A),
              ),
            ),
          ),
           const SizedBox(height: 14),
          AnimatedSize(
            duration: DynamicHeightTradingViewConstants.animationDuration,
            curve: Curves.easeInOut, // Animation curve
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
                final borderColor = isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
                
                return Container(
                  height: effectiveHeight.clamp(
                    widget.minHeight ?? DynamicHeightTradingViewConstants.minHeight,
                    widget.maxHeight ?? DynamicHeightTradingViewConstants.maxHeight,
                  ),
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: borderColor,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      // Use Stack to overlay loading indicator
                      children: [
                        // WebView content with overscan
                        Transform.scale(
                          scaleX: 1.011,
                          scaleY: 1.02,
                          child: Padding(
                            padding: contentPadding,
                            child: WebViewWidget(controller: _controller),
                          ),
                        ),
                        // Show loading indicator only when actually loading
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}
