import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/platform_capabilities.dart';
import 'package:musaffa_terminal/Components/windows_html_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async'; // Import for Timer

/// Widget height constants for market indices TradingView widget
class DynamicHeightTradingViewConstants {
  /// Default height for medium screens (horizontal layout)
  static const double defaultHeight = 380.0;

  /// Height for small screens (vertical layout)
  static const double smallScreenHeight = 340.0;

  /// Height for large screens
  static const double largeScreenHeight = 440.0;

  /// Minimum height for responsive sizing
  static const double minHeight = 420.0;

  /// Maximum height for responsive sizing
  static const double maxHeight = 520.0;

  /// Height for extra large screens
  static const double extraLargeScreenHeight = 480.0;
  
  /// Title text + spacing above the chart body in [DynamicHeightTradingView.build].
  static const double chromeHeight = 48.0;
  
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
  WebViewController? _controller;
  double? _webViewHeight; // State variable to hold the dynamic height
  bool _isLoading = true; // Track loading state (initial and theme changes)
  Brightness? _currentLoadedBrightness; // Track the theme loaded in WebView
  Timer? _resizeTimer; // Timer to debounce resize events

  // --- Function to Generate TradingView HTML ---
  String _generateTradingViewHtml(String colorTheme) {
    // Ensure width and height in the *script config* are 100%
    // Added ResizeObserver JavaScript
    final String pageBg = colorTheme == 'dark' ? '#14161A' : '#FFFFFF';
    return '''
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>TradingView Widget</title>        
        <style>
            /* Without an explicit scheme the WebView follows the macOS system
               appearance, so a system in Dark Mode paints the canvas and the
               scrollbars dark even while the app is on the light theme. */
            :root { color-scheme: $colorTheme; }
            /* The embedded iframe does not always cover the last few pixels of
               the page. An explicit background makes that remainder match the
               card instead of exposing the WebView's default canvas. */
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; background: $pageBg; font-family: Inter, system-ui, -apple-system, "Segoe UI", sans-serif; -webkit-user-select: none; user-select: none; }
            .tradingview-widget-container { height: 100%; width: 100%; overflow: hidden; background: $pageBg; }
            .tradingview-widget-container__widget { background: $pageBg; }
            /* display:block keeps the iframe off the text baseline, which
               otherwise leaves dead pixels under the widget. */
            iframe { width: 100%; height: 100%; border: 0; display: block; vertical-align: bottom; background: $pageBg; }
            
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
      "plotLineColorGrowing": "#059669",
      "plotLineColorFalling": "#DC2626",
      "belowLineFillColorGrowing": "rgba(5, 150, 105, 0.10)",
      "belowLineFillColorFalling": "rgba(220, 38, 38, 0.08)",
      "belowLineFillColorGrowingBottom": "rgba(5, 150, 105, 0)",
      "belowLineFillColorFallingBottom": "rgba(220, 38, 38, 0)",
      "gridLineColor": "rgba(238, 240, 243, 0)",
      "scaleFontColor": "rgba(107, 114, 128, 1)",
      "showSymbolLogo": true,
      "symbolActiveColor": "rgba(247, 248, 250, 1)",
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

    if (!PlatformCapabilities.isWebViewFlutterSupported) {
      _isLoading = false;
      return;
    }

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
                _controller?.runJavaScript('''
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
            // Allow ALL subresources (scripts, images, iframes) - needed for
            // widget functionality. Widget interactions happen within iframes.
            if (!request.isMainFrame) {
              return NavigationDecision.navigate;
            }

            final url = request.url.toLowerCase();
            if (url.startsWith('data:') || url == 'about:blank') {
              return NavigationDecision.navigate;
            }

            // Every remaining main-frame load would replace the widget with a
            // web page — a click on the TradingView logo, a symbol row, or any
            // external link. Blocking them all makes such clicks a no-op.
            debugPrint('Blocking main-frame navigation to ${request.url}');
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
    final controller = _controller;
    if (controller == null) return;

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

      controller.loadRequest(Uri.parse(dataUrl)).then((_) {
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
    
    // Use AnimatedSize for smoother height transitions
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Visibility(
      visible: true,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        child: Container(
          decoration: HomeUi.cardDecoration(isDark).copyWith(
            border: Border.all(color: HomeUi.borderLight(isDark), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget chartBody = AnimatedSize(
                duration: DynamicHeightTradingViewConstants.animationDuration,
                curve: Curves.easeInOut,
                child: Builder(
                  builder: (context) {
                    final bgColor = HomeUi.cardBg(isDark);

                    return SizedBox(
                      height: snapToDevicePixels(
                        context,
                        effectiveHeight.clamp(
                          widget.minHeight ??
                              DynamicHeightTradingViewConstants.minHeight,
                          widget.maxHeight ??
                              DynamicHeightTradingViewConstants.maxHeight,
                        ),
                      ),
                      width: double.infinity,
                      child: Stack(
                        children: [
                          AdaptiveHtmlWebView(
                            html: _generateTradingViewHtml(
                              isDark ? 'dark' : 'light',
                            ),
                            flutterController: _controller,
                            backgroundColor: bgColor,
                          ),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    );
                  },
                ),
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Text(
                      widget.title ?? "Market Indices",
                      textAlign: TextAlign.start,
                      style: HomeUi.cardTitle(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: HomeUi.borderLight(isDark),
                  ),
                  // Callers derive the body height by subtracting an estimated
                  // `chromeHeight` from the card height, so the request can be a
                  // fraction of a pixel taller than the space the title and
                  // divider actually leave. Letting the body shrink into the
                  // real remainder keeps it from overflowing the card.
                  if (constraints.hasBoundedHeight)
                    Flexible(child: chartBody)
                  else
                    chartBody,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
