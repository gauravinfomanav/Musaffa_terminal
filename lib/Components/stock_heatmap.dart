import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
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
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 0.0);
  
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
  /// Whether to show the header/title above the heatmap. Defaults to true.
  final bool showHeader;

  const StockHeatmap({
    super.key,
    this.height,
    this.width,
    this.useResponsiveHeight = true,
    this.minHeight,
    this.maxHeight,
    this.title,
    this.showHeader = true,
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
  
  // Simplified: no responsive/cached calculations
  Timer? _heartbeatTimer;

  @override
  bool get wantKeepAlive => true;

  /// Returns explicit height if set, otherwise a simple default height.
  double _calculateHeight(BuildContext context) {
    final minH = widget.minHeight ?? StockHeatmapConstants.minHeight;
    final maxH = widget.maxHeight ?? StockHeatmapConstants.maxHeight;
    final h = widget.height ?? StockHeatmapConstants.defaultHeight;
    return h.clamp(minH, maxH);
  }

  // --- Function to Generate Stock Heatmap HTML ---
  String _generateStockHeatmapHtml(String colorTheme) {
    final backgroundColor = colorTheme == 'dark' ? '#1A1A1A' : '#FFFFFF';
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Stock Heatmap</title>
        <style>
          html, body { margin:0; padding:0; height:100%; width:100%; background:$backgroundColor; }
          .tradingview-widget-container { height:100%; width:100%; background:$backgroundColor; }
          .tradingview-widget-container__widget { height:100%; width:100%; }
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
          "colorTheme": "$colorTheme",
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
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            Future.delayed(const Duration(milliseconds: 300), () {
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
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final calculatedHeight = _calculateHeight(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
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
          ],
          // WebView with simple fixed height and full width, tappable to open full screen
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StockHeatmapFullScreenPage(),
                ),
              );
            },
            child: SizedBox(
              height: calculatedHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: StockHeatmapConstants.contentPadding,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
  }
}

/// Full-screen page for the Stock Heatmap, no parent scrolling
class StockHeatmapFullScreenPage extends StatefulWidget {
  const StockHeatmapFullScreenPage({super.key});

  @override
  State<StockHeatmapFullScreenPage> createState() => _StockHeatmapFullScreenPageState();
}

class _StockHeatmapFullScreenPageState extends State<StockHeatmapFullScreenPage> {
  bool _isWatchlistOpen = false;

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F1115) : Colors.white,
      body: GestureDetector(
        onTap: () {
          if (_isWatchlistOpen) {
            setState(() {
              _isWatchlistOpen = false;
            });
          }
        },
        child: Stack(
        children: [
          Column(
            children: [
              HomeTabBar(
                showBackButton: true,
                isWatchlistOpen: _isWatchlistOpen,
                onWatchlistToggle: _toggleWatchlist,
                onThemeToggle: () {
                  final currentTheme = Theme.of(context).brightness;
                  Get.changeThemeMode(
                    currentTheme == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              ),
              // Heatmap fills remaining height below the tab bar
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: constraints.maxHeight,
                      width: double.infinity,
                      child: StockHeatmap(
                        useResponsiveHeight: false,
                        height: constraints.maxHeight,
                        minHeight: 0,
                        maxHeight: constraints.maxHeight,
                        showHeader: false,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Watchlist sidebar overlay
          if (_isWatchlistOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleWatchlist,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Row(
                    children: [
                      Expanded(child: Container()),
                      GestureDetector(
                        onTap: () {},
                        child: WatchlistSidebar(
                          isDarkMode: isDarkMode,
                          onClose: _toggleWatchlist,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  // No custom sidebar builder needed; using shared WatchlistSidebar for consistency
}
