import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'shimmer.dart';
import 'dart:convert';
import 'dart:async';

class MiniWidgetsRow extends StatefulWidget {
  const MiniWidgetsRow({super.key});

  @override
  State<MiniWidgetsRow> createState() => _MiniWidgetsRowState();
}

class _MiniWidgetsRowState extends State<MiniWidgetsRow> {
  late WebViewController _controller;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;

  // --- Function to Generate Mini Widgets HTML ---
  String _generateMiniWidgetsHtml(String colorTheme) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Mini Widgets</title>
        <style>
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; background: #FFFFFF; border: none !important; outline: none !important; }
            .widgets-container { 
                display: flex; 
                gap: 8px; 
                height: 100%; 
                width: 100%; 
                background: #FFFFFF;
                border: none !important;
                outline: none !important;
            }
            .mini-widget { 
                flex: 1; 
                height: 100%; 
                background: #FFFFFF;
                border: none !important;
                outline: none !important;
            }
            .tradingview-widget-container { 
                height: 100%; 
                width: 100%; 
                background: #FFFFFF !important; 
                border: none !important;
                outline: none !important;
            }
            .tradingview-widget-container__widget { 
                background: #FFFFFF !important; 
                border: none !important;
                outline: none !important;
            }
            iframe { 
                background: #FFFFFF !important; 
                border: none !important;
                outline: none !important;
            }
            [class*="tradingview"] { 
                background: #FFFFFF !important; 
                border: none !important;
                outline: none !important;
            }
            div[style*="background"] { 
                background: #FFFFFF !important; 
                border: none !important;
                outline: none !important;
            }
            * { border: none !important; outline: none !important; }
            
            /* Remove WebView borders and shadows */
            body, html, div, iframe, * { 
                border: none !important; 
                outline: none !important; 
                box-shadow: none !important;
                -webkit-box-shadow: none !important;
                -moz-box-shadow: none !important;
            }
            
            /* Force remove any default WebView styling */
            .widgets-container, .mini-widget, .tradingview-widget-container {
                border: 0 !important;
                outline: 0 !important;
                box-shadow: none !important;
                -webkit-appearance: none !important;
                -moz-appearance: none !important;
                appearance: none !important;
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
        </style>
    </head>
    <body>
        <div class="widgets-container">
            <!-- US100 Widget -->
            <div class="mini-widget">
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
            
            <!-- US500 Widget -->
            <div class="mini-widget">
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
            
            <!-- NASDAQ Widget -->
            <div class="mini-widget">
                <div class="tradingview-widget-container">
                    <div class="tradingview-widget-container__widget"></div>
                    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
                    {
                        "symbol": "NASDAQ:NDX",
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
            
            <!-- USTEC Widget -->
            <div class="mini-widget">
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
    </body>
    </html>
    ''';
  }

  @override
  void initState() {
    super.initState();
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
            print("Mini Widgets WebView page started loading: $url");
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            print('Mini Widgets WebView page finished loading: $url');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            debugPrint('''Mini Widgets Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}''');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow initial data URL load and TradingView URLs
            if (request.url.startsWith('data:text/html;base64') ||
                request.url.startsWith('https://s3.tradingview.com') ||
                request.url.startsWith('https://www.tradingview.com') ||
                request.url.startsWith('https://www.tradingview-widget.com')) {
              return NavigationDecision.navigate;
            }
            print('Blocking navigation to ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWebViewContent();
  }

  void _loadWebViewContent() {
    final Brightness currentBrightness = Theme.of(context).brightness;
    print("Mini Widgets: Current theme brightness: $currentBrightness");

    if (currentBrightness != _currentLoadedBrightness) {
      print("Mini Widgets: Theme changed or initial load. Reloading WebView. New theme: $currentBrightness");
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
        }
        print("Error loading Mini Widgets WebView content: $error");
      });
    } else {
      print("Mini Widgets: Theme hasn't changed. No reload needed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.transparent, width: 0),
        color: Colors.transparent,
      ),
      clipBehavior: Clip.hardEdge,
      child: _isLoading
          ? Row(
              children: List.generate(4, (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: ShimmerWidgets.box(
                    width: double.infinity,
                    height: 180,
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
          : ClipRRect(
              borderRadius: BorderRadius.zero,
              clipBehavior: Clip.hardEdge,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent, width: 0),
                ),
                child: WebViewWidget(controller: _controller),
              ),
            ),
    );
  }
}
