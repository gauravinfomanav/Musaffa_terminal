import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:musaffa_terminal/utils/platform_capabilities.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/Components/windows_html_webview.dart';
import 'shimmer.dart';
import 'dart:convert';
import 'dart:async';

/// Widget height constants for market indices mini widgets
class MiniWidgetsRowConstants {
  /// Minimum height for responsive sizing (smallest screens)
  static const double minHeight = 140.0;
  static const double maxHeight = 260.0;
  static const double baseHeightPercentage = 0.105;
  static const double minHeightPercentage = 0.085;
  static const double maxHeightPercentage = 0.135;
  static const double widgetGap = 12.0;

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
  WebViewController? _controller;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;
  bool _isWebViewInitialized = false;

  @override
  bool get wantKeepAlive => true;

  // --- Function to Generate Mini Widgets HTML ---
  String _generateMiniWidgetsHtml(String colorTheme) {
    // App background color (for gaps between widgets)
    final appBgColor = colorTheme == 'dark' ? '#0C0D0F' : '#F5F6F8';
    final widgetBgColor = colorTheme == 'dark' ? '#14161A' : '#FFFFFF';
    final borderColor = colorTheme == 'dark' ? '#2A2E34' : '#E8EAEE';
    final hoverBorder = colorTheme == 'dark' ? '#3A4048' : '#D9DDE3';
    final shadow = colorTheme == 'dark'
        ? '0 1px 0 rgba(255,255,255,0.04)'
        : 'none';
    final hoverShadow = colorTheme == 'dark'
        ? '0 8px 28px rgba(0,0,0,0.28)'
        : '0 10px 28px rgba(15,23,42,0.045)';
    const gap = MiniWidgetsRowConstants.widgetGap;

    String tvConfig(String symbol) => '''
                    {
                        "symbol": "$symbol",
                        "chartOnly": false,
                        "dateRange": "12M",
                        "noTimeScale": true,
                        "colorTheme": "$colorTheme",
                        "isTransparent": true,
                        "locale": "en",
                        "width": "100%",
                        "autosize": true,
                        "height": "100%"
                    }''';
    
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
                gap: ${gap}px !important; 
                height: 100% !important; 
                width: 100% !important;
                background: $appBgColor !important;
                margin: 0 !important;
                padding: 0 !important;
                box-sizing: border-box !important;
                align-items: stretch !important;
            }
            .mini-widget { 
                flex: 1 1 0 !important;
                min-width: 0 !important;
                height: 100% !important; 
                background: $widgetBgColor !important;
                border: 1px solid $borderColor !important;
                border-radius: 10px !important;
                box-shadow: $shadow !important;
                margin: 0 !important;
                padding: 0 !important;
                box-sizing: border-box !important;
                overflow: hidden !important;
                transition: box-shadow 180ms ease, border-color 180ms ease !important;
            }
            .mini-widget:hover {
                border-color: $hoverBorder !important;
                box-shadow: $hoverShadow !important;
            }
            .mini-widget-wrapper {
                height: 100% !important;
                width: 100% !important;
                background: $widgetBgColor !important;
                display: flex !important;
                align-items: stretch !important;
                overflow: hidden !important;
                border-radius: 10px !important;
                padding: 4px 8px 2px !important;
                box-sizing: border-box !important;
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
            * { -webkit-tap-highlight-color: transparent !important; }
            * { user-select: none !important; }
            html, body { overflow: hidden !important; }
            .widgets-container { overflow: hidden !important; }
            .mini-widget, .mini-widget-wrapper, .tradingview-widget-container {
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
                    ${tvConfig("CAPITALCOM:US100")}
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
                    ${tvConfig("CAPITALCOM:US500")}
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
                    ${tvConfig("PEPPERSTONE:XAUUSD")}
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
                    ${tvConfig("ICMARKETS:USTEC")}
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
                    ${tvConfig("BITSTAMP:BTCUSD")}
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
    if (!PlatformCapabilities.isWebViewFlutterSupported) {
      _isLoading = false;
      return;
    }

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
    final controller = _controller;
    if (controller == null) return;

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

      controller.loadRequest(Uri.parse(dataUrl)).then((_) {
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
    final appBackgroundColor = isDarkMode ? const Color(0xFF0C0D0F) : const Color(0xFFF5F6F8);
    final widgetHeight = _calculateHeight(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        height: widgetHeight,
        width: double.infinity,
        child: _isLoading
            ? Row(
                children: List.generate(MiniWidgetsRowConstants.chartCount, (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < MiniWidgetsRowConstants.chartCount - 1
                          ? MiniWidgetsRowConstants.widgetGap
                          : 0,
                    ),
                    decoration: HomeUi.cardDecoration(isDarkMode),
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
            : AdaptiveHtmlWebView(
                  html: _generateMiniWidgetsHtml(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'dark'
                        : 'light',
                  ),
                  flutterController: _controller,
                  backgroundColor: appBackgroundColor,
                ),
      ),
    );
  }
}
