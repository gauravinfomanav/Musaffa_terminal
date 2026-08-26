import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
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
/// Loads the embed as the **main document** (not a nested iframe shell) so
/// mouse-wheel scrolling works under WebView2 composition mode.
class EconomicCalendarScreen extends StatefulWidget {
  const EconomicCalendarScreen({super.key});

  @override
  State<EconomicCalendarScreen> createState() => _EconomicCalendarScreenState();
}

class _EconomicCalendarScreenState extends State<EconomicCalendarScreen> {
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();

  /// Match TradingView toolbar left inset (globe / country filter row).
  static const double _cardContentInset = 16;

  WebViewController? _controller;
  WindowsWebViewHandle? _windowsHandle;
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

  Map<String, Object?> _widgetConfig(String colorTheme) => <String, Object?>{
        'colorTheme': colorTheme,
        'isTransparent': true,
        'locale': 'en',
        'countryFilter': '',
        'importanceFilter': '-1,0,1',
        'width': '100%',
        'height': '100%',
      };

  /// Direct embed URL — main-frame scroll (wheel + scrollbar).
  String _embedUrl(String colorTheme) {
    final String encoded =
        Uri.encodeComponent(jsonEncode(_widgetConfig(colorTheme)));
    return 'https://s.tradingview.com/embed-widget/events/?locale=en#$encoded';
  }

  bool _isAllowedNavigation(String url) {
    final String lower = url.toLowerCase();
    if (lower.startsWith('data:text/html') || lower == 'about:blank') {
      return true;
    }
    if (lower.contains('s.tradingview.com/embed-widget') ||
        lower.contains('s3.tradingview.com') ||
        lower.contains('tradingview-widget.com')) {
      return true;
    }
    return false;
  }

  void _initializeWebView() {
    if (!PlatformCapabilities.isWebViewFlutterSupported) {
      // Windows WebView2 — AdaptiveHtmlWebView(url) + onWindowsPageFinished.
      _isLoading = true;
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
            Future.delayed(const Duration(milliseconds: 280), () {
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
                description: ${error.description}''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (!request.isMainFrame) {
              return NavigationDecision.navigate;
            }
            if (_isAllowedNavigation(request.url)) {
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
    final Brightness current = Theme.of(context).brightness;
    if (_currentLoadedBrightness != null &&
        _currentLoadedBrightness != current) {
      _isLoading = true;
    }
    if (_isWebViewInitialized) {
      _loadWebViewContent();
    }
  }

  void _loadWebViewContent() {
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
    final String url = _embedUrl(colorTheme);

    final WebViewController? flutterController = _controller;
    if (flutterController != null) {
      flutterController.loadRequest(Uri.parse(url)).then((_) {
        if (mounted) {
          _currentLoadedBrightness = currentBrightness;
        }
      }).catchError((Object error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        debugPrint('Error loading Economic Calendar: $error');
      });
      return;
    }

    final WindowsWebViewHandle? windows = _windowsHandle;
    if (windows != null) {
      // Windows path loads via AdaptiveHtmlWebView url + didUpdateWidget.
      _currentLoadedBrightness = currentBrightness;
    }
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
    final String colorTheme = isDark ? 'dark' : 'light';
    final String embedUrl = _embedUrl(colorTheme);

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Obx(
                  () => HomeTabBar(
                    showBackButton: true,
                    isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
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

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          pagePad.left,
                          12,
                          pagePad.right,
                          pagePad.bottom,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius:
                                BorderRadius.circular(HomeUi.radiusCard),
                            border: Border.all(
                              color: HomeUi.borderLight(isDark),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.32 : 0.05,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(HomeUi.radiusCard),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCardHeader(isDark),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: HomeUi.borderLight(isDark)
                                      .withValues(alpha: 0.9),
                                ),
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ColoredBox(
                                        color: cardBg,
                                        child: AdaptiveHtmlWebView(
                                          url: embedUrl,
                                          flutterController: _controller,
                                          backgroundColor: cardBg,
                                          onWindowsCreated:
                                              (WindowsWebViewHandle handle) {
                                            _windowsHandle = handle;
                                          },
                                          onWindowsPageFinished: () {
                                            if (!mounted) return;
                                            setState(() {
                                              _isLoading = false;
                                              _isWebViewInitialized = true;
                                              _currentLoadedBrightness =
                                                  Theme.of(context).brightness;
                                            });
                                          },
                                        ),
                                      ),
                                      if (_isLoading) _buildLoading(isDark),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildCardHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _cardContentInset,
        14,
        _cardContentInset,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Economic Calendar',
                  style: HomeUi.cardTitle(isDark).copyWith(
                    fontSize: 16,
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Key macro events worldwide · filter by country or impact',
                  style: HomeUi.subtitle(isDark).copyWith(
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: HomeUi.positive(isDark).withValues(
                alpha: isDark ? 0.14 : 0.08,
              ),
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              border: Border.all(
                color: HomeUi.positive(isDark).withValues(
                  alpha: isDark ? 0.28 : 0.18,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: HomeUi.positive(isDark),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Live',
                  style: HomeUi.control(isDark, active: true).copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.positive(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return ColoredBox(
      color: HomeUi.cardBg(isDark),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _cardContentInset,
          18,
          _cardContentInset,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ShimmerWidgets.box(
                  width: 88,
                  height: 28,
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                  baseColor: HomeUi.elevatedBg(isDark),
                  highlightColor: HomeUi.cardBg(isDark),
                ),
                const SizedBox(width: 10),
                ShimmerWidgets.box(
                  width: 88,
                  height: 28,
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                  baseColor: HomeUi.elevatedBg(isDark),
                  highlightColor: HomeUi.cardBg(isDark),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 18),
            for (int i = 0; i < 7; i++) ...[
              if (i == 0 || i == 3)
                Padding(
                  padding: EdgeInsets.only(bottom: 10, top: i == 0 ? 0 : 8),
                  child: ShimmerWidgets.box(
                    width: 96,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: HomeUi.elevatedBg(isDark),
                    highlightColor: HomeUi.cardBg(isDark),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShimmerWidgets.box(
                  width: double.infinity,
                  height: 44,
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  baseColor: HomeUi.elevatedBg(isDark),
                  highlightColor: HomeUi.cardBg(isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
