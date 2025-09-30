import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';

class DynamicHeightMarketQuotes extends StatefulWidget {
  final double? initialHeight;
  final double? width;

  const DynamicHeightMarketQuotes({
    super.key,
    this.initialHeight = 800,
    this.width,
  });

  @override
  State<DynamicHeightMarketQuotes> createState() =>
      _DynamicHeightMarketQuotesState();
}

class _DynamicHeightMarketQuotesState extends State<DynamicHeightMarketQuotes> {
  late WebViewController _controller;
  double? _webViewHeight;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;
  Timer? _resizeTimer;

  // --- Function to Generate TradingView Market Quotes HTML ---
  String _generateTradingViewHtml(String colorTheme) {
    // Read the HTML file and replace the color theme
    String htmlContent = '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>TradingView Market Quotes</title>
        <style>
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; background: #FFFFFF; }
            .tradingview-widget-container { height: 100%; width: 100%; background: #FFFFFF !important; }
            .tradingview-widget-container__widget { background: #FFFFFF !important; }
            iframe { background: #FFFFFF !important; }
            [class*="tradingview"] { background: #FFFFFF !important; }
            div[style*="background"] { background: #FFFFFF !important; }
            
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
    <!-- TradingView Widget BEGIN -->
        <div class="tradingview-widget-container">
        <div class="tradingview-widget-container__widget"></div>
        <script
                type="text/javascript"
                src="https://s3.tradingview.com/external-embedding/embed-widget-market-quotes.js"
                async
        >
            {
          "colorTheme": "$colorTheme",
          "locale": "en",
          "largeChartUrl": "",
          "isTransparent": false,
          "showSymbolLogo": true,
          "backgroundColor": "#FFFFFF",
          "support_host": "https://www.tradingview.com",
          "width": "100%",
          "height": "100%",
          "symbolsGroups": [
            {
              "name": "Indices",
              "symbols": [
                {
                  "name": "FOREXCOM:SPXUSD",
                  "displayName": "S&P 500 Index"
                },
                {
                  "name": "FOREXCOM:NSXUSD",
                  "displayName": "US 100 Cash CFD"
                },
                {
                  "name": "FOREXCOM:DJI",
                  "displayName": "Dow Jones Industrial Average Index"
                },
                {
                  "name": "INDEX:NKY",
                  "displayName": "Japan 225"
                },
                {
                  "name": "INDEX:DEU40",
                  "displayName": "DAX Index"
                },
                {
                  "name": "FOREXCOM:UKXGBP",
                  "displayName": "FTSE 100 Index"
                }
              ]
            },
            {
              "name": "Futures",
              "symbols": [
                {
                  "name": "BMFBOVESPA:ISP1!",
                  "displayName": "S&P 500"
                },
                {
                  "name": "BMFBOVESPA:EUR1!",
                  "displayName": "Euro"
                },
                {
                  "name": "CMCMARKETS:GOLD",
                  "displayName": "Gold"
                },
                {
                  "name": "PYTH:WTI3!",
                  "displayName": "WTI Crude Oil"
                },
                {
                  "name": "BMFBOVESPA:CCM1!",
                  "displayName": "Corn"
                }
              ]
            },
            {
              "name": "Bonds",
              "symbols": [
                {
                  "name": "EUREX:FGBL1!",
                  "displayName": "Euro Bund"
                },
                {
                  "name": "EUREX:FBTP1!",
                  "displayName": "Euro BTP"
                },
                {
                  "name": "EUREX:FGBM1!",
                  "displayName": "Euro BOBL"
                }
              ]
            },
            {
              "name": "Forex",
              "symbols": [
                {
                  "name": "FX:EURUSD",
                  "displayName": "EUR to USD"
                },
                {
                  "name": "FX:GBPUSD",
                  "displayName": "GBP to USD"
                },
                {
                  "name": "FX:USDJPY",
                  "displayName": "USD to JPY"
                },
                {
                  "name": "FX:USDCHF",
                  "displayName": "USD to CHF"
                },
                {
                  "name": "FX:AUDUSD",
                  "displayName": "AUD to USD"
                },
                {
                  "name": "FX:USDCAD",
                  "displayName": "USD to CAD"
                }
              ]
            }
          ]
        }
        </script>
    </div>
    <!-- TradingView Widget END -->

    <!-- JavaScript to send height back to Flutter -->
    <script type="text/javascript">
        // Ensure this channel name matches the one in Flutter
        const channelName = 'ResizeObserver';

        // Function to send height
        function sendHeight() {
          // Wait for TradingView widget to load completely
          setTimeout(() => {
            // Try to get the actual widget height
            const widgetContainer = document.querySelector('.tradingview-widget-container');
            const widget = document.querySelector('.tradingview-widget-container__widget');
            
            let height = 0;
            
            if (widget && widget.offsetHeight > 0) {
              // Use the actual widget height
              height = widget.offsetHeight;
            } else if (widgetContainer && widgetContainer.offsetHeight > 0) {
              // Fallback to container height
              height = widgetContainer.offsetHeight;
            } else {
              // Final fallback to body height
              height = document.body.scrollHeight;
            }
            
            // Add some padding to ensure no clipping
            height = Math.max(height + 20, 400); // Minimum 400px
            
            if (window[channelName] && typeof window[channelName].postMessage === 'function') {
              // Send the height as a string
              window[channelName].postMessage(height.toString());
              console.log('Sent dynamic height: ' + height);
            } else {
               console.error('Flutter JavaScript channel not found: ' + channelName);
            }
          }, 1000); // Wait 1 second for widget to fully load
        }

        // Fallback for older browsers: Send on load and periodically
        console.warn('ResizeObserver not supported. Falling back to onload/setTimeout.');
        window.onload = () => {
          console.log('Fallback: window.onload triggered');
          sendHeight();
          // Optionally, send periodically if content might change size later
          setTimeout(sendHeight, 1500);
          setTimeout(sendHeight, 3500);
        };
         // Ensure sendHeight is called even if onload already fired
         if (document.readyState === 'complete') {
            console.log('Fallback: Document already complete, calling sendHeight');
            sendHeight();
            setTimeout(sendHeight, 1500);
            setTimeout(sendHeight, 3500);
         }
    </script>
    </body>
    </html>
    ''';
    return htmlContent;
  }

  @override
  void initState() {
    super.initState();
    print("initState: Setting initial height to ${widget.initialHeight}");
    _webViewHeight = widget.initialHeight;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ResizeObserver',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final height = double.tryParse(message.message);
            if (height != null && height > 0 && mounted) {
              setState(() {
                _webViewHeight = height;
                print('Received dynamic height: $height');
              });
            }
          } catch (e) {
            print('Error parsing height: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted && progress < 100 && !_isLoading) {
              // Optionally set loading state during navigation/reload
            }
          },
          onPageStarted: (String url) {
            print("WebView page started loading: $url");
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            print('WebView page finished loading: $url');
            Future.delayed(const Duration(milliseconds: 300), () {
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
            debugPrint('''Page resource error:
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
    print("didChangeDependencies: Current theme brightness: $currentBrightness");

    if (currentBrightness != _currentLoadedBrightness) {
      print("Theme changed or initial load. Reloading WebView. New theme: $currentBrightness");
      setState(() {
        _isLoading = true;
      });

      final String colorTheme =
          currentBrightness == Brightness.dark ? 'dark' : 'light';
      final String htmlContent = _generateTradingViewHtml(colorTheme);
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
        print("Error loading WebView content: $error");
      });
    } else {
      print("Theme hasn't changed. No reload needed.");
    }
  }

  @override
  void dispose() {
    _resizeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Text(
              "Market Quotes",
              textAlign: TextAlign.start,
              style: DashboardTextStyles.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: _webViewHeight ?? (widget.initialHeight ?? 200),
              width: widget.width ?? double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading ||
                      _webViewHeight == null ||
                      _webViewHeight! <= 0)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
