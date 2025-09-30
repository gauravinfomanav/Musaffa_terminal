import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async'; // Import for Timer

// Define the JavaScript channel name (must match in JS code)
const String _kJsChannelName = 'ResizeObserver';

class DynamicHeightTradingView extends StatefulWidget {
  final double? initialHeight; // Optional initial height before calculation
  final double? width;

  const DynamicHeightTradingView({
    super.key,
    this.initialHeight = 700, // Provide a reasonable default initial height
    this.width,
  });

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

  @override
  void initState() {
    super.initState();
    print("initState: Setting initial height to ${widget.initialHeight}");
    _webViewHeight = widget.initialHeight; // Set initial height

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
                // Trigger an initial height check from JS *after* page finished
                // _controller.runJavaScript(
                //   'setTimeout(() => { checkHeight(); }, 100);' // Use the fallback check function
                // );
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
      // If it wasn't loading before and theme didn't change, ensure loading indicator is off
      // (Handles cases where didChangeDependencies might be called for other reasons)
      if (_isLoading && _webViewHeight != null && _webViewHeight! > 0) {
        // If we have a height and theme is same, likely finished loading previously
        // setState(() => _isLoading = false);
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
    // Use AnimatedSize for smoother height transitions
    return Visibility(
      visible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make column take minimum space
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Market Indices",
              textAlign: TextAlign.start,
              style: DashboardTextStyles.titleSmall,
            ),
          ),
          const SizedBox(height: 26),
          AnimatedSize(
            duration: const Duration(milliseconds: 250), // Animation duration
            curve: Curves.easeInOut, // Animation curve
            child: SizedBox(
              // Use the calculated height, or the initial/default if not yet calculated/loading
              // Use a minimum height while loading after initial build to prevent collapse
              height: _webViewHeight ?? (widget.initialHeight ?? 200),
              width: widget.width ??
                  double.infinity, // Use provided width or expand
              child: Stack(
                // Use Stack to overlay loading indicator
                children: [
                  // Hide WebView visually while loading *and* height is not determined yet
                  // Or just let it load underneath the indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: WebViewWidget(controller: _controller),
                  ),
                  // Show loading indicator centered
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
