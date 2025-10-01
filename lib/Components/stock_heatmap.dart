import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';

class StockHeatmap extends StatefulWidget {
  final double initialHeight;

  const StockHeatmap({
    super.key,
    this.initialHeight = 600,
  });

  @override
  State<StockHeatmap> createState() => _StockHeatmapState();
}

class _StockHeatmapState extends State<StockHeatmap> {
  late WebViewController _controller;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;
  double _webViewHeight = 600;

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
        
        <script>
            // Prevent all clicks and navigation while allowing zoom/pan
            document.addEventListener('DOMContentLoaded', function() {
                // Prevent all click events
                document.addEventListener('click', function(event) {
                    event.preventDefault();
                    event.stopPropagation();
                    event.stopImmediatePropagation();
                    return false;
                }, true);
                
                // Prevent context menu
                document.addEventListener('contextmenu', function(event) {
                    event.preventDefault();
                    event.stopPropagation();
                    return false;
                }, true);
                
                // Override window.open to prevent popups
                window.open = function() {
                    return null;
                };
                
                // Prevent all link clicks
                document.addEventListener('click', function(event) {
                    const target = event.target;
                    if (target.tagName === 'A' || target.closest('a')) {
                        event.preventDefault();
                        event.stopPropagation();
                        event.stopImmediatePropagation();
                        return false;
                    }
                }, true);
                
                // Prevent all button clicks
                document.addEventListener('click', function(event) {
                    const target = event.target;
                    if (target.tagName === 'BUTTON' || target.closest('button')) {
                        event.preventDefault();
                        event.stopPropagation();
                        event.stopImmediatePropagation();
                        return false;
                    }
                }, true);
                
                // Disable all links after they load
                setTimeout(function() {
                    const links = document.querySelectorAll('a');
                    links.forEach(link => {
                        link.style.pointerEvents = 'none';
                        link.onclick = function(event) {
                            event.preventDefault();
                            event.stopPropagation();
                            return false;
                        };
                    });
                }, 1000);
            });
        </script>
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
            print("Stock Heatmap WebView page started loading: $url");
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            print('Stock Heatmap WebView page finished loading: $url');
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
            debugPrint('''Stock Heatmap Page resource error:
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
    print("Stock Heatmap: Current theme brightness: $currentBrightness");

    if (currentBrightness != _currentLoadedBrightness) {
      print("Stock Heatmap: Theme changed or initial load. Reloading WebView. New theme: $currentBrightness");
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
      print("Stock Heatmap: Theme hasn't changed. No reload needed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Stock Heatmap",
            textAlign: TextAlign.start,
            style: Theme.of(context).brightness == Brightness.dark
                ? const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE5E7EB),
                  )
                : const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF374151),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // WebView
        Expanded(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent, width: 0),
              color: Colors.transparent,
            ),
            clipBehavior: Clip.hardEdge,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.zero,
                    clipBehavior: Clip.hardEdge,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent, width: 0),
                      ),
                      child: WebViewWidget(controller: _controller),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
