
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class TradingViewChart extends StatefulWidget {
  final double? height;
  final double? width;
  final String? symbol;

  const TradingViewChart({
    super.key,
    this.height = 600,
    this.width,
    this.symbol,
  });

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late WebViewController _controller;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;

  String _generateTradingViewHtml(String colorTheme) {
    return '''
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>TradingView Widget</title>        
        <style>
            body, html { 
                margin: 0; 
                padding: 0; 
                height: 100%; 
                width: 100%; 
                overflow: hidden; 
                background-color: ${colorTheme == 'dark' ? '#1A1A1A' : '#FFFFFF'};
            }
            .tradingview-widget-container { 
                height: 100%; 
                width: 100%; 
            }
        </style>
    </head>
    <body>
        <div class="tradingview-widget-container">
          <div class="tradingview-widget-container__widget"></div>
          
          <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-market-overview.js" async>
          {
            "title": "Market Overview",
            "tabs": [
              {
                "title": "US Markets",
                "symbols": [
                  {
                    "s": "FOREXCOM:SPXUSD",
                    "d": "S&P 500"
                  },
                  {
                    "s": "FOREXCOM:NSXUSD", 
                    "d": "NASDAQ 100"
                  },
                  {
                    "s": "FOREXCOM:DJI",
                    "d": "Dow Jones"
                  },
                  {
                    "s": "FOREXCOM:RUTUSD",
                    "d": "Russell 2000"
                  }
                ]
              },
              {
                "title": "Sectors",
                "symbols": [
                  {
                    "s": "AMEX:XLK",
                    "d": "Technology"
                  },
                  {
                    "s": "AMEX:XLF",
                    "d": "Financials"
                  },
                  {
                    "s": "AMEX:XLE",
                    "d": "Energy"
                  },
                  {
                    "s": "AMEX:XLV",
                    "d": "Healthcare"
                  },
                  {
                    "s": "AMEX:XLY",
                    "d": "Consumer Discretionary"
                  }
                ]
              },
              {
                "title": "Global",
                "symbols": [
                  {
                    "s": "INDEX:SX5E",
                    "d": "Euro Stoxx 50"
                  },
                  {
                    "s": "FOREXCOM:UKXGBP",
                    "d": "FTSE 100"
                  },
                  {
                    "s": "INDEX:NKY",
                    "d": "Nikkei 225"
                  },
                  {
                    "s": "INDEX:HSI",
                    "d": "Hang Seng"
                  }
                ]
              }
            ],
            "width": "100%",
            "height": "100%",
            "showChart": true,
            "showFloatingTooltip": true,
            "locale": "en",
            "plotLineColorGrowing": "#10B981",
            "plotLineColorFalling": "#EF4444",
            "belowLineFillColorGrowing": "rgba(16, 185, 129, 0.12)",
            "belowLineFillColorFalling": "rgba(239, 68, 68, 0.12)",
            "belowLineFillColorGrowingBottom": "rgba(16, 185, 129, 0)",
            "belowLineFillColorFallingBottom": "rgba(239, 68, 68, 0)",
            "gridLineColor": "rgba(240, 243, 250, 0)",
            "scaleFontColor": "rgba(120, 123, 134, 1)",
            "showSymbolLogo": true,
            "symbolActiveColor": "rgba(79, 70, 229, 0.12)",
            "colorTheme": "$colorTheme"
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted && progress < 100 && !_isLoading) {
              setState(() => _isLoading = true);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (!request.url.startsWith('data:text/html;base64')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
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

    if (currentBrightness != _currentLoadedBrightness) {
      setState(() => _isLoading = true);

      final String colorTheme = currentBrightness == Brightness.dark ? 'dark' : 'light';
      final String htmlContent = _generateTradingViewHtml(colorTheme);
      final String contentBase64 = base64Encode(const Utf8Encoder().convert(htmlContent));
      final String dataUrl = 'data:text/html;base64,$contentBase64';

      _controller.loadRequest(Uri.parse(dataUrl)).then((_) {
        if (mounted) {
          _currentLoadedBrightness = currentBrightness;
        }
      }).catchError((error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        debugPrint("Error loading WebView: $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
