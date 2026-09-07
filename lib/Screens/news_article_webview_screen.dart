import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/windows_html_webview.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/platform_capabilities.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens a news article inside the app WebView instead of the system browser.
void openNewsArticle(
  BuildContext context, {
  required String? url,
  String? title,
  String? source,
}) {
  final String? normalized = _normalizeNewsUrl(url);
  if (normalized == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No URL available for this news item')),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NewsArticleWebViewScreen(
        url: normalized,
        title: title,
        source: source,
      ),
    ),
  );
}

String? _normalizeNewsUrl(String? rawUrl) {
  if (rawUrl == null) return null;
  var url = rawUrl.trim();
  if (url.isEmpty) return null;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  return Uri.tryParse(url) == null ? null : url;
}

class NewsArticleWebViewScreen extends StatefulWidget {
  const NewsArticleWebViewScreen({
    super.key,
    required this.url,
    this.title,
    this.source,
  });

  final String url;
  final String? title;
  final String? source;

  @override
  State<NewsArticleWebViewScreen> createState() =>
      _NewsArticleWebViewScreenState();
}

class _NewsArticleWebViewScreenState extends State<NewsArticleWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    if (!PlatformCapabilities.isWebViewAvailable) {
      _isLoading = false;
      _error = 'WebView is not available on this platform.';
      return;
    }

    if (!PlatformCapabilities.isWebViewFlutterSupported) {
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _error = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String headline = (widget.title ?? '').trim();
    final String source = (widget.source ?? '').trim();

    return Scaffold(
      backgroundColor: HomeUi.pageBg(isDark),
      body: Column(
        children: <Widget>[
          HomeTabBar(
            showBackButton: true,
            onThemeToggle: () {
              final Brightness current = Theme.of(context).brightness;
              Get.changeThemeMode(
                current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: HomeUi.cardBg(isDark),
              border: Border(
                bottom: BorderSide(color: HomeUi.borderLight(isDark)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (source.isNotEmpty)
                  Text(
                    source.toUpperCase(),
                    style: HomeUi.overline(isDark).copyWith(
                      fontSize: 10,
                      letterSpacing: 0.9,
                    ),
                  ),
                if (source.isNotEmpty) const SizedBox(height: 4),
                Text(
                  headline.isEmpty ? 'News article' : headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.sectionTitle(isDark).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              color: HomeUi.accent(isDark),
              backgroundColor: HomeUi.borderLight(isDark),
            ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: HomeUi.subtitle(isDark),
                      ),
                    ),
                  )
                : AdaptiveHtmlWebView(
                    url: widget.url,
                    flutterController: _controller,
                    backgroundColor: HomeUi.pageBg(isDark),
                    onWindowsPageFinished: () {
                      if (mounted) setState(() => _isLoading = false);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
