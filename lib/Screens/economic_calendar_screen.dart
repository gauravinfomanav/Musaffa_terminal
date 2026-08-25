import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/windows_html_webview.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/platform_capabilities.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Full-screen TradingView Economic Calendar (Events) widget.
///
/// Follows the same AdaptiveHtmlWebView + data-URL pattern as stock heatmaps.
class EconomicCalendarScreen extends StatefulWidget {
  const EconomicCalendarScreen({super.key});

  @override
  State<EconomicCalendarScreen> createState() => _EconomicCalendarScreenState();
}

class _EconomicCalendarScreenState extends State<EconomicCalendarScreen> {
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();

  WebViewController? _controller;
  bool _isLoading = true;
  Brightness? _currentLoadedBrightness;
  bool _isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>()
          .setActive(SidebarNavItem.economicCalendar);
    }
    _initializeWebView();
  }

  String _generateEconomicCalendarHtml(String colorTheme) {
    // Match HomeUi.cardBg so the WebView's outer chrome (letterboxing while
    // the widget loads, scrollbar track, etc.) blends with the app's card.
    final String backgroundColor =
        colorTheme == 'dark' ? '#14161A' : '#FFFFFF';
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Economic Calendar</title>
  <style>
    /* Pin the scheme to the app theme; otherwise the WebView follows the
       macOS system appearance and paints uncovered pixels and scrollbars
       dark while the app is on the light theme. */
    :root { color-scheme: $colorTheme; }
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      width: 100%;
      background: $backgroundColor;
      overflow: hidden;
    }
    .tradingview-widget-container,
    .tradingview-widget-container__widget {
      height: 100%;
      width: 100%;
      background: $backgroundColor;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: 0;
      display: block;
    }
  </style>
</head>
<body>
  <div class="tradingview-widget-container">
    <div class="tradingview-widget-container__widget"></div>
    <script type="text/javascript"
      src="https://s3.tradingview.com/external-embedding/embed-widget-events.js"
      async>
    {
      "colorTheme": "$colorTheme",
      "isTransparent": false,
      "locale": "en",
      "countryFilter": "",
      "importanceFilter": "-1,0,1",
      "width": "100%",
      "height": "100%"
    }
    </script>
  </div>
</body>
</html>
''';
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
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
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
              setState(() => _isLoading = false);
            }
            debugPrint('''Economic Calendar resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}''');
          },
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url.toLowerCase();

            if (request.url.startsWith('data:text/html;base64')) {
              return NavigationDecision.navigate;
            }

            // Widget scripts / iframes must load.
            if (!request.isMainFrame) {
              return NavigationDecision.navigate;
            }

            if (url.contains('tradingview.com') ||
                url.contains('tradingview-widget.com')) {
              if (url.contains('/symbols/') ||
                  url.contains('/chart/') ||
                  url.contains('/screener/') ||
                  url.contains('/markets/') ||
                  url.contains('/ideas/') ||
                  url.contains('/publish/') ||
                  url.contains('/economic-calendar/') ||
                  (url.contains('www.tradingview.com') &&
                      !url.contains('s3.tradingview.com')) ||
                  (url.contains('in.tradingview.com') &&
                      !url.contains('s3.tradingview.com'))) {
                debugPrint(
                  'Blocking navigation to TradingView website: ${request.url}',
                );
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            }

            debugPrint('Blocking navigation to ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      );

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
    final WebViewController? controller = _controller;
    if (controller == null) return;

    final Brightness currentBrightness = Theme.of(context).brightness;
    if (currentBrightness == _currentLoadedBrightness) {
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() => _isLoading = true);

    final String colorTheme =
        currentBrightness == Brightness.dark ? 'dark' : 'light';
    final String htmlContent = _generateEconomicCalendarHtml(colorTheme);
    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(htmlContent));
    final String dataUrl = 'data:text/html;base64,$contentBase64';

    controller.loadRequest(Uri.parse(dataUrl)).then((_) {
      if (mounted) {
        _currentLoadedBrightness = currentBrightness;
      }
    }).catchError((Object error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading Economic Calendar WebView content: $error');
    });
  }

  void _toggleWatchlist() => _watchlistService.toggleWatchlist();

  void _closeWatchlist() {
    if (_watchlistService.isWatchlistOpen.value) {
      _watchlistService.closeWatchlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = HomeUi.pageBg(isDark);
    final Color cardBg = HomeUi.cardBg(isDark);
    final Color title = HomeUi.title(isDark);
    final Color muted = HomeUi.muted(isDark);

    return Scaffold(
      backgroundColor: pageBg,
      body: GestureDetector(
        onTap: () {
          if (_watchlistService.isWatchlistOpen.value) {
            _watchlistService.closeWatchlist();
          }
        },
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Obx(
                    () => HomeTabBar(
                      showBackButton: true,
                      isWatchlistOpen:
                          _watchlistService.isWatchlistOpen.value,
                      onWatchlistToggle: _toggleWatchlist,
                      onThemeToggle: () {
                        final Brightness currentTheme =
                            Theme.of(context).brightness;
                        Get.changeThemeMode(
                          currentTheme == Brightness.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final double width = constraints.maxWidth;
                        final EdgeInsets pagePad = HomeUi.pagePadding(width);
                        final bool narrow = width < 700;

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            pagePad.left,
                            14,
                            pagePad.right,
                            pagePad.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(isDark, title, muted, narrow: narrow),
                              const SizedBox(height: 14),
                              Expanded(
                                child: Container(
                                  decoration: HomeUi.cardDecoration(isDark),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      AdaptiveHtmlWebView(
                                        html: _generateEconomicCalendarHtml(
                                          isDark ? 'dark' : 'light',
                                        ),
                                        flutterController: _controller,
                                        backgroundColor: cardBg,
                                      ),
                                      if (_isLoading)
                                        Container(
                                          color: cardBg,
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 28,
                                                height: 28,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: HomeUi.accent(isDark),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Loading economic calendar…',
                                                style:
                                                    HomeUi.subtitle(isDark),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              if (!_watchlistService.isWatchlistOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  onTap: _closeWatchlist,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        const Expanded(child: SizedBox.expand()),
                        GestureDetector(
                          onTap: () {},
                          child: WatchlistSidebar(
                            isDarkMode: isDark,
                            onClose: _closeWatchlist,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color title,
    Color muted, {
    required bool narrow,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: HomeUi.iconWellGradient,
            shape: BoxShape.circle,
            border: Border.all(color: HomeUi.iconWellBorder),
          ),
          child: HomeUi.brandIcon(
            icon: Icons.public_rounded,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Economic Calendar',
                style: HomeUi.heading(isDark).copyWith(
                  fontSize: narrow ? 20 : 22,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Key macro events worldwide · use filters to narrow by country or impact',
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
