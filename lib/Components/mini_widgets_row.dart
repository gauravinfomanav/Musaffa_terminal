import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'shimmer.dart';
import 'dart:convert';
import 'dart:async';

/// Widget height constants for market indices mini widgets
class MiniWidgetsRowConstants {
  /// Minimum height for responsive sizing (smallest screens)
  static const double minHeight = 140.0;

  /// Maximum height for responsive sizing (largest screens)
  static const double maxHeight = 280.0;

  static const double baseHeightPercentage = 0.11;

  static const double minHeightPercentage = 0.08;

  static const double maxHeightPercentage = 0.14;

  /// Gap between mini chart cards
  static const double widgetGap = 8.0;

  static const int chartCount = 5;

  static const int loadingDelayMs = 100;
}

class MiniWidgetsRow extends StatefulWidget {
  final double? height;
  
  const MiniWidgetsRow({
    super.key,
    this.height,
  });

  @override
  State<MiniWidgetsRow> createState() => _MiniWidgetsRowState();
}

class _MiniWidgetsRowState extends State<MiniWidgetsRow> 
    with AutomaticKeepAliveClientMixin {
  late WebViewController _controller;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;
  bool _isWebViewInitialized = false;

  @override
  bool get wantKeepAlive => true;

  // --- Function to Generate Mini Widgets HTML ---
  String _generateMiniWidgetsHtml(String colorTheme) {
    // App background color (for gaps between widgets)
    final appBgColor = colorTheme == 'dark' ? '#0F0F0F' : '#FAFAFA';
    // Widget background color (inside each widget box)
    final widgetBgColor = colorTheme == 'dark' ? '#2D2D2D' : '#FFFFFF';
    // Theme-aware border color (very light)
    final borderColor = colorTheme == 'dark' ? '#505050' : '#D1D5DB';
    
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Mini Widgets</title>
        <style>
            body, html { 
                margin: 0 !important; 
                padding: 0 !important; 
                height: 100% !important; 
                width: 100% !important; 
                overflow: hidden !important; 
                background: $appBgColor !important;
                background-color: $appBgColor !important;
                border: none !important; 
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important;
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                touch-action: none !important;
                overscroll-behavior: none !important;
            }
            .widgets-container { 
                display: flex !important; 
                gap: 0 !important; 
                height: 100% !important; 
                width: 100% !important; 
                background: $appBgColor !important;
                border: none !important;
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            .mini-widget { 
                flex: 1 !important; 
                height: 100% !important; 
                background: $widgetBgColor !important;
                border: none !important;
                border-width: 0 !important;
                box-shadow: inset 0 0 0 0.5px $borderColor !important;
                border-radius: 6px !important;
                outline: none !important;
                margin: 0 !important;
                padding: 0 !important;
                box-sizing: border-box !important;
                overflow: hidden !important;
            }
            .mini-widget:not(:last-child) {
                margin-right: ${MiniWidgetsRowConstants.widgetGap}px !important;
                box-sizing: border-box !important;
            }
            .mini-widget-wrapper {
                height: 100% !important;
                width: 100% !important;
                background: $widgetBgColor !important;
                display: flex !important;
                align-items: center !important;
                overflow: hidden !important;
                border-radius: 6px !important;
            }
            .tradingview-widget-container { 
                height: 100% !important; 
                width: 100% !important; 
                background: $widgetBgColor !important; 
                border: none !important;
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            .tradingview-widget-container__widget { 
                background: $widgetBgColor !important; 
                border: none !important;
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            iframe { 
                background: $widgetBgColor !important; 
                border: none !important;
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            [class*="tradingview"] { 
                background: $widgetBgColor !important; 
                border: none !important;
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            div[style*="background"] { 
                background: $widgetBgColor !important; 
                border: none !important;
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            * { 
                border: none !important; 
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important; 
            }
            
            /* Remove WebView borders and shadows */
            body, html, div, iframe, * { 
                border: none !important; 
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: none !important; 
                box-shadow: none !important;
                -webkit-box-shadow: none !important;
                -moz-box-shadow: none !important;
            }
            
            /* Force remove any default WebView styling */
            .widgets-container, .tradingview-widget-container {
                border: 0 !important;
                border-width: 0 !important;
                border-style: none !important;
                border-color: transparent !important;
                outline: 0 !important;
                box-shadow: none !important;
                -webkit-appearance: none !important;
                -moz-appearance: none !important;
                appearance: none !important;
                margin: 0 !important;
                padding: 0 !important;
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
            
            /* Disable all interactions and clicks */
            * { pointer-events: none !important; }
            body { pointer-events: none !important; }
            html { pointer-events: none !important; }
            a { pointer-events: none !important; }
            button { pointer-events: none !important; }
            iframe { pointer-events: none !important; }
            
            /* Apply border to each mini-widget (must be after general border removal rules) */
            div.mini-widget {
                border: none !important;
                border-width: 0 !important;
                box-shadow: inset 0 0 0 0.5px $borderColor !important;
                border-radius: 6px !important;
                overflow: hidden !important;
            }
        </style>
    </head>
    <body>
        <div class="widgets-container">
            <!-- US100 Widget -->
            <div class="mini-widget">
                <div class="mini-widget-wrapper">
                <div class="tradingview-widget-container">
                    <div class="tradingview-widget-container__widget"></div>
                    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                    {
                        "symbol": "CAPITALCOM:US100",
                        "chartOnly": false,
                        "dateRange": "12M",
                        "noTimeScale": false,
                        "colorTheme": "$colorTheme",
                        "isTransparent": false,
                        "locale": "en",
                        "width": "100%",
                        "autosize": true,
                        "height": "100%"
                    }
                    </script>
                </div>
                </div>
            </div>
            
            <!-- US500 Widget -->
            <div class="mini-widget">
                <div class="mini-widget-wrapper">
                <div class="tradingview-widget-container">
                    <div class="tradingview-widget-container__widget"></div>
                    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                    {
                        "symbol": "CAPITALCOM:US500",
                        "chartOnly": false,
                        "dateRange": "12M",
                        "noTimeScale": false,
                        "colorTheme": "$colorTheme",
                        "isTransparent": false,
                        "locale": "en",
                        "width": "100%",
                        "autosize": true,
                        "height": "100%"
                    }
                    </script>
                </div>
                </div>
            </div>
            
            <!-- NASDAQ Widget -->
            <div class="mini-widget">
                <div class="mini-widget-wrapper">
                <div class="tradingview-widget-container">
                    <div class="tradingview-widget-container__widget"></div>
                    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                    {
                        "symbol": "PEPPERSTONE:XAUUSD",
                        "chartOnly": false,
                        "dateRange": "12M",
                        "noTimeScale": false,
                        "colorTheme": "$colorTheme",
                        "isTransparent": false,
                        "locale": "en",
                        "width": "100%",
                        "autosize": true,
                        "height": "100%"
                    }
                    </script>
                </div>
                </div>
            </div>
            
            <!-- USTEC Widget -->
            <div class="mini-widget">
                <div class="mini-widget-wrapper">
                <div class="tradingview-widget-container">
                    <div class="tradingview-widget-container__widget"></div>
                    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                    {
                        "symbol": "ICMARKETS:USTEC",
                        "chartOnly": false,
                        "dateRange": "12M",
                        "noTimeScale": false,
                        "colorTheme": "$colorTheme",
                        "isTransparent": false,
                        "locale": "en",
                        "width": "100%",
                        "autosize": true,
                        "height": "100%"
                    }
                    </script>
                </div>
                </div>
            </div>

            <!-- Bitcoin Widget -->
            <div class="mini-widget">
                <div class="mini-widget-wrapper">
                <div class="tradingview-widget-container">
                    <div class="tradingview-widget-container__widget"></div>
                    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                    {
                        "symbol": "BITSTAMP:BTCUSD",
                        "chartOnly": false,
                        "dateRange": "12M",
                        "noTimeScale": false,
                        "colorTheme": "$colorTheme",
                        "isTransparent": false,
                        "locale": "en",
                        "width": "100%",
                        "autosize": true,
                        "height": "100%"
                    }
                    </script>
                </div>
                </div>
            </div>
            
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
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            Future.delayed(Duration(milliseconds: MiniWidgetsRowConstants.loadingDelayMs), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _isWebViewInitialized = true;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // Log error for debugging (can be enhanced with error UI)
              debugPrint('MiniWidgetsRow WebView error: ${error.description}');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow initial data URL load and TradingView URLs
            if (request.url.startsWith('data:text/html;base64') ||
                request.url.startsWith('https://s3.tradingview.com') ||
                request.url.startsWith('https://www.tradingview.com') ||
                request.url.startsWith('https://www.tradingview-widget.com')) {
              return NavigationDecision.navigate;
            }
           
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
      final String htmlContent = _generateMiniWidgetsHtml(colorTheme);
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
          debugPrint('MiniWidgetsRow load error: $error');
        }
      });
    }
  }

  @override
  void dispose() {
    // WebView will be automatically disposed by Flutter
    super.dispose();
  }

  /// Calculates responsive height based on screen size if height is not provided
  double _calculateHeight(BuildContext context) {
    if (widget.height != null) {
      return widget.height!.clamp(
        MiniWidgetsRowConstants.minHeight,
        MiniWidgetsRowConstants.maxHeight,
      );
    }
    
    // Truly responsive height based on screen dimensions
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Calculate height as percentage of screen height for true responsiveness
    double heightPercentage = MiniWidgetsRowConstants.baseHeightPercentage;
    
    // Adjust percentage based on screen width for better proportions
    if (screenWidth < 800) {
      // Small screens: use slightly smaller percentage
      heightPercentage = MiniWidgetsRowConstants.minHeightPercentage;
    } else if (screenWidth < 1400) {
      // Medium screens: use base percentage
      heightPercentage = MiniWidgetsRowConstants.baseHeightPercentage;
    } else if (screenWidth < 2000) {
      // Large screens: use slightly larger percentage
      heightPercentage = MiniWidgetsRowConstants.baseHeightPercentage * 1.2;
    } else {
      // Extra large screens: use maximum percentage
      heightPercentage = MiniWidgetsRowConstants.maxHeightPercentage;
    }
    
    // Calculate responsive height
    double calculatedHeight = screenHeight * heightPercentage;
    
    // Clamp to min/max constraints
    return calculatedHeight.clamp(
      MiniWidgetsRowConstants.minHeight,
      MiniWidgetsRowConstants.maxHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode 
        ? const Color(0xFF505050) 
        : const Color.fromARGB(255, 235, 235, 235); // Very light border
    // App background color (for container/gaps between widgets)
    final appBackgroundColor = isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final widgetHeight = _calculateHeight(context);
    
    // Get screen width for explicit sizing (prevents layout ambiguity)
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: Container(
        height: widgetHeight,
        width: screenWidth,
        color: appBackgroundColor,
        child: _isLoading
            ? Row(
                children: List.generate(MiniWidgetsRowConstants.chartCount, (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < MiniWidgetsRowConstants.chartCount - 1
                          ? MiniWidgetsRowConstants.widgetGap
                          : 0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 0.1),
                    ),
                    child: ShimmerWidgets.box(
                      width: double.infinity,
                      height: widgetHeight,
                      baseColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      highlightColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[100]!,
                    ),
                  ),
                )),
              )
            : Transform.scale(
                scaleX: 1.01,   // No horizontal scaling (left/right)
                scaleY: 1.011, // Vertical scaling (top/bottom only)
                child: WebViewWidget(controller: _controller),
              ),
      ),
    );
  }
}
