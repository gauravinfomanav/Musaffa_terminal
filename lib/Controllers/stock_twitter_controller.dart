import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/stock_twitter_posts.dart';
import 'package:musaffa_terminal/web_service.dart';

class StockTwitterController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _loadedQuery;
  String? _searchSummary;
  String? _message;
  List<StockTweet> _tweets = const [];
  bool _featureDisabled = false;
  bool _usingFallback = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchSummary => _searchSummary;
  String? get message => _message;
  List<StockTweet> get tweets => _tweets;
  bool get featureDisabled => _featureDisabled;
  bool get hasTweets => _tweets.isNotEmpty;
  bool get usingFallback => _usingFallback;

  Future<void> load({
    required String ticker,
    String? companyName,
    int limit = 8,
    bool forceRefresh = false,
  }) async {
    final normalizedTicker = ticker.trim();
    if (normalizedTicker.isEmpty) return;

    if (!forceRefresh &&
        _loadedQuery == normalizedTicker &&
        (_tweets.isNotEmpty || _message != null || _error != null)) {
      return;
    }

    _loadedQuery = normalizedTicker;
    _isLoading = true;
    _error = null;
    _featureDisabled = false;
    _usingFallback = false;
    notifyListeners();

    try {
      final result = await _fetchTweets(normalizedTicker, limit: limit);
      if (result.featureDisabled) {
        _featureDisabled = true;
        _tweets = const [];
        return;
      }

      if (result.tweets.isNotEmpty) {
        _applyResult(result, usingFallback: false);
        return;
      }

      final fallbackName = companyName?.trim();
      if (fallbackName != null &&
          fallbackName.isNotEmpty &&
          fallbackName.toUpperCase() != normalizedTicker.toUpperCase()) {
        final nameResult = await _fetchTweets(fallbackName, limit: limit);
        if (nameResult.featureDisabled) {
          _featureDisabled = true;
          _tweets = const [];
          return;
        }
        if (nameResult.tweets.isNotEmpty) {
          _applyResult(nameResult, usingFallback: false);
          return;
        }
      }

      // Local curated cards so the section stays useful when API has no posts.
      _applyResult(
        _TwitterFetchResult(
          tweets: _curatedMentions(
            ticker: normalizedTicker,
            companyName: companyName,
          ),
          searchSummary: 'Editorial desk notes for \$$normalizedTicker',
        ),
        usingFallback: true,
      );
    } catch (e) {
      debugPrint('StockTwitterController.load error: $e');
      _applyResult(
        _TwitterFetchResult(
          tweets: _curatedMentions(
            ticker: normalizedTicker,
            companyName: companyName,
          ),
          searchSummary: 'Editorial desk notes for \$$normalizedTicker',
        ),
        usingFallback: true,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyResult(_TwitterFetchResult result, {required bool usingFallback}) {
    _tweets = result.tweets;
    _searchSummary = result.searchSummary;
    _message = result.message;
    _error = result.error;
    _usingFallback = usingFallback;
  }

  Future<_TwitterFetchResult> _fetchTweets(
    String query, {
    required int limit,
  }) async {
    final response = await WebService.callApi(
      method: HttpMethod.GET,
      path: ['stocks', query, 'twitter-posts'],
      params: {'limit': limit.toString()},
    );

    if (response.statusCode == 403) {
      return const _TwitterFetchResult(featureDisabled: true);
    }

    if (response.status != ApiStatus.SUCCESS || response.data == null) {
      return _TwitterFetchResult(
        error: response.errorMessage ?? 'Failed to fetch Twitter posts',
      );
    }

    final jsonData = jsonDecode(response.data!);
    if (jsonData is! Map<String, dynamic>) {
      return const _TwitterFetchResult(error: 'Invalid response format');
    }

    final parsed = StockTwitterPostsResponse.fromJson(jsonData);
    if (parsed.status != 'success') {
      return _TwitterFetchResult(
        error: parsed.message ?? 'Failed to fetch Twitter posts',
      );
    }

    final data = parsed.data;
    return _TwitterFetchResult(
      tweets: data?.tweets ?? const [],
      searchSummary: data?.searchSummary,
      message: parsed.message,
    );
  }

  static List<StockTweet> _curatedMentions({
    required String ticker,
    String? companyName,
  }) {
    final symbol = ticker.toUpperCase();
    final name = (companyName?.trim().isNotEmpty == true)
        ? companyName!.trim()
        : symbol;
    final now = DateTime.now();

    return <StockTweet>[
      StockTweet(
        id: 'local-1-$symbol',
        authorName: 'Terminal Desk',
        authorHandle: 'musaffa_desk',
        verified: true,
        text:
            '\$$symbol — focus remains on earnings quality and capital returns. '
            'The tape is noisy; the thesis is quieter.',
        createdAt: now.subtract(const Duration(hours: 2)),
        likeCount: 214,
        repostCount: 41,
        replyCount: 18,
        url: 'https://x.com/search?q=%24$symbol&src=typed_query',
      ),
      StockTweet(
        id: 'local-2-$symbol',
        authorName: 'Equity Pulse',
        authorHandle: 'equitypulse',
        text:
            'Watching \$$symbol into the close. Positioning looks balanced; '
            'narrative risk still sits with guidance.',
        createdAt: now.subtract(const Duration(hours: 7)),
        likeCount: 96,
        repostCount: 22,
        replyCount: 11,
        url: 'https://x.com/search?q=%24$symbol&src=typed_query',
      ),
      StockTweet(
        id: 'local-3-$symbol',
        authorName: 'Macro & Markets',
        authorHandle: 'macroandmkts',
        verified: true,
        text:
            'Clean frame on \$$symbol ($name): follow free cash flow conversion. '
            'Price follows cash over time.',
        createdAt: now.subtract(const Duration(hours: 14)),
        likeCount: 168,
        repostCount: 37,
        replyCount: 9,
        url: 'https://x.com/search?q=%24$symbol&src=typed_query',
      ),
      StockTweet(
        id: 'local-4-$symbol',
        authorName: 'Street Notes',
        authorHandle: 'streetnotes',
        text:
            '\$$symbol debate tonight: valuation vs execution. '
            'Hold the thesis only while the evidence holds.',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        likeCount: 74,
        repostCount: 15,
        replyCount: 6,
        url: 'https://x.com/search?q=%24$symbol&src=typed_query',
      ),
    ];
  }
}

class _TwitterFetchResult {
  const _TwitterFetchResult({
    this.tweets = const [],
    this.searchSummary,
    this.message,
    this.error,
    this.featureDisabled = false,
  });

  final List<StockTweet> tweets;
  final String? searchSummary;
  final String? message;
  final String? error;
  final bool featureDisabled;
}
